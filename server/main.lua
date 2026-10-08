ESX = exports['es_extended']:getSharedObject()

OrgCache = {}
PlayerOrg = {}
ActiveTasks = {}

local function notify(src, msg, type)
    TriggerClientEvent('lisunio-orgs:client:notify', src, msg, type or 'inform')
end

function IsAdmin(src)
    if src == 0 then return true end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local group = xPlayer.getGroup()
    for i = 1, #Config.AdminGroups do
        if group == Config.AdminGroups[i] then
            return true
        end
    end

    return false
end

function GetIdentifier(xPlayer)
    return xPlayer and xPlayer.getIdentifier() or nil
end

function GetOrgById(id)
    return OrgCache[tonumber(id)]
end

function GetPlayerOrganization(src)
    return PlayerOrg[src]
end

function HasOrgPermission(src, permission)
    local member = PlayerOrg[src]
    if not member then return false end

    local org = OrgCache[member.orgId]
    if not org then return false end

    if org.type == 'company' then
        local company = Config.Companies[org.job]
        local grade = company and company.grades and company.grades[tonumber(member.rankId)]
        local permissions = grade and grade.permissions or {}
        return permissions['*'] == true or permissions[permission] == true
    end

    local rank = org.ranks[member.rankId]
    if not rank then return false end
    return rank.permissions['*'] == true or rank.permissions[permission] == true
end

function syncOrgBalance(org)
    if not org or not org.bankIban then return 0 end
    if GetResourceState(Config.BankingResource) ~= 'started' then return 0 end

    local balance = tonumber(exports[Config.BankingResource]:getAccountMoney(org.bankIban)) or 0
    org.balance = balance
    return balance
end

function EnsureOrgBankAccount(org)
    if GetResourceState(Config.BankingResource) ~= 'started' then
        print(('[lisunio-orgs] ERROR: %s is not started.'):format(Config.BankingResource))
        return false
    end

    if org.bankIban then
        local exists = MySQL.scalar.await('SELECT iban FROM p_bank_accounts WHERE iban = ? LIMIT 1', { org.bankIban })
        if exists then
            syncOrgBalance(org)
            return true
        end
    end

    local iban = exports[Config.BankingResource]:generateUniqueIBAN()
    if not iban then return false end

    local inserted = MySQL.insert.await([[
        INSERT INTO p_bank_accounts
            (iban, owner, name, balance, type, credit_score, users, invoices, transactions, logs)
        VALUES (?, NULL, ?, 0, 'society', 0, '[]', '[]', '[]', '[]')
    ]], {
        iban,
        org.name
    })

    if not inserted then
        return false
    end

    MySQL.update.await('UPDATE lisunio_orgs SET bank_iban = ? WHERE id = ?', {
        iban,
        org.id
    })

    org.bankIban = iban
    org.balance = 0
    return true
end

local function getCompanyRanks(org)
    local company = Config.Companies[org.job]
    if not company then return {} end

    local list = {}
    for grade, rank in pairs(company.grades or {}) do
        list[#list + 1] = {
            id = tonumber(grade),
            name = rank.name or ('Stopień %s'):format(grade),
            level = tonumber(grade),
            permissions = rank.permissions or {}
        }
    end
    table.sort(list, function(a, b) return a.level < b.level end)
    return list
end

local function getCompanyMembers(org)
    local rows = MySQL.query.await([[
        SELECT identifier, CONCAT(COALESCE(firstname, ''), ' ', COALESCE(lastname, '')) AS name, job_grade
        FROM users
        WHERE job = ?
        ORDER BY job_grade DESC, firstname ASC
    ]], { org.job }) or {}

    local members = {}
    for i = 1, #rows do
        local row = rows[i]
        local name = OrgTrim(row.name)
        if name == '' then name = row.identifier end

        local online = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(row.identifier) or nil
        members[#members + 1] = {
            identifier = row.identifier,
            name = name,
            rankId = tonumber(row.job_grade) or 0,
            source = online and online.source or nil
        }
    end

    return members
end

local function serializeOrg(org, src)
    local member = PlayerOrg[src]
    if not member or not org then return nil end

    local rank
    local ranks
    local members

    if org.type == 'company' then
        local company = Config.Companies[org.job]
        if not company then return nil end
        local grade = company.grades[tonumber(member.rankId)] or company.grades[company.defaultGrade or 0]
        rank = {
            id = tonumber(member.rankId),
            name = grade and grade.name or 'Pracownik',
            level = tonumber(member.rankId) or 0,
            permissions = grade and grade.permissions or {}
        }
        ranks = getCompanyRanks(org)
        members = getCompanyMembers(org)
    else
        rank = org.ranks[member.rankId]
        ranks = org.ranksList
        members = org.members
    end

    local balance = syncOrgBalance(org)

    local notes = MySQL.query.await([[
        SELECT id, title, content, private, identifier, created_at, updated_at
        FROM lisunio_org_notes
        WHERE org_id = ? AND (private = 0 OR identifier = ?)
        ORDER BY updated_at DESC
        LIMIT 100
    ]], { org.id, member.identifier }) or {}

    local tasks = {}
    for id, task in pairs(Config.Tasks) do
        tasks[#tasks + 1] = {
            id = id,
            label = task.label,
            description = task.description,
            cooldown = task.cooldown or 0,
            requirements = {
                minPolice = task.requirements and task.requirements.minPolice or 0,
                minRank = task.requirements and task.requirements.minRank or 0
            }
        }
    end

    return {
        id = org.id,
        name = org.name,
        short = org.short,
        type = org.type,
        location = org.location,
        job = org.job,
        bankIban = org.bankIban,
        balance = balance,
        me = {
            identifier = member.identifier,
            name = member.name,
            rankId = member.rankId
        },
        rank = rank and {
            id = rank.id,
            name = rank.name,
            level = rank.level,
            permissions = rank.permissions
        } or nil,
        ranks = ranks,
        members = members,
        notes = notes,
        tasks = tasks,
        shops = Config.Shop,
        company = org.type == 'company'
    }
end

local function loadOrganizations()
    local orgs = MySQL.query.await('SELECT * FROM lisunio_orgs') or {}

    for i = 1, #orgs do
        local row = orgs[i]
        local org = {
            id = row.id,
            name = row.name,
            short = row.short,
            type = row.type,
            location = row.location,
            job = row.job,
            bankIban = row.bank_iban,
            ranks = {},
            ranksList = {},
            members = {},
            balance = 0
        }

        local ranks = MySQL.query.await('SELECT * FROM lisunio_org_ranks WHERE org_id = ? ORDER BY level ASC', { row.id }) or {}
        for r = 1, #ranks do
            local rankRow = ranks[r]
            local permissions = json.decode(rankRow.permissions or '{}') or {}
            if tonumber(rankRow.level) == 1 and next(permissions) == nil then
                permissions = {
                    ['tablet.view'] = true,
                    ['tasks.view'] = true,
                    ['notes.view'] = true,
                    ['notes.write'] = true,
                    ['notes.org'] = true,
                    ['shop.view'] = true,
                    ['bank.view'] = true
                }
                MySQL.update.await('UPDATE lisunio_org_ranks SET permissions = ? WHERE id = ?', { json.encode(permissions), rankRow.id })
            end
            local rank = {
                id = rankRow.id,
                name = rankRow.name,
                level = rankRow.level,
                permissions = permissions
            }

            org.ranks[rank.id] = rank
            org.ranksList[#org.ranksList + 1] = rank
        end

        if #ranks == 0 then
            local id = MySQL.insert.await([[
                INSERT INTO lisunio_org_ranks (org_id, name, level, permissions)
                VALUES (?, 'Członek', 1, ?)
            ]], { row.id, '{}' })

            local rank = {
                id = id,
                name = 'Członek',
                level = 1,
                permissions = {}
            }

            org.ranks[id] = rank
            org.ranksList[1] = rank
        end

        local members = MySQL.query.await('SELECT * FROM lisunio_org_members WHERE org_id = ?', { row.id }) or {}
        for m = 1, #members do
            local memberRow = members[m]
            org.members[memberRow.identifier] = {
                identifier = memberRow.identifier,
                name = memberRow.name,
                rankId = memberRow.rank_id,
                joinedAt = memberRow.joined_at
            }
        end

        OrgCache[org.id] = org

        if not EnsureOrgBankAccount(org) then
            print(('[lisunio-orgs] WARNING: nie udało się utworzyć konta bankowego dla org #%s.'):format(org.id))
        end

        local location = Config.Locations[org.location]
        if location then
            exports.ox_inventory:RegisterStash(
                ('org_%s'):format(org.id),
                org.name,
                location.slots or 80,
                location.capacity or 500000,
                nil,
                nil,
                location.stash
            )
        end
    end

    for _, location in pairs(Config.Locations) do
        if location.type == 'company' and location.job then
            exports.ox_inventory:RegisterStash(
                ('company_%s'):format(location.job),
                location.label,
                location.slots or 80,
                location.capacity or 500000,
                nil,
                nil,
                location.stash
            )
        end
    end
end

function refreshPlayer(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = GetIdentifier(xPlayer)
    PlayerOrg[src] = nil
    Player(src).state:set('org', nil, true)

    -- Najpierw organizacja kryminalna.
    for _, org in pairs(OrgCache) do
        if org.type == 'criminal' then
            local member = org.members[identifier]
            if member then
                PlayerOrg[src] = {
                    orgId = org.id,
                    identifier = identifier,
                    name = member.name,
                    rankId = member.rankId,
                    company = false
                }
                Player(src).state:set('org', {
                    id = org.id,
                    name = org.name,
                    short = org.short,
                    type = org.type,
                    location = org.location,
                    rankId = member.rankId,
                    company = false
                }, true)
                return
            end
        end
    end

    -- Firma jest rozpoznawana wyłącznie po ESX jobie.
    if Config.CompanyUsesESXJob and xPlayer.job then
        for _, org in pairs(OrgCache) do
            if org.type == 'company' and org.job == xPlayer.job.name and Config.Companies[org.job] then
                local grade = tonumber(xPlayer.job.grade) or 0
                local company = Config.Companies[org.job]
                if not company.grades[grade] then
                    grade = tonumber(company.defaultGrade) or 0
                end

                PlayerOrg[src] = {
                    orgId = org.id,
                    identifier = identifier,
                    name = xPlayer.getName(),
                    rankId = grade,
                    company = true
                }

                Player(src).state:set('org', {
                    id = org.id,
                    name = org.name,
                    short = org.short,
                    type = 'company',
                    location = org.location,
                    job = org.job,
                    rankId = grade,
                    company = true
                }, true)
                return
            end
        end
    end
end

exports.ox_inventory:registerHook('openInventory', function(payload)
    if payload.inventoryType ~= 'stash' then return end
    if type(payload.inventoryId) ~= 'string' then return end

    local orgId = payload.inventoryId:match('^org_(%d+)$')
    if orgId then
        local member = PlayerOrg[payload.source]
        if not member or member.orgId ~= tonumber(orgId) then
            return false
        end
        return
    end

    local companyJob = payload.inventoryId:match('^company_(.+)$')
    if companyJob then
        local xPlayer = ESX.GetPlayerFromId(payload.source)
        if not xPlayer or not xPlayer.job or xPlayer.job.name ~= companyJob then
            return false
        end
    end
end, {})

CreateThread(function()
    Wait(1000)

    MySQL.query.await('ALTER TABLE lisunio_orgs ADD COLUMN IF NOT EXISTS bank_iban varchar(20) DEFAULT NULL')
    loadOrganizations()

    Wait(500)
    local players = GetPlayers()
    for i = 1, #players do
        refreshPlayer(tonumber(players[i]))
    end
end)

AddEventHandler('playerDropped', function()
    PlayerOrg[source] = nil
    ActiveTasks[source] = nil
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    if playerId then
        SetTimeout(500, function()
            refreshPlayer(playerId)
        end)
    end
end)

AddEventHandler('esx:setJob', function(playerId)
    if playerId then
        SetTimeout(250, function()
            refreshPlayer(playerId)
        end)
    end
end)

RegisterNetEvent('lisunio-orgs:server:requestData', function()
    local src = source
    local member = PlayerOrg[src]
    if not member then
        TriggerClientEvent('lisunio-orgs:client:data', src, nil)
        return
    end

    local org = OrgCache[member.orgId]
    TriggerClientEvent('lisunio-orgs:client:data', src, serializeOrg(org, src))
end)

RegisterNetEvent('lisunio-orgs:server:refresh', function()
    refreshPlayer(source)
end)

local function getPlayerBank(xPlayer)
    if not xPlayer then return 0 end
    if GetResourceState(Config.BankingResource) ~= 'started' then return 0 end
    return tonumber(exports[Config.BankingResource]:getAccountMoney(GetIdentifier(xPlayer))) or 0
end

RegisterNetEvent('lisunio-orgs:server:deposit', function(amount)
    local src = source
    if not HasOrgPermission(src, 'bank.deposit') then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return notify(src, 'Podaj prawidłową kwotę.', 'error')
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    local member = PlayerOrg[src]
    local org = member and OrgCache[member.orgId]
    if not xPlayer or not org or not org.bankIban then return end

    local identifier = GetIdentifier(xPlayer)
    local personalBalance = getPlayerBank(xPlayer)

    if personalBalance < amount then
        return notify(src, ('Masz tylko %s $ na koncie bankowym.'):format(personalBalance), 'error')
    end

    local removed = exports[Config.BankingResource]:removeAccountMoney(identifier, amount)
    if not removed then
        return notify(src, 'Bank odrzucił operację pobrania pieniędzy.', 'error')
    end

    local added = exports[Config.BankingResource]:addAccountMoney(org.bankIban, amount)
    if not added then
        exports[Config.BankingResource]:addAccountMoney(identifier, amount)
        return notify(src, 'Nie udało się zasilić konta organizacji. Pieniądze zwrócono.', 'error')
    end

    syncOrgBalance(org)

    exports[Config.BankingResource]:createHistory({
        iban = org.bankIban,
        type = 'income',
        amount = amount,
        title = 'Wpłata do organizacji',
        from = xPlayer.getName(),
        to = org.name
    })

    notify(src, ('Wpłacono %s $ do organizacji.'):format(amount), 'success')
    TriggerClientEvent('lisunio-orgs:client:requestRefresh', src)
end)

RegisterNetEvent('lisunio-orgs:server:withdraw', function(amount)
    local src = source
    if not HasOrgPermission(src, 'bank.withdraw') then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return notify(src, 'Podaj prawidłową kwotę.', 'error')
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    local member = PlayerOrg[src]
    local org = member and OrgCache[member.orgId]
    if not xPlayer or not org or not org.bankIban then return end

    local orgBalance = syncOrgBalance(org)
    if orgBalance < amount then
        return notify(src, ('Organizacja ma tylko %s $ na koncie.'):format(orgBalance), 'error')
    end

    local removed = exports[Config.BankingResource]:removeAccountMoney(org.bankIban, amount)
    if not removed then
        return notify(src, 'Nie udało się pobrać pieniędzy z konta organizacji.', 'error')
    end

    local identifier = GetIdentifier(xPlayer)
    local added = exports[Config.BankingResource]:addAccountMoney(identifier, amount)
    if not added then
        exports[Config.BankingResource]:addAccountMoney(org.bankIban, amount)
        return notify(src, 'Nie udało się zasilić twojego konta. Pieniądze zwrócono organizacji.', 'error')
    end

    syncOrgBalance(org)

    exports[Config.BankingResource]:createHistory({
        iban = org.bankIban,
        type = 'outcome',
        amount = amount,
        title = 'Wypłata z organizacji',
        from = org.name,
        to = xPlayer.getName()
    })

    notify(src, ('Wypłacono %s $ z organizacji.'):format(amount), 'success')
    TriggerClientEvent('lisunio-orgs:client:requestRefresh', src)
end)

exports('GetPlayerOrg', function(src)
    return PlayerOrg[src]
end)

exports('GetOrg', function(id)
    return OrgCache[tonumber(id)]
end)

exports('HasOrgPermission', HasOrgPermission)
