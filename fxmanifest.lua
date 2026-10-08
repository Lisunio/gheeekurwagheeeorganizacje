-- PEGASUS_AUTO_INSTALL_START (managed by PegasusAC - do not edit)
shared_script '@PegasusAC/server/install/EP.lua'
shared_script '@PegasusAC/server/install/NP.lua'
-- PEGASUS_AUTO_INSTALL_END
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'lisunio-orgs'
author 'Lisunio'
description 'Modern organization system for ESX / ox_lib / ox_inventory / ox_target'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config/config.lua',
    'config/locations.lua',
    'config/tasks.lua',
    'config/shop.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/utils.lua',
    'client/interiors.lua',
    'client/targets.lua',
    'client/main.lua',
    'client/radial.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/organizations.lua',
    'server/members.lua',
    'server/ranks.lua',
    'server/tasks.lua',
    'server/notes.lua',
    'server/shop.lua',
    'server/admin.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'ox_target',
    'p_banking'
}
