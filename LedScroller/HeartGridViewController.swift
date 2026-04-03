import UIKit

// 爱心格子全屏预览控制器
class HeartGridViewController: UIViewController {
    
    private var heartGridView: HeartGridFullScreenView!
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
    
    private func setupUI() {
        view.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
        
        // 创建爱心格子视图
        heartGridView = HeartGridFullScreenView()
        heartGridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heartGridView)
        
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
            // 爱心格子视图使用safeArea，确保在安全区域内居中
            heartGridView.topAnchor.constraint(equalTo: view.topAnchor),
            heartGridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heartGridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heartGridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
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

// 全屏爱心格子视图
class HeartGridFullScreenView: UIView {
    
    private var gridSize: CGFloat = 18  // 固定格子大小
    private var spacing: CGFloat = 2.5
    private var rows: Int = 0
    private var cols: Int = 0
    
    // 动画相关属性
    private var animationTimer: Timer?
    private var backgroundGridAlphas: [[CGFloat]] = []  // 背景格子的透明度
    
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
        // 启动动画定时器（降低频率）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateAnimation()
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
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 计算能容纳多少行列的格子（填充满整个屏幕）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 确保至少有足够的空间显示爱心
        let heartPattern = getHeartPattern()
        let heartRows = heartPattern.count
        let heartCols = heartPattern[0].count
        
        // 如果计算出的网格太小，无法容纳爱心，则调整格子大小
        if rows < heartRows + 4 || cols < heartCols + 4 {
            // 重新计算格子大小以确保爱心能完整显示
            let maxGridSizeForHeight = (rect.height - CGFloat(heartRows + 4) * spacing) / CGFloat(heartRows + 4)
            let maxGridSizeForWidth = (rect.width - CGFloat(heartCols + 4) * spacing) / CGFloat(heartCols + 4)
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
        
        // 绘制所有格子
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                // 圆形格子（cornerRadius = 0.5 * gridSize）
                let path = UIBezierPath(ovalIn: rect)
                
                // 判断当前格子是否在爱心图案内
                // 需要考虑边界框的偏移量
                let heartRow = row - centeredHeartStartRow + boundingBox.topRow
                let heartCol = col - centeredHeartStartCol + boundingBox.leftCol
                
                var isHeartGrid = false
                if heartRow >= 0 && heartRow < heartRows && heartCol >= 0 && heartCol < heartCols {
                    isHeartGrid = heartPattern[heartRow][heartCol]
                }
                
                if isHeartGrid {
                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    path.fill()
                    
                    // 静态发光效果
                    let glowRadius = gridSize * 0.3
                    let glowPath = UIBezierPath(ovalIn: rect.insetBy(dx: -glowRadius, dy: -glowRadius))
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.4).setFill()
                    glowPath.fill()
                } else {
                    // 未点亮的格子：暗蓝色带随机闪烁效果（提亮颜色）
                    let alpha = backgroundGridAlphas[row][col]
                    UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // 返回18x20的爱心图案（垂直居中优化 - 减少顶部空白）
    private func getHeartPattern() -> [[Bool]] {
        return [
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, true,  true,  true,  true,  false, false, false, false, true,  true,  true,  true,  false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  false, false, true,  true,  true,  true,  true,  true,  false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false],
            [false, false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, false, false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, false, false, false, true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false],
            [false, false, false, false, false, false, true,  true,  true,  true,  true,  true,  false, false, false, false, false, false],
            [false, false, false, false, false, false, false, true,  true,  true,  true,  false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, true,  true,  false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
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