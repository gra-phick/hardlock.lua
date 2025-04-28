 
--// MEC SIM HARDLOCK AIMBOT + PREDICTION + RAGE MODE + SMART TARGETING - by ChatGPT

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = UIS:GetMouseLocation

-- SETTINGS
local Aimbot = {
    Enabled = true,
    RageMode = true,              -- Rage = No FOV limit and instant lock
    TeamCheck = true,
    WallCheck = false,
    Prediction = true,
    PredictionMultiplier = 0.165,
    FOVRadius = 120,
    LockOnKey = Enum.UserInputType.MouseButton2,
    Toggle = false,
    AimParts = {"Head", "UpperTorso", "HumanoidRootPart"},
    AutoShoot = false,           -- Rage bonus: Auto fire if true
}

-- Variables
local LockedPlayer = nil
local IsAiming = false

-- Helper Functions
local function IsPartVisible(part)
    if not part then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.Ignore or workspace.Terrain}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500, rayParams)
    return result and result.Instance and result.Instance:IsDescendantOf(part.Parent)
end

local function GetBestTargetPart(character)
    for _, partName in ipairs(Aimbot.AimParts) do
        local part = character:FindFirstChild(partName)
        if part and IsPartVisible(part) then
            return part
        end
    end
    return nil
end

local function GetClosestTarget()
    local closestPlayer = nil
    local shortestDistance = Aimbot.RageMode and math.huge or Aimbot.FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if Aimbot.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end

                local targetPart = GetBestTargetPart(player.Character)

                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local mousePos = Mouse(UIS)
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                        if distance < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function AimAt(target)
    if not target or not target.Character then return end

    local part = GetBestTargetPart(target.Character)
    if not part then return end

    local predictedPosition = part.Position
    if Aimbot.Prediction then
        local partVelocity = part.Velocity or Vector3.zero
        predictedPosition = predictedPosition + (partVelocity * Aimbot.PredictionMultiplier)
    end

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)

    if Aimbot.AutoShoot then
        -- Bonus: simulate left mouse click if needed
        mouse1press()
        task.wait(0.05)
        mouse1release()
    end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    if Aimbot.Enabled and IsAiming then
        LockedPlayer = GetClosestTarget()
        if LockedPlayer then
            AimAt(LockedPlayer)
        end
    end
end)

-- Input Handling
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Aimbot.LockOnKey then
        if Aimbot.Toggle then
            IsAiming = not IsAiming
        else
            IsAiming = true
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if not Aimbot.Toggle and input.UserInputType == Aimbot.LockOnKey then
        IsAiming = false
        LockedPlayer = nil
    end
end)
