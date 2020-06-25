local welcome = Mail() -- You cannot reset the default group's welcome bonus so don't mess it up. (it'd be a ton of extra work to make it work with the default group)
welcome.header = "Welcome to the server!"
welcome.text = "We hope you enjoy your stay."
--welcome.money = 100000
--welcome:setResources(10000,1000,100) -- 10000 iron, 1000 titanium, 100 naonite

local daily = Mail()
daily.header = "Daily Login Bonus"
daily.text = "Thanks for logging in today!"

local default = {
    name = "Default",
    power = math.huge, -- EXAMPLE NUMBERS: 0 being owner, 1 being super admin, 2 being admin, 3 being moderator, 4 being trial moderator, 5 donator -- Used when comparing power over other users
    mail = welcome, -- generally you wont want to change this, instead change the code above -- You cannot reset the default group's welcome bonus so don't mess it up. (it'd be a ton of extra work to make it work with the default group)
    --daily = {seconds = 24*60*60, mail = daily}, -- commented out by default
    commands = {}, -- commands this rank can use
    privileges = {} -- permissions this rank has for use in other mods
} -- Changed so it isn't a tailcall so other people are actually able to mod this file

return default
