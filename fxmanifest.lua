-- ██╗  ██╗██████╗ ██████╗     ██████╗ ███████╗██╗   ██╗
-- ╚██╗██╔╝╚════██╗██╔══██╗    ██╔══██╗██╔════╝██║   ██║
--  ╚███╔╝  █████╔╝██║  ██║    ██║  ██║█████╗  ██║   ██║
--  ██╔██╗  ╚═══██╗██║  ██║    ██║  ██║██╔══╝  ╚██╗ ██╔╝
-- ██╔╝ ██╗██████╔╝██████╔╝    ██████╔╝███████╗ ╚████╔╝
-- ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═════╝ ╚══════╝  ╚═══╝
--
--  X3D-Developer  ·  https://x3d-developer.com  ·  ฟรี ใช้ได้ทุกเซิร์ฟเวอร์

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'x3d_carry'
version '1.0.0'
author 'X3D-Developer'
description 'ระบบอุ้มผู้เล่น — ขออนุญาตก่อนอุ้ม, เซิร์ฟเวอร์คุมทั้งหมด, ไม่ต้องพึ่งเฟรมเวิร์ก'

ui_page 'web/build/index.html'

shared_scripts {
    'config.lua',
    'locales.lua',
}

client_scripts {
    'addons/framework/client.lua',
    'addons/notify/client.lua',
    'client.lua',
}

server_scripts {
    'addons/framework/server.lua',
    'server.lua',
}

files {
    'web/build/index.html',
    'web/build/**/*',
}
