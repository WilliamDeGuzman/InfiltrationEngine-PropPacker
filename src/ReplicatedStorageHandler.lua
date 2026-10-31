local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debug = require(script.Parent:WaitForChild("Debug"))

--[[
	The goal of ReplicatedStorageHandler is to place CustomProps
	within the CustomPropPacks folder into ReplicatedStorage so
	it can show up in PropPreview. This isnt done within the
	CustomProps folder because we don't want users messing with
	the props we load from the CustomPropPacks and we don't want
	to make the explorer scroll even longer. We also handle
	collisions where two prop packs have different names for the
	same prop!
]]

local ReplicatedStorageHandler = {}
-- Props pack folder is important!
local PropPacksFolder = workspace:WaitForChild("DebugMission"):WaitForChild("CustomPropPacks")

local ChildAddedEvent = PropPacksFolder.ChildAdded:Connect(function(child)
	Debug:clog("New props pack added: " .. child.Name)
	ReplicatedStorageHandler:refreshPropPacks()
end)
local ChildRemovedEvent = PropPacksFolder.ChildRemoved:Connect(function(child)
	Debug:clog("Props pack removed: " .. child.Name)
	ReplicatedStorageHandler:refreshPropPacks() 
end)
PropPacksFolder:GetPropertyChangedSignal("Parent"):Connect(function()
	Debug:clog("Parent change detection")
	if PropPacksFolder.Parent == nil then
		Debug:clog("Deleting events")
		ChildAddedEvent:Disconnect()
		ChildAddedEvent = nil
		ChildRemovedEvent:Disconnect()
		ChildRemovedEvent = nil
	end
end)

-- Anchors all parts of props and turns off cast shadow
function ReplicatedStorageHandler:setModelProperties (model) 
	for _, v in model:getChildren() do
		if #v:getChildren() ~= 0 then
			ReplicatedStorageHandler:setModelProperties (v)
		end
		pcall(function() 
			v.Anchored = true
			v.CastShadow = false
		end)
	end
end

-- Counts all props
function ReplicatedStorageHandler:getProps (pack, iterations, author)
	if not author then author = "" end
	if not iterations then iterations = 0 end
	local props = {} -- [ PropName = { [Author, String] } ]

	local propCount = 0
	for i, v in ipairs(pack:GetChildren()) do
		if iterations == 0 and (author == "" or v.Name == "CustomProps" or v.Name == "Folder") then 
			author = "MissingAuthor" .. i
		end
		
		if v:IsA("Folder") then
			local attributeAuthor = v:GetAttribute("Author")
			if attributeAuthor ~= nil and attributeAuthor ~= "" then 
				author = attributeAuthor
			end
			local subfolderProps = ReplicatedStorageHandler:getProps(v, iterations + 1, author)
			for prop, data in pairs(subfolderProps) do
				if not props[prop] then 
					props[prop] = data
				else
					table.insert(props[prop], 1, { ["Prop"] = data[1].Prop, ["Author"] = data[1].Author} )
				end
			end
		elseif v:IsA("Model") then
			local prop = v
			if not props[prop.Name] then
				props[prop.Name] = { {
					["Prop"] = prop, 
					["Author"] = author
				} }
			else
				props[prop][#props[prop] + 1] = {
					["Prop"] = prop,
					["Author"] = author
				}
			end
			
			ReplicatedStorageHandler:setModelProperties (v)
		end
	end
	return props
end

function ReplicatedStorageHandler:clearPropPacksFromReplicatedStorage() 
	for _, prop in ReplicatedStorage.Assets.Props:GetChildren() do
		if prop:GetAttribute("FromPropsPack") then
			prop:Destroy()
		end
	end
end

function ReplicatedStorageHandler:addPropPacksToReplicatedStorage(props) 
	for propName, propsWithName in props do
		for i, propData in propsWithName do
			local clone = propData.Prop:Clone()
			-- Collision was detected in the getter
			if #propsWithName ~= 1 then
				clone.Name ..= "_" .. propData.Author
			end
			clone:SetAttribute("FromPropsPack", true)
			clone:SetAttribute("Author", propData.Author)
			clone.Parent = ReplicatedStorage.Assets.Props
		end
	end
end

function ReplicatedStorageHandler:refreshPropPacks ()
	local props = ReplicatedStorageHandler:getProps(PropPacksFolder)
	Debug:clog (props)
	ReplicatedStorageHandler:clearPropPacksFromReplicatedStorage()
	ReplicatedStorageHandler:addPropPacksToReplicatedStorage(props)
end

return ReplicatedStorageHandler
