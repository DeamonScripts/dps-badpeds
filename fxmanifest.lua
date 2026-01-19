fx_version 'cerulean'
game       'gta5'
lua54      'yes'
author     'AlexCarton'
description 'Police NPC Interaction System with Intel Trading and Jail System'
version    '2.0.0'

-- Dependencies
-- Required: qb-core, qb-menu, qb-target or ox_target
-- Optional: oxmysql (for jail system), dps-ainpcs (for AI dialogue)
-- Run sql/jail_records.sql if using the jail system

shared_scripts {
    'shared/characters.lua', -- Shared character pool (can be used by dps-ainpcs)
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Optional: only needed if jail system enabled
    'server.lua'
}

client_scripts {
    'client.lua'
}

files {
    'stream/idcard.ytd'
}

dependencies {
    'qb-core',
    'qb-menu'
}


