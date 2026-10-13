fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mazilkata-playerlist'
author 'Mazilkata Development'
description 'NPV Inspired PlayerList'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua',
    'locales/bg.lua'
}

client_scripts {
    'client/head_ids.lua',
    'client/main.lua'
}

server_scripts {
    'bridge/standalone.lua',
    'bridge/esx.lua',
    'bridge/qb.lua',
    'bridge/qbx.lua',
    'bridge/loader.lua',
    'server/utils.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/*',
    'html/fonts/**'
}
