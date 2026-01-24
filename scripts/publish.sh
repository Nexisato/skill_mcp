#!/bin/bash
# 发布脚本 - 用于发布 skill-mcp-server 到 PyPI

set -e  # 遇到错误立即退出

echo "🚀 开始发布 skill-mcp-server 到 PyPI"

# 检查是否在正确的目录
if [ ! -f "pyproject.toml" ]; then
    echo "❌ 错误: 未找到 pyproject.toml，请在项目根目录运行此脚本"
    exit 1
fi

# 检查必要的工具
if ! command -v python &> /dev/null; then
    echo "❌ 错误: 未找到 python"
    exit 1
fi

# 读取版本号
VERSION=$(grep -E "^version\s*=" pyproject.toml | sed -E 's/.*version\s*=\s*"([^"]+)".*/\1/')
echo "📦 当前版本: $VERSION"

# 清理旧的构建文件
echo "🧹 清理旧的构建文件..."
rm -rf dist/ build/ *.egg-info .eggs/

# 构建分发包
echo "🔨 构建分发包..."
if command -v uv &> /dev/null; then
    echo "使用 uv 构建..."
    uv build
else
    echo "使用 python -m build 构建..."
    python -m build
fi

# 检查分发包
echo "✅ 检查分发包..."
# 尝试多种方式运行 twine
if command -v twine &> /dev/null; then
    twine check dist/*
elif python -m twine --version &> /dev/null 2>&1; then
    python -m twine check dist/*
elif command -v uv &> /dev/null && uv pip list 2>/dev/null | grep -q twine; then
    echo "⚠️  跳过 twine check（twine 已安装但无法直接访问）"
    echo "💡 分发包已构建成功，可以直接发布"
else
    echo "⚠️  跳过 twine check（twine 未找到）"
    echo "💡 分发包已构建成功，可以直接发布"
fi

# 询问是否发布到 TestPyPI
read -p "是否先发布到 TestPyPI 进行测试? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 发布到 TestPyPI..."
    # 尝试多种方式运行 twine
    if command -v twine &> /dev/null; then
        twine upload --repository testpypi dist/*
    elif python -m twine --version &> /dev/null 2>&1; then
        python -m twine upload --repository testpypi dist/*
    else
        echo "❌ 错误: 无法找到 twine 命令"
        echo "💡 请运行: uv pip install twine 或 pip install twine"
        exit 1
    fi
    echo "✅ 已发布到 TestPyPI"
    echo "💡 测试安装: pip install --index-url https://test.pypi.org/simple/ skill-mcp-server"
    read -p "测试完成后，是否发布到正式 PyPI? (y/n) " -n 1 -r
    echo
fi

# 发布到正式 PyPI
if [[ $REPLY =~ ^[Yy]$ ]] || [[ ! $REPLY =~ ^[Yy]$ ]]; then
    read -p "确认发布到正式 PyPI? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📤 发布到 PyPI..."
        # 尝试多种方式运行 twine
        if command -v twine &> /dev/null; then
            twine upload dist/*
        elif python -m twine --version &> /dev/null 2>&1; then
            python -m twine upload dist/*
        else
            echo "❌ 错误: 无法找到 twine 命令"
            echo "💡 请运行: uv pip install twine 或 pip install twine"
            exit 1
        fi
        echo "✅ 发布成功！"
        echo "🔗 查看包: https://pypi.org/project/skill-mcp-server/"
        
        # 询问是否创建 Git tag
        read -p "是否创建 Git tag v$VERSION? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag "v$VERSION"
            git push origin "v$VERSION"
            echo "✅ Git tag 已创建并推送"
        fi
    else
        echo "❌ 已取消发布"
    fi
fi

echo "✨ 完成！"
