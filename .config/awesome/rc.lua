-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
require("vicious")
require("calendar2")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/dust/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt -g 80x30+10+40"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor
icon_theme = "/home/el/.icons/black-white_2-Style"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.top,
    awful.layout.suit.max,
    awful.layout.suit.floating
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ " one "," two "," three "," four ", }, s, awful.layout.suit.max)
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Terminal", "urxvt" },
                                    { "Firefox", "firefox" },
                                    { "Pidgin", "pidgin" },
                                    { "Chrome", "google-chrome" },
                                    { "Nicotine", "nicotine" },
                                    { "Thunar", "thunar" },
                                    { "Rhythmbox", "rhythmbox" },
                                    { "VirtualBox", "VirtualBox" },
                                    { "Gimp", "gimp" }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
--Spacer widget
spacer = widget({ type = "textbox"})
spacer.text = "   "
seperator = widget({type="textbox"})
seperator.text = "|"
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right", format = " %a %b %d, %l:%M %p " })
-- attach calendar to textclock
calendar2.addCalendarToWidget(mytextclock, "<span color='green'>%s</span>")

-- Create a systray
mysystray = widget({ type = "systray", align = "right" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
-- Initialize widget
cpuwidget = awful.widget.graph()
-- Graph properties
cpuwidget:set_width(50)
cpuwidget:set_background_color("#494B4F")
cpuwidget:set_color("#FF5656")
cpuwidget:set_gradient_colors({ "#FF5656", "#88A175", "#AECF96" })
-- Register widget
vicious.register(cpuwidget, vicious.widgets.cpu, "$1")


mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

-- }}}
-- {{{ My custom widgets
--dofile "/home/el/.config/awesome/widgets.lua"
--}}}
 
-- {{{ for s = 1, screen.count()
for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", height = 16, screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mytaglist[s], spacer,
            mypromptbox[s],
            cpuwidget.widget, spacer,
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        s == 1 and mytextclock or nil,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end)
--    awful.button({ }, 4, awful.tag.viewnext),
--    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "r", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"  }, "e", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"  }, "w", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, }, "e", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, }, "w", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey,           }, "q", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
--    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- My program
    awful.key({ modkey, }, "f", function () awful.util.spawn("firefox") end),
    awful.key({ modkey, }, "t", function () awful.util.spawn("thunderbird") end),
    awful.key({ modkey, }, "u", function () awful.util.spawn("google-chrome") end),
    awful.key({ modkey, }, "p", function () awful.util.spawn("pidgin") end),
    awful.key({ modkey, }, "g", function () awful.util.spawn("gvim") end),
    awful.key({ modkey, }, "v", function () awful.util.spawn("thunar") end),
    awful.key({ }, "XF86Terminal", function () awful.util.spawn(terminal) end),

    -- Mulimedia
    awful.key({ }, "XF86AudioRaiseVolume", function () awful.util.spawn("dvol -i 3") end),
    awful.key({ }, "XF86AudioLowerVolume", function () awful.util.spawn("dvol -d 3") end),
    awful.key({ }, "XF86AudioMute", function () awful.util.spawn("dvol -t") end),
    awful.key({ }, "XF86AudioNext", function () awful.util.spawn("mocp -f") end),
    awful.key({ }, "XF86AudioPrev", function () awful.util.spawn("mocp -r") end),
    awful.key({ }, "XF86AudioPause", function () awful.util.spawn("mocp -G") end),
    awful.key({ modkey }, "i", function (c) c.minimize=true end),
    -- Prompt
    awful.key({ modkey },            "F1",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "F4",
        function ()
            awful.prompt.run({ prompt = "Run Lua code: " },
            mypromptbox[mouse.screen].widget,
            awful.util.eval, nil,
            awful.util.getdir("cache") .. "/history_eval")
        end)
)

-- Client awful tagging: this is useful to tag some clients and then do stuff like move to tag on them
clientkeys = awful.util.table.join(
--    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,		  }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey,		  }, "x",      function (c) c:kill()                         end),
    awful.key({ modkey, "Shift" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
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
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 1 of screen 2.
    { rule = { class = "Namoroka" },
      properties = { tag = tags[2][1], fullscreen = true } },
    { rule = { class = "google-chrome" },
        properties = { tag = tags[2][1], fullscreen = true } },
    { rule = { class = "Pidgin" }, properties = { tag = tags[1][4], 
      floating = true } },
    { rule = { class = "Skype" },
      properties = { tag = tags[1][4] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

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
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
