local function buildCompanyRanks(org)
    local company = Config.Companies[org.job]
    if not company then return end

    org.ranks = {}
    org.ranksList = {}

    for grade, rank in pairs(company.grades or {}) do
        local r = {
            id = tonumber(grade),
            name = rank.name or ('Stopień %s'):format(grade),
            level = tonumber(grade),
            permissions = rank.permissions or {}
        }
        org.ranks[r.id] = r
        org.ranksList[#org.ranksList + 1] = r
    end

    table.sort(org.ranksList, function(a, b) return a.level < b.level end)
end

local function createOrg(src, target, name, short, location)
    if not IsAdmin(src) then return false, 'Brak uprawnień.' end

    target = tonumber(target)
    name = OrgTrim(name)
    short = OrgShort(short, Config.MaxShortLength)
    location = OrgTrim(location)

    local loc = Config.Locations[location]
    if not target or name == '' or short == '' or not loc then
        return false, 'Nieprawidłowe dane.'
    end

    if #name > Config.MaxOrgNameLength then
        return false, 'Nazwa jest za długa.'
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return false, 'Gracz musi być online.' end

    if loc.type == 'company' then
        if not Config.Companies[loc.job] then
            return false, ('Job %s nie jest skonfigurowany w Config.Companies.'):format(loc.job or '?')
        end

        local existsJob = MySQL.scalar.await('SELECT id FROM lisunio_orgs WHERE type = "company" AND job = ? LIMIT 1', { loc.job })
        if existsJob then return false, 'Organizacja tej firmy już istnieje.' end
    end

    local exists = MySQL.scalar.await('SELECT id FROM lisunio_orgs WHERE short = ?', { short })
    if exists then return false, 'Taki skrót już istnieje.' end

    local orgId = MySQL.insert.await([[
        INSERT INTO lisunio_orgs (name,short,type,location,job,created_by,bank_iban)
        VALUES (?,?,?,?,?,?,?)
    ]], {
        name, short, loc.type, location, loc.job,
        GetIdentifier(ESX.GetPlayerFromId(src)), nil
    })

    local org = {
        id = orgId,
        name = name,
        short = short,
        type = loc.type,
        location = location,
        job = loc.job,
        bankIban = nil,
        ranks = {},
        ranksList = {},
        members = {},
        balance = 0
    }

    if loc.type == 'company' then
        buildCompanyRanks(org)
        local defaultGrade = tonumber(Config.Companies[loc.job].defaultGrade) or 0
        xTarget.setJob(loc.job, defaultGrade)
    else
        local bossId = MySQL.insert.await('INSERT INTO lisunio_org_ranks (org_id,name,level,permissions) VALUES (?,?,?,?)', {
            orgId, 'Szef', 100, json.encode({ ['*'] = true })
        })

        MySQL.insert.await('INSERT INTO lisunio_org_ranks (org_id,name,level,permissions) VALUES (?,?,?,?)', {
            orgId, 'Członek', 1, json.encode({
                ['tablet.view'] = true,
                ['members.view'] = true,
                ['tasks.view'] = true,
                ['notes.view'] = true,
                ['notes.write'] = true,
                ['notes.org'] = true,
                ['shop.view'] = true,
                ['shop.buy'] = true,
                ['bank.view'] = true
            })
        })

        MySQL.insert.await('INSERT INTO lisunio_org_members (org_id,identifier,name,rank_id) VALUES (?,?,?,?)', {
            orgId, GetIdentifier(xTarget), xTarget.getName(), bossId
        })

        local ranks = MySQL.query.await('SELECT * FROM lisunio_org_ranks WHERE org_id = ? ORDER BY level', { orgId }) or {}
        for i = 1, #ranks do
            local r = ranks[i]
            local rr = {
                id = r.id,
                name = r.name,
                level = r.level,
                permissions = json.decode(r.permissions or '{}') or {}
            }
            org.ranks[rr.id] = rr
            org.ranksList[#org.ranksList + 1] = rr
        end

        org.members[GetIdentifier(xTarget)] = {
            identifier = GetIdentifier(xTarget),
            name = xTarget.getName(),
            rankId = bossId
        }
    end

    OrgCache[orgId] = org
    EnsureOrgBankAccount(org)
    refreshPlayer(target)

    return true, ('Utworzono %s #%s.'):format(loc.type == 'company' and 'firmę' or 'organizację', orgId)
end

RegisterCommand(Config.AdminCommand, function(src, args)
    local ok, msg = createOrg(src, args[1], args[2], args[3], args[4])
    if src == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', src, { description=msg, type=ok and 'success' or 'error' }) end
end, false)

RegisterCommand(Config.AdminDeleteCommand, function(src, args)
    if not IsAdmin(src) then return end
    local id = tonumber(args[1]); local org = id and OrgCache[id]
    if not org then return end
    if org.type == 'company' and org.job and Config.Companies[org.job] then
        local company = Config.Companies[org.job]
        local users = MySQL.query.await('SELECT identifier FROM users WHERE job = ?', { org.job }) or {}
        for i = 1, #users do
            local x = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(users[i].identifier) or nil
            if x then
                x.setJob(company.fireJob or 'unemployed', tonumber(company.fireGrade) or 0)
            else
                MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ? AND job = ?', {
                    company.fireJob or 'unemployed', tonumber(company.fireGrade) or 0, users[i].identifier, org.job
                })
            end
        end
    end

    MySQL.update.await('DELETE FROM lisunio_orgs WHERE id = ?', { id })
    OrgCache[id] = nil
    for playerId, member in pairs(PlayerOrg) do
        if member.orgId == id then refreshPlayer(playerId) end
    end
end, false)

exports('CreateOrganization', createOrg)
exports('CreateCompany', createOrg)

RegisterCommand('orgcreatecompany', function(src, args)
    local ok, msg = createOrg(src, args[1], args[2], args[3], args[4])
    if src == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', src, { description = msg, type = ok and 'success' or 'error' }) end
end, false)

RegisterNetEvent('lisunio-orgs:server:breach', function(locationKey)
    local src = source
    local location = Config.Locations[locationKey]
    if not location or location.interior ~= 'teleport' then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= 'police' then return end
    local count = exports.ox_inventory:Search(src, 'count', Config.TaranItem) or 0
    if count < 1 then return end
    exports.ox_inventory:RemoveItem(src, Config.TaranItem, 1)
    TriggerClientEvent('lisunio-orgs:client:breach:' .. locationKey, src)
end)
