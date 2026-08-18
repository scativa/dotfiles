local wezterm = require 'wezterm'
local mux = wezterm.mux
local config = wezterm.config_builder()

-- ==========================================
-- SISTEMA Y SHELL POR DEFECTO
-- ==========================================
config.default_prog = { 'powershell.exe', '-NoLogo' }

-- ==========================================
-- MENÚ DE LANZAMIENTO RÁPIDO
-- ==========================================
config.launch_menu = {
  {
    label = 'PowerShell 7 / Windows PowerShell',
    args = { 'powershell.exe', '-NoLogo' },
  },
  {
    label = 'CMD (Símbolo del sistema)',
    args = { 'cmd.exe' },
  },
  {
    label = 'WSL - Ubuntu',
    domain = { DomainName = 'WSL:Ubuntu' },
  },
  {
    label = 'Git Bash',
    args = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-i', '-l' },
  },
}

-- ==========================================
-- APARIENCIA Y FUENTES
-- ==========================================
config.font_size = 10.0
config.window_background_opacity = 0.96
config.color_scheme = 'Catppuccin Mocha'

config.font = wezterm.font_with_fallback({  
    'JetBrainsMono Nerd Font',  
    'Old Timey Mono', 
})

-- ==========================================
-- COMPORTAMIENTO DE VENTANA (GUI)
-- ==========================================
wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  
  local gui_window = window:gui_window()
  local screen = wezterm.gui.screens().active
  
  local width = screen.width / 2
  local height = screen.height / 10 * 9
  
  gui_window:set_inner_size(width, height)
  gui_window:set_position(1, 30)
end)

-- ==========================================
-- FUNCIÓN INTELIGENTE DE SPLIT
-- ==========================================
-- Detecta el ejecutable del panel activo para clonarlo exactamente
local function split_pane_smart(direction)
  return wezterm.action_callback(function(window, pane)
    local process_info = pane:get_foreground_process_info()
    local args = nil

    if process_info and process_info.executable then
      local exe = process_info.executable:match("([^/\\]+)$"):lower()
      
      if exe == "cmd.exe" then
        args = { "cmd.exe" }
      elseif exe == "bash.exe" then
        args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l" }
      elseif exe == "powershell.exe" or exe == "pwsh.exe" then
        args = { "powershell.exe", "-NoLogo" }
      end
    end

    window:perform_action(
      wezterm.action.SplitPane {
        direction = direction,
        size = { Percent = 50 },
        command = args and { args = args } or nil,
      },
      pane
    )
  end)
end

-- ==========================================
-- ATAJOS DE TECLADO
-- ==========================================
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.window_close_confirmation = 'NeverPrompt'

config.keys = {
  -- --- Aplicaciones rápidas ---
  {
    key = 'u',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SpawnCommandInNewTab {
      domain = { DomainName = 'WSL:Ubuntu' },
    },
  },
  {
    key = 'q',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
  {
    key = 'b',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SpawnCommandInNewTab {
      args = { 'powershell.exe', '-NoLogo' },
      domain = { DomainName = 'local' },
    },
  },
  {
    key = 'w',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentTab { confirm = false },
  },
  { 
    key = 'm', 
    mods = 'LEADER', 
    action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS' } 
  },
  
  -- --- Gestión de Paneles Inteligente (Leader + | o -) ---
  { key = '|', mods = 'LEADER', action = split_pane_smart('Right') },
  { key = '-', mods = 'LEADER', action = split_pane_smart('Down') },
  
  -- Moverse entre paneles con ALT + Flechas
  { key = 'LeftArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
  
  -- Nueva pestaña
  { key = 't', mods = 'LEADER', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
}

-- 1. Definir el dominio de multiplexación local
config.unix_domains = {
  {
    name = 'unix',
  },
}

-- 2. Conectarse automáticamente a la sesión 'unix' al iniciar WezTerm
config.default_gui_startup_args = { 'connect', 'unix' }

return config