#!/bin/bash

# 清理Xcode构建缓存和派生数据
echo "🧹 清理Xcode缓存..."

# 清理项目构建文件夹
if [ -d "build" ]; then
    rm -rf build
    echo "✅ 已删除 build 文件夹"
fi

# 清理DerivedData
DERIVED_DATA_PATH=~/Library/Developer/Xcode/DerivedData
if [ -d "$DERIVED_DATA_PATH" ]; then
    echo "🗑️  清理 DerivedData..."
    rm -rf "$DERIVED_DATA_PATH"
    echo "✅ 已清理 DerivedData"
fi

# 清理模块缓存
MODULE_CACHE_PATH=~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
if [ -d "$MODULE_CACHE_PATH" ]; then
    rm -rf "$MODULE_CACHE_PATH"
    echo "✅ 已清理模块缓存"
fi

echo ""
echo "✨ 清理完成！"
echo ""
echo "📝 接下来请执行以下步骤："
echo "1. 在Xcode中打开项目"
echo "2. 按 Cmd+Shift+K 清理项目"
echo "3. 按 Cmd+B 重新构建项目"
echo "4. 如果还有问题，请关闭Xcode后重新打开"
echo ""
