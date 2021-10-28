fx_version 'cerulean'
game 'gta5'

description 'A speaker resource by Gacha#4596'

shared_script { 
    'Config.lua',
    '@qb-core/import.lua'--Remove this line if you use ESX
}

client_scripts {
    'Client/Cmain.lua'
}

server_scripts {
    'Server/Smain.lua'
}

ui_page 'Ui/Index.html'

files {
    'Ui/Index.html',
    'Ui/Style.css',
    'Ui/App.js',
    'Ui/bankgothic.ttf'
}