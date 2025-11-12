# 发布指南

本文档说明如何发布 Islands Dark Theme 扩展的新版本。

## 前置准备

### 1. 获取发布令牌

#### VS Code Marketplace (必需)

1. 访问 [Azure DevOps](https://dev.azure.com/)
2. 创建或登录您的组织
3. 创建 Personal Access Token (PAT):
   - 点击右上角用户图标 → Personal access tokens
   - 点击 "New Token"
   - Name: `vscode-marketplace`
   - Organization: 选择 "All accessible organizations"
   - Scopes: 选择 "Custom defined" → 勾选 "Marketplace" → "Manage"
   - 点击 "Create" 并保存生成的 token

4. 创建 Publisher (如果还没有):
   ```bash
   npx @vscode/vsce create-publisher <publisher-name>
   ```

5. 在 `package.json` 中设置 publisher:
   ```json
   {
     "publisher": "your-publisher-name"
   }
   ```

#### Open VSX Registry (可选，推荐)

1. 访问 [Open VSX Registry](https://open-vsx.org/)
2. 使用 GitHub 账号登录
3. 进入 [Access Tokens](https://open-vsx.org/user-settings/tokens) 页面
4. 创建新的 Access Token 并保存

### 2. 配置 GitHub Secrets

在您的 GitHub 仓库中设置以下 Secrets:

1. 进入仓库 → Settings → Secrets and variables → Actions
2. 添加以下 secrets:
   - `VSCE_TOKEN`: 您的 VS Code Marketplace PAT
   - `OVSX_TOKEN`: 您的 Open VSX Registry token (可选)

## 发布流程

### 方式一：使用自动化脚本 (推荐)

1. **确保所有更改已提交**
   ```bash
   git status
   ```

2. **运行发布脚本**
   ```bash
   chmod +x scripts/release.sh
   ./scripts/release.sh
   ```

3. **按照提示选择版本类型**:
   - `patch`: 修复 bug (1.0.0 → 1.0.1)
   - `minor`: 新功能 (1.0.0 → 1.1.0)
   - `major`: 破坏性更改 (1.0.0 → 2.0.0)
   - `custom`: 自定义版本号

4. **确认推送**
   - 脚本会自动更新版本号、创建 git tag 并推送
   - GitHub Actions 将自动构建和发布

### 方式二：手动发布

1. **更新版本号**
   ```bash
   npm version patch  # 或 minor, major
   ```

2. **提交更改**
   ```bash
   git add .
   git commit -m "chore: bump version to x.x.x"
   ```

3. **创建并推送标签**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin main
   git push origin v1.0.0
   ```

4. **GitHub Actions 自动发布**
   - 推送标签后，GitHub Actions 会自动触发
   - 监控进度: https://github.com/YOUR_USERNAME/Islands-Dark-Theme/actions

### 方式三：本地手动发布

如果不使用 GitHub Actions:

```bash
# 安装 vsce
npm install -g @vscode/vsce

# 打包
vsce package

# 发布到 VS Code Marketplace
vsce publish

# (可选) 发布到 Open VSX
npm install -g ovsx
ovsx publish -p YOUR_OVSX_TOKEN
```

## GitHub Actions 工作流

### CI 工作流 (ci.yml)

- **触发条件**: 推送到 main/develop 分支或创建 PR
- **功能**:
  - 验证扩展可以正确打包
  - 检查主题文件是否存在
  - 上传构建产物

### 发布工作流 (publish.yml)

- **触发条件**: 
  - 推送版本标签 (v*.*.*)  
  - 手动触发 (workflow_dispatch)
- **功能**:
  - 打包扩展为 .vsix 文件
  - 发布到 VS Code Marketplace
  - 发布到 Open VSX Registry
  - 创建 GitHub Release
  - 上传 .vsix 文件到 Release

## 版本号规范

遵循 [语义化版本](https://semver.org/lang/zh-CN/):

- **MAJOR (主版本号)**: 不兼容的 API 修改
- **MINOR (次版本号)**: 向下兼容的功能性新增
- **PATCH (修订号)**: 向下兼容的问题修正

示例:
- `1.0.0` → `1.0.1`: 修复 bug
- `1.0.0` → `1.1.0`: 添加新主题变体
- `1.0.0` → `2.0.0`: 重大主题重构

## 发布检查清单

发布前请确认:

- [ ] 所有更改已提交并推送
- [ ] README.md 已更新
- [ ] CHANGELOG.md 已更新 (如果有)
- [ ] 主题文件已测试
- [ ] package.json 中的信息正确
- [ ] 版本号符合语义化版本规范
- [ ] GitHub Secrets 已正确配置

## 验证发布

发布后验证:

1. **VS Code Marketplace**
   - 访问: https://marketplace.visualstudio.com/items?itemName=YOUR_PUBLISHER.islands-dark-theme
   - 检查版本号和描述

2. **Open VSX Registry**
   - 访问: https://open-vsx.org/extension/YOUR_PUBLISHER/islands-dark-theme

3. **GitHub Release**
   - 访问: https://github.com/YOUR_USERNAME/Islands-Dark-Theme/releases
   - 确认 .vsix 文件已上传

4. **本地测试**
   ```bash
   # 在 VS Code 中搜索并安装
   # 或从 GitHub Release 下载 .vsix 并安装
   code --install-extension islands-dark-theme-x.x.x.vsix
   ```

## 故障排除

### 发布失败

1. **检查 GitHub Actions 日志**
   - 查看详细错误信息

2. **验证 Secrets**
   - 确保 VSCE_TOKEN 和 OVSX_TOKEN 正确
   - Token 需要有正确的权限

3. **本地测试打包**
   ```bash
   vsce package
   ```

### 版本冲突

如果版本号已存在:

```bash
# 删除本地标签
git tag -d v1.0.0

# 删除远程标签
git push origin :refs/tags/v1.0.0

# 更新版本号并重新发布
npm version patch
```

## 回滚发布

如果需要撤回发布:

1. **从 Marketplace 取消发布** (需要手动操作)
2. **删除 GitHub Release**
3. **回滚代码**:
   ```bash
   git revert HEAD
   git push origin main
   ```

## 相关链接

- [VS Code 扩展发布文档](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)
- [vsce 工具文档](https://github.com/microsoft/vscode-vsce)
- [Open VSX 发布指南](https://github.com/eclipse/openvsx/wiki/Publishing-Extensions)
- [语义化版本规范](https://semver.org/lang/zh-CN/)
