-- =========================================================================
-- Hyprland monitor and workspace configuration (Lua module)
-- =========================================================================

-- Laptop internal display
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
-- Generic external monitor / hotplug
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
