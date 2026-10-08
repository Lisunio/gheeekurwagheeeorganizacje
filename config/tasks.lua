Config.Tasks = {
    package = {
        label = 'Przechwycenie przesyłki',
        description = 'Odbierz przesyłkę i dostarcz ją do wskazanego punktu.',
        cooldown = 1800,
        requirements = {
            minPolice = 2,
            minRank = 2,
            custom = function(source, org)
                return true
            end
        },
        start = function(source, org)
            return {
                destination = vec3(1212.0, -1261.0, 35.2)
            }
        end,
        check = function(source, org, state)
            local ped = GetPlayerPed(source)
            if ped == 0 then return false end
            local coords = GetEntityCoords(ped)
            return #(coords - state.destination) <= 4.0
        end,
        reward = function(source, org, state)
            return {
                money = 15000,
                items = {
                    { name = 'lockpick', count = 2 }
                }
            }
        end
    },

    -- Własne zadania dodawaj tutaj.
}
