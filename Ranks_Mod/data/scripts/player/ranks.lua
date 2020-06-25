package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")

-- namespace RanksPlayer
RanksPlayer = {}
RanksPlayer.privileges = {}--[[passPrivilege = false}
--[[
because script is bound to player we can treat each array as the players information
so when a permission is requested it is queued from server and stored in local array
because we have no way of knowing what the server actually says it'll return false on first attempt which should be fine
update the value every time its checked so if they lose the permission they're no longer able to interact with said object
]]
--[[
if onServer() then
    function RanksPlayer.getPrivilege(id, ...)
        local player = Player(id)
        local args = {...}
        for k, v in pairs(args) do
            local err, val = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "checkFor_", "privileges", player.id.id, v)
            invokeClientFunction(player, "setPrivilege", v, val)
        end
    end
    callable(RanksPlayer,"getPrivilege")
else
    function RanksPlayer.setPrivilege(privilege, val)
        RanksPlayer.privileges[privilege] = val
    end
end]]

function RanksPlayer.setAllPrivileges(privileges)
    if type(privileges) == "table" then
        RanksPlayer.privileges = privileges
    end
end

function RanksPlayer.sendToClient()
    local player = Player(callingPlayer)
    local err, privileges = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua","listPlayerPrivileges",player.id.id)
    invokeClientFunction(player, "setAllPrivileges", privileges)
end
callable(RanksPlayer,"sendToClient")

function RanksPlayer.initialize()
    if onClient() then
        invokeServerFunction("sendToClient")
    else
--        Player():registerCallback("onMailRead","onMailRead")
    end
end
--[[
function RanksPlayer.onMailRead(playerIndex, mailIndex)
    print("player",playerIndex,"mail",mailIndex)
    local mail = Player(playerIndex):getMail(mailIndex)
    for i = 1, mail:getNumItems() do
        local item = mail:getItem(i)
        print(item, type(item), item.__avoriontype, item.name)
    end
end
]]
function RanksPlayer.hasPrivilege(id, ...)
    if onClient() then
        --invokeServerFunction("getPrivilege", id, ...)
        local args = {...}
        local haspermission = true
        for _, privilege in pairs(args) do
            if not RanksPlayer.privileges[privilege] then
                haspermission = false
            end
        end
        return haspermission
    else
        local error, value = Galaxy():invokeFunction("data/scripts/galaxy/ranks.lua", "hasPrivilege", id, ...)
        return value
    end
end