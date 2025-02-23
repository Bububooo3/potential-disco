local Slither = {}

local constants = require(script.Parent.Configuration.Constants)

export type Snake =  {}

function Slither.new(plr): Snake
	local mover = {}
	
	mover["Name"] = plr.Name
	
	return mover
end



return Slither
