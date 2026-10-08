RegisterNetEvent('lisunio-orgs:server:addNote', function(title, content, private)
    local src = source
    local p = PlayerOrg[src]
    if not p or not HasOrgPermission(src, 'notes.write') then return end

    title = OrgTrim(tostring(title or '')):sub(1, 100)
    content = tostring(content or '')
    private = private == true

    if title == '' or content == '' or #content > Config.MaxNotesLength then
        return TriggerClientEvent('lisunio-orgs:client:notify', src, 'Nieprawidłowa notatka.', 'error')
    end

    if not private and not HasOrgPermission(src, 'notes.org') then
        return TriggerClientEvent('lisunio-orgs:client:notify', src, 'Nie masz dostępu do notatek organizacji.', 'error')
    end

    MySQL.insert.await([[
        INSERT INTO lisunio_org_notes (org_id, identifier, private, title, content)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        p.orgId,
        p.identifier,
        private and 1 or 0,
        title,
        content
    })

    TriggerClientEvent('lisunio-orgs:client:notify', src, 'Notatka została zapisana.', 'success')
    TriggerClientEvent('lisunio-orgs:client:requestRefresh', src)
end)

RegisterNetEvent('lisunio-orgs:server:deleteNote', function(id)
    local src = source
    local p = PlayerOrg[src]
    if not p or not HasOrgPermission(src, 'notes.view') then return end

    id = tonumber(id)
    if not id then return end

    local note = MySQL.single.await('SELECT * FROM lisunio_org_notes WHERE id = ? AND org_id = ?', { id, p.orgId })
    if not note then return end

    local allowed = note.private == 1 and note.identifier == p.identifier or HasOrgPermission(src, 'notes.manage')
    if not allowed then
        return TriggerClientEvent('lisunio-orgs:client:notify', src, 'Nie możesz usunąć tej notatki.', 'error')
    end

    MySQL.update.await('DELETE FROM lisunio_org_notes WHERE id = ?', { id })
    TriggerClientEvent('lisunio-orgs:client:requestRefresh', src)
end)
