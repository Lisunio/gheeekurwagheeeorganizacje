local function orgAndMember(src)
    local p = PlayerOrg[src]
    return p and OrgCache[p.orgId], p
end

local function canManageTarget(myLevel, targetLevel)
    return tonumber(targetLevel) < tonumber(myLevel)
end

RegisterNetEvent('lisunio-orgs:server:hire', function(targetId, rankId)
    local src = source
    if not HasOrgPermission(src, 'members.hire') then return end

    local org, me = orgAndMember(src)
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not org or not me or not target or target.source == src then return end

    if org.type == 'company' then
        local company = Config.Companies[org.job]
        if not company then return end

        local targetGrade = tonumber(rankId) or tonumber(company.defaultGrade) or 0
        local myGrade = tonumber(me.rankId) or 0
        local grade = company.grades[targetGrade]
        if not grade or not canManageTarget(myGrade, targetGrade) then return end

        target.setJob(org.job, targetGrade)
        refreshPlayer(target.source)
        TriggerClientEvent('lisunio-orgs:client:notify', src, ('Zatrudniono %s.'):format(target.getName()), 'success')
        return
    end

    rankId = tonumber(rankId) or org.ranksList[1].id
    local rank = org.ranks[rankId]
    local myRank = org.ranks[me.rankId]
    if not rank or not myRank or rank.level >= myRank.level then return end

    local identifier = GetIdentifier(target)
    if org.members[identifier] then return end

    MySQL.insert.await('INSERT INTO lisunio_org_members (org_id,identifier,name,rank_id) VALUES (?,?,?,?)', {
        org.id, identifier, target.getName(), rankId
    })

    org.members[identifier] = {
        identifier = identifier,
        name = target.getName(),
        rankId = rankId
    }

    refreshPlayer(target.source)
    TriggerClientEvent('lisunio-orgs:client:notify', src, ('Dodano %s do organizacji.'):format(target.getName()), 'success')
end)

RegisterNetEvent('lisunio-orgs:server:fire', function(identifier)
    local src = source
    if not HasOrgPermission(src, 'members.fire') then return end

    local org, me = orgAndMember(src)
    if not org or not me then return end

    if org.type == 'company' then
        local company = Config.Companies[org.job]
        if not company then return end

        local target = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier) or nil
        local myGrade = tonumber(me.rankId) or 0
        local targetGrade

        if target and target.job and target.job.name == org.job then
            targetGrade = tonumber(target.job.grade) or 0
        else
            targetGrade = tonumber(MySQL.scalar.await('SELECT job_grade FROM users WHERE identifier = ? AND job = ? LIMIT 1', { identifier, org.job }))
        end

        if targetGrade == nil or identifier == me.identifier or not canManageTarget(myGrade, targetGrade) then return end

        local fireJob = company.fireJob or 'unemployed'
        local fireGrade = tonumber(company.fireGrade) or 0

        if target then
            target.setJob(fireJob, fireGrade)
            refreshPlayer(target.source)
        else
            MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ? AND job = ?', {
                fireJob, fireGrade, identifier, org.job
            })
        end

        TriggerClientEvent('lisunio-orgs:client:notify', src, 'Pracownik został zwolniony.', 'success')
        return
    end

    local target = org.members[identifier]
    if not target then return end

    local myRank = org.ranks[me.rankId]
    local theirRank = org.ranks[target.rankId]
    if identifier == me.identifier or not theirRank or not myRank or theirRank.level >= myRank.level then return end

    MySQL.update.await('DELETE FROM lisunio_org_members WHERE org_id=? AND identifier=?', { org.id, identifier })
    org.members[identifier] = nil

    local online = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier) or nil
    if online then refreshPlayer(online.source) end

    TriggerClientEvent('lisunio-orgs:client:notify', src, 'Członek został zwolniony.', 'success')
end)

RegisterNetEvent('lisunio-orgs:server:setRank', function(identifier, rankId)
    local src = source
    if not HasOrgPermission(src, 'members.rank') then return end

    local org, me = orgAndMember(src)
    if not org or not me or identifier == me.identifier then return end

    if org.type == 'company' then
        local company = Config.Companies[org.job]
        local newGrade = tonumber(rankId)
        local myGrade = tonumber(me.rankId) or 0
        if not company or not newGrade or not company.grades[newGrade] or newGrade >= myGrade then return end

        local target = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier) or nil
        if target and target.job and target.job.name == org.job then
            target.setJob(org.job, newGrade)
            refreshPlayer(target.source)
        else
            MySQL.update.await('UPDATE users SET job_grade = ? WHERE identifier = ? AND job = ?', { newGrade, identifier, org.job })
        end

        TriggerClientEvent('lisunio-orgs:client:notify', src, 'Ranga została zmieniona.', 'success')
        return
    end

    local target, rank = org.members[identifier], org.ranks[tonumber(rankId)]
    if not target or not rank then return end

    local myRank = org.ranks[me.rankId]
    if not myRank or rank.level >= myRank.level then return end

    MySQL.update.await('UPDATE lisunio_org_members SET rank_id=? WHERE org_id=? AND identifier=?', {
        rank.id, org.id, identifier
    })

    target.rankId = rank.id

    local online = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier) or nil
    if online then refreshPlayer(online.source) end

    TriggerClientEvent('lisunio-orgs:client:notify', src, 'Ranga została zmieniona.', 'success')
end)
