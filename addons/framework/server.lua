-- ═══════════════════════════════════════════════════════════════
--  FRAMEWORK BRIDGE (server)
--
--  ที่นี่คือจุดเดียวที่ x3d_carry คุยกับเฟรมเวิร์ก
--  ค่าเริ่มต้น: ACE permission (ใช้ได้ทุกเฟรมเวิร์ก) + ESX ถ้ามี
--  ใช้ QBCore / เฟรมเวิร์กอื่น: ดูตัวอย่างท้ายไฟล์
-- ═══════════════════════════════════════════════════════════════

Framework = {}

local ESX
local function esx()
    if ESX then return ESX end
    if GetResourceState('es_extended') ~= 'started' then return nil end
    ESX = exports.es_extended:getSharedObject()
    return ESX
end

--- ผู้เล่นคนนี้อุ้มคนอื่นได้โดยไม่ต้องขออนุญาตไหม
--- (คนหมดสติถูกอุ้มได้เสมอ ไม่ผ่านฟังก์ชันนี้)
--- @param src number server id
--- @return boolean
function Framework.CanForce(src)
    if Config.ForceAce and IsPlayerAceAllowed(src, Config.ForceAce) then
        return true
    end

    local e = esx()
    if not e then return false end

    local xPlayer = e.GetPlayerFromId(src)
    if not xPlayer then return false end

    if Config.ForceGroups[xPlayer.getGroup()] then return true end

    local job = xPlayer.job and xPlayer.job.name
    return job ~= nil and Config.ForceJobs[job] == true
end

-- ═══════════════════════════════════════════════════════════════
--  QBCore — คัดลอกทับฟังก์ชันด้านบน
-- ═══════════════════════════════════════════════════════════════
-- function Framework.CanForce(src)
--     if Config.ForceAce and IsPlayerAceAllowed(src, Config.ForceAce) then return true end
--     local QBCore = exports['qb-core']:GetCoreObject()
--     local Player = QBCore.Functions.GetPlayer(src)
--     if not Player then return false end
--     if Config.ForceJobs[Player.PlayerData.job.name] then return true end
--     return false
-- end

-- ═══════════════════════════════════════════════════════════════
--  STANDALONE (ACE อย่างเดียว) — คัดลอกทับฟังก์ชันด้านบน
--  server.cfg:  add_ace group.admin x3d_carry.force allow
-- ═══════════════════════════════════════════════════════════════
-- function Framework.CanForce(src)
--     return Config.ForceAce ~= false and IsPlayerAceAllowed(src, Config.ForceAce)
-- end
