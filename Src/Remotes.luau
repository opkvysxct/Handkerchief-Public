local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.Handkerlib.Types)

local Remotes = {}

function Remotes:CreateFolders()
	assert(not Remotes:RetrevieFolders(true), "[H] Server Already Initialized.")
	local mainFolder: Folder = Instance.new("Folder", ReplicatedStorage["Handkerchief"])
	local reFolder: Folder = Instance.new("Folder", mainFolder)
	local ureFolder: Folder = Instance.new("Folder", mainFolder)
	local rfFolder: Folder = Instance.new("Folder", mainFolder)
	mainFolder.Name = "Connections"
	reFolder.Name = "Remote Events"
	ureFolder.Name = "Unreliable Remote Events"
	rfFolder.Name = "Remote Functions"
end

function Remotes:RetrevieFolders(preventAssert: boolean?): Folder | false
	local folder: Folder = ReplicatedStorage["Handkerchief"]:FindFirstChild("Connections")
	if not preventAssert then
		assert(folder, "[HC] Server was not initialized.")
		assert(
			folder:IsA("Folder"),
			"[HC] Connection instance already exists inside ReplicatedStorage but is not a folder."
		)
	end
	return folder or false
end

function Remotes:_ValidateAndGetRemoteTypes(remoteType: string): (string, Folder)
	if remoteType ~= "RE" and remoteType ~= "URE" and remoteType ~= "RF" then
		error("[HC] Invalid remoteType provided, " .. remoteType .. " is not a valid type.")
	end
	local folders: Folder = Remotes:RetrevieFolders() :: Folder
	local remoteTypes: { [string]: string } = {
		["RE"] = "RemoteEvent",
		["URE"] = "UnreliableRemoteEvent",
		["RF"] = "RemoteFunction",
	}
	local correspondingFolder: { [string]: Folder } = {
		["RE"] = folders:FindFirstChild("Remote Events"),
		["URE"] = folders:FindFirstChild("Unreliable Remote Events"),
		["RF"] = folders:FindFirstChild("Remote Functions"),
	}
	return remoteTypes[remoteType], correspondingFolder[remoteType]
end

-- Type can be RE, URE or RF
function Remotes:CreateRemote(remoteName: string, remoteType: string): Types.Remote
	if RunService:IsClient() then
		error("[HC] This function is not meant to be called on client.")
	end
	local remoteTypeToUse: string, remoteFolderToUse: Folder = Remotes:_ValidateAndGetRemoteTypes(remoteType)
	local remote = Instance.new(remoteTypeToUse, remoteFolderToUse) :: Types.Remote
	remote.Name = remoteName
	return remote
end

function Remotes:GetRemote(name: string, remoteType: string): Types.Remote
	local _rT: string, remoteFolderToUse: Folder = Remotes:_ValidateAndGetRemoteTypes(remoteType)
	local toReturn = remoteFolderToUse[name] :: Types.Remote?
	assert(toReturn, "[HC] Given remote does not exists.")
	return toReturn
end

--function Remotes:ForceCreateRemote(remoteName: string, remoteType: string, where: Instance): Types.Remote end

--function Remotes:ForceGetRemote(name: string, remoteType: string, where: Instance): Types.Remote end

return Remotes
