-- VYSX 2025
-- VERSION 1.0.1
-- Requires Handkerlib

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.Handkerlib.Types)
local Remotes = require(script.Remotes)
local internalEvents = script.InternalEvents

local Handkerchief = {}

function Handkerchief:Init(moduleFiles: { ModuleScript }, componentFiles: { ModuleScript }?)
	local isLoaded: boolean = false
	if RunService:IsServer() then
		local status: RemoteEvent = Instance.new("RemoteEvent", script)
		status.Name = "Status"
		internalEvents.Status.OnServerEvent:Connect(function(player: Player)
			internalEvents.Status:FireClient(player, isLoaded)
		end)
		Remotes:CreateFolders()
	elseif RunService:IsClient() then
		internalEvents.Status.OnClientEvent:Connect(function(returned: boolean)
			isLoaded = returned
		end)
		while not isLoaded do
			internalEvents.Status:FireServer()
			task.wait(0.5)
		end
	end
	Handkerchief:InitModules(Handkerchief:TestAndLoadModules(moduleFiles, { "Init", "Run" }))
	if componentFiles then
		Handkerchief:InitComponents(Handkerchief:TestAndLoadModules(componentFiles, { "OnCreate", "OnDestroy", "Tag" }))
	end
	isLoaded = true
	print("[HC] Server loaded.")
end

function Handkerchief:ReturnModules(root: Instance, pattern: string?): { ModuleScript }
	local descendants: { Instance } = root:GetDescendants()
	local modules: { ModuleScript } = {}
	for index: number, thing: Instance in descendants do
		if not thing:IsA("ModuleScript") then
			continue
		end
		if pattern then
			if not string.match(thing.Name, pattern) then
				continue
			end
		end
		table.insert(modules, thing)
	end
	return modules
end

function Handkerchief:TestAndLoadModules(
	moduleFiles: { ModuleScript },
	searchFor: { string }
): { [ModuleScript]: Types.GenericLoadedModule }
	local modules: { [ModuleScript]: Types.GenericLoadedModule } = {}
	for moduleIndex: number, module: ModuleScript in moduleFiles do
		if not module:IsA("ModuleScript") then
			error("[HC] Invalid file provided.")
		end
		local reqModule: Types.GenericLoadedModule = require(module) :: Types.GenericLoadedModule
		for searchIndex: number, searchString: string in searchFor do
			if not reqModule[searchString] then
				error("[HC] Invalid module format, No " .. searchString .. " found.")
			end
		end
		modules[module] = reqModule
	end
	return modules
end

function Handkerchief:InitComponents(modules: { [ModuleScript]: Types.GenericLoadedModule })
	for moduleScript: ModuleScript, loadedModule: Types.GenericLoadedModule in modules do
		local tag: string = loadedModule["Tag"]
		for _index: number, instance: Instance in CollectionService:GetTagged(tag) do
			loadedModule:OnCreate(instance)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
			loadedModule:OnCreate(instance)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
			loadedModule:OnDestroy()
		end)
	end
end

function Handkerchief:InitModules(modules: { [ModuleScript]: Types.GenericLoadedModule })
	for moduleScript: ModuleScript, loadedModule: Types.GenericLoadedModule in modules do
		loadedModule:Init()
	end
	for moduleScript: ModuleScript, loadedModule: Types.GenericLoadedModule in modules do
		loadedModule:Run()
	end
end

return Handkerchief
