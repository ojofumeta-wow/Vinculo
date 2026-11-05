-- Simulación mínima del cliente de WoW para probar Vínculo fuera del juego.
unpack = table.unpack
local DIR = ...

local function stub()
    local obj = {}
    local mt = {}
    mt.__index = function(t, k)
        local f = function(self, ...)
            if k == "CreateTexture" or k == "CreateFontString" then return stub() end
            if k == "GetText" then return rawget(self, "_text") or "" end
            if k == "SetText" then rawset(self, "_text", (...)) return end
            if k == "IsShown" then return rawget(self, "_shown") end
            if k == "Show" then rawset(self, "_shown", true); local s = rawget(self, "_scripts"); if s and s.OnShow then s.OnShow(self) end return end
            if k == "Hide" then rawset(self, "_shown", false) return end
            if k == "SetShown" then rawset(self, "_shown", (...) and true or false) return end
            if k == "SetScript" then local s = rawget(self, "_scripts") or {}; s[select(1, ...)] = select(2, ...); rawset(self, "_scripts", s) return end
            if k == "RegisterEvent" then rawset(self, "_events", rawget(self, "_events") or {}); self._events[...] = true return end
            if k == "UnregisterEvent" then return end
            if k == "GetStringHeight" then return 100 end
            if k == "GetStringWidth" then return #(rawget(self, "_text") or "") * 7 end
            if k == "GetHighlightTexture" then local h = rawget(self, "_hl") or stub(); rawset(self, "_hl", h) return h end
            if k == "GetFrameLevel" then return 1 end
            if k == "GetChecked" then return rawget(self, "_checked") end
            if k == "SetChecked" then rawset(self, "_checked", (...)) return end
            if k == "HasFocus" then return rawget(self, "_focus") or false end
            if k == "SetFocus" then rawset(self, "_focus", true) return end
            if k == "ClearFocus" then rawset(self, "_focus", false) return end
            return nil
        end
        rawset(t, k, f)
        return f
    end
    return setmetatable(obj, mt)
end

local frames = {}
function CreateFrame() local f = stub(); frames[#frames + 1] = f; return f end
UIParent = stub()
UISpecialFrames = {}
tinsert = table.insert
StaticPopupDialogs = {}
SlashCmdList = {}
YES, NO = "Sí", "No"
local printed = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) printed[#printed + 1] = m; print("[chat] " .. m) end }
local sent = {}
function SendChatMessage(msg, ch) sent[#sent + 1] = { msg, ch } end
function GetLocale() return "esES" end
local clock = os.time()
function date(fmt, t) return os.date(fmt, t or clock) end
function time() return clock end
GameTooltip = stub()
local now = 1000
function GetTime() return now end
C_Timer = { NewTicker = function() end, After = function(_, fn) fn() end }

-- Estado simulado
local S = {
    pet = nil, zone = "Bosque de Elwynn", instance = false, kind = "none",
    inCombat = false, playerDead = false, secretInCombat = true,
}
local SECRET = setmetatable({}, { __name = "secret" })
function issecretvalue(v) return v == SECRET end
local function petRead(v)
    if S.inCombat and S.secretInCombat then return SECRET end
    return v
end
function UnitClass() return "Cazador", "HUNTER" end
local function targetRead(v) if S.targetSecret then return SECRET end return v end
function UnitName(u)
    if u == "player" then return "Javier" end
    if u == "target" then return S.target and targetRead(S.target.name) end
    return S.pet and petRead(S.pet.name)
end
function UnitIsPlayer(u) return u == "player" end
function UnitCanAttack(_, u) return u == "target" and S.target ~= nil end
function UnitCreatureType(u) return S.target and targetRead(S.target.kind) end
function GetRealmName() return "Forever" end
function UnitExists(u) return (u == "pet" and S.pet ~= nil) or (u == "target" and S.target ~= nil) end
function UnitGUID(u) return S.pet and petRead(S.pet.guid) end
function UnitCreatureFamily(u)
    if u == "target" then return S.target and targetRead(S.target.family) end
    return S.pet and petRead(S.pet.family)
end
function UnitLevel() return S.pet and petRead(S.pet.level) end
function UnitIsDead(u) return S.pet and S.pet.dead or false end
function UnitIsDeadOrGhost() return S.playerDead end
function GetPetLoyalty() return S.pet and ("Nivel de lealtad " .. S.pet.loyalty) end
function GetRealZoneText() return S.zone end
-- Mapas: zona (tipo 3) dentro de un continente (tipo 2)
local MAPS = { [10] = { mapType = 3, name = "Páramos de Poniente", parentMapID = 20 },
    [20] = { mapType = 2, name = "Reinos del Este", parentMapID = 0 } }
C_Map = {
    GetBestMapForUnit = function() return S.mapId end,
    GetMapInfo = function(id) return MAPS[id] end,
    GetMapChildrenInfo = function(id)
        if id == 946 then return { { mapID = 20, name = "Reinos del Este", mapType = 2 } } end
        if id == 20 then return { { mapID = 10, name = "Páramos de Poniente", mapType = 3 } } end
        return {}
    end,
    OpenWorldMap = function(id) S.openedMap = id end,
    GetPlayerMapPosition = function() return { GetXY = function() return 0.4, 0.5 end } end,
}
function IsInInstance() return S.instance, S.kind end
function GetInstanceInfo() return S.zone end
function IsInGroup() return true end
function IsInRaid() return false end

-- Carga del addon
local ns = {}
for _, file in ipairs({ "Locale.lua", "Data.lua", "Zones.lua", "Skills.lua", "Foods.lua", "Core.lua", "Achievements.lua", "Extras.lua", "UI.lua" }) do
    local chunk = assert(loadfile(DIR .. "/" .. file))
    chunk("Vinculo", ns)
end

local addonFrame = frames[1]
local function fire(event, ...) addonFrame._scripts.OnEvent(addonFrame, event, ...) end

local function check(cond, msg)
    if not cond then error("FALLO: " .. msg, 2) end
    print("ok - " .. msg)
end

fire("ADDON_LOADED", "Vinculo")
fire("PLAYER_LOGIN")
check(addonFrame._events.UNIT_PET, "registra eventos de cazador")

-- Domesticar una bestia nueva
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 1515)
S.pet = { guid = "Pet-0-1-1-1-3823-0A1B2C", name = "Colmillo", family = "Lobo", level = 10, loyalty = 1 }
fire("UNIT_PET", "player")
local pet = ns:GetPet(ns.activeKey)
check(pet and pet.name == "Colmillo", "crea la ficha al invocar")
check(pet.tamed, "detecta que es recién domesticada")
check(pet.timeline[1].e == "EV_TAMED", "primera entrada: domesticación")
check(pet.zoneCount == 1, "cuenta la zona inicial")

-- Combate superado (con valores secretos en combate)
fire("PLAYER_REGEN_DISABLED"); S.inCombat = true; now = now + 20
fire("UNIT_HEALTH", "pet")
S.inCombat = false; fire("PLAYER_REGEN_ENABLED")
check(pet.stats.victories == 1, "cuenta un combate superado")
check(pet.achievements.victory_1, "otorga el logro Primera presa")
check(math.abs(pet.stats.timeCombat - 20) < 0.01, "suma tiempo en combate")

-- Subida de nivel y lealtad
S.pet.level = 11; S.pet.loyalty = 2
fire("UNIT_LEVEL", "pet")
check(pet.level == 11, "registra la subida de nivel")
local hasLoyalty = false
for _, e in ipairs(pet.timeline) do if e.e == "EV_LOYALTY" then hasLoyalty = true end end
check(hasLoyalty, "registra el aumento de lealtad")

-- Muere en combate (desaparece) y la revivimos
fire("PLAYER_REGEN_DISABLED"); S.inCombat = true
local saved = S.pet; S.pet = nil
fire("UNIT_PET", "player")
S.inCombat = false; fire("PLAYER_REGEN_ENABLED")
check(pet.stats.falls == 1, "detecta la caída en combate")
check(pet.stats.victories == 1, "no cuenta como combate superado")
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 982)
check(pet.stats.falls == 1 and pet.stats.revives == 1, "revivir no duplica la caída")
S.pet = saved; fire("UNIT_PET", "player")

-- Retirarla con Retirar mascota en combate no cuenta como caída
fire("PLAYER_REGEN_DISABLED"); S.inCombat = true
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 2641)
S.pet = nil; fire("UNIT_PET", "player")
S.inCombat = false; fire("PLAYER_REGEN_ENABLED")
check(pet.stats.falls == 1, "retirarla no cuenta como caída")
S.pet = saved; fire("UNIT_PET", "player")

-- Revivir fuera de combate sin haber visto la caída la apunta
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 982)
check(pet.stats.falls == 2 and pet.stats.revives == 2, "revivir sin caída vista apunta la caída")

-- Comer, mazmorra y jefe
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 6991)
check(pet.stats.feeds == 1, "cuenta las comidas")
S.zone = "Las Minas de la Muerte"; S.instance = true; S.kind = "party"
fire("ZONE_CHANGED_NEW_AREA")
check(pet.dungeonCount == 1, "registra la mazmorra")
fire("PLAYER_REGEN_DISABLED"); S.inCombat = true
fire("ENCOUNTER_END", 1, "Edwin VanCleef", 1, 5, 1)
S.inCombat = false; fire("PLAYER_REGEN_ENABLED")
check(pet.stats.bosses == 1 and pet.achievements.boss_1, "cuenta el jefe y su logro")
fire("ENCOUNTER_END", 1, SECRET, 1, 5, 1)
check(pet.stats.bosses == 1, "ignora nombres de jefe secretos")

-- Renombrar
S.instance = false; S.kind = "none"; S.zone = "Páramos de Poniente"; S.mapId = 10
fire("ZONE_CHANGED_NEW_AREA")
check(pet.zoneContinent and pet.zoneContinent["Páramos de Poniente"] == "Reinos del Este", "apunta el continente de la zona")
S.pet.name = "Rayo"; fire("UNIT_NAME_UPDATE", "pet")
check(pet.name == "Rayo", "detecta el cambio de nombre")

-- Segunda mascota ya existente (no domesticada ahora)
now = now + 1000
S.pet = { guid = "Pet-0-1-1-1-1234-FFFF", name = "Garra", family = "Felino", level = 30, loyalty = 4 }
fire("UNIT_PET", "player")
local pet2 = ns:GetPet(ns.activeKey)
check(pet2 ~= pet and pet2.timeline[1].e == "EV_FIRST_SEEN", "segunda mascota: inicio de diario")

-- Interfaz
SlashCmdList.VINCULO("")
check(ns.UI.frame and ns.UI.frame._shown, "abre la ventana")
ns.UI.tab = "achievements"; ns.UI:Refresh()
check(#ns.UI.achRows == #ns.ACHIEVEMENTS and ns.UI.achHead._text:find(" de " .. #ns.ACHIEVEMENTS), "los logros salen en rejilla con su contador")
check(ns.UI.achNext._text:find("Siguiente"), "indica el siguiente hito: " .. tostring(ns.UI.achNext._text))
ns.UI.achRows[1]._scripts.OnEnter(ns.UI.achRows[1])
ns.UI.tab = "travels"; ns.UI:Refresh()
check(not ns.UI.achHead._shown, "la cabecera de logros se oculta en otras pestañas")
ns.UI.selectedKey = pet.key; ns.UI.tab = "story"; ns.UI:Refresh()
local lastEntry = pet.timeline[#pet.timeline]
check(ns.UI.storyRows[1]._shown and ns.UI.storyRows[1].text._text == ns:FormatEvent(lastEntry), "la Historia empieza por lo más reciente")
check(ns.UI.storyRows[#pet.timeline]._shown and not ns.UI.storyRows[#pet.timeline + 1], "hay una fila por suceso")
ns.UI.tab = "travels"; ns.UI:Refresh()
check(not ns.UI.storyRows[1]._shown, "la línea de tiempo se oculta en otras pestañas")
-- Sin mascotas, el libro se abre en el Bestiario y vuelve a la mascota al llegar la primera
local savedPets, savedOrder = ns.charDB.pets, ns.charDB.order
ns.charDB.pets, ns.charDB.order = {}, {}
ns.UI.selectedKey = nil; ns.UI:Refresh()
check(ns.UI.selectedKey == "wishes" and ns.UI.sinceText._text ~= "", "sin mascotas abre el Bestiario con su aviso")
ns.charDB.pets, ns.charDB.order = savedPets, savedOrder
ns.UI:Refresh()
check(ns.UI.selectedKey ~= "wishes", "al llegar una mascota, deja el Bestiario")
ns.UI.selectedKey = pet.key; ns.UI:Refresh()
check(ns.UI.body._text:find("Reinos del Este %(1%)"), "Viajes agrupa las zonas por continente: " .. tostring(ns.UI.body._text))
ns.UI.tab = "story"; ns.UI:Refresh()
check(ns.UI.nameText._text == "Rayo", "muestra la ficha seleccionada")
print(ns.UI.body._text)

-- Compartir, retirar, borrar
ns:Share(pet)
check(#sent == 1 and sent[1][2] == "PARTY", "comparte en el grupo: " .. sent[1][1])
ns:SetRetired(pet, true)
check(pet.retired, "pasa al recuerdo")
ns:DeletePet(pet)
check(ns:GetPet(pet.key) == nil, "borra la ficha")
ns.UI:Refresh()

-- Comandos
SlashCmdList.VINCULO("avisos")
check(ns.db.opt.toasts == false, "desactiva avisos")
SlashCmdList.VINCULO("avisos")

-- Bienvenida solo una vez
local welcomes = 0
for _, m in ipairs(printed) do if m:find("cargado") then welcomes = welcomes + 1 end end
fire("PLAYER_LOGIN")
local welcomes2 = 0
for _, m in ipairs(printed) do if m:find("cargado") then welcomes2 = welcomes2 + 1 end end
check(welcomes == 1 and welcomes2 == 1, "la bienvenida sale una sola vez")

-- Personalidad
local name = ns:GetPersonality(pet2)
check(name == "Aún os estáis conociendo", "mascota nueva: aún os estáis conociendo")
pet2.stats.victories = 120; pet2.stats.timeTogether = 2 * 3600; pet2.stats.feeds = 20
local pname, pdesc = ns:GetPersonality(pet2)
check(pname == "Glotona", "personalidad glotona: " .. pdesc)
pet2.stats.feeds = 0; pet2.stats.falls = 30
pname, pdesc = ns:GetPersonality(pet2)
check(pname == "Temeraria", "personalidad temeraria: " .. pdesc)
pet2.stats.falls = 0
pname = ns:GetPersonality(pet2)
check(pname == "Fiel", "sin rasgo destacado: fiel")
ns.UI.selectedKey = pet2.key; ns.UI:Refresh()
check(ns.UI.tagText._text:find("Fiel"), "la ficha muestra la personalidad: " .. ns.UI.tagText._text)
ns.db.opt.personality = false; ns.UI:Refresh()
check(not ns.UI.tagText._text:find("Fiel"), "se puede ocultar la personalidad")
ns.db.opt.personality = true

-- Aniversarios
clock = pet2.created + 35 * 86400
local before = #printed
ns:CheckAnniversaries(true)
check(pet2.months == 1 and pet2.achievements.anniv_1m, "primer mes: logro de aniversario")
local annivMsgs = 0
for i = before + 1, #printed do if printed[i]:find("cumplís un mes") then annivMsgs = annivMsgs + 1 end end
check(annivMsgs == 1, "avisa del aniversario en el chat")
before = #printed
ns:CheckAnniversaries(true)
check(#printed == before, "no repite el aniversario")
clock = pet2.created + 400 * 86400
ns:CheckAnniversaries(true)
check(pet2.achievements.anniv_1y and pet2.timeline[#pet2.timeline].a[1] == "un año"
    or (function() for _, e in ipairs(pet2.timeline) do if e.e == "EV_ANNIVERSARY" and e.a[1] == "un año" then return true end end end)(),
    "tras mucho sin jugar celebra solo el último hito (un año)")

-- Resumen semanal
ns:CheckWeek(true) -- foto de esta semana
pet2.stats.victories = pet2.stats.victories + 40
pet2.stats.bosses = pet2.stats.bosses + 3
pet2.stats.timeTogether = pet2.stats.timeTogether + 5 * 3600
before = #printed
ns:CheckWeek(true)
check(#printed == before, "misma semana: no repite el resumen")
clock = clock + 8 * 86400
ns:CheckWeek(true)
local lw = ns.charDB.lastWeek
check(lw and lw.v == 40 and lw.b == 3 and lw.t == 5 * 3600 and #printed == before, "resumen semanal guardado para la ventana")
ns.UI:Week() -- la ventana se construye y se rellena sin errores
ns.UI:Card(pet2)
check(ns.UI.card and ns.UI.week, "tarjeta y resumen se crean")
check(not ns.UI.frame._shown, "abrir la tarjeta cierra el libro")
check(pcall(ns.UI.card._scripts.OnUpdate, ns.UI.card), "la tarjeta se actualiza sin errores (la X sigue al ratón)")
ns.UI.frame:Show()
ns.db.opt.weekly = false
clock = clock + 8 * 86400
before = #printed
ns:CheckWeek(true)
check(#printed == before, "el resumen semanal se puede desactivar")

-- Avisos discretos
ns.db.opt.chatOnly = true
pet2.stats.feeds = 100
ns:CheckAchievements(pet2)
check(printed[#printed]:find("Buena mesa"), "aviso discreto en el chat: " .. printed[#printed])

-- Panel de opciones
check(ns.UI.options ~= nil, "existe el panel de opciones")

-- Botón del minimapa: sale por defecto y la opción lo quita
Minimap = Minimap or stub()
ns.db.opt.minimap = true; ns.UI:UpdateMinimap()
check(ns.UI.minimap:IsShown(), "botón del minimapa visible")
ns.db.opt.minimap = false; ns.UI:UpdateMinimap()
check(not ns.UI.minimap:IsShown(), "la opción quita el botón del minimapa")
ns.db.opt.minimap = true

-- Fallo 1: cambiar de mascota con la nota abierta no copia la nota
local p3 = { guid = "Pet-0-1-1-1-5555-AAAA", name = "Zarpa", family = "Oso", level = 20, loyalty = 3 }
S.pet = p3; fire("UNIT_PET", "player")
pet2.note = "nota de Garra"
ns.UI.selectedKey = pet2.key; ns.UI:Refresh()
ns.UI.note:SetFocus()
ns.UI.note:SetText("nota de Garra!"); ns.UI.note._scripts.OnTextChanged(ns.UI.note)
local rowZarpa
for _, row in ipairs(ns.UI.rows) do if row.key == p3.guid then rowZarpa = row end end
rowZarpa._scripts.OnClick(rowZarpa)
ns.UI.note._scripts.OnTextChanged(ns.UI.note)
check(ns:GetPet(p3.guid).note == "" and ns.UI.note:GetText() == "", "la nota no pasa a otra mascota")
check(pet2.note == "nota de Garra!", "la nota de Garra se conserva")

-- Fallo 2: mascota muerta que sigue existiendo no cuenta dos caídas
local zarpa = ns:GetPet(p3.guid)
fire("PLAYER_REGEN_DISABLED"); S.inCombat = true
p3.dead = true; fire("UNIT_HEALTH", "pet")
S.inCombat = false; fire("PLAYER_REGEN_ENABLED")
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 982)
p3.dead = false
check(zarpa.stats.falls == 1 and zarpa.stats.revives == 1, "muerta pero presente: una sola caída")

-- Fallo 3: tras semanas sin jugar no sale un resumen viejo
ns.db.opt.weekly = true
clock = clock + 8 * 86400
ns:CheckWeek(true)
zarpa.stats.victories = zarpa.stats.victories + 50
clock = clock + 21 * 86400
before = #printed
ns:CheckWeek(true)
check(#printed == before, "no resume semanas antiguas")

-- Forever: C_PetInfo.GetPetLoyalty devuelve solo el nombre
local loyaltyName = "Leal"
C_PetInfo = { GetPetLoyalty = function() return loyaltyName end }
fire("UNIT_PET", "player")
loyaltyName = "Mejor amigo"; fire("UNIT_PET", "player")
check(zarpa.loyaltyText == "Mejor amigo" and zarpa.timeline[#zarpa.timeline].e == "EV_LOYALTY",
    "lealtad por nombre desde C_PetInfo")
C_PetInfo = nil

-- Forever: C_ChatInfo.SendChatMessage, y si falla se muestra en tu chat
local viaC = 0
C_ChatInfo = { SendChatMessage = function() viaC = viaC + 1 end }
ns:Share(zarpa)
check(viaC == 1, "comparte con C_ChatInfo.SendChatMessage")
C_ChatInfo = { SendChatMessage = function() error("restringido") end }
before = #printed
ns:Share(zarpa)
check(#printed == before + 1 and printed[#printed]:find("Zarpa"), "si el envío falla, lo muestra solo a ti")
C_ChatInfo = nil

local function lastEvent(p) return p.timeline[#p.timeline].e end

-- Estado de ánimo y puntos de entrenamiento
local happy = 2
C_PetInfo = {
    GetPetHappiness = function() return happy, 100, 0 end,
    GetPetTrainingPoints = function() return 120, 40 end,
}
fire("UNIT_PET", "player")
check(zarpa.happiness == 2 and zarpa.trainingFree == 80 and zarpa.trainingTotal == 120, "lee ánimo y puntos de entrenamiento")
happy = 1; fire("UNIT_HAPPINESS", "pet")
check(lastEvent(zarpa) == "EV_UNHAPPY", "apunta cuando se pone triste")
happy = 3; fire("UNIT_HAPPINESS", "pet")
check(lastEvent(zarpa) == "EV_HAPPY_AGAIN", "apunta cuando vuelve a estar contenta")
local happyBefore = zarpa.stats.timeHappy or 0
now = now + 30; fire("UNIT_PET", "player")
check(math.abs(zarpa.stats.timeHappy - happyBefore - 30) < 0.01, "suma el tiempo contenta")
ns.UI.selectedKey = zarpa.key; ns.UI.tab = "story"; ns.UI:Refresh()
local statRows = ns.UI:StatRows(zarpa)
local trainingRow
for _, r in ipairs(statRows) do if r[1] == ns.L.STAT_TRAINING then trainingRow = r[2] end end
check(#statRows == 12 and trainingRow == "80 libres de 120" and ns.UI.subText._text:find("Contenta"), "la ficha muestra ánimo y entrenamiento")
-- Medallones y frase: las cifras esenciales, y lo que está a cero no se cuenta
check(ns.UI.medals.victories._text == tostring(zarpa.stats.victories), "el medallón de combates lleva la cifra")
local story = ns.UI.storyText._text
local storyLines = select(2, story:gsub("\n", "")) + 1
check(story:find("levantarse") and storyLines <= 2, "la frase cuenta lo que no es medallón y no pasa de 2 líneas: " .. story)
check(ns.UI.medals.zoneCount._text == tostring(zarpa.zoneCount) and ns.UI.medals.feeds._text == tostring(zarpa.stats.feeds), "la segunda fila de medallones lleva zonas y comidas")
check(not story:find(" 0 "), "la frase no menciona lo que está a cero")
local happyOnly = { stats = { victories = 0, bosses = 0, bestStreak = 0, timeTogether = 100, timeHappy = 100, timeCombat = 0, feeds = 0, falls = 0, revives = 0 }, zoneCount = 0, dungeonCount = 0 }
check(ns.UI:StatStory(happyOnly):find("buen ánimo"), "la frase cuenta el ánimo si es lo único")
local blank = { stats = { victories = 0, bosses = 0, bestStreak = 0, timeTogether = 0, timeCombat = 0, feeds = 0, falls = 0, revives = 0 }, zoneCount = 0, dungeonCount = 0 }
check(ns.UI:StatStory(blank) == ns.L.SUM_NONE, "sin datos, la frase invita a salir a cazar")
ns.UI.statHover._scripts.OnEnter(ns.UI.statHover)

-- Establo: fichas nuevas, unión con la invocada y mascotas abandonadas
local popups = {}
function StaticPopup_Show(name, _, _, data) popups[#popups + 1] = { name = name, data = data } end
pet2.retired = nil
C_StableInfo = {
    GetActivePetList = function() return { { name = "Zarpa", familyName = "Oso", petNumber = 7, icon = 123, level = 20 } } end,
    GetStabledPetList = function() return { { name = "Sombra", familyName = "Felino", petNumber = 9, icon = 456, level = 25, loyaltyName = "Leal" } } end,
}
fire("PET_STABLE_SHOW")
local sombra = ns:GetPet("stable:9")
check(sombra and sombra.timeline[1].e == "EV_STABLE_FOUND" and sombra.stabled and sombra.icon == 456, "crea la ficha de la mascota del establo")
check(zarpa.petNumber == 7 and zarpa.icon == 123 and not zarpa.stabled, "une la invocada con su hueco del establo")
check(#popups == 1 and popups[1].name == "VINCULO_ABANDONED" and popups[1].data == pet2, "pregunta por la que ya no está")
fire("PET_STABLE_UPDATE")
check(#popups == 1, "no pregunta dos veces por la misma")
StaticPopupDialogs.VINCULO_ABANDONED.OnAccept(nil, pet2)
check(pet2.retired, "al aceptar, pasa al recuerdo")

local count = #ns.charDB.order
C_StableInfo = { GetActivePetList = function() error("restringido") end, GetStabledPetList = function() return {} end }
fire("PET_STABLE_SHOW")
check(#ns.charDB.order == count and #popups == 1, "si el establo falla, no toca nada")
C_StableInfo = nil

S.pet = { guid = "Pet-0-1-1-1-999-0009", name = "Sombra", family = "Felino", level = 25, loyalty = 3 }
fire("UNIT_PET", "player")
check(ns:GetPet("stable:9") == nil and ns:GetPet(S.pet.guid) == sombra and #ns.charDB.order == count,
    "al invocarla, la del establo se queda con su ficha")

-- Lista de deseos
check(ns:AddWish("   ") == nil, "un deseo sin nombre no se añade")
local wish = ns:AddWish("Huargo, Montañas de Alterac, el gris del risco")
check(wish.name == "Huargo" and wish.zone == "Montañas de Alterac" and wish.note == "el gris del risco", "añade un deseo con zona y nota")
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 1515)
S.pet = { guid = "Pet-0-1-1-1-1213-0077", name = "Huargo", family = "Lobo", level = 30, loyalty = 1 }
fire("UNIT_PET", "player")
local huargo = ns:GetPet(S.pet.guid)
local wishLogged = false
for _, e in ipairs(huargo.timeline) do if e.e == "EV_WISH_DONE" then wishLogged = true end end
check(wish.done and wishLogged, "al domesticarla, el deseo se cumple")
-- Objetivo seleccionado: se apunta con nombre, zona y familia; sin familia o repetido, no
local oldTarget = S.target
local oldZone = S.zone; S.zone = "Barrens"
S.target = { name = "Jabalí", family = "Jabalí" }
local fromTarget = ns:AddWishFromTarget()
check(fromTarget and fromTarget.name == "Jabalí" and fromTarget.zone == "Barrens" and fromTarget.note == "Jabalí", "añade el objetivo a los deseos")
check(ns:AddWishFromTarget() == nil and #ns:GetWishes() == 2, "no repite un deseo pendiente")
S.target = { name = "Murloc" }
check(ns:AddWishFromTarget() == nil and #ns:GetWishes() == 2, "sin familia no es una bestia")
S.target = { name = "Jabalí", family = "Jabalí" }; S.targetSecret = true
check(ns:AddWishFromTarget() == nil and #ns:GetWishes() == 2, "un objetivo con valores secretos no se apunta")
S.targetSecret = nil; S.target = oldTarget; S.zone = oldZone

ns.UI.selectedKey = "wishes"; ns.UI:Refresh()
check(ns.UI.wishRows[1]._shown and ns.UI.wishInput._shown and ns.UI.wishPage._shown, "los deseos pendientes salen en la página izquierda")
check(ns.UI.wishRows[2]._shown and ns.UI.subText._text == "1 de 2 domesticadas", "los cumplidos salen tras los pendientes, con su contador")
local codex = ns:Codex()
check(ns.UI.codexHead._text:find(" de 17 familias") and #ns.UI.codexCells == #codex.entries, "la derecha enseña el Códice con su contador")
check(ns.UI.body._text:find("Doma 5 familias"), "y debajo, los retos")
ns.UI.codexCells[1]._scripts.OnEnter(ns.UI.codexCells[1])
check(ns.UI.rows.wish._shown and ns.UI.rows.wish.key == "wishes", "hay marcador de deseos en la lista")
ns:RemoveWish(2)
ns.UI:Refresh()
check(#ns:GetWishes() == 1 and not ns.UI.wishEmpty._shown, "borra el pendiente y deja el cumplido")
ns.UI.selectedKey = huargo.key; ns.UI:Refresh()
check(not ns.UI.wishInput._shown and ns.UI.nameText._text == "Huargo", "al volver a una mascota se ocultan los deseos")

-- Códice de familias
check(ns:FamilyKey("Lobo") == "Wolf" and ns:FamilyKey("wolf") == "Wolf" and ns:FamilyKey("Familia nueva") == "Familia nueva", "las familias se reconocen en español e inglés")
local codexNow = ns:Codex()
local byKey = {}
for _, e in ipairs(codexNow.entries) do byKey[e.key] = e end
check(byKey.Wolf.state == "tamed" and byKey.Cat.state == "tamed" and byKey.Bat.state == "unknown", "el Códice marca las familias de tus mascotas y deja en silueta las demás")
S.target = { name = "Murciélago raro", family = "Murciélago" }
fire("PLAYER_REGEN_DISABLED"); S.inCombat = true; S.inCombat = false; fire("PLAYER_REGEN_ENABLED")
check(huargo.preyFamilies and huargo.preyFamilies.Bat == 1, "al ganar cuenta la familia de la presa")
S.target = nil
byKey = {}
for _, e in ipairs(ns:Codex().entries) do byKey[e.key] = e end
check(byKey.Bat.state == "hunted" and byKey.Bat.kills == 1, "una familia derrotada pero no domesticada sale como cazada")
local challenges = ns:Challenges()
check(#challenges == 5 and challenges[1].id == "families" and challenges[1].cur >= 2, "los retos se calculan con lo que ya guarda el diario")

-- Sugerencias de la caja de deseos
local sugg = ns:WishSuggestions(1, "murci")
check(#sugg >= 1 and sugg[1].text == "Murciélago raro", "sugiere bestias ya vistas al escribir su comienzo")
check(#ns:WishSuggestions(1, "zzzz") == 0 and #ns:WishSuggestions(1, "") == 0, "sin coincidencias no sugiere nada")
local someZone = next(huargo.zones)
local zs = ns:WishSuggestions(2, someZone:sub(1, 3):lower())
check(#zs >= 1, "sugiere zonas ya pisadas")
local inputBox = ns.UI.wishInput
inputBox:SetText("Murci")
inputBox._scripts.OnTextChanged(inputBox, true)
check(ns.UI.wishInput:GetText() == "Murci", "escribir no cambia el texto")

-- La tabla real: todas las bestias traen una familia conocida
local knownFam = {}
for _, f in ipairs(ns.FAMILIES) do knownFam[f.key] = true end
local badFam = 0
for _, b in ipairs(ns.BEASTS) do if not knownFam[b.fam] or not b.en then badFam = badFam + 1 end end
check(#ns.BEASTS > 50 and badFam == 0, "la tabla de bestias es válida")
check(#ns:WishSuggestions(1, "lobo") >= 3, "con la tabla real, 'lobo' sugiere lobos")

-- Cada zona de la tabla de bestias tiene nombre propio (no depende de los IDs del cliente)
local noName = 0
for _, b in ipairs(ns.BEASTS) do
    for _, id in ipairs(b.zones or {}) do if not (ns.ZONES[id] and ns.ZONES[id].en) then noName = noName + 1 end end
end
check(noName == 0, "todas las zonas de las bestias tienen nombre")
check(ns:BeastZones("Lobo joven")[1] and ns:BeastZones("Lobo joven")[1].text == "Bosque de Elwynn", "'Lobo joven' vive en el Bosque de Elwynn")

-- Bestias de la tabla propia: "lobo" sugiere lobos concretos
ns.BEASTS = { { en = "Timber Wolf", es = "Lobo de la espesura", fam = "Wolf", lvl = { 1, 10 }, zones = { 10 } },
    { en = "Giant Spider", fam = "Spider", lvl = { 5, 9 } } }
local viaFamily = ns:WishSuggestions(1, "lobo")
check(#viaFamily == 1 and viaFamily[1].hint:find("Lobo"), "escribir la familia sugiere sus bestias")
check(#ns:WishSuggestions(1, "spid") == 1 and #ns:WishSuggestions(1, "timber") == 1, "también por nombre inglés o parte del nombre")
check(ns:BeastZones("lobo de la espesura")[1].text == "Páramos de Poniente", "una bestia dice dónde vive")
check(ns:WishSuggestions(2, "", "Timber Wolf")[1].text == "Páramos de Poniente", "tras escribir la bestia, sin teclear la zona salen sus zonas")
local autoZone = ns:AddWish("Timber Wolf")
check(autoZone.zone == "Páramos de Poniente", "sin zona escrita se apunta la de la tabla")
ns:RemoveWish(#ns:GetWishes())
ns.BEASTS = nil

-- "Ver mapa": resuelve la zona por nombre (sin tildes ni mayúsculas) y abre el mapa
check(ns:ZoneMapID("paramos de PONIENTE") == 10, "la zona se encuentra por nombre aunque falten tildes")
ns:ShowZoneOnMap("Páramos de Poniente")
check(S.openedMap == 10, "el botón abre el mapa en esa zona")
check(ns:ZoneMapID("Zona que no existe") == nil, "una zona desconocida no abre nada")

-- Marcas en el mapa del mundo (sin chincheta nativa en este cliente)
local pinCanvas = CreateFrame("Frame")
pinCanvas.GetWidth = function() return 1000 end
pinCanvas.GetHeight = function() return 700 end
pinCanvas.GetFrameLevel = function() return 3 end
WorldMapFrame = { GetMapID = function() return 10 end, GetCanvas = function() return pinCanvas end }
ns:AddWish("Oso, Páramos de Poniente")
local pinOk, pinErr = pcall(ns.UpdateMapPins, ns, pinCanvas)
check(pinOk, "dibujar las marcas del mapa no falla: " .. tostring(pinErr))
-- Zona aproximada vista desde otro mapa (sin GetMapRectOnMap) y con el interruptor apagado
WorldMapFrame.GetMapID = function() return 11 end
pinOk, pinErr = pcall(ns.UpdateMapPins, ns, pinCanvas)
check(pinOk, "el círculo de zona aproximada se dibuja en otro mapa: " .. tostring(pinErr))
ns.db.opt.mapPins = false
pinOk, pinErr = pcall(ns.UpdateMapPins, ns, pinCanvas)
check(pinOk and ns.db.opt.mapPins == false, "con el interruptor apagado no se dibuja nada: " .. tostring(pinErr))
ns.db.opt.mapPins = true
ns:RemoveWish(#ns:GetWishes())
WorldMapFrame = nil

-- Lugares donde has visto una bestia
S.mapId = 10
S.target = { name = "Lobo joven", family = "Lobo" }
ns:RecordSighting()
ns:RecordSighting()
check(#ns:SpotsFor("Lobo joven") == 1 and ns:SpotsFor("lobo JOVEN")[1].m == 10, "se apunta dónde ves una bestia, una vez por lugar")
S.target = { name = "Murloc" }
ns:RecordSighting()
check(#ns:SpotsFor("Murloc") == 0, "lo que no tiene familia no se apunta")
S.target = nil

-- Aviso y tooltip de bestias de la lista
ns:AddWish("Lobo joven, Bosque de Elwynn")
S.target = { name = "Lobo joven", family = "Lobo" }
local printedBefore = #printed
ns.events.PLAYER_TARGET_CHANGED()
local alertShown = ns.UI.toast and ns.UI.toast.name._text == "Lobo joven" and ns.UI.toast.title._text:find("Ahí está")
check(alertShown, "avisa al ver una bestia de la lista (panel)")
ns.UI.toast.name:SetText("")
ns.events.PLAYER_TARGET_CHANGED()
check(ns.UI.toast.name._text == "", "no repite el aviso enseguida")
local tipLines = {}
local tip = { AddLine = function(_, text) tipLines[#tipLines + 1] = text end, Show = function() end }
ns.AddBeastLines(tip, "target")
check(tipLines[1] == "En tu lista de deseos" and tipLines[2] and tipLines[2]:find("Lobo"), "el tooltip dice si está en la lista y la familia")
ns.db.opt.beastTip = false
local tipOff = {}
ns.AddBeastLines({ AddLine = function(_, x) tipOff[#tipOff + 1] = x end, Show = function() end }, "target")
check(#tipOff == 0, "con la opción apagada el tooltip no añade nada")
ns.db.opt.beastTip = true
ns:RemoveWish(#ns:GetWishes())
S.target = nil

-- Habilidades que enseña la bestia y comida para la mascota
check(ns:BeastSkillsText("Barnabus") == "Mordisco 6", "el tooltip sabe qué habilidad enseña una bestia")
check(ns:BeastSkillsText("Bestia Que No Existe") == nil, "sin datos no inventa nada")
C_PetInfo = { CanPetEatItem = function(id) return id == 117 or id == 4599 end }
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 3 or 0 end,
    GetContainerItemID = function(bag, slot) return ({ 117, 999, 4599 })[slot] end,
    GetContainerItemInfo = function(bag, slot) return { stackCount = slot == 1 and 20 or 5 } end,
}
local oldGetItemInfo = GetItemInfo
GetItemInfo = function(id) return "Objeto " .. id, "", 1, id == 4599 and 15 or 5 end
local fBag, fSlot, fId = ns:BestFood()
check(fId == 4599 and fBag == 0 and fSlot == 3, "elige la comida de más nivel que la mascota puede comer")
C_PetInfo = nil
local oldFamily = UnitCreatureFamily
UnitCreatureFamily = function() return "Lobo" end
local rBag, rSlot, rId = ns:BestFood()
check(rId == 4599 and rSlot == 3, "sin la API de Forever, el respaldo usa la dieta de la familia y la tabla de comidas")
UnitCreatureFamily = function() return "Gorila" end
check(ns:BestFood() == nil, "una familia que no come carne no recibe carne")
UnitCreatureFamily = oldFamily
C_Container = nil
GetItemInfo = oldGetItemInfo

-- Una mascota con la familia en otro idioma (cambio de idioma del cliente) sigue siendo la misma
local langPet = ns:AddPet("Creature-lang-1", "Pelusa", "Lobo", 10)
check(ns:FindPetByName("Pelusa", "Wolf") == langPet, "'Lobo' y 'Wolf' son la misma familia al buscar la ficha")
check(ns:FindPetByName("Pelusa", "Bear") == nil, "otra familia no coincide")
ns:DeletePet(langPet)

-- Exportar
local exported = ns:ExportText(huargo)
check(exported:find("Diario de Huargo") and exported:find("Cumpliste un deseo") and not exported:find("|c"), "exporta la historia en texto plano")
SlashCmdList.VINCULO("exportar")
check(ns.UI.export._shown, "/vinculo exportar abre la ventana")
-- Presas y frases de la mascota
local function fight() fire("PLAYER_REGEN_DISABLED"); S.inCombat = true; S.inCombat = false; fire("PLAYER_REGEN_ENABLED") end
now = now + 1000
local function says()
    local n = 0
    for _, m in ipairs(printed) do if m:find(" dice: ") then n = n + 1 end end
    return n
end
local greeted = false
for _, m in ipairs(printed) do if m:find("^Colmillo dice: ") then greeted = true end end
check(greeted, "saluda al domesticarla")
local sentBefore, saidBefore = #sent, says()
S.target = { name = "Jabalí", kind = "Bestia" }
for _ = 1, 10 do fight() end
check(huargo.prey["Jabalí"] == 10 and huargo.preyTypes["Bestia"] == 10, "cuenta las presas al ganar")
local said = printed[#printed - 0]
check(says() == saidBefore + 1 and said:find("Huargo dice:") and said:find("Jabalí"), "la mascota comenta su presa favorita")
check(ns:GetLikes(huargo)[1] == "Presa favorita: Jabalí (10)", "apunta la presa favorita")
ns.UI.selectedKey = huargo.key; ns.UI:Refresh()
check(ns.UI.likesText._text:find("Jabalí"), "la ficha muestra los gustos")
check(ns:ExportText(huargo):find("Presa favorita"), "los gustos salen al exportar")
S.targetSecret = true; fight(); S.targetSecret = nil
check(huargo.prey["Jabalí"] == 10, "un objetivo secreto no se cuenta")
ns:Say(huargo, "level", 31)
check(says() == saidBefore + 1, "respeta la espera entre frases")
now = now + 31; ns:Say(huargo, "level", 31)
check(says() == saidBefore + 2 and printed[#printed]:find("31"), "habla otra vez pasado el tiempo")
now = now + 1000; ns:Say(sombra, "level", 26)
check(says() == saidBefore + 2, "solo habla la que está contigo")
ns.db.opt.talk = false; ns:Say(huargo, "boss", "Hogger")
check(says() == saidBefore + 2, "se puede desactivar")
ns.db.opt.talk = true
function InCombatLockdown() return true end
ns:Say(huargo, "boss", "Hogger")
check(says() == saidBefore + 2, "en combate no habla")
InCombatLockdown = nil
fire("PLAYER_REGEN_ENABLED")
check(says() == saidBefore + 3 and printed[#printed]:find("Hogger"), "lo dice al acabar el combate")
S.target = { name = "Murloc", kind = "Humanoide" }
for _ = 1, 2 do
    fire("PLAYER_REGEN_DISABLED"); S.pet.dead = true; fire("UNIT_HEALTH", "pet"); fire("PLAYER_REGEN_ENABLED"); S.pet.dead = nil
    fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 982)
end
check(huargo.nemesis["Murloc"] == 2 and ns:GetLikes(huargo)[2]:find("Murloc"), "apunta su némesis")
check(#sent == sentBefore, "nunca envía nada a otros jugadores")
S.target = nil

-- Classic Era: sin C_PetInfo, con las globales antiguas
C_PetInfo = nil
function GetPetHappiness() return 2, 100, 0 end
function GetPetTrainingPoints() return 150, 50 end
fire("UNIT_HAPPINESS", "pet")
check(huargo.happiness == 2 and huargo.trainingFree == 100 and huargo.trainingTotal == 150, "en Era lee ánimo y entrenamiento de las globales")
GetPetHappiness, GetPetTrainingPoints = nil, nil

-- Forever: Domar bestia lanza otro ID de hechizo y la lealtad no sirve de pista
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 1278028)
S.pet = { guid = "Pet-0-1-1-1-3824-0A1B2D", name = "Ocultorroca", family = "Jabalí", level = 8 }
fire("UNIT_PET", "player")
check(ns:GetPet(ns.activeKey).name == "Ocultorroca" and ns:GetPet(ns.activeKey).tamed, "en Forever reconoce Domar bestia por su ID nuevo")

-- Al despedirla, la ficha se actualiza sola: "Descansando" y sin "Aún os estáis conociendo"
local ocul = ns:GetPet(ns.activeKey)
ns.UI.selectedKey = ocul.key; ns.UI:Refresh()
check(ns.UI.tagText._text:find("Contigo ahora") and ns.UI.tagText._text:find("conociendo"), "con ella a tu lado: Contigo ahora y su personalidad")
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 2641)
S.pet = nil; fire("UNIT_PET", "player")
ns.UI.selectedKey = ocul.key; ns.UI:Refresh()
check(ns.UI.tagText._text:find("Descansando") and not ns.UI.tagText._text:find("Contigo ahora") and not ns.UI.tagText._text:find("conociendo"),
    "despedida: sale Descansando y desaparece la personalidad de recién llegada: " .. tostring(ns.UI.tagText._text))

-- Muerta y sin revivir: Caída
ocul.pendingFall = true; ns.UI:Refresh()
check(ns.UI.tagText._text:find("Caída") and not ns.UI.tagText._text:find("Descansando"), "muerta sin revivir: sale Caída")
ocul.pendingFall = nil

-- Borrar la ficha no borra lo aprendido en el Códice
local function tamedCount() local c = ns:Codex(); return c.baseTamed + c.extraTamed end
local before = tamedCount()
ns:DeletePet(ocul)
check(before >= 1 and tamedCount() == before, "borrar una mascota conserva su familia en el Códice")

-- Si el GUID de la mascota cambia, su foto del resumen semanal cambia de clave con ella
local oldKey = huargo.key
ns.charDB.week = { id = -1, pets = { [oldKey] = { v = 1, b = 0, z = 0, t = 0 } } }
S.pet = { guid = "Pet-0-1-1-1-3823-NEWGUID", name = huargo.name, family = huargo.family, level = huargo.level }
fire("UNIT_PET", "player")
check(huargo.key ~= oldKey and ns.charDB.week.pets[huargo.key] and not ns.charDB.week.pets[oldKey], "el resumen semanal sigue a la mascota al cambiar su clave")

-- Una ficha retirada que se vuelve a llamar con otro GUID se reutiliza, no se duplica
local nPets = 0; for _ in pairs(ns.charDB.pets) do nPets = nPets + 1 end
huargo.retired = true; ns.activeKey = nil
S.pet = { guid = "Pet-0-1-1-1-3823-RETIRADA", name = huargo.name, family = huargo.family, level = huargo.level }
fire("UNIT_PET", "player")
local nAfter = 0; for _ in pairs(ns.charDB.pets) do nAfter = nAfter + 1 end
check(nAfter == nPets and not huargo.retired and ns.activeKey == huargo.key, "una ficha retirada se reutiliza al volver con otro GUID")

-- Abandonar la mascota: queda abandonada, no se reactiva y no hay botón de recuperarla
ns.activeKey = huargo.key
ns:PetAbandoned()
ns.UI.selectedKey = huargo.key; ns.UI:Refresh()
check(huargo.abandoned and huargo.retired and ns.activeKey == nil and huargo.timeline[#huargo.timeline].e == "EV_ABANDONED", "abandonar la deja en el recuerdo con su suceso")
check(ns.UI.tagText._text:find("Abandonada") and not ns.UI.tagText._text:find("En el recuerdo"), "la ficha dice Abandonada")
S.pet = { guid = huargo.key, name = huargo.name, family = huargo.family, level = huargo.level }
fire("UNIT_PET", "player") -- la misma mascota aún existe un instante tras abandonarla
check(huargo.retired and ns.activeKey ~= huargo.key, "la abandonada no se reactiva con su mismo GUID")
S.pet = { guid = "Pet-0-1-1-1-3823-OTRO", name = huargo.name, family = huargo.family, level = huargo.level }
fire("UNIT_PET", "player")
check(huargo.retired and ns.activeKey ~= huargo.key, "una mascota nueva con el mismo nombre no reactiva a la abandonada")
S.pet = nil

-- La lealtad de Forever llega como "(Nivel de lealtad 1) Rebelde": la línea solo debe llevar el nombre
huargo.loyaltyText = "(Nivel de lealtad 1) Rebelde"
ns.UI.selectedKey = huargo.key; ns.UI:Refresh()
check(ns.UI.subText._text:find("Rebelde") and not ns.UI.subText._text:find("Nivel de lealtad"), "la línea de nivel no lleva el paréntesis de lealtad: " .. tostring(ns.UI.subText._text))
print("\nTODAS LAS PRUEBAS PASAN")
