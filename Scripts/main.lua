local modName = "PortableRadio"

local function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

local scripts = {
    "utils",
    "uemath"
}

local _startpath = file_exists([[ue4ss\Mods\]] .. modName .. [[\options.lua]]) and ([[ue4ss\Mods\]] .. modName) or ([[Mods\]] .. modName)
print("Loading options from " .. _startpath .. "\n")
dofile(_startpath .. [[\options.lua]])

print("Loading " .. modName .. " deps\n")
for _, script in ipairs(scripts) do
    require(script)
end

local radioEnabled = false
local playerRadio = nil
local hasLoadedRadioAsset = false
local isEnabled = false
local changedRadioFrequency = false

-- [[
--     Mod toggle
-- ]]

-- This should always be executed in game thread
local function SpawnFromClass(className)
    if (not className) or (type(className) ~= "string") then
        dprint("Invalid class name\n")
        return
    end

    -- Create object in front of player
    local position = GetPlayerLocation()

    if (not position) then
        dprint("Failed to get player position\n")
        return
    end

    dprint("Player position: " .. VectorToString(position) .. "\n")
    dprint("Spawning object at " .. position.X .. ", " .. position.Y .. ", " .. position.Z .. "\n")

    local object = SpawnActorFromClass(className, FVector(position.X, position.Y, position.Z), FRotator(0, 0, 0))

    if (IsValid(object)) then
        dprint("Object spawned successfully\n")
        return object
    else
        dprint("Failed to spawn object\n")
        return nil
    end
end

function SpawnPortableRadio()
    if (not isEnabled) then return end
    print("SpawnPortableRadio:\n")

    if IsValid(playerRadio) then
        dprint("Radio already spawned\n")
        return nil
    end

    if (not IsWalking()) then
        dprint("Not walking\n")
        return
    end

    if (ALWAYS_TRY_LOAD_ASSET) then
        LoadAsset(RADIO_BP_ASSET)
    end

    playerRadio = SpawnFromClass(RADIO_BP_ASSET)

    if (not IsRadioValid()) then
        playerRadio = nil
        dprint("Failed to spawn radio\n")
        return
    end

    playerRadio:SetActorEnableCollision(false)
    playerRadio:SetActorHiddenInGame(true)

    local playerPawn = GetPlayerPawn()

    if IsValid(playerPawn) and IsValid(playerPawn.RootComponent) then
        playerRadio:K2_AttachToComponent(playerPawn.RootComponent, playerPawn.RootComponent:GetAttachSocketName(), 1, 1, 1, false)
        dprint("Radio attached to player\n")
    end

    TurnOnRadio()
    dprint("Radio spawned\n")
end

function GetRadio()
    return IsValid(playerRadio) and playerRadio or nil
end

function TurnOnRadio()
    if (radioEnabled) then return end

    dprint("Attempting to turn on radio\n")

    if (not CanUseRadio()) then
        SpawnPortableRadio()
        return
    end

    playerRadio:BndEvt__BP_Interactable_Radio_120_HoldOn_K2Node_ComponentBoundEvent_10_InteractSignature__DelegateSignature()
    dprint("Radio turned on\n")

    SetRadioVolume(DEFAULT_RADIO_VOLUME)
    radioEnabled = true
    return true
end

function TurnOffRadio()
    if (changedRadioFrequency) then return false end

    dprint("Attempting to turn off radio\n")

    if (not CanUseRadio()) then
        radioEnabled = false
        return
    end

    playerRadio:BndEvt__BP_Interactable_Radio_120_HoldOff_K2Node_ComponentBoundEvent_11_InteractSignature__DelegateSignature()
    dprint("Radio turned off\n")

    radioEnabled = false
    return true
end

function ToggleRadio()
    if (not isEnabled) then return end

    dprint("Attempting to toggle radio\n")

    if (radioEnabled) then
        if (not IsRadioValid()) then
            radioEnabled = false
            TurnOnRadio()
            return
        end

        TurnOffRadio()
    else
        TurnOnRadio()
    end
end

function ChangeRadioFrequency()
    if (not radioEnabled) then return end

    dprint("Attempting to change radio frequency\n")

    if (not CanUseRadio()) then
        return
    end

    playerRadio:BndEvt__BP_Interactable_Radio_120_SingleClick_K2Node_ComponentBoundEvent_9_InteractSignature__DelegateSignature()
    dprint("Radio frequency changed\n")

    changedRadioFrequency = true

    ExecuteWithDelay(2500, function()
        changedRadioFrequency = false
    end)

    return true
end

function DestroyRadio()
    ExecuteInGameThread(function()
        if IsValid(playerRadio) and (not playerRadio.bActorIsBeingDestroyed) then
            playerRadio:K2_DestroyActor()
            playerRadio = nil
            dprint("Radio destroyed\n")
        end
    end)
end

function SetRadioVolume(volume)
    if (not isEnabled) then return end

    volume = tonumber(volume)

    if (not volume) then
        dprint("Invalid volume value\n")
        return
    end

    if (not CanUseRadio()) then
        return
    end

    local audio = playerRadio.InteractableRadioAk

    if IsNotValid(audio) then
        dprint("Failed to get radio audio component\n")
        return
    end

    audio:SetOutputBusVolume(volume)
    dprint("Radio volume set to " .. volume .. "\n")
end

function IsRadioValid()
    return IsValid(playerRadio) and (playerRadio.BndEvt__BP_Interactable_Radio_120_HoldOn_K2Node_ComponentBoundEvent_10_InteractSignature__DelegateSignature ~= nil)
end

function CanUseRadio()
    if (not isEnabled) then 
        dprint("Not enabled\n")
        return false 
    end
    if (not IsRadioValid()) then 
        dprint("Radio not spawned\n")
        return false 
    end
    if (not IsWalking()) then 
        dprint("Not walking\n")
        return false 
    end
    return true
end

function IsWalking()
    local characterMovement = GetPlayerCharacterMovement()

    if IsNotValid(characterMovement) then
        dprint("Failed to get player character movement\n")
        return false
    end

    return characterMovement:IsWalking()
end

NotifyOnNewObject("/Script/Stalker2.LoadingScreenWidget", function(self)
    DestroyRadio()

    if (not hasLoadedRadioAsset) then
        ExecuteInGameThread(function()
            LoadAsset(RADIO_BP_ASSET)
        end)
        hasLoadedRadioAsset = true
    end

    isEnabled = false

    dprint("Loading screen created\n")
end)

NotifyOnNewObject("/Script/Stalker2.DeathScreen", function(self)
    DestroyRadio()

    isEnabled = false
    dprint("Death screen created\n")
end)

NotifyOnNewObject("/Script/Stalker2.Stalker2PlayerController", function(self)
    isEnabled = true
    dprint("Player controller created\n")
end)

RegisterConsoleCommandHandler("TurnOnRadio", TurnOnRadio)
RegisterConsoleCommandHandler("TurnOffRadio", TurnOffRadio)
RegisterConsoleCommandHandler("ToggleRadio", ToggleRadio)
RegisterConsoleCommandHandler("ChangeRadioFrequency", ChangeRadioFrequency)
RegisterConsoleCommandHandler("SetRadioVolume", function(FullCommand, Parameters, OutputDevice)
    print("SetRadioVolume (command):\n")

    print(string.format("Command: %s\n", FullCommand))
    print(string.format("Number of parameters: %i\n", #Parameters))

    for ParameterNumber, Parameter in ipairs(Parameters) do
        print(string.format("Parameter #%i -> '%s'\n", ParameterNumber, Parameter))
    end

    SetRadioVolume(Parameters[1])
    return false
end)

RegisterKeyBind(KEY_TOGGLE_RADIO, MODIFIERS_TOGGLE_RADIO, function()
    ExecuteInGameThread(function()
        ToggleRadio()
    end)
end)
RegisterKeyBind(KEY_CHANGE_RADIO_FREQUENCY, MODIFIERS_CHANGE_RADIO_FREQUENCY, function()
    ExecuteInGameThread(function()
        ChangeRadioFrequency()
    end)
end)