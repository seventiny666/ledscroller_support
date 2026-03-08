import UIKit

// 爱心格子视图 - 用于热门动画封面
class HeartGridView: UIView {
    
    private var gridSize: CGFloat = 12  // 封面用较小的格子
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
        // 启动动画定时器（封面版本更慢）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func updateAnimation() {
        // 随机更新背景格子透明度（封面版本更温和）
        for row in 0..<backgroundGridAlphas.count {
            for col in 0..<backgroundGridAlphas[row].count {
                // 8% 的概率改变透明度
                if Float.random(in: 0...1) < 0.08 {
                    backgroundGridAlphas[row][col] = CGFloat.random(in: 0.4...1.0)
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
        
        // 确保rect有有效的尺寸
        guard rect.width > 0 && rect.height > 0 else { return }
        
        // 计算能容纳多少行列的格子（填充满整个封面）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 确保至少有最小的网格数量
        cols = max(cols, 10)
        rows = max(rows, 8)
        
        // 定义爱心形状（15x15网格）
        let heartPattern = getHeartPattern()
        let heartRows = heartPattern.count
        let heartCols = heartPattern[0].count
        
        // 如果网格太小无法容纳内容，调整格子大小
        if rows < heartRows || cols < heartCols {
            let maxGridSizeForHeight = rect.height / CGFloat(heartRows + 2)
            let maxGridSizeForWidth = rect.width / CGFloat(heartCols + 2)
            gridSize = min(maxGridSizeForHeight, maxGridSizeForWidth, 12) // 最大不超过12px
            gridSize = max(gridSize, 4) // 最小4px
            
            // 重新计算行列数
            cols = Int((rect.width + spacing) / (gridSize + spacing))
            rows = Int((rect.height + spacing) / (gridSize + spacing))
            cols = max(cols, heartCols + 2)
            rows = max(rows, heartRows + 2)
        }
        
        // 初始化背景格子透明度数组（如果需要）
        if backgroundGridAlphas.count != rows || (backgroundGridAlphas.first?.count ?? 0) != cols {
            backgroundGridAlphas = Array(repeating: Array(repeating: CGFloat.random(in: 0.4...1.0), count: cols), count: rows)
        }
        
        // 计算实际的网格总尺寸
        let totalGridWidth = CGFloat(cols) * gridSize + CGFloat(cols - 1) * spacing
        let totalGridHeight = CGFloat(rows) * gridSize + CGFloat(rows - 1) * spacing
        
        // 计算起始位置以居中显示
        let startX = (rect.width - totalGridWidth) / 2
        let startY = (rect.height - totalGridHeight) / 2
        
        // 计算爱心在网格中的真正居中位置
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
                
                var isRedGrid = false
                
                // 判断是否在爱心图案内
                let heartRow = row - centeredHeartStartRow
                let heartCol = col - centeredHeartStartCol
                if heartRow >= 0 && heartRow < heartRows && heartCol >= 0 && heartCol < heartCols {
                    isRedGrid = heartPattern[heartRow][heartCol]
                }
                
                if isRedGrid {
                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    path.fill()
                    
                    // 静态发光效果（封面版本较温和）
                    let glowRadius = gridSize * 0.4
                    let glowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -glowRadius, dy: -glowRadius), 
                                               cornerRadius: gridSize * 0.25 + glowRadius)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.3).setFill()
                    glowPath.fill()
                } else {
                    // 未点亮的格子：暗蓝色带随机闪烁效果
                    let alpha = backgroundGridAlphas[row][col]
                    UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // 返回15x15的爱心图案（与HeartGridViewController相同）
    private func getHeartPattern() -> [[Bool]] {
        return [
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, true,  true,  true,  false, false, false, true,  true,  true,  false, false, false, false],
            [false, true,  true,  true,  true,  true,  false, true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, false, true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false],
            [false, false, false, false, true,  true,  true,  true,  true,  false, false, false, false, false, false],
            [false, false, false, false, false, true,  true,  true,  false, false, false, false, false, false, false],
            [false, false, false, false, false, false, true,  false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
        ]
    }
}

// I LOVE U 格子视图 - 用于热门动画封面
class ILoveUView: UIView {
    
    private var gridSize: CGFloat = 12  // 封面用格子大小与红心封面保持一致
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
        // 启动动画定时器（封面版本更慢）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func updateAnimation() {
        // 随机更新背景格子透明度（封面版本更温和）
        for row in 0..<backgroundGridAlphas.count {
            for col in 0..<backgroundGridAlphas[row].count {
                // 8% 的概率改变透明度
                if Float.random(in: 0...1) < 0.08 {
                    backgroundGridAlphas[row][col] = CGFloat.random(in: 0.4...1.0)
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
        
        // 确保rect有有效的尺寸
        guard rect.width > 0 && rect.height > 0 else { return }
        
        // 计算能容纳多少行列的格子（填充满整个封面）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 确保至少有最小的网格数量
        cols = max(cols, 10)
        rows = max(rows, 8)
        
        // 定义爱心形状（15x15网格，与HeartGridView一致）
        let heartPattern = getHeartPattern()
        let heartRows = heartPattern.count
        let heartCols = heartPattern[0].count
        
        // 如果网格太小无法容纳内容，调整格子大小（与HeartGridView逻辑一致）
        if rows < heartRows || cols < heartCols + 4 { // 需要额外空间放置I和U
            let maxGridSizeForHeight = rect.height / CGFloat(heartRows + 2)
            let maxGridSizeForWidth = rect.width / CGFloat(heartCols + 6) // 为I和U留出空间
            gridSize = min(maxGridSizeForHeight, maxGridSizeForWidth, 12) // 最大不超过12px，与红心封面保持一致
            gridSize = max(gridSize, 4) // 最小4px，与红心封面保持一致
            
            // 重新计算行列数
            cols = Int((rect.width + spacing) / (gridSize + spacing))
            rows = Int((rect.height + spacing) / (gridSize + spacing))
            cols = max(cols, heartCols + 4)
            rows = max(rows, heartRows)
        }
        
        // 初始化背景格子透明度数组（如果需要）
        if backgroundGridAlphas.count != rows || (backgroundGridAlphas.first?.count ?? 0) != cols {
            backgroundGridAlphas = Array(repeating: Array(repeating: CGFloat.random(in: 0.4...1.0), count: cols), count: rows)
        }
        
        // 计算实际的网格总尺寸
        let totalGridWidth = CGFloat(cols) * gridSize + CGFloat(cols - 1) * spacing
        let totalGridHeight = CGFloat(rows) * gridSize + CGFloat(rows - 1) * spacing
        
        // 计算起始位置以居中显示
        let startX = (rect.width - totalGridWidth) / 2
        let startY = (rect.height - totalGridHeight) / 2
        
        // 计算爱心在网格中的真正居中位置
        let exactHeartStartRow = (Double(rows) - Double(heartRows)) / 2.0
        let exactHeartStartCol = (Double(cols) - Double(heartCols)) / 2.0
        
        let centeredHeartStartRow = Int(exactHeartStartRow.rounded())
        let centeredHeartStartCol = Int(exactHeartStartCol.rounded())
        
        // 获取字母I和U的图案（封面版本较小）
        let letterI = getLetterIPattern()
        let letterU = getLetterUPattern()
        
        // 计算字母I的位置（爱心左边，调整距离适应15x15爱心）
        let iStartRow = centeredHeartStartRow + (heartRows - letterI.count) / 2
        let iStartCol = max(0, centeredHeartStartCol - 2) // 调整为2格距离
        
        // 计算字母U的位置（爱心右边，调整距离适应15x15爱心）
        let uStartRow = centeredHeartStartRow + (heartRows - letterU.count) / 2
        let uStartCol = min(cols - letterU[0].count, centeredHeartStartCol + heartCols + 1) // 调整为1格距离
        
        // 绘制所有格子
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: gridSize * 0.25)
                
                var isRedGrid = false
                
                // 判断是否在爱心图案内
                let heartRow = row - centeredHeartStartRow
                let heartCol = col - centeredHeartStartCol
                if heartRow >= 0 && heartRow < heartRows && heartCol >= 0 && heartCol < heartCols {
                    isRedGrid = heartPattern[heartRow][heartCol]
                }
                
                // 判断是否在字母I内
                let iRow = row - iStartRow
                let iCol = col - iStartCol
                if iRow >= 0 && iRow < letterI.count && iCol >= 0 && iCol < letterI[0].count {
                    isRedGrid = isRedGrid || letterI[iRow][iCol]
                }
                
                // 判断是否在字母U内
                let uRow = row - uStartRow
                let uCol = col - uStartCol
                if uRow >= 0 && uRow < letterU.count && uCol >= 0 && uCol < letterU[0].count {
                    isRedGrid = isRedGrid || letterU[uRow][uCol]
                }
                
                if isRedGrid {
                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    path.fill()
                    
                    // 静态发光效果（封面版本较温和）
                    let glowRadius = gridSize * 0.4
                    let glowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -glowRadius, dy: -glowRadius), 
                                               cornerRadius: gridSize * 0.25 + glowRadius)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.3).setFill()
                    glowPath.fill()
                } else {
                    // 未点亮的格子：暗蓝色带随机闪烁效果
                    let alpha = backgroundGridAlphas[row][col]
                    UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // 返回15x15的爱心图案（与HeartGridView保持一致）
    private func getHeartPattern() -> [[Bool]] {
        return [
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, true,  true,  false, false, false, true,  true,  false, false, false, false, false],
            [false, false, true,  true,  true,  true,  false, true,  true,  true,  true,  false, false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false],
            [false, false, false, true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false],
            [false, false, false, false, true,  true,  true,  true,  true,  false, false, false, false, false, false],
            [false, false, false, false, false, true,  true,  true,  false, false, false, false, false, false, false],
            [false, false, false, false, false, false, true,  false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false],
            [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
        ]
    }
    
    // 字母I的图案（高度与爱心协调）
    private func getLetterIPattern() -> [[Bool]] {
        return [
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true],
            [true]
        ]
    }
    
    // 字母U的图案（圆角矩形样式，无上边）
    private func getLetterUPattern() -> [[Bool]] {
        return [
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [true,  false, false, false, true],
            [false, true,  false, true,  false],
            [false, true,  true,  true,  false]
        ]
    }
}

// 520封面视图 - 用于热门动画封面
class View520: UIView {
    
    private var gridSize: CGFloat = 6  // 封面用更小的格子，让520数字看起来密集一些
    private var spacing: CGFloat = 2.0
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
        // 启动动画定时器（封面版本更慢）
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func updateAnimation() {
        // 随机更新背景格子透明度（封面版本更温和）
        for row in 0..<backgroundGridAlphas.count {
            for col in 0..<backgroundGridAlphas[row].count {
                // 8% 的概率改变透明度
                if Float.random(in: 0...1) < 0.08 {
                    backgroundGridAlphas[row][col] = CGFloat.random(in: 0.4...1.0)
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
        
        // 确保rect有有效的尺寸
        guard rect.width > 0 && rect.height > 0 else { return }
        
        // 计算能容纳多少行列的格子（填充满整个封面）
        cols = Int((rect.width + spacing) / (gridSize + spacing))
        rows = Int((rect.height + spacing) / (gridSize + spacing))
        
        // 确保至少有最小的网格数量
        cols = max(cols, 10)
        rows = max(rows, 8)
        
        // 定义520数字图案
        let digit5 = getDigit5Pattern()
        let digit2 = getDigit2Pattern()
        let digit0 = getDigit0Pattern()
        
        let digitRows = digit5.count
        let digitCols = digit5[0].count
        
        // 强制使用固定的小格子尺寸，不进行自动放大（与红心封面保持一致）
        // 不再根据内容大小调整格子尺寸，保持12px的固定尺寸
        
        // 初始化背景格子透明度数组（如果需要）
        if backgroundGridAlphas.count != rows || (backgroundGridAlphas.first?.count ?? 0) != cols {
            backgroundGridAlphas = Array(repeating: Array(repeating: CGFloat.random(in: 0.4...1.0), count: cols), count: rows)
        }
        
        // 计算实际的网格总尺寸
        let totalGridWidth = CGFloat(cols) * gridSize + CGFloat(cols - 1) * spacing
        let totalGridHeight = CGFloat(rows) * gridSize + CGFloat(rows - 1) * spacing
        
        // 计算起始位置以居中显示
        let startX = (rect.width - totalGridWidth) / 2
        let startY = (rect.height - totalGridHeight) / 2
        
        // 计算520在网格中的居中位置
        let totalDigitWidth = digitCols * 3 + 4 // 3个数字 + 间距(2+2格)
        let exactDigitStartRow = (Double(rows) - Double(digitRows)) / 2.0
        let exactDigitStartCol = (Double(cols) - Double(totalDigitWidth)) / 2.0
        
        let centeredDigitStartRow = Int(exactDigitStartRow.rounded())
        let centeredDigitStartCol = Int(exactDigitStartCol.rounded())
        
        // 计算每个数字的起始列
        let digit5StartCol = centeredDigitStartCol
        let digit2StartCol = digit5StartCol + digitCols + 2 // 5后面加2格间距
        let digit0StartCol = digit2StartCol + digitCols + 2 // 2后面加2格间距
        
        // 绘制所有格子
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (gridSize + spacing)
                let y = startY + CGFloat(row) * (gridSize + spacing)
                
                let rect = CGRect(x: x, y: y, width: gridSize, height: gridSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: gridSize * 0.25)
                
                var isRedGrid = false
                
                // 判断是否在数字5内
                let digitRow = row - centeredDigitStartRow
                let digit5Col = col - digit5StartCol
                if digitRow >= 0 && digitRow < digitRows && digit5Col >= 0 && digit5Col < digitCols {
                    isRedGrid = digit5[digitRow][digit5Col]
                }
                
                // 判断是否在数字2内
                let digit2Col = col - digit2StartCol
                if digitRow >= 0 && digitRow < digitRows && digit2Col >= 0 && digit2Col < digitCols {
                    isRedGrid = isRedGrid || digit2[digitRow][digit2Col]
                }
                
                // 判断是否在数字0内
                let digit0Col = col - digit0StartCol
                if digitRow >= 0 && digitRow < digitRows && digit0Col >= 0 && digit0Col < digitCols {
                    isRedGrid = isRedGrid || digit0[digitRow][digit0Col]
                }
                
                if isRedGrid {
                    // 点亮的格子：亮红色带静态发光效果
                    let baseColor = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
                    baseColor.setFill()
                    path.fill()
                    
                    // 静态发光效果（封面版本较温和）
                    let glowRadius = gridSize * 0.4
                    let glowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -glowRadius, dy: -glowRadius), 
                                               cornerRadius: gridSize * 0.25 + glowRadius)
                    UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 0.3).setFill()
                    glowPath.fill()
                } else {
                    // 未点亮的格子：暗蓝色带随机闪烁效果
                    let alpha = backgroundGridAlphas[row][col]
                    UIColor(red: 0.15, green: 0.22, blue: 0.35, alpha: alpha).setFill()
                    path.fill()
                }
            }
        }
    }
    
    // 数字5的图案（7x4网格 - 封面优化版本）
    private func getDigit5Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true],
            [true,  false, false, false],
            [true,  false, false, false],
            [true,  true,  true,  true],
            [false, false, false, true],
            [false, false, false, true],
            [true,  true,  true,  true]
        ]
    }
    
    // 数字2的图案（7x4网格 - 封面优化版本）
    private func getDigit2Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true],
            [false, false, false, true],
            [false, false, false, true],
            [true,  true,  true,  true],
            [true,  false, false, false],
            [true,  false, false, false],
            [true,  true,  true,  true]
        ]
    }
    
    // 数字0的图案（7x4网格 - 封面优化版本）
    private func getDigit0Pattern() -> [[Bool]] {
        return [
            [true,  true,  true,  true],
            [true,  false, false, true],
            [true,  false, false, true],
            [true,  false, false, true],
            [true,  false, false, true],
            [true,  false, false, true],
            [true,  true,  true,  true]
        ]
    }
}

// 爱心流星雨封面视图
class LoveRainCoverView: UIView {
    
    private var animationTimer: Timer?
    private var hearts: [HeartParticle] = []
    
    struct HeartParticle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var alpha: CGFloat
        var speed: CGFloat
    }
    
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
        // 创建初始爱心粒子
        createHearts()
        
        // 启动动画定时器
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func createHearts() {
        hearts.removeAll()
        
        // 创建多个爱心粒子
        for _ in 0..<8 {
            let heart = HeartParticle(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: -50...bounds.height),
                size: CGFloat.random(in: 8...16),
                alpha: CGFloat.random(in: 0.3...0.8),
                speed: CGFloat.random(in: 1...3)
            )
            hearts.append(heart)
        }
    }
    
    private func updateAnimation() {
        // 更新爱心位置
        for i in 0..<hearts.count {
            hearts[i].y += hearts[i].speed
            
            // 如果爱心超出底部，重新从顶部开始
            if hearts[i].y > bounds.height + 20 {
                hearts[i].y = -20
                hearts[i].x = CGFloat.random(in: 0...bounds.width)
                hearts[i].size = CGFloat.random(in: 8...16)
                hearts[i].alpha = CGFloat.random(in: 0.3...0.8)
                hearts[i].speed = CGFloat.random(in: 1...3)
            }
        }
        
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 如果bounds发生变化，重新创建爱心
        if hearts.isEmpty || bounds.width != rect.width || bounds.height != rect.height {
            createHearts()
        }
        
        // 绘制爱心粒子
        for heart in hearts {
            drawHeart(at: CGPoint(x: heart.x, y: heart.y), size: heart.size, alpha: heart.alpha)
        }
        
        // 在中心绘制"I LOVE U"文字
        drawCenterText(in: rect)
    }
    
    private func drawHeart(at center: CGPoint, size: CGFloat, alpha: CGFloat) {
        let path = UIBezierPath()
        let heartSize = size
        
        // 简化的爱心形状
        path.move(to: CGPoint(x: center.x, y: center.y + heartSize * 0.3))
        
        path.addCurve(
            to: CGPoint(x: center.x - heartSize * 0.4, y: center.y - heartSize * 0.2),
            controlPoint1: CGPoint(x: center.x - heartSize * 0.4, y: center.y + heartSize * 0.1),
            controlPoint2: CGPoint(x: center.x - heartSize * 0.4, y: center.y - heartSize * 0.1)
        )
        
        path.addArc(
            withCenter: CGPoint(x: center.x - heartSize * 0.2, y: center.y - heartSize * 0.2),
            radius: heartSize * 0.2,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        path.addArc(
            withCenter: CGPoint(x: center.x + heartSize * 0.2, y: center.y - heartSize * 0.2),
            radius: heartSize * 0.2,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + heartSize * 0.3),
            controlPoint1: CGPoint(x: center.x + heartSize * 0.4, y: center.y - heartSize * 0.1),
            controlPoint2: CGPoint(x: center.x + heartSize * 0.4, y: center.y + heartSize * 0.1)
        )
        
        path.close()
        
        // 设置粉色并绘制
        UIColor(red: 1.0, green: 0.5, blue: 0.75, alpha: alpha).setFill()
        path.fill()
    }
    
    private func drawCenterText(in rect: CGRect) {
        let text = "I   LOVE   U"  // 增加单词间距
        let fontSize: CGFloat = min(rect.width, rect.height) * 0.3
        let font = UIFont.systemFont(ofSize: fontSize, weight: .black)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 1.0, green: 0.5, blue: 0.75, alpha: 0.8)
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
}

// 烟花封面视图
class FireworksCoverView: UIView {
    
    private var animationTimer: Timer?
    private var particles: [FireworkParticle] = []
    
    struct FireworkParticle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var alpha: CGFloat
        var color: UIColor
    }
    
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
        // 创建初始烟花粒子
        createParticles()
        
        // 启动动画定时器
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func createParticles() {
        particles.removeAll()
        
        // 创建多个烟花粒子
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),  // 红色
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),  // 金色
            UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0),  // 蓝色
            UIColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 1.0)   // 粉色
        ]
        
        for _ in 0..<12 {
            let particle = FireworkParticle(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height),
                size: CGFloat.random(in: 4...8),
                alpha: CGFloat.random(in: 0.5...1.0),
                color: colors.randomElement() ?? .white
            )
            particles.append(particle)
        }
    }
    
    private func updateAnimation() {
        // 随机改变粒子透明度（闪烁效果）
        for i in 0..<particles.count {
            if Float.random(in: 0...1) < 0.3 {
                particles[i].alpha = CGFloat.random(in: 0.3...1.0)
            }
        }
        
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 如果bounds发生变化，重新创建粒子
        if particles.isEmpty || bounds.width != rect.width || bounds.height != rect.height {
            createParticles()
        }
        
        // 绘制烟花粒子
        for particle in particles {
            let particleRect = CGRect(
                x: particle.x - particle.size / 2,
                y: particle.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            
            let path = UIBezierPath(ovalIn: particleRect)
            particle.color.withAlphaComponent(particle.alpha).setFill()
            path.fill()
            
            // 添加发光效果
            let glowPath = UIBezierPath(ovalIn: particleRect.insetBy(dx: -particle.size * 0.5, dy: -particle.size * 0.5))
            particle.color.withAlphaComponent(particle.alpha * 0.3).setFill()
            glowPath.fill()
        }
    }
}

// 烟花绽放封面视图
class FireworksBloomCoverView: UIView {
    
    private var animationTimer: Timer?
    private var particles: [BloomParticle] = []
    
    struct BloomParticle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var alpha: CGFloat
        var color: UIColor
    }
    
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
        // 创建初始粒子
        createParticles()
        
        // 启动动画定时器
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func createParticles() {
        particles.removeAll()
        
        // 创建多个烟花绽放粒子（更密集）
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),  // 红色
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),  // 金色
            UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0),  // 蓝色
            UIColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 1.0),  // 粉色
            UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)   // 绿色
        ]
        
        for _ in 0..<20 {
            let particle = BloomParticle(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height),
                size: CGFloat.random(in: 3...6),
                alpha: CGFloat.random(in: 0.5...1.0),
                color: colors.randomElement() ?? .white
            )
            particles.append(particle)
        }
    }
    
    private func updateAnimation() {
        // 随机改变粒子透明度（闪烁效果）
        for i in 0..<particles.count {
            if Float.random(in: 0...1) < 0.4 {
                particles[i].alpha = CGFloat.random(in: 0.3...1.0)
            }
        }
        
        setNeedsDisplay()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 如果bounds发生变化，重新创建粒子
        if particles.isEmpty || bounds.width != rect.width || bounds.height != rect.height {
            createParticles()
        }
        
        // 绘制烟花粒子
        for particle in particles {
            let particleRect = CGRect(
                x: particle.x - particle.size / 2,
                y: particle.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            
            let path = UIBezierPath(ovalIn: particleRect)
            particle.color.withAlphaComponent(particle.alpha).setFill()
            path.fill()
            
            // 添加发光效果
            let glowPath = UIBezierPath(ovalIn: particleRect.insetBy(dx: -particle.size * 0.5, dy: -particle.size * 0.5))
            particle.color.withAlphaComponent(particle.alpha * 0.3).setFill()
            glowPath.fill()
        }
    }
}

// 模版分类
enum TemplateCategory: String, CaseIterable {
    case neon = "霓虹灯看板"
    case idol = "偶像应援"
    case ledScreen = "LED横幅"
    case popularAnimation = "热门动画"
    case clock = "数字时钟"
    case other = "其他分类"
    
    var localizedName: String {
        switch self {
        case .neon: return "neon".localized
        case .idol: return "idol".localized
        case .ledScreen: return "led".localized
        case .popularAnimation: return "popularAnimation".localized
        case .clock: return "clock".localized
        case .other: return "other".localized
        }
    }
    
    var titleColor: UIColor {
        switch self {
        case .neon:
            return UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0) // #8EFFE6
        case .idol:
            return UIColor(red: 0xFF/255.0, green: 0x6B/255.0, blue: 0xD6/255.0, alpha: 1.0) // #FF6BD6
        case .ledScreen:
            return UIColor(red: 0x6B/255.0, green: 0xFF/255.0, blue: 0xB0/255.0, alpha: 1.0) // #6BFFB0
        case .popularAnimation:
            return UIColor(red: 0xFF/255.0, green: 0x69/255.0, blue: 0xB4/255.0, alpha: 1.0) // #FF69B4 粉红色
        case .clock, .other:
            return .white
        }
    }
}

// Tab类型
enum TemplateTab: String {
    case popular = "热门模版"
    case animation = "动画模版"
    
    var localizedName: String {
        switch self {
        case .popular: return "popular".localized
        case .animation: return "animation".localized
        }
    }
}

// 模版广场视图控制器
class TemplateSquareViewController: UIViewController {
    
    private var tableView: UITableView!
    private var categories: [TemplateCategory] = []
    private var currentTab: TemplateTab = .popular
    private lazy var segmentedControl: UISegmentedControl = {
        let items = [TemplateTab.popular.localizedName, TemplateTab.animation.localizedName]
        return UISegmentedControl(items: items)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateCategories()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 强制恢复竖屏
        AppDelegate.orientationLock = .portrait
        
        // 刷新UI以应用语言更改
        refreshUI()
        
        // 强制刷新布局，修复从横屏返回后卡片尺寸异常的问题
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 确保分段控制器是胶囊形状（圆角为高度的一半）
        if segmentedControl.bounds.height > 0 {
            segmentedControl.layer.cornerRadius = segmentedControl.bounds.height / 2
            segmentedControl.layer.masksToBounds = true
        }
    }
    
    private func updateCategories() {
        switch currentTab {
        case .popular:
            // 热门模版：霓虹灯看板、偶像应援、LED横幅
            categories = [.neon, .idol, .ledScreen]
        case .animation:
            // 动画模版：热门动画、数字时钟、其他分类
            categories = [.popularAnimation, .clock, .other]
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1) // 纯黑背景
        
        // 隐藏导航栏标题
        title = ""
        
        // 设置导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground() // 改为透明背景
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // 设置分段控制器 - 放在导航栏标题位置
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        // 自定义分段控制器样式 - 简单的胶囊背景 + 文字
        segmentedControl.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1) // 深色胶囊背景
        
        if #available(iOS 13.0, *) {
            // iOS 13+ 使用新的API
            // 选中背景颜色（青色胶囊）
            segmentedControl.selectedSegmentTintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        } else {
            // iOS 12 及以下
            segmentedControl.tintColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0)
        }
        
        // 未选中状态：白色半透明文字
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ], for: .normal)
        
        // 选中状态：黑色文字
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .selected)
        
        // 将分段控制器设置为导航栏的titleView
        navigationItem.titleView = segmentedControl
        
        // 设置分段控制器的固定尺寸（增加高度以显示内边距效果）
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.widthAnchor.constraint(equalToConstant: 220),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40) // 从36增加到40，让选中背景看起来有内边距
        ])
        
        // 创建表格视图
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TemplateCategoryCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.contentInset = UIEdgeInsets(top: 18, left: 0, bottom: 20, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            // 表格视图直接从顶部开始
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func segmentChanged() {
        currentTab = segmentedControl.selectedSegmentIndex == 0 ? .popular : .animation
        updateCategories()
        tableView.reloadData()
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    private func refreshUI() {
        // 更新分段控制器的标题
        segmentedControl.setTitle(TemplateTab.popular.localizedName, forSegmentAt: 0)
        segmentedControl.setTitle(TemplateTab.animation.localizedName, forSegmentAt: 1)
        
        // 刷新表格视图以更新分类标题
        tableView.reloadData()
    }
    
    func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.numberOfLines = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            toast.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        toast.alpha = 0
        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.3, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}

// MARK: - UITableViewDelegate & DataSource
extension TemplateSquareViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! TemplateCategoryCell
        let category = categories[indexPath.section]
        cell.configure(with: category, tab: currentTab)
        cell.onItemTapped = { [weak self] item in
            self?.handleItemTap(item)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let category = categories[indexPath.section]
        // 根据不同分类的卡片数量计算高度
        switch category {
        case .clock:
            // 时钟分类只有1个卡片
            return 220
        case .popularAnimation:
            // 热门动画分类有6个卡片，需要3行（2+2+2）
            return 574 // 减少高度，紧凑布局
        default:
            // 其他分类有4个卡片（2行×2列）
            return 374 // 减少高度，紧凑布局
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let category = categories[section]
        
        // 如果是热门动画分类，添加火焰图标
        if category == .popularAnimation {
            // 创建火焰图标视图（使用渐变色）
            let fireIconView = UIView()
            fireIconView.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(fireIconView)
            
            // 创建火焰emoji标签
            let fireLabel = UILabel()
            fireLabel.text = "🔥"
            fireLabel.font = .systemFont(ofSize: 20)
            fireLabel.translatesAutoresizingMaskIntoConstraints = false
            fireIconView.addSubview(fireLabel)
            
            // 标题文字
            let label = UILabel()
            label.text = category.localizedName
            label.textColor = UIColor.white.withAlphaComponent(0.9)
            label.font = .systemFont(ofSize: 18, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                fireIconView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                fireIconView.topAnchor.constraint(equalTo: headerView.topAnchor),
                fireIconView.widthAnchor.constraint(equalToConstant: 24),
                fireIconView.heightAnchor.constraint(equalToConstant: 24),
                
                fireLabel.centerXAnchor.constraint(equalTo: fireIconView.centerXAnchor),
                fireLabel.centerYAnchor.constraint(equalTo: fireIconView.centerYAnchor),
                
                label.leadingAnchor.constraint(equalTo: fireIconView.trailingAnchor, constant: 8),
                label.topAnchor.constraint(equalTo: headerView.topAnchor)
            ])
        } else {
            // 其他分类：标题文字（去掉图标）
            let label = UILabel()
            label.text = category.localizedName
            label.textColor = UIColor.white.withAlphaComponent(0.9) // 白色 0.9透明度
            label.font = .systemFont(ofSize: 18, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
                label.topAnchor.constraint(equalTo: headerView.topAnchor)
            ])
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36 // 所有模块统一36px（文字高度20px + 文字到卡片间距16px）
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10 // 模块间距10px
    }
    
    private func handleItemTap(_ item: LEDItem) {
        // 特殊效果直接跳转
        if item.isHeartGrid {
            // 爱心格子：跳转到爱心格子全屏预览
            AppDelegate.orientationLock = .landscape
            let heartGridVC = HeartGridViewController()
            heartGridVC.modalPresentationStyle = .fullScreen
            present(heartGridVC, animated: true)
        } else if item.isILoveU {
            // I LOVE U：跳转到I LOVE U全屏预览
            AppDelegate.orientationLock = .landscape
            let iLoveUVC = ILoveUViewController()
            iLoveUVC.modalPresentationStyle = .fullScreen
            present(iLoveUVC, animated: true)
        } else if item.is520 {
            // 520：跳转到520全屏预览
            AppDelegate.orientationLock = .landscape
            let view520VC = View520ViewController()
            view520VC.modalPresentationStyle = .fullScreen
            present(view520VC, animated: true)
        } else if item.isLoveRain {
            // 爱心流星雨：跳转到爱心雨动画
            AppDelegate.orientationLock = .landscape
            let loveRainVC = LoveRainViewController()
            loveRainVC.modalPresentationStyle = .fullScreen
            present(loveRainVC, animated: true)
        } else if item.isFlipClock {
            AppDelegate.orientationLock = .landscape
            let clockVC = FlipClockViewController()
            clockVC.modalPresentationStyle = .fullScreen
            present(clockVC, animated: true)
        } else if item.isFireworksBloom {
            let fireworksVC = FireworksBloomViewController()
            fireworksVC.modalPresentationStyle = .fullScreen
            present(fireworksVC, animated: true)
        } else if item.isFireworks {
            let fireworksVC = FireworksViewController()
            fireworksVC.modalPresentationStyle = .fullScreen
            present(fireworksVC, animated: true)
        } else if currentTab == .popular && (item.isNeonTemplate || item.isIdolTemplate || item.isLEDTemplate) {
            // 热门模版：点击封面直接进入全屏预览（无按钮）
            AppDelegate.orientationLock = .landscape
            let displayVC = LEDFullScreenViewController(ledItem: item)
            displayVC.modalPresentationStyle = .fullScreen
            present(displayVC, animated: true)
        } else {
            // 其他：普通LED卡片直接全屏预览
            AppDelegate.orientationLock = .landscape
            let displayVC = LEDFullScreenViewController(ledItem: item)
            displayVC.modalPresentationStyle = .fullScreen
            present(displayVC, animated: true)
        }
    }
}

// MARK: - 模版分类Cell
class TemplateCategoryCell: UITableViewCell {
    
    private var collectionView: UICollectionView!
    private var items: [LEDItem] = []
    private var currentTab: TemplateTab = .popular
    var onItemTapped: ((LEDItem) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 强制刷新CollectionView布局，修复从横屏返回后尺寸异常的问题
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TemplateItemCell.self, forCellWithReuseIdentifier: "ItemCell")
        collectionView.isScrollEnabled = false
        collectionView.clipsToBounds = false // 关闭裁剪，让底部卡片完全显示
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with category: TemplateCategory, tab: TemplateTab) {
        currentTab = tab
        items = getItems(for: category)
        collectionView.reloadData()
    }
    
    private func getItems(for category: TemplateCategory) -> [LEDItem] {
        let allItems = LEDDataManager.shared.loadItems()
        
        switch category {
        case .popularAnimation:
            // 返回热门动画：爱心格子、爱心雨、烟花、烟花绽放
            var items: [LEDItem] = []
            
            // 爱心格子（新增的第一个卡片）
            var heartGridItem = LEDItem(
                id: "heart-grid-animation",
                text: "红心",
                fontSize: 80,
                textColor: "#FF3366",
                backgroundColor: "#1a1a2e",
                glowIntensity: 5.0
            )
            // 标记为特殊的爱心格子动画
            heartGridItem.isHeartGrid = true
            items.append(heartGridItem)
            
            // I LOVE U（新增的第二个卡片）
            var iLoveUItem = LEDItem(
                id: "i-love-u-animation",
                text: "I LOVE U",
                fontSize: 80,
                textColor: "#FF3366",
                backgroundColor: "#1a1a2e",
                glowIntensity: 5.0
            )
            // 标记为特殊的I LOVE U动画
            iLoveUItem.isILoveU = true
            items.append(iLoveUItem)
            
            // 520（新增的第三个卡片）
            var item520 = LEDItem(
                id: "520-animation",
                text: "520",
                fontSize: 80,
                textColor: "#FF3366",
                backgroundColor: "#1a1a2e",
                glowIntensity: 5.0
            )
            // 标记为特殊的520动画
            item520.is520 = true
            items.append(item520)
            
            // 爱心雨
            if let loveRainItem = allItems.first(where: { $0.isLoveRain }) {
                items.append(loveRainItem)
            }
            
            // 烟花
            if let fireworksItem = allItems.first(where: { $0.isFireworks }) {
                items.append(fireworksItem)
            }
            
            // 烟花绽放
            if let fireworksBloomItem = allItems.first(where: { $0.isFireworksBloom }) {
                items.append(fireworksBloomItem)
            }
            
            return items
        case .clock:
            // 返回翻页时钟和占位符
            var items = allItems.filter { $0.isFlipClock }
            // 如果没有时钟，创建占位符
            if items.isEmpty {
                let clockItem = LEDItem(
                    id: "clock-placeholder",
                    text: "数字时钟",
                    fontSize: 50,
                    textColor: "#8EFFE6",
                    backgroundColor: "#1a1a2e",
                    glowIntensity: 3.0
                )
                items.append(clockItem)
            }
            return items
        case .other:
            // 返回预设卡片 + 用户创建的卡片
            let presetItems = allItems.filter { $0.isDefaultPreset }
            let userItems = allItems.filter { 
                !$0.isFlipClock && !$0.isNeonTemplate && !$0.isIdolTemplate && 
                !$0.isLEDTemplate && !$0.isDefaultPreset && 
                !$0.isFireworks && !$0.isFireworksBloom && !$0.isLoveRain
            }
            // 预设卡片在前，用户创建的在后
            return presetItems + userItems
        case .neon:
            // 霓虹灯看板模版（占位）- 改为4个
            return createPlaceholderItems(category: "neon", count: 4)
        case .idol:
            // 偶像应援模版（占位）- 改为4个
            return createPlaceholderItems(category: "idol", count: 4)
        case .ledScreen:
            // LED屏幕模版（占位）- 改为4个
            return createPlaceholderItems(category: "led", count: 4)
        }
    }
    
    private func createPlaceholderItems(category: String, count: Int) -> [LEDItem] {
        var items: [LEDItem] = []
        
        // 定义每个分类的文字内容
        let texts: [String]
        switch category {
        case "neon":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        case "idol":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        case "led":
            texts = ["Drink Juice", "Dance party!", "Nice Day", "party hard"]
        default:
            texts = ["TEXT 1", "TEXT 2", "TEXT 3", "TEXT 4"]
        }
        
        // 根据分类设置不同的滚动类型
        let scrollType: LEDItem.ScrollType
        let speed: Double
        switch category {
        case "neon", "idol":
            // 霓虹灯和偶像屏幕：使用闪烁效果
            scrollType = .blink
            speed = 0.5 // 闪烁速度（更快）
        case "led":
            // LED屏幕：从右到左滚动
            scrollType = .scrollLeft
            speed = 2.0 // 滚动速度
        default:
            scrollType = .none
            speed = 1.5
        }
        
        for i in 1...count {
            let text = i <= texts.count ? texts[i - 1] : "TEXT \(i)"
            let imageName = "\(category)_\(i)" // 例如：neon_1, idol_2, led_3
            let item = LEDItem(
                id: "\(category)-\(i)",
                text: text,
                fontSize: 120, // 进一步增加字体大小到120pt，全屏预览更醒目
                textColor: "#FFFFFF", // 白色
                backgroundColor: "#1a1a2e",
                backgroundImageName: imageName, // 添加背景图片
                glowIntensity: 3.0,
                scrollType: scrollType,
                speed: speed,
                fontName: "PingFangSC-Semibold" // 设置为粗体字体
            )
            items.append(item)
        }
        return items
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension TemplateCategoryCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! TemplateItemCell
        let item = items[indexPath.item]
        cell.configure(with: item, tab: currentTab)
        
        if currentTab == .popular {
            // 热门模版：只有试用按钮
            cell.onTryTapped = { [weak self] item in
                // 试用：进入编辑页面
                guard let self = self else { return }
                if let parentVC = self.parentViewController as? TemplateSquareViewController {
                    let createVC = LEDCreateViewController(editingItem: item, isTemplateEdit: true)
                    createVC.onSave = {
                        parentVC.showToast(message: "saved".localized)
                    }
                    let nav = UINavigationController(rootViewController: createVC)
                    nav.modalPresentationStyle = .fullScreen
                    parentVC.present(nav, animated: true)
                }
            }
            
            cell.onPreviewTapped = { [weak self] item in
                // 点击封面：直接进入全屏预览（无按钮）
                self?.onItemTapped?(item)
            }
        } else {
            // 动画模版：点击封面直接进入对应效果
            cell.onPreviewTapped = { [weak self] item in
                self?.onItemTapped?(item)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 56) / 2 // 2列，左右各20，中间16
        return CGSize(width: width, height: width * 0.95) // 增加高度以容纳按钮
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 不再需要，因为点击由cell内部处理
    }
}

// MARK: - 模版项Cell
class TemplateItemCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let overlayTextLabel = UILabel() // 封面图片上的文字
    private let titleLabel = UILabel() // 卡片下方的标题（动画模版用）
    private let containerView = UIView()
    private let buttonStack = UIStackView() // 按钮容器
    private let tryButton = UIButton(type: .system) // 试用按钮
    private let previewButton = UIButton(type: .system) // 预览按钮
    private var currentItem: LEDItem?
    var onTryTapped: ((LEDItem) -> Void)?
    var onPreviewTapped: ((LEDItem) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 容器
        containerView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.18)
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = false // 改为false，避免裁剪底部内容
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 图片（16:9比例）
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        containerView.addSubview(imageView)
        
        // 添加点击手势到图片
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imageView.addGestureRecognizer(tapGesture)
        
        // 封面图片上的文字（霓虹效果）
        overlayTextLabel.textColor = .white
        overlayTextLabel.font = .systemFont(ofSize: 20, weight: .bold)
        overlayTextLabel.textAlignment = .center
        overlayTextLabel.numberOfLines = 2
        overlayTextLabel.adjustsFontSizeToFitWidth = true
        overlayTextLabel.minimumScaleFactor = 0.5
        overlayTextLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(overlayTextLabel)
        
        // 标题（动画模版用）
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 按钮容器
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStack)
        
        // 试用模版按钮（胶囊形状）
        tryButton.setTitle("try".localized, for: .normal)
        tryButton.setTitleColor(.white, for: .normal)
        tryButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        tryButton.backgroundColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 0.3)
        tryButton.layer.cornerRadius = 7 // 胶囊形状（高度14px的一半）
        tryButton.layer.masksToBounds = true
        tryButton.layer.borderWidth = 1
        tryButton.layer.borderColor = UIColor(red: 0x8E/255.0, green: 0xFF/255.0, blue: 0xE6/255.0, alpha: 1.0).cgColor
        tryButton.addTarget(self, action: #selector(tryButtonTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(tryButton)
        
        // 预览模版按钮（胶囊形状）
        previewButton.setTitle("preview".localized, for: .normal)
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        previewButton.backgroundColor = UIColor.systemPink.withAlphaComponent(0.3)
        previewButton.layer.cornerRadius = 7 // 胶囊形状（高度14px的一半）
        previewButton.layer.masksToBounds = true
        previewButton.layer.borderWidth = 1
        previewButton.layer.borderColor = UIColor.systemPink.cgColor
        previewButton.addTarget(self, action: #selector(previewButtonTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(previewButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 9),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -9),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0/16.0),
            
            overlayTextLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            overlayTextLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            overlayTextLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            overlayTextLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            buttonStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 18),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),
            buttonStack.heightAnchor.constraint(equalToConstant: 14) // 高度14px
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 确保按钮始终是胶囊形状（圆角为高度的一半）
        // 使用实际高度来计算，确保完美的胶囊形状
        if tryButton.bounds.height > 0 {
            tryButton.layer.cornerRadius = tryButton.bounds.height / 2
        }
        if previewButton.bounds.height > 0 {
            previewButton.layer.cornerRadius = previewButton.bounds.height / 2
        }
    }
    
    @objc private func imageTapped() {
        guard let item = currentItem else { return }
        onPreviewTapped?(item)
    }
    
    @objc private func tryButtonTapped() {
        guard let item = currentItem else { return }
        onTryTapped?(item)
    }
    
    @objc private func previewButtonTapped() {
        guard let item = currentItem else { return }
        onPreviewTapped?(item)
    }
    
    func configure(with item: LEDItem, tab: TemplateTab) {
        currentItem = item
        
        // 移除之前可能添加的所有自定义视图
        imageView.subviews.forEach { subview in
            if subview is HeartGridView || subview is ILoveUView || subview is View520 || subview is LoveRainCoverView || subview is FireworksCoverView || subview is FireworksBloomCoverView {
                subview.removeFromSuperview()
            }
        }
        
        // 如果是爱心格子动画，添加自定义视图
        if item.isHeartGrid {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
            
            let heartGridView = HeartGridView()
            heartGridView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(heartGridView)
            
            NSLayoutConstraint.activate([
                heartGridView.topAnchor.constraint(equalTo: imageView.topAnchor),
                heartGridView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                heartGridView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                heartGridView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            heartGridView.setNeedsLayout()
            heartGridView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                heartGridView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是I LOVE U动画，添加自定义视图
        if item.isILoveU {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
            
            let iLoveUView = ILoveUView()
            iLoveUView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(iLoveUView)
            
            NSLayoutConstraint.activate([
                iLoveUView.topAnchor.constraint(equalTo: imageView.topAnchor),
                iLoveUView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                iLoveUView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                iLoveUView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            iLoveUView.setNeedsLayout()
            iLoveUView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                iLoveUView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是爱心流星雨动画，添加自定义封面视图
        if item.isLoveRain {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景
            
            let loveRainCoverView = LoveRainCoverView()
            loveRainCoverView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(loveRainCoverView)
            
            NSLayoutConstraint.activate([
                loveRainCoverView.topAnchor.constraint(equalTo: imageView.topAnchor),
                loveRainCoverView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                loveRainCoverView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                loveRainCoverView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            loveRainCoverView.setNeedsLayout()
            loveRainCoverView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                loveRainCoverView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是520动画，添加自定义视图
        if item.is520 {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景突出格子闪烁效果
            
            let view520 = View520()
            view520.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(view520)
            
            NSLayoutConstraint.activate([
                view520.topAnchor.constraint(equalTo: imageView.topAnchor),
                view520.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                view520.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                view520.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            view520.setNeedsLayout()
            view520.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                view520.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是烟花动画，添加自定义封面视图
        if item.isFireworks {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景
            
            let fireworksCoverView = FireworksCoverView()
            fireworksCoverView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(fireworksCoverView)
            
            NSLayoutConstraint.activate([
                fireworksCoverView.topAnchor.constraint(equalTo: imageView.topAnchor),
                fireworksCoverView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                fireworksCoverView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                fireworksCoverView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            fireworksCoverView.setNeedsLayout()
            fireworksCoverView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                fireworksCoverView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        // 如果是烟花绽放动画，添加自定义封面视图
        if item.isFireworksBloom {
            imageView.image = nil
            imageView.backgroundColor = UIColor.black // 黑色背景
            
            let fireworksBloomCoverView = FireworksBloomCoverView()
            fireworksBloomCoverView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(fireworksBloomCoverView)
            
            NSLayoutConstraint.activate([
                fireworksBloomCoverView.topAnchor.constraint(equalTo: imageView.topAnchor),
                fireworksBloomCoverView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                fireworksBloomCoverView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                fireworksBloomCoverView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            // 强制立即布局，确保尺寸正确
            fireworksBloomCoverView.setNeedsLayout()
            fireworksBloomCoverView.layoutIfNeeded()
            
            // 延迟绘制，确保布局完成
            DispatchQueue.main.async {
                fireworksBloomCoverView.setNeedsDisplay()
            }
            
            // 隐藏文字标签
            overlayTextLabel.isHidden = true
        }
        
        if tab == .popular {
            // 热门模版：只显示试用按钮，隐藏预览按钮和标题
            // 特殊动画（爱心格子、I LOVE U、520、爱心流星雨、烟花、烟花绽放）不显示文字
            if !item.isHeartGrid && !item.isILoveU && !item.is520 && !item.isLoveRain && !item.isFireworks && !item.isFireworksBloom {
                overlayTextLabel.text = item.text
                overlayTextLabel.isHidden = false
            }
            titleLabel.isHidden = true
            buttonStack.isHidden = false
            tryButton.isHidden = false
            previewButton.isHidden = true
            
            // 调整按钮高度
            buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            buttonStack.addArrangedSubview(tryButton)
            
            // 强制立即布局并更新按钮圆角
            layoutIfNeeded()
            if tryButton.bounds.height > 0 {
                tryButton.layer.cornerRadius = tryButton.bounds.height / 2
            }
        } else {
            // 动画模版：显示标题，隐藏按钮和封面文字
            overlayTextLabel.isHidden = true
            titleLabel.text = item.text
            titleLabel.isHidden = false
            buttonStack.isHidden = true
        }
        
        // 封面图片上的文字添加霓虹效果
        overlayTextLabel.layer.shadowColor = UIColor(red: 255/255.0, green: 31/255.0, blue: 157/255.0, alpha: 0.75).cgColor
        overlayTextLabel.layer.shadowRadius = 20
        overlayTextLabel.layer.shadowOpacity = 1.0
        overlayTextLabel.layer.shadowOffset = .zero
        overlayTextLabel.layer.masksToBounds = false
        
        // 尝试加载图片，如果没有则使用占位颜色（特殊动画除外）
        if !item.isHeartGrid && !item.isILoveU && !item.is520 && !item.isLoveRain && !item.isFireworks && !item.isFireworksBloom {
            if let imageName = item.imageName, !imageName.isEmpty {
                imageView.image = UIImage(named: imageName)
            } else {
                // 使用占位颜色
                imageView.image = nil
                imageView.backgroundColor = UIColor(hex: item.backgroundColor)
            }
        }
    }
}

// LEDItem扩展：添加模版相关属性
extension LEDItem {
    var isNeonTemplate: Bool {
        return id.hasPrefix("neon-")
    }
    
    var isIdolTemplate: Bool {
        return id.hasPrefix("idol-")
    }
    
    var isLEDTemplate: Bool {
        return id.hasPrefix("led-")
    }
    
    var imageName: String? {
        // 图片命名规则：category_number.png
        // 例如：neon_1.png, idol_2.png, led_3.png, clock_1.png
        if isNeonTemplate {
            return "neon_\(id.replacingOccurrences(of: "neon-", with: ""))"
        } else if isIdolTemplate {
            return "idol_\(id.replacingOccurrences(of: "idol-", with: ""))"
        } else if isLEDTemplate {
            return "led_\(id.replacingOccurrences(of: "led-", with: ""))"
        } else if isFlipClock {
            // 翻页时钟使用 clock_1
            return "clock_1"
        }
        return nil
    }
}

// UIView扩展：获取父视图控制器
extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
