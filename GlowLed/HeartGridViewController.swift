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
        view.backgroundColor = UIColor(red: 0.08, green: 0.12, blue: 0.2, alpha: 1.0) // 深蓝色背景
        
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
            // 爱心格子视图填满整个屏幕（不使用安全区域，确保背景完全填充）
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
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
        
        // 计算实际的网格总尺寸
        let totalGridWidth = CGFloat(cols) * gridSize + CGFloat(cols - 1) * spacing
        let totalGridHeight = CGFloat(rows) * gridSize + CGFloat(rows - 1) * spacing
        
        // 计算起始位置以居中显示
        let startX = (rect.width - totalGridWidth) / 2
        let startY = (rect.height - totalGridHeight) / 2
        
        // 计算爱心在网格中的真正居中位置
        // 使用浮点数计算，然后四舍五入确保居中
        let exactHeartStartRow = (Double(rows) - Double(heartRows)) / 2.0
        let exactHeartStartCol = (Double(cols) - Double(heartCols)) / 2.0
        
        let centeredHeartStartRow = Int(exactHeartStartRow.rounded())
        let centeredHeartStartCol = Int(exactHeartStartCol.rounded())
        
        // 绘制所有格子
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: gridSize * 0.25)
                
                // 判断当前格子是否在爱心图案内
                let heartRow = row - centeredHeartStartRow
                let heartCol = col - centeredHeartStartCol
                
                var isHeartGrid = false
                if heartRow >= 0 && heartRow < heartRows && heartCol >= 0 && heartCol < heartCols {
                    isHeartGrid = heartPattern[heartRow][heartCol]
                }
                
                if isHeartGrid {
                    // 点亮的格子：亮红色带发光效果
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0).setFill()
                    path.fill()
                    
                    // 添加发光效果
                    let glowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -1, dy: -1), cornerRadius: gridSize * 0.25 + 1)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.3).setFill()
                    glowPath.fill()
                } else {
                    // 未点亮的格子：暗蓝色（填充满整个背景）
                    UIColor(red: 0.1, green: 0.15, blue: 0.25, alpha: 1.0).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // 返回20x20的爱心图案（更大更详细）
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
}