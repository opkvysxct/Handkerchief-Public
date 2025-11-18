--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.Handkerlib.Types)

local Remotes = {}

function Remotes:CreateFolders()
	assert(not self:RetrevieFolders(true), "[H] Server Already Initialized.")
	local mainFolder: Folder = Instance.new("Folder", ReplicatedStorage["Handkerchief"])
	local reFolder: Folder = Instance.new("Folder", mainFolder)
	local ureFolder: Folder = Instance.new("Folder", mainFolder)
	local rfFolder: Folder = Instance.new("Folder", mainFolder)
	mainFolder.Name = "Connections"
	reFolder.Name = "Remote Events"
	ureFolder.Name = "Unreliable Remote Events"
	rfFolder.Name = "Remote Functions"
end

function Remotes:RetrevieFolders(preventAssert: boolean?): Folder?
	local folder: Instance? = ReplicatedStorage["Handkerchief"]:FindFirstChild("Connections")
	if not preventAssert then
		assert(folder, "[HC] Server was not initialized.")
		assert(folder:IsA("Folder"))
		assert(
			folder:IsA("Folder"),
			"[HC] Connection instance already exists inside ReplicatedStorage but is not a folder."
		)
	end
	return folder :: Folder or nil
end

function Remotes:_ValidateAndGetRemoteTypes(remoteType: string): (string, Folder)
	if remoteType ~= "RE" and remoteType ~= "URE" and remoteType ~= "RF" then
		error("[HC] Invalid remoteType provided, " .. remoteType .. " is not a valid type.")
	end
	local folders: Folder = self:RetrevieFolders() :: Folder
	local remoteTypes: { [string]: string } = {
		["RE"] = "RemoteEvent",
		["URE"] = "UnreliableRemoteEvent",
		["RF"] = "RemoteFunction",
	}
	local correspondingFolder: { [string]: Folder } = {
		["RE"] = folders:FindFirstChild("Remote Events") :: Folder,
		["URE"] = folders:FindFirstChild("Unreliable Remote Events") :: Folder,
		["RF"] = folders:FindFirstChild("Remote Functions") :: Folder,
	}
	assert(correspondingFolder.RE, "[H] Remote events folder does not exists.")
	assert(correspondingFolder.RE:IsA("Folder"), "[H] Remote events folder is not a folder.")
	assert(correspondingFolder.URE, "[H] Unreliable remote events folder does not exists.")
	assert(correspondingFolder.URE:IsA("Folder"), "[H] Unreliable remote events folder is not a folder.")
	assert(correspondingFolder.RF, "[H] Remote functions folder does not exists.")
	assert(correspondingFolder.RF:IsA("Folder"), "[H] Remote folder functions is not a folder.")
	return remoteTypes[remoteType], correspondingFolder[remoteType]
end

-- Type can be RE, URE or RF
function Remotes:CreateRemote(remoteName: string, remoteType: string): Types.Remote
	if RunService:IsClient() then
		error("[HC] This function is not meant to be called on client.")
	end
	local remoteTypeToUse: string, remoteFolderToUse: Folder = self:_ValidateAndGetRemoteTypes(remoteType)
	local remote = Instance.new(remoteTypeToUse, remoteFolderToUse) :: Types.Remote
	remote.Name = remoteName
	return remote
end

function Remotes:GetRemote(name: string, remoteType: string): Types.Remote
	local _rT: string, remoteFolderToUse: Folder = self:_ValidateAndGetRemoteTypes(remoteType)
	local toReturn = remoteFolderToUse:FindFirstChild(name) :: Types.Remote?
	assert(toReturn, "[HC] Given remote does not exists.")
	return toReturn
end

return Remotes
