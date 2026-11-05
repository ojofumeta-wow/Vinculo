local ADDON, ns = ...
local L = ns.L

local DAY = 86400
local WEEK = 7 * DAY
local MONDAY_OFFSET = 4 * DAY -- el 1/1/1970 fue jueves; así las semanas empiezan en lunes
local MIN_FIGHTS = 25

------------------------------------------------------------------------
-- Personalidad
------------------------------------------------------------------------

-- Cada rasgo devuelve una puntuación (1 = destaca claramente) y el dato que
-- se enseña en la explicación. Gana el rasgo con mayor puntuación.
local TRAITS = {
    { id = "glutton", score = function(p, s, h)
        if h < 1 then return 0 end
        return (s.feeds / h) / 1.5, s.feeds / h
    end },
    { id = "reckless", score = function(p, s)
        local rate = s.falls * 100 / math.max(s.victories, 1)
        return rate / 4, rate
    end },
    { id = "wanderer", score = function(p) return p.zoneCount / 15, p.zoneCount end },
    { id = "giantslayer", score = function(p, s) return s.bosses / 25, s.bosses end },
    { id = "tireless", score = function(p, s, h) return h / 50, ns.FormatTime(s.timeTogether) end },
    { id = "unbreakable", score = function(p, s) return s.bestStreak / 150, s.bestStreak end },
    { id = "loyal", score = function(p) return (p.loyalty or 0) >= 6 and 1 or 0 end },
}

-- Devuelve nombre y explicación de la personalidad de la mascota.
function ns:GetPersonality(pet)
    local texts = L.PERSONALITY
    local s = pet.stats
    if s.victories < MIN_FIGHTS then
        return texts.newcomer[1], texts.newcomer[2]
    end
    local hours = s.timeTogether / 3600
    local bestId, bestScore, bestValue = "faithful", 0.999, nil
    for _, trait in ipairs(TRAITS) do
        local score, value = trait.score(pet, s, hours)
        if score > bestScore then
            bestId, bestScore, bestValue = trait.id, score, value
        end
    end
    local t = texts[bestId]
    local ok, desc = pcall(string.format, t[2], bestValue)
    return t[1], ok and desc or t[2]
end

------------------------------------------------------------------------
-- Gustos: lo que más caza y quién le cuesta más
------------------------------------------------------------------------

local function top(t)
    local best, n = nil, 0
    for name, c in pairs(t or {}) do
        if c > n or (c == n and best and name < best) then best, n = name, c end
    end
    return best, n
end

-- Como mucho dos gustos, para que quepan en una línea de la ficha.
function ns:GetLikes(pet)
    local likes = {}
    local prey, n = top(pet.prey)
    if prey and n >= 5 then
        likes[#likes + 1] = L.LIKE_PREY:format(prey, n)
    else
        local kind, k = top(pet.preyTypes)
        if kind and k >= 10 then likes[#likes + 1] = L.LIKE_TYPE:format(kind) end
    end
    local foe, f = top(pet.nemesis)
    if foe and f >= 2 then likes[#likes + 1] = L.LIKE_NEMESIS:format(foe, f) end
    return likes
end

------------------------------------------------------------------------
-- La mascota habla (solo en tu chat)
------------------------------------------------------------------------

-- Segundos que tienen que pasar desde la última frase, y probabilidad de hablar.
-- Lo importante puede hablar pronto; lo que pasa a menudo, poco y no siempre.
local TALK_RULES = {
    tamed = { 0, 1 }, hello = { 0, 1 },
    level = { 30, 1 }, boss = { 30, 1 }, revive = { 30, 1 }, sad = { 120, 1 },
    prey = { 300, 1 }, streak = { 300, 1 }, happy = { 600, 1 },
    zone = { 600, 0.5 }, feed = { 600, 0.3 },
}
local LOGIN_QUIET = 20 -- al entrar hay muchas lecturas seguidas; nada de hablar
local lastTalk, quietUntil = -math.huge, 0
local pendingTalk

local function speak(msg)
    local info = ChatTypeInfo and ChatTypeInfo.MONSTER_SAY
    local r, g, b = 1, 1, 0.62
    if info and info.r then r, g, b = info.r, info.g, info.b end
    DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b)
end

-- Nunca se envía a otros jugadores: solo AddMessage a tu ventana de chat.
function ns:Say(pet, kind, ...)
    local rule, lines = TALK_RULES[kind], L.TALK and L.TALK[kind]
    if not rule or not lines or not ns.db.opt.talk or pet.retired or pet.key ~= ns.activeKey then return end
    local now = GetTime()
    if now < quietUntil and kind ~= "tamed" then return end
    if now - lastTalk < rule[1] or math.random() > rule[2] then return end
    local ok, line = pcall(string.format, lines[math.random(#lines)], ...)
    if not ok then return end
    lastTalk = now
    local msg = L.TALK_SAYS:format(pet.name, line)
    -- En combate el chat va lleno: la frase espera a que termine.
    if InCombatLockdown and InCombatLockdown() then pendingTalk = msg else speak(msg) end
end

local onLogin = ns.events.PLAYER_LOGIN
ns.events.PLAYER_LOGIN = function(...)
    quietUntil = GetTime() + LOGIN_QUIET
    onLogin(...)
end

local onCombatEnd = ns.events.PLAYER_REGEN_ENABLED
ns.events.PLAYER_REGEN_ENABLED = function(...)
    onCombatEnd(...)
    if pendingTalk then
        local msg = pendingTalk
        pendingTalk = nil
        C_Timer.After(1.5, function() speak(msg) end)
    end
end

------------------------------------------------------------------------
-- Aniversarios
------------------------------------------------------------------------

local function monthsBetween(t1, t2)
    local a, b = date("*t", t1), date("*t", t2)
    local months = (b.year - a.year) * 12 + (b.month - a.month)
    if b.day < a.day then months = months - 1 end
    return math.max(months, 0)
end

local function isMilestone(m)
    return m == 1 or m == 3 or m == 6 or (m > 0 and m % 12 == 0)
end

local function anniversaryText(m)
    if m % 12 == 0 then
        local years = m / 12
        return years == 1 and L.ANNIV_YEAR or L.ANNIV_YEARS:format(years)
    end
    return m == 1 and L.ANNIV_MONTH or L.ANNIV_MONTHS:format(m)
end

function ns:CheckAnniversaries(notify)
    local pets = ns.charDB.pets
    local now = time()
    for _, pet in pairs(pets) do
        local months = monthsBetween(pet.created, now)
        pet.months = months
        local seen = pet.annivSeen or 0
        if months > seen then
            -- Si pasaste mucho sin jugar, solo se celebra el último hito.
            local hit
            for m = seen + 1, months do
                if isMilestone(m) then hit = m end
            end
            pet.annivSeen = months
            if hit and not pet.retired then
                local text = anniversaryText(hit)
                self:Log(pet, "EV_ANNIVERSARY", text)
                if notify and ns.db.opt.anniv then
                    self:Print(L.ANNIV_CHAT:format(pet.name, text))
                end
            end
        end
        self:CheckAchievements(pet)
    end
    self:Changed()
end

------------------------------------------------------------------------
-- Resumen semanal
------------------------------------------------------------------------

local function weekId(t)
    return math.floor((t - MONDAY_OFFSET) / WEEK)
end

local function snapshot(pet)
    local s = pet.stats
    return { v = s.victories, b = s.bosses, z = pet.zoneCount, t = s.timeTogether }
end

-- Una sola línea en el chat con la mascota que más te acompañó la semana pasada.
function ns:CheckWeek(notify)
    local charDB = ns.charDB
    local id = weekId(time())
    local week = charDB.week
    if week and week.id == id then return end

    -- Solo si la foto es de la semana anterior; si no, el resumen mezclaría semanas antiguas.
    if week and week.id == id - 1 and notify and ns.db.opt.weekly then
        local best, bestDelta
        for key, pet in pairs(charDB.pets) do
            if not pet.retired then
                local old = week.pets[key] or { v = 0, b = 0, z = 0, t = 0 }
                local cur = snapshot(pet)
                local d = { v = cur.v - old.v, b = cur.b - old.b, z = cur.z - old.z, t = cur.t - old.t }
                if not bestDelta or d.v > bestDelta.v or (d.v == bestDelta.v and d.t > bestDelta.t) then
                    best, bestDelta = pet, d
                end
            end
        end
        if best and (bestDelta.v > 0 or bestDelta.t >= 600) then
            -- Se guarda para poder volver a verlo con /vinculo semana; la ventana la dibuja la interfaz.
            charDB.lastWeek = { name = best.name, v = bestDelta.v, b = bestDelta.b, z = bestDelta.z, t = bestDelta.t }
            -- Una ventana que falle no debe romper el inicio de sesión: el resumen queda guardado para /vinculo semana.
            pcall(self.UI.Week, self.UI)
        end
    end

    local pets = {}
    for key, pet in pairs(charDB.pets) do pets[key] = snapshot(pet) end
    charDB.week = { id = id, pets = pets }
end

------------------------------------------------------------------------
-- Establo
------------------------------------------------------------------------

local function stableList(fn)
    if not fn then return end
    local ok, list = pcall(fn)
    if ok and type(list) == "table" then return list end
end

local function findStabled(info)
    for _, pet in pairs(ns.charDB.pets) do
        if info.petNumber and pet.petNumber == info.petNumber then return pet end
    end
    return ns:FindPetByName(info.name, info.familyName)
end

-- Al abrir el establo: crea la ficha de las mascotas guardadas y pregunta por las que ya no están.
function ns:ScanStable()
    local api = C_StableInfo
    if not api then return end
    local active = stableList(api.GetActivePetList)
    local stabled = stableList(api.GetStabledPetList)
    -- Si alguna lista falla, no se toca nada: mejor no preguntar por error.
    if not active or not stabled or #active + #stabled == 0 then return end

    local seen = {}
    for i, list in ipairs({ active, stabled }) do
        for _, info in ipairs(list) do
            if type(info) == "table" and type(info.name) == "string"
                and not (issecretvalue and issecretvalue(info.name)) then
                local pet = findStabled(info)
                if not pet then
                    pet = self:AddPet("stable:" .. (info.petNumber or info.name), info.name, info.familyName, info.level)
                    pet.metZone = nil
                    self:Log(pet, "EV_STABLE_FOUND", info.name)
                end
                pet.petNumber = info.petNumber or pet.petNumber
                pet.icon = info.icon or pet.icon
                pet.family = pet.family or info.familyName
                if type(info.level) == "number" and info.level > (pet.level or 0) then pet.level = info.level end
                pet.loyaltyText = pet.loyaltyText or info.loyaltyName
                pet.stabled = (i == 2 and pet.key ~= ns.activeKey) or nil
                seen[pet.key] = true
                self:CheckAchievements(pet)
            end
        end
    end

    -- Una sola pregunta por visita, y nunca dos veces por la misma mascota en la sesión.
    self.askedAbandon = self.askedAbandon or {}
    for _, key in ipairs(ns.charDB.order) do
        local pet = ns.charDB.pets[key]
        if pet and not pet.retired and not seen[key] and key ~= ns.activeKey and not self.askedAbandon[key] then
            self.askedAbandon[key] = true
            StaticPopup_Show("VINCULO_ABANDONED", pet.name, nil, pet)
            break
        end
    end
    self:Changed()
end

ns.events.PET_STABLE_SHOW = function() ns:ScanStable() end
ns.events.PET_STABLE_UPDATE = ns.events.PET_STABLE_SHOW

------------------------------------------------------------------------
-- Lista de deseos
------------------------------------------------------------------------

function ns:GetWishes()
    ns.charDB.wishes = ns.charDB.wishes or {}
    return ns.charDB.wishes
end

-- "nombre, zona, nota": solo el nombre es obligatorio.
function ns:AddWish(text)
    local parts = {}
    for part in ((text or "") .. ","):gmatch("([^,]*),") do
        parts[#parts + 1] = part:gsub("^%s+", ""):gsub("%s+$", "")
    end
    if not parts[1] or parts[1] == "" then return end
    -- Sin zona escrita, la de la tabla de bestias (si la conoce).
    if (parts[2] or "") == "" then
        local z = self:BeastZones(parts[1])[1]
        if z then parts[2] = z.text end
    end
    local wishes = self:GetWishes()
    wishes[#wishes + 1] = { name = parts[1], zone = parts[2] ~= "" and parts[2] or nil,
        note = (#parts > 2) and table.concat(parts, ", ", 3) or nil, t = time() }
    self:Changed()
    return wishes[#wishes]
end

-- Apunta la bestia que tienes seleccionada: nombre, zona y familia, sin teclear.
function ns:AddWishFromTarget()
    local safe = ns.safe
    local name = safe(UnitExists, "target") and not safe(UnitIsPlayer, "target") and safe(UnitName, "target")
    local family = type(name) == "string" and safe(UnitCreatureFamily, "target")
    if type(name) ~= "string" or name == "" or type(family) ~= "string" then
        self:Print(L.WISH_NOTARGET)
        return
    end
    for _, w in ipairs(self:GetWishes()) do
        if not w.done and w.name:lower() == name:lower() then
            self:Print(L.WISH_DUP:format(name))
            return
        end
    end
    -- El texto se parte por comas: las del nombre y la zona sobran.
    local zone = safe(GetRealZoneText) or safe(GetZoneText) or ""
    local wish = self:AddWish(name:gsub(",", " ") .. ", " .. tostring(zone):gsub(",", " ") .. ", " .. family:gsub(",", " "))
    if wish then self:Print(L.WISH_ADDED:format(name)) end
    return wish
end

function ns:RemoveWish(index)
    table.remove(self:GetWishes(), index)
    self:Changed()
end

-- Al domesticar, la bestia nueva lleva el nombre de la criatura: si estaba en la lista, se marca.
function ns:CompleteWish(pet)
    local name = pet.name and pet.name:lower()
    for _, wish in ipairs(self:GetWishes()) do
        if not wish.done and wish.name:lower() == name then
            wish.done = time()
            self:Log(pet, "EV_WISH_DONE", wish.name)
            return wish
        end
    end
end

-- Sugerencias para la caja de deseos: segmento 1 = bestia (las que ya has visto o apuntado),
-- segmento 2 = zona (las del juego y las que has pisado).
local ACCENTS = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n",
    ["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ñ"] = "n" }
local function fold(s)
    s = s:lower()
    for from, to in pairs(ACCENTS) do s = s:gsub(from, to) end
    return s
end

-- shortcut: solo cuenta las zonas bajo los continentes del mapa cósmico (946); si el cliente no lo da,
-- quedan las zonas que has pisado. Verificar en el juego.
local zoneCache
function ns:ZoneList()
    if zoneCache then return zoneCache end
    local list = {}
    if C_Map and C_Map.GetMapChildrenInfo then
        -- Los continentes salen de los mapas raíz (en Forever el cósmico 946 no devolvía nada), de los que cuelgan del
        -- mapa de Azeroth y de los dos conocidos: Kalimdor 1414 y Reinos del Este 1415 (este último confirmado en Forever).
        local continents, seen = {}, {}
        local function add(id)
            if type(id) == "number" and not seen[id] then seen[id] = true; continents[#continents + 1] = id end
        end
        for _, root in ipairs({ 946, 947 }) do
            local ok, found = pcall(C_Map.GetMapChildrenInfo, root, 2, true)
            for _, c in ipairs(ok and type(found) == "table" and found or {}) do add(c.mapID) end
        end
        add(1414)
        add(1415)
        for _, id in ipairs(continents) do
            local info = ns.safe(C_Map.GetMapInfo, id)
            local hint = type(info) == "table" and info.name or nil
            local ok2, zones = pcall(C_Map.GetMapChildrenInfo, id, 3, true)
            for _, z in ipairs(ok2 and type(zones) == "table" and zones or {}) do
                if type(z.name) == "string" and z.name ~= "" then list[#list + 1] = { text = z.name, hint = hint, id = z.mapID } end
            end
        end
    end
    if #list > 0 then zoneCache = list end -- si el cliente aún no las da, se reintenta la próxima vez
    return list
end

-- uiMapID de una zona por su nombre (sin mayúsculas ni tildes). Los IDs del cliente de Forever no son los de Classic Era,
-- por eso se busca por nombre en el propio mapa del cliente.
function ns:ZoneMapID(name)
    if type(name) ~= "string" then return end
    local n = fold(name)
    for _, z in ipairs(self:ZoneList()) do
        if z.id and fold(z.text) == n then return z.id end
    end
    -- Respaldo: si estás en esa zona (o dentro de ella), su mapa sale subiendo desde el mapa actual.
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo then
        local id = ns.safe(C_Map.GetBestMapForUnit, "player")
        for _ = 1, 6 do
            if type(id) ~= "number" or id <= 0 then break end
            local info = ns.safe(C_Map.GetMapInfo, id)
            if type(info) ~= "table" then break end
            if type(info.name) == "string" and fold(info.name) == n then return id end
            id = info.parentMapID
        end
    end
end

-- Marcas propias en el mapa del mundo: una por zona con deseos pendientes, en el centro de la zona (o de su recuadro
-- en el mapa que se esté viendo). Este cliente no tiene chincheta nativa (C_Map.SetUserWaypoint), así que se dibujan aquí.
-- shortcut: se colocan en el centro de la zona; si se graban lugares vistos, usar esas coordenadas.
local mapPins, pinDriver = {}, nil

local function newMapPin(canvas)
    local pin = CreateFrame("Button", nil, canvas)
    pin:SetSize(28, 28)
    pin:SetFrameStrata("DIALOG") -- por encima del mapa y de sus marcas (con solo el nivel de marco quedaba debajo)
    pin:SetFrameLevel(9000)
    -- Lugar visto de verdad: el icono. Zona aproximada: un círculo que la rodea (las texturas no capturan el ratón,
    -- así que el aro no estorba al mapa; solo el centro de 28 px enseña el tooltip).
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints()
    pin.icon:SetTexture("Interface\\AddOns\\Vinculo\\Media\\Icon")
    pin.ring = pin:CreateTexture(nil, "ARTWORK")
    pin.ring:SetPoint("CENTER")
    pin.ring:SetTexture("Interface\\AddOns\\Vinculo\\Media\\ZoneRing")
    pin.dot = pin:CreateTexture(nil, "OVERLAY")
    pin.dot:SetSize(10, 10)
    pin.dot:SetPoint("CENTER")
    pin.dot:SetTexture("Interface\\AddOns\\Vinculo\\Media\\Circle")
    pin.dot:SetVertexColor(1, 0.75, 0.16, 1)
    pin:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.TITLE)
        for _, name in ipairs(s.names or {}) do GameTooltip:AddLine(name, 1, 1, 1) end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return pin
end

-- Lugares donde has visto cada bestia (se graban solos al seleccionarla): nombre sin tildes -> { {m=mapa, x=, y=} }.
-- Es de toda la cuenta y está acotado (MAX_NAMES nombres, MAX_SPOTS lugares por nombre).
local MAX_SPOTS, MAX_NAMES = 6, 800

function ns:RecordSighting()
    local safe = ns.safe
    if not (safe(UnitExists, "target") and not safe(UnitIsPlayer, "target")) then return end
    local name, family = safe(UnitName, "target"), safe(UnitCreatureFamily, "target")
    if type(name) ~= "string" or name == "" or type(family) ~= "string" then return end
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return end
    local map = safe(C_Map.GetBestMapForUnit, "player")
    local pos = map and safe(C_Map.GetPlayerMapPosition, map, "player")
    if type(pos) ~= "table" and type(pos) ~= "userdata" then return end
    local ok, x, y = pcall(pos.GetXY, pos)
    if not ok or type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return end
    x, y = math.floor(x * 1000 + 0.5) / 1000, math.floor(y * 1000 + 0.5) / 1000
    ns.db.spots = ns.db.spots or {}
    local key = fold(name)
    local list = ns.db.spots[key]
    if not list then
        if (ns.db.spotNames or 0) >= MAX_NAMES then return end
        list = {}
        ns.db.spots[key] = list
        ns.db.spotNames = (ns.db.spotNames or 0) + 1
    end
    for _, s in ipairs(list) do
        if s.m == map and math.abs(s.x - x) < 0.04 and math.abs(s.y - y) < 0.04 then return end
    end
    list[#list + 1] = { m = map, x = x, y = y }
    if #list > MAX_SPOTS then table.remove(list, 1) end
end

function ns:SpotsFor(name)
    return (ns.db.spots and ns.db.spots[fold(name or "")]) or {}
end

-- Posición (0-1) de un punto de otro mapa sobre el mapa que se está viendo; nil si no cabe en él.
local function onMap(cur, map, x, y)
    if map == cur then return x, y end
    if C_Map and C_Map.GetMapRectOnMap then
        local ok, l, r, t, b = pcall(C_Map.GetMapRectOnMap, map, cur)
        if ok and l and r and t and b then return l + x * (r - l), t + y * (b - t) end
    end
end

-- Diámetro (en fracción del lado menor del lienzo) del círculo que rodea la zona `id` vista desde el mapa `cur`.
local function zoneDiameter(cur, id, w, h)
    if id == cur then return 0.4 end -- ya estás dentro de la zona: un círculo moderado en su centro
    if C_Map and C_Map.GetMapRectOnMap then
        local ok, l, r, t, b = pcall(C_Map.GetMapRectOnMap, id, cur)
        if ok and l and r and t and b then
            return math.max(0.03, math.min((r - l) * w, (b - t) * h) * 0.8 / math.min(w, h))
        end
    end
    return 0.1
end

function ns:UpdateMapPins(canvas)
    local cur = WorldMapFrame:GetMapID()
    local scale = (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or 1
    if type(scale) ~= "number" or scale <= 0 then scale = 1 end
    local w, h = canvas:GetWidth(), canvas:GetHeight()
    local points = {}
    for _, wish in ipairs(ns.db.opt.mapPins and self:GetWishes() or {}) do
        if wish.zone and not wish.done and #points < 40 then
            local spots = self:SpotsFor(wish.name)
            if #spots > 0 then
                -- Lugares reales donde la has visto.
                for _, s in ipairs(spots) do
                    local x, y = onMap(cur, s.m, s.x, s.y)
                    if x then points[#points + 1] = { x = x, y = y, name = wish.name } end
                end
            else
                -- Sin lugares grabados: el centro de su zona, avisando de que es aproximado.
                local id = self:ZoneMapID(wish.zone)
                local x, y
                if id then x, y = onMap(cur, id, 0.5, 0.5) end
                if x then points[#points + 1] = { x = x, y = y, name = wish.name, approx = true, d = zoneDiameter(cur, id, w, h) } end
            end
        end
    end
    local ps = 1 / scale -- las marcas se dibujan dentro del lienzo, que se escala al hacer zoom: se compensa
    for i, p in ipairs(points) do
        local pin = mapPins[i]
        if not pin then pin = newMapPin(canvas); mapPins[i] = pin end
        pin.names = { p.name, p.approx and L.MAP_APPROX or nil }
        pin.icon:SetShown(not p.approx)
        pin.ring:SetShown(p.approx and true or false)
        pin.dot:SetShown(p.approx and true or false)
        if p.approx then
            local size = p.d * math.min(w, h) / ps -- píxeles del lienzo, compensando el zoom como la posición
            pin.ring:SetSize(size, size)
        end
        pin:SetScale(ps)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT", p.x * w / ps, -p.y * h / ps)
        pin:Show()
    end
    for i = #points + 1, #mapPins do mapPins[i]:Hide() end
end

function ns:EnsureMapPins()
    if pinDriver or not WorldMapFrame or not WorldMapFrame.GetCanvas then return end
    local ok, canvas = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
    if not ok or not canvas then return end
    pinDriver = CreateFrame("Frame", nil, canvas)
    local elapsed = 0
    pinDriver:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < 0.25 then return end
        elapsed = 0
        pcall(ns.UpdateMapPins, ns, canvas) -- un fallo aquí nunca debe romper el mapa
    end)
end

-- ¿Come la mascota este objeto? Forever lo dice directamente (C_PetInfo.CanPetEatItem); en MoP y Era se usa
-- el respaldo de Foods.lua: la dieta de su familia y el tipo de cada comida conocida.
local function petEats(id)
    if C_PetInfo and C_PetInfo.CanPetEatItem then
        local ok, eats = pcall(C_PetInfo.CanPetEatItem, id)
        return ok and eats == true
    end
    local family = ns.safe(UnitCreatureFamily, "pet")
    local diets = type(family) == "string" and ns.FAMILY_DIETS and ns.FAMILY_DIETS[ns:FamilyKey(family)]
    local kind = ns.PET_FOODS and ns.PET_FOODS[id]
    if not (diets and kind) then return false end
    for _, d in ipairs(diets) do
        if d == kind then return true end
    end
    return false
end

-- La mejor comida de tus bolsas para la mascota: bolsa, hueco e ID, o nada.
-- Elige el objeto de más nivel y, a igualdad, la pila más pequeña.
function ns:BestFood()
    local CC = C_Container
    local slots = (CC and CC.GetContainerNumSlots) or GetContainerNumSlots
    local itemAt = (CC and CC.GetContainerItemID) or GetContainerItemID
    if not (slots and itemAt) then return end
    local bestBag, bestSlot, bestId, bestLevel, bestCount
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, slots(bag) or 0 do
            local id = itemAt(bag, slot)
            if id and petEats(id) then
                local level = select(4, ns.ItemInfo(id)) or 0
                local info = CC and CC.GetContainerItemInfo and CC.GetContainerItemInfo(bag, slot)
                local count = type(info) == "table" and info.stackCount or 1
                if not bestId or level > bestLevel or (level == bestLevel and count < bestCount) then
                    bestBag, bestSlot, bestId, bestLevel, bestCount = bag, slot, id, level, count
                end
            end
        end
    end
    return bestBag, bestSlot, bestId
end

-- Aviso al ver una bestia de tu lista de deseos (ratón encima, objetivo o placa de nombre). Nunca en combate,
-- y como mucho una vez cada 2 minutos por bestia.
local alerted = {}
function ns:CheckBeastAlert(unit)
    local opt = ns.db and ns.db.opt
    if not (opt and opt.beastAlert) or (InCombatLockdown and InCombatLockdown()) then return end
    local wishes = self:GetWishes()
    if #wishes == 0 then return end
    local safe = ns.safe
    local name = safe(UnitName, unit)
    if type(name) ~= "string" or safe(UnitIsPlayer, unit) then return end
    local key = fold(name)
    local now = GetTime()
    if alerted[key] and now - alerted[key] < 120 then return end
    for _, w in ipairs(wishes) do
        if not w.done and fold(w.name) == key then
            alerted[key] = now
            self:Print(L.ALERT_BEAST:format(name))
            if opt.sound and SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST then pcall(PlaySound, SOUNDKIT.UI_EPICLOOT_TOAST) end
            return
        end
    end
end

-- Nombres de las habilidades de mascota en español (de memoria, sin verificar en el juego; si falta una, sale en inglés).
local SKILL_ES = { ["Bite"] = "Mordisco", ["Claw"] = "Garra", ["Cower"] = "Agazaparse", ["Charge"] = "Carga",
    ["Dash"] = "Carrera", ["Dive"] = "Picado", ["Furious Howl"] = "Aullido furioso", ["Lightning Breath"] = "Aliento de relámpago",
    ["Prowl"] = "Acechar", ["Scorpid Poison"] = "Veneno de escórpido", ["Screech"] = "Chillido",
    ["Shell Shield"] = "Escudo de caparazón", ["Thunderstomp"] = "Pisotón atronador" }

-- Habilidades que enseña una bestia (tabla de Skills.lua, que va por nombre en inglés; en español se pasa por Data.lua).
-- Devuelve el texto "Mordisco 3, Garra 2" o nil.
function ns:BeastSkillsText(name)
    local skills = ns.BEAST_SKILLS
    if not skills or type(name) ~= "string" then return end
    local entry = skills[name]
    if not entry and ns.BEASTS then
        local n = fold(name)
        for _, b in ipairs(ns.BEASTS) do
            if b.es and fold(b.es) == n then entry = skills[b.en] break end
        end
    end
    if not entry or not entry.skills then return end
    local es = (GetLocale and GetLocale() or "enUS"):find("^es")
    local out = {}
    for _, s in ipairs(entry.skills) do out[#out + 1] = ((es and SKILL_ES[s[1]]) or s[1]) .. " " .. s[2] end
    return table.concat(out, ", ")
end

-- Tooltip de una bestia: si está en tu lista, qué habilidad enseña y si ya has domesticado su familia.
local function addBeastLines(tooltip, unit)
    local opt = ns.db and ns.db.opt
    if not (opt and opt.beastTip) then return end
    local safe = ns.safe
    if not unit or safe(UnitIsPlayer, unit) then return end
    local name, family = safe(UnitName, unit), safe(UnitCreatureFamily, unit)
    if type(name) ~= "string" or type(family) ~= "string" then return end
    local key = fold(name)
    for _, w in ipairs(ns:GetWishes()) do
        if fold(w.name) == key then
            tooltip:AddLine(w.done and L.TIP_WISH_DONE or L.TIP_WISH, 1, 0.82, 0)
            break
        end
    end
    local teaches = ns:BeastSkillsText(name)
    if teaches then tooltip:AddLine(L.TIP_TEACHES:format(teaches), 0.9, 0.8, 0.5) end
    local fkey = ns:FamilyKey(family)
    for _, e in ipairs(ns:Codex().entries) do
        if e.key == fkey then
            if e.state == "tamed" then tooltip:AddLine(L.TIP_FAMILY_TAMED:format(e.name), 0.4, 0.9, 0.4)
            else tooltip:AddLine(L.TIP_FAMILY_NEW:format(e.name), 0.8, 0.8, 0.8) end
            break
        end
    end
    tooltip:Show()
end
ns.AddBeastLines = addBeastLines -- para pruebas

-- Se engancha por los dos caminos (datos de tooltip modernos y el script clásico): según el cliente solo funciona uno.
-- La marca vinculoDone evita duplicar las líneas si disparan los dos; se limpia al vaciarse el tooltip.
function ns:HookTooltip()
    if ns.tipHooked then return end
    local function onUnit(tt)
        if tt ~= GameTooltip or tt.vinculoDone == true then return end
        local ok, _, unit = pcall(tt.GetUnit, tt)
        if ok and unit then
            tt.vinculoDone = true
            pcall(addBeastLines, tt, unit)
        end
    end
    local a, b = false, false
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        a = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, onUnit)
    end
    if GameTooltip and GameTooltip.HookScript then
        b = pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", onUnit)
        pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipCleared", function(tt) tt.vinculoDone = nil end)
    end
    ns.tipHooked = a or b
end

local prevLogin = ns.events.PLAYER_LOGIN
ns.events.PLAYER_LOGIN = function(...)
    if prevLogin then prevLogin(...) end
    ns:EnsureMapPins()
    ns:HookTooltip()
end

-- Abre el mapa del mundo en la zona y, donde el cliente lo permite, deja una chincheta en su centro.
-- shortcut: sin coordenadas de la bestia, la marca es el centro de la zona; si algún día se graban lugares, usar esos.
function ns:ShowZoneOnMap(zone)
    local id = self:ZoneMapID(zone)
    if not id then
        ns.dbg(("mapa: sin id para «%s»; zonas conocidas del cliente=%d"):format(tostring(zone), #self:ZoneList()))
        self:Print(L.MAP_NOZONE:format(tostring(zone)))
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        self:Print(L.MAP_COMBAT)
        return
    end
    self:EnsureMapPins()
    local opened = C_Map and C_Map.OpenWorldMap and pcall(C_Map.OpenWorldMap, id)
    if not opened and WorldMapFrame then
        if not WorldMapFrame:IsShown() and ToggleWorldMap then pcall(ToggleWorldMap) end
        opened = pcall(WorldMapFrame.SetMapID, WorldMapFrame, id)
    end
    -- Temporal: queda en /vinculo debug para ver por qué no abre el mapa en Forever.
    ns.dbg(("mapa: zona=%s id=%s OpenWorldMap=%s abierto=%s"):format(tostring(zone), tostring(id),
        tostring(C_Map and C_Map.OpenWorldMap ~= nil), tostring(opened)))
    if not opened then self:Print(L.MAP_FAIL:format(zone)) end
    -- El mapa debe verse por encima del libro: se baja el libro mientras el mapa esté abierto.
    if opened and ns.UI and ns.UI.frame and WorldMapFrame and WorldMapFrame.HookScript then
        ns.UI:SetStrata("LOW")
        if not ns.mapHooked then
            ns.mapHooked = pcall(WorldMapFrame.HookScript, WorldMapFrame, "OnHide", function()
                -- En combate no se puede cambiar la capa de un marco que contiene un botón seguro: queda pendiente.
                if InCombatLockdown and InCombatLockdown() then ns.strataPending = true; return end
                if ns.UI.frame then ns.UI:SetStrata("HIGH") end
            end)
        end
    end
    if C_Map and C_Map.SetUserWaypoint and C_Map.CreateUiMapPoint then
        local ok = pcall(function()
            if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(id) then error("no") end
            C_Map.SetUserWaypoint(C_Map.CreateUiMapPoint(id, 0.5, 0.5))
        end)
        if ok then self:Print(L.MAP_PINNED:format(zone)) end
    end
end

-- `beast` (solo en el segmento 2): la bestia ya escrita; sus zonas salen primero, incluso sin teclear nada.
function ns:WishSuggestions(segment, query, beast)
    local q = fold(query or "")
    local mine = {}
    for _, z in ipairs(segment == 2 and beast and self:BeastZones(beast) or {}) do
        if q == "" or fold(z.text):find(q, 1, true) then mine[#mine + 1] = z end
    end
    if q == "" then return mine end
    local pool, seen = {}, {}
    local function add(text, hint)
        if type(text) == "string" and text ~= "" and not seen[text] then
            seen[text] = true
            pool[#pool + 1] = { text = text, hint = hint }
        end
    end
    if segment == 1 then
        for _, w in ipairs(self:GetWishes()) do add(w.name, w.zone) end
        for _, pet in pairs(ns.charDB.pets) do
            for name in pairs(pet.prey or {}) do add(name) end
        end
    else
        for _, z in ipairs(self:ZoneList()) do add(z.text, z.hint) end
        for _, pet in pairs(ns.charDB.pets) do
            for zone in pairs(pet.zones or {}) do add(zone, pet.zoneContinent and pet.zoneContinent[zone]) end
        end
    end
    local starts, contains = {}, {}
    for _, e in ipairs(pool) do
        local at = fold(e.text):find(q, 1, true)
        if at == 1 and fold(e.text) ~= q then starts[#starts + 1] = e elseif at and at > 1 then contains[#contains + 1] = e end
    end
    local function byText(a, b) return a.text < b.text end
    table.sort(starts, byText)
    table.sort(contains, byText)
    for _, e in ipairs(contains) do starts[#starts + 1] = e end
    if segment == 1 then
        for _, e in ipairs(self:BeastSuggestions(query)) do
            if not seen[e.text] then
                seen[e.text] = true
                starts[#starts + 1] = e
            end
        end
    end
    if #mine > 0 then
        local own = {}
        for _, z in ipairs(mine) do own[z.text] = true end
        for _, e in ipairs(starts) do
            if not own[e.text] then mine[#mine + 1] = e end
        end
        starts = mine
    end
    while #starts > 6 do starts[#starts] = nil end
    return starts
end

------------------------------------------------------------------------
-- Códice de familias: se rellena solo con las mascotas que has tenido y las bestias que has derrotado
------------------------------------------------------------------------

-- Las 17 familias que existen en Era, MoP y Forever. Nombres en minúsculas, en inglés y español; si el cliente
-- devuelve otro nombre, esa familia se apunta igualmente como "otra", con su nombre tal cual.
ns.FAMILIES = {
    { key = "Bat", names = { "bat", "murciélago" } },
    { key = "Bear", names = { "bear", "oso" } },
    { key = "Boar", names = { "boar", "jabalí" } },
    { key = "CarrionBird", icon = "Vulture", names = { "carrion bird", "carroñero", "ave carroñera", "pájaro carroñero" } },
    { key = "Cat", names = { "cat", "felino", "gato" } },
    { key = "Crab", names = { "crab", "cangrejo" } },
    { key = "Crocolisk", names = { "crocolisk", "crocolisco" } },
    { key = "Gorilla", names = { "gorilla", "gorila" } },
    { key = "Hyena", names = { "hyena", "hiena" } },
    { key = "Owl", names = { "owl", "búho" } },
    { key = "Raptor", names = { "raptor" } },
    { key = "Scorpid", names = { "scorpid", "escórpido" } },
    { key = "Spider", names = { "spider", "araña" } },
    { key = "TallStrider", names = { "tallstrider", "zancaalta" } },
    { key = "Turtle", names = { "turtle", "tortuga" } },
    { key = "WindSerpent", names = { "wind serpent", "serpiente alada" } },
    { key = "Wolf", names = { "wolf", "lobo" } },
}

local FAMILY_BY_NAME = {}
for _, f in ipairs(ns.FAMILIES) do
    f.iconPath = "Interface\\Icons\\Ability_Hunter_Pet_" .. (f.icon or f.key)
    for _, n in ipairs(f.names) do FAMILY_BY_NAME[n] = f end
end

-- Nombre (localizado) de una familia -> clave fija. Si no se conoce, se devuelve el nombre.
function ns:FamilyKey(name)
    if type(name) ~= "string" then return end
    local f = FAMILY_BY_NAME[name:lower()]
    return f and f.key or name
end

local function familyName(f)
    local es = (GetLocale and GetLocale() or "enUS"):find("^es")
    local n = (es and f.names[2]) or f.names[1]
    return n:sub(1, 1):upper() .. n:sub(2)
end

-- Zonas donde vive una bestia de la tabla propia (por su nombre en inglés o en español), con el nombre localizado del mapa.
-- Nombre de zona por su ID de Classic: de la tabla propia (Zones.lua), porque los IDs del cliente de Forever
-- pueden ser otros; si falta, lo que diga el mapa del cliente.
local function zoneName(id)
    local z = ns.ZONES and ns.ZONES[id]
    if z then return ((GetLocale and GetLocale() or "enUS"):find("^es") and z.es) or z.en end
    local ok, info = pcall(C_Map and C_Map.GetMapInfo or error, id)
    if ok and type(info) == "table" and type(info.name) == "string" then return info.name end
end

function ns:BeastZones(name)
    local out = {}
    if not ns.BEASTS or type(name) ~= "string" then return out end
    local n = fold((name:gsub("^%s+", ""):gsub("%s+$", "")))
    if n == "" then return out end
    local seen = {}
    for _, b in ipairs(ns.BEASTS) do
        if fold(b.en) == n or (b.es and fold(b.es) == n) then
            for _, id in ipairs(b.zones or {}) do
                local zone = zoneName(id)
                if zone and not seen[zone] then
                    seen[zone] = true
                    out[#out + 1] = { text = zone }
                end
            end
        end
    end
    return out
end

-- Bestias de la tabla propia (ns.BEASTS, en Data.lua) cuyo nombre o familia encaja con lo escrito.
-- Así "lobo" sugiere lobos concretos aunque no sepas cómo se llaman. Lleva la zona para rellenarla sola.
function ns:BeastSuggestions(query)
    local q = fold(query or "")
    if #q < 2 or not ns.BEASTS then return {} end -- con una letra saldría casi cualquier bestia
    local es = (GetLocale and GetLocale() or "enUS"):find("^es")
    local famByKey = {}
    for _, f in ipairs(ns.FAMILIES) do famByKey[f.key] = f end
    local out = {}
    for _, b in ipairs(ns.BEASTS) do
        local name = (es and b.es) or b.en
        local fam = famByKey[b.fam]
        local famText = fam and familyName(fam) or ""
        local hit = fold(name):find(q, 1, true) or fold(b.en):find(q, 1, true)
        local byFamily = fold(famText):find(q, 1, true) == 1 or (fam and fold(fam.names[1]):find(q, 1, true) == 1)
        if hit or byFamily then
            out[#out + 1] = { text = name, hint = famText .. (b.lvl and (" · " .. b.lvl[1] .. "-" .. b.lvl[2]) or ""),
                rank = hit and 1 or 2, level = b.lvl and b.lvl[1] or 0 }
        end
    end
    -- Primero los que encajan por nombre; luego, por familia y de menor a mayor nivel.
    table.sort(out, function(a, c)
        if a.rank ~= c.rank then return a.rank < c.rank end
        if a.level ~= c.level then return a.level < c.level end
        return a.text < c.text
    end)
    return out
end

-- Al borrar una mascota se conserva en el Códice lo que había aprendido (familia domada, presas).
function ns:KeepInCodex(pet)
    local keep = ns.charDB.codexKept
    if not keep then
        keep = { tamed = {}, preyFamilies = {}, preyTypes = {}, prey = 0 }
        ns.charDB.codexKept = keep
    end
    local k = self:FamilyKey(pet.family)
    if k and (not keep.tamed[k] or (pet.created or 0) < keep.tamed[k]) then keep.tamed[k] = pet.created or 0 end
    for fam, n in pairs(pet.preyFamilies or {}) do keep.preyFamilies[fam] = (keep.preyFamilies[fam] or 0) + n end
    for _, n in pairs(pet.prey or {}) do keep.prey = keep.prey + n end
    for t in pairs(pet.preyTypes or {}) do keep.preyTypes[t] = true end
end

-- Todo lo que cuenta el Códice, sumando todas las mascotas del diario.
function ns:Codex()
    -- Parte de lo guardado de las mascotas ya borradas: el Códice es del personaje, no de cada ficha.
    local keep = ns.charDB.codexKept or { tamed = {}, preyFamilies = {}, preyTypes = {}, prey = 0 }
    local tamed, kills, types, prey, pets = {}, {}, {}, keep.prey, 0
    local typeCount = 0
    for k, t in pairs(keep.tamed) do tamed[k] = t end
    for fam, n in pairs(keep.preyFamilies) do kills[fam] = n end
    for t in pairs(keep.preyTypes) do types[t] = true; typeCount = typeCount + 1 end
    for _, pet in pairs(ns.charDB.pets) do
        pets = pets + 1
        local k = self:FamilyKey(pet.family)
        if k and (not tamed[k] or (pet.created or 0) < tamed[k]) then tamed[k] = pet.created or 0 end
        for fam, n in pairs(pet.preyFamilies or {}) do kills[fam] = (kills[fam] or 0) + n end
        for _, n in pairs(pet.prey or {}) do prey = prey + n end
        for t in pairs(pet.preyTypes or {}) do
            if not types[t] then types[t] = true; typeCount = typeCount + 1 end
        end
    end

    local entries, isBase, baseTamed = {}, {}, 0
    for _, f in ipairs(ns.FAMILIES) do
        isBase[f.key] = true
        local state = tamed[f.key] and "tamed" or (kills[f.key] and "hunted" or "unknown")
        if state == "tamed" then baseTamed = baseTamed + 1 end
        entries[#entries + 1] = { key = f.key, name = familyName(f), icon = f.iconPath, state = state,
            kills = kills[f.key] or 0, since = tamed[f.key] }
    end
    -- Familias que no están entre las 17 (las de MoP o con otro nombre): salen en cuanto aparecen
    local extra, extraTamed = {}, 0
    for k in pairs(tamed) do if not isBase[k] then extra[k] = true end end
    for k in pairs(kills) do if not isBase[k] then extra[k] = true end end
    local names = {}
    for k in pairs(extra) do names[#names + 1] = k end
    table.sort(names)
    for _, k in ipairs(names) do
        if tamed[k] then extraTamed = extraTamed + 1 end
        entries[#entries + 1] = { key = k, name = k, state = tamed[k] and "tamed" or "hunted",
            kills = kills[k] or 0, since = tamed[k] }
    end
    return { entries = entries, baseTamed = baseTamed, baseTotal = #ns.FAMILIES, extraTamed = extraTamed,
        pets = pets, prey = prey, typeCount = typeCount }
end

-- Retos: objetivos propios que se calculan con lo que ya guarda el diario.
function ns:Challenges(codex)
    codex = codex or self:Codex()
    return {
        { id = "families", cur = codex.baseTamed + codex.extraTamed, goal = 5 },
        { id = "pets", cur = codex.pets, goal = 3 },
        { id = "prey", cur = codex.prey, goal = 100 },
        { id = "types", cur = codex.typeCount, goal = 5 },
        { id = "classic", cur = codex.baseTamed, goal = codex.baseTotal },
    }
end
