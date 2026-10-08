local function countPolice()
    local players = ESX.GetExtendedPlayers and ESX.GetExtendedPlayers('job', Config.PoliceJob or 'police') or GetPlayers()
    if type(players) == 'table' then
        return #players
    end
    return 0
end

local function getRankLevel(org, member)
    if org.type == 'company' then
        return tonumber(member.rankId) or 0
    end

    local rank = org.ranks[member.rankId]
    return rank and tonumber(rank.level) or 0
end

RegisterNetEvent('lisunio-orgs:server:startTask', function(taskId)
    local src = source
    if not HasOrgPermission(src, 'tasks.start') then return end
    if ActiveTasks[src] then return end

    local p = PlayerOrg[src]
    local org = p and OrgCache[p.orgId]
    local task = Config.Tasks[taskId]
    if not org or not p or not task then return end

    local req = task.requirements or {}
    local rankLevel = getRankLevel(org, p)
    if req.minRank and rankLevel < req.minRank then
        TriggerClientEvent('lisunio-orgs:client:notify', src, 'Masz za niską rangę do tego zadania.', 'error')
        return
    end

    if req.minPolice and countPolice() < req.minPolice then
        TriggerClientEvent('lisunio-orgs:client:notify', src, ('Wymaganych jest co najmniej %s policjantów.'):format(req.minPolice), 'error')
        return
    end

    if req.custom and req.custom(src, org) ~= true then return end

    local last = org.taskCooldowns and org.taskCooldowns[taskId] or 0
    if os.time() < last then
        TriggerClientEvent('lisunio-orgs:client:notify', src, 'To zadanie jest jeszcze na cooldownie.', 'error')
        return
    end

    org.taskCooldowns = org.taskCooldowns or {}
    org.taskCooldowns[taskId] = os.time() + (task.cooldown or 0)

    local state = task.start and task.start(src, org) or {}
    ActiveTasks[src] = {
        id = taskId,
        orgId = org.id,
        state = state
    }

    TriggerClientEvent('lisunio-orgs:client:taskStarted', src, taskId, state)
end)

RegisterNetEvent('lisunio-orgs:server:finishTask', function()
    local src = source
    local active = ActiveTasks[src]
    if not active then return end

    local p = PlayerOrg[src]
    local org = p and OrgCache[p.orgId]
    local task = Config.Tasks[active.id]
    if not org or not p or active.orgId ~= org.id or not task then
        ActiveTasks[src] = nil
        return
    end

    if not task.check or task.check(src, org, active.state) ~= true then
        TriggerClientEvent('lisunio-orgs:client:notify', src, 'Warunki zadania nie zostały spełnione.', 'error')
        return
    end

    local reward = task.reward and task.reward(src, org, active.state) or {}
    local x = ESX.GetPlayerFromId(src)
    if not x then return end

    if reward.money and tonumber(reward.money) and tonumber(reward.money) > 0 then
        x.addAccountMoney(Config.CurrencyAccount, tonumber(reward.money), 'lisunio-orgs task reward')
    end

    for i = 1, #(reward.items or {}) do
        local item = reward.items[i]
        exports.ox_inventory:AddItem(src, item.name, item.count, item.metadata)
    end

    ActiveTasks[src] = nil
    TriggerClientEvent('lisunio-orgs:client:taskFinished', src, reward)
end)
