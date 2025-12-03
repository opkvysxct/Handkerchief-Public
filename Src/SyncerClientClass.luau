--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StoreSuperClass = require(ReplicatedStorage.Handkerlib.SuperClasses.StoreSuperClass)
local internalEvents = script.Parent.InternalEvents

local SyncerClientClass = {}
SyncerClientClass.__index = SyncerClientClass

type Data = { any }

type SyncFunction = (newValue: any, params: { any }?) -> nil

type Params = {
	SyncFunctionStore: StoreSuperClass.Class,
}

export type Class = typeof(setmetatable({} :: Params, SyncerClientClass))

function SyncerClientClass.Create(): Class
	local self = {}
	self.SyncFunctionStore = StoreSuperClass.Create("string", "(newValue: any, params: { any }?) -> nil")
	return setmetatable(self, SyncerClientClass)
end

function SyncerClientClass.GetDataFromServer(self: Class)
	local receivedData: Data? = internalEvents.SyncerProfile:InvokeServer()
	while not receivedData do
		receivedData = internalEvents.SyncerProfile:InvokeServer()
		task.wait(0.5)
	end
	return receivedData :: Data
end

function SyncerClientClass.Run(self: Class)
	internalEvents.SyncerChangeFromServer.OnClientEvent:Connect(function(player: Player, syncKey: string, newValue: any, params: { any })
		self:IncomingChange(syncKey, newValue, params)
	end)
end

function SyncerClientClass.IncomingChange(self: Class, syncKey: string, newValue: any, params: { any }?)
	local syncFunction: SyncFunction = self.SyncFunctionStore:ReturnGivenElement(syncKey)
	syncFunction(newValue, params)
end

function SyncerClientClass.Change(self: Class, syncKey: string, newValue: any, params: { any }?)
	internalEvents.SyncerChangeFromClient:FireServer(syncKey, newValue, params)
end

return SyncerClientClass
