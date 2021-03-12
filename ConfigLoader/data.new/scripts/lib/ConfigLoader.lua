package.path = package.path .. ";data/scripts/lib/?.lua"
ConfigLoaderDisk = include("ConfigLoaderDisk") -- Should go unused.
--include("utility")

local DebugOn = false
function localConfig()
  local path = getScriptPath()
  if onClient() then
    return ConfigLoaderDisk:getConfig("/moddata/ConfigLoader", path)
  else
    return ConfigLoaderDisk:getConfig(Server().folder.."moddata/ConfigLoader", path)
  end
end

function getConfig()
  local path, err, val = getScriptPath()
  if onClient() then
    local psucceeded, player = pcall(function() return Player() end)
    if player and valid(player) then
      err, val = player:invokeFunction("data/scripts/player/ConfigLoaderPlayerHelper.lua", "getConfig", path)
      if not val then
        if DebugOn then
          print('Client player invoke failed with error:', err, 'for path', path)
          if err == 3 then
            printTable(player:getScripts())
          end
        end
        val = localConfig()
      end
    else
      if DebugOn then
        print('Client falling back on local config for path', path)
      end
      val = localConfig()
    end

  else

    local function tryGalaxy(path)
      local psucceeded, galaxy = pcall(function() return Galaxy() end)
      if galaxy then
        local err, val = galaxy:invokeFunction("data/scripts/galaxy/ConfigLoaderGalaxy.lua", "getConfig", path)
        if not val then
          if DebugOn then
            print('Server galaxy invoke failed with error:', err, 'for path', path, '\nFalling back on local config for path', path)
            if err == 3 then
              printTable(galaxy:getScripts())
            end
          end
          val = localConfig()
        end
        return val
      end
    end

    local psucceeded, entity
    if not string.find(path, 'commands') then
      psucceeded, entity =  pcall(function() return Entity() end)
    end
    if entity then
      err, val = entity:invokeFunction("data/scripts/entity/ConfigLoaderEntityHelper.lua", "getConfig", path)
      if not val then
        if DebugOn then
          print('Server entity invoke failed with error:', err, 'for path', path)
          if err == 3 then
            printTable(entity:getScripts())
          end
        end
        val = tryGalaxy(path)
      end
    else
      val = tryGalaxy(path)
    end

  end
  return val
end

function updateConfig(self)
  self.___config = getConfig()
end

-- Using this delayed initialization i can avoid indexing Players etc before the game is ready for it in most cases
function index(self, ind, ...)
  if type(self.___config[ind]) == 'nil' then
    self:___updateConfig()
  end
  self.___config.___funcs = self.___config.___funcs or {}
  if self.___config.___funcs[ind] then
    local func = function(_, ...)
      local internal = loadstring('return '..self.___config.___funcs[ind])
      internal = internal()
      return internal(...)
    end
    local newvalue = {__tostring = self.___config.___funcs[ind]}
    setmetatable(newvalue, {__call = func})
    self.___config[ind] = newvalue
  end
  return self.___config[ind]
end
function newindex(self, ind, val)
  if type(self.___config[ind]) == 'nil' then
    self:___updateConfig()
    --self.local_config = localConfig()
    --return self.local_config[ind]
  end
  self.___config[ind] = val
end
-- Potentially look at moving ___config into metadata to avoid conflicts, though you'd think no one would overwrite that value right?
return setmetatable({___config = {}, ___updateConfig = updateConfig},{__index = index})--, __newindex = newindex})
