#!/bin/bash

# LedScreen 项目快速启动脚本
# 使用方法: ./open_project.sh

echo "🚀 LedScreen 项目启动器"
echo "===================="
echo ""

# 检查 Xcode 是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误: 未检测到 Xcode"
    echo "请先安装 Xcode: https://apps.apple.com/app/xcode/id497799835"
    exit 1
fi

echo "✅ Xcode 已安装"

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_PATH="$SCRIPT_DIR/LedScreen.xcodeproj"

# 检查项目文件是否存在
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ 错误: 未找到项目文件"
    echo "路径: $PROJECT_PATH"
    exit 1
fi

echo "✅ 项目文件已找到"
echo ""

# 显示项目信息
echo "📦 项目信息"
echo "-------------------"
echo "项目名称: LedScreen"
echo "项目路径: $PROJECT_PATH"
echo "最低版本: iOS 15.0+"
echo ""

# 询问用户操作
echo "请选择操作:"
echo "1) 打开项目"
echo "2) 清理并打开项目"
echo "3) 编译项目"
echo "4) 查看文档"
echo "5) 退出"
echo ""
read -p "请输入选项 (1-5): " choice

case $choice in
    1)
        echo ""
        echo "🔨 正在打开项目..."
        open "$PROJECT_PATH"
        echo "✅ 项目已在 Xcode 中打开"
        echo ""
        echo "💡 提示:"
        echo "1. 选择目标设备 (iPhone 14 Pro 模拟器)"
        echo "2. 点击 Run 按钮 (⌘R)"
        echo "3. 等待编译完成"
        ;;
    2)
        echo ""
        echo "🧹 正在清理项目..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/LedScreen-*
        echo "✅ 清理完成"
        echo ""
        echo "🔨 正在打开项目..."
        open "$PROJECT_PATH"
        echo "✅ 项目已在 Xcode 中打开"
        ;;
    3)
        echo ""
        echo "🔨 正在编译项目..."
        echo "目标: iPhone 14 Pro 模拟器"
        echo ""
        xcodebuild -project "$PROJECT_PATH" \
                   -scheme LedScreen \
                   -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
                   clean build
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ 编译成功!"
            echo ""
            echo "💡 下一步:"
            echo "运行: ./open_project.sh"
            echo "选择: 1) 打开项目"
        else
            echo ""
            echo "❌ 编译失败"
            echo "请检查 Xcode 版本和模拟器配置"
        fi
        ;;
    4)
        echo ""
        echo "📚 可用文档:"
        echo "-------------------"
        echo "1. README.md - 项目说明"
        echo "2. QUICKSTART.md - 快速开始"
        echo "3. ARCHITECTURE.md - 架构设计"
        echo "4. PROJECT_SUMMARY.md - 项目总结"
        echo "5. DEMO_GUIDE.md - 演示指南"
        echo "6. CHECKLIST.md - 检查清单"
        echo ""
        read -p "请输入要查看的文档编号 (1-6): " doc_choice
        
        case $doc_choice in
            1) open "$SCRIPT_DIR/README.md" ;;
            2) open "$SCRIPT_DIR/QUICKSTART.md" ;;
            3) open "$SCRIPT_DIR/ARCHITECTURE.md" ;;
            4) open "$SCRIPT_DIR/PROJECT_SUMMARY.md" ;;
            5) open "$SCRIPT_DIR/DEMO_GUIDE.md" ;;
            6) open "$SCRIPT_DIR/CHECKLIST.md" ;;
            *) echo "❌ 无效选项" ;;
        esac
        ;;
    5)
        echo ""
        echo "👋 再见!"
        exit 0
        ;;
    *)
        echo ""
        echo "❌ 无效选项"
        exit 1
        ;;
esac

echo ""
echo "🎉 完成!"
echo ""
echo "📖 更多帮助:"
echo "- 快速开始: cat QUICKSTART.md"
echo "- 项目文档: cat README.md"
echo "- 演示指南: cat DEMO_GUIDE.md"
echo ""
