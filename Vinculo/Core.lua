local ADDON, ns = ...
local L = ns.L

local SPELL_FEED_PET = 6991
local SPELL_REVIVE_PET = 982
local SPELL_TAME_BEAST = 1515
local SPELL_DISMISS_PET = 2641
local MAX_TIMELINE = 300
local TICK = 15

local DEFAULT_OPTIONS = {
    toasts = true,      -- avisar al conseguir logros
    chatOnly = false,   -- avisos solo en el chat, sin ventana
    sound = true,
    weekly = true,      -- resumen semanal al entrar
    anniv = true,       -- recordar aniversarios
    personality = true,
    talk = true,        -- la mascota comenta cosas en tu chat (solo lo ves tú)
    minimap = true,     -- botón en el minimapa
    noanim = false,     -- sin animaciones (más ligero)
    beastAlert = true,  -- avisar al ver una bestia de tu lista de deseos
    beastTip = true,    -- datos de la bestia en su tooltip
}
local PREY_MILESTONES = { [10] = true, [25] = true, [50] = true, [100] = true, [250] = true, [500] = true, [1000] = true }

-- En Forever algunas APIs devuelven "valores secretos" en combate: no se pueden
-- comparar ni guardar. safe() devuelve nil en vez de un valor secreto o un error.
local function isSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) or false
end

local function pack(...)
    return { n = select("#", ...), ... }
end

local function safe(fn, ...)
    if not fn then return end
    local r = pack(pcall(fn, ...))
    if not r[1] then return end
    for i = 2, r.n do
        if isSecret(r[i]) then return end
    end
    return unpack(r, 2, r.n)
end
ns.safe = safe

local db, charDB
local isHunter = false
local inCombat = false
local combat -- estado del combate en curso
local lastTick
local lastTameCast = 0
local dismissedAt = 0

ns.activeKey = nil -- mascota invocada ahora mismo
ns.lastKey = nil   -- última mascota que estuvo contigo (para Revivir mascota)

------------------------------------------------------------------------
-- Utilidades
------------------------------------------------------------------------

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff9acd32" .. L.TITLE .. "|r: " .. msg)
end

function ns.FormatTime(sec)
    sec = math.floor(sec or 0)
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    if d > 0 then return L.TIME_DH:format(d, h) end
    if h > 0 then return L.TIME_HM:format(h, m) end
    return L.TIME_M:format(m)
end

local function currentZone()
    return safe(GetRealZoneText) or safe(GetZoneText) or "?"
end

local function petExists()
    return safe(UnitExists, "pet") and true or false
end

-- El GUID de una mascota de cazador se mantiene entre invocaciones y sesiones.
local function readPetKey()
    if not petExists() then return end
    return safe(UnitGUID, "pet")
end

-- Forever declara C_PetInfo.GetPetLoyalty (devuelve el nombre); la global queda de respaldo.
local function readLoyalty()
    local text = safe((C_PetInfo and C_PetInfo.GetPetLoyalty) or GetPetLoyalty)
    if type(text) ~= "string" then return end
    return tonumber(text:match("(%d+)")), text
end

-- 1 triste, 2 normal, 3 contenta. Forever solo da el estado, no el número exacto.
local function readHappiness()
    -- La global es la de Classic Era (versión de prueba).
    local h = safe((C_PetInfo and C_PetInfo.GetPetHappiness) or GetPetHappiness)
    if type(h) == "number" and h >= 1 and h <= 3 then return h end
end

local function readTraining()
    local total, used = safe((C_PetInfo and C_PetInfo.GetPetTrainingPoints) or GetPetTrainingPoints)
    if type(total) == "number" and type(used) == "number" then return total - used, total end
end

-- Lo que tienes seleccionado en combate. El registro de combate está restringido
-- para addons en Forever, así que el objetivo es la mejor pista de a quién cazáis.
local function readPrey()
    if not safe(UnitExists, "target") or safe(UnitIsPlayer, "target") then return end
    if not safe(UnitCanAttack, "player", "target") then return end
    local name = safe(UnitName, "target")
    if type(name) ~= "string" or name == "" then return end
    local kind = safe(UnitCreatureType, "target")
    local family = safe(UnitCreatureFamily, "target")
    return name, type(kind) == "string" and kind or nil, type(family) == "string" and family or nil
end

local function count(pet, field, name)
    pet[field] = pet[field] or {}
    pet[field][name] = (pet[field][name] or 0) + 1
    return pet[field][name]
end

function ns:Talk(...)
    if ns.Say then ns:Say(...) end
end

function ns:Changed()
    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
end

------------------------------------------------------------------------
-- Datos
------------------------------------------------------------------------

local function newPet(key, name, family, level)
    return {
        key = key,
        name = name,
        family = family,
        level = level or 1,
        created = time(),
        metZone = currentZone(),
        note = "",
        stats = {
            victories = 0, bosses = 0, falls = 0, revives = 0, feeds = 0,
            timeTogether = 0, timeCombat = 0, streak = 0, bestStreak = 0, timeHappy = 0,
        },
        zones = {}, zoneCount = 0,
        dungeons = {}, dungeonCount = 0,
        bossKills = {},
        achievements = {},
        timeline = {},
    }
end

function ns:GetPets()
    return charDB.pets, charDB.order
end

function ns:AddPet(key, name, family, level)
    local pet = newPet(key, name, family, level)
    charDB.pets[key] = pet
    table.insert(charDB.order, key)
    return pet
end

-- Busca una ficha no retirada con ese nombre y familia (para unir la del establo con la invocada).
function ns:FindPetByName(name, family, skipKey)
    if not name then return end
    for key, pet in pairs(charDB.pets) do
        -- La familia se compara por su clave, no por el texto: si cambias el idioma del cliente ("Lobo" / "Wolf"),
        -- seguiría siendo la misma mascota.
        if key ~= skipKey and not pet.retired and pet.name == name
            and (not family or not pet.family or pet.family == family or ns:FamilyKey(pet.family) == ns:FamilyKey(family)) then
            return pet
        end
    end
end

-- Cambia la clave de una ficha sin perder su sitio en la lista.
local function rekey(pet, key)
    charDB.pets[pet.key] = nil
    for i, k in ipairs(charDB.order) do
        if k == pet.key then charDB.order[i] = key break end
    end
    if charDB.lastKey == pet.key then charDB.lastKey = key end
    pet.key = key
    charDB.pets[key] = pet
end

function ns:GetPet(key)
    return key and charDB.pets[key]
end

function ns:Log(pet, event, ...)
    local tl = pet.timeline
    tl[#tl + 1] = { t = time(), e = event, a = { ... } }
    -- Conserva siempre la primera entrada (el día que os conocisteis).
    while #tl > MAX_TIMELINE do table.remove(tl, 2) end
end

function ns:FormatEvent(entry)
    local fmt = L[entry.e] or entry.e
    -- Sin zona conocida, la frase no puede acabar en "en .".
    if entry.e == "EV_FIRST_SEEN" and not (entry.a and entry.a[2] and entry.a[2] ~= "") then fmt = L.EV_FIRST_SEEN_NOZONE end
    local ok, text = pcall(string.format, fmt, unpack(entry.a or {}))
    return ok and text or fmt
end

function ns:SetRetired(pet, retired)
    pet.retired = retired or nil
    self:Log(pet, retired and "EV_RETIRED" or "EV_UNRETIRED", pet.name)
    self:Changed()
end

function ns:DeletePet(pet)
    charDB.pets[pet.key] = nil
    for i, k in ipairs(charDB.order) do
        if k == pet.key then table.remove(charDB.order, i) break end
    end
    if ns.activeKey == pet.key then ns.activeKey = nil end
    if ns.lastKey == pet.key then ns.lastKey = nil end
    self:Changed()
end

------------------------------------------------------------------------
-- Seguimiento
------------------------------------------------------------------------

-- Nombre del continente del mapa actual, subiendo por los mapas padre (nil si no se sabe).
local function currentContinent()
    local id = C_Map and safe(C_Map.GetBestMapForUnit, "player")
    local continentType = (Enum and Enum.UIMapType and Enum.UIMapType.Continent) or 2
    for _ = 1, 8 do
        if type(id) ~= "number" or id <= 0 then return end
        local info = safe(C_Map.GetMapInfo, id)
        if type(info) ~= "table" then return end
        if info.mapType == continentType and type(info.name) == "string" then return info.name, id end
        id = info.parentMapID
    end
end

local function visitZone(pet)
    local zone = currentZone()
    if not zone or zone == "?" or zone == "" then return end
    local inInstance, kind = safe(IsInInstance)
    if inInstance and (kind == "party" or kind == "raid") then
        local name = safe(GetInstanceInfo) or zone
        if not pet.dungeons[name] then
            pet.dungeons[name] = time()
            pet.dungeonCount = pet.dungeonCount + 1
            ns:Log(pet, "EV_DUNGEON", name)
        end
    elseif not inInstance then
        -- Se apunta en cada visita: así las zonas anteriores a esta versión se rellenan al pisarlas.
        local continent, continentID = currentContinent()
        if continent then
            pet.zoneContinent = pet.zoneContinent or {}
            pet.zoneContinent[zone] = continent
            -- El id no cambia con el idioma: sirve para agrupar sin duplicar continentes
            pet.zoneContinentID = pet.zoneContinentID or {}
            pet.zoneContinentID[zone] = continentID
        end
        if not pet.zones[zone] then
            pet.zones[zone] = time()
            pet.zoneCount = pet.zoneCount + 1
            ns:Log(pet, "EV_ZONE", zone)
            ns:Talk(pet, "zone", zone)
        end
    end
end

local function recordFall(pet)
    if pet.pendingFall then return end
    pet.pendingFall = true
    pet.stats.falls = pet.stats.falls + 1
    pet.stats.streak = 0
    if combat and combat.prey then count(pet, "nemesis", combat.prey) end
    ns:Log(pet, "EV_FALL", pet.name, currentZone())
end

-- Lee la mascota actual y actualiza su ficha. Fuera de combate es fiable;
-- en combate muchas lecturas vuelven vacías y simplemente no se tocan.
-- Guarda el displayID de la mascota invocada (con un modelo fuera de pantalla) para que el retrato 2D la muestre aunque no lo esté.
local capModel
local function captureModel(pet)
    if not capModel then
        local ok, m = pcall(CreateFrame, "PlayerModel", nil, UIParent)
        if not ok or not m then return end
        m:SetSize(1, 1)
        m:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 10, -10) -- fuera de la pantalla
        capModel = m
    end
    if not pcall(capModel.SetUnit, capModel, "pet") then return end
    C_Timer.After(1, function()
        local ok, id = pcall(capModel.GetDisplayInfo, capModel)
        if ok and type(id) == "number" and id > 0 and id ~= pet.displayID then
            pet.displayID = id
            ns:Changed()
        end
    end)
end

function ns:RefreshPet()
    if not isHunter then return end
    local key = readPetKey()
    if not key then
        if not petExists() then ns.activeKey = nil end
        self:Changed()
        return
    end

    local name = safe(UnitName, "pet")
    local family = safe(UnitCreatureFamily, "pet")
    local level = safe(UnitLevel, "pet")
    local loyalty, loyaltyText = readLoyalty()

    local pet, greet = charDB.pets[key], nil
    if not pet then
        -- El GUID de la mascota cambia al invocarla o al reconectar: se reutiliza la ficha
        -- (del establo o de antes) con el mismo nombre y familia, mejor la última usada.
        local known = self:GetPet(charDB.lastKey)
        if not (known and not known.retired and known.name == name
            and (not family or not known.family or known.family == family or self:FamilyKey(known.family) == self:FamilyKey(family))) then
            known = self:FindPetByName(name, family)
        end
        if known then
            rekey(known, key)
            pet = known
        end
    end
    if not pet then
        if not name then return end -- sin nombre todavía; se reintenta luego
        pet = self:AddPet(key, name, family, level)
        pet.loyalty = loyalty
        local justTamed = (GetTime() - lastTameCast) < 120 or loyalty == 1
        pet.tamed = justTamed or nil
        self:Log(pet, justTamed and "EV_TAMED" or "EV_FIRST_SEEN", name, pet.metZone)
        if justTamed then self:CompleteWish(pet) end
        greet = justTamed and "tamed" or "hello"
    else
        if name and name ~= pet.name then
            self:Log(pet, "EV_RENAMED", name, pet.name)
            pet.name = name
        end
        if family then pet.family = family end
        if level and level > (pet.level or 0) then
            pet.level = level
            self:Log(pet, "EV_LEVEL", pet.name, level)
            self:Talk(pet, "level", level)
        end
        -- Puede llegar solo el nombre, sin número: se apunta cualquier cambio de texto.
        if loyaltyText and pet.loyaltyText and loyaltyText ~= pet.loyaltyText then
            self:Log(pet, "EV_LOYALTY", loyaltyText)
        end
        if loyalty then pet.loyalty = loyalty end
    end
    pet.loyaltyText = loyaltyText or pet.loyaltyText
    pet.stabled = nil

    local happiness = readHappiness()
    if happiness then
        if happiness == 1 and pet.happiness and pet.happiness > 1 then
            self:Log(pet, "EV_UNHAPPY", pet.name)
            self:Talk(pet, "sad")
        elseif happiness == 3 and pet.happiness == 1 then
            self:Log(pet, "EV_HAPPY_AGAIN", pet.name)
            self:Talk(pet, "happy")
        end
        pet.happiness = happiness
    end
    pet.trainingFree, pet.trainingTotal = readTraining()
    pet.lastSeen = time()
    -- Una mascota muerta puede seguir existiendo; la caída queda pendiente hasta revivirla.
    if not safe(UnitIsDead, "pet") then pet.pendingFall = nil end

    if pet.retired then self:SetRetired(pet, false) end
    if not pet.displayID then captureModel(pet) end
    ns.activeKey = key
    ns.lastKey = key
    charDB.lastKey = key
    if greet then self:Talk(pet, greet) end
    visitZone(pet)
    self:CheckAchievements(pet)
    self:Changed()
end

local function tickTime()
    local now = GetTime()
    local elapsed = lastTick and (now - lastTick) or 0
    lastTick = now
    local pet = ns:GetPet(ns.activeKey)
    if pet and petExists() and elapsed > 0 and elapsed < TICK * 4 then
        pet.stats.timeTogether = pet.stats.timeTogether + elapsed
        if pet.happiness == 3 then pet.stats.timeHappy = (pet.stats.timeHappy or 0) + elapsed end
        ns:CheckAchievements(pet)
    end
end

------------------------------------------------------------------------
-- Eventos
------------------------------------------------------------------------

local events = {}
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event, ...)
    local handler = events[event]
    if handler then handler(...) end
end)

function events.ADDON_LOADED(name)
    if name ~= ADDON then return end
    VinculoDB = VinculoDB or {}
    db = VinculoDB
    db.version = 1
    db.opt = db.opt or {}
    for k, v in pairs(DEFAULT_OPTIONS) do
        if db.opt[k] == nil then db.opt[k] = v end
    end
    db.chars = db.chars or {}
    local charKey = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    db.chars[charKey] = db.chars[charKey] or { pets = {}, order = {} }
    charDB = db.chars[charKey]
    ns.db = db
    ns.charDB = charDB
    ns.lastKey = charDB.lastKey
    frame:UnregisterEvent("ADDON_LOADED")
end

function events.PLAYER_LOGIN()
    local _, class = UnitClass("player")
    isHunter = class == "HUNTER"
    if not isHunter then return end
    for _, e in ipairs({
        "PLAYER_ENTERING_WORLD", "UNIT_PET", "UNIT_LEVEL", "UNIT_NAME_UPDATE",
        "PET_BAR_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "UNIT_HEALTH", "UNIT_SPELLCAST_SUCCEEDED", "ENCOUNTER_END",
        "ZONE_CHANGED_NEW_AREA", "UNIT_HAPPINESS", "PET_STABLE_SHOW", "PET_STABLE_UPDATE",
        "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED",
    }) do
        pcall(frame.RegisterEvent, frame, e)
    end
    lastTick = GetTime()
    C_Timer.NewTicker(TICK, tickTime)
    -- Solo se presenta la primera vez; después no ensucia el chat.
    if not db.welcomed then
        db.welcomed = true
        ns:Print(L.LOADED)
    end
    -- Aniversarios y resumen semanal, un momento después de entrar para que no se pierdan.
    C_Timer.After(8, function()
        ns:CheckAnniversaries(true)
        ns:CheckWeek(true)
    end)
end

function events.PLAYER_ENTERING_WORLD()
    C_Timer.After(2, function() ns:RefreshPet() end)
end

function events.ZONE_CHANGED_NEW_AREA()
    local pet = ns:GetPet(ns.activeKey)
    if pet and petExists() then
        visitZone(pet)
        ns:CheckAchievements(pet)
        ns:Changed()
    end
end

function events.UNIT_PET(unit)
    if unit ~= "player" then return end
    if inCombat then
        -- Desaparece en combate sin haberla retirado tú: ha caído.
        if not petExists() and combat and combat.key
            and (GetTime() - dismissedAt) > 2
            and not safe(UnitIsDeadOrGhost, "player") then
            local pet = ns:GetPet(combat.key)
            if pet then recordFall(pet); combat.fell = true end
            ns.activeKey = nil
            ns:Changed()
        end
        return
    end
    tickTime()
    ns:RefreshPet()
end

local function petUnitEvent(unit)
    if unit == "pet" and not inCombat then ns:RefreshPet() end
end
events.UNIT_LEVEL = petUnitEvent
events.UNIT_NAME_UPDATE = petUnitEvent
events.UNIT_HAPPINESS = petUnitEvent
events.PET_BAR_UPDATE = function() if not inCombat then ns:RefreshPet() end end

function events.UNIT_HEALTH(unit)
    if unit ~= "pet" or not combat or combat.fell then return end
    if safe(UnitIsDead, "pet") then
        local pet = ns:GetPet(combat.key)
        if pet then recordFall(pet); combat.fell = true; ns:Changed() end
    end
end

-- Diagnóstico temporal (/vinculo debug): últimas entradas y salidas de combate y por qué se contó o no una victoria.
local dbgLog = {}
local function dbg(text)
    dbgLog[#dbgLog + 1] = ("%.0f %s"):format(GetTime(), text)
    if #dbgLog > 12 then table.remove(dbgLog, 1) end
end

function events.PLAYER_REGEN_DISABLED()
    inCombat = true
    dbg(("ENTRA: activeKey=%s mascota=%s"):format(tostring(ns.activeKey ~= nil), tostring(petExists())))
    if ns.activeKey and petExists() then
        combat = { key = ns.activeKey, start = GetTime(), fell = false }
        combat.prey, combat.preyType, combat.preyFamily = readPrey()
    else
        combat = nil
    end
end

-- Si cambias de objetivo en combate, cuenta el último al que atacabais.
-- Bestias de tu lista de deseos: aviso al pasar el ratón por encima o ver su placa de nombre.
function events.UPDATE_MOUSEOVER_UNIT() ns:CheckBeastAlert("mouseover") end
function events.NAME_PLATE_UNIT_ADDED(unit) ns:CheckBeastAlert(unit) end

function events.PLAYER_TARGET_CHANGED()
    ns:CheckBeastAlert("target")
    if ns.RecordSighting then ns:RecordSighting() end -- apunta dónde ves cada bestia, para el mapa
    if not combat then return end
    local name, kind, family = readPrey()
    if name then combat.prey, combat.preyType, combat.preyFamily = name, kind, family end
end

function events.PLAYER_REGEN_ENABLED()
    inCombat = false
    if ns.UI and ns.UI.frame then
        if ns.strataPending then ns.strataPending = nil; ns.UI:SetStrata("HIGH") end
        ns.UI:SyncFeed() -- lo que se escondió con la transparencia en combate se oculta del todo ahora
    end
    local c = combat
    combat = nil
    dbg(("SALE: combate=%s cayo=%s mascota=%s muerta=%s jugadorMuerto=%s"):format(tostring(c ~= nil), tostring(c and c.fell),
        tostring(petExists()), tostring(safe(UnitIsDead, "pet")), tostring(safe(UnitIsDeadOrGhost, "player"))))
    if c then
        local pet = ns:GetPet(c.key)
        if pet then
            pet.stats.timeCombat = pet.stats.timeCombat + (GetTime() - c.start)
            if not c.fell and petExists() and not safe(UnitIsDead, "pet")
                and not safe(UnitIsDeadOrGhost, "player") then
                local s = pet.stats
                s.victories = s.victories + 1
                s.streak = s.streak + 1
                if s.streak > s.bestStreak then s.bestStreak = s.streak end
                if s.streak % 50 == 0 then ns:Talk(pet, "streak", s.streak) end
                if c.prey then
                    local n = count(pet, "prey", c.prey)
                    if c.preyType then count(pet, "preyTypes", c.preyType) end
                    -- Familia de la bestia derrotada: alimenta el Códice (se guarda con una clave fija, no localizada)
                    if c.preyFamily then count(pet, "preyFamilies", ns.FamilyKey and ns:FamilyKey(c.preyFamily) or c.preyFamily) end
                    if PREY_MILESTONES[n] then ns:Talk(pet, "prey", c.prey, n) end
                end
            end
            ns:CheckAchievements(pet)
        end
    end
    ns:RefreshPet()
end

function events.UNIT_SPELLCAST_SUCCEEDED(unit, _, spellID)
    if unit ~= "player" or isSecret(spellID) then return end
    if spellID == SPELL_TAME_BEAST then
        lastTameCast = GetTime()
    elseif spellID == SPELL_DISMISS_PET then
        dismissedAt = GetTime()
    elseif spellID == SPELL_FEED_PET then
        local pet = ns:GetPet(ns.activeKey)
        if pet then
            pet.stats.feeds = pet.stats.feeds + 1
            ns:Talk(pet, "feed")
            ns:CheckAchievements(pet)
            ns:Changed()
        end
    elseif spellID == SPELL_REVIVE_PET then
        local pet = ns:GetPet(ns.lastKey)
        if pet then
            -- Si no vimos la caída (p. ej. fuera de combate), la apuntamos ahora.
            recordFall(pet)
            pet.pendingFall = nil
            pet.stats.revives = pet.stats.revives + 1
            ns:Log(pet, "EV_REVIVE", pet.name)
            ns:Talk(pet, "revive")
            ns:CheckAchievements(pet)
            ns:Changed()
        end
    end
end

function events.ENCOUNTER_END(_, encounterName, _, _, success)
    if isSecret(success) or success ~= 1 or isSecret(encounterName) then return end
    local key = (combat and combat.key) or ns.activeKey
    local pet = ns:GetPet(key)
    if not pet or not encounterName then return end
    pet.stats.bosses = pet.stats.bosses + 1
    local first = not pet.bossKills[encounterName]
    pet.bossKills[encounterName] = (pet.bossKills[encounterName] or 0) + 1
    if first then
        ns:Log(pet, "EV_BOSS", encounterName)
        ns:Talk(pet, "boss", encounterName)
    end
    ns:CheckAchievements(pet)
    ns:Changed()
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
ns.events = events -- para pruebas

------------------------------------------------------------------------
-- Compartir y comandos
------------------------------------------------------------------------

function ns:ShareText(pet)
    local earned = 0
    for _ in pairs(pet.achievements) do earned = earned + 1 end
    return L.SHARE_LINE:format(pet.name, pet.family or L.FAMILY_UNKNOWN, pet.level or 1,
        pet.stats.victories, pet.stats.bosses, ns.FormatTime(pet.stats.timeTogether),
        earned, #ns.ACHIEVEMENTS)
end

function ns:Share(pet)
    if not pet then return end
    local text = self:ShareText(pet)
    local channel
    if IsInRaid and IsInRaid() then channel = "RAID"
    elseif IsInGroup and IsInGroup() then channel = "PARTY"
    elseif IsInGuild and IsInGuild() then channel = "GUILD" end
    -- Forever declara C_ChatInfo.SendChatMessage; si falla, se muestra solo en tu chat.
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    if channel and send and pcall(send, text, channel) then return end
    if channel then
        self:Print(text)
    else
        self:Print(L.NO_CHANNEL)
        self:Print(text)
    end
end

SLASH_VINCULO1 = "/vinculo"
SLASH_VINCULO2 = "/diario"
SlashCmdList.VINCULO = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if not isHunter then ns:Print(L.NOT_HUNTER) return end
    if msg == "avisos" or msg == "toasts" then
        db.opt.toasts = not db.opt.toasts
        ns:Print(db.opt.toasts and L.TOASTS_ON or L.TOASTS_OFF)
        ns:Changed()
    elseif msg == "compartir" or msg == "share" then
        ns:Share(ns:GetPet(ns.activeKey or ns.lastKey))
    elseif msg == "exportar" or msg == "export" then
        ns.UI:Export(ns:GetPet(ns.activeKey or ns.lastKey))
    elseif msg == "aviso" or msg == "test" then
        -- Enseña el aviso de logro con un logro de prueba (para ver cómo queda).
        local pet = ns:GetPet(ns.activeKey or ns.lastKey)
        if pet then ns.UI:Toast(pet, (ns:AchievementText("victory_1")), "Interface\\Icons\\Ability_Hunter_Pet_Wolf") end
    elseif msg == "tip" then
        -- Diagnóstico temporal del tooltip de bestias: ejecuta la lógica sobre tu objetivo y dice qué pasa.
        local ok, err = pcall(ns.AddBeastLines, GameTooltip, "target")
        ns:Print(("tip: ok=%s %s enganchado=%s nombre=%s familia=%s opcion=%s"):format(tostring(ok), ok and "" or tostring(err),
            tostring(ns.tipHooked), tostring(safe(UnitName, "target")), tostring(safe(UnitCreatureFamily, "target")),
            tostring(ns.db.opt.beastTip)))
    elseif msg == "debug" then
        for _, line in ipairs(dbgLog) do ns:Print(line) end
        if #dbgLog == 0 then ns:Print("debug: sin combates todavía") end
    elseif msg == "ayuda" or msg == "help" then
        ns:Print(L.HELP)
    else
        ns.UI:Toggle()
    end
end
