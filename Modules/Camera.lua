export type custom = {
    RenderPriority: Enum.RenderPriority,
    callback: (CFrame) -> ()
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local CameraShaker = require(Knit.Util.CameraShaker)
local Signal = require(Knit.Util.Signal)

local main = {}
main.__index = main

function main.new()
    if(RunService:IsClient() == false) then return end
    local self = setmetatable({
        is_custom = false,
        camera = workspace.CurrentCamera
    },main)
    return self
end

function main:CustomShake<custom>(data : custom) : {any}
    if(self.is_custom == false) then self.is_custom = true end
    print(data)
    if(data.RenderPriority == nil) then error("arg.RenderPriority is not set",2) end
    if(data.callback == nil) then error("arg.callback is not set",2) end
    self.shaker = CameraShaker.new(data.RenderPriority,data.callback)
    return self.shaker
end

function main:TargetTo(target:CFrame) : CFrame
    if(not self.camera) then
        error("self is not initialized (.new is not called)",2)
    end
    if(self.camera.CameraType ~= Enum.CameraType.Scriptable) then
        self.camera.CameraType = Enum.CameraType.Scriptable
    end
    self.camera.CFrame = target
    return self.camera.CFrame
end

function main:StopTarget(callback)
    if(callback) then
        callback(self.camera,self.is_custom)
    end
    if(not self.camera) then
        error("self is not initialized (.new is not called)",2)
    end
    self.camera.CameraType = Enum.CameraType.Custom
    self.camera.CFrame = Players.LocalPlayer.Character:WaitForChild("Head").CFrame
    if(self.camera.CameraSubject.Name ~= Players.LocalPlayer.Character:WaitForChild("Humanoid").Name) then
        self.camera.CameraSubject = Players.LocalPlayer.Character:WaitForChild("Humanoid")
    end
end

function main:ChangeSubject(instance: Instance)
    assert(typeof(instance) == "Instance","arg 1 must be a instance.")
    if(self.camera) then
        self.camera.CameraSubject = instance
    else
        error("self is not initialized (.new is not called)",2)
    end
    if(instance.Name == "Humanoid") then
        return
    else
        local class = {
            data = {
                default_subject_cf = instance.CFrame,
                subject_location = HttpService:JSONEncode(instance:GetFullName()),
                auto_update = true,
                instance_obsever = nil,
                default_instance = instance,
                onRemoveSignal = Signal.new(),
            },
            subject = self.camera.CameraSubject
        }
        class.data.instance_obsever = workspace.DescendantRemoving:Connect(function(object)
            if(object.Name == class.data.default_instance.Name) then
                local getRemovedTime = workspace:GetServerTimeNow()
                local date_time = DateTime.fromUnixTimestamp(getRemovedTime)
                local time = date_time:ToLocalTime()
                local formated_time = `{time.Hour}h:{time.Minute}m:{time.Second}s`
                local format = ("Instance %s removed at %s Path: %s"):format(object.Name,formated_time,HttpService:JSONEncode(instance:GetFullName()) or class.data.subject_location)
                class.data.default_instance = format
                warn(class.data.default_instance)
                class.data.onRemoveSignal:Fire()
            end
        end)
        class.data.onRemoveSignal:Once(function()
            self:StopTarget()
            class.data.instance_obsever:Disconnect()
            table.clear(class.data)
            table.clear(class)
        end)
        return class
    end
end

return main
