--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormattingLib = require(ReplicatedStorage.Handkerlib.Shared.Components.FormattingLib)
local StoreSuperClass = require(ReplicatedStorage.Handkerlib.SuperClasses.StoreSuperClass)
local internalEvents = script.Parent.InternalEvents

local SyncerServerClass = {}
SyncerServerClass.__index = SyncerServerClass

type Data = { any }

type SyncFunction = (player: Player, newValue: any, params: { any }?) -> nil

type Params = {
	ProfileStore: StoreSuperClass.Class,
	SyncFunctionStore: StoreSuperClass.Class,
}

export type Class = typeof(setmetatable({} :: Params, SyncerServerClass))

function SyncerServerClass.Create(): Class
	local self = {}
	self.ProfileStore = StoreSuperClass.Create("string", "function")
	self.SyncFunctionStore = StoreSuperClass.Create("string", "function")
	return setmetatable(self, SyncerServerClass)
end

function SyncerServerClass.RunServer(self: Class, shouldKick: boolean?)
	internalEvents.SyncerProfile.OnServerInvoke = function(player: Player): Data?
		if not self.ProfileStore:TryToReturnGivenElement(player.UserId) then
			warn(FormattingLib:FormatLogMessage(script, `Profile for {player.Name} does not exists.`))
			if shouldKick then player:Kick("No player profile detected on the server.") end
			return nil
		end
		return self.ProfileStore:ReturnGivenElement(player.UserId)
	end
	internalEvents.SyncerChangeFromClient.OnServerEvent:Connect(function(player: Player, syncKey: string, newValue: any, params: { any })
		self:IncomingChange(player, syncKey, newValue, params)
	end)
end

function SyncerServerClass.IncomingChange(self: Class, player: Player, syncKey: string, newValue: any, params: { any }?)
	-- Tries to get the syncFunction because client can use cheats to send invalid syncKey
	local syncFunction: SyncFunction? = self.SyncFunctionStore:TryToReturnGivenElement(syncKey)
	if not syncFunction then
		warn(FormattingLib:FormatLogMessage(script, "No syncFunction with given syncKey."))
		player:Kick("No syncFunction with given syncKey")
	else
		syncFunction(player, newValue, params)
	end
end

function SyncerServerClass.Change(self: Class, player: Player, syncKey: string, newValue: any, params: { any }?)
	internalEvents.SyncerChangeFromServer:FireClient(player, syncKey, newValue, params)
end

return SyncerServerClass
