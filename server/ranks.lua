RegisterNetEvent('lisunio-orgs:server:createRank', function(name, level, permissions)
    local src = source
    if not HasOrgPermission(src, 'ranks.manage') then return end
    local p = PlayerOrg[src]; local org = OrgCache[p.orgId]; if not org or org.type == 'company' then return end; local my = org.ranks[p.rankId]
    level, name = tonumber(level), OrgTrim(name)
    if not level or level >= my.level or name == '' or #name > 32 then return end
    permissions = type(permissions) == 'table' and permissions or {}
    local id = MySQL.insert.await('INSERT INTO lisunio_org_ranks (org_id,name,level,permissions) VALUES (?,?,?,?)', { org.id, name, level, json.encode(permissions) })
    local r = { id=id,name=name,level=level,permissions=permissions }; org.ranks[id]=r; org.ranksList[#org.ranksList+1]=r
    table.sort(org.ranksList, function(a,b) return a.level < b.level end)
end)

RegisterNetEvent('lisunio-orgs:server:updateRank', function(rankId, name, level, permissions)
    local src = source
    if not HasOrgPermission(src, 'ranks.manage') then return end
    local p = PlayerOrg[src]; local org = OrgCache[p.orgId]; if not org or org.type == 'company' then return end; local my = org.ranks[p.rankId]; local r = org.ranks[tonumber(rankId)]
    level, name = tonumber(level), OrgTrim(name)
    if not r or r.id == my.id or not level or level >= my.level then return end
    permissions = type(permissions) == 'table' and permissions or {}
    MySQL.update.await('UPDATE lisunio_org_ranks SET name=?,level=?,permissions=? WHERE id=? AND org_id=?', { name,level,json.encode(permissions),r.id,org.id })
    r.name=name; r.level=level; r.permissions=permissions
end)
