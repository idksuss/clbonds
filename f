
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RuntimeItems = Workspace:WaitForChild("RuntimeItems")
local PickUpToolRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Tool"):WaitForChild("PickUpTool")

-- Optional filtering by tool names
local allowedTools = {
    ["Revolver"] = true,
    ["Shotgun"] = true,
    ["Rifle"] = true,
    ["Navy Revolver"] = true,
    ["Mauser C96"] = true,
    ["Bolt Action Rifle"] = true,
    ["Electrocutioner"] = true,
    ["Sawed-Off Shotgun"] = true
}

-- Cache collected tools
local collected = {}

-- Function to try pickup
local function tryPickUp(toolModel)
    if not collected[toolModel] and toolModel:IsA("Model") then
        if allowedTools[toolModel.Name] or toolModel:FindFirstChild("Handle") then
            collected[toolModel] = true
            local args = {toolModel}
            pcall(
                function()
                    PickUpToolRemote:FireServer(unpack(args))
                end
            )
        end
    end
end

-- Scan existing tools
for _, tool in ipairs(RuntimeItems:GetChildren()) do
    tryPickUp(tool)
end

-- Watch for new ones
RuntimeItems.ChildAdded:Connect(
    function(tool)
        task.wait(0.1)
        tryPickUp(tool)
    end
)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Bond = true
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote =
    ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemotePromise"):WaitForChild(
    "Remotes"
):WaitForChild("C_ActivateObject")

local StopEvent = Instance.new("BindableEvent")
StopEvent.Name = "StopAmmoLoop"
StopEvent.Parent = ReplicatedStorage

local connections = {} -- Assuming connections table is defined elsewhere
local stopConn =
    StopEvent.Event:Connect(
    function()
        Bond = false
    end
)
table.insert(connections, stopConn)

local function ammoCollector()
    if not Bond then
        return
    end

    for _, item in pairs(workspace.RuntimeItems:GetChildren()) do
        if item and item.Name:match("^RevolverAmmo") then
            local args = {item} -- Pass the item as the argument
            remote:FireServer(unpack(args))
        end
    end

    task.delay(0.1, ammoCollector)
end

task.spawn(ammoCollector)

local Mstatus = true
local originalHoldDurations1 = {} -- Store original hold durations only for Moneybag prompts
local runService = game:GetService("RunService")
local moneyBagConnections = {} -- Store connections to prevent memory leaks

local function skipHoldPrompt1(prompt)
    if prompt and prompt:IsA("ProximityPrompt") and prompt.Parent and prompt.Parent.Name == "MoneyBag" then
        if not originalHoldDurations1[prompt] then
            originalHoldDurations1[prompt] = prompt.HoldDuration -- Save original hold duration
        end
        prompt.HoldDuration = 0 -- Remove hold time for Moneybag prompts only
    end
end

local function restoreMoneybagPrompts()
    for prompt, duration in pairs(originalHoldDurations1) do
        if prompt and prompt.Parent and prompt.Parent.Name == "MoneyBag" then
            prompt.HoldDuration = duration -- Restore only Moneybag prompts
        end
    end
    originalHoldDurations1 = {} -- Clear stored values
end

local function handleMoneyBag(v)
    if not Mstatus then
        return
    end
    if v:IsA("Model") and v.Name == "Moneybag" and v:FindFirstChild("MoneyBag") then
        local prompt = v.MoneyBag:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            skipHoldPrompt1(prompt)
        end
    end
end

local function cleanupConnections()
    for _, connection in pairs(moneyBagConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    table.clear(moneyBagConnections)
end

local function collectMoneyBags()
    if not Mstatus then
        return
    end
    cleanupConnections() -- Prevent duplicate connections

    -- Scan for existing Moneybags
    for _, v in ipairs(workspace.RuntimeItems:GetChildren()) do
        handleMoneyBag(v)
    end

    -- Auto-collect new Moneybags
    local connection =
        runService.Heartbeat:Connect(
        function()
            if not Mstatus then
                return
            end
            for _, v in ipairs(workspace.RuntimeItems:GetChildren()) do
                if v:IsA("Model") and v.Name == "Moneybag" and v:FindFirstChild("MoneyBag") then
                    local prompt = v.MoneyBag:FindFirstChildOfClass("ProximityPrompt")
                    if
                        prompt and
                            (v.MoneyBag.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <=
                                prompt.MaxActivationDistance
                     then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end
    )

    table.insert(moneyBagConnections, connection)
end

collectMoneyBags()

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

if noclip then
    noclipConnection =
        game:GetService("RunService").Stepped:Connect(
        function()
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    )
else
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end
