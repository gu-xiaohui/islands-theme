#!/bin/bash

# Islands Dark Theme - Release Script
# 用于创建新版本并触发自动发布

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Islands Dark Theme - Release Script${NC}"
echo "====================================="

# 检查是否有未提交的更改
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}Error: You have uncommitted changes. Please commit or stash them first.${NC}"
    git status -s
    exit 1
fi

# 检查当前分支
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo -e "${YELLOW}Warning: You are not on the main branch (current: $CURRENT_BRANCH)${NC}"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 获取当前版本
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo -e "Current version: ${YELLOW}$CURRENT_VERSION${NC}"

# 询问新版本类型
echo ""
echo "Select version bump type:"
echo "  1) patch (bug fixes)        - $CURRENT_VERSION -> $(npm version patch --no-git-tag-version --dry-run | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')"
echo "  2) minor (new features)     - $CURRENT_VERSION -> $(npm version minor --no-git-tag-version --dry-run | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')"
echo "  3) major (breaking changes) - $CURRENT_VERSION -> $(npm version major --no-git-tag-version --dry-run | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')"
echo "  4) custom version"
echo "  5) cancel"
echo ""
read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        VERSION_TYPE="patch"
        ;;
    2)
        VERSION_TYPE="minor"
        ;;
    3)
        VERSION_TYPE="major"
        ;;
    4)
        read -p "Enter custom version (e.g., 1.2.3): " CUSTOM_VERSION
        if [[ ! $CUSTOM_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo -e "${RED}Error: Invalid version format. Use semantic versioning (e.g., 1.2.3)${NC}"
            exit 1
        fi
        VERSION_TYPE=$CUSTOM_VERSION
        ;;
    5)
        echo "Release cancelled."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Release cancelled.${NC}"
        exit 1
        ;;
esac

# 更新版本号
echo ""
echo -e "${GREEN}Updating version...${NC}"
if [[ $VERSION_TYPE =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    npm version $VERSION_TYPE --no-git-tag-version
else
    npm version $VERSION_TYPE --no-git-tag-version
fi

NEW_VERSION=$(node -p "require('./package.json').version")
echo -e "New version: ${GREEN}$NEW_VERSION${NC}"

# 提交更改
echo ""
echo -e "${GREEN}Committing version bump...${NC}"
git add package.json package-lock.json
git commit -m "chore: bump version to $NEW_VERSION"

# 创建标签
echo -e "${GREEN}Creating git tag v$NEW_VERSION...${NC}"
git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"

# 推送到远程
echo ""
echo -e "${YELLOW}Ready to push changes and trigger release.${NC}"
read -p "Push to remote and trigger GitHub Actions? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Pushing to remote...${NC}"
    git push origin $CURRENT_BRANCH
    git push origin "v$NEW_VERSION"
    
    echo ""
    echo -e "${GREEN}✓ Release process initiated!${NC}"
    echo -e "Version ${GREEN}$NEW_VERSION${NC} has been tagged and pushed."
    echo -e "GitHub Actions will now build and publish the extension."
    echo ""
    echo -e "Monitor the progress at:"
    echo -e "${YELLOW}https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')/actions${NC}"
else
    echo ""
    echo -e "${YELLOW}Changes committed and tagged locally but not pushed.${NC}"
    echo "To push manually, run:"
    echo "  git push origin $CURRENT_BRANCH"
    echo "  git push origin v$NEW_VERSION"
fi
