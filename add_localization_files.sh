#!/bin/bash

# LedScreen 多语言文件添加脚本
# 此脚本会打开Xcode项目，你需要手动添加文件

echo "========================================="
echo "LedScreen 多语言功能 - 文件添加助手"
echo "========================================="
echo ""

# 检查文件是否存在
echo "检查必要文件..."
if [ ! -f "LedScreen/LanguageManager.swift" ]; then
    echo "❌ 错误: LanguageManager.swift 不存在"
    exit 1
fi
echo "✅ LanguageManager.swift 存在"

# 检查本地化文件夹
LOCALIZATION_FOLDERS=(
    "zh-Hans.lproj"
    "zh-Hant.lproj"
    "ja.lproj"
    "ko.lproj"
    "es.lproj"
    "de.lproj"
    "fr.lproj"
    "pt.lproj"
    "it.lproj"
)

for folder in "${LOCALIZATION_FOLDERS[@]}"; do
    if [ ! -d "LedScreen/$folder" ]; then
        echo "❌ 错误: $folder 不存在"
        exit 1
    fi
    echo "✅ $folder 存在"
done

echo ""
echo "所有文件检查完成！"
echo ""
echo "========================================="
echo "接下来的步骤："
echo "========================================="
echo ""
echo "1. 打开Xcode项目"
echo "   正在打开..."
open LedScreen.xcodeproj

sleep 2

echo ""
echo "2. 添加 LanguageManager.swift"
echo "   - 在Xcode左侧，右键点击 'LedScreen' 文件夹"
echo "   - 选择 'Add Files to LedScreen...'"
echo "   - 选择: LedScreen/LanguageManager.swift"
echo "   - 确保勾选 'Copy items if needed'"
echo "   - 点击 'Add'"
echo ""
echo "3. 添加本地化文件夹"
echo "   对以下每个文件夹重复上述步骤："
for folder in "${LOCALIZATION_FOLDERS[@]}"; do
    echo "   - LedScreen/$folder/"
done
echo ""
echo "4. 配置项目本地化"
echo "   - 选择项目根节点（蓝色图标）"
echo "   - 在 PROJECT 设置 -> Info -> Localizations"
echo "   - 点击 '+' 添加所有语言"
echo ""
echo "5. 创建 Localizable.strings"
echo "   - 右键 'LedScreen' 文件夹 -> New File"
echo "   - 选择 'Strings File'"
echo "   - 命名为 'Localizable'"
echo "   - 在检查器中点击 'Localize...'"
echo "   - 勾选所有语言"
echo ""
echo "6. 清理并编译"
echo "   - Product -> Clean Build Folder (Shift + Cmd + K)"
echo "   - Product -> Build (Cmd + B)"
echo ""
echo "========================================="
echo "详细说明请查看: 多语言功能-修复编译错误指南.md"
echo "========================================="
