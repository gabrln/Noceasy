-- =========================================================================
-- Hyprland Modular Configuration (v0.55+ Lua Loader)
-- =========================================================================

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local hypr_dir = config_home .. "/hypr"

-- Dynamic module loader (executes fresh on reload without static caching)
local function load_module(name)
    dofile(hypr_dir .. "/modules/" .. name .. ".lua")
end

-- Load configuration modules in logical order
load_module("env")
load_module("monitors")
load_module("settings")
load_module("animations")
load_module("rules")
load_module("keybinds")
load_module("autostart")

-- Apply dynamic colors from Noctalia theme templates
require("noctalia").apply_theme()
