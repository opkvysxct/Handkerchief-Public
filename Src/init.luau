--!strict
-- VYSX 2025
-- VERSION 1.1.2
-- Requires Handkerlib

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.Handkerlib.Types)
local Remotes = require(script.Remotes)

local Handkerchief = {}

Handkerchief.Libs = {}
Handkerchief.Handkerlib = require(ReplicatedStorage.Handkerlib)
Handkerchief.Remotes = require(script.Remotes)
Handkerchief.Database = require(script.Database)
Handkerchief.SyncerClientClass = require(script.SyncerClientClass)
Handkerchief.SyncerServerClass = require(script.SyncerServerClass)

function Handkerchief:Init(moduleFiles: { ModuleScript }, componentFiles: { ModuleScript }?)
	local isLoaded: boolean = false
	if RunService:IsServer() then
		script.InternalEvents.LoadStatus.OnServerInvoke = function(player: Player)
			return isLoaded
		end
		Remotes:CreateFolders()
	elseif RunService:IsClient() then
		while not script.InternalEvents.LoadStatus:InvokeServer() do
			task.wait(0.5)
		end
	end
	self:InitModules(self:TestAndLoadModules(moduleFiles, { "Init", "Run" }))
	if componentFiles then
		self:InitComponents(self:TestAndLoadModules(componentFiles, { "OnCreate", "OnDestroy", "Tag" }))
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
