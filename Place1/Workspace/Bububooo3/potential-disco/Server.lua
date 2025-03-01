-- @ScriptType: Script
local slither_module = require(script.Main)
local constants = require(script.Configuration.Constants)

game.Players.PlayerAdded:Connect(function(plr)
	local moving_bool_val = Instance.new("BoolValue", plr)
	moving_bool_val.Name = "Moving"
	moving_bool_val.Value = false
	
	slither_module.new(plr)
end)