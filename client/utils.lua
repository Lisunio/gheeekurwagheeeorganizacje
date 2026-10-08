function Notify(description, type)
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.orgTabletOpen then
        SendNUIMessage({
            action = 'notify',
            message = description,
            type = type or 'inform'
        })
        return
    end

    lib.notify({ description = description, type = type or 'inform' })
end

function OpenOrgStash(orgId)
    exports.ox_inventory:openInventory('stash', ('org_%s'):format(orgId))
end

function HasTaran()
    return (exports.ox_inventory:Search('count', Config.TaranItem) or 0) > 0
end

function OpenLocationStash(locationKey)
    local location = Config.Locations[locationKey]
    if not location then return end
    if location.type == 'criminal' then
        local org = LocalPlayer.state.org
        if org and org.location == locationKey then OpenOrgStash(org.id) end
    elseif location.type == 'company' and ESX.PlayerData.job and ESX.PlayerData.job.name == location.job then
        exports.ox_inventory:openInventory('stash', ('company_%s'):format(location.job))
    end
end
