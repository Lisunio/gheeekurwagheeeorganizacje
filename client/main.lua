local tabletOpen = false
local currentData = nil
local tabletObject = nil
local tabletDict = Config.Tablet.animDict
local tabletClip = Config.Tablet.animClip

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    return hash
end

local function loadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end

local function startTabletAnimation()
    if tabletObject and DoesEntityExist(tabletObject) then return end

    local ped = cache.ped
    loadAnim(tabletDict)

    local model = loadModel(Config.Tablet.prop)
    tabletObject = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)

    AttachEntityToEntity(
        tabletObject,
        ped,
        GetPedBoneIndex(ped, Config.Tablet.bone),
        Config.Tablet.offset.x,
        Config.Tablet.offset.y,
        Config.Tablet.offset.z,
        Config.Tablet.rotation.x,
        Config.Tablet.rotation.y,
        Config.Tablet.rotation.z,
        true,
        true,
        false,
        true,
        2,
        true
    )

    SetModelAsNoLongerNeeded(model)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    TaskPlayAnim(ped, tabletDict, tabletClip, 8.0, -8.0, -1, 49, 0.0, false, false, false)
end

local function stopTabletAnimation()
    local ped = cache.ped

    StopAnimTask(ped, tabletDict, tabletClip, 8.0)
    ClearPedSecondaryTask(ped)

    if tabletObject and DoesEntityExist(tabletObject) then
        DetachEntity(tabletObject, true, true)
        DeleteEntity(tabletObject)
    end

    tabletObject = nil
end

local function requestTabletData()
    TriggerServerEvent('lisunio-orgs:server:requestData')
end

local function openTablet()
    if tabletOpen then return end

    if not LocalPlayer.state.org then
        return Notify(Config.Messages.noAccess, 'error')
    end

    requestTabletData()
end

local function reallyOpenTablet(data)
    if tabletOpen or not data then return end

    currentData = data
    tabletOpen = true
    LocalPlayer.state:set('orgTabletOpen', true, false)

    startTabletAnimation()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'open',
        data = data
    })
end

RegisterNetEvent('lisunio-orgs:client:openTablet', openTablet)

RegisterNetEvent('lisunio-orgs:client:data', function(data)
    if not data then
        if tabletOpen then
            SetNuiFocus(false, false)
            tabletOpen = false
            LocalPlayer.state:set('orgTabletOpen', false, false)
            stopTabletAnimation()
        end

        return Notify('Nie należysz do organizacji.', 'error')
    end

    if tabletOpen then
        currentData = data
        SendNUIMessage({ action = 'update', data = data })
        return
    end

    reallyOpenTablet(data)
end)

RegisterNetEvent('lisunio-orgs:client:requestRefresh', function()
    if tabletOpen then
        requestTabletData()
    end
end)

RegisterCommand(Config.OpenCommand, openTablet, false)

exports('OpenTablet', openTablet)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    tabletOpen = false
    LocalPlayer.state:set('orgTabletOpen', false, false)
    stopTabletAnimation()
    cb(1)
end)

RegisterNUICallback('refresh', function(_, cb)
    requestTabletData()
    cb(1)
end)

RegisterNUICallback('action', function(data, cb)
    local action = data.action

    if action == 'hire' then
        TriggerServerEvent('lisunio-orgs:server:hire', data.target, data.rankId)
    elseif action == 'fire' then
        TriggerServerEvent('lisunio-orgs:server:fire', data.identifier)
    elseif action == 'rank' then
        TriggerServerEvent('lisunio-orgs:server:setRank', data.identifier, data.rankId)
    elseif action == 'createRank' then
        TriggerServerEvent('lisunio-orgs:server:createRank', data.name, data.level, data.permissions)
    elseif action == 'updateRank' then
        TriggerServerEvent('lisunio-orgs:server:updateRank', data.rankId, data.name, data.level, data.permissions)
    elseif action == 'deposit' then
        TriggerServerEvent('lisunio-orgs:server:deposit', data.amount)
    elseif action == 'withdraw' then
        TriggerServerEvent('lisunio-orgs:server:withdraw', data.amount)
    elseif action == 'startTask' then
        TriggerServerEvent('lisunio-orgs:server:startTask', data.taskId)
    elseif action == 'finishTask' then
        TriggerServerEvent('lisunio-orgs:server:finishTask')
    elseif action == 'addNote' then
        TriggerServerEvent('lisunio-orgs:server:addNote', data.title, data.content, data.private)
    elseif action == 'deleteNote' then
        TriggerServerEvent('lisunio-orgs:server:deleteNote', data.id)
    elseif action == 'buy' then
        TriggerServerEvent('lisunio-orgs:server:buy', data.shopId, data.item, data.amount)
    end

    SetTimeout(300, function()
        if tabletOpen then requestTabletData() end
    end)

    cb(1)
end)

RegisterNetEvent('lisunio-orgs:client:notify', function(message, type)
    Notify(message, type)
end)

RegisterNetEvent('lisunio-orgs:client:taskStarted', function(id, state)
    Notify(('Rozpoczęto zadanie: %s'):format(id), 'success')

    if state and state.destination then
        SetNewWaypoint(state.destination.x, state.destination.y)
    end
end)

RegisterNetEvent('lisunio-orgs:client:taskFinished', function()
    Notify('Zadanie wykonane. Nagroda została wypłacona.', 'success')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    stopTabletAnimation()
end)

CreateThread(function()
    while true do
        if tabletOpen then
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)

            if not IsEntityPlayingAnim(cache.ped, tabletDict, tabletClip, 3) then
                TaskPlayAnim(cache.ped, tabletDict, tabletClip, 8.0, -8.0, -1, 49, 0.0, false, false, false)
            end

            Wait(500)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('lisunio-orgs:server:refresh')
end)
