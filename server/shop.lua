RegisterNetEvent('lisunio-orgs:server:buy', function(shopId, itemName, amount)
    local src = source
    amount = math.floor(tonumber(amount) or 1)

    if amount < 1 or amount > 50 then return end
    if not HasOrgPermission(src, 'shop.buy') then return end

    local shop = Config.Shop[shopId]
    if not shop then return end

    local selected
    for i = 1, #(shop.items or {}) do
        local item = shop.items[i]
        if item.name == itemName then
            selected = item
            break
        end
    end

    if not selected then return end

    local p = PlayerOrg[src]
    local org = p and OrgCache[p.orgId]
    if not org or not org.bankIban then return end

    local total = selected.price * amount
    local balance = syncOrgBalance and syncOrgBalance(org) or tonumber(exports[Config.BankingResource]:getAccountMoney(org.bankIban)) or 0

    if balance < total then
        return TriggerClientEvent('lisunio-orgs:client:notify', src, ('Brak środków. Saldo organizacji: %s $'):format(balance), 'error')
    end

    local removed = exports[Config.BankingResource]:removeAccountMoney(org.bankIban, total)
    if not removed then
        return TriggerClientEvent('lisunio-orgs:client:notify', src, 'Bank odrzucił płatność.', 'error')
    end

    local delivery = os.date('%Y-%m-%d %H:%M:%S', os.time() + ((shop.deliveryMinutes or 0) * 60))
    local orderId = MySQL.insert.await([[
        INSERT INTO lisunio_org_shop_orders
            (org_id, identifier, item, amount, price, delivery_at)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        org.id,
        p.identifier,
        itemName,
        amount,
        total,
        delivery
    })

    if not orderId then
        exports[Config.BankingResource]:addAccountMoney(org.bankIban, total)
        return TriggerClientEvent('lisunio-orgs:client:notify', src, 'Nie udało się utworzyć zamówienia. Pieniądze zwrócono.', 'error')
    end

    syncOrgBalance(org)

    exports[Config.BankingResource]:createHistory({
        iban = org.bankIban,
        type = 'outcome',
        amount = total,
        title = 'Zakup organizacyjny',
        from = org.name,
        to = ('Sklep organizacji #%s'):format(orderId)
    })

    TriggerClientEvent('lisunio-orgs:client:notify', src, ('Zamówienie #%s przyjęte. Dostawa za %s min.'):format(orderId, shop.deliveryMinutes or 0), 'success')

    TriggerClientEvent('lisunio-orgs:client:requestRefresh', src)
end)

lib.cron.new('*/1 * * * *', function()
    local rows = MySQL.query.await('SELECT * FROM lisunio_org_shop_orders WHERE delivered = 0 AND delivery_at <= NOW()') or {}

    for i = 1, #rows do
        local order = rows[i]
        local org = OrgCache[order.org_id]

        if org then
            local stashId = ('org_%s'):format(org.id)
            local added = exports.ox_inventory:AddItem(stashId, order.item, order.amount)

            if added then
                MySQL.update.await('UPDATE lisunio_org_shop_orders SET delivered = 1 WHERE id = ?', { order.id })
            end
        end
    end
end)
