-- @ScriptType: ModuleScript
local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")

local selectedScripts = {}
local entries = 0

--- BEGIN CODE ---
	
local Functions = {}





function Functions.getScriptPath(scriptFile)
	local path = scriptFile.Name .. ".lua"
	local parent = scriptFile.Parent
	while parent and parent:IsA("Folder") do
		task.wait()
		path = parent.Name .. "/" .. path
		parent = parent.Parent
	end
	return path
end





function Functions.getRepoContents(repo, token, path)
	local url = "https://api.github.com/repos/" .. repo .. "/contents/" .. (path or "")
	local headers = {
		["Authorization"] = "token " .. token,
		["Accept"] = "application/vnd.github.v3+json"
	}

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = headers
		})
	end)

	if success then
		return HttpService:JSONDecode(response.Body)
	else
		warn("Failed to fetch repository contents.")
		return nil
	end
end





function Functions.createEntry(name, parentFrame, isFolder)
	local entry = script.templatefileindicator:Clone()
	
	entry.template.Text = name
	entry.Name = name
	entry.LayoutOrder = entries
	
	if isFolder then
		entry.template.Text = "<b>"..entry.template.Text.."</b>"
		entry.template.TextColor3 = Color3.fromRGB(160, 182, 170)
	end
	
	entry.LayoutOrder = entries

	local folder = script.templatefolder:Clone()
	folder.LayoutOrder = entry.LayoutOrder+1

	entry.MouseButton1Click:Connect(function()
		folder.Visible = not(folder.Visible)
	end)
	
	entry.Visible = true
	entry.Parent = parentFrame
	folder.Parent = parentFrame
	folder.Visible = false
	
	entries += 2
	return entry, folder
end




function Functions.populateExplorer(repo, token, parentFrame, path)
	local contents = Functions.getRepoContents(repo, token, path)

	if not contents then return end

	for _, item in ipairs(contents) do
		local isFolder = (item.type == "dir")
		local entry, fldr = Functions.createEntry(item.name, parentFrame, isFolder)

		if isFolder then
			-- Recursively populate folders
			Functions.populateExplorer(repo, token, fldr, item.path)
		else
			-- Clicking a file will print its content (you can add file viewer functionality)
			entry.MouseButton1Click:Connect(function()		
				--if fldr.Visible == true then
				--	fldr.Visible = true
				--else
				--	fldr.Visible = false
				--end
			end)
		end
	end
end







function Functions.getFileSHA(repo, token, filePath)
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





function Functions.createFolder(repo, folderPath, token)
	local url = "https://api.github.com/repos/" .. repo .. "/contents/" .. folderPath .. "/.gitkeep"

	local requestBody = HttpService:JSONEncode({
		message = "Created folder: " .. folderPath,
		content = Functions.to_base64("Placeholder file to keep folder"),
		branch = "main"
	})

	local headers = {
		["Authorization"] = "token " .. token,
		["Accept"] = "application/vnd.github.v3+json"
	}

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "PUT",
			Headers = headers,
			Body = requestBody
		})
	end)

	if success then
		print("Successfully created folder: " .. folderPath)
	else
		warn("Failed to create folder: " .. response)
	end
end




function Functions.ensureFolderExists(path, parent)
	local folderNames = string.split(path, "/")
	for _, folderName in ipairs(folderNames) do
		local existingFolder = parent:FindFirstChild(folderName)
		if not existingFolder then
			existingFolder = Instance.new("Folder")
			existingFolder.Name = folderName
			existingFolder.Parent = parent
		end
		parent = existingFolder
	end
	print("Created folder path: " .. path)
	return parent
end




local scriptsSeen = {}
function Functions.scanFolder(folder, path)
	for _, obj in ipairs(folder:GetChildren()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			scriptsSeen[obj.Name] = {["Source"] = obj.Source, ["Class"] = obj.ClassName, ["Object"] = obj}

		end
		
		if #obj:GetChildren() > 0 then
			Functions.scanFolder(obj, path .. obj.Name .. "/") -- Recursively scan subfolders
		end
	end
	
	return true
end





function Functions.getSelectedScripts()
	local selected = Selection:Get()
	scriptsSeen = {}

	for _, obj in ipairs(selected) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			scriptsSeen[obj.Name] = {["Source"] = obj.Source, ["Class"] = obj.ClassName, ["Object"] = obj}

		end
		
		if #obj:GetChildren() > 0 then

			Functions.scanFolder(obj, obj.Name .. "/")
		end
	end

	return scriptsSeen
end





function Functions.to_base64(data)
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





function Functions.from_base64(data)
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

return Functions
