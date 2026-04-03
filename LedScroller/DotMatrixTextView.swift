import UIKit

// Renders an attributed string as a grid of circular "LED" dots.
//
// This is intentionally static: it rasterizes the text once (on layout/content changes)
// and then draws dots based on sampled pixel intensity. This makes emoji work too,
// because they get rasterized into the bitmap first.
public final class DotMatrixTextView: UIView {

    public struct Style {
        public var dotDiameter: CGFloat = 5
        public var dotSpacing: CGFloat = 2
        public var threshold: CGFloat = 0.10
        public var levels: Int = 6
        public var insets: UIEdgeInsets = .init(top: 10, left: 12, bottom: 10, right: 12)

        public var step: CGFloat { dotDiameter + dotSpacing }
        
        public init(dotDiameter: CGFloat = 5, dotSpacing: CGFloat = 2, threshold: CGFloat = 0.10, levels: Int = 6, insets: UIEdgeInsets = .init(top: 10, left: 12, bottom: 10, right: 12)) {
            self.dotDiameter = dotDiameter
            self.dotSpacing = dotSpacing
            self.threshold = threshold
            self.levels = levels
            self.insets = insets
        }
    }

    public var style = Style() { didSet { invalidateCache() } }

    // Use a white rasterization color so intensity is stable, then tint the dots with dotColor.
    public var dotColor: UIColor = .white { didSet { setNeedsDisplay() } }

    public var attributedText: NSAttributedString? { didSet { invalidateCache() } }

    // Cache: points grouped by quantized intensity level (0..levels-1).
    private var levelPoints: [[CGPoint]] = []
    private var cachedBoundsSize: CGSize = .zero
    private var cachedTextHash: Int = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        contentMode = .redraw
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        rebuildIfNeeded()
    }

    private func invalidateCache() {
        cachedBoundsSize = .zero
        setNeedsLayout()
        setNeedsDisplay()
    }

    private func rebuildIfNeeded() {
        let size = bounds.size
        guard size.width > 1, size.height > 1 else {
            levelPoints = []
            return
        }

        let textHash = attributedText?.string.hashValue ?? 0
        if cachedBoundsSize == size && cachedTextHash == textHash && !levelPoints.isEmpty {
            return
        }

        cachedBoundsSize = size
        cachedTextHash = textHash
        levelPoints = Array(repeating: [], count: max(style.levels, 2))

        guard let attributedText else { return }

        let contentRect = bounds.inset(by: style.insets)
        guard contentRect.width > 1, contentRect.height > 1 else { return }

        // Rasterize text into a bitmap matching our view size.
        guard let cgImage = rasterize(attributedText: attributedText, in: contentRect)?.cgImage else {
            return
        }

        guard let pixels = cgImage.rgbaPixels() else { return }

        let scale = UIScreen.main.scale
        let step = max(style.step, 2)
        let radius = max(style.dotDiameter / 2, 0.5)

        // Sample pixel intensity at each dot center.
        let minX = contentRect.minX
        let maxX = contentRect.maxX
        let minY = contentRect.minY
        let maxY = contentRect.maxY

        var y = minY
        while y <= maxY {
            var x = minX
            while x <= maxX {
                let px = Int((x * scale).rounded(.down))
                let py = Int((y * scale).rounded(.down))

                let intensity = pixels.intensityAt(x: px, y: py)
                if intensity >= style.threshold {
                    // Quantize to a small number of alpha levels to keep drawing fast.
                    let t = min(max(intensity, 0), 1)
                    let idx = min(Int((t * CGFloat(levelPoints.count - 1)).rounded(.down)), levelPoints.count - 1)
                    // Align to pixel grid a bit to reduce shimmer.
                    let p = CGPoint(x: x.rounded(.toNearestOrAwayFromZero), y: y.rounded(.toNearestOrAwayFromZero))
                    levelPoints[idx].append(p)
                }

                x += step
            }
            y += step
        }

        // Avoid degenerate case when dot diameter > step.
        _ = radius
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard !levelPoints.isEmpty else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let radius = max(style.dotDiameter / 2, 0.5)
        let diameter = radius * 2
        let levelsCount = levelPoints.count

        // Draw low intensity first, high intensity last.
        for i in 0..<levelsCount {
            let points = levelPoints[i]
            guard !points.isEmpty else { continue }

            // Map level index to alpha (non-linear feels more "LED-like").
            let t = CGFloat(i) / CGFloat(max(levelsCount - 1, 1))
            let alpha = pow(t, 1.6)
            ctx.setFillColor(dotColor.withAlphaComponent(alpha).cgColor)

            for p in points {
                let r = CGRect(x: p.x - radius, y: p.y - radius, width: diameter, height: diameter)
                ctx.fillEllipse(in: r)
            }
        }
    }

    private func rasterize(attributedText: NSAttributedString, in contentRect: CGRect) -> UIImage? {
        let scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: {
            let f = UIGraphicsImageRendererFormat()
            f.scale = scale
            f.opaque = false
            return f
        }())

        // Draw into a full-size bitmap so sampling coordinates match view space.
        return renderer.image { _ in
            let maxSize = CGSize(width: contentRect.width, height: contentRect.height)
            let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]

            // Force white foreground for stable intensity; emoji keeps its own color.
            let forced = NSMutableAttributedString(attributedString: attributedText)
            forced.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: forced.length))

            let textBounds = forced.boundingRect(with: maxSize, options: options, context: nil).integral
            let origin = CGPoint(
                x: contentRect.midX - textBounds.width / 2,
                y: contentRect.midY - textBounds.height / 2
            )
            let drawRect = CGRect(origin: origin, size: textBounds.size)

            forced.draw(with: drawRect, options: options, context: nil)
        }
    }
}

private struct RGBAPixels {
    let data: [UInt8]
    let width: Int
    let height: Int

    // Returns intensity 0..1 using premultiplied RGBA.
    func intensityAt(x: Int, y: Int) -> CGFloat {
        guard x >= 0, y >= 0, x < width, y < height else { return 0 }
        let idx = (y * width + x) * 4
        if idx + 3 >= data.count { return 0 }

        let r = CGFloat(data[idx]) / 255.0
        let g = CGFloat(data[idx + 1]) / 255.0
        let b = CGFloat(data[idx + 2]) / 255.0
        let a = CGFloat(data[idx + 3]) / 255.0

        // Luma * alpha works well for both text and emoji.
        let luma = (0.2126 * r + 0.7152 * g + 0.0722 * b)
        return luma * a
    }
}

private extension CGImage {
    func rgbaPixels() -> RGBAPixels? {
        let width = self.width
        let height = self.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let ctx = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        ctx.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return RGBAPixels(data: data, width: width, height: height)
    }
}
