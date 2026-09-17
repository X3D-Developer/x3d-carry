-- ═══════════════════════════════════════════════════════════════
--  x3d_carry — server
--  เซิร์ฟเวอร์เป็นเจ้าของคู่อุ้มทั้งหมด client สั่งอะไรไม่ได้นอกจากขอ
-- ═══════════════════════════════════════════════════════════════

local Carry   = {}
local Carried = {}
local Pending = {}
local NextAsk = {}

local function pedOf(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return ped
end

local function online(src)
    return GetPlayerName(src) ~= nil
end

local function busy(src)
    return Carry[src] ~= nil or Carried[src] ~= nil
end

local function pairOk(a, b, range)
    local pa, pb = pedOf(a), pedOf(b)
    if not pa or not pb then return false end
    if GetVehiclePedIsIn(pa, false) ~= 0 or GetVehiclePedIsIn(pb, false) ~= 0 then return false end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb)) <= range
end

local function stop(carrier)
    local c = Carry[carrier]
    if not c then return end
    Carry[carrier]    = nil
    Carried[c.target] = nil
    local ped = pedOf(c.target)
    if ped then Entity(ped).state:set('x3dCarry', nil, true) end
end

local function begin(carrier, target, style, forced)
    local ped = pedOf(target)
    if not ped then return end
    Carry[carrier]  = { target = target, style = style, forced = forced }
    Carried[target] = carrier
    Entity(ped).state:set('x3dCarry', { by = carrier, style = style, forced = forced }, true)
end

RegisterNetEvent('x3d_carry:request', function(targetSrc, style)
    local src = source
    targetSrc = tonumber(targetSrc)

    if not targetSrc or targetSrc == src then return end
    if type(style) ~= 'string' then return end

    local def = Config.Styles[style]
    if not def then return end

    local now = GetGameTimer()
    if (NextAsk[src] or 0) > now then return end
    NextAsk[src] = now + Config.Cooldown

    if not online(src) or not online(targetSrc) then return end
    if busy(src) or busy(targetSrc) then return end

    local waiting = Pending[targetSrc]
    if waiting and waiting.expires > now then return end

    if not pairOk(src, targetSrc, Config.Range + 0.5) then return end

    local targetPed = pedOf(targetSrc)
    if not targetPed then return end

    local dead = GetEntityHealth(targetPed) <= 0
    if def.target == 'dead' and not dead then return end
    if def.target == 'alive' and dead then return end

    if dead or Framework.CanForce(src) then
        begin(src, targetSrc, style, true)
    else
        Pending[targetSrc] = { carrier = src, style = style, expires = now + Config.RequestTTL }
        TriggerClientEvent('x3d_carry:prompt', targetSrc, GetPlayerName(src), style, Config.RequestTTL)
    end
end)

RegisterNetEvent('x3d_carry:answer', function(accepted)
    local src = source
    local req = Pending[src]
    Pending[src] = nil

    if not req then return end
    if GetGameTimer() > req.expires then return end

    if accepted ~= true then
        if online(req.carrier) then
            TriggerClientEvent('x3d_carry:declined', req.carrier, GetPlayerName(src))
        end
        return
    end

    if busy(src) or busy(req.carrier) then return end
    if not pairOk(req.carrier, src, Config.Range + 0.5) then return end

    begin(req.carrier, src, req.style, false)
end)

RegisterNetEvent('x3d_carry:release', function()
    local src = source
    if Carry[src] then return stop(src) end

    local carrier = Carried[src]
    if carrier and Carry[carrier] and not Carry[carrier].forced then stop(carrier) end
end)

local function cleanup(src)
    stop(src)

    local carrier = Carried[src]
    if carrier then stop(carrier) end

    Pending[src] = nil
    NextAsk[src] = nil

    for target, req in pairs(Pending) do
        if req.carrier == src then Pending[target] = nil end
    end
end

AddEventHandler('playerDropped', function()
    cleanup(source)
end)

CreateThread(function()
    while true do
        Wait(2000)
        for carrier, c in pairs(Carry) do
            local pc, pt = pedOf(carrier), pedOf(c.target)
            if not pc or not pt then
                stop(carrier)
            elseif GetEntityHealth(pc) <= 0 then
                stop(carrier)
            elseif GetEntityHealth(pt) <= 0 and Config.Styles[c.style].target == 'alive' then
                stop(carrier)
            elseif GetVehiclePedIsIn(pc, false) ~= 0 or GetVehiclePedIsIn(pt, false) ~= 0 then
                stop(carrier)
            elseif #(GetEntityCoords(pc) - GetEntityCoords(pt)) > Config.MaxDist then
                stop(carrier)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for carrier in pairs(Carry) do stop(carrier) end
end)

exports('IsCarrying', function(src) return Carry[src] ~= nil end)
exports('IsCarried', function(src) return Carried[src] ~= nil end)
exports('StopCarry', function(src)
    if Carry[src] then stop(src) return true end
    local carrier = Carried[src]
    if carrier then stop(carrier) return true end
    return false
end)
