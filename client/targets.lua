local function addTarget(name, coords, icon, label, action, canInteract)
    if not coords then return end

    exports.ox_target:addSphereZone({
        coords = coords,
        radius = 1.0,
        debug = Config.Debug,
        options = {{
            name = name,
            icon = icon,
            label = label,
            canInteract = canInteract,
            onSelect = action
        }}
    })
end

local function hasAccess(locationKey)
    local org = LocalPlayer.state.org
    return org and org.location == locationKey
end

CreateThread(function()
    for key, location in pairs(Config.Locations) do
        addTarget(
            ('org_%s_tablet'):format(key),
            location.coords,
            'fa-solid fa-tablet-screen-button',
            'Otwórz tablet',
            function()
                TriggerEvent('lisunio-orgs:client:openTablet')
            end,
            function()
                if location.type == 'criminal' then
                    return hasAccess(key)
                end

                return ESX.PlayerData.job and ESX.PlayerData.job.name == location.job
            end
        )

        addTarget(
            ('org_%s_stash'):format(key),
            location.stash,
            'fa-solid fa-box',
            'Otwórz szafkę organizacji',
            function()
                OpenLocationStash(key)
            end,
            function()
                return hasAccess(key) or (
                    location.type == 'company' and
                    ESX.PlayerData.job and
                    ESX.PlayerData.job.name == location.job
                )
            end
        )

        addTarget(
            ('org_%s_clothing'):format(key),
            location.clothing,
            'fa-solid fa-shirt',
            'Szafka z ubraniami',
            function()
                if Config.ClothingExport then
                    Config.ClothingExport()
                else
                    Notify('Podłącz Config.ClothingExport w config.lua.', 'error')
                end
            end,
            function()
                return hasAccess(key) or (
                    location.type == 'company' and
                    ESX.PlayerData.job and
                    ESX.PlayerData.job.name == location.job
                )
            end
        )

        AddInteriorTargets(key, location)
    end
end)
