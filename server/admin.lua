RegisterCommand('orgsetrank', function(src, args)
    if not IsAdmin(src) then return end

    local target = ESX.GetPlayerFromId(tonumber(args[1]))
    local org = OrgCache[tonumber(args[2])]
    local rankId = tonumber(args[3])
    if not target or not org or not rankId then return end

    if org.type == 'company' then
        local company = Config.Companies[org.job]
        if not company or not company.grades[rankId] then return end
        target.setJob(org.job, rankId)
        refreshPlayer(target.source)
        return
    end

    local rank = org.ranks[rankId]
    if not rank then return end

    local identifier = GetIdentifier(target)
    if not org.members[identifier] then return end

    MySQL.update.await('UPDATE lisunio_org_members SET rank_id=? WHERE org_id=? AND identifier=?', {
        rank.id, org.id, identifier
    })

    org.members[identifier].rankId = rank.id
    refreshPlayer(target.source)
end, false)
