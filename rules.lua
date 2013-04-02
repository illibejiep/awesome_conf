awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },

    { 
      rule_any = { class = { "chrome", "Chrome", "x-www-browser", "X-www-browser", "chromium-browser", "Chromium-browser" } },
      properties = { 
        border_width = 0
      },
      callback = function (c)
        c:add_signal("property::y", function() c:geometry({x = 1280, y = 0}) end)
        c:add_signal("property::x", function() c:geometry({x = 1280, y = 0}) end)
      end
    },
    { 
      rule_any = { class = {  "sun-awt-X11-XFramePeer", "jetbrains-phpstorm"} },
      properties = { 
        border_width = 1
      },
      callback = function (c)
        c:add_signal("property::y", function() c:geometry({x = 1280, y = -22}) end)
        c:add_signal("property::x", function() c:geometry({x = 1280, y = -22}) end)
      end
    },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}