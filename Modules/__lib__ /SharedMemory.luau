local SharedTableRegistryService = game:GetService("SharedTableRegistry")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = script:WaitForChild("Modules")
local Promise = require(ReplicatedStorage.Packages.Promise)

export type setSharedTable = {
	Name: string;
	Value: any;
}

export type setSharedTableParallel = {
	Name: string;
	Value: any;
	ScriptSourceInstance: Actor;
}

local util = {}
util.__index = {}

function util:getSharedTable(__name__ : string) : SharedTable | nil
	assert(type(__name__) == "string","[__name__] arg must be a string")
	return SharedTableRegistryService:GetSharedTable(__name__)
end

function util:setSharedTable(__data__ : setSharedTable) : SharedTable | {} | nil
	assert(
		type(__data__) == "table" and type(__data__.Name) == "string" and type(__data__.Value) ~= "nil",
		"[__data__] arg is not a setSharedTableInformation."
	)
	Promise.try(function()
		return SharedTableRegistryService:SetSharedTable(__data__.Name,__data__.Value)
	end):andThen(function(t)
	end):catch(function(err)
		local shared_t = SharedTable.new()
		shared_t[__data__.Name] = __data__.Value
		SharedTableRegistryService:SetSharedTable(__data__.Name,shared_t)
	end)
	return self:getSharedTable(__data__.Name)
end

function util:cloneSharedTable(__name__ : string, SetIfIsNil : boolean, __data__ : setSharedTableParallel)
	local sharedTable = self:getSharedTable(__name__)
	if(sharedTable and RunService:IsServer()) then 
		return sharedTable
	elseif(sharedTable and RunService:IsClient()) then
		return SharedTable.cloneAndFreeze(sharedTable,true)
	end
	if(SetIfIsNil) then
		return self:setSharedTable(__data__)
	end
end

function util:removeSharedTable(__name__ : string) : boolean
	assert(type(__name__) == "string","[__name__] arg must be a string")
	local sharedTable = self:getSharedTable(__name__)
	if(not sharedTable) then return false end
	SharedTable.clear(sharedTable)
	return true
end

function util:SyncSharedTable(__data__ : setSharedTableParallel)
	assert(
		type(__data__) == "table" and type(__data__.Name) == "string" and type(__data__.Value) ~= "nil" and __data__.ScriptSourceInstance:IsA("Actor"),
		"[__data__] arg is not a setSharedTableParallel."
	)
	if(not __data__.ScriptSourceInstance:IsA("Actor")) then return warn("Synchronize,Desynchronize can only be called within a actor") end
	task.synchronize()
	local result = self:setSharedTable(__data__)
	assert(type(result) ~= "table","failed to create a sharedTable")
	task.desynchronize()
	return result
end

return util
