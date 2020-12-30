-- {{{ Tags
sharedtags = require("awesome-sharedtags")
tags = sharedtags({
    -- Create all tags, only non-empty and focused will be shown
    -- Set tiling ratio for the master window to approx. the golden ratio
    -- Default layout is tiling (2)
    { name = "1", screen = 1, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "2", screen = 2, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "3", screen = 3, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "4", screen = 1, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "5", screen = 1, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "6", screen = 1, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "7", screen = 1, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "8", screen = 1, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "9", screen = 1, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    { name = "0", screen = 1, layout = awful.layout.layouts[2], master_width_factor = 0.62},
    -- { layout = awful.layout.layouts[2] },
    -- { screen = 2, layout = awful.layout.layouts[2] }
})

return tags
