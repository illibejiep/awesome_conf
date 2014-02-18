-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Load Debian menu entries
require("debian.menu")

awful.util.spawn_with_shell('~/init')
awful.util.spawn_with_shell("xscreensaver -no-splash")

home_dir = os.getenv("HOME")
-- Error handling
dofile(home_dir .. "/.config/awesome/error_handling.lua")

-- Themes define colours, icons, and wallpapers
beautiful.init(home_dir .. "/.config/awesome/themes/my/theme.lua")

-- Variable definitions
dofile(home_dir .. "/.config/awesome/variables.lua")

-- Tags
dofile(home_dir .. "/.config/awesome/tags.lua")

-- Menu
dofile(home_dir .. "/.config/awesome/menu.lua")

-- Wibox
dofile(home_dir .. "/.config/awesome/wibox.lua")

-- Mouse bindings
dofile(home_dir .. "/.config/awesome/mouse_bindings.lua")

-- Key bindings
dofile(home_dir .. "/.config/awesome/key_bindings.lua")

-- Rules
dofile(home_dir .. "/.config/awesome/rules.lua")

-- Signals
dofile(home_dir .. "/.config/awesome/signals.lua")