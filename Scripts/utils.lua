local UEHelpers = require("UEHelpers")
require("uemath")

-- UEHelpers function shortcuts
GetKismetSystemLibrary = UEHelpers.GetKismetSystemLibrary ---@type fun(ForceInvalidateCache: boolean?): UKismetSystemLibrary
GetKismetMathLibrary = UEHelpers.GetKismetMathLibrary ---@type fun(ForceInvalidateCache: boolean?): UKismetMathLibrary
GetGameplayStatics = UEHelpers.GetGameplayStatics ---@type fun(ForceInvalidateCache: boolean?): UGameplayStatics

local modName = "PortableRadio"

function dprint(...)
    if (not DEBUG) then return false end
    return print("[" .. modName .. "] " .. table.concat({...}, ", "))
end

---@param object UObject
---@return boolean Valid
function IsValid(object)
    return object ~= nil and object.IsValid ~= nil and object:IsValid()
end

---@param object UObject
---@return boolean NotValid
function IsNotValid(object)
    return not IsValid(object)
end

function CreateInvalidObject()
    return nil
end

function SpawnActorFromClass(ActorClassName, Location, Rotation)
    local invalidActor = CreateInvalidObject()

    dprint("SpawnActorFromClass: " .. ActorClassName .. "\n")

    if type(ActorClassName) ~= "string" or not Location then return invalidActor end
    Rotation = Rotation or FRotator()

    local gameplayStatics = GetGameplayStatics()
    if IsNotValid(gameplayStatics) then return invalidActor end

    dprint("SpawnActorFromClass: gameplayStatics: " .. gameplayStatics:type() .. "\n")

    local world = UEHelpers.GetWorld()
    if IsNotValid(world) then return invalidActor end

    dprint("SpawnActorFromClass: world: " .. world:type() .. "\n")

    local actorClass = StaticFindObject(ActorClassName)
    if IsValid(actorClass) and (actorClass:type() == "AActor") then
        dprint("SpawnActorFromClass: Actor class found: " .. actorClass:type() .. "\n")
        local class = gameplayStatics:GetObjectClass(actorClass)

        if IsValid(class) and (class:type() == "UClass") then
            dprint("SpawnActorFromClass: Class found: " .. class:type() .. "\n")
            actorClass = class
        end
    end

    if IsNotValid(actorClass) or (actorClass:type() ~= "UClass") then return invalidActor end

    local actor = world:SpawnActor(actorClass, Location, Rotation)

    if IsValid(actor) then
        dprint("SpawnActorFromClass: Actor successfully spawned: " .. actor:type() .. "\n")
        return actor
    end

    dprint("SpawnActorFromClass: Failed to spawn actor\n" .. "\n")
    return invalidActor
end

--- Returns the first valid PlayerController that is currently controlled by a player.
---@return APlayerController?
local PlayerController = nil
function GetPlayerController()
    if PlayerController and PlayerController:IsValid() then return PlayerController end
    -- local PlayerControllers = jsb.simpleBench("findallof", FindAllOf, "Controller")
    -- Uncomment line above and comment line below to profile this function
    local PlayerControllers = FindAllOf("PlayerController")
    if not PlayerControllers then return end
    for _, Controller in pairs(PlayerControllers or {}) do
        if Controller.Pawn:IsValid() and Controller.Pawn:IsPlayerControlled() then
            PlayerController = Controller
            break
        end
    end
    if PlayerController and PlayerController:IsValid() then
        return PlayerController
    end
    dprint("No PlayerController found\n")
    return nil
end

---@return Pawn
function GetPlayerPawn()
    local playerController = GetPlayerController()
    if IsNotValid(playerController) then return CreateInvalidObject() end

    return playerController.Pawn
end

function GetPlayerCharacter()
    local playerController = GetPlayerController()
    if IsNotValid(playerController) then return CreateInvalidObject() end

    return playerController.Character
end

function GetPlayerCharacterMovement()
    local playerCharacter = GetPlayerCharacter()
    if IsNotValid(playerCharacter) then return CreateInvalidObject() end

    return playerCharacter.CharacterMovement
end

---@return FVector?
function GetPlayerForwardVector()
    local playerPawn = GetPlayerPawn()
    if IsNotValid(playerPawn) then return nil end

    local kismetSystemLibrary = GetKismetSystemLibrary()
    if not kismetSystemLibrary then return nil end

    return playerPawn:GetActorForwardVector()
end

---@return FVector?
function GetPlayerLocation()
    local playerPawn = GetPlayerPawn()
    if IsNotValid(playerPawn) then return nil end

    return playerPawn:K2_GetActorLocation()
end

---@return FRotator?
function GetPlayerRotation()
    local playerPawn = GetPlayerPawn()
    if IsNotValid(playerPawn) then return nil end

    return playerPawn:K2_GetActorRotation()
end
