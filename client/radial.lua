local radialId = 'lisunio-org-tablet'

local function updateRadial()
    local org = LocalPlayer.state.org

    if org then
        lib.addRadialItem({
            id = radialId,
            label = 'Tablet organizacji',
            icon = 'tablet-screen-button',
            onSelect = function()
                TriggerEvent('lisunio-orgs:client:openTablet')
            end
        })
    else
        lib.removeRadialItem(radialId)
    end
end

AddStateBagChangeHandler('org', nil, function(bagName)
    local localBag = ('player:%s'):format(GetPlayerServerId(PlayerId()))
    if bagName ~= localBag then return end
    SetTimeout(100, updateRadial)
end)

CreateThread(function()
    Wait(1500)
    updateRadial()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        lib.removeRadialItem(radialId)
    end
end)
