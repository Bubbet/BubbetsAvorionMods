--[[
tabWindow = nil

function printable(...)
	local args = {...}
	for _, v in pairs(args) do
		if type(v) == "table" then
			printTable(v)
		else
			print(v)
		end
	end
end


local function hook()
	--printTable(debug.getinfo(debug.getinfo( 2, "f" ).func))
	if debug.getinfo( 3, "f" ).func == initUI then
		--local i, name, value = 1, debug.getlocal( 2, 1 )
		--printable("this", debug.getlocal( 2, 5 ))
		local name, value
		for i = -10, 80 do
			--if type(value) == "userdata" then
				print((type(value) == "userdata") and value.__avoriontype or type(value), name, type(value) == "table" and "TABLE" or value, i)
				tabWindow = value
			--end
			i, name, value = i+1, debug.getlocal( 2, i )
		end
		--tabWindow = debug.getlocal(2, 5)
	end
		--[[
		print("found")
		local i, name, value = 2, debug.getlocal( 2, 1 )
		print(i, "HOOK", name, value)
		while name do
			if #name == 1 then
				print(i, "HOOK", name, value )
			end
			print(i, "HOOK", name, value )
			i, name, value = i+1, debug.getlocal( 2, i )
		end
	end--]
end

local old_initUI = initUI
function initUI()
	debug.sethook( hook, "r" )
	old_initUI()
	debug.sethook()
	print(tabWindow)
	local tab = tabWindow:createTab("Entity", "data/textures/icons/ship.png", "Fuck your locals")
end
]]

function ind(self, ind) return self.element[ind] end
function newidn(self, ind, val) self.element[ind] = val end
local old_scriptUI = ScriptUI
function ScriptUI() -- Absolute galaxy brain play here
	local x = {element = old_scriptUI(), children = {}}
	for k, v in pairs(getmetatable(x.element)) do
		x[k] = function(self, ...) return v(self.element, ...) end
	end
	local old_createWindow = x["createWindow"]
	x["createWindow"] = function(self, rect)
		local y = {element = self.element:createWindow(rect), children = {}}
		for k, v in pairs(getmetatable(y.element)) do
			y[k] = function(self, ...) return v(self.element, ...) end
		end
		y["createTabbedWindow"] = function(self, rect)
			local z = self.element:createTabbedWindow(rect)
			table.insert(self.children, z)
			return z
		end
		setmetatable(y, {__index = ind, __newindex = newind})
		self["createWindow"] = old_createWindow -- Set things back to default so we dont have dumb stuff happening
		return y
	end
	x["registerWindow"] = function(self, window, ...) self.element:registerWindow(window.element, ...) end
	setmetatable(x, {__index = ind, __newindex = newind})
	return x
end

package.path = package.path .. ";data/scripts/lib/gravyui/?.lua"
local Node = include("Node")
include("callable")

function setReturn(text) code_return_label.caption = text or "No return value." end
function onCodeClear() code_box.text = "" end
function onCodeRun(_, _, input)
	if onClient() then invokeServerFunction("onCodeRun", _, _, code_box.text) end
	local code = loadstring([[
		package.path = package.path .. ';data/scripts/lib/?.lua';
		include('utility');
	]] .. (input or code_box.text))
	local ret = code and code()
	if onServer() then
		invokeClientFunction(Player(callingPlayer), "setReturn", ret)
	else
		setReturn(ret)
	end
end
callable(nil, "onCodeRun")

local old_initUI = initUI
function initUI()
	old_initUI()
	window.element.caption = "Debug" -- lmao more bandaid fixes because thats the whole thing here
	window.element.showCloseButton = 1
	window.element.moveable = 1
	local tabbedWindow = window.children[1]
	---@type Tab
	local tab = tabbedWindow:createTab("Entity", "data/textures/icons/ship.png", "Run Lua")
	local root_node = Node(tab.size)
	local top, mid, bottom = root_node:rows({1, 10, 20}, 10)
	code_box = tab:createMultiLineTextBox(top.rect)
	code_return_label = tab:createLabel(mid.rect, "No return value.", 14)
	code_return_label:setLeftAligned()
	local left, right = bottom:cols(2, 10)
	tab:createButton(left.rect, 'Clear', 'onCodeClear')
	tab:createButton(right.rect, 'Run', 'onCodeRun')
end
