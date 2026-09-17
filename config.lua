-- ═══════════════════════════════════════════════════════════════
--  x3d_carry — ตั้งค่า
--  X3D-Developer · https://x3d-developer.com
-- ═══════════════════════════════════════════════════════════════

Config = {}

-- ภาษาของข้อความในเกม: 'th' หรือ 'en' (แก้ข้อความเองได้ที่ locales.lua)
Config.Locale = 'th'

-- ชื่อคำสั่งของ resource นี้ — มีคำสั่งเดียว
--   /x3dcarry              เปิดเมนู
--   /x3dcarry piggyback    เรียกท่านั้นตรง ๆ (ชื่อท่าดูที่ Config.Styles)
--
-- ⚠ อย่าตั้งเป็นชื่อสั้น ๆ อย่าง 'carry' — ถ้าเซิร์ฟมีสคริปต์อื่นจองชื่อนั้นอยู่
-- FiveM จะทิ้งคำสั่งของเราเงียบ ๆ ปุ่มลัดจะไม่ทำงาน และไม่มี error ให้เห็น
Config.Command = 'x3dcarry'

-- ปุ่มเปิดเมนูอุ้ม ('' = ไม่ผูกปุ่ม ใช้ /x3dcarry แทน)
Config.MenuKey = 'F9'

-- ระยะที่กดอุ้มได้ (เมตร)
Config.Range = 3.0

-- ระยะที่ห่างกันได้ขณะอุ้มอยู่ เกินกว่านี้เซิร์ฟเวอร์ปล่อยให้เอง
Config.MaxDist = 4.5

-- คำขออุ้มค้างอยู่ได้กี่มิลลิวินาทีก่อนหมดอายุ
Config.RequestTTL = 15000

-- กันกดรัว: ผู้เล่นหนึ่งคนขออุ้มได้ทุกกี่มิลลิวินาที
Config.Cooldown = 2000

-- ═══════════════════════════════════════════════════════════════
--  สิทธิ์อุ้มโดยไม่ต้องขอ (ผู้ถูกอุ้มดิ้นหลุดไม่ได้)
--  ศพถูกอุ้มได้เสมอ ไม่ต้องมีสิทธิ์
-- ═══════════════════════════════════════════════════════════════

-- ACE permission — ใช้ได้ทุกเฟรมเวิร์ก ใส่ใน server.cfg:
--   add_ace group.admin x3d_carry.force allow
-- ตั้งเป็น false ถ้าไม่ใช้
Config.ForceAce = 'x3d_carry.force'

-- กลุ่มแอดมิน (ESX / QBCore — ดู addons/framework/server.lua)
Config.ForceGroups = {
    admin      = true,
    superadmin = true,
    mod        = true,
}

-- อาชีพที่อุ้มได้โดยไม่ต้องขอ (ESX / QBCore — ดู addons/framework/server.lua)
Config.ForceJobs = {
    police    = true,
    ambulance = true,
}

-- ═══════════════════════════════════════════════════════════════
--  อุ้มศพ — กันตายซ้ำ
--
--  เกมเล่นอนิเมชันกับศพไม่ได้ ต้อง "ปลุกปลอม" ด้วย
--  NetworkResurrectLocalPlayer ก่อน แล้วค่อยเล่นท่าศพทับ
--  ช่วงที่ร่างยังไม่ตายจริงนี่แหละที่ระบบอื่นอาจฆ้าซ้ำได้
-- ═══════════════════════════════════════════════════════════════
Config.Corpse = {
    -- เลือดที่ตั้งให้ร่างระหว่างถูกอุ้ม (ต้อง > 0 ไม่งั้นเกมถือว่าตาย)
    fakeHealth = 120,

    -- ⚠ กันตายซ้ำ — อย่าปิด ถ้าเซิร์ฟมีระบบหิว/กระหาย/เลือดไหล
    --
    -- invincible/proofs กันความเสียหายได้ แต่กัน SetEntityHealth(ped, 0)
    -- ที่สคริปต์อื่นสั่งตรง ๆ ไม่ได้ ตัวนี้เลยคอยเติมเลือดคืนทุก ๆ กี่ ms
    -- ถ้ามีอะไรมาลดเลือดร่างระหว่างถูกอุ้ม
    healthGuard    = true,
    guardInterval  = 200,

    -- ยกร่างขึ้นกี่เมตรก่อนปลุกปลอม (กันร่างจมพื้น)
    liftOnPickup = 0.4,

    -- ยกร่างขึ้นกี่เมตรตอนวางลง ให้มีที่ว่างให้ล้มลงพื้น
    liftOnDrop = 0.7,

    -- บังคับให้ร่างล้มลงพื้นตอนวาง (ไม่งั้นศพยืนแข็งทื่อ)
    ragdollOnDrop = true,
    ragdollMs     = 5000,
}

-- ═══════════════════════════════════════════════════════════════
--  ท่าอุ้ม — เพิ่มท่าใหม่ได้ ระบบสร้างเมนู + คำสั่งให้เองทุกท่า
--
--    order    ลำดับในเมนู
--    key      ปุ่มเริ่มต้นของท่านั้น ('' = ไม่ผูก ผู้เล่นตั้งเองได้
--             ใน ตั้งค่า FiveM > Key Bindings > FiveM)
--             ชื่อคีย์ของท่า = ชื่อ key ในตารางนี้ เช่น /x3dcarry piggyback
--    target   ใช้กับใครได้ — 'dead' ศพเท่านั้น · 'alive' คนเป็นเท่านั้น · 'any' ได้หมด
--    offset   ตำแหน่งคนถูกอุ้มเทียบกับคนอุ้ม
--    carrier  อนิเมชันของคนอุ้ม
--    victim   อนิเมชันของคนถูกอุ้ม
-- ═══════════════════════════════════════════════════════════════
Config.Styles = {
    dragdeath = {
        order   = 1,
        key     = '',
        th      = 'อุ้มศพ',
        en      = 'Carry Corpse',
        target  = 'dead',
        offset  = vector3(0.27, 0.15, 0.63),
        heading = 0.0,
        carrier = { dict = 'missfinale_c2mcs_1', anim = 'fin_c2_mcs_1_camman',   flag = 49 },
        victim  = { dict = 'missarmenian2',      anim = 'corpse_search_exit_ped', flag = 47 },
    },
    carrypeople = {
        order   = 2,
        key     = '',
        th      = 'อุ้มพาดบ่า',
        en      = 'Carry People',
        target  = 'alive',
        offset  = vector3(0.27, 0.15, 0.63),
        heading = 0.0,
        carrier = { dict = 'missfinale_c2mcs_1', anim = 'fin_c2_mcs_1_camman', flag = 49 },
        victim  = { dict = 'nm',                 anim = 'firemans_carry',      flag = 33 },
    },
    piggyback = {
        order   = 3,
        key     = '',
        th      = 'ขี่หลัง',
        en      = 'Piggy Back',
        target  = 'alive',
        offset  = vector3(0.0, -0.07, 0.45),
        heading = 0.0,
        carrier = { dict = 'anim@arena@celeb@flat@paired@no_props@', anim = 'piggyback_c_player_a', flag = 49 },
        victim  = { dict = 'anim@arena@celeb@flat@paired@no_props@', anim = 'piggyback_c_player_b', flag = 33 },
    },
}

-- คนอุ้มหน่วงกี่ ms ก่อนเริ่มท่า ให้ร่างคนถูกอุ้มติดเข้าที่ก่อน
-- ต่ำกว่านี้ท่าคู่จะเหลื่อมกัน (ขี่หลังลอย / พาดบ่าหลุด)
Config.CarrierDelay = 500

-- ═══════════════════════════════════════════════════════════════
--  ปุ่มในเมนู (control id ของ FiveM)
--  ชุดเดียวกับ esx_menu_default — ลูกศรขึ้น/ลง, Enter, Backspace
-- ═══════════════════════════════════════════════════════════════
Config.Keys = {
    up     = 172,
    down   = 173,
    select = 176,
    back   = 177,
}
