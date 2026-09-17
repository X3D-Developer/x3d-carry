-- ═══════════════════════════════════════════════════════════════
--  x3d_carry — ข้อความในเกม
--  เลือกภาษาที่ Config.Locale · เพิ่มภาษาใหม่ได้โดยเพิ่มตารางใหม่
-- ═══════════════════════════════════════════════════════════════

Locales = {}

Locales.th = {
    title        = 'ระบบอุ้ม',
    menu_title   = 'เมนูอุ้ม',
    no_player    = 'ไม่มีผู้เล่นอยู่ในบริเวณ',
    in_vehicle   = 'ใช้ในรถไม่ได้',
    target_veh   = 'เป้าหมายอยู่ในรถ',
    only_dead    = 'ท่านี้ใช้ได้กับผู้หมดสติเท่านั้น',
    only_alive   = 'ท่านี้ใช้กับผู้หมดสติไม่ได้',
    declined     = '%s ปฏิเสธคำขออุ้ม',
    request      = '%s ขออุ้มคุณแบบ %s',
    ask_title    = 'ตกลงที่จะโดนอุ้มไหม ?',
    yes          = 'ตกลง',
    no           = 'ไม่',
    put_down     = 'วางลง',
    struggle     = 'ดิ้นหลุด',
    keybind_menu = 'เปิดเมนูอุ้ม',
    keybind      = 'อุ้มผู้เล่น (%s)',
    hint_move    = 'เลื่อน',
    hint_pick    = 'เลือก',
    hint_back    = 'ปิด',
}

Locales.en = {
    title        = 'Carry',
    menu_title   = 'Carry Menu',
    no_player    = 'No players nearby',
    in_vehicle   = 'Not usable inside a vehicle',
    target_veh   = 'Target is in a vehicle',
    only_dead    = 'This style only works on an unconscious person',
    only_alive   = 'This style cannot be used on an unconscious person',
    declined     = '%s declined your carry request',
    request      = '%s wants to carry you (%s)',
    ask_title    = 'Accept being carried?',
    yes          = 'Yes',
    no           = 'No',
    put_down     = 'Put down',
    struggle     = 'Struggle free',
    keybind_menu = 'Open carry menu',
    keybind      = 'Carry player (%s)',
    hint_move    = 'move',
    hint_pick    = 'select',
    hint_back    = 'close',
}

--- ดึงข้อความตาม Config.Locale (ไม่มีคีย์ในภาษานั้น ใช้ภาษาไทยแทน)
--- @param key string
--- @return string
function L(key)
    local dict = Locales[Config.Locale] or Locales.th
    return dict[key] or Locales.th[key] or key
end

--- ชื่อท่าอุ้มตามภาษาที่เลือก
--- @param styleKey string
--- @return string
function StyleLabel(styleKey)
    local def = Config.Styles[styleKey]
    if not def then return styleKey end
    return def[Config.Locale] or def.th or styleKey
end
