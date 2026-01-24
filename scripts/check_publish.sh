#!/bin/bash
# 检查包是否成功发布到 PyPI

PACKAGE_NAME="skill-mcp-server"
PYPI_URL="https://pypi.org/project/${PACKAGE_NAME}/"

echo "🔍 检查 ${PACKAGE_NAME} 是否已发布到 PyPI..."
echo ""

# 方法 1: 使用 curl 检查 HTTP 状态
echo "方法 1: 检查 PyPI 页面..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${PYPI_URL}" 2>/dev/null)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 成功！包已发布到 PyPI"
    echo "🔗 访问: ${PYPI_URL}"
else
    echo "⚠️  HTTP 状态码: ${HTTP_CODE}"
    if [ "$HTTP_CODE" = "404" ]; then
        echo "❌ 包可能还未发布，或者包名不正确"
    fi
fi

echo ""

# 方法 2: 尝试获取包信息
echo "方法 2: 获取包信息..."
PYPI_JSON_URL="https://pypi.org/pypi/${PACKAGE_NAME}/json"

if command -v curl &> /dev/null; then
    JSON_RESPONSE=$(curl -s "${PYPI_JSON_URL}" 2>/dev/null)
    if echo "$JSON_RESPONSE" | grep -q '"name"'; then
        echo "✅ 包信息获取成功！"
        VERSION=$(echo "$JSON_RESPONSE" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$VERSION" ]; then
            echo "📦 最新版本: ${VERSION}"
        fi
    else
        echo "⚠️  无法获取包信息"
    fi
fi

echo ""
echo "💡 提示:"
echo "   1. 直接在浏览器访问: ${PYPI_URL}"
echo "   2. 尝试安装: pip install ${PACKAGE_NAME}"
echo "   3. 检查你的 PyPI 账户: https://pypi.org/manage/projects/"
