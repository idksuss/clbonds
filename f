local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local nobandagedelay = true
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local autoCollect = true
local collectammo = true
local autoHeal = true
local healThreshold = 40
game.Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic
game.Players.LocalPlayer.CameraMaxZoomDistance = 100
local noclip = true
local autocollectbandoil = true
local noclipConnection
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local autoCollectDistance = 35
local hrp = character:WaitForChild("HumanoidRootPart")
local function getDistance(pos1, pos2)
    local pos1Vec3 = typeof(pos1) == "CFrame" and pos1.Position or pos1
    local pos2Vec3 = typeof(pos2) == "CFrame" and pos2.Position or pos2
    return (pos1Vec3 - pos2Vec3).Magnitude
end
local function getClosestAmmo()
    local itemsFolder = workspace:FindFirstChild("RuntimeItems")
    if not itemsFolder then return nil end

    local closestAmmo, closestPart
    local minDistance = math.huge

    for _, model in ipairs(itemsFolder:GetChildren()) do
        if model:IsA("Model") and model.Name == "RevolverAmmo" then
            local AmmoPart = model:FindFirstChildWhichIsA("BasePart")
            if AmmoPart then
                local distance = (hrp.Position - AmmoPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestAmmo = model
                    closestPart = AmmoPart
                end
            end
        end
    end

    return closestAmmo, closestPart
end
if noclip then
noclipConnection = game:GetService("RunService").Stepped:Connect(function()
for _, part in pairs(character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end)
else
if noclipConnection then
noclipConnection:Disconnect()
noclipConnection = nil
end
end
RunService.RenderStepped:Connect(function()
if nobandagedelay and LocalPlayer.PlayerGui.BandageUse.Enabled and LocalPlayer.Character then
local Bandage = LocalPlayer.Character:FindFirstChild("Bandage")
if Bandage ~= nil then
Bandage.Use:FireServer()
end
end

for _, obj in pairs(workspace:GetDescendants()) do
if obj:IsA("ProximityPrompt") then
obj.HoldDuration = 0
end
end

if autoCollect then
for _, moneyBag in ipairs(workspace.RuntimeItems:GetChildren()) do
if moneyBag:IsA("Model") then
local prompt = moneyBag:FindFirstChild("CollectPrompt", true)
if prompt and prompt:IsA("ProximityPrompt") then
prompt.HoldDuration = 0
prompt:InputHoldBegin()
wait(0.05)
prompt:InputHoldEnd()
end
end
end
end

if autocollectbandoil then
for _, pickbandoil in ipairs(workspace.RuntimeItems:GetChildren()) do
if string.find(pickbandoil.Name, "Bandage") then
ReplicatedStorage.Remotes.Tool.PickUpTool:FireServer(workspace.RuntimeItems.Bandage)
end
if string.find(pickbandoil.Name, "Snake Oil") then
ReplicatedStorage.Remotes.Tool.PickUpTool:FireServer(workspace.RuntimeItems["Snake Oil"])
end
end
end

if collectammo then
if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
local playerPosition = LocalPlayer.Character.HumanoidRootPart.Position
local model, AmmoPart = getClosestAmmo()
if not model or not AmmoPart then return end
local ammoPosition = AmmoPart.Position
if getDistance(playerPosition, ammoPosition) <= autoCollectDistance then
game:GetService("ReplicatedStorage").Packages.RemotePromise.Remotes.C_ActivateObject:FireServer(model)
task.wait(0.5)
end
end
end

if autoHeal then
local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
if humanoid and humanoid.Health < healThreshold then
local bandage = LocalPlayer.Backpack:FindFirstChild("Bandage")
if bandage then
bandage.Use:FireServer()
end
end
end
end)
