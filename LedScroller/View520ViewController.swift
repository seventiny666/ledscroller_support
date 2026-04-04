import UIKit

// 520全屏预览控制器
class View520ViewController: UIViewController {
    
    private var view520: View520FullScreenView!
    private var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 强制横屏（iPad端额外强制旋转）
        AppDelegate.orientationLock = .landscape
        if UIDevice.current.userInterfaceIdiom == .pad {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 恢复竖屏
        AppDelegate.orientationLock = .portrait
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
        
        // 创建520视图
        view520 = View520FullScreenView()
        view520.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(view520)
        
        // 关闭按钮
        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            // 520视图填满整个屏幕
            view520.topAnchor.constraint(equalTo: view.topAnchor),
            view520.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view520.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view520.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 关闭按钮在右上角
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// 全屏520视图
class View520FullScreenView: UIView {
    
    private var gridSize: CGFloat = 18  // 固定格子大小
    private var spacing: CGFloat = 2.5
    private var rows: Int = 0
    private var cols: Int = 0
    
    // 动画相关属性
    private var animationTimer: Timer?
    private var backgroundGridAlphas: [[CGFloat]] = []  // 背景格子的透明度
    private var scrollOffset: CGFloat = 0  // 滚动偏移量
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
    }
    
    private func setupAnimation() {
        // 启动动画定时器（滚动动画）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func updateAnimation() {
        // 更新滚动偏移量（从右向左滚动，进一步加快速度）
        scrollOffset += 12.0  // 从8.0增加到12.0，速度进一步提升
        
        // 计算520数字的总宽度
        let digitCols = 6 // 每个数字6列宽
        let totalDigitWidth = digitCols * 3 + 8 // 3个数字 + 间距(4+4格)
        let digitPixelWidth = CGFloat(totalDigitWidth) * (gridSize + spacing)
        
        // 当520滚出屏幕左侧-10像素后立即重置，实现无缝循环
        if scrollOffset > digitPixelWidth + 10 {  // 520完全滚出左侧10像素后重置
            scrollOffset = -digitPixelWidth  // 从右侧屏幕外开始，让520逐渐滑入
        }
        
        // 随机更新背景格子透明度（降低频率）
        if Int.random(in: 0...10) == 0 {  // 约10%的概率更新背景
            for row in 0..<backgroundGridAlphas.count {
                for col in 0..<backgroundGridAlphas[row].count {
                    // 5% 的概率改变透明度
                    if Float.random(in: 0...1) < 0.05 {
                        backgroundGridAlphas[row][col] = CGFloat.random(in: 0.3...1.0)
                    }
                }
            }
        }
        
        // 触发重绘
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 计算能容纳多少行列的格子（填充满整个屏幕）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 定义520数字图案
        let digit5 = getDigit5Pattern()
        let digit2 = getDigit2Pattern()
        let digit0 = getDigit0Pattern()
        
        let digitRows = digit5.count
        let digitCols = digit5[0].count
        
        // 如果计算出的网格太小，无法容纳数字，则调整格子大小
        let totalDigitCols = digitCols * 3 + 8 // 3个数字 + 2个间距(各4格)
        if rows < digitRows + 4 || cols < totalDigitCols + 4 {
            // 重新计算格子大小以确保数字能完整显示
            let maxGridSizeForHeight = (rect.height - CGFloat(digitRows + 4) * spacing) / CGFloat(digitRows + 4)
            let maxGridSizeForWidth = (rect.width - CGFloat(totalDigitCols + 4) * spacing) / CGFloat(totalDigitCols + 4)
            gridSize = min(maxGridSizeForHeight, maxGridSizeForWidth, 18) // 最大不超过18px
            
            // 重新计算行列数
            cols = Int((rect.width + spacing) / (gridSize + spacing))
            rows = Int((rect.height + spacing) / (gridSize + spacing))
        }
        
        // 初始化背景格子透明度数组（如果需要）
        if backgroundGridAlphas.count != rows || (backgroundGridAlphas.first?.count ?? 0) != cols {
            backgroundGridAlphas = Array(repeating: Array(repeating: CGFloat.random(in: 0.3...1.0), count: cols), count: rows)
        }
        
        // 计算实际的网格总尺寸
        let totalGridWidth = CGFloat(cols) * gridSize + CGFloat(cols - 1) * spacing
        let totalGridHeight = CGFloat(rows) * gridSize + CGFloat(rows - 1) * spacing
        
        // 计算起始位置以居中显示
        let startX = (rect.width - totalGridWidth) / 2
        let startY = (rect.height - totalGridHeight) / 2
        
        // 计算520在网格中的真正居中位置
        let totalDigitWidth = digitCols * 3 + 8 // 3个数字 + 间距(4+4格)
        let exactDigitStartRow = (Double(rows) - Double(digitRows)) / 2.0
        let exactDigitStartCol = (Double(cols) - Double(totalDigitWidth)) / 2.0
        
        let centeredDigitStartRow = Int(exactDigitStartRow.rounded())
        let centeredDigitStartCol = Int(exactDigitStartCol.rounded())
        
        // 计算每个数字的起始列（不应用滚动偏移，保持固定位置）
        let digit5StartCol = centeredDigitStartCol
        let digit2StartCol = digit5StartCol + digitCols + 4 // 5后面加4格间距
        let digit0StartCol = digit2StartCol + digitCols + 4 // 2后面加4格间距
        
        // 第一步：绘制完整的背景格子网格
        for row in 0..<rows {
            for col in 0..<cols {
                let bgX = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                let rect = CGRect(x: bgX, y: y, width: gridSize, height: gridSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: gridSize * 0.25)
                
                // 绘制背景格子：暗蓝色带随机闪烁效果
                let alpha = backgroundGridAlphas[row][col]
                UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                path.fill()
            }
        }
        
        // 第二步：在背景上层绘制滚动的520数字
        for row in 0..<rows {
            for col in 0..<cols {
                let bgX = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                // 判断当前格子是否在520数字图案内
                let digitRow = row - centeredDigitStartRow
                
                var is520Grid = false
                
                // 判断是否在数字5内
                let digit5Col = col - digit5StartCol
                if digitRow >= 0 && digitRow < digitRows && digit5Col >= 0 && digit5Col < digitCols {
                    is520Grid = digit5[digitRow][digit5Col]
                }
                
                // 判断是否在数字2内
                let digit2Col = col - digit2StartCol
                if digitRow >= 0 && digitRow < digitRows && digit2Col >= 0 && digit2Col < digitCols {
                    is520Grid = is520Grid || digit2[digitRow][digit2Col]
                }
                
                // 判断是否在数字0内
                let digit0Col = col - digit0StartCol
                if digitRow >= 0 && digitRow < digitRows && digit0Col >= 0 && digit0Col < digitCols {
                    is520Grid = is520Grid || digit0[digitRow][digit0Col]
                }
                
                if is520Grid {
                    // 520数字格子：应用滚动偏移，绘制在背景上层
                    let x = bgX - scrollOffset
                    let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: gridSize * 0.25)
                    
                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    path.fill()
                    
                    // 静态发光效果
                    let glowRadius = gridSize * 0.3
                    let glowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -glowRadius, dy: -glowRadius), 
                                               cornerRadius: gridSize * 0.25 + glowRadius)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.4).setFill()
                    glowPath.fill()
                }
            }
        }
    }
    
    // 数字5的图案（11x6网格 - 更大更修长版本）
    private func getDigit5Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true,  true,  true],
            [true,  false, false, false, false, false],
            [true,  false, false, false, false, false],
            [true,  false, false, false, false, false],
            [true,  false, false, false, false, false],
            [true,  true,  true,  true,  true,  true],
            [false, false, false, false, false, true],
            [false, false, false, false, false, true],
            [false, false, false, false, false, true],
            [false, false, false, false, false, true],
            [true,  true,  true,  true,  true,  true]
        ]
    }
    
    // 数字2的图案（11x6网格 - 更大更修长版本）
    private func getDigit2Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true,  true,  true],
            [false, false, false, false, false, true],
            [false, false, false, false, false, true],
            [false, false, false, false, false, true],
            [false, false, false, false, false, true],
            [true,  true,  true,  true,  true,  true],
            [true,  false, false, false, false, false],
            [true,  false, false, false, false, false],
            [true,  false, false, false, false, false],
            [true,  false, false, false, false, false],
            [true,  true,  true,  true,  true,  true]
        ]
    }
    
    // 数字0的图案（11x6网格 - 更大更修长版本）
    private func getDigit0Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true,  true,  true],
            [true,  false, false, false, false, true],
            [true,  false, false, false, false, true],
            [true,  false, false, false, false, true],
            [true,  false, false, false, false, true],
            [true,  false, false, false, false, true],
            [true,  false, false, false, false, true],
            [true,  false, false, false, false, true],
            [true,  false, false, false, false, true],
            [true,  false, false, false, false, true],
            [true,  true,  true,  true,  true,  true]
        ]
    }
}
