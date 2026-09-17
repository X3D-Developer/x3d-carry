-- ═══════════════════════════════════════════════════════════════
--  NOTIFY (client)
--
--  ค่าเริ่มต้น: esx_notify ถ้ามี · ox_lib ถ้ามี · ไม่งั้นการ์ดของ x3d_carry เอง
--  ใช้ okokNotify / mythic / ของตัวเอง? เขียนทับฟังก์ชันเดียวนี้
-- ═══════════════════════════════════════════════════════════════

--- @param message string
--- @param kind string 'success' | 'error' | 'warning' | 'info'
function Notify(message, kind)
    kind = kind or 'info'

    if GetResourceState('esx_notify') == 'started' then
        exports['esx_notify']:Notify(kind, 4000, message, L('title'), 'top-right')
        return
    end

    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ title = L('title'), description = message, type = kind })
        return
    end

    -- ── okokNotify ───────────────────────────────────────────
    -- exports['okokNotify']:Alert(L('title'), message, 4000, kind)

    -- ค่าเริ่มต้นสำรอง: การ์ดแจ้งเตือนของ x3d_carry (รองรับภาษาไทย)
    SendNUIMessage({ action = 'toast', data = { message = message, kind = kind, title = L('title') } })
end
