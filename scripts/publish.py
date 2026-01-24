#!/usr/bin/env python3
"""
发布脚本 - 用于发布 skill-mcp-server 到 PyPI
使用 Python 模块方式运行 twine，避免 PATH 问题
"""

import os
import sys
import subprocess
import re
from pathlib import Path


def get_version() -> str:
    """从 pyproject.toml 读取版本号"""
    pyproject_path = Path("pyproject.toml")
    if not pyproject_path.exists():
        print("❌ 错误: 未找到 pyproject.toml，请在项目根目录运行此脚本")
        sys.exit(1)
    
    content = pyproject_path.read_text()
    match = re.search(r'^version\s*=\s*"([^"]+)"', content, re.MULTILINE)
    if match:
        return match.group(1)
    print("❌ 错误: 无法从 pyproject.toml 读取版本号")
    sys.exit(1)


def run_command(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    """运行命令"""
    try:
        result = subprocess.run(cmd, check=check, capture_output=True, text=True)
        return result
    except subprocess.CalledProcessError as e:
        print(f"❌ 命令执行失败: {' '.join(cmd)}")
        print(f"错误: {e.stderr}")
        sys.exit(1)


def check_twine() -> bool:
    """检查 twine 是否可用"""
    try:
        result = run_command([sys.executable, "-m", "twine", "--version"], check=False)
        return result.returncode == 0
    except Exception:
        return False


def main() -> None:
    print("🚀 开始发布 skill-mcp-server 到 PyPI")
    
    # 检查 twine
    if not check_twine():
        print("❌ 错误: 无法找到 twine 模块")
        print("💡 请运行: pip install twine 或 uv pip install twine")
        sys.exit(1)
    
    # 读取版本号
    version = get_version()
    print(f"📦 当前版本: {version}")
    
    # 清理旧的构建文件
    print("🧹 清理旧的构建文件...")
    for path in ["dist", "build"]:
        if Path(path).exists():
            import shutil
            shutil.rmtree(path)
    
    # 构建分发包
    print("🔨 构建分发包...")
    if Path("uv.lock").exists() or subprocess.run(["which", "uv"], capture_output=True).returncode == 0:
        print("使用 uv 构建...")
        run_command(["uv", "build"])
    else:
        print("使用 python -m build 构建...")
        run_command([sys.executable, "-m", "build"])
    
    # 检查分发包
    print("✅ 检查分发包...")
    dist_files = list(Path("dist").glob("*"))
    if not dist_files:
        print("❌ 错误: 未找到构建的分发包")
        sys.exit(1)
    
    dist_paths = [str(f) for f in dist_files]
    result = run_command([sys.executable, "-m", "twine", "check"] + dist_paths, check=False)
    if result.returncode != 0:
        print("⚠️  twine check 有警告，但可以继续")
        print(result.stdout)
    
    # 询问是否发布到 TestPyPI
    print("\n是否先发布到 TestPyPI 进行测试? (y/n): ", end="")
    reply = input().strip().lower()
    
    if reply == "y":
        print("📤 发布到 TestPyPI...")
        run_command([sys.executable, "-m", "twine", "upload", "--repository", "testpypi"] + dist_paths)
        print("✅ 已发布到 TestPyPI")
        print("💡 测试安装: pip install --index-url https://test.pypi.org/simple/ skill-mcp-server")
        print("\n测试完成后，是否发布到正式 PyPI? (y/n): ", end="")
        reply = input().strip().lower()
    
    # 发布到正式 PyPI
    if reply != "y":
        print("\n确认发布到正式 PyPI? (y/n): ", end="")
        reply = input().strip().lower()
    
    if reply == "y":
        print("📤 发布到 PyPI...")
        run_command([sys.executable, "-m", "twine", "upload"] + dist_paths)
        print("✅ 发布成功！")
        print(f"🔗 查看包: https://pypi.org/project/skill-mcp-server/")
        
        # 询问是否创建 Git tag
        print(f"\n是否创建 Git tag v{version}? (y/n): ", end="")
        reply = input().strip().lower()
        if reply == "y":
            run_command(["git", "tag", f"v{version}"])
            run_command(["git", "push", "origin", f"v{version}"])
            print("✅ Git tag 已创建并推送")
    else:
        print("❌ 已取消发布")
    
    print("✨ 完成！")


if __name__ == "__main__":
    main()
