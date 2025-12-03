--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FormattingLib = require(ReplicatedStorage.Handkerlib.Shared.Components.FormattingLib)
local Types = require(ReplicatedStorage.Handkerlib.Types)

local Remotes = {}

function Remotes:CreateFolders()
	assert(not self:RetrevieFolders(true), FormattingLib:FormatLogMessage(script, `Server Already Initialized.`))
	local mainFolder: Folder = Instance.new("Folder")
	mainFolder.Parent = ReplicatedStorage["Handkerchief"]
	local reFolder: Folder = Instance.new("Folder")
	reFolder.Parent = mainFolder
	local ureFolder: Folder = Instance.new("Folder")
	ureFolder.Parent = mainFolder
	local rfFolder: Folder = Instance.new("Folder")
	rfFolder.Parent = mainFolder

	mainFolder.Name = "Connections"
	reFolder.Name = "Remote Events"
	ureFolder.Name = "Unreliable Remote Events"
	rfFolder.Name = "Remote Functions"
end

function Remotes:RetrevieFolders(preventAssert: boolean?): Folder?
	local folder: Instance? = ReplicatedStorage["Handkerchief"]:FindFirstChild("Connections")
	if not preventAssert then
		assert(folder, FormattingLib:FormatLogMessage(script, `Server was not initialized.`))
		assert(folder:IsA("Folder"), FormattingLib:FormatLogMessage(script, `Connection instance already exists inside ReplicatedStorage but is not a folder.`))
	end
	return folder :: Folder or nil
end

function Remotes:_ValidateAndGetRemoteTypes(remoteType: string): (string, Folder)
	if remoteType ~= "RE" and remoteType ~= "URE" and remoteType ~= "RF" then error("[HC] Invalid remoteType provided, " .. remoteType .. " is not a valid type.") end
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
	assert(correspondingFolder.RE, FormattingLib:FormatLogMessage(script, `Remote events folder does not exists.`))
	assert(correspondingFolder.RE:IsA("Folder"), FormattingLib:FormatLogMessage(script, `Remote events folder is not a folder.`))
	assert(correspondingFolder.URE, FormattingLib:FormatLogMessage(script, `Unreliable remote events folder does not exists.`))
	assert(correspondingFolder.URE:IsA("Folder"), FormattingLib:FormatLogMessage(script, `Unreliable remote events folder is not a folder.`))
	assert(correspondingFolder.RF, FormattingLib:FormatLogMessage(script, `Remote functions folder does not exists.`))
	assert(correspondingFolder.RF:IsA("Folder"), FormattingLib:FormatLogMessage(script, `Remote folder functions is not a folder.`))
	return remoteTypes[remoteType], correspondingFolder[remoteType]
end

-- Type can be RE, URE or RF
function Remotes:CreateRemote(remoteName: string, remoteType: string): Types.Remote
	assert(not RunService:IsClient(), FormattingLib:FormatLogMessage(script, `This function is not meant to be called on client.`))
	local remoteTypeToUse: string, remoteFolderToUse: Folder = self:_ValidateAndGetRemoteTypes(remoteType)
	local remote = Instance.new(remoteTypeToUse) :: Types.Remote
	remote.Parent = remoteFolderToUse
	remote.Name = remoteName
	return remote
end

function Remotes:GetRemote<RemoteToReturn>(name: string, remoteType: string): Types.Remote
	local _rT: string, remoteFolderToUse: Folder = self:_ValidateAndGetRemoteTypes(remoteType)
	local toReturn: Instance? = remoteFolderToUse:FindFirstChild(name)
	assert(toReturn, FormattingLib:FormatLogMessage(script, `Given remote does not exists.`))
	assert(toReturn:IsA("RemoteEvent") or toReturn:IsA("UnreliableRemoteEvent") or toReturn:IsA("RemoteFunction"), FormattingLib:FormatLogMessage(script, `Given remote is somehow not an remote.`))
	return toReturn :: Types.Remote
end

return Remotes
