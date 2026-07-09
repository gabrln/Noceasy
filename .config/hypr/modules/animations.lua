-- =========================================================================
-- Hyprland animations and bezier curves (Lua module)
-- =========================================================================

hl.config({ animations = { enabled = true } })

-- Bezier curves for smooth transitions
hl.curve("wind",      { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.00 } } })
hl.curve("winIn",     { type = "bezier", points = { { 0.1,  1.0 }, { 0.1, 1.00 } } })
hl.curve("winOut",    { type = "bezier", points = { { 0.3,  0.0 }, { 0,   1.0  } } })
hl.curve("liner",     { type = "bezier", points = { { 1,    1   }, { 1,   1    } } })
hl.curve("overshot",  { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.5,  0.0 }, { 0.99, 0.99 } } })
hl.curve("smoothIn",  { type = "bezier", points = { { 0.5, -0.5 }, { 0.68, 1.5 } } })

-- Window animations: standardised, fast and minimal
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 2,  bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2,  bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 2,  bezier = "wind",      style = "slide" })
hl.animation({ leaf = "border",           enabled = true, speed = 1,  bezier = "liner" })
hl.animation({ leaf = "fade",             enabled = true, speed = 2,  bezier = "smoothOut" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 2,  bezier = "wind",      style = "slidevert" })

-- Scratchpads (special workspace): slide up on open, down on close
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,  bezier = "wind",      style = "slidevert" })

-- UI layers (bars, panels, wallpaper) with smooth fade on login
hl.animation({ leaf = "layersIn",         enabled = true, speed = 4,  bezier = "smoothOut", style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2,  bezier = "winOut" })
