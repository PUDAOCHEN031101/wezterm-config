-- WezTerm 配置 - Dracula 护眼 + ROS/长时开发向
-- 原则：深灰底（非纯黑）、ANSI 分层清晰（红/黄/绿易辨日志）、少花哨渐变；JetBrains Mono + 轻微透明
-- 核心：分屏 + 标签 + 工作区 + WSL + 右键菜单 + 布局保存恢复 + 快速跳转 + 多路复用
--
-- 若调试/编辑本文件时「错误弹窗叠很多层、不自动关」：多半是自动重载 + 配置语法错误。
-- 已关闭自动重载；改完配置后请 Ctrl+Shift+R 或重启 WezTerm。勿再使用 visual_bell = 'EaseInOut' 字符串（会整份配置报错）。
-- CONFIG_REV=20260415 已移除无效项：visual_bell 字符串、colors.scrollbar_track（若报错仍提这两项=读到旧文件或未重启）

local WSL_DISTRO = 'Ubuntu'

local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder and wezterm.config_builder() or {}

-- ── 工作区与布局管理 ──
local WORKSPACE_FILE = wezterm.home_dir .. '/.wezterm_workspaces.json'

-- 保存当前工作区布局
local function save_workspace_layout()
  local workspace_name = mux.get_active_workspace()
  local all_windows = mux.all_windows()
  local layout_data = {}
  
  for _, window in ipairs(all_windows) do
    if window:get_workspace() == workspace_name then
      local tabs = {}
      for _, tab in ipairs(window:tabs()) do
        local panes_info = {}
        for _, pane in ipairs(tab:panes()) do
          local info = {
            cwd = pane:get_current_working_dir(),
            domain = pane:get_domain_name(),
          }
          table.insert(panes_info, info)
        end
        table.insert(tabs, { panes = panes_info })
      end
      layout_data = { workspace = workspace_name, tabs = tabs }
      break
    end
  end
  
  -- 读取现有数据并更新
  local file = io.open(WORKSPACE_FILE, 'r')
  local saved = {}
  if file then
    local content = file:read('*all')
    file:close()
    saved = wezterm.json_parse(content) or {}
  end
  
  saved[workspace_name] = layout_data
  
  file = io.open(WORKSPACE_FILE, 'w')
  if file then
    file:write(wezterm.json_encode(saved))
    file:close()
  end
end

-- 恢复工作区布局
local function restore_workspace_layout(workspace_name)
  local file = io.open(WORKSPACE_FILE, 'r')
  if not file then return false end
  
  local content = file:read('*all')
  file:close()
  
  local saved = wezterm.json_parse(content) or {}
  local layout = saved[workspace_name]
  
  if not layout or not layout.tabs then return false end
  
  -- 恢复到第一个标签的第一个目录
  local first_tab = layout.tabs[1]
  if first_tab and first_tab.panes and first_tab.panes[1] then
    local pane_info = first_tab.panes[1]
    if pane_info.cwd then
      local path = tostring(pane_info.cwd):gsub('file://', ''):gsub('///', '/')
      return path
    end
  end
  return false
end

-- 获取所有保存的工作区列表
local function get_saved_workspaces()
  local file = io.open(WORKSPACE_FILE, 'r')
  if not file then return {} end
  
  local content = file:read('*all')
  file:close()
  
  local saved = wezterm.json_parse(content) or {}
  local workspaces = {}
  for name, _ in pairs(saved) do
    table.insert(workspaces, name)
  end
  return workspaces
end

-- ── 第五优先级：按路径切换强调色（子串匹配，先匹配先生效；ROS/多环境目录可在此加规则）──
local DEFAULT_SCHEME = 'Dracula-ROS'
local PATH_THEME_RULES = {
  { pattern = '/prod/', scheme = 'Dracula-Warn' },
  { pattern = 'production', scheme = 'Dracula-Warn' },
  { pattern = '/staging/', scheme = 'Dracula-Staging' },
  { pattern = 'staging', scheme = 'Dracula-Staging' },
}

local function scheme_for_path(path_str)
  if not path_str or path_str == '' then return DEFAULT_SCHEME end
  local lower = path_str:lower()
  for _, rule in ipairs(PATH_THEME_RULES) do
    if lower:find(rule.pattern, 1, true) then
      return rule.scheme
    end
  end
  return DEFAULT_SCHEME
end

-- Git 分支缓存
-- 手动刷新模式：默认不在 update-status 中主动查询，避免轮询引发的进程抖动。
local ENABLE_GIT_BRANCH = false
local git_cache = { cwd = '', branch = '-', t = 0 }
local GIT_REFRESH_SEC = 6

-- ── 外观：Dracula 系（标准 ANSI：红错 / 黄警 / 绿成功，便于 rqt/ros2 topic 与日志扫读）──
config.color_schemes = {
  [DEFAULT_SCHEME] = {
    foreground = '#f8f8f2',
    background = '#282a36',
    cursor_bg = '#f8f8f2',
    cursor_fg = '#282a36',
    selection_fg = '#f8f8f2',
    selection_bg = '#44475a',
    ansi = {
      '#21222c', -- 0 黑（非纯黑）
      '#ff5555', -- 1 红 error
      '#50fa7b', -- 2 绿 success
      '#f1fa8c', -- 3 黄 warning
      '#bd93f9', -- 4 蓝紫
      '#ff79c6', -- 5 品红
      '#8be9fd', -- 6 青
      '#f8f8f2', -- 7 前景白
    },
    brights = {
      '#6272a4',
      '#ff6e6e',
      '#69ff94',
      '#ffffa5',
      '#d6acff',
      '#ff92df',
      '#a4ffff',
      '#ffffff',
    },
    tab_bar = {
      background = '#1e1f29',
      active_tab = { bg_color = '#44475a', fg_color = '#f8f8f2' },
      inactive_tab = { bg_color = '#282a36', fg_color = '#6272a4' },
      inactive_tab_hover = { bg_color = '#343746', fg_color = '#bd93f9' },
      new_tab = { bg_color = '#21222c', fg_color = '#6272a4' },
    },
  },
  ['Dracula-Warn'] = {
    foreground = '#f8f8f2',
    background = '#2d2228',
    cursor_bg = '#ff5555',
    cursor_fg = '#1e1f29',
    selection_fg = '#f8f8f2',
    selection_bg = '#4a3038',
    ansi = {
      '#2a2024', '#ff6e6e', '#50fa7b', '#f1fa8c', '#c9a8ff', '#ff79c6', '#8be9fd', '#f8f8f2',
    },
    brights = {
      '#7a8bb0', '#ff8a8a', '#69ff94', '#ffffa5', '#d6acff', '#ff92df', '#a4ffff', '#ffffff',
    },
    tab_bar = {
      background = '#261a20',
      active_tab = { bg_color = '#4a3038', fg_color = '#ffb86c' },
      inactive_tab = { bg_color = '#2d2228', fg_color = '#a08088' },
      inactive_tab_hover = { bg_color = '#3a2830', fg_color = '#f8f8f2' },
      new_tab = { bg_color = '#221820', fg_color = '#806870' },
    },
  },
  ['Dracula-Staging'] = {
    foreground = '#f8f8f2',
    background = '#252a38',
    cursor_bg = '#f1fa8c',
    cursor_fg = '#1e1f29',
    selection_fg = '#f8f8f2',
    selection_bg = '#3d4a62',
    ansi = {
      '#1f2430', '#ff5555', '#50fa7b', '#f1fa8c', '#bd93f9', '#ff79c6', '#8be9fd', '#f8f8f2',
    },
    brights = {
      '#6272a4', '#ff6e6e', '#69ff94', '#ffffa5', '#d6acff', '#ff92df', '#a4ffff', '#ffffff',
    },
    tab_bar = {
      background = '#1e2330',
      active_tab = { bg_color = '#3d4a62', fg_color = '#8be9fd' },
      inactive_tab = { bg_color = '#252a38', fg_color = '#6272a4' },
      inactive_tab_hover = { bg_color = '#2f3548', fg_color = '#f8f8f2' },
      new_tab = { bg_color = '#1a1e28', fg_color = '#6272a4' },
    },
  },
}
config.color_scheme = DEFAULT_SCHEME

-- 长时看日志：纯色底，不用多色纵向渐变（避免干扰 ROS 彩色输出分层）
-- config.window_background_gradient = nil

config.font = wezterm.font({ family = 'JetBrains Mono', harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' } })
config.font_size = 14.0
config.window_background_opacity = 0.93
config.win32_system_backdrop = 'Acrylic'
config.default_cursor_style = 'BlinkingBar'
config.cursor_thickness = 2
-- 不显式设 visual_bell：避免旧版/类型差异导致 Config 报错弹窗；需要时再按文档用「表」配置（勿写字符串）
config.colors = {
  scrollbar_thumb = '#6272a4',
}
config.enable_scroll_bar = true

-- ── WSL2 默认启动 ──
-- 使用原生 WSL 域作为默认域；显式设置 WSL 域 default_cwd，避免继承 Windows 当前目录落到 /mnt/c/Users/lenovo
config.default_domain = 'WSL:' .. WSL_DISTRO
config.default_prog = { 'bash', '-l' }

-- 若出现「新标签/新窗口一闪就关」：多半是 wsl/bash 秒退。默认 exit_behavior=Close 会立刻关掉窗格，看不到报错。
-- Hold = 进程结束后保留窗格，便于看退出码与提示；确认无问题后可改回 'CloseOnCleanExit'。
config.exit_behavior = 'Hold'
config.exit_behavior_messaging = 'Brief'

-- 可选：保留 WSL 域定义（用于切换回 WSL 模式）
config.wsl_domains = {
  { name = 'WSL:' .. WSL_DISTRO, distribution = WSL_DISTRO, default_cwd = '/home/lenovo' }
}

-- ── 标签栏 ──
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false

local function short_path_display(path_str)
  if not path_str or path_str == '' then return '~' end
  local norm = path_str:gsub('\\', '/')
  local parts = {}
  for part in norm:gmatch('[^/]+') do
    table.insert(parts, part)
  end
  if #parts == 0 then return '~' end
  if #parts <= 3 then
    return norm:sub(-44)
  end
  return parts[#parts - 2] .. '/' .. parts[#parts - 1] .. '/' .. parts[#parts]
end

local function domain_label(domain_name, path_hint)
  local d = (domain_name or ''):lower()
  if d:find('wsl', 1, true) then
    return 'WSL'
  end
  -- 兜底：某些情况下 domain 仍是 local，但路径是 unix 形态，实际在 WSL 会话中
  if d == 'local' and type(path_hint) == 'string' and path_hint:match('^/') then
    return 'WSL'
  end
  if d:find('ssh', 1, true) then
    return 'SSH'
  end
  return 'WIN'
end

local function display_path_for_domain(path_str, domain_name)
  if not path_str or path_str == '' then return '~' end
  local label = domain_label(domain_name, path_str)
  if label == 'WSL' then
    -- 某些场景下 cwd 仍可能给到 Windows 盘符路径；转换为 WSL 习惯路径，避免误判“没同步”。
    local drv, rest = path_str:match('^([A-Za-z]):/(.*)$')
    if drv and rest then
      return '/mnt/' .. drv:lower() .. '/' .. rest
    end
  end
  return path_str
end

-- 统一处理 pane:get_current_working_dir() 的不同返回形态（URL/table）
local function normalize_cwd(uri)
  if not uri then return '' end
  local raw = ''
  if type(uri) == 'table' and uri.file_path then
    raw = uri.file_path
  else
    raw = tostring(uri)
  end
  if not raw or raw == '' then return '' end

  local s = raw:gsub('\\', '/')
  -- 处理 file://host/path 或 file:///C:/path
  s = s:gsub('^file://[^/]*', '')
  -- 把 /C:/Users 规范成 C:/Users
  if s:match('^/[A-Za-z]:/') then
    s = s:sub(2)
  end
  s = s:gsub('%%20', ' ')
  s = s:gsub('/+$', '')
  if s == '' then
    s = '/'
  end
  return s
end

local last_window_scheme = {}

local function refresh_git_branch(cwd_str, force)
  if (not ENABLE_GIT_BRANCH) and (not force) then
    git_cache.branch = '-'
    return
  end
  if not cwd_str or cwd_str == '' then
    git_cache.branch = '-'
    git_cache.cwd = ''
    return
  end
  local now = os.time()
  if cwd_str ~= git_cache.cwd then
    git_cache.cwd = cwd_str
    git_cache.t = 0
  end
  if (not force) and git_cache.t > 0 and (now - git_cache.t) < GIT_REFRESH_SEC then
    return
  end
  git_cache.t = now
  -- 仅调用本地 git，避免周期性拉起 wsl.exe 导致终端/宿主进程抖动
  local q = cwd_str:gsub('"', '')
  local cmd = string.format('git -C "%s" rev-parse --abbrev-ref HEAD 2>nul', q)
  local h = io.popen(cmd, 'r')
  if not h then
    git_cache.branch = '-'
    return
  end
  local out = h:read('*l') or ''
  h:close()
  out = out:gsub('^%s+', ''):gsub('%s+$', '')
  if out == '' or out:find('fatal', 1, true) or out:find('not a git', 1, true) then
    git_cache.branch = '-'
  else
    git_cache.branch = out
  end
end

-- ── 状态栏：Git / 路径 / WS / 电池 / 时间 + 按目录换配色 ──
wezterm.on('update-status', function(window, pane)
  local workspace_name = 'default'
  pcall(function()
    local ws = window:active_workspace()
    if ws and ws ~= '' then workspace_name = ws end
  end)

  local cwd_str = ''
  local pane_domain = 'local'
  pcall(function()
    local uri = pane:get_current_working_dir()
    cwd_str = normalize_cwd(uri)
  end)
  pcall(function()
    local dn = pane:get_domain_name()
    if dn and dn ~= '' then pane_domain = dn end
  end)

  local want_scheme = scheme_for_path(cwd_str)
  local wid = '_'
  pcall(function() wid = tostring(window:window_id()) end)
  if last_window_scheme[wid] ~= want_scheme then
    last_window_scheme[wid] = want_scheme
    pcall(function()
      window:set_config_overrides({ color_scheme = want_scheme })
    end)
  end

  -- 手动模式默认不在状态栏刷新里查询 git，避免外部进程抖动
  if ENABLE_GIT_BRANCH then
    pcall(function() refresh_git_branch(cwd_str, false) end)
  end
  local battery_text = ''
  pcall(function()
    local info = wezterm.battery_info()
    if info and info[1] then
      local pct = math.floor(info[1].state_of_charge * 100)
      battery_text = string.format('%d%%', pct)
    end
  end)
  local parts = {
    { text = workspace_name, color = '#caa9fa' },
  }
  if battery_text ~= '' then
    table.insert(parts, { text = battery_text, color = '#f1fa8c' })
  end
  table.insert(parts, { text = wezterm.strftime('%H:%M'), color = '#8be9fd' })

  local cells = {}
  for i, part in ipairs(parts) do
    table.insert(cells, { Foreground = { Color = part.color } })
    table.insert(cells, { Text = part.text })
    if i < #parts then
      table.insert(cells, { Foreground = { Color = '#6272a4' } })
      table.insert(cells, { Text = '  ·  ' })
    else
      table.insert(cells, { Text = ' ' })
    end
  end

  window:set_right_status(wezterm.format(cells))
end)

-- ── 同时在标签标题显示工作区 ──
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  -- 获取当前工作区名称
  local workspace_name = 'default'
  local ok, result = pcall(function()
    -- 通过 pane 获取窗口再获取工作区
    local win = tab.active_pane and tab.active_pane:window()
    if win then
      local ws = win:active_workspace()
      return ws and ws ~= '' and ws or 'default'
    end
    return 'default'
  end)
  if ok and result then
    workspace_name = result
  end

  -- 获取当前目录
  local cwd = 'home'
  if tab.active_pane then
    local cwd_uri = tab.active_pane:get_current_working_dir()
    if cwd_uri then
      local path = cwd_uri.file_path or ''
      cwd = path:match('([^/]+)$') or 'home'
    end
  end

  -- 标签标题：工作区:目录
  local title = workspace_name .. ':' .. cwd
  if #title > max_width then
    title = title:sub(1, max_width - 2) .. '..'
  end

  return {
    { Foreground = { Color = '#8be9fd' } },
    { Text = title },
  }
end)

-- ── 快捷键 ──
config.keys = {
  -- 分屏
  { key = 'l', mods = 'CTRL|SHIFT', action = act.SplitPane({ direction = 'Right', command = { domain = 'CurrentPaneDomain' } }) },
  { key = 'Enter', mods = 'CTRL|SHIFT', action = act.SplitPane({ direction = 'Down', command = { domain = 'CurrentPaneDomain' } }) },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane({ confirm = false }) },
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Left') },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Right') },
  { key = 'UpArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Up') },
  { key = 'DownArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Down') },
  -- 标签
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab('CurrentPaneDomain') },
  { key = '1', mods = 'CTRL|SHIFT', action = act.ActivateTab(0) },
  { key = '2', mods = 'CTRL|SHIFT', action = act.ActivateTab(1) },
  { key = '3', mods = 'CTRL|SHIFT', action = act.ActivateTab(2) },
  { key = '4', mods = 'CTRL|SHIFT', action = act.ActivateTab(3) },
  -- 全屏
  { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
  -- 工作区：F9 切换/创建工作区（不存在则自动创建）
  { key = 'F9', mods = 'CTRL|SHIFT', action = act.PromptInputLine {
    description = '输入工作区名称（回车切换/创建）',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:perform_action(act.SwitchToWorkspace { name = line }, pane)
      end
    end),
  } },
  -- F10/F11 在最近工作区间切换
  { key = 'F10', mods = 'CTRL|SHIFT', action = act.SwitchWorkspaceRelative(1) },
  { key = 'F11', mods = 'CTRL|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
  -- 智能工作区切换（显示保存的工作区列表）- 改用 PromptInputLine 显示列表
  { key = 'F9', mods = 'CTRL|SHIFT|ALT', action = wezterm.action_callback(function(window, pane)
    local saved = get_saved_workspaces()
    local list_text = ''
    
    -- 构建工作区列表
    if #saved > 0 then
      list_text = '【已保存的工作区】\n'
      for i, name in ipairs(saved) do
        list_text = list_text .. '  ' .. i .. '. ' .. name .. '\n'
      end
      list_text = list_text .. '\n'
    end
    
    list_text = list_text .. '【预设工作区】\n'
    list_text = list_text .. '  c. coding\n'
    list_text = list_text .. '  d. docs\n'
    list_text = list_text .. '  s. server\n'
    list_text = list_text .. '\n输入名称或编号切换/创建工作区：'
    
    -- 使用 PromptInputLine 让用户输入
    window:perform_action(
      act.PromptInputLine {
        description = list_text,
        action = wezterm.action_callback(function(win, p, line)
          if not line or line == '' then return end
          
          -- 解析输入
          local workspace_name = line
          local num = tonumber(line)
          
          -- 如果是数字，对应已保存的工作区
          if num and num > 0 and num <= #saved then
            workspace_name = saved[num]
          -- 预设快捷方式
          elseif line == 'c' or line == 'C' then
            workspace_name = 'coding'
          elseif line == 'd' or line == 'D' then
            workspace_name = 'docs'
          elseif line == 's' or line == 'S' then
            workspace_name = 'server'
          end
          
          -- 尝试恢复目录并切换
          local saved_cwd = restore_workspace_layout(workspace_name)
          if saved_cwd then
            local cmd = { 'wsl.exe', '-d', WSL_DISTRO, '--cd', saved_cwd }
            win:perform_action(
              act.SwitchToWorkspace { name = workspace_name, spawn = { args = cmd } },
              p
            )
          else
            win:perform_action(act.SwitchToWorkspace { name = workspace_name }, p)
          end
        end),
      },
      pane
    )
  end) },
  -- 快速跳转到常用项目目录（配合 zoxide）
  { key = 'Z', mods = 'CTRL|SHIFT', action = act.PromptInputLine {
    description = '输入项目名或路径（配合 zoxide）',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        -- 尝试用 zoxide 解析路径
        local projects = {
          ['obsidian'] = '/home/lenovo/project/Obsidian',
          ['wezterm'] = '/mnt/c/Users/lenovo/.config/wezterm',
          ['cursor'] = '/home/lenovo/project/cursor',
          ['dotfiles'] = '/home/lenovo/dotfiles',
        }
        local target_dir = projects[line] or line
        
        -- 在当前窗格切换目录
        pane:send_text('cd "' .. target_dir .. '" && clear\n')
        
        -- 保存当前工作区布局
        save_workspace_layout()
      end
    end),
  } },
  -- 手动刷新 Git 分支（零轮询，按一次查一次）
  { key = 'g', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    local cwd_str = ''
    pcall(function()
      local uri = pane:get_current_working_dir()
      cwd_str = normalize_cwd(uri)
    end)
    pcall(function() refresh_git_branch(cwd_str, true) end)
    pcall(function()
      window:toast_notification('WezTerm', 'Git 分支已手动刷新：' .. (git_cache.branch or '-'), nil, 1200)
    end)
  end) },
  -- 手动保存当前布局
  { key = 'S', mods = 'CTRL|SHIFT|ALT', action = wezterm.action_callback(function()
    save_workspace_layout()
    wezterm.log_info('工作区布局已保存')
  end) },
  -- ═══════════════════════════════════════════════════════════
  -- 第四优先级：多路复用（Multiplexer）
  -- ═══════════════════════════════════════════════════════════
  -- 列出所有活动工作区（类似 tmux ls）
  { key = 'M', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs { flags = 'WORKSPACES' } },
  -- 连接到已保存的会话域（恢复工作区）
  { key = 'A', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    -- 显示可连接的工作区列表
    local saved = get_saved_workspaces()
    if #saved == 0 then
      wezterm.log_info('没有保存的工作区')
      return
    end
    -- 切换到第一个保存的工作区
    window:perform_action(act.SwitchToWorkspace { name = saved[1] }, pane)
  end) },
  -- 断开当前窗口（后台保持运行，类似 tmux detach）
  -- 注意：这会关闭窗口但保持工作区运行，可以用 Ctrl+Shift+A 恢复
  { key = 'D', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    -- 先保存当前布局
    save_workspace_layout()
    wezterm.log_info('工作区已保存，可以安全关闭窗口')
    -- 关闭窗口但不退出程序（工作区在后台保持）
    window:perform_action(act.CloseCurrentWindow { confirm = false }, pane)
  end) },
  -- 新建独立会话窗口（不共享当前会话）
  { key = 'N', mods = 'CTRL|SHIFT|ALT', action = act.SpawnWindow },
}

-- 右键菜单：用「松开右键」打开，单击后不必一直按着；选完一项或选「退出」或按 Esc 即关闭
local function make_context_menu()
  return act.InputSelector {
    title = '右键菜单｜松手后用 ↑↓ 选择，Enter 确定，Esc 或选「退出」关闭（无需长按鼠标）',
    choices = {
      { id = 'split_r', label = '左右分屏' },
      { id = 'split_d', label = '上下分屏' },
      { id = 'close_p', label = '关闭当前窗格' },
      { id = 'fullscreen', label = '切换全屏' },
      { id = 'close_win', label = '关闭当前窗口' },
      { id = 'new_t', label = '新建标签' },
      { id = 'ws_switch', label = '切换或创建工作区…' },
      { id = 'ws_save', label = '保存当前布局' },
      { id = 'ws_list', label = '列出所有工作区' },
      { id = 'ws_detach', label = '保存布局并关闭本窗口' },
      { id = 'new_win', label = '新建独立窗口' },
      { id = 'cancel', label = '── 退出菜单（不执行任何操作）──' },
    },
    action = wezterm.action_callback(function(window, pane, id)
      if id == 'cancel' then
        return
      elseif id == 'split_r' then
        window:perform_action(act.SplitPane { direction = 'Right', command = { domain = 'CurrentPaneDomain' } }, pane)
      elseif id == 'split_d' then
        window:perform_action(act.SplitPane { direction = 'Down', command = { domain = 'CurrentPaneDomain' } }, pane)
      elseif id == 'close_p' then
        window:perform_action(act.CloseCurrentPane { confirm = false }, pane)
      elseif id == 'fullscreen' then
        window:perform_action(act.ToggleFullScreen, pane)
      elseif id == 'close_win' then
        window:perform_action(act.CloseCurrentWindow { confirm = false }, pane)
      elseif id == 'new_t' then
        window:perform_action(act.SpawnTab('CurrentPaneDomain'), pane)
      elseif id == 'ws_switch' then
        window:perform_action(
          act.PromptInputLine {
            description = '输入工作区名称（回车切换/创建）：',
            action = wezterm.action_callback(function(win, p, line)
              if line then win:perform_action(act.SwitchToWorkspace { name = line }, p) end
            end),
          },
          pane
        )
      elseif id == 'ws_save' then
        save_workspace_layout()
      elseif id == 'ws_list' then
        window:perform_action(act.ShowLauncherArgs { flags = 'WORKSPACES' }, pane)
      elseif id == 'ws_detach' then
        save_workspace_layout()
        window:perform_action(act.CloseCurrentWindow { confirm = false }, pane)
      elseif id == 'new_win' then
        window:perform_action(act.SpawnWindow, pane)
      end
    end),
  }
end

-- 鼠标：松开右键时弹出菜单（按下→松开=一次完整点击，之后不必按着右键选）
-- 需要另开新窗口：用菜单里「新建独立窗口」，或快捷键 Ctrl+Shift+Alt+N
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = 'Right' } }, mods = 'NONE', action = make_context_menu() },
}

-- ── 多路复用 / SSH（可选）──
-- 注意：当前 WezTerm 版本无 config.mux_enabled 字段；勿使用无效项，否则会整份配置报错。
-- 需要原生 mux 时：终端里运行 `wezterm start --multiplex`，再用 `wezterm connect <域名>`（见官方文档）。
config.ssh_domains = {
  -- {
  --   name = 'myserver',
  --   remote_address = 'user@192.168.1.100:22',
  --   ssh_option = { identity_file = '~/.ssh/id_rsa' },
  -- },
}

-- ── 其它 ──
config.audible_bell = 'Disabled'
-- false：编辑 .wezterm.lua 时若曾保存过「半成品」，自动重载会对每个窗口各弹一次错误框且需手动关
config.automatically_reload_config = false
config.window_close_confirmation = 'NeverPrompt'

return config
