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

-- Error handling
dofile("/home/vlapin/.config/awesome/error_handling.lua")

-- Variable definitions
dofile("/home/vlapin/.config/awesome/variables.lua")

-- Tags
dofile("/home/vlapin/.config/awesome/tags.lua")

-- Menu
dofile("/home/vlapin/.config/awesome/menu.lua")

-- Wibox
dofile("/home/vlapin/.config/awesome/wibox.lua")

-- Mouse bindings
dofile("/home/vlapin/.config/awesome/mouse_bindings.lua")

-- Key bindings
dofile("/home/vlapin/.config/awesome/key_bindings.lua")

-- Rules
dofile("/home/vlapin/.config/awesome/rules.lua")

-- Signals
dofile("/home/vlapin/.config/awesome/signals.lua")