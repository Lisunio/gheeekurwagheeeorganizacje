local function teleport(coords)
    if not coords then return end

    local ped = cache.ped
    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do Wait(0) end

    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    DoScreenFadeIn(250)
end

function AddInteriorTargets(key, location)
    if location.interior ~= 'teleport' or not location.entry or not location.exit then
        return
    end

    exports.ox_target:addSphereZone({
        coords = location.entry,
        radius = 1.3,
        debug = Config.Debug,
        options = {{
            name = ('org_%s_enter'):format(key),
            icon = 'fa-solid fa-door-open',
            label = 'Wejdź do siedziby',
            canInteract = function()
                local org = LocalPlayer.state.org
                if org and org.location == key then
                    return true
                end

                local job = ESX.PlayerData.job
                return job and job.name == 'police' and HasTaran()
            end,
            onSelect = function()
                local org = LocalPlayer.state.org
                if org and org.location == key then
                    teleport(location.exit)
                    return
                end

                local job = ESX.PlayerData.job
                if not job or job.name ~= 'police' or not HasTaran() then
                    return
                end

                local success = lib.progressBar({
                    duration = Config.TaranDuration,
                    label = 'Wyważanie drzwi',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        move = true,
                        car = true,
                        combat = true
                    },
                    anim = {
                        dict = 'missheistfbisetup1',
                        clip = 'hassle_intro_loop_f'
                    }
                })

                if success then
                    TriggerServerEvent('lisunio-orgs:server:breach', key)
                end
            end
        }}
    })

    exports.ox_target:addSphereZone({
        coords = location.exit,
        radius = 1.3,
        debug = Config.Debug,
        options = {{
            name = ('org_%s_exit'):format(key),
            icon = 'fa-solid fa-door-closed',
            label = 'Wyjdź z siedziby',
            canInteract = function()
                local org = LocalPlayer.state.org
                return org and org.location == key
            end,
            onSelect = function()
                teleport(location.entry)
            end
        }}
    })

    RegisterNetEvent('lisunio-orgs:client:breach:' .. key, function()
        teleport(location.exit)
    end)
end
