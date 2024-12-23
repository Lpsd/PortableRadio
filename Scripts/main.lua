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
        dprint("Invalid class name")
        return
    end

    -- Create object in front of player
    local position = GetPlayerLocation()

    if (not position) then
        dprint("Failed to get player position")
        return
    end

    dprint("Player position: " .. VectorToString(position))
    dprint("Spawning object at " .. position.X .. ", " .. position.Y .. ", " .. position.Z)

    local object = SpawnActorFromClass(className, FVector(position.X, position.Y, position.Z), FRotator(0, 0, 0))

    if (IsValid(object)) then
        dprint("Object spawned successfully")
        return object
    else
        dprint("Failed to spawn object")
        return nil
    end
end

function SpawnPortableRadio()
    if (not isEnabled) then return end
    print("SpawnPortableRadio:\n")

    if IsValid(playerRadio) then
        dprint("Radio already spawned")
        return nil
    end

    if (ALWAYS_TRY_LOAD_ASSET) then
        LoadAsset(RADIO_BP_ASSET)
    end

    playerRadio = SpawnFromClass(RADIO_BP_ASSET)

    if IsNotValid(playerRadio) then
        playerRadio = nil
        dprint("Failed to spawn radio\n")
        return
    end

    playerRadio:SetActorEnableCollision(false)
    playerRadio:SetActorHiddenInGame(true)

    local playerPawn = GetPlayerPawn()

    if IsValid(playerPawn) and IsValid(playerPawn.RootComponent) then
        playerRadio:K2_AttachToComponent(playerPawn.RootComponent, playerPawn.RootComponent:GetAttachSocketName(), 1, 1, 1, false)
        dprint("Radio attached to player")
    end

    TurnOnRadio()
    dprint("Radio spawned\n")
end

function GetRadio()
    return IsValid(playerRadio) and playerRadio or nil
end

function TurnOnRadio()
    if (not isEnabled) then return end

    if (radioEnabled) then
        return false
    end

    if IsNotValid(playerRadio) then
        SpawnPortableRadio()
        return false
    end

    playerRadio:BndEvt__BP_Interactable_Radio_120_HoldOn_K2Node_ComponentBoundEvent_10_InteractSignature__DelegateSignature()
    dprint("Radio turned on\n")

    SetRadioVolume(DEFAULT_RADIO_VOLUME)
    radioEnabled = true
    return true
end

function TurnOffRadio()
    if (not isEnabled) then return end
    if (changedRadioFrequency) then return false end

    if (not radioEnabled) then
        return false
    end

    if IsNotValid(playerRadio) then
        radioEnabled = false
        dprint("Radio not spawned\n")
        return false
    end

    playerRadio:BndEvt__BP_Interactable_Radio_120_HoldOff_K2Node_ComponentBoundEvent_11_InteractSignature__DelegateSignature()
    dprint("Radio turned off\n")

    radioEnabled = false
    return true
end

function ToggleRadio()
    if (not isEnabled) then return end

    if (radioEnabled) then
        if IsNotValid(playerRadio) then
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
    if (not isEnabled) then return end
    if (not radioEnabled) then return end

    if IsNotValid(playerRadio) then
        dprint("Attempted to change radio frequency, but radio not spawned\n")
        return false
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
    if IsValid(playerRadio) and (not playerRadio.bActorIsBeingDestroyed) then
        dprint("Destroying radio by actor\n")
        playerRadio:K2_DestroyActor()
        playerRadio = nil
    end
end

function SetRadioVolume(volume)
    if (not isEnabled) then return end

    volume = tonumber(volume)

    if (not volume) then
        dprint("Invalid volume value")
        return
    end

    if IsNotValid(playerRadio) then
        dprint("Attempted to set radio volume, but radio not spawned\n")
        return
    end

    local audio = playerRadio.InteractableRadioAk

    if IsNotValid(audio) then
        dprint("Failed to get radio audio component")
        return
    end

    audio:SetOutputBusVolume(volume)
    dprint("Radio volume set to " .. volume)
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

    dprint("Loading screen\n")
end)

NotifyOnNewObject("/Script/Stalker2.DeathScreen", function(self)
    DestroyRadio()

    isEnabled = false
    dprint("Death screen\n")
end)

NotifyOnNewObject("/Script/Stalker2.Stalker2PlayerController", function(self)
    isEnabled = true
    dprint("Player created")
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