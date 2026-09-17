-- ═══════════════════════════════════════════════════════════════
--  x3d_carry — client
--  ฝั่งนี้แสดงผลอย่างเดียว การตัดสินใจทั้งหมดอยู่ที่ server.lua
-- ═══════════════════════════════════════════════════════════════

local amCarried    = false
local carriedStyle = nil
local carriedForce = false
local fakeAlive    = false

local carryTarget  = nil
local carryStyle   = nil

local menuOpen  = false
local menuKind  = nil
local menuItems = {}
local menuIndex = 1

local function ui(action, data) SendNUIMessage({ action = action, data = data or {} }) end

local function isDeadNow()
    if fakeAlive then return true end
    return Framework.IsDead()
end

local function requestAnim(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local started = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() - started > 5000 then return false end
        Wait(10)
    end
    return true
end

local function sortedStyles()
    local keys = {}
    for key in pairs(Config.Styles) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return Config.Styles[a].order < Config.Styles[b].order end)
    return keys
end

local function styleHint(styleKey)
    local def = Config.Styles[styleKey]
    if not def then return '' end
    if def.key and def.key ~= '' then return def.key end
    return Config.MenuKey ~= '' and Config.MenuKey or ('/' .. def.command)
end

local function setChip(text, key)
    ui('chip', { text = text, key = key })
end

-- ── ศพ: ปลุกปลอมเพื่อให้เล่นอนิเมชันได้ แล้วกันตายซ้ำ ────────────

local function enterFakeAlive()
    if fakeAlive then return end

    local cfg    = Config.Corpse
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local z      = coords.z + cfg.liftOnPickup

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, z, false, false, false, true)
    NetworkResurrectLocalPlayer(coords.x, coords.y, z, GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, cfg.fakeHealth)

    SetEntityInvincible(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    SetEntityCanBeDamaged(ped, false)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
    SetPedCanRagdoll(ped, false)
    ClearPedTasksImmediately(ped)

    fakeAlive = true
    Framework.OnCorpseCarried()
end

local function leaveFakeAlive(killAgain)
    if not fakeAlive then return end
    fakeAlive = false

    local cfg    = Config.Corpse
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    SetPedConfigFlag(ped, 71, false)
    SetPedCanRagdoll(ped, true)
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    SetEntityCanBeDamaged(ped, true)
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)

    if not killAgain then
        Framework.OnCorpseDropped()
        return
    end

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z + cfg.liftOnDrop, false, false, false, true)
    ClearPedTasksImmediately(ped)

    if cfg.ragdollOnDrop then
        SetPedToRagdoll(ped, cfg.ragdollMs, cfg.ragdollMs, 0, false, false, false)
    end

    SetEntityHealth(ped, 0)
    Framework.OnCorpseDropped()
end

-- กันตายซ้ำ: อะไรก็ตามที่มาลดเลือดร่างระหว่างปลุกปลอม โดนเติมคืนทันที
CreateThread(function()
    while true do
        if fakeAlive and Config.Corpse.healthGuard then
            local ped = PlayerPedId()
            if GetEntityHealth(ped) < Config.Corpse.fakeHealth then
                SetEntityHealth(ped, Config.Corpse.fakeHealth)
            end
            Wait(Config.Corpse.guardInterval)
        else
            Wait(500)
        end
    end
end)

-- ── อนิเมชัน ────────────────────────────────────────────────────

local function playCarrier(styleKey)
    local def = Config.Styles[styleKey]
    if not def then return false end
    if not requestAnim(def.carrier.dict) then return false end
    TaskPlayAnim(PlayerPedId(), def.carrier.dict, def.carrier.anim, 8.0, -8.0, -1, def.carrier.flag, 0, false, false, false)
    return true
end

local function playCarried(styleKey, carrierSrc)
    local def = Config.Styles[styleKey]
    if not def then return false end

    local carrierPed = GetPlayerPed(GetPlayerFromServerId(carrierSrc))
    if not carrierPed or carrierPed == 0 then return false end
    if not requestAnim(def.victim.dict) then return false end

    if def.target == 'dead' then enterFakeAlive() end

    local ped = PlayerPedId()
    AttachEntityToEntity(ped, carrierPed, 0, def.offset.x, def.offset.y, def.offset.z,
        0.5, 0.5, def.heading, false, false, false, false, 2, false)
    FreezeEntityPosition(ped, true)
    TaskPlayAnim(ped, def.victim.dict, def.victim.anim, 8.0, -8.0, -1, def.victim.flag, 0, false, false, false)

    if def.target == 'dead' then
        Wait(100)
        SetPedConfigFlag(PlayerPedId(), 71, true)
    end

    return true
end

local function dropCarried(killAgain)
    local ped = PlayerPedId()
    ClearPedSecondaryTask(ped)
    DetachEntity(ped, true, false)
    FreezeEntityPosition(ped, false)

    leaveFakeAlive(killAgain)

    amCarried    = false
    carriedStyle = nil
    carriedForce = false
    setChip(nil)
end

local function dropCarrier()
    carryTarget = nil
    carryStyle  = nil
    ClearPedSecondaryTask(PlayerPedId())
    setChip(nil)
end

-- ── เมนู (ไม่ยึดเมาส์ — คุมด้วยคีย์บอร์ดเหมือน esx_menu_default) ──

local function closeMenu()
    if not menuOpen then return end
    menuOpen  = false
    menuKind  = nil
    menuItems = {}
    ui('menuClose')
end

local function showMenu(kind, title, list, ttl)
    menuOpen  = true
    menuKind  = kind
    menuItems = list
    menuIndex = 1

    local payload = {}
    for i, item in ipairs(list) do
        payload[i] = { label = item.label, active = item.active == true }
    end

    ui('menu', {
        title    = title,
        items    = payload,
        index    = 0,
        ttl      = ttl,
        hintMove = L('hint_move'),
        hintPick = L('hint_pick'),
        hintBack = L('hint_back'),
    })
end

local function activeStyle()
    if carryTarget then return carryStyle end
    if amCarried and not carriedForce then return carriedStyle end
    return nil
end

local function nearbyPlayers()
    local me       = PlayerPedId()
    local myId     = PlayerId()
    local myCoords = GetEntityCoords(me)
    local found    = {}

    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= myId then
            local ped = GetPlayerPed(pid)
            if ped ~= 0 and ped ~= me and DoesEntityExist(ped) then
                local dist = #(GetEntityCoords(ped) - myCoords)
                if dist <= Config.Range then
                    found[#found + 1] = {
                        pid  = pid,
                        ped  = ped,
                        dist = dist,
                        dead = IsPedDeadOrDying(ped, true),
                    }
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.dist < b.dist end)
    return found
end

local function trigger(styleKey)
    local def = Config.Styles[styleKey]
    if not def then return end

    if activeStyle() then
        TriggerServerEvent('x3d_carry:release')
        return
    end

    local me = PlayerPedId()
    if IsPedInAnyVehicle(me, false) then return Notify(L('in_vehicle'), 'error') end

    local near = nearbyPlayers()
    if #near == 0 then return Notify(L('no_player'), 'error') end

    local pick
    for _, entry in ipairs(near) do
        if def.target == 'any'
            or (def.target == 'dead' and entry.dead)
            or (def.target == 'alive' and not entry.dead) then
            pick = entry
            break
        end
    end

    if not pick then
        return Notify(def.target == 'dead' and L('only_dead') or L('only_alive'), 'error')
    end

    if IsPedInAnyVehicle(pick.ped, false) then return Notify(L('target_veh'), 'error') end

    TriggerServerEvent('x3d_carry:request', GetPlayerServerId(pick.pid), styleKey)
end

local function openCarryMenu()
    if menuOpen then return closeMenu() end
    if isDeadNow() then return end

    local me = PlayerPedId()
    if IsPedInAnyVehicle(me, false) then return Notify(L('in_vehicle'), 'error') end

    local running = activeStyle()
    local list    = {}

    if running then
        list[1] = {
            label  = ('%s  —  %s'):format(StyleLabel(running), carryTarget and L('put_down') or L('struggle')),
            active = true,
            style  = running,
        }
    else
        for _, key in ipairs(sortedStyles()) do
            list[#list + 1] = { label = StyleLabel(key), style = key }
        end
    end

    showMenu('carry', L('menu_title'), list)
end

local function selectItem()
    local item = menuItems[menuIndex]
    if not item then return closeMenu() end

    if menuKind == 'ask' then
        closeMenu()
        TriggerServerEvent('x3d_carry:answer', item.value == true)
        return
    end

    closeMenu()
    trigger(item.style)
end

CreateThread(function()
    while true do
        if menuOpen then
            DisableControlAction(0, Config.Keys.up, true)
            DisableControlAction(0, Config.Keys.down, true)
            DisableControlAction(0, Config.Keys.select, true)
            DisableControlAction(0, Config.Keys.back, true)

            if IsDisabledControlJustPressed(0, Config.Keys.up) then
                menuIndex = menuIndex > 1 and menuIndex - 1 or #menuItems
                ui('menuIndex', { index = menuIndex - 1 })
            elseif IsDisabledControlJustPressed(0, Config.Keys.down) then
                menuIndex = menuIndex < #menuItems and menuIndex + 1 or 1
                ui('menuIndex', { index = menuIndex - 1 })
            elseif IsDisabledControlJustPressed(0, Config.Keys.select) then
                selectItem()
            elseif IsDisabledControlJustPressed(0, Config.Keys.back) then
                closeMenu()
            end

            Wait(0)
        else
            Wait(200)
        end
    end
end)

-- ── สถานะกลาง: state bag ของคนที่ถูกอุ้ม ────────────────────────

AddStateBagChangeHandler('x3dCarry', nil, function(bagName, _, value)
    local netId = tonumber(bagName:match('^entity:(%d+)$'))
    if not netId then return end

    local tries = 0
    while not NetworkDoesEntityExistWithNetworkId(netId) and tries < 100 do
        Wait(10)
        tries = tries + 1
    end

    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent == 0 then return end

    local mine = ent == PlayerPedId()

    if value then
        closeMenu()

        if mine then
            for _ = 1, 20 do
                if playCarried(value.style, value.by) then
                    amCarried    = true
                    carriedStyle = value.style
                    carriedForce = value.forced == true
                    if not carriedForce and Config.Styles[value.style].target ~= 'dead' then
                        setChip(L('struggle'), styleHint(value.style))
                    end
                    return
                end
                Wait(100)
            end
        elseif value.by == GetPlayerServerId(PlayerId()) then
            carryTarget = ent
            carryStyle  = value.style
            setChip(L('put_down'), styleHint(value.style))
            Wait(Config.CarrierDelay)
            if carryTarget == ent then playCarrier(value.style) end
        end
        return
    end

    if mine and amCarried then
        dropCarried(true)
    elseif carryTarget == ent then
        dropCarrier()
    end
end)

-- ── คำขออุ้ม ────────────────────────────────────────────────────

RegisterNetEvent('x3d_carry:prompt', function(carrierName, styleKey, ttl)
    if menuOpen or amCarried or carryTarget then return end

    showMenu('ask', L('ask_title'), {
        { label = L('yes'), value = true },
        { label = L('no'),  value = false },
    }, ttl)

    ui('toast', { title = L('title'), kind = 'info',
                  message = L('request'):format(carrierName, StyleLabel(styleKey)) })

    local deadline = GetGameTimer() + ttl
    while menuOpen and menuKind == 'ask' and GetGameTimer() < deadline do
        Wait(200)
    end
    if menuOpen and menuKind == 'ask' then closeMenu() end
end)

RegisterNetEvent('x3d_carry:declined', function(targetName)
    Notify(L('declined'):format(targetName), 'error')
end)

-- ── คำสั่ง + ปุ่มลัด ─────────────────────────────────────────────

-- คำสั่งเดียวทั้ง resource ชื่อขึ้นต้นด้วย x3d เสมอ
-- อย่าใช้ชื่อสั้น ๆ อย่าง 'carry' — ถ้าเซิร์ฟมีสคริปต์อื่นจองชื่อนั้นอยู่
-- FiveM จะทิ้ง RegisterCommand ของเราเงียบ ๆ และปุ่มลัดจะไม่ทำงาน
--   /x3dcarry              เปิดเมนู
--   /x3dcarry piggyback    เรียกท่านั้นตรง ๆ
RegisterCommand(Config.Command, function(_, args)
    local styleKey = args and args[1]
    if styleKey and Config.Styles[styleKey] then
        trigger(styleKey)
    else
        openCarryMenu()
    end
end, false)

if Config.MenuKey ~= '' then
    RegisterKeyMapping(Config.Command, L('keybind_menu'), 'keyboard', Config.MenuKey)
end

for styleKey, def in pairs(Config.Styles) do
    if type(def.key) == 'string' then
        RegisterKeyMapping(Config.Command .. ' ' .. styleKey,
            L('keybind'):format(StyleLabel(styleKey)), 'keyboard', def.key)
    end
end

-- ── ล็อกการควบคุมขณะถูกอุ้ม ─────────────────────────────────────

CreateThread(function()
    while true do
        if amCarried then
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 38, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 74, true)
            DisableControlAction(0, 140, true)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- ── ตัวเทียบสถานะทุก 1 วิ: กันอนิเมชันหลุด และกันค้างตอนเกิดใหม่ ──

CreateThread(function()
    while true do
        Wait(1000)
        local me  = PlayerPedId()
        local bag = Entity(me).state.x3dCarry

        if amCarried then
            if not bag then
                dropCarried(fakeAlive)
            else
                local def = Config.Styles[carriedStyle]
                if def and (not IsEntityAttachedToAnyPed(me)
                    or not IsEntityPlayingAnim(me, def.victim.dict, def.victim.anim, 3)) then
                    requestAnim(def.victim.dict)
                    TaskPlayAnim(me, def.victim.dict, def.victim.anim, 8.0, -8.0, -1, def.victim.flag, 0, false, false, false)
                end
            end
        elseif carryTarget then
            if not DoesEntityExist(carryTarget) then
                dropCarrier()
            else
                local def = Config.Styles[carryStyle]
                if def and not IsEntityPlayingAnim(me, def.carrier.dict, def.carrier.anim, 3) then
                    playCarrier(carryStyle)
                end
            end
        end
    end
end)

-- เกิดใหม่แล้วต้องไม่มีอะไรค้าง (ร่างเปลี่ยน ped state bag เดิมตามไม่ทัน)
AddEventHandler('playerSpawned', function()
    closeMenu()
    if amCarried then dropCarried(false) end
    if fakeAlive then leaveFakeAlive(false) end
    if carryTarget then dropCarrier() end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    DetachEntity(ped, true, false)
    FreezeEntityPosition(ped, false)
    ClearPedSecondaryTask(ped)
    if fakeAlive then leaveFakeAlive(true) end
    ui('reset')
end)

exports('IsCarried', function() return amCarried end)
exports('IsCarrying', function() return carryTarget ~= nil end)
exports('IsFakeAlive', function() return fakeAlive end)
