#!/bin/bash

# Islands Theme 发布脚本
# 用法: ./scripts/publish.sh [patch|minor|major]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Islands Theme 发布脚本 ===${NC}\n"

# 检查是否安装了 vsce
if ! command -v vsce &> /dev/null; then
    echo -e "${RED}错误: vsce 未安装${NC}"
    echo "请运行: npm install -g @vscode/vsce"
    exit 1
fi

# 检查工作目录是否干净
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}警告: 工作目录有未提交的更改${NC}"
    git status -s
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 获取版本类型参数
VERSION_TYPE=${1:-patch}

if [[ ! "$VERSION_TYPE" =~ ^(patch|minor|major)$ ]]; then
    echo -e "${RED}错误: 无效的版本类型 '$VERSION_TYPE'${NC}"
    echo "用法: $0 [patch|minor|major]"
    exit 1
fi

echo -e "${GREEN}步骤 1/6: 更新版本号 ($VERSION_TYPE)${NC}"
npm version $VERSION_TYPE --no-git-tag-version
NEW_VERSION=$(node -p "require('./package.json').version")
echo -e "新版本: ${GREEN}v$NEW_VERSION${NC}\n"

echo -e "${GREEN}步骤 2/6: 打包插件${NC}"
vsce package
echo ""

echo -e "${GREEN}步骤 3/6: 提交版本更改${NC}"
git add package.json
git commit -m "chore: bump version to v$NEW_VERSION"
echo ""

echo -e "${GREEN}步骤 4/6: 创建 Git 标签${NC}"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
echo ""

echo -e "${GREEN}步骤 5/6: 推送到 GitHub${NC}"
git push origin main
git push origin "v$NEW_VERSION"
echo ""

echo -e "${GREEN}步骤 6/6: 发布到 VS Code Marketplace${NC}"
read -p "是否发布到 Marketplace? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    vsce publish
    echo -e "\n${GREEN}✓ 发布成功!${NC}"
else
    echo -e "\n${YELLOW}跳过 Marketplace 发布${NC}"
    echo "手动发布命令: vsce publish"
fi

echo -e "\n${GREEN}=== 发布完成 ===${NC}"
echo -e "版本: ${GREEN}v$NEW_VERSION${NC}"
echo -e "VSIX 文件: ${GREEN}islands-theme-$NEW_VERSION.vsix${NC}"
echo -e "\n后续步骤:"
echo "1. 在 GitHub 上创建 Release: https://github.com/guxiaohui/islands-theme/releases/new"
echo "2. 上传 .vsix 文件到 Release"
echo "3. 编写 Release Notes"
