-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local mywidget = require("mywidget")
local cjson = require('cjson')

cjson.encode_sparse_array(true)

home_dir = os.getenv("HOME")
-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

function debugIt(val)
  naughty.notify(
    {
      preset = naughty.config.presets.critical,
      title = "debug",
      text = cjson.encode(val)
    }
  )
end
-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

awful.util.spawn('guake')

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(home_dir .. "/.config/awesome/themes/my/theme.lua")

if beautiful.wallpaper then
  if beautiful.background_color then
    bg_color = beautiful.background_color
  else
    bg_color = "#000000"
  end 

  bg_surface = gears.surface.load(beautiful.wallpaper)

--  bg_timer = timer { timeout = 5 }
--  bg_timer:connect_signal("timeout", function()
--      awful.util.spawn(home_dir .. '/.config/awesome/bg',false)
--      bg_surface = gears.surface.load_uncached(beautiful.wallpaper)
--      for s = 1, screen.count() do
--          gears.wallpaper.fit(beautiful.wallpaper,s,bg_color)
--      end
--      bg_timer:stop()
--      bg_timer.timeout = 5
--      bg_timer:start()
--    end 
--  )

  for s = 1, screen.count() do
      gears.wallpaper.fit(bg_surface,s,bg_color)
  end
--  bg_timer:start()
end

-- This is used later as the default terminal and editor to run.
terminal = "gnome-terminal"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}
box_layout = {}
box = {}
mylauncher = {}
layout = {}
right_layout = {}
command = {}
clock_box = {}
command_box = {}
clientsPosition = {}

batteryHistory = {}
batteryHistorySize = 0
batteryWidth = 500

for s = 1, screen.count() do
  mylauncher[s] = awful.widget.launcher({ image = beautiful.awesome_icon, menu = awful.menu.clients() })

  mylauncher[s]:connect_signal("button::press",function ()
      mylauncher[mouse.screen].menu = awful.menu.clients({x = 1900})
    end
  )

  layout[s] = wibox.layout.fixed.horizontal()

  if s == 1 then

    fcfull = io.open('/sys/class/power_supply/BAT1/charge_full')
    cfull = fcfull:read()
    fcfull:close()

    fcnow = io.open('/sys/class/power_supply/BAT1/charge_now')
    cnow = fcnow:read()
    fcnow:close()

    percents = 100*cnow/cfull

    local batteryGraph = wibox.widget.base.make_widget()
    batteryGraph.fit = function(mycross, width, height)
       return batteryWidth, height
    end
    
    batteryGraph.draw = function(mycross, wibox, cr, width, height)
    end
   

    battery = wibox.widget.textbox()
    battery.fit = function(mycross, width, height)
       return 80, height
    end

    layout[s]:add(batteryGraph)
    layout[s]:add(battery)
    
    battery:set_text(math.floor(percents) .. "% ?h ??m")
    
    batteryInterval = 30
    batteryTimer = timer({timeout = batteryInterval})
    batteryTimer:connect_signal('timeout', function () 
      fcnow = io.open('/sys/class/power_supply/BAT1/charge_now')
      cnow = fcnow:read()
      fcnow:close()
      diff = percents - 100*cnow/cfull
      percents = 100*cnow/cfull
      if diff >=0 then
        seconds = batteryInterval*percents/diff
      else
        seconds = batteryInterval*(100 - percents)/diff
      end
      hour = math.floor(seconds/3600)
      minutes = math.floor(seconds/60 - hour*60)
      battery:set_text(math.floor(percents) .. "% " .. hour .. 'h ' .. minutes ..'m')

      table.insert(batteryHistory, percents)
      batteryHistorySize = batteryHistorySize + 1
      if batteryHistorySize >= batteryWidth then
        table.remove(batteryHistory, 1)
        batteryHistorySize = batteryHistorySize - 1
      end

      flog = io.open('/tmp/battery.log','a+')
      flog:write(os.time() .. ',' ..percents .. "\n")
      flog:close()

      batteryGraph.draw = function(mycross, wibox, cr, width, height)
          
          prev = batteryHistory[1]
          maxD = 0
          for i,p in ipairs(batteryHistory) do 
            d = math.abs(prev - p)

            if (maxD < d) then
              maxD = d
            end
            prev = p
          end  

          x = batteryWidth - batteryHistorySize
          prev = batteryHistory[1]
          for i,p in ipairs(batteryHistory) do 
            d = math.abs(prev - p)
            if (maxD == 0) then
              h = height
            else
              h = math.floor(height * d / maxD)
            end

             -- naughty.notify({ preset = naughty.config.presets.critical,
             --  title = '',
             --  text = cjson.encode({i, h,d,maxD})})

            if (prev <= p) then
              cr:set_source_rgba(0, 255, 0, 0.3)
            else
              cr:set_source_rgba(255, 0, 0, 0.5)
            end 
            cr:move_to(x, height)
            cr:line_to(x, height - h)
            cr:set_line_width(0.5)
            cr:stroke()
            x = x + 1
            prev = p
          end
      end

      batteryGraph:emit_signal("widget::updated")

    end)
    batteryTimer:start()
    
    layout[s]:add(wibox.widget.systray())
    
  end 

  layout[s]:add(awful.widget.textclock())
  layout[s]:add(awful.widget.layoutbox(s))

  layout[s]:add(mylauncher[s])

  right_layout[s] = wibox.layout.align.horizontal()
  right_layout[s]:set_right(layout[s])
  command[s] = awful.widget.prompt({prompt = ': '})

  box_layout[s] = wibox.layout.align.horizontal();
  box_layout[s]:set_left(command[s])
  box_layout[s]:set_right(right_layout[s])

  box[s] = awful.wibox( { type = "normal", position = "bottom", screen = s, ontop = false, height = 16 } )
  box[s]:set_bg("#ffffff00")
  box[s]:set_widget(box_layout[s])
end

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey}, "Left", 
      function()
        fb = io.open('/sys/class/backlight/intel_backlight/brightness', 'w+')
        br = tonumber(fb:read())
        fb:write(0)
        fb:close()
      end
    ),
    awful.key({ modkey}, "Right", 
      function()
        fb = io.open('/sys/class/backlight/intel_backlight/brightness', 'w+')
        br = tonumber(fb:read())
        fb:write(187)
        fb:close()
      end
    ),
    awful.key({ modkey}, "Up", 
      function()
        fb = io.open('/sys/class/backlight/intel_backlight/brightness', 'w+')
        br = tonumber(fb:read())
        br = br + 3
        if (br > 187) then
          br = 187
        end

        fb:write(br)
        fb:close()
      end
    ),
    awful.key({ modkey}, "Down", 
      function()
        fb = io.open('/sys/class/backlight/intel_backlight/brightness', 'w+')
        br = tonumber(fb:read())
        br = br - 3
        if (br < 0) then
          br = 0
        end

        fb:write(br)
        fb:close()
      end
    ),
    awful.key({ modkey}, "h", 
      function ()
        clientsPosition = {}
        
        for c in awful.client.iterate(function(c)  return true end) do    
            clientsPosition[c.window] = {
              geometry = c:geometry(),
              screen = c.screen,
              tag = awful.tag.getidx(c:tags()[1]),
              sx = screen[c.screen].geometry.x,
              sy = screen[c.screen].geometry.y,
            }
        end
        cPos = io.open('/tmp/clients_position','w+')
        cPos:write(cjson.encode(clientsPosition))
        cPos:close()
        os.execute("xrandr --output HDMI2 --mode 3840x2160 --left-of eDP1") 
      end 
    ),
    awful.key({ modkey}, "l", 
      function () 
        os.execute("xrandr --output HDMI2 --mode 1920x1080 --left-of eDP1")
      end 
    ),
    awful.key({ modkey }, "p", function () awful.util.spawn("poweroff") end ),
    awful.key({ modkey, "Control" }, "l", function () awful.util.spawn("xscreensaver-command -lock") end),
    -- Layout manipulation
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey, "Control" }, "space", function () awful.layout.set(awful.layout.suit.floating) end),

    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),
    -- Prompt
    awful.key({ modkey },            "r",     
    	function () 
         command[mouse.screen]:run()
    	end
    )
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "m",      function (c) c.maximized = not c.maximized  end),
    awful.key({ modkey, "Shift"   }, "m",      
      function (c)
        c.maximized = true
        geometry = c:geometry()
        c.maximized = false
        c:geometry(geometry)
      end
    ),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) 
      if c.instance ~= 'sun-awt-X11-XFramePeer' and c.instance ~= 'sun-awt-X11-XWindowPeer' and c.instance ~= 'sun-awt-X11-XDialogPeer' then
        -- naughty.notify({ preset = naughty.config.presets.critical,
        --            title = c.instance,
        --             text = c.class})
        client.focus = c; c:raise() 
      end
    end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { 
      rule_any = { class = {"cairo-dock", "Cairo-dock" } },
      properties = { border_width = 0 , ontop = false } },
    -- cliens without border
    { 
      rule_any = { class = { 
          "chrome", 
          "Chrome", 
          "x-www-browser", 
          "X-www-browser", 
          "chromium-browser", 
          "Chromium-browser",
          "chromium", 
          "Chromium",
          "guake",
          "Guake",
          "Main.py"
      } },
      properties = { 
        border_width = 0
      },
      callback = function (c)
        --c:connect_signal("property::y", function() c:geometry({x = 0, y = 0}) end)
        --c:connect_signal("property::x", function() c:geometry({x = 0, y = 0}) end)
      end
    },
    { 
      rule_any = { class = {  "sun-awt-X11-XFramePeer", "jetbrains-phpstorm"} },
      properties = { 
        border_width = 1
      },
      callback = function (c)
        --c:connect_signal("property::y", function() c:geometry({x = 0, y = -22}) end)
        --c:connect_signal("property::x", function() c:geometry({x = 0, y = -22}) end)
      end
    }
}
-- }}}

clientsPosition = {}
cPos = io.open('/tmp/clients_position','r')
if (cPos) then
  clientsPosition = cjson.decode(cPos:read())
  cPos:close()
end
--debugIt(clientsPosition)

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    -- c:connect_signal("mouse::enter", function(c)
    --     if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
    --         and awful.client.focus.filter(c) then
    ---         client.focus = c
    --     end
    -- end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
    awful.client.movetoscreen(c, mouse.screen)

    for id,data in pairs(clientsPosition) do
      id = id + 0
      if (id == c.window) then 
        awful.client.movetoscreen(c, data.screen)
        awful.client.movetotag(c, tags[tag])
        
        cgeometry = data.geometry
        data.geometry.x = screen[c.screen].geometry.x + data.geometry.x - data.sx;
        data.geometry.y = screen[c.screen].geometry.y + data.geometry.y - data.sy;
        c:geometry(cgeometry)
        --naughty.notify({ preset = naughty.config.presets.critical,
        --             title = c.name,
        --             text = cjson.encode(cgeometry)})
      end
    end

end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

browser = "chromium"