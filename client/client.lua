
local text = Config.Texts
local debug = Config.Debug
local prompt = Config.Prompts 

Config.Textures = {
    cross = {"scoretimer_textures", "scoretimer_generic_cross"},
    locked = {"menu_textures","stamp_locked_rank"},
    tick = {"scoretimer_textures","scoretimer_generic_tick"},
    money = {"inventory_items", "money_moneystack"},
    alert = {"menu_textures", "menu_icon_alert"},
}

------------------------------------

local control = true
local PromptKey 
local PromptGroup = GetRandomIntInRange(0, 0xffffff)
local prompts = {}
local activeEntity = nil


local str = text.washing
PromptKey = PromptRegisterBegin()
PromptSetControlAction(PromptKey, prompt.interactions)
str = CreateVarString(10, 'LITERAL_STRING', str)
PromptSetText(PromptKey, str)
PromptSetEnabled(PromptKey, 1)
PromptSetVisible(PromptKey, 1)
PromptSetStandardMode(PromptKey,1)
PromptSetGroup(PromptKey, PromptGroup)
Citizen.InvokeNative(0xC5F428EE08FA7F2C,PromptKey,true)
PromptRegisterEnd(PromptKey)
prompts[#prompts+1] = PromptKey


---- Function 
function SetAnim(animDict,animName)
    SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_UNARMED'), true)
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(0)
    end

    TaskPlayAnim(PlayerPedId(), animDict,animName, 3.0, 3.0, -1, 25, 0, false, false, false) --- 4.0 / 4.0
end

function startWashing(_)
    DisableControl()
    Citizen.Wait(100)
    local entityMove = _
    local entityMoveCoords = GetEntityCoords(entityMove)

    TaskGoToCoordAnyMeans(PlayerPedId(), entityMoveCoords.x, entityMoveCoords.y, entityMoveCoords.z, 1.0, 0.0, false, 0.0)
    while GetScriptTaskStatus(PlayerPedId(), 0x93399E79) ~= 8 do
        Citizen.Wait(0)
    end
    Wait(100)
    TaskTurnPedToFaceEntity(PlayerPedId(),entityMove,1000,0.5,0.5,0.0)
    Citizen.Wait(2000)
    SetAnim('amb_misc@world_human_wash_face_bucket@table@male_a@idle_b', 'idle_e')
    Citizen.Wait(3000)
    SetAnim('amb_misc@world_human_wash_wading@wash_off@male_b@wip_base', 'wip_base')

    ClearPedEnvDirt(PlayerPedId())
    ClearPedBloodDamage(PlayerPedId())
    Citizen.InvokeNative(0xE3144B932DFDFF65, PlayerPedId(), 0.0, -1, true, true)
    ClearPedDamageDecalByZone(PlayerPedId(), 10)
    Citizen.InvokeNative(0x7F5D88333EE8A86F, PlayerPedId(), true)
    Citizen.Wait(Config.time*1000)
    ClearPedTasks(PlayerPedId())
    control = false
    TriggerEvent("Notification:d_labs_washing", 'success', text.notif, Config.Textures.alert[1], Config.Textures.alert[2], 2000)
    Citizen.Wait(2*1000)
end

function DisableControl()
    Citizen.CreateThread(function()
        control = true 
        while control do
            Citizen.Wait(0)
            Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x07CE1E61, true) -- Mouse
            Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xAC4BD4F1, true) -- WAPON (TAB)
            Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x4D8FB4C1, true) -- A/D
            Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0xFDA83190, true) -- W/S
            Citizen.InvokeNative(0xFE99B66D079CF6BC, 0, 0x8FFC75D6, true) -- Shift
        end
    end)
end

--- MAIN 

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(0)
        local max = 9999999
        local closestCoords = nil
        local closestDistance = max
        local PedCoords = GetEntityCoords(PlayerPedId())
        local SendEntity = nil


        for k, v in pairs(Config.Prop) do
            local entityCoords = nil

            activeEntity = GetClosestObjectOfType(PedCoords.x, PedCoords.y, PedCoords.z, 3.0, GetHashKey(v),false, false)
            if DoesEntityExist(activeEntity) then
                entityCoords = GetEntityCoords(activeEntity)
            end

            if entityCoords then
                local minus = vector3(entityCoords.x,entityCoords.y,entityCoords.z)
                local distance = #(GetEntityCoords(PlayerPedId()) - minus)
                if distance < closestDistance then
                    closestDistance = distance
                    closestCoords = entityCoords
                    SendEntity = activeEntity
                end
            end
        end

        if closestDistance < 3 then 
            local label = CreateVarString(10,'LITERAL_STRING', text.standingWater)
            PromptSetActiveGroupThisFrame(PromptGroup, label)

            if Citizen.InvokeNative(0xC92AC953F0A982AE,PromptKey) then
                startWashing(SendEntity)
            end
        else
            Citizen.Wait(2000)
        end

        SetEntityAsNoLongerNeeded(activeEntity)

    end
end)



------------- onResourceStop

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    ClearPedTasks(PlayerPedId())
end)

------------- Notification

RegisterNetEvent('Notification:d_labs_washing')
AddEventHandler('Notification:d_labs_washing', function(t1, t2, dict, txtr, timer)
    if not HasStreamedTextureDictLoaded(dict) then
        RequestStreamedTextureDict(dict, true) 
        while not HasStreamedTextureDictLoaded(dict) do
            Citizen.Wait(5)
        end
    end
    if txtr ~= nil then
        exports.d_labs_washing.LeftNot(0, tostring(t1), tostring(t2), tostring(dict), tostring(txtr), tonumber(timer))
    else
        local txtr = "tick"
        exports.d_labs_washing.LeftNot(0, tostring(t1), tostring(t2), tostring(dict), tostring(txtr), tonumber(timer))
    end
end)



