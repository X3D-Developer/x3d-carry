-- ═══════════════════════════════════════════════════════════════
--  FRAMEWORK BRIDGE (client)
--
--  จุดเดียวที่ x3d_carry คุยกับเฟรมเวิร์กฝั่งผู้เล่น
--  ค่าเริ่มต้นทำงานได้เลยแบบ standalone — ESX/QBCore ดูตัวอย่างในไฟล์
-- ═══════════════════════════════════════════════════════════════

Framework = {}

--- ผู้เล่นตายอยู่ไหม
--- ใช้ตัดสินว่าเป็น "ศพ" หรือ "คนเป็น" ทั้งตอนเปิดเมนูและตอนถูกอุ้ม
---
--- ⚠ ต้องเช็กจาก "สถานะของเฟรมเวิร์ก" ไม่ใช่เลือดของร่าง
--- เพราะระหว่างอุ้มศพ ร่างถูกปลุกปลอมให้เลือดเต็ม แต่ยังตายอยู่
--- @return boolean
function Framework.IsDead()
    if GetResourceState('es_extended') == 'started' then
        local ok, dead = pcall(function()
            return exports.es_extended:getSharedObject().PlayerData.dead
        end)
        if ok and dead ~= nil then return dead == true end
    end

    -- ── QBCore ───────────────────────────────────────────────
    -- local Player = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
    -- if Player and Player.metadata then return Player.metadata.isdead == true end

    -- standalone: เชื่อเลือดของร่าง (x3d_carry จะข้ามค่านี้เองระหว่างปลุกปลอม)
    return IsEntityDead(PlayerPedId())
end

--- เรียกตอนร่างของ "เรา" ถูกปลุกปลอมเพื่อให้อุ้มศพได้
---
--- ⚠ กันตายซ้ำ — ใส่คำสั่งดันค่าสถานะที่อาจฆ่าซ้ำไว้ตรงนี้
--- ระบบหิว/กระหาย/เลือดไหล จะไม่ทำงานระหว่างนี้
function Framework.OnCorpseCarried()
    if GetResourceState('esx_status') == 'started' then
        TriggerEvent('esx_status:set', 'hunger', 1000000)
        TriggerEvent('esx_status:set', 'thirst', 1000000)
        TriggerEvent('esx_status:set', 'stress', 0)
    end

    -- ── QBCore (qb-hud / qb-smallresources) ──────────────────
    -- TriggerServerEvent('hud:server:RelieveStress', 100)
    -- TriggerServerEvent('consumables:server:setHunger', 100)
    -- TriggerServerEvent('consumables:server:setThirst', 100)
end

--- เรียกตอนร่างถูกวางลงและกลับไปตายจริง
function Framework.OnCorpseDropped()
end
