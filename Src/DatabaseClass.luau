--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CleanerClass = require(ReplicatedStorage.Handkerlib.Shared.Classes.CleanerClass)
local FormattingLib = require(ReplicatedStorage.Handkerlib.Shared.Components.FormattingLib)
local StoreSuperClass = require(ReplicatedStorage.Handkerlib.SuperClasses.StoreSuperClass)
local DatabaseClass = {}
DatabaseClass.__index = DatabaseClass

type Limits = {
	Reads: number,
	Writes: number,
}

type Params = {
	_DefaultPlayerDataStoreName: string,
	_DefaultGlobalDataStoreName: string,
	_AutoSavingEnabled: boolean,
	_AutoSavingThreshold: number,
	_AutoSavingFunction: (player: Player) -> any,
	_MaxReadsAndWrites: number,
	_DatabaseUsesInPastMinute: Limits,
	_Cleaner: CleanerClass.Class,
	AvailablePlayers: StoreSuperClass.Class,
}

export type AvailablePlayerData = {
	Data: any,
	LastTimeSaved: number,
}

export type Class = typeof(setmetatable({} :: Params, DatabaseClass))

function DatabaseClass.Create(playerDataStoreName: string, globalDataStoreName: string, autoSavingThreshold: number?): Class
	local self = {}
	self._DefaultPlayerDataStoreName = playerDataStoreName
	self._DefaultGlobalDataStoreName = globalDataStoreName
	self._AutoSavingEnabled = false
	self._AutoSavingThreshold = autoSavingThreshold or 0.75
	self._AutoSavingFunction = function(player: Player) end
	self._MaxReadsAndWrites = 0
	self._DatabaseUsesInPastMinute = {
		Reads = 0,
		Writes = 0,
	}
	self._Cleaner = CleanerClass.Create()
	self.AvailablePlayers = StoreSuperClass.Create("number", "Player")
	return setmetatable(self, DatabaseClass)
end

-- For internal use
function DatabaseClass.ReturnDataStore(self: Class, dataStoreName: string?, requestGlobal: boolean?): DataStore
	if dataStoreName then
		return DataStoreService:GetDataStore(dataStoreName)
	elseif requestGlobal then
		return DataStoreService:GetDataStore(self._DefaultGlobalDataStoreName)
	else
		return DataStoreService:GetDataStore(self._DefaultPlayerDataStoreName)
	end
end

function DatabaseClass.SetCustomData(self: Class, dataKey: any, dataValue: any, dataStoreName: string?)
	self._DatabaseUsesInPastMinute.Writes += 1
	local success: boolean, errorMessage: string = pcall(function()
		self:ReturnDataStore(dataStoreName, true):SetAsync(dataKey, dataValue)
	end)
	if not success then warn(FormattingLib:FormatLogMessage(script, errorMessage)) end
end

function DatabaseClass.UpdateCustomData(self: Class, dataKey: any, dataValue: any, dataStoreName: string?)
	self._DatabaseUsesInPastMinute.Writes += 1
	self._DatabaseUsesInPastMinute.Reads += 1
	local success: boolean, errorMessage: string = pcall(function()
		self:ReturnDataStore(dataStoreName, true):UpdateAsync(dataKey, dataValue)
	end)
	if not success then warn(FormattingLib:FormatLogMessage(script, errorMessage)) end
end

function DatabaseClass.GetCustomData(self: Class, dataKey: any, dataStoreName: string?): any
	self._DatabaseUsesInPastMinute.Reads += 1
	local res: any
	local success: boolean, errorMessage: string = pcall(function()
		res = self:ReturnDataStore(dataStoreName, true):GetAsync(dataKey)
	end)
	if not success then warn(FormattingLib:FormatLogMessage(script, errorMessage)) end
	return res
end

function DatabaseClass.SetUserData(self: Class, player: Player, dataValue: any, dataStoreName: string?)
	self:SetCustomData(tostring(player.UserId), dataValue)
end

function DatabaseClass.UpdateUserData(self: Class, player: Player, dataValue: any, dataStoreName: string?)
	self:UpdateCustomData(tostring(player.UserId), dataValue)
end

function DatabaseClass.GetUserData(self: Class, player: Player, dataStoreName: string?): any
	return self:GetCustomData(tostring(player.UserId))
end

function DatabaseClass.CalculateThreshold(self: Class): boolean
	return self._DatabaseUsesInPastMinute.Writes / math.clamp(self._MaxReadsAndWrites, 1, math.huge) < self._AutoSavingThreshold
end

function DatabaseClass.SetPlayerDataAutoSavingFunction(self: Class, functionToUse: (player: Player) -> any)
	self._AutoSavingFunction = functionToUse
end

function DatabaseClass.StartPlayerDataAutoSaving(self: Class)
	self._Cleaner:CleanUp()
	self._Cleaner:AddConnection(Players.PlayerAdded:Connect(function()
		self._MaxReadsAndWrites = 60 + #Players:GetPlayers() * 10
	end))
	self._Cleaner:AddConnection(Players.PlayerRemoving:Connect(function()
		self._MaxReadsAndWrites = 60 + #Players:GetPlayers() * 10
	end))
	self._Cleaner:AddThread(task.spawn(function()
		while self._AutoSavingEnabled and task.wait(60) do
			self._DatabaseUsesInPastMinute.Reads = 0
			self._DatabaseUsesInPastMinute.Writes = 0
		end
	end))
	self._Cleaner:AddThread(task.spawn(function()
		while self._AutoSavingEnabled and task.wait(15) do
			if not self:CalculateThreshold() then continue end
			for index: number, player: Player in self.AvailablePlayers:ReturnElements() do
				self:SetUserData(player, self._AutoSavingFunction(player))
			end
		end
	end))
end

function DatabaseClass.StopPlayerDataAutoSaving(self: Class)
	self._AutoSavingEnabled = false
	self._Cleaner:Destroy()
end

function DatabaseClass.Destroy(self: Class)
	self:StopPlayerDataAutoSaving()
	setmetatable(self :: any, nil)
	table.clear(self :: any)
	table.freeze(self :: any)
end

return DatabaseClass
