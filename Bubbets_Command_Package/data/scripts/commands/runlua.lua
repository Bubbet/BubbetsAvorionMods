package.path = package.path .. ";data/scripts/lib/?.lua"
local chf = include("commandhelperfunctions")

function execute(sender, _, ...)

	local args = {...}
	local code = loadstring([[
		package.path = package.path .. ';data/scripts/lib/?.lua';
		include('utility');
	]] .. (args and table.concat(args, " ")))

	local ret = code()

	return 1, "", "Lua ran, returned: " .. (ret or "No return value.")
end

function getDescription()
	return "A better run command that doesn't try to print the outputs."
end

function getHelp()
	return "Usage: /runlua code"
end
