import UIKit

// I LOVE U 全屏预览控制器
class ILoveUViewController: UIViewController {
    
    private var iLoveUView: ILoveUFullScreenView!
    private var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 强制横屏
        AppDelegate.orientationLock = .landscape
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 恢复竖屏
        AppDelegate.orientationLock = .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
        
        // 创建I LOVE U视图
        iLoveUView = ILoveUFullScreenView()
        iLoveUView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iLoveUView)
        
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
            // I LOVE U视图填满整个屏幕
            iLoveUView.topAnchor.constraint(equalTo: view.topAnchor),
            iLoveUView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            iLoveUView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            iLoveUView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
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

// 全屏I LOVE U视图
class ILoveUFullScreenView: UIView {
    
    private var gridSize: CGFloat = 18  // 固定格子大小
    private var spacing: CGFloat = 2.5
    private var rows: Int = 0
    private var cols: Int = 0
    
    // 动画相关属性
    private var animationTimer: Timer?
    private var backgroundGridAlphas: [[CGFloat]] = []  // 背景格子的透明度
    
    // 心跳动画相关
    private var heartbeatTimer: Timer?
    private var heartbeatScale: CGFloat = 1.0
    private var heartbeatPhase: Int = 0 // 0: normal, 1: expand, 2: contract

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
        setupHeartbeatAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
        setupHeartbeatAnimation()
    }
    
    private func setupAnimation() {
        // 启动动画定时器（降低频率）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func setupHeartbeatAnimation() {
        // 心跳动画 - 慢速放大缩小
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateHeartbeat()
        }
    }
    
    private func updateAnimation() {
        // 随机更新背景格子透明度
        for row in 0..<backgroundGridAlphas.count {
            for col in 0..<backgroundGridAlphas[row].count {
                // 10% 的概率改变透明度
                if Float.random(in: 0...1) < 0.1 {
                    backgroundGridAlphas[row][col] = CGFloat.random(in: 0.3...1.0)
                }
            }
        }
        
        // 触发重绘
        setNeedsDisplay()
    }
    
    private func updateHeartbeat() {
        // 心跳节奏：放大 -> 快速缩小 -> 正常 -> 正常（短暂停顿）
        heartbeatPhase = (heartbeatPhase + 1) % 6
        
        switch heartbeatPhase {
        case 0:
            heartbeatScale = 1.0
        case 1:
            heartbeatScale = 1.15  // 快速放大
        case 2:
            heartbeatScale = 0.95  // 快速缩小
        case 3:
            heartbeatScale = 1.1   // 第二次放大
        case 4:
            heartbeatScale = 0.98  // 第二次缩小
        case 5:
            heartbeatScale = 1.0   // 恢复正常
        default:
            heartbeatScale = 1.0
        }
        
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
        heartbeatTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 计算能容纳多少行列的格子（填充满整个屏幕）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 确保至少有足够的空间显示内容
        let heartPattern = getHeartPattern()
        let heartRows = heartPattern.count
        let heartCols = heartPattern[0].count
        
        // 如果计算出的网格太小，无法容纳内容，则调整格子大小
        if rows < heartRows + 4 || cols < heartCols + 10 { // 需要额外空间放置I和U
            // 重新计算格子大小以确保内容能完整显示
            let maxGridSizeForHeight = (rect.height - CGFloat(heartRows + 4) * spacing) / CGFloat(heartRows + 4)
            let maxGridSizeForWidth = (rect.width - CGFloat(heartCols + 10) * spacing) / CGFloat(heartCols + 10)
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
        
        // 计算爱心在网格中的真正居中位置
        // 使用爱心图案的实际边界框来计算，而不是整个网格的大小
        let boundingBox = getHeartBoundingBox()
        let heartActualHeight = boundingBox.bottomRow - boundingBox.topRow + 1
        let heartActualWidth = boundingBox.rightCol - boundingBox.leftCol + 1
        
        // 使用浮点数计算，然后四舍五入确保居中
        let exactHeartStartRow = (Double(rows) - Double(heartActualHeight)) / 2.0
        let exactHeartStartCol = (Double(cols) - Double(heartActualWidth)) / 2.0
        
        let centeredHeartStartRow = Int(exactHeartStartRow.rounded())
        let centeredHeartStartCol = Int(exactHeartStartCol.rounded())
        
        // 计算I和U的图案位置（使用与心相同高度的网格）
        let iPattern = getIPattern()
        let uPattern = getUPattern()
        let iRows = iPattern.count
        let iCols = iPattern[0].count
        let uRows = uPattern.count
        let uCols = uPattern[0].count

        // I和U的高度与心一样高，计算需要的格子数
        let letterGridHeight = heartActualHeight // 和心一样高的行数

        // 计算I和U在心左右两侧的位置
        let spacingToHeart = max(iCols, uCols) + 2 // 距离心的格数

        // I的起始列（心左边）- 往右移动3个圆点
        let iStartCol = centeredHeartStartCol - spacingToHeart - iCols + 3
        // U的起始列（心右边）- 往左移动4个圆点
        let uStartCol = centeredHeartStartCol + boundingBox.leftCol + heartActualWidth + spacingToHeart - 4

        // 垂直居中：I/U和心顶部对齐
        let letterStartRow = centeredHeartStartRow + boundingBox.topRow

        // 绘制所有格子
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)

                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                // 圆形格子
                let path = UIBezierPath(ovalIn: rect)

                // 判断当前格子是否在爱心图案内
                // 需要考虑边界框的偏移量
                let heartRow = row - centeredHeartStartRow + boundingBox.topRow
                let heartCol = col - centeredHeartStartCol + boundingBox.leftCol

                var isHeartGrid = false
                if heartRow >= 0 && heartRow < heartRows && heartCol >= 0 && heartCol < heartCols {
                    isHeartGrid = heartPattern[heartRow][heartCol]
                }

                // 判断是否是I或U的点
                var isLetterGrid = false
                var isIGrid = false

                // 检查I
                let iLocalRow = row - letterStartRow
                let iLocalCol = col - iStartCol
                if iLocalRow >= 0 && iLocalRow < min(iRows, letterGridHeight) && iLocalCol >= 0 && iLocalCol < iCols {
                    if iPattern[iLocalRow][iLocalCol] {
                        isLetterGrid = true
                        isIGrid = true
                    }
                }

                // 检查U
                let uLocalRow = row - letterStartRow
                let uLocalCol = col - uStartCol
                if uLocalRow >= 0 && uLocalRow < min(uRows, letterGridHeight) && uLocalCol >= 0 && uLocalCol < uCols {
                    if uPattern[uLocalRow][uLocalCol] {
                        isLetterGrid = true
                    }
                }

                if isHeartGrid {
                    // 应用心跳缩放
                    let centerX = x + gridSize / 2
                    let centerY = y + gridSize / 2
                    let scaledX = centerX - (centerX - (startX + totalGridWidth / 2)) * (heartbeatScale - 1)
                    let scaledY = centerY - (centerY - (startY + totalGridHeight / 2)) * (heartbeatScale - 1)
                    let scaledRect = CGRect(
                        x: scaledX - gridSize * heartbeatScale / 2,
                        y: scaledY - gridSize * heartbeatScale / 2,
                        width: gridSize * heartbeatScale,
                        height: gridSize * heartbeatScale
                    )

                    let scaledPath = UIBezierPath(ovalIn: scaledRect)

                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    scaledPath.fill()

                    // 静态发光效果
                    let glowRadius = gridSize * heartbeatScale * 0.3
                    let glowPath = UIBezierPath(ovalIn: scaledRect.insetBy(dx: -glowRadius, dy: -glowRadius))
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.4).setFill()
                    glowPath.fill()
                } else if isLetterGrid {
                    // I和U：红色圆形点（和心一样的颜色）
                    let circlePath = UIBezierPath(ovalIn: rect)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0).setFill()
                    circlePath.fill()
                } else {
                    // 未点亮的格子：暗蓝色带随机闪烁效果（提亮颜色）
                    let alpha = backgroundGridAlphas[row][col]
                    UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // I 字母图案（3列 x 12行）
    private func getIPattern() -> [[Bool]] {
        return [
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false],
            [false, true, false]
        ]
    }

    // U 字母图案（7列 x 10行）- 两侧竖线 + 底部5个红点
    private func getUPattern() -> [[Bool]] {
        return [
            [true,  false, false, false, false, false, true ],
            [true,  false, false, false, false, false, true ],
            [true,  false, false, false, false, false, true ],
            [true,  false, false, false, false, false, true ],
            [true,  false, false, false, false, false, true ],
            [true,  false, false, false, false, false, true ],
            [true,  false, false, false, false, false, true ],
            [true,  false, false, false, false, false, true ],
            [true,  false, false, false, false, false, true ],
            [false, true,  true,  true,  true,  true,  false]
        ]
    }
    
    // 返回20x20的爱心图案（与HeartGridView相同）
    private func getHeartPattern() -> [[Bool]] {
        return [
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, true,  true,  true,  true,  false, false, false, false, true,  true,  true,  true,  false, false, false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  false, false, true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false],
            [false, false, false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false, false],
            [false, false, false, false, false, true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false, false, false],
            [false, false, false, false, false, false, true,  true,  true,  true,  true,  true,  false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, true,  true,  true,  true,  false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
        ]
    }
    
    // 计算爱心图案的实际边界框（用于更精确的居中）
    private func getHeartBoundingBox() -> (topRow: Int, bottomRow: Int, leftCol: Int, rightCol: Int) {
        let pattern = getHeartPattern()
        var topRow = pattern.count
        var bottomRow = 0
        var leftCol = pattern[0].count
        var rightCol = 0
        
        for row in 0..<pattern.count {
            for col in 0..<pattern[row].count {
                if pattern[row][col] {
                    topRow = min(topRow, row)
                    bottomRow = max(bottomRow, row)
                    leftCol = min(leftCol, col)
                    rightCol = max(rightCol, col)
                }
            }
        }
        
        return (topRow, bottomRow, leftCol, rightCol)
    }
}
