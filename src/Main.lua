local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorageHandler = require(script.Parent.ReplicatedStorageHandler)
local APIConsumer = require(script.Parent.APIConsumer)
local PropPacksFolder

local hookName = nil
local propPacker = {}

function propPacker.OnAPILoaded(api: APIReference, packerState)
	hookName = hookName or api.GetRegistrantFactory("mrwd", "PropPacker")
	local hookData = {}
	packerState[1] = api.AddHook("PreSerialize", hookName("PreSerialize"), propPacker.OnPreSerialize, hookData)
end

function propPacker.OnAPIUnloaded(api: APIReference, packerState)
	for _, token in ipairs(packerState) do
		api.RemoveHook(token)
	end
end

-- Load only relevant props into customprops
function propPacker.PopulateCustomProps(mission)
	local packAuthors = {}
	local props = ReplicatedStorageHandler:getProps(mission:FindFirstChild("CustomPropPacks"))
	for propname, propdata in props do
		local clone
		if #propdata ~= 1 then
			for i, data in propdata do
				if not mission.Props:FindFirstChild(propname .. "_" .. data.Author, true) then continue end
				clone = data.Prop:Clone()
				clone.Name = propname .. "_" .. data.Author
				clone.Parent = mission.CustomProps
				packAuthors[data.Author] = 1
			end
		elseif mission.Props:FindFirstChild(propname, true) and not mission.CustomProps:FindFirstChild(propname, true) then
			clone = propdata[1].Prop:Clone()
			clone.Parent = mission.CustomProps
			packAuthors[propdata[1].Author] = 1
		end
	end
	if packAuthors == {} then return end
	local desc = mission.CustomMissionSettings:FindFirstChild("MissionDesc")
	if not desc then return end
	desc.Value ..= "\nUsing props from: "
	local comma = "" -- not a comma yet
	for author in packAuthors do
		desc.Value ..= comma .. author
		comma = ", "
	end
end

function propPacker.OnPreSerialize(callbackState, invokeState, mission: Folder)
	-- Let prefabs load customprops in first
	local first = true
	repeat
		if not first then coroutine.yield() end
		local _, prefabPresent = invokeState.Get("Sprix_PrefabSystem_PreSerialize_Present")
		local prefabSuccess, prefabDone = invokeState.Get("Sprix_PrefabSystem_PreSerialize", "Done")
		local prefabDone = (not prefabPresent) or (prefabSuccess and prefabDone)
		first = false
	until prefabDone
	
	-- create customprops folder if it does not exist
	local CustomProps = mission:FindFirstChild("CustomProps")
	if not CustomProps then
		CustomProps = Instance.new("Folder")
		CustomProps.Name = "CustomProps"
		CustomProps.Parent = mission
	end
	
	-- move elements out of CustomProps folders
	for _, v in CustomProps:QueryDescendants("Model") do
		v.Parent = CustomProps
	end
	for _, v in CustomProps:QueryDescendants("Folder") do
		v:Destroy()
	end
	
	propPacker.PopulateCustomProps(mission)
	mission:FindFirstChild("CustomPropPacks"):Destroy()
end

APIConsumer.DoAPILoop(plugin, "PropPacker", propPacker.OnAPILoaded, propPacker.OnAPIUnloaded)
