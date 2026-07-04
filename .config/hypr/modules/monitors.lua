-- =========================================================================
-- Hyprland Monitors & Workspaces (Lua Module)
-- =========================================================================

-- Primary laptop display
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Fallback for external monitors / hotplug
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Persistent workspaces (1 through 10)
for i = 1, 10 do
    hl.workspace_rule({
        workspace  = tostring(i),
        persistent = true,
    })
end
