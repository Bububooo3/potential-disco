local toolbar = plugin:CreateToolbar("GitHub Sync")
local button = toolbar:CreateButton("Push", "Push Selected Scripts to GitHub", "")

local isOpen = false -- UI starts visible

-- HEY HEY HEY THIS WSNT HERE BEFORE!
--[[
NOW WE ARE TESTING.....

UPDATING WITH SHA!
]]


--local widgetInfo = DockWidgetPluginGuiInfo.new(
--	Enum.InitialDockState.Float, true, false, 300, 400, 394, 337
--)

--local widget = plugin:CreateDockWidgetPluginGui("GitHubSync", widgetInfo)

local CoreGui = game:GetService("CoreGui")

-- Check if the UI already exists
local ui = script:FindFirstChild("GitSyncUI")
if not ui then
	warn("UI not found in the script!")
	return
end

-- Clone and move the UI into CoreGui
local uiClone = ui:Clone()
uiClone.Parent = CoreGui
uiClone.Enabled = false

button.Click:Connect(function()
	isOpen = not isOpen
	uiClone.Enabled = isOpen
end)

plugin.Unloading:Connect(function()
	if uiClone then
		uiClone:Destroy()
	end
end)


local frame = uiClone.Frame

local t = frame.ScrollingFrame.template

local pushButton = frame.PushBTN

local HttpService = game:GetService("HttpService")

local selectedScripts = {}

local Selection = game:GetService("Selection")

local function getSelectedScripts()
	local selected = Selection:Get()
	local scripts = {}

	for _, obj in ipairs(selected) do
		if obj:IsA("Script") or obj:IsA("ModuleScript") or obj:IsA("LocalScript") then
			scripts[obj.Name] = obj.Source
		end
	end

	return scripts
end

-- this function converts a string to base64
function to_base64(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	return ((data:gsub('.', function(x) 
		local r,b='',x:byte()
		for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c=0
		for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end

-- this function converts base64 to string
function from_base64(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

local HttpService = game:GetService("HttpService")

local function getFileSHA(repo, token, filePath)
	local HttpService = game:GetService("HttpService")
	local url = "https://api.github.com/repos/" .. repo .. "/contents/" .. filePath

	local headers = {
		["Authorization"] = "token " .. token,
		["Accept"] = "application/vnd.github.v3+json"
	}

	local success, response = pcall(function()
		return HttpService:GetAsync(url, true, headers)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		return data.sha -- Return the SHA if the file exists
	else
		return nil -- File doesn't exist, so no SHA needed
	end
end


local function pushToGitHub(repo, token)
	local scripts = getSelectedScripts()
	local url = "https://api.github.com/repos/" .. repo .. "/contents/"

	if next(scripts) == nil then
		warn("No scripts selected!")
		return
	end

	for name, source in pairs(scripts) do
		local filePath = name .. ".lua"
		local fileUrl = url .. filePath

		-- Get SHA if the file exists
		local sha = getFileSHA(repo, token, filePath)

		local requestBody = {
			message = "Updated " .. filePath,
			content = to_base64(source),
			branch = "main"
		}

		-- Include SHA only if the file exists (GitHub requires this)
		if sha then
			requestBody.sha = sha
		end

		local headers = {
			["Authorization"] = "token " .. token,
			["Accept"] = "application/vnd.github.v3+json"
		}

		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = fileUrl,
				Method = "PUT",
				Headers = headers,
				Body = HttpService:JSONEncode(requestBody)
			})
		end)

		if success then
			print("Pushed: " .. filePath)
			print("Response: ", response) -- Debugging response
		else
			warn("Failed to push: " .. filePath)
			warn(response)
		end
	end
end



local textbox = frame.repoBOX

local tokenBox = frame.tokenBOX

pushButton.MouseButton1Click:Connect(function()
	local repo = textbox.Text
	local token = tokenBox.Text
	if repo ~= "" and token ~= "" then
		pushToGitHub(repo, token)
	else
		warn("Enter both the repository name and token")
	end
end)

while task.wait(.05) do
	local scripts = getSelectedScripts()
	
	for i, v in pairs(frame.ScrollingFrame:GetChildren()) do
		if not(scripts[v.Name]) and v ~= t and v:IsA("TextLabel") then
			v:Destroy()
		end
	end
	
	for name, source in pairs(scripts) do
		local scr = frame.ScrollingFrame
		
		if not(scr:FindFirstChild(name)) then
			temp = t:Clone()
			temp.Name = name
			temp.Text = name
			temp.Parent = frame.ScrollingFrame
			temp.Visible = true
		end
		
	end
	
end