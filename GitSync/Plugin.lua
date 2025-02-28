-- @ScriptType: Script
local toolbar = plugin:CreateToolbar("GitHub Sync")
local button = toolbar:CreateButton("Push/Pull/Update", "Push, Pull, and Update Selected Scripts to and from GitHub", "rbxassetid://120039353796013", "Toggle")
local settingsBTN = toolbar:CreateButton("Settings", "Configure GitSync Settings", "rbxassetid://140418971118966", "Settings")
local erepo = plugin:GetSetting("REPO") or "Enter GitHub Repo (e.g. user/repository)"
local key = plugin:GetSetting("TOKEN") or "Enter GitHub Token"

local isOpenUI = false
local isOpenSettings = false

local waiting = false
local waitTime = 1

local Interactions = require(script.Interactions)
local Functions = require(script.Functions)
local Style = require(script.Style)
Style.Init(plugin)

-- HEY HEY HEY THIS WSNT HERE BEFORE!
--[[
NOW WE ARE TESTING.....
PUSHING WITH PUT

UPDATING WITH SHA!

PULLING WITH FETCH (and stuff)
ACCIDENTALLY PULLED OLD VERSION OVER NEW VERSION LUCKILY THERE ARE BACKUPS
]]


--local widgetInfo = DockWidgetPluginGuiInfo.new(
--	Enum.InitialDockState.Float, true, false, 300, 400, 394, 337
--)

--local widget = plugin:CreateDockWidgetPluginGui("GitHubSync", widgetInfo)

local CoreGui = game:GetService("CoreGui")

-- Check if the UI already exists
local ui = script:FindFirstChild("GitSyncUI")
local settingsui = script:FindFirstChild("SettingsUI")
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right, false, false, 300, 200, 300, 200
)
local explorer_widget = plugin:CreateDockWidgetPluginGui("GitHubSyncExplorer", widgetInfo)
explorer_widget.Title = "Git Explorer"
local explorer_frame = script.ExplorerWindow
explorer_frame.Parent = explorer_widget
explorer_frame.Size = UDim2.fromScale(1,1)

if not ui then
	warn("UI not found in the script!")
	return
end

if not settingsui then
	warn("Settings UI not found in the script!")
	return
end

-- Clone and move the UI into CoreGui
local uiClone = ui:Clone()
uiClone.Parent = CoreGui
uiClone.Enabled = false

local settingsuiClone = settingsui:Clone()
settingsuiClone.Parent = CoreGui
settingsuiClone.Enabled = false

button.Click:Connect(function()
	isOpenUI = not isOpenUI
	uiClone.Enabled = isOpenUI
	
	if isOpenUI == false then
		settingsuiClone.Enabled = false
	end
end)

settingsBTN.Click:Connect(function()
	isOpenSettings = not isOpenSettings
	settingsuiClone.Enabled = isOpenSettings
end)

plugin.Unloading:Connect(function()
	if uiClone then
		uiClone:Destroy()
	end
end)


local frame = uiClone.Frame

Style.makeDraggable(frame)

local t = frame.ScrollingFrame.template

local pushButton = frame.PushBTN
local pullButton = frame.PullBTN
local loadRepoButton = frame.ViewRepoBTN

local HttpService = game:GetService("HttpService")







--uiClone.Frame.Frame.dragger.MouseButton1Down:Connect(function(x,y)
--	repeat
--	local lastpos = UDim2.fromOffset(plugin:GetMouse().X, plugin:GetMouse().Y + 27)
--	frame.Position = lastpos
--	task.wait()
--	until uiClone.Frame.Frame.dragger.MouseButton1Up
--end)


local textbox = frame.repoBOX
textbox.Text = erepo

local tokenBox = frame.tokenBOX
tokenBox.Text = key

frame.Close.MouseButton1Click:Connect(function()
	isOpenUI = not isOpenUI
	uiClone.Enabled = isOpenUI

	if isOpenUI == false then
		settingsuiClone.Enabled = false
	end
end)

pushButton.MouseButton1Click:Connect(function()
	if not(waiting) then
		waiting = true
		pushButton.ImageLabel.ImageColor3 = Color3.fromRGB(88, 166, 255)
		local repo = textbox.Text
		local token = tokenBox.Text
		if repo ~= "" and token ~= "" then
			plugin:SetSetting("REPO", repo)
			plugin:SetSetting("TOKEN", token)

			Interactions.pushToGitHub(repo, token, pushButton)
		else
			warn("Enter both the repository name and token")
			pushButton.ImageLabel.ImageColor3 = Color3.fromRGB(248, 81, 73)
		end

		task.wait(waitTime)
		pushButton.ImageLabel.Image = ui.push.Value
		pushButton.ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
		waiting = false
	end
end)

pullButton.MouseButton1Click:Connect(function()
	if not(waiting) then
		waiting = true
		pullButton.ImageLabel.ImageColor3 = Color3.fromRGB(88, 166, 255)
		local repo = textbox.Text
		local token = tokenBox.Text

		if repo ~= "" and token ~= "" then
			plugin:SetSetting("REPO", repo)
			plugin:SetSetting("TOKEN", token)

			Interactions.pullFromGitHub(repo, token, pullButton)
		else
			warn("Enter both the repository name and token")
			pullButton.ImageLabel.ImageColor3 = Color3.fromRGB(248, 81, 73)
		end

		task.wait(waitTime)
		pullButton.ImageLabel.Image = ui.pull.Value
		pullButton.ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
		waiting = false
	end
end)

loadRepoButton.MouseButton1Click:Connect(function()
	local repo = textbox.Text
	local token = tokenBox.Text
	if repo ~= "" and token ~= "" then
		explorer_widget.Enabled = true
		
		for i, v in pairs(explorer_frame.ScrollingFrame:GetChildren()) do
			if v:IsA("TextButton") or v:IsA("Frame") then
				v:Destroy()
			end
		end
		
		Functions.populateExplorer(repo, token, explorer_frame.ScrollingFrame, "")
	else
		warn("Enter both repository name and token.")
	end
end)

while task.wait(.05) do
	local scripts = Functions.getSelectedScripts()

	for i, v in pairs(frame.ScrollingFrame:GetChildren()) do
		if not(scripts[v.Name]) and v ~= t and v:IsA("TextLabel") then
			v:Destroy()
		end
	end

	for name, data in pairs(scripts) do
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