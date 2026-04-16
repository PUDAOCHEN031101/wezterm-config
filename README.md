# WezTerm Config

这是一套面向 Windows + WSL + ROS 开发的 WezTerm 配置仓库。

## 包含内容

- `.wezterm.lua`：主配置文件
- `Plan/do.md`：功能说明与使用记录

## 当前特性

- 默认进入 WSL `Ubuntu`
- Dracula 风格、适合长时间开发
- 工作区切换、布局保存与恢复
- 简化状态栏：工作区、电量、时间
- 右键菜单支持分屏、全屏、关闭窗口等常用操作

## 部署

1. 安装 WezTerm。
2. 将仓库里的 `.wezterm.lua` 复制到用户目录：
   - Windows: `%USERPROFILE%\.wezterm.lua`
3. 重启 WezTerm 或按 `Ctrl+Shift+R` 重载配置。

## 说明

这个仓库只保存配置与说明，不包含 WezTerm 可执行文件、DLL、源码或安装产物。
