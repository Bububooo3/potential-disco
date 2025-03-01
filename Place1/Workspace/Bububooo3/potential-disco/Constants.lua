-- @ScriptType: Script
export type slither_constants = {SpeedRange: NumberRange, Handling: number}

local Constants: slither_constants = {}

Constants.SpeedRange = NumberRange.new(0)
Constants.Handling = 0











--- Returns a table containing immutable game constants.
return setmetatable({}, {
	__index = Constants,
	__newindex = function() error("Attempt to modify read-only table") end
})
