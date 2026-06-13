fx_version 'cerulean'
game 'gta5'
lua54 'yes'
version '0.1.0'
author '22scripts, xLaugh'

escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'bridge/client.lua',
    'bridge/server.lua',
    'client/client.lua',
    'server/server.lua',
}

shared_scripts {
    'config.lua',
    'locales/*.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/*.html',
    'html/*.css',
    'html/*.js',
    'html/images/*.webp',
    'html/images/*.png'
}
