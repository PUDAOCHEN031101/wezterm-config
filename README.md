# WezTerm Config

这是一套面向 Windows + WSL Ubuntu + ROS/长时开发的个人 WezTerm 工作台配置。它优先保证稳定、清晰和低干扰，而不是透明、动画或复杂状态栏。

## 当前体验

- 默认进入 `WSL:Ubuntu`，起始目录固定为 `/home/lenovo`。
- 使用 Dracula-ROS 深灰配色；进入 `/prod/` 路径片段，或路径中包含 `production` / `staging` 时自动切换强调色。
- 使用软件渲染、1 FPS 动画、全不透明背景并禁用 Windows Acrylic，减少宿主进程抖动。
- 使用 4 px 稳定竖线光标；非活动窗格明显压暗，黄色分割线强化当前窗格识别。
- 支持标签、上下/左右分屏、工作区切换、右键动作菜单和常用目录跳转。
- 状态栏只显示工作区、电量和时间；Git 轮询默认关闭，避免周期性拉起外部进程。
- 自动重载关闭；修改配置后用 `Ctrl+Shift+R` 手动重载，避免半成品配置触发多窗口错误弹窗。

## 常用快捷键

| 操作 | 快捷键 |
|---|---|
| 手动重载配置 | `Ctrl+Shift+R` |
| 左右 / 上下分屏 | `Ctrl+Shift+L` / `Ctrl+Shift+Enter` |
| 在窗格间移动 | `Ctrl+Shift+方向键` |
| 新建标签 / 关闭窗格 | `Ctrl+Shift+T` / `Ctrl+Shift+W` |
| 切换或创建工作区 | `Ctrl+Shift+F9` |
| 智能工作区选择 | `Ctrl+Shift+Alt+F9` |
| 前后切换工作区 | `Ctrl+Shift+F10` / `Ctrl+Shift+F11` |
| 记录工作区信息 | `Ctrl+Shift+Alt+S` |
| 列出工作区 | `Ctrl+Shift+M` |
| 常用目录跳转 | `Ctrl+Shift+Z` |
| 右键动作菜单 | 在终端区域松开鼠标右键 |

更完整的操作说明见 [`Plan/do.md`](Plan/do.md)。

## 已知边界

- Windows 用户目录下的 `%USERPROFILE%\.wezterm_workspaces.json` 会记录标签、窗格和本机路径；当前恢复逻辑只会尝试使用第一个标签、第一个窗格的工作目录，不会重建完整分屏、标签、进程或比例。该文件可能包含隐私路径，不应提交。
- WSL 新分屏为稳定起见固定从 `/home/lenovo` 启动，不继承当前 WSL 窗格目录。
- `Ctrl+Shift+D` 只是记录工作区信息后关闭窗口，不等同于 tmux 的持久会话；本仓库未配置独立 mux server，长任务持久化请使用 tmux 等专用工具。
- `Ctrl+Shift+G` 只做一次 Git 分支查询并弹出通知，分支不会常驻状态栏。
- 常用目录别名、WSL 发行版和 home 路径都是本机值；当前别名已对齐本机的 `Obsidian`、`WezTerm` 和 `dotfiles`，在其他机器部署前仍需检查 `.wezterm.lua` 中的 `WSL_DISTRO`、`/home/lenovo` 与 `projects` 表。
- 当前自定义标签标题使用了版本敏感的 pane API；若回退为默认标题，不影响终端主体功能，后续可单独修复并做 GUI 验收。
- 关闭窗格和窗口均不弹确认框；误触会直接终止其中的前台任务。

## 部署

1. 安装 WezTerm，并确认 WSL 中存在名为 `Ubuntu` 的发行版。
2. 将仓库的 `.wezterm.lua` 复制到 `%USERPROFILE%\.wezterm.lua`。
3. 完全重启 WezTerm，或按 `Ctrl+Shift+R` 手动重载。

PowerShell 示例：

```powershell
Copy-Item .\.wezterm.lua "$env:USERPROFILE\.wezterm.lua" -Force
wezterm.exe --config-file "$env:USERPROFILE\.wezterm.lua" show-keys --lua > $null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

当前已在 `wezterm 20240203-110809-5046fc22` 上通过配置加载与快捷键解析；GUI 渲染、WSL 启动、事件回调和工作区行为仍需在真实窗口中冒烟验证。

## 仓库内容

- `.wezterm.lua`：唯一需要部署的主配置。
- `Plan/do.md`：功能、快捷键与行为边界的详细说明。
- `.gitignore`：排除便携版二进制、源码和安装产物。

仓库不包含 WezTerm 可执行文件、DLL、源码、安装产物或运行时生成的工作区数据。
