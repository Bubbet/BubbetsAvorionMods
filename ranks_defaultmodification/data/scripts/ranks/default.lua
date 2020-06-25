local welcome = Mail() -- You cannot reset the default group's welcome bonus so don't mess it up. (it'd be a ton of extra work to make it work with the default group)
welcome.header = "Welcome to the server!"
welcome.text = "We hope you enjoy your stay."
welcome.money = 100000
welcome:setResources(10000,1000,100) -- 10000 iron, 1000 titanium, 100 naonite