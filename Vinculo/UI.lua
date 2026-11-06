local ADDON, ns = ...
local L = ns.L

local UI = {}
ns.UI = UI

-- El libro (Media/Book.tga, 1024×512) se ve a 880×440; las páginas útiles salen de esa imagen.
local WIDTH, HEIGHT = 880, 440
local LEFT_X, RIGHT_X, PAGE_W = 75, 484, 330
local TAB_W, TAB_H, TAB_STEP, TAB_OUT = 150, 45, 48, 60
local MAX_TABS = 7 -- una menos que el hueco: el marcador de deseos va debajo de las mascotas
local WISH_KEY, WISH_ICON = "wishes", "Interface\\Icons\\INV_Scroll_03"
local GREEN = { 0.6, 0.8, 0.2 }
local INK = { 0.24, 0.14, 0.05 }
local INK_SOFT = { 0.42, 0.29, 0.14 }
local INK_RED = { 0.54, 0.16, 0.05 }
local HAPPY_COLOR = { "|cff8a290d", "|cff6b4a24", "|cff2f5a12" }
local DEFAULT_ICON = "Interface\\Icons\\Ability_Hunter_BeastTaming"
-- Retrato 3D: zoom (0 = cuerpo entero, 1 = cara), posición x/y/z y giro en radianes.
-- Se ajusta en vivo con /vinculo modelo zoom x y z giro.

-- Icono de cada familia (los trae el juego). Clave: nombre en minúsculas, en inglés y español.
-- Si un nombre no está, sale el icono por defecto; hay que verificar los dibujos en el juego.
local FAMILY_ICONS = {}
for icon, names in pairs({
    Wolf = { "wolf", "lobo" }, Bear = { "bear", "oso" }, Cat = { "cat", "felino", "gato" },
    Boar = { "boar", "jabalí" }, Crab = { "crab", "cangrejo" }, Crocolisk = { "crocolisk", "crocolisco" },
    Gorilla = { "gorilla", "gorila" }, Hyena = { "hyena", "hiena" }, Owl = { "owl", "búho" },
    Raptor = { "raptor" }, Scorpid = { "scorpid", "escórpido" }, Spider = { "spider", "araña" },
    Bat = { "bat", "murciélago" }, TallStrider = { "tallstrider", "zancaalta" },
    Turtle = { "turtle", "tortuga" }, WindSerpent = { "wind serpent", "serpiente alada" },
    Vulture = { "carrion bird", "carroñero" }, Dragonhawk = { "dragonhawk", "dragonhalcón" },
    Ravager = { "ravager", "devastador" }, Sporebat = { "sporebat", "esporiélago" },
    Moth = { "moth", "polilla" }, Wasp = { "wasp", "avispa" }, Devilsaur = { "devilsaur", "demosaurio" },
    CoreHound = { "core hound", "can del núcleo" }, Silithid = { "silithid", "silítido" },
    Worm = { "worm", "gusano" }, Rhino = { "rhino", "rinoceronte" }, Fox = { "fox", "zorro" },
    Monkey = { "monkey", "mono" }, Dog = { "dog", "perro" },
}) do
    for _, n in ipairs(names) do FAMILY_ICONS[n] = "Interface\\Icons\\Ability_Hunter_Pet_" .. icon end
end

local function petIcon(pet)
    return pet.icon or (pet.family and FAMILY_ICONS[pet.family:lower()]) or DEFAULT_ICON
end
function UI:FamilyIcon(family)
    return family and FAMILY_ICONS[family:lower()] or DEFAULT_ICON
end
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local function panel(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    f:SetBackdropBorderColor(0.4, 0.5, 0.2, 1)
    return f
end

local function text(parent, font, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    if r then fs:SetTextColor(r, g, b) end
    fs:SetJustifyH("LEFT")
    return fs
end

-- Redondea un icono con una máscara propia (Media/Circle, 128 px, borde suave); el cuadrado del icono desaparece.
local function round(tex)
    if tex.SetMask then pcall(tex.SetMask, tex, MEDIA .. "Circle") end
end

-- Fundido de entrada corto con una animación de WoW (sin ficheros). Si el cliente no la admite, no pasa nada.
-- shortcut: solo fundidos, sin retraso entre elementos (con retraso, el elemento se vería antes de desaparecer).
local fades = setmetatable({}, { __mode = "k" })
local function fadeIn(frame, duration)
    if ns.db and ns.db.opt.noanim then return end
    local g = fades[frame]
    if g == nil then
        g = false
        local ok, grp = pcall(frame.CreateAnimationGroup, frame)
        local a = ok and grp and grp.CreateAnimation and grp:CreateAnimation("Alpha")
        if a and a.SetFromAlpha and a.SetToAlpha then
            a:SetFromAlpha(0)
            a:SetToAlpha(1)
            if a.SetSmoothing then a:SetSmoothing("OUT") end
            g = { grp = grp, alpha = a }
        end
        fades[frame] = g
    end
    if g then
        g.alpha:SetDuration(duration)
        g.grp:Stop()
        g.grp:Play()
    end
end

-- Fuentes propias (licencia OFL, en Media/Fonts): IM Fell English para el texto y Caveat para lo que escribe
-- el jugador. Cubren tildes y ñ, así que solo se usan en español e inglés; en otros idiomas, la del cliente.
local locale = GetLocale and GetLocale() or "enUS"
local OWN_FONTS = locale:find("^es") or locale:find("^en")
local BODY_FONT = MEDIA .. "Fonts\\IMFell.ttf"
local NOTE_FONT = MEDIA .. "Fonts\\Caveat.ttf"

-- Cambia la letra de una fuente (FontString o EditBox); si no carga, se queda la que tenía.
local function setFace(fs, path, size)
    if not OWN_FONTS then return end
    local fallback = fs:GetFontObject()
    local ok, loaded = pcall(fs.SetFont, fs, path, size, "")
    if (not ok or loaded == false) and fallback then fs:SetFontObject(fallback) end
end

-- Texto de tinta sobre el pergamino: sin la sombra negra de las fuentes del juego.
local function ink(parent, font, color)
    local fs = text(parent, font, unpack(color or INK))
    fs:SetShadowOffset(0, 0)
    fs.baseFont, fs.inkColor = font or "GameFontHighlight", color or INK
    local _, size = fs:GetFont()
    -- IM Fell tiene la caja baja: un punto más para que se lea igual.
    if size then setFace(fs, BODY_FONT, size + 1) end
    return fs
end

-- Números sueltos (fechas, contadores, cifras): IM Fell los dibuja "antiguos" y un 0 parece una o.
-- En frases quedan bien; solos, vuelven a la fuente del juego.
local function numeric(fs)
    if not fs.baseFont then return fs end
    -- SetFont explícito: SetFontObject no siempre deshace un SetFont anterior.
    local obj = _G[fs.baseFont]
    local path, size, flags
    if obj and obj.GetFont then path, size, flags = obj:GetFont() end
    if path then pcall(fs.SetFont, fs, path, size, flags or "") else fs:SetFontObject(fs.baseFont) end
    fs:SetShadowOffset(0, 0)
    fs:SetTextColor(unpack(fs.inkColor))
    return fs
end

-- Morpheus, la letra de los títulos de libros del juego; si no carga, se queda la normal.
local TITLE_FONT = "Fonts\\MORPHEUS.TTF"
local function titleFont(fs, size)
    local fallback = fs:GetFontObject()
    local ok, loaded = pcall(fs.SetFont, fs, TITLE_FONT, size, "")
    -- Algunos clientes no devuelven nada al acertar: solo un false claro es fallo.
    if (not ok or loaded == false) and fallback then fs:SetFontObject(fallback) end
end

local function line(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetColorTexture(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.45)
    t:SetHeight(1)
    return t
end

local function date_(t)
    return date("%d/%m/%Y", t)
end

------------------------------------------------------------------------
-- Ventana principal
------------------------------------------------------------------------

function UI:Build()
    if self.frame then return end

    -- Marco vacío que se mueve; dentro, las pestañas de mascota quedan debajo del libro.
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "VinculoFrame")
    _G.VinculoFrame = f
    f:SetScript("OnShow", function() UI:Refresh(); fadeIn(f, 0.22) end)
    f:SetScript("OnHide", function() UI:SyncFeed() end)
    self.frame = f

    local book = CreateFrame("Frame", nil, f)
    book:SetAllPoints()
    book:SetFrameLevel(f:GetFrameLevel() + 5)
    book:EnableMouse(true)
    book:RegisterForDrag("LeftButton")
    -- En combate no se mueve el libro: el botón de alimentar (protegido) no puede seguirlo y no se puede reanclar.
    book:SetScript("OnDragStart", function()
        if InCombatLockdown and InCombatLockdown() then return end
        f:StartMoving()
        f:SetScript("OnUpdate", function() UI:PlaceFeed() end)
    end)
    book:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        f:SetScript("OnUpdate", nil)
        UI:PlaceFeed()
    end)
    local bg = book:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(MEDIA .. "Book")
    self.book = book

    -- Cerrar y ajustes: dibujados a tinta en la esquina de la página derecha
    local function inkIcon(file, tip, drawn)
        local b = CreateFrame("Button", nil, book)
        b:SetSize(16, 16)
        local t = b:CreateTexture(nil, "ARTWORK")
        t:SetAllPoints()
        t:SetTexture(file)
        -- Las cruces ya vienen dibujadas a tinta; los iconos del juego se tiñen.
        if drawn then t:SetAlpha(0.7) else t:SetDesaturated(true); t:SetVertexColor(unpack(INK_SOFT)) end
        b:SetScript("OnEnter", function(s)
            if drawn then t:SetAlpha(1) else t:SetVertexColor(unpack(INK_RED)) end
            GameTooltip:SetOwner(s, "ANCHOR_LEFT")
            GameTooltip:SetText(tip)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function()
            if drawn then t:SetAlpha(0.7) else t:SetVertexColor(unpack(INK_SOFT)) end
            GameTooltip:Hide()
        end)
        return b
    end
    local close = inkIcon(MEDIA .. "Cross", CLOSE or "Close", true)
    close:SetPoint("TOPRIGHT", book, "TOPLEFT", RIGHT_X + PAGE_W + 2, -34)
    close:SetScript("OnClick", function() f:Hide() end)

    local gear = inkIcon("Interface\\Buttons\\UI-OptionsButton", L.OPTIONS)
    gear:SetPoint("RIGHT", close, "LEFT", -6, 0)
    gear:SetScript("OnClick", function() UI.options:SetShown(not UI.options:IsShown()); UI:Refresh() end)

    -- Tarjeta para compartir: icono junto a los ajustes, visible solo con una mascota seleccionada.
    local cardIcon = inkIcon(MEDIA .. "CardIcon", L.CARD_TIP, true)
    cardIcon:SetPoint("RIGHT", gear, "LEFT", -6, 0)
    cardIcon:SetScript("OnClick", function() UI:Card(ns:GetPet(UI.selectedKey)) end)
    self.cardIcon = cardIcon

    self:BuildList()
    self:BuildPage()
    self:BuildOptions()
end

local OPTION_LIST = {
    { "toasts", L.OPT_TOASTS },
    { "chatOnly", L.OPT_CHATONLY },
    { "sound", L.OPT_SOUND },
    { "weekly", L.OPT_WEEKLY },
    { "anniv", L.OPT_ANNIV },
    { "personality", L.OPT_PERSONALITY },
    { "talk", L.OPT_TALK },
    { "minimap", L.OPT_MINIMAP },
    { "beastAlert", L.OPT_ALERT },
    { "beastTip", L.OPT_TIP },
    { "mapPins", L.OPT_PINS },
    { "noanim", L.OPT_NOANIM },
}

-- Los ajustes son una página más del libro: ocupan la derecha en lugar de la pestaña.
function UI:BuildOptions()
    local o = CreateFrame("Frame", nil, self.book)
    o:SetAllPoints(self.tabBox)
    o:SetFrameLevel(self.tabBox:GetFrameLevel() + 2)
    o:Hide()

    local checks = {}
    for i, opt in ipairs(OPTION_LIST) do
        local cb = CreateFrame("CheckButton", nil, o, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("TOPLEFT", -2, -2 - (i - 1) * 17.5) -- 12 ajustes caben en el recuadro de la página
        -- Casilla dibujada a tinta (Media/CheckOff y CheckOn), sin las texturas del juego
        for _, setter in ipairs({ "SetNormalTexture", "SetPushedTexture", "SetCheckedTexture", "SetDisabledCheckedTexture" }) do
            pcall(cb[setter], cb, "")
        end
        -- Con "" el cliente puede dejar la marca amarilla de la plantilla (desplazada): se esconde del todo.
        for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetCheckedTexture", "GetDisabledCheckedTexture" }) do
            local ok, tex = pcall(cb[getter], cb)
            if ok and type(tex) == "table" and tex.SetAlpha then tex:SetAlpha(0) end
        end
        cb.box = cb:CreateTexture(nil, "ARTWORK")
        cb.box:SetAllPoints()
        local label = ink(cb, "GameFontHighlight")
        label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        label:SetWidth(PAGE_W - 30)
        label:SetJustifyH("LEFT")
        label:SetText(opt[2])
        cb:SetScript("OnClick", function(s)
            ns.db.opt[opt[1]] = s:GetChecked() and true or false
            s.box:SetTexture(MEDIA .. (s:GetChecked() and "CheckOn" or "CheckOff"))
            UI:UpdateMinimap()
            UI:Refresh()
        end)
        checks[opt[1]] = cb
    end
    o:SetScript("OnShow", function()
        for key, cb in pairs(checks) do
            cb:SetChecked(ns.db.opt[key])
            cb.box:SetTexture(MEDIA .. (ns.db.opt[key] and "CheckOn" or "CheckOff"))
        end
    end)
    self.options = o
end

-- Las mascotas son pestañas de cuero que asoman por la izquierda del libro.
function UI:BuildList()
    self.rows = {}
    self.listOffset = 0

    local empty = ink(self.book, "GameFontHighlight", INK_SOFT)
    empty:SetPoint("TOPLEFT", LEFT_X, -150)
    empty:SetWidth(PAGE_W)
    empty:SetJustifyH("CENTER")
    empty:SetText(L.NO_PETS)
    self.listEmpty = empty
end

local function rowAt(index)
    local row = UI.rows[index]
    if row then return row end
    row = CreateFrame("Button", nil, UI.frame)
    row:SetSize(TAB_W, TAB_H)
    row:SetFrameLevel(UI.frame:GetFrameLevel() + 1)

    -- Tab.tga: la tira ocupa 155 de 256 filas. El hueco del anillo está al 14,5 % del ancho.
    local leather = row:CreateTexture(nil, "BORDER")
    leather:SetAllPoints()
    leather:SetTexture(MEDIA .. "Tab")
    leather:SetTexCoord(0, 1, 0, 155 / 256)
    row.leather = leather

    row.icon = row:CreateTexture(nil, "BACKGROUND")
    row.icon:SetSize(TAB_H * 0.6, TAB_H * 0.6) -- algo mayor que el hueco: el anillo de latón tapa el borde
    round(row.icon)
    row.icon:SetPoint("CENTER", row, "LEFT", TAB_W * 0.1436, 0.4) -- centro del hueco medido en Tab.tga (73,5 / 76 de 512x155)

    row.glow = row:CreateTexture(nil, "OVERLAY")
    row.glow:SetSize(TAB_H * 0.9, TAB_H * 0.9)
    row.glow:SetPoint("CENTER", row.icon)
    row.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    row.glow:SetBlendMode("ADD")

    row:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    row:GetHighlightTexture():ClearAllPoints()
    row:GetHighlightTexture():SetAllPoints(row.icon)

    row:SetScript("OnClick", function(self)
        -- Sin esto, la nota abierta de otra mascota se guardaría en la nueva.
        UI.note:ClearFocus()
        UI.options:Hide()
        UI.selectedKey = self.key
        UI.autoWish = nil
        UI:Refresh()
        fadeIn(UI.statBox, 0.2)
        fadeIn(UI.tabBox, 0.2)
    end)
    row:SetScript("OnEnter", function(self)
        if self.key == WISH_KEY then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(L.TAB_BESTIARY)
            GameTooltip:AddLine(L.WISH_INTRO, 1, 1, 1)
            GameTooltip:Show()
            return
        end
        local pet = ns:GetPet(self.key)
        if not pet then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(pet.name)
        GameTooltip:AddLine((pet.family or L.FAMILY_UNKNOWN) .. " · " .. L.LEVEL:format(pet.level or 1), 1, 1, 1)
        if pet.retired then GameTooltip:AddLine(L.RETIRED_TAG, 0.6, 0.6, 0.6)
        elseif self.key == ns.activeKey then GameTooltip:AddLine(L.ACTIVE_TAG, GREEN[1], GREEN[2], GREEN[3]) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Con más de MAX_TABS mascotas, la rueda del ratón pasa pestañas.
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta)
        local max = math.max(0, #UI.listKeys - MAX_TABS)
        UI.listOffset = math.min(math.max(UI.listOffset - delta, 0), max)
        UI:RefreshList(UI.listKeys)
    end)
    UI.rows[index] = row
    return row
end

-- Medallón de logro: lo usan la rejilla de Logros y la fila de sellos de la página izquierda.
local ACH_COLS, ACH_CELL_W, ACH_CELL_H, ACH_RING = 6, 52, 44, 38

local function achValue(cur, goal, seconds)
    if seconds then return ns.FormatTime(cur), ns.FormatTime(goal) end
    return tostring(cur), tostring(goal)
end

local function achCell(parent)
    local cell = CreateFrame("Button", nil, parent)
    cell:SetSize(ACH_CELL_W, ACH_CELL_H)
    cell.icon = cell:CreateTexture(nil, "BACKGROUND")
    cell.icon:SetSize(ACH_RING * 0.82, ACH_RING * 0.82)
    round(cell.icon)
    cell.icon:SetPoint("CENTER")
    cell.ring = cell:CreateTexture(nil, "ARTWORK")
    cell.ring:SetSize(ACH_RING, ACH_RING)
    cell.ring:SetPoint("CENTER")
    cell.ring:SetTexture(MEDIA .. "Ring64")
    cell:SetScript("OnEnter", function(c)
        local title, desc = ns:AchievementText(c.id)
        GameTooltip:SetOwner(c, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        GameTooltip:AddLine(desc, 1, 1, 1, true)
        if c.earned then
            GameTooltip:AddLine(L.ACH_EARNED:format(date_(c.earned)), GREEN[1], GREEN[2], GREEN[3])
        elseif c.cur then
            local cv, gv = achValue(c.cur, c.goal, c.seconds)
            GameTooltip:AddLine(L.ACH_PROGRESS:format(cv, gv), 1, 0.82, 0)
        end
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return cell
end

local function paintAch(cell, pet, a)
    local earned = pet.achievements[a.id]
    local _, cur, goal, seconds = a.check(pet)
    cell.id, cell.earned, cell.cur, cell.goal, cell.seconds = a.id, earned or false, cur or false, goal or false, seconds or false
    cell.icon:SetTexture(a.icon)
    cell.icon:SetDesaturated(not earned)
    cell.icon:SetAlpha(earned and 1 or 0.45)
    cell.ring:SetDesaturated(not earned)
    -- Apagado con color y no con transparencia: así el anillo sigue tapando las esquinas del icono.
    cell.ring:SetAlpha(1)
    local shade = earned and 1 or 0.7
    cell.ring:SetVertexColor(shade, shade, shade)
end

function UI:BuildPage()
    local page = self.book

    -- Página izquierda: retrato en el anillo, nombre y datos básicos
    local RING = 77
    local portrait = CreateFrame("Frame", nil, page)
    portrait:SetSize(RING, RING)
    portrait:SetPoint("TOPLEFT", LEFT_X - 6, -34)

    -- El hueco del anillo mide el 60 % del ancho; la máscara redonda lo llena sin esquinas.
    local hole = RING * 0.74 -- mayor que el hueco real: el aro tapa el borde del fondo
    local dark = portrait:CreateTexture(nil, "BACKGROUND")
    dark:SetSize(hole, hole)
    dark:SetPoint("CENTER")
    dark:SetTexture(MEDIA .. "Circle") -- ya es un círculo: la máscara no funciona con colores lisos
    dark:SetVertexColor(0.1, 0.07, 0.04, 1)

    local icon = portrait:CreateTexture(nil, "ARTWORK")
    icon:SetSize(hole, hole)
    icon:SetPoint("CENTER")
    self.portraitIcon = icon
    round(icon)

    local ringFrame = CreateFrame("Frame", nil, portrait)
    ringFrame:SetAllPoints()
    ringFrame:SetFrameLevel(portrait:GetFrameLevel() + 5)
    local ring = ringFrame:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ring:SetTexture(MEDIA .. "Ring128")

    local name = ink(page, "GameFontNormalHuge")
    titleFont(name, 26)
    name:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 12, -8)
    name:SetPoint("RIGHT", page, "LEFT", LEFT_X + PAGE_W, 0)
    self.nameText = name

    local sub = numeric(ink(page, "GameFontHighlight"))
    sub:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    sub:SetPoint("RIGHT", name) -- sin esto, una línea larga se sale de la página y pisa el lomo
    sub:SetWordWrap(false)
    self.subText = sub

    local since = numeric(ink(page, "GameFontHighlightSmall", INK_SOFT))
    since:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -4)
    since:SetPoint("RIGHT", name)
    self.sinceText = since

    local tag = ink(page, "GameFontNormalSmall", INK_RED)
    tag:SetPoint("TOPLEFT", since, "BOTTOMLEFT", 0, -4)
    self.tagText = tag

    -- Zona invisible sobre la etiqueta para explicar la personalidad al pasar el ratón.
    local tagHover = CreateFrame("Frame", nil, page)
    tagHover:SetAllPoints(tag)
    tagHover:SetScript("OnEnter", function(s)
        if not UI.personalityDesc then return end
        GameTooltip:SetOwner(s, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(L.PERSONALITY_TITLE .. ": " .. UI.personalityName)
        GameTooltip:AddLine(UI.personalityDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tagHover:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Estadísticas: cuatro medallones con lo esencial, una frase con el resto y la lista entera al pasar el ratón
    local statBox = CreateFrame("Frame", nil, page)
    statBox:SetAllPoints()
    self.statBox = statBox
    local MEDALS = {
        { "victories", "Ability_Hunter_BeastMastery", L.MEDAL_VICTORIES },
        { "bosses", "INV_Misc_Head_Dragon_01", L.MEDAL_BOSSES },
        { "timeTogether", "INV_Misc_PocketWatch_01", L.MEDAL_TIME },
        { "bestStreak", "Spell_Holy_DivineIntervention", L.MEDAL_STREAK },
        { "zoneCount", "INV_Misc_Map_01", L.MEDAL_ZONES },
        { "dungeonCount", "INV_Misc_Map02", L.MEDAL_DUNGEONS },
        { "feeds", "INV_Misc_Food_14", L.MEDAL_FEEDS },
        { "falls", "INV_Misc_Bone_HumanSkull_01", L.MEDAL_FALLS },
    }
    self.medals = {}
    local STEP = PAGE_W / 4
    for i, m in ipairs(MEDALS) do
        local cx = LEFT_X + STEP * ((i - 1) % 4 + 0.5)
        local cy = -150 - math.floor((i - 1) / 4) * 84
        local icon = statBox:CreateTexture(nil, "BACKGROUND")
        icon:SetSize(38, 38) -- más grande que el hueco: el anillo tapa el borde propio del icono
        icon:SetPoint("CENTER", page, "TOPLEFT", cx, cy)
        round(icon)
        icon:SetTexture("Interface\\Icons\\" .. m[2])
        local ring = statBox:CreateTexture(nil, "ARTWORK")
        ring:SetSize(46, 46)
        ring:SetPoint("CENTER", icon)
        ring:SetTexture(MEDIA .. "Ring64")
        local value = numeric(ink(statBox, "GameFontNormalLarge"))
        value:SetPoint("TOP", page, "TOPLEFT", cx, cy - 28)
        local label = ink(statBox, "GameFontHighlightSmall", INK_SOFT)
        label:SetPoint("TOP", value, "BOTTOM", 0, -1)
        label:SetText(m[3])
        self.medals[m[1]] = value
    end

    local story = ink(statBox, "GameFontHighlight")
    story:SetPoint("TOPLEFT", page, "TOPLEFT", LEFT_X + 4, -302)
    story:SetWidth(PAGE_W - 8)
    story:SetJustifyH("LEFT")
    story:SetJustifyV("TOP")
    story:SetSpacing(4)
    self.storyText = story

    -- Zona sensible sobre todo el bloque: al pasar el ratón sale la lista completa
    local hover = CreateFrame("Frame", nil, statBox)
    hover:SetPoint("TOPLEFT", page, "TOPLEFT", LEFT_X, -126)
    hover:SetSize(PAGE_W, 214)
    hover:EnableMouse(true)
    hover:SetScript("OnEnter", function(s)
        local pet = ns:GetPet(UI.selectedKey)
        if not pet then return end
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:SetText(pet.name)
        for _, r in ipairs(UI:StatRows(pet)) do GameTooltip:AddDoubleLine(r[1], tostring(r[2]), 1, 1, 1, 1, 0.82, 0) end
        GameTooltip:Show()
    end)
    hover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.statHover = hover


    -- Página derecha: las pestañas son títulos escritos; la elegida, en tinta oscura y subrayada
    self.tabs = {}
    local tabNames = { { "story", L.TAB_STORY }, { "achievements", L.TAB_ACHIEVEMENTS },
        { "travels", L.TAB_TRAVELS } }
    local prev
    for _, t in ipairs(tabNames) do
        local b = CreateFrame("Button", nil, page)
        local label = ink(b, "GameFontNormalLarge")
        titleFont(label, 19)
        label:SetPoint("LEFT")
        label:SetText(t[2])
        b.label = label
        b:SetSize(label:GetStringWidth() + 4, 24)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 14, 0)
        else b:SetPoint("TOPLEFT", RIGHT_X, -36) end
        b.underline = line(b)
        b.underline:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, 2)
        b.underline:SetPoint("RIGHT", label)
        b.underline:SetHeight(2)
        b:SetScript("OnClick", function()
            if UI.tab ~= t[1] then fadeIn(UI.tabBox, 0.2) end -- como pasar una hoja
            UI.tab = t[1]; UI.options:Hide(); UI:Refresh()
        end)
        b:SetScript("OnEnter", function(s) if UI.tab ~= t[1] then s.label:SetTextColor(unpack(INK)) end end)
        b:SetScript("OnLeave", function() UI:Refresh() end)
        self.tabs[t[1]] = b
        prev = b
    end
    self.tab = "story"
    -- En la vista de deseos ocupa el sitio de las pestañas.
    local wt = ink(page, "GameFontNormalLarge")
    titleFont(wt, 19)
    wt:SetPoint("TOPLEFT", RIGHT_X, -36)
    wt:SetText(L.CODEX_TITLE)
    wt:Hide()
    self.wishTitle = wt
    local head = line(page)
    self.head = head
    head:SetPoint("TOPLEFT", RIGHT_X, -66)
    head:SetWidth(PAGE_W)

    -- Contenido desplazable de la pestaña (acaba antes de la esquina quemada)
    local box = CreateFrame("Frame", nil, page)
    box:SetPoint("TOPLEFT", RIGHT_X, -74)
    box:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", RIGHT_X + PAGE_W, -288)

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -14, 0)
    -- Barra de tinta, fina y sin flechas (la rueda del ratón sigue moviendo el texto).
    local bar = scroll.ScrollBar
    if type(bar) == "table" then
        bar:ClearAllPoints()
        bar:SetPoint("TOPRIGHT", box, "TOPRIGHT", -2, -2)
        bar:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -2, 2)
        bar:SetWidth(6)
        for _, c in ipairs({ bar:GetChildren() }) do
            c:Hide()
            c:SetScript("OnShow", c.Hide) -- la plantilla las vuelve a mostrar al cambiar el contenido
        end
        bar:SetWidth(8)
        self.scrollBar = bar
        -- Carril: una línea de tinta, igual que las del resto del libro
        local track = bar:CreateTexture(nil, "BACKGROUND")
        track:SetPoint("TOP")
        track:SetPoint("BOTTOM")
        track:SetWidth(2)
        track:SetColorTexture(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.35)
        local thumb = bar:GetThumbTexture()
        if thumb then
            thumb:SetTexture(MEDIA .. "ScrollThumb")
            thumb:SetTexCoord(0, 48 / 64, 0, 108 / 128)
            thumb:SetSize(10, 22)
        end
    end
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnSizeChanged", function(s, w) child:SetWidth(w) end)
    self.content = child
    self.tabBox = box

    local body = numeric(ink(child, "GameFontHighlight"))
    body:SetPoint("TOPLEFT")
    body:SetPoint("RIGHT")
    body:SetJustifyV("TOP")
    body:SetSpacing(3)
    self.body = body
    self.achRows = {}
    self.storyRows = {}
    self.wishRows = {}

    -- Deseos pendientes: en la página izquierda, con su línea para escribir
    local wp = CreateFrame("Frame", nil, page)
    wp:SetAllPoints()
    wp:Hide()
    self.wishPage = wp
    local wish = CreateFrame("EditBox", nil, wp)
    wish:SetFontObject("GameFontHighlight")
    setFace(wish, NOTE_FONT, 15)
    wish:SetTextColor(unpack(INK))
    wish:SetShadowOffset(0, 0)
    wish:SetHeight(20)
    wish:SetPoint("TOPLEFT", LEFT_X, -104)
    wish:SetWidth(PAGE_W)
    wish:SetAutoFocus(false)
    wish:SetMaxLetters(120)
    local wishLine = line(wish)
    wishLine:SetPoint("BOTTOMLEFT", 0, 1)
    wishLine:SetPoint("BOTTOMRIGHT", 0, 1)
    local wishHint = ink(wish, "GameFontHighlightSmall", INK_SOFT)
    setFace(wishHint, NOTE_FONT, 14)
    wishHint:SetPoint("LEFT", 2, 0)
    wishHint:SetText(L.WISH_HINT)
    -- Sugerencias bajo la caja: actúan sobre el trozo que estás escribiendo (bestia, zona). Tab o clic para elegir.
    local SUG_ROWS = 6
    local sug = CreateFrame("Frame", nil, wp)
    sug:SetPoint("TOPLEFT", wish, "BOTTOMLEFT", 0, -3)
    sug:SetSize(PAGE_W, SUG_ROWS * 18 + 4)
    sug:SetFrameStrata("DIALOG")
    -- Cambiar la capa del libro (al abrir el mapa) cambia también la de sus hijos: el nivel es lo que la mantiene
    -- por encima de las filas de deseos. Se fija antes de crear los botones, que heredan el nivel.
    sug:SetFrameLevel(wp:GetFrameLevel() + 40)
    local sugEdge = sug:CreateTexture(nil, "BACKGROUND", nil, -1)
    sugEdge:SetPoint("TOPLEFT", -1, 1)
    sugEdge:SetPoint("BOTTOMRIGHT", 1, -1)
    sugEdge:SetColorTexture(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.8)
    local sugBg = sug:CreateTexture(nil, "BACKGROUND")
    sugBg:SetAllPoints()
    sugBg:SetColorTexture(0.95, 0.88, 0.72, 0.98)
    sug:Hide()
    local sugRows = {}
    local refreshSuggestions
    local function accept(item)
        local before = wish.sugBefore or ""
        wish:SetText(before .. (before ~= "" and " " or "") .. item.text .. ", ")
        wish:SetFocus()
        wish:SetCursorPosition(#wish:GetText())
        refreshSuggestions() -- tras elegir la bestia, salen las zonas donde vive
    end
    for i = 1, SUG_ROWS do
        local b = CreateFrame("Button", nil, sug)
        b:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 18)
        b:SetPoint("TOPRIGHT", -2, -2 - (i - 1) * 18)
        b:SetHeight(18)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(INK_RED[1], INK_RED[2], INK_RED[3], 0.15)
        b.mark = b:CreateTexture(nil, "BACKGROUND")
        b.mark:SetAllPoints()
        b.mark:SetColorTexture(INK_RED[1], INK_RED[2], INK_RED[3], 0.25)
        b.mark:Hide()
        b.text = ink(b, "GameFontHighlight")
        b.text:SetPoint("LEFT", 4, 0)
        b.hint = ink(b, "GameFontHighlightSmall", INK_SOFT)
        b.hint:SetPoint("RIGHT", -4, 0)
        b:SetScript("OnClick", function(s) if s.item then accept(s.item) end end)
        sugRows[i] = b
    end
    refreshSuggestions = function()
        local text = wish:GetText()
        local before, seg = text:match("^(.*,)([^,]*)$")
        local segment = 1
        if before then
            local _, commas = before:gsub(",", "")
            segment = commas + 1
        else
            before, seg = "", text
        end
        seg = seg:gsub("^%s+", "")
        local list = segment <= 2 and ns:WishSuggestions(segment, seg, text:match("^([^,]*),")) or {}
        wish.sugBefore = before
        wish.sugSel = nil
        for i, b in ipairs(sugRows) do
            b.mark:Hide()
            b.item = list[i]
            b:SetShown(list[i] ~= nil)
            if list[i] then
                b.text:SetText(list[i].text)
                b.hint:SetText(list[i].hint or "")
            end
        end
        sug:SetHeight(math.max(#list, 1) * 18 + 4)
        sug:SetShown(#list > 0)
    end
    wish:SetScript("OnTextChanged", function(s, userInput)
        wishHint:SetShown(s:GetText() == "")
        if userInput then refreshSuggestions() else sug:Hide() end
    end)
    wish:SetScript("OnTabPressed", function(s)
        local row = sugRows[s.sugSel or 1]
        if sug:IsShown() and row.item then accept(row.item) end
    end)
    -- Flechas arriba/abajo recorren las sugerencias; Tab elige la marcada (la primera si no hay ninguna).
    wish:SetScript("OnArrowPressed", function(s, key)
        if not sug:IsShown() or (key ~= "UP" and key ~= "DOWN") then return end
        local n = 0
        for _, b in ipairs(sugRows) do if b.item then n = n + 1 end end
        local sel = ((s.sugSel or (key == "DOWN" and 0 or n + 1)) - 1 + (key == "DOWN" and 1 or -1)) % n + 1
        s.sugSel = sel
        for i, b in ipairs(sugRows) do b.mark:SetShown(i == sel) end
    end)
    wish:SetScript("OnEditFocusLost", function()
        -- Un instante de espera: si se hizo clic en una sugerencia, esta se elige antes de cerrarse.
        C_Timer.After(0.2, function() if not wish:HasFocus() then sug:Hide() end end)
    end)
    wish:SetScript("OnEnterPressed", function(s)
        if ns:AddWish(s:GetText()) then s:SetText("") end
        sug:Hide()
        s:ClearFocus()
    end)
    wish:SetScript("OnEscapePressed", function(s) sug:Hide() s:ClearFocus() end)
    wish:Hide()
    self.wishInput = wish

    -- Apunta la bestia seleccionada, sin teclear
    local addT = CreateFrame("Button", nil, wp)
    local addFs = ink(addT, "GameFontNormalSmall", INK_RED)
    addFs:SetPoint("LEFT")
    addFs:SetText(L.WISH_ADD_TARGET)
    addT:SetSize(addFs:GetStringWidth() + 2, 18)
    addT:SetPoint("TOPLEFT", LEFT_X, -130)
    addT:SetScript("OnEnter", function() addFs:SetTextColor(unpack(INK)) end)
    addT:SetScript("OnLeave", function() addFs:SetTextColor(unpack(INK_RED)) end)
    addT:SetScript("OnClick", function() ns:AddWishFromTarget() end)

    local wishEmpty = ink(wp, "GameFontHighlight", INK_SOFT)
    wishEmpty:SetPoint("TOPLEFT", LEFT_X, -172)
    wishEmpty:SetWidth(PAGE_W)
    wishEmpty:SetJustifyH("LEFT")
    wishEmpty:SetText(L.WISH_EMPTY)
    self.wishEmpty = wishEmpty
    local wishMore = ink(wp, "GameFontHighlightSmall", INK_SOFT)
    self.wishMore = wishMore

    -- Nota personal, escrita a mano sobre una línea al pie de la página izquierda
    local note = CreateFrame("EditBox", nil, page)
    note:SetFontObject("GameFontHighlight")
    setFace(note, NOTE_FONT, 16)
    note:SetTextColor(unpack(INK))
    note:SetShadowOffset(0, 0)
    -- Varias líneas: empieza bajo la frase y llega hasta el pie de la página
    note:SetMultiLine(true)
    note:SetSpacing(3)
    note:SetPoint("TOPLEFT", self.storyText, "BOTTOMLEFT", -4, -16)
    note:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", LEFT_X + PAGE_W, -384)
    note:SetAutoFocus(false)
    note:SetMaxLetters(400)
    local noteLine = line(note)
    noteLine:SetPoint("BOTTOMLEFT", 0, 1)
    noteLine:SetPoint("BOTTOMRIGHT", 0, 1)
    local hint = ink(note, "GameFontHighlight", INK_SOFT)
    setFace(hint, NOTE_FONT, 16)
    hint:SetPoint("TOPLEFT", 2, -2)
    hint:SetText(L.NOTE_HINT)
    note:SetScript("OnTextChanged", function(s)
        hint:SetShown(s:GetText() == "" and not s:HasFocus())
        local pet = ns:GetPet(UI.selectedKey)
        if pet then pet.note = s:GetText() end
    end)
    note:SetScript("OnEditFocusGained", function() hint:Hide() end)
    note:SetScript("OnEditFocusLost", function(s) hint:SetShown(s:GetText() == "") end)
    note:SetScript("OnEscapePressed", note.ClearFocus)
    self.note, self.noteHint = note, hint

    -- Gustos que el diario apunta solo, entre la frase y tu nota
    local likes = ink(page, "GameFontHighlightSmall", INK_SOFT)
    likes:SetPoint("TOPLEFT", self.storyText, "BOTTOMLEFT", 0, -6)
    likes:SetWidth(PAGE_W - 4)
    likes:SetJustifyH("LEFT")
    likes:SetWordWrap(false)
    self.likesText = likes
    note:ClearAllPoints()
    note:SetPoint("TOPLEFT", likes, "BOTTOMLEFT", -2, -6)
    note:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", LEFT_X + PAGE_W, -384)

    -- Acciones: palabras escritas a tinta, como las pestañas (un botón de plástico desentona en el libro)
    local prevAction
    local function action(label, color)
        local b = CreateFrame("Button", nil, page)
        local fs = ink(b, "GameFontNormalSmall", color)
        fs:SetPoint("LEFT")
        b:SetFontString(fs)
        b:SetText(label)
        b.label = fs
        b:SetSize(fs:GetStringWidth() + 2, 18)
        if prevAction then
            b:SetPoint("LEFT", prevAction, "RIGHT", 12, 0)
            local dot = ink(b, "GameFontNormalSmall", INK_SOFT)
            dot:SetPoint("RIGHT", b, "LEFT", -5, 0)
            dot:SetText("·")
        else b:SetPoint("TOPLEFT", RIGHT_X, -314) end
        b:SetScript("OnEnter", function() fs:SetTextColor(unpack(INK_RED)) end)
        b:SetScript("OnLeave", function() fs:SetTextColor(unpack(color)) end)
        prevAction = b
        return b
    end

    local share = action(L.BTN_SHARE, INK_SOFT)
    share:SetScript("OnClick", function() ns:Share(ns:GetPet(UI.selectedKey)) end)

    local export = action(L.BTN_EXPORT, INK_SOFT)
    export:SetScript("OnClick", function() UI:Export(ns:GetPet(UI.selectedKey)) end)

    local retire = action(L.BTN_RETIRE, INK_SOFT)
    retire:SetScript("OnClick", function()
        local pet = ns:GetPet(UI.selectedKey)
        if not pet then return end
        if pet.retired then ns:SetRetired(pet, false)
        else StaticPopup_Show("VINCULO_RETIRE", pet.name, nil, pet) end
    end)
    self.retireButton = retire

    local delete = action(L.BTN_DELETE, INK_RED)
    delete:SetScript("OnClick", function()
        local pet = ns:GetPet(UI.selectedKey)
        if pet then StaticPopup_Show("VINCULO_DELETE", pet.name, nil, pet) end
    end)

    -- Alimentar: insignia redonda junto al retrato, con el icono de la comida que se usará. Es un botón seguro con
    -- Feed Pet: sus atributos solo se cambian fuera de combate, por eso no va en pageWidgets (RefreshFeed lo muestra).
    -- Va FUERA de la jerarquía del libro: un marco con un hijo protegido no se puede ocultar en combate, y el libro
    -- debe poder cerrarse siempre. Sigue al retrato por su anclaje; en combate se esconde con la transparencia.
    local feed = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    feed:SetSize(38, 38)
    -- Anclado a UIParent, nunca al libro: un marco protegido anclado a otro impide moverlo u ocultarlo en combate.
    -- PlaceFeed lo coloca junto al retrato (fuera de combate).
    feed:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 0, 0)
    self.portraitFrame = portrait
    feed:SetFrameStrata("HIGH")
    feed:SetFrameLevel(self.frame:GetFrameLevel() + 30)
    -- El cliente moderno dispara los botones seguros al pulsar (CVar ActionButtonUseKeyDown, activada por defecto):
    -- registrando solo "AnyUp" no ocurría nada.
    feed:RegisterForClicks("AnyUp", "AnyDown")
    feed.icon = feed:CreateTexture(nil, "BACKGROUND")
    feed.icon:SetSize(30, 30)
    feed.icon:SetPoint("CENTER")
    round(feed.icon)
    local feedRing = feed:CreateTexture(nil, "ARTWORK")
    feedRing:SetAllPoints()
    feedRing:SetTexture(MEDIA .. "Ring64")
    -- La cantidad, con la fuente de pilas del juego (blanca y con contorno): la tinta oscura no se lee sobre el icono.
    feed.count = feed:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    feed.count:SetPoint("BOTTOMRIGHT", -1, 1)
    feed:SetScript("PreClick", function()
        UI:RefreshFeed(true)
    end)
    feed:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        if s.foodId then
            GameTooltip:SetText(L.FEED_TIP:format(select(1, ns.ItemInfo(s.foodId)) or ("#" .. s.foodId)))
        else
            GameTooltip:SetText(L.FEED_NONE)
        end
        GameTooltip:Show()
    end)
    feed:SetScript("OnLeave", function() GameTooltip:Hide() end)
    feed:Hide()
    self.feed = feed

    self.pageWidgets = { portrait, share, self.cardIcon, export, retire, delete, note, box, head }
    self.pageWidgets[#self.pageWidgets + 1] = self.statBox
end

StaticPopupDialogs.VINCULO_DELETE = {
    text = L.CONFIRM_DELETE,
    button1 = YES, button2 = NO,
    OnAccept = function(_, pet) UI.selectedKey = nil; ns:DeletePet(pet) end,
    timeout = 0, whileDead = true, hideOnEscape = true, showAlert = true,
}

StaticPopupDialogs.VINCULO_RETIRE = {
    text = L.CONFIRM_RETIRE,
    button1 = YES, button2 = NO,
    OnAccept = function(_, pet) ns:SetRetired(pet, true) end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs.VINCULO_ABANDONED = {
    text = L.CONFIRM_ABANDONED,
    button1 = YES, button2 = NO,
    OnAccept = function(_, pet) ns:SetRetired(pet, true) end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

------------------------------------------------------------------------
-- Pintado
------------------------------------------------------------------------

local function sortedKeys()
    local pets, order = ns:GetPets()
    local active, retired = {}, {}
    for _, key in ipairs(order) do
        local pet = pets[key]
        if pet then table.insert(pet.retired and retired or active, key) end
    end
    for _, k in ipairs(retired) do active[#active + 1] = k end
    return active
end

function UI:RefreshList(keys)
    self.listKeys = keys
    self.listOffset = math.min(self.listOffset, math.max(0, #keys - MAX_TABS))
    local shown = math.min(#keys - self.listOffset, MAX_TABS)
    for i = 1, shown do
        local key = keys[self.listOffset + i]
        local pet = ns:GetPet(key)
        local row = rowAt(i)
        local selected = key == self.selectedKey
        row.key = key
        -- La elegida asoma un poco más.
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -(selected and TAB_OUT + 10 or TAB_OUT), -24 - (i - 1) * TAB_STEP)
        row.icon:SetTexture(petIcon(pet))
        row.icon:SetDesaturated(pet.retired and true or false)
        local shade = pet.retired and 0.55 or 1
        row.leather:SetVertexColor(shade, shade, shade)
        row.glow:SetShown(selected)
        row:Show()
    end
    for i = shown + 1, MAX_TABS do if self.rows[i] then self.rows[i]:Hide() end end

    -- Los deseos son de tu personaje, no de una mascota: marcador aparte, bajo la última.
    local wr = rowAt("wish")
    local on = self.selectedKey == WISH_KEY
    wr.key = WISH_KEY
    wr:ClearAllPoints()
    wr:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -(on and TAB_OUT + 10 or TAB_OUT), -32 - shown * TAB_STEP)
    wr.icon:SetTexture(WISH_ICON)
    wr.glow:SetShown(on)
    wr:Show()
    self.listEmpty:SetShown(#keys == 0 and not on)
end

-- Historia: línea de tiempo con nodos. Los hitos llevan anillo y letra oscura; lo menor, un punto pequeño.
local EVENT_ICON = {
    EV_TAMED = "Ability_Hunter_BeastTaming", EV_FIRST_SEEN = "INV_Misc_Note_01", EV_STABLE_FOUND = "INV_Misc_Note_01",
    EV_BOSS = "INV_Misc_Head_Dragon_01", EV_ANNIVERSARY = "INV_Misc_Gift_01", EV_WISH_DONE = "INV_Scroll_03",
    EV_ACHIEVEMENT = "Spell_Holy_DivineIntervention", EV_LEVEL = "Ability_Hunter_BeastMastery",
    EV_ZONE = "INV_Misc_Map_01", EV_DUNGEON = "INV_Misc_Map02", EV_FALL = "INV_Misc_Bone_HumanSkull_01",
    EV_REVIVE = "Ability_Hunter_BeastSoothe", EV_RENAMED = "INV_Scroll_03", EV_LOYALTY = "Ability_Hunter_BeastTaming",
    EV_ABANDONED = "INV_Misc_Bone_HumanSkull_01", EV_FALL_FOE = "INV_Misc_Bone_HumanSkull_01",
    EV_MILESTONE = "Spell_Holy_DivineIntervention", EV_RECORD = "Ability_Hunter_BeastMastery",
    EV_EPITAPH = "INV_Scroll_03",
}
local EVENT_BIG = {
    EV_ABANDONED = true, EV_MILESTONE = true, EV_EPITAPH = true,
    EV_TAMED = true, EV_FIRST_SEEN = true, EV_STABLE_FOUND = true, EV_BOSS = true,
    EV_ANNIVERSARY = true, EV_WISH_DONE = true, EV_ACHIEVEMENT = true,
}
-- shortcut: se dibujan solo los últimos 100 sucesos; paginar si algún diario llega a más.
local STORY_MAX = 100

local function eventStyle(entry)
    local icon = "Interface\\Icons\\" .. (EVENT_ICON[entry.e] or "INV_Misc_Note_01")
    local big = EVENT_BIG[entry.e]
    if entry.e == "EV_LEVEL" then
        local lvl = tonumber(entry.a and entry.a[2]) or 0
        big = lvl > 0 and lvl % 10 == 0
    end
    return icon, big
end

function UI:RefreshStory(pet)
    local width = (self.content:GetWidth() or 300) - 40
    local n = math.min(#pet.timeline, STORY_MAX)
    local y, prevDate = 0, nil
    for k = 1, n do
        local entry = pet.timeline[#pet.timeline - k + 1]
        local row = self.storyRows[k]
        if not row then
            row = CreateFrame("Frame", nil, self.content)
            row.line = row:CreateTexture(nil, "BACKGROUND")
            row.line:SetWidth(2)
            row.line:SetColorTexture(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.35)
            row.node = row:CreateTexture(nil, "ARTWORK")
            round(row.node)
            row.ring = row:CreateTexture(nil, "OVERLAY")
            row.ring:SetTexture(MEDIA .. "Ring64")
            row.date = numeric(ink(row, "GameFontHighlightSmall", INK_RED))
            row.date:SetPoint("TOPLEFT", 36, -1)
            row.text = ink(row, "GameFontHighlight")
            row.text:SetJustifyH("LEFT")
            row.text:SetJustifyV("TOP")
            self.storyRows[k] = row
        end
        local icon, big = eventStyle(entry)
        local d = date_(entry.t)
        local showDate = d ~= prevDate
        prevDate = d
        row.date:SetShown(showDate)
        row.date:SetText(d)
        row.text:ClearAllPoints()
        row.text:SetPoint("TOPLEFT", 36, showDate and -15 or -2)
        row.text:SetWidth(width)
        row.text:SetText(ns:FormatEvent(entry))
        row.text:SetTextColor(unpack(big and INK or INK_SOFT))
        local h = math.max(big and 36 or 24, (showDate and 15 or 2) + row.text:GetStringHeight() + 9)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT")
        row:SetHeight(h)
        row.node:ClearAllPoints()
        row.node:SetPoint("CENTER", row, "TOPLEFT", 16, showDate and -15 or -9)
        row.node:SetTexture(icon)
        row.node:SetSize(big and 25 or 12, big and 25 or 12)
        row.ring:ClearAllPoints()
        row.ring:SetPoint("CENTER", row.node)
        row.ring:SetSize(30, 30)
        row.ring:SetShown(big and true or false)
        -- La línea une cada nodo con el siguiente; arranca y acaba en el primero y el último.
        row.line:ClearAllPoints()
        if k == 1 then row.line:SetPoint("TOP", row.node, "CENTER") else row.line:SetPoint("TOP", row, "TOPLEFT", 16, 0) end
        if k == n then row.line:SetPoint("BOTTOM", row.node, "CENTER") else row.line:SetPoint("BOTTOM", row, "BOTTOMLEFT", 16, 0) end
        row:Show()
        y = y + h
    end
    for k = n + 1, #self.storyRows do self.storyRows[k]:Hide() end
    return y
end

local function sortedByTime(map)
    local list = {}
    for name, t in pairs(map) do list[#list + 1] = { name = name, t = t } end
    table.sort(list, function(a, b) return a.t < b.t end)
    return list
end

-- Continentes guardados antes del hotfix pueden estar en otro idioma: se unen por esta lista
local CONTINENTS = {
    { "Eastern Kingdoms", "Reinos del Este" }, { "Kalimdor", "Kalimdor" }, { "Outland", "Terrallende" },
    { "Northrend", "Rasganorte" }, { "Pandaria", "Pandaria" }, { "Broken Isles", "Islas Abruptas" },
}
local continentByName = {}
for _, p in ipairs(CONTINENTS) do continentByName[p[1]:lower()] = p; continentByName[p[2]:lower()] = p end
local function continentName(name)
    local p = continentByName[name:lower()]
    if not p then return name end
    return (locale:find("^es") and p[2]) or p[1]
end

local function travelsText(pet)
    local lines = {}
    local function section(title, map, suffix)
        local list = sortedByTime(map)
        if #list == 0 then return end
        lines[#lines + 1] = "|cff5a1e08" .. title .. " (" .. #list .. ")|r"
        for _, item in ipairs(list) do
            lines[#lines + 1] = "  " .. item.name .. (suffix and suffix(item) or "")
        end
        lines[#lines + 1] = " "
    end
    -- Zonas agrupadas por continente; las que aún no se sabe de cuál son van al final
    local groups, order = {}, {}
    for _, it in ipairs(sortedByTime(pet.zones)) do
        local c = pet.zoneContinent and pet.zoneContinent[it.name]
        local cid = pet.zoneContinentID and pet.zoneContinentID[it.name]
        local info = cid and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(cid)
        if info and type(info.name) == "string" then c = info.name end -- nombre en el idioma actual
        c = c and continentName(c) or L.TRAVEL_OTHER
        if not groups[c] then groups[c] = {}; order[#order + 1] = c end
        table.insert(groups[c], it)
    end
    table.sort(order, function(a, b)
        if (a == L.TRAVEL_OTHER) ~= (b == L.TRAVEL_OTHER) then return b == L.TRAVEL_OTHER end
        if #groups[a] ~= #groups[b] then return #groups[a] > #groups[b] end
        return a < b
    end)
    for _, c in ipairs(order) do
        -- Si de ninguna se sabe el continente, el título es el de siempre
        local title = (#order == 1 and c == L.TRAVEL_OTHER) and L.STAT_ZONES or c
        lines[#lines + 1] = "|cff5a1e08" .. title .. " (" .. #groups[c] .. ")|r"
        for _, it in ipairs(groups[c]) do
            lines[#lines + 1] = "  " .. it.name .. "  |cff7a6448" .. date_(it.t) .. "|r"
        end
        lines[#lines + 1] = " "
    end
    section(L.STAT_DUNGEONS, pet.dungeons, function(it) return "  |cff7a6448" .. date_(it.t) .. "|r" end)
    local bosses = {}
    for name, count in pairs(pet.bossKills) do bosses[#bosses + 1] = { name = name, count = count } end
    table.sort(bosses, function(a, b) return a.count > b.count end)
    if #bosses > 0 then
        lines[#lines + 1] = "|cff5a1e08" .. L.STAT_BOSSES .. " (" .. #bosses .. ")|r"
        for _, b in ipairs(bosses) do lines[#lines + 1] = "  " .. b.name .. "  |cff7a6448x" .. b.count .. "|r" end
    end
    return table.concat(lines, "\n")
end

-- Logros: rejilla de medallones. Conseguidos a color; pendientes en gris, con el progreso en el tooltip.
function UI:RefreshAchievements(pet)
    local earnedCount, best, bestRatio = 0, nil, -1
    for _, a in ipairs(ns.ACHIEVEMENTS) do
        if pet.achievements[a.id] then
            earnedCount = earnedCount + 1
        else
            local _, cur, goal = a.check(pet)
            if cur and goal and goal > 0 and cur / goal > bestRatio then best, bestRatio = a, cur / goal end
        end
    end

    local head = self.achHead
    if not head then
        head = numeric(ink(self.content, "GameFontNormal"))
        head:SetPoint("TOPLEFT", 2, -2)
        self.achHead = head
        local nxt = numeric(ink(self.content, "GameFontHighlightSmall", INK_SOFT))
        nxt:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
        nxt:SetPoint("RIGHT", -4, 0)
        nxt:SetJustifyH("LEFT")
        self.achNext = nxt
    end
    head:SetText(L.ACH_COUNT:format(earnedCount, #ns.ACHIEVEMENTS))
    head:Show()
    if best then
        local _, cur, goal, seconds = best.check(pet)
        local c, g = achValue(cur, goal, seconds)
        self.achNext:SetText(L.ACH_NEXT:format((ns:AchievementText(best.id)), c, g))
    else
        self.achNext:SetText("")
    end
    self.achNext:Show()

    local top = 40
    for i, a in ipairs(ns.ACHIEVEMENTS) do
        local cell = self.achRows[i]
        if not cell then cell = achCell(self.content); self.achRows[i] = cell end
        paintAch(cell, pet, a)
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", ((i - 1) % ACH_COLS) * ACH_CELL_W + 2, -(top + math.floor((i - 1) / ACH_COLS) * ACH_CELL_H))
        cell:Show()
    end
    return top + math.ceil(#ns.ACHIEVEMENTS / ACH_COLS) * ACH_CELL_H
end

-- Bestiario. Izquierda: tus deseos (primero los pendientes, luego los cumplidos). Derecha: el Códice de familias
-- y los Retos, que se rellenan solos.
local WISH_ROWS, WISH_STEP = 6, 36

local function codexCell(parent)
    local cell = CreateFrame("Button", nil, parent)
    cell:SetSize(ACH_CELL_W, ACH_CELL_H)
    cell.icon = cell:CreateTexture(nil, "BACKGROUND")
    cell.icon:SetSize(ACH_RING * 0.82, ACH_RING * 0.82)
    round(cell.icon)
    cell.icon:SetPoint("CENTER")
    cell.ring = cell:CreateTexture(nil, "ARTWORK")
    cell.ring:SetSize(ACH_RING, ACH_RING)
    cell.ring:SetPoint("CENTER")
    cell.ring:SetTexture(MEDIA .. "Ring64")
    cell:SetScript("OnEnter", function(c)
        local en = c.entry
        if not en then return end
        GameTooltip:SetOwner(c, "ANCHOR_RIGHT")
        if en.state == "unknown" then
            GameTooltip:SetText("???")
            GameTooltip:AddLine(L.CODEX_UNKNOWN, 1, 1, 1, true)
        else
            GameTooltip:SetText(en.name)
            if en.since and en.since > 0 then GameTooltip:AddLine(L.CODEX_TAMED:format(date_(en.since)), GREEN[1], GREEN[2], GREEN[3]) end
            if en.kills > 0 then GameTooltip:AddLine(L.CODEX_HUNTED:format(en.kills), 1, 1, 1) end
            if (en.beastTotal or 0) > 0 then GameTooltip:AddLine(L.CODEX_BEASTS:format(en.beastTamed, en.beastTotal), 1, 1, 1) end
        end
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return cell
end

local CHALLENGE_TEXT = { families = "CH_FAMILIES", pets = "CH_PETS", prey = "CH_PREY", types = "CH_TYPES", classic = "CH_CLASSIC", beasts = "CH_BEASTS" }

function UI:RefreshWishes()
    local wishes = ns:GetWishes()
    local pending, done = {}, {}
    for i, w in ipairs(wishes) do table.insert(w.done and done or pending, { i = i, w = w }) end
    table.sort(done, function(a, b) return a.w.done > b.w.done end)
    local list = {}
    for _, it in ipairs(pending) do list[#list + 1] = it end
    for _, it in ipairs(done) do list[#list + 1] = it end
    self.subText:SetText(L.WISH_COUNT:format(#done, #wishes))
    self.wishEmpty:SetShown(#list == 0)
    self.wishMore:Hide()

    for n, it in ipairs(list) do
        if n > WISH_ROWS then
            self.wishMore:ClearAllPoints()
            self.wishMore:SetPoint("TOPLEFT", self.wishPage, "TOPLEFT", LEFT_X, -158 - WISH_ROWS * WISH_STEP)
            self.wishMore:SetText(L.WISH_MORE:format(#list - WISH_ROWS))
            self.wishMore:Show()
            break
        end
        local row = self.wishRows[n]
        if not row then
            row = CreateFrame("Frame", nil, self.wishPage)
            row:SetSize(PAGE_W, 32)
            row.title = ink(row, "GameFontNormal")
            row.title:SetPoint("TOPLEFT", 2, -1)
            row.desc = ink(row, "GameFontHighlightSmall", INK_SOFT)
            row.desc:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
            row.desc:SetPoint("RIGHT", -24, 0)
            local rm = CreateFrame("Button", nil, row)
            rm:SetSize(18, 18)
            rm:SetPoint("TOPRIGHT", 0, -2)
            local x = ink(rm, "GameFontNormal", INK_SOFT)
            x:SetPoint("CENTER")
            x:SetText("×")
            rm:SetScript("OnEnter", function() x:SetTextColor(unpack(INK_RED)) end)
            rm:SetScript("OnLeave", function() x:SetTextColor(unpack(INK_SOFT)) end)
            rm:SetScript("OnClick", function(s) ns:RemoveWish(s.index) end)
            row.remove = rm
            -- "Ver mapa": abre el mapa del mundo en la zona del deseo
            local mp = CreateFrame("Button", nil, row)
            local mpFs = ink(mp, "GameFontNormalSmall", INK_RED)
            mpFs:SetPoint("RIGHT")
            mpFs:SetText(L.MAP_BUTTON)
            mp:SetSize(mpFs:GetStringWidth() + 2, 18)
            mp:SetPoint("TOPRIGHT", -20, -2)
            mp:SetScript("OnEnter", function(s)
                mpFs:SetTextColor(unpack(INK))
                GameTooltip:SetOwner(s, "ANCHOR_LEFT")
                GameTooltip:SetText(L.MAP_TIP:format(s.zone or ""))
                GameTooltip:Show()
            end)
            mp:SetScript("OnLeave", function() mpFs:SetTextColor(unpack(INK_RED)); GameTooltip:Hide() end)
            mp:SetScript("OnClick", function(s) ns:ShowZoneOnMap(s.zone) end)
            row.map = mp
            self.wishRows[n] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.wishPage, "TOPLEFT", LEFT_X, -158 - (n - 1) * WISH_STEP)
        row.remove.index = it.i
        row.map.zone = it.w.zone
        row.map:SetShown(it.w.zone ~= nil and not it.w.done)
        row.title:SetText(it.w.done and ("|cff2f5a12" .. it.w.name .. "|r") or it.w.name)
        local parts = {}
        if it.w.zone then parts[#parts + 1] = it.w.zone end
        if it.w.note then parts[#parts + 1] = it.w.note end
        if it.w.done then parts[#parts + 1] = "|cff8a290d" .. L.WISH_DONE:format(date_(it.w.done)) .. "|r" end
        row.desc:SetText(table.concat(parts, " · "))
        row:Show()
    end

    -- Códice: una casilla por familia (a color si la has domesticado, apagada si solo has derrotado bestias suyas,
    -- silueta si aún no la conoces) y, debajo, los retos.
    local codex = ns:Codex()
    if not self.codexHead then
        local h = numeric(ink(self.content, "GameFontNormal"))
        h:SetPoint("TOPLEFT", 2, -2)
        self.codexHead = h
        self.retoHead = ink(self.content, "GameFontNormal", INK_RED)
        self.codexCells = {}
    end
    self.codexHead:SetText(L.CODEX_COUNT:format(codex.baseTamed, codex.baseTotal))
    self.codexHead:Show()
    local top = 26
    for i, en in ipairs(codex.entries) do
        local cell = self.codexCells[i]
        if not cell then cell = codexCell(self.content); self.codexCells[i] = cell end
        cell.entry = en
        cell.icon:SetTexture(en.icon or (FAMILY_ICONS[en.key:lower()]) or DEFAULT_ICON)
        local state = en.state
        cell.icon:SetDesaturated(state == "unknown")
        cell.icon:SetAlpha(state == "tamed" and 1 or (state == "hunted" and 0.7 or 0.3))
        cell.ring:SetDesaturated(state ~= "tamed")
        local shade = state == "tamed" and 1 or (state == "hunted" and 0.85 or 0.6)
        cell.ring:SetVertexColor(shade, shade, shade)
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", ((i - 1) % ACH_COLS) * ACH_CELL_W + 2, -(top + math.floor((i - 1) / ACH_COLS) * ACH_CELL_H))
        cell:Show()
    end
    for i = #codex.entries + 1, #self.codexCells do self.codexCells[i]:Hide() end
    local gridBottom = top + math.ceil(#codex.entries / ACH_COLS) * ACH_CELL_H

    self.retoHead:ClearAllPoints()
    self.retoHead:SetPoint("TOPLEFT", self.content, "TOPLEFT", 2, -(gridBottom + 6))
    self.retoHead:SetText(L.CODEX_CHALLENGES)
    self.retoHead:Show()
    local lines = {}
    for _, ch in ipairs(ns:Challenges(codex)) do
        local complete = ch.cur >= ch.goal
        lines[#lines + 1] = (complete and "|cff2f5a12" or "|cff5a3a18") .. "· " .. L[CHALLENGE_TEXT[ch.id]]
            .. "  (" .. math.min(ch.cur, ch.goal) .. " / " .. ch.goal .. ")|r"
    end
    self.body:ClearAllPoints()
    self.body:SetPoint("TOPLEFT", 0, -(gridBottom + 26))
    self.body:SetPoint("RIGHT")
    self.body:SetText(table.concat(lines, "\n"))
    return gridBottom + 26 + self.body:GetStringHeight()
end

-- Vista del Bestiario: la izquierda lleva el título y tus deseos; la derecha, el Códice y los Retos.
function UI:RefreshWishView()
    for _, w in ipairs(self.pageWidgets) do w:Hide() end
    self.tabBox:Show()
    self.head:Show()
    for _, b in pairs(self.tabs) do b:Hide() end
    for _, row in ipairs(self.achRows) do row:Hide() end
    for _, row in ipairs(self.storyRows) do row:Hide() end
    if self.achHead then self.achHead:Hide(); self.achNext:Hide() end
    for _, row in ipairs(self.wishRows) do row:Hide() end
    self.nameText:SetText(L.TAB_BESTIARY)
    self.sinceText:SetText((self.listKeys and #self.listKeys > 0) and "" or L.NO_PETS_HINT)
    self.tagText:SetText("")
    self.likesText:SetText("")
    self.wishTitle:Show()
    self.wishPage:Show()
    self.wishInput:Show()
    local height = self:RefreshWishes()
    self.content:SetHeight(math.max(1, height + 8))
    if self.scrollBar then
        local want = height + 8 > 214
        self.scrollBar:SetAlpha(want and 1 or 0)
        self.scrollBar:EnableMouse(want and true or false)
    end
    self.tabBox:SetShown(not self.options:IsShown())
end

local function plural(n, one, many) return (n == 1 and one or many):format(n) end

-- Todas las cifras, para el tooltip
function UI:StatRows(pet)
    local s = pet.stats
    local happy = s.timeTogether > 0 and (math.floor((s.timeHappy or 0) * 100 / s.timeTogether + 0.5) .. " %") or "-"
    return {
        { L.STAT_VICTORIES, s.victories }, { L.STAT_BOSSES, s.bosses },
        { L.STAT_ZONES, pet.zoneCount }, { L.STAT_DUNGEONS, pet.dungeonCount },
        { L.STAT_STREAK, s.bestStreak }, { L.STAT_TIME, ns.FormatTime(s.timeTogether) },
        { L.STAT_COMBAT, ns.FormatTime(s.timeCombat) }, { L.STAT_FEEDS, s.feeds },
        { L.STAT_FALLS, s.falls }, { L.STAT_REVIVES, s.revives }, { L.STAT_HAPPY, happy },
        { L.STAT_TRAINING, pet.trainingTotal and L.TRAINING_FMT:format(pet.trainingFree, pet.trainingTotal) or "-" },
    }
end

-- Lo que no es medallón, contado en frases; lo que está a cero no se menciona.
function UI:StatStory(pet)
    local s, lines = pet.stats, {}
    local function add(n, one, many)
        if (n or 0) > 0 then lines[#lines + 1] = plural(n, one, many) end
    end
    if (s.timeCombat or 0) >= 60 then lines[#lines + 1] = L.SUM_COMBAT:format(ns.FormatTime(s.timeCombat)) end
    add(s.revives, L.SUM_REVIVES_1, L.SUM_REVIVES)
    if (s.timeHappy or 0) > 0 and s.timeTogether > 0 then
        lines[#lines + 1] = L.SUM_HAPPY:format(math.floor(s.timeHappy * 100 / s.timeTogether + 0.5))
    end
    if pet.trainingTotal and (pet.trainingFree or 0) > 0 then lines[#lines + 1] = L.SUM_TRAINING:format(pet.trainingFree) end
    if #lines == 0 then return L.SUM_NONE end
    -- Caben 2 líneas sobre la nota; el resto sigue en el tooltip.
    for i = #lines, 3, -1 do lines[i] = nil end
    return table.concat(lines, "\n")
end

-- Muestra el botón de alimentar solo con la mascota invocada y elige la comida. Nada de esto se puede tocar en combate.
-- Coloca el botón de alimentar sobre la esquina inferior derecha del retrato.
function UI:PlaceFeed()
    local b, p = self.feed, self.portraitFrame
    if not b or not p or (InCombatLockdown and InCombatLockdown()) then return end
    local right, bottom = p:GetRight(), p:GetBottom()
    if not (right and bottom) then return end
    local s = p:GetEffectiveScale() / UIParent:GetEffectiveScale()
    b:ClearAllPoints()
    b:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (right - 6) * s, (bottom + 8) * s)
end

-- Mostrar u ocultar el botón: fuera de combate con Show/Hide; en combate (protegido) solo con la transparencia.
function UI:SyncFeed()
    local b = self.feed
    if not b then return end
    local want = (self.feedWanted and self.frame and self.frame:IsShown()) and true or false
    b:SetAlpha(want and (b.foodId and 1 or 0.5) or 0)
    if not (InCombatLockdown and InCombatLockdown()) then b:SetShown(want) end
end

-- La capa del libro y la del botón de alimentar van juntas (no se toca en combate: el botón es protegido).
function UI:SetStrata(strata)
    if InCombatLockdown and InCombatLockdown() then return false end
    self.frame:SetFrameStrata(strata)
    if self.feed then self.feed:SetFrameStrata(strata) end
    return true
end

function UI:RefreshFeed(show)
    local b = self.feed
    if not b then return end
    self.feedWanted = show and true or false
    if InCombatLockdown and InCombatLockdown() then self:SyncFeed() return end
    self:PlaceFeed()
    local bag, slot, id = ns:BestFood()
    b.foodId = id
    -- Macro, la forma habitual de alimentar: lanza Alimentar mascota (6991) y usa la comida sobre ella.
    -- (Antes: type=spell con target-bag/target-slot; el botón no respondía en Forever, causa sin confirmar.)
    local info = C_Spell and C_Spell.GetSpellInfo and ns.safe(C_Spell.GetSpellInfo, 6991)
    local spellName = (type(info) == "table" and info.name) or "Feed Pet"
    b:SetAttribute("type1", id and "macro" or nil)
    b:SetAttribute("macrotext1", id and ("/cast " .. spellName .. "\n/use item:" .. id) or nil)
    local icon = id and ((C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)) or (GetItemIcon and GetItemIcon(id)))
    b.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Food_14")
    local n = id and ((C_Item and C_Item.GetItemCount and C_Item.GetItemCount(id)) or (GetItemCount and GetItemCount(id))) or 0
    b.count:SetText(type(n) == "number" and n > 1 and n or "")
    self:SyncFeed()
end

function UI:Refresh()
    local f = self.frame
    if not f or not f:IsShown() then return end

    local keys = sortedKeys()
    if self.selectedKey ~= WISH_KEY and not ns:GetPet(self.selectedKey) then
        self.selectedKey = (ns:GetPet(ns.activeKey) and ns.activeKey) or keys[1]
        -- Sin mascotas, el libro se abre en el Bestiario (lo único que ya se puede usar); autoWish lo suelta al llegar la primera.
        if not self.selectedKey then self.selectedKey, self.autoWish = WISH_KEY, true end
    elseif self.autoWish and keys[1] then
        self.autoWish = nil
        self.selectedKey = (ns:GetPet(ns.activeKey) and ns.activeKey) or keys[1]
    end
    self:RefreshList(keys)

    if self.selectedKey == WISH_KEY then self:RefreshFeed(false); return self:RefreshWishView() end
    self.wishTitle:Hide()
    self.wishPage:Hide()
    local pet = ns:GetPet(self.selectedKey)
    for _, w in ipairs(self.pageWidgets) do w:SetShown(pet ~= nil) end
    if not pet then
        self:RefreshFeed(false)
        self.nameText:SetText("")
        self.subText:SetText("")
        self.sinceText:SetText("")
        self.tagText:SetText("")
        for _, b in pairs(self.tabs) do b:Hide() end
        return
    end
    for _, b in pairs(self.tabs) do b:Show() end

    -- Cabecera
    local isActive = pet.key == ns.activeKey
    self:RefreshFeed(isActive and not pet.retired and UnitExists("pet") and true or false)
    self.portraitIcon:SetTexture(petIcon(pet))
    self.portraitIcon:SetDesaturated(pet.retired and true or false)
    -- Retrato 2D nativo. Invocada, desde la unidad; si no, desde el displayID guardado; si falla, el icono de familia.
    local ok = false
    if isActive and UnitExists("pet") then
        ok = pcall(SetPortraitTexture, self.portraitIcon, "pet")
    elseif pet.displayID and SetPortraitTextureFromCreatureDisplayID then
        ok = pcall(SetPortraitTextureFromCreatureDisplayID, self.portraitIcon, pet.displayID)
    end
    if not ok then self.portraitIcon:SetTexture(petIcon(pet)) end
    self.nameText:SetText(pet.name)
    local sub = (pet.family or L.FAMILY_UNKNOWN) .. " · " .. L.LEVEL:format(pet.level or 1)
    -- Forever da "(Nivel de lealtad 1) Rebelde": el paréntesis sobra y ensancha la línea hasta el lomo del libro.
    if pet.loyaltyText then sub = sub .. " · " .. (pet.loyaltyText:gsub("^%b()%s*", "")) end
    -- El ánimo solo vale para la que está contigo; el de las demás sería viejo.
    if isActive and pet.happiness then sub = sub .. " · " .. HAPPY_COLOR[pet.happiness] .. L.HAPPINESS[pet.happiness] .. "|r" end
    self.subText:SetText(sub)
    -- Solo se dice "juntos desde" si la domesticaste con el addon activo; si no, la fecha es la de instalación.
    local since = (pet.tamed and L.TOGETHER_SINCE or L.DIARY_SINCE):format(date_(pet.created))
    if pet.tamed and pet.metZone then since = since .. " · " .. L.MET_IN:format(pet.metZone) end
    self.sinceText:SetText(since)
    local tags = {}
    if pet.retired then
        tags[#tags + 1] = "|cff7a6a50" .. (pet.abandoned and L.ABANDONED_TAG or L.RETIRED_TAG) .. "|r"
    elseif pet.pendingFall and (isActive or ns.lastKey == pet.key) then
        -- Murió y sigue sin revivir (Core la marca al caer y la suelta al revivirla).
        tags[#tags + 1] = "|cff8a290d" .. L.FALLEN_TAG .. "|r"
    elseif isActive then
        tags[#tags + 1] = "|cff2f5a12" .. L.ACTIVE_TAG .. "|r"
    else
        -- Fuera de tu lado: en el establo, o despedida un rato (aún no pasó por el establo).
        tags[#tags + 1] = "|cff7a6a50" .. (pet.stabled and L.STABLED_TAG or L.RESTING_TAG) .. "|r"
    end
    self.personalityName, self.personalityDesc = nil, nil
    if ns.db.opt.personality then
        local name, desc = ns:GetPersonality(pet)
        -- "Aún os estáis conociendo" habla de algo en marcha: no tiene sentido con la mascota fuera.
        if isActive or name ~= L.PERSONALITY.newcomer[1] then
            self.personalityName, self.personalityDesc = name, desc
            tags[#tags + 1] = "|cff8a290d" .. name .. "|r"
        end
    end
    self.tagText:SetText(table.concat(tags, "  ·  "))
    self.likesText:SetText(table.concat(ns:GetLikes(pet), "  ·  "))

    -- Estadísticas
    local s = pet.stats
    self.medals.victories:SetText(tostring(s.victories))
    self.medals.bosses:SetText(tostring(s.bosses))
    self.medals.timeTogether:SetText(ns.FormatTime(s.timeTogether))
    self.medals.bestStreak:SetText(tostring(s.bestStreak))
    self.medals.zoneCount:SetText(tostring(pet.zoneCount))
    self.medals.dungeonCount:SetText(tostring(pet.dungeonCount))
    self.medals.feeds:SetText(tostring(s.feeds))
    self.medals.falls:SetText(tostring(s.falls))
    self.storyText:SetText(self:StatStory(pet))

    -- Pestaña activa
    for name, b in pairs(self.tabs) do
        local on = name == self.tab and not self.options:IsShown()
        b.label:SetTextColor(unpack(on and INK or INK_SOFT))
        b.label:SetAlpha(on and 1 or 0.7)
        b.underline:SetShown(on)
    end
    self.tabBox:SetShown(not self.options:IsShown())
    for _, row in ipairs(self.achRows) do row:Hide() end
    for _, row in ipairs(self.storyRows) do row:Hide() end
    if self.achHead then self.achHead:Hide(); self.achNext:Hide() end
    for _, row in ipairs(self.wishRows) do row:Hide() end
    self.wishInput:Hide()
    if self.codexHead then
        self.codexHead:Hide()
        self.retoHead:Hide()
        for _, c in ipairs(self.codexCells) do c:Hide() end
    end
    self.body:ClearAllPoints()
    self.body:SetPoint("TOPLEFT")
    self.body:SetPoint("RIGHT")
    local height
    if self.tab == "achievements" then
        self.body:SetText("")
        height = self:RefreshAchievements(pet)
    elseif self.tab == "travels" then
        self.body:SetText(travelsText(pet))
        height = self.body:GetStringHeight()
    else
        self.body:SetText("")
        height = self:RefreshStory(pet)
    end
    self.content:SetHeight(math.max(1, height + 8))
    -- La barra solo en Historia y Viajes, y solo si el contenido no cabe (el recuadro mide de -74 a -288).
    -- Se usa la transparencia y no Hide: la plantilla del juego la vuelve a mostrar al cambiar la altura y parpadeaba.
    if self.scrollBar then
        local want = (self.tab == "story" or self.tab == "travels") and height + 8 > 214
        self.scrollBar:SetAlpha(want and 1 or 0)
        self.scrollBar:EnableMouse(want and true or false)
    end

    -- Nota y botones
    if not self.note:HasFocus() and self.note:GetText() ~= (pet.note or "") then
        self.note:SetText(pet.note or "")
    end
    self.noteHint:SetShown((pet.note or "") == "" and not self.note:HasFocus())
    self.retireButton:SetShown(not pet.abandoned) -- una mascota abandonada no vuelve
    self.retireButton:SetText(pet.retired and L.BTN_UNRETIRE or L.BTN_RETIRE)
    self.retireButton:SetWidth(self.retireButton.label:GetStringWidth() + 2)
end

------------------------------------------------------------------------
-- Exportar: la historia entera en texto plano, lista para copiar
------------------------------------------------------------------------

local function plain(s)
    return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

function ns:ExportText(pet)
    local lines = { L.EXPORT_TITLE:format(pet.name), plain(self:ShareText(pet)), "" }
    if pet.note and pet.note ~= "" then lines[#lines + 1] = pet.note; lines[#lines + 1] = "" end
    local likes = self:GetLikes(pet)
    if #likes > 0 then lines[#lines + 1] = table.concat(likes, " · "); lines[#lines + 1] = "" end
    for i = 1, #pet.timeline do
        local entry = pet.timeline[i]
        lines[#lines + 1] = date_(entry.t) .. "  " .. plain(self:FormatEvent(entry))
    end
    return table.concat(lines, "\n")
end

function UI:Export(pet)
    if not pet then return end
    local e = self.export
    if not e then
        e = panel(UIParent)
        e:SetSize(460, 320)
        e:SetPoint("CENTER")
        e:SetFrameStrata("DIALOG")
        e:EnableMouse(true)
        tinsert(UISpecialFrames, "VinculoExportFrame")
        _G.VinculoExportFrame = e
        e.title = text(e, "GameFontNormal")
        e.title:SetPoint("TOPLEFT", 12, -10)
        local hint = text(e, "GameFontDisableSmall")
        hint:SetPoint("BOTTOMLEFT", 12, 10)
        hint:SetText(L.EXPORT_HINT)
        local close = CreateFrame("Button", nil, e, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 0, 0)
        local scroll = CreateFrame("ScrollFrame", nil, e, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -30)
        scroll:SetPoint("BOTTOMRIGHT", -30, 28)
        local box = CreateFrame("EditBox", nil, scroll)
        box:SetMultiLine(true)
        box:SetFontObject("ChatFontNormal")
        box:SetWidth(410)
        box:SetAutoFocus(false)
        box:SetScript("OnEscapePressed", function() e:Hide() end)
        -- Solo lectura: lo que escribas se deshace.
        box:SetScript("OnTextChanged", function(s, user) if user then s:SetText(e.text); s:HighlightText() end end)
        scroll:SetScrollChild(box)
        e.box = box
        self.export = e
    end
    e.text = ns:ExportText(pet)
    e.title:SetText(L.EXPORT_TITLE:format(pet.name))
    e.box:SetText(e.text)
    e:Show()
    e.box:SetFocus()
    e.box:HighlightText()
end

------------------------------------------------------------------------
-- Páginas sueltas con el arte del libro: la tarjeta para compartir (Media/Card, 512×1024) y el resumen
-- semanal (Media/Week, 512×256). Se mueven arrastrando; Esc o clic derecho las cierran.
------------------------------------------------------------------------

local function loosePage(name, texture, w, h)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(w, h)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseUp", function(s, button) if button == "RightButton" then s:Hide() end end)
    tinsert(UISpecialFrames, name)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(MEDIA .. texture)
    f:Hide()
    return f
end

-- Cifra grande en Morpheus (como los títulos del libro) con su etiqueta debajo.
local function bigStat(parent, x, y, size)
    -- Fuente de los números del libro: Morpheus dibuja "1m" como "1M" con rasgos de mayúscula.
    local num = numeric(ink(parent, "GameFontNormalHuge"))
    local path = num:GetFont()
    if path then pcall(num.SetFont, num, path, size, "") end
    num:SetPoint("TOP", parent, "TOPLEFT", x, y)
    local label = ink(parent, "GameFontHighlightSmall", INK_SOFT)
    label:SetPoint("TOP", num, "BOTTOM", 0, -1)
    return num, label
end

local function centered(parent, font, color, y)
    local fs = ink(parent, font, color)
    fs:SetPoint("TOP", parent, "TOP", 0, y)
    fs:SetJustifyH("CENTER")
    return fs
end

-- Pone el texto con la letra de título al tamaño pedido, o más pequeño si no cabe en maxW (nombres largos).
local function fitTitle(fs, text, size, maxW)
    fs:SetText(text)
    titleFont(fs, size)
    local w = fs:GetStringWidth() or 0
    if w > maxW then titleFont(fs, math.max(12, math.floor(size * maxW / w))) end
end

local CARD_W, CARD_H = 250, 390
local function buildCard()
    local c = loosePage("VinculoCardFrame", "Card", CARD_W, CARD_H)
    -- Retrato: el mismo anillo del libro, más grande que el hueco de la página para taparlo.
    local RING = 72
    local hole = RING * 0.74
    local portrait = CreateFrame("Frame", nil, c)
    portrait:SetSize(RING, RING)
    portrait:SetPoint("TOP", 0, -26)
    local dark = portrait:CreateTexture(nil, "BACKGROUND")
    dark:SetSize(hole + 6, hole + 6)
    dark:SetPoint("CENTER")
    dark:SetTexture(MEDIA .. "Circle")
    dark:SetVertexColor(0.1, 0.07, 0.04, 1)
    c.icon = portrait:CreateTexture(nil, "ARTWORK")
    c.icon:SetSize(hole, hole)
    c.icon:SetPoint("CENTER")
    round(c.icon)
    local ringFrame = CreateFrame("Frame", nil, portrait)
    ringFrame:SetAllPoints()
    ringFrame:SetFrameLevel(portrait:GetFrameLevel() + 5)
    local ring = ringFrame:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ring:SetTexture(MEDIA .. "Ring128")

    c.name = centered(c, "GameFontNormalHuge", nil, -108)
    c.name:SetWidth(CARD_W - 56)
    c.name:SetWordWrap(false)
    c.sub = centered(c, "GameFontHighlight", INK_SOFT, -140)
    local top = line(c)
    top:SetPoint("TOPLEFT", 34, -164)
    top:SetPoint("TOPRIGHT", -34, -164)
    c.nums, c.labels = {}, {}
    for i = 1, 4 do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        c.nums[i], c.labels[i] = bigStat(c, 78 + col * 94, -176 - row * 62, 28)
    end
    c.labels[1]:SetText(L.CARD_FIGHTS)
    c.labels[2]:SetText(L.CARD_TIME)
    c.labels[3]:SetText(L.CARD_ZONES)
    c.labels[4]:SetText(L.CARD_ACH)
    local bottom = line(c)
    bottom:SetPoint("TOPLEFT", 34, -298)
    bottom:SetPoint("TOPRIGHT", -34, -298)
    c.since = centered(c, "GameFontHighlightSmall", INK_SOFT, -308)
    c.brand = centered(c, "GameFontNormalSmall", INK_RED, -338)
    c.brand:SetText("VÍNCULO")
    -- La X solo se ve con el ratón encima, para que no salga en la captura.
    local close = CreateFrame("Button", nil, c)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", -26, -26)
    local x = close:CreateTexture(nil, "ARTWORK")
    x:SetAllPoints()
    x:SetTexture(MEDIA .. "Cross")
    close:SetScript("OnClick", function() c:Hide() end)
    close:SetAlpha(0)
    -- IsMouseOver (método del marco, declarado en Forever); la global MouseIsOver no lo está y daba un error por fotograma.
    c:SetScript("OnUpdate", function(s) close:SetAlpha(s:IsMouseOver() and 1 or 0) end)
    return c
end

function UI:Card(pet)
    if not pet then return end
    local c = self.card
    if not c then
        c = buildCard()
        self.card = c
    end
    local earned = 0
    for _ in pairs(pet.achievements) do earned = earned + 1 end
    c.icon:SetTexture(petIcon(pet))
    fitTitle(c.name, pet.name, 26, CARD_W - 56)
    c.sub:SetText((pet.family or L.FAMILY_UNKNOWN) .. " · " .. L.LEVEL:format(pet.level or 1))
    c.nums[1]:SetText(pet.stats.victories)
    c.nums[2]:SetText(ns.FormatTime(pet.stats.timeTogether))
    c.nums[3]:SetText(pet.zoneCount)
    c.nums[4]:SetText(earned .. "/" .. #ns.ACHIEVEMENTS)
    -- Solo se dice "juntos desde" si la domesticaste con el addon activo (igual que la ficha).
    c.since:SetText((pet.tamed and L.TOGETHER_SINCE or L.DIARY_SINCE):format(date_(pet.created)))
    -- El libro se cierra para dejar sitio a la captura.
    if self.frame then self.frame:Hide() end
    c:Show()
end

local WEEK_W, WEEK_H = 360, 196
local function buildWeek()
    local w = loosePage("VinculoWeekFrame", "Week", WEEK_W, WEEK_H)
    -- La tira de cuero cuelga del centro (hasta ~1/3 de la altura): el título va debajo.
    w.title = centered(w, "GameFontNormalHuge", nil, -62)
    w.title:SetWidth(WEEK_W - 60)
    w.title:SetWordWrap(false)
    w.nums, w.labels = {}, {}
    for i = 1, 3 do
        w.nums[i], w.labels[i] = bigStat(w, 70 + (i - 1) * 110, -98, 24)
    end
    w.labels[1]:SetText(L.CARD_FIGHTS)
    w.labels[2]:SetText(L.WEEK_BOSSES_LABEL)
    w.labels[3]:SetText(L.CARD_TIME)
    w.zones = centered(w, "GameFontHighlightSmall", INK_SOFT, -146)
    local function action(label, point, x, onClick)
        local b = CreateFrame("Button", nil, w)
        local fs = ink(b, "GameFontHighlightSmall", INK_SOFT)
        fs:SetPoint("CENTER")
        fs:SetText(label)
        b:SetSize(fs:GetStringWidth() + 4, 16)
        b:SetPoint(point, w, point, x, 16)
        b:SetScript("OnEnter", function() fs:SetTextColor(unpack(INK_RED)) end)
        b:SetScript("OnLeave", function() fs:SetTextColor(unpack(INK_SOFT)) end)
        b:SetScript("OnClick", onClick)
    end
    action(L.WEEK_NEVER, "BOTTOMLEFT", 32, function()
        ns.db.opt.weekly = false
        w:Hide()
        UI:Refresh()
    end)
    action(L.BTN_CLOSE, "BOTTOMRIGHT", -32, function() w:Hide() end)
    return w
end

-- Enseña el último resumen guardado (ns.charDB.lastWeek, que escribe CheckWeek).
function UI:Week()
    local rec = ns.charDB and ns.charDB.lastWeek
    if not rec then return ns:Print(L.NO_WEEK) end
    local w = self.week
    if not w then
        w = buildWeek()
        self.week = w
    end
    fitTitle(w.title, L.WEEK_TITLE:format(rec.name), 20, WEEK_W - 60)
    w.nums[1]:SetText(rec.v)
    w.nums[2]:SetText(rec.b)
    w.nums[3]:SetText(ns.FormatTime(rec.t))
    w.zones:SetText(rec.z > 0 and ((rec.z == 1 and L.WEEK_ZONE or L.WEEK_ZONES):format(rec.z)) or "")
    w:Show()
    fadeIn(w, 0.4)
end

function UI:Toggle()
    self:Build()
    self.frame:SetShown(not self.frame:IsShown())
end

------------------------------------------------------------------------
-- Botón redondo del minimapa (se arrastra por el borde; se quita en ajustes)
------------------------------------------------------------------------

local function placeMinimap(b)
    local a = math.rad(ns.db.minimapAngle or 210)
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
end

function UI:UpdateMinimap()
    if not Minimap then return end
    local b = self.minimap
    if not b then
        b = CreateFrame("Button", "VinculoMinimapButton", Minimap)
        b:SetSize(31, 31)
        b:SetFrameStrata("MEDIUM")
        b:SetFrameLevel(8)
        b:RegisterForClicks("LeftButtonUp")
        b:RegisterForDrag("LeftButton")
        b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
        -- El logo ya es una insignia redonda con su aro: no lleva el borde estándar.
        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(MEDIA .. "Icon")
        b:SetScript("OnClick", function() UI:Toggle() end)
        b:SetScript("OnDragStart", function(s)
            s:SetScript("OnUpdate", function()
                local mx, my = Minimap:GetCenter()
                local scale = Minimap:GetEffectiveScale()
                local cx, cy = GetCursorPosition()
                local atan2 = math.atan2 or math.atan
                ns.db.minimapAngle = math.deg(atan2(cy / scale - my, cx / scale - mx))
                placeMinimap(s)
            end)
        end)
        b:SetScript("OnDragStop", function(s) s:SetScript("OnUpdate", nil) end)
        b:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_LEFT")
            GameTooltip:SetText(L.TITLE)
            GameTooltip:AddLine(L.MINIMAP_TIP, 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.minimap = b
    end
    placeMinimap(b)
    b:SetShown(ns.db.opt.minimap)
end

local onLogin = ns.events.PLAYER_LOGIN
ns.events.PLAYER_LOGIN = function(...)
    onLogin(...)
    UI:UpdateMinimap()
end

------------------------------------------------------------------------
-- Aviso de logro
------------------------------------------------------------------------

-- Aviso con la plantilla de logro del propio juego (mismo cartel, animación y apilado que un logro real).
-- Se registra una sola vez y todo va protegido: si algo falla o el cliente no la tiene (Era), se usa el panel propio.
local nativeToast, toastSystem -- nil sin probar, true si funciona, false si falló

local function nativeSetUp(frame, achName, icon, title)
    if not (frame.Name and frame.Shield and frame.Icon and frame.Icon.Texture and frame.Unlocked) then return false end
    frame.Name:SetText(achName)
    frame.Unlocked:SetText(title)
    if frame.Shield.Points then frame.Shield.Points:SetText("") end -- nuestros logros no dan puntos
    -- En el sitio del escudo de puntos va el logo de Vínculo.
    frame.Shield:SetAlpha(0)
    if not frame.vinculoLogo then
        local logo = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        logo:SetSize(44, 44)
        logo:SetPoint("CENTER", frame.Shield, "CENTER", 0, 0)
        logo:SetTexture(MEDIA .. "Icon")
        frame.vinculoLogo = logo
    end
    frame.Icon.Texture:SetTexture(icon)
    frame.id = nil -- no es un logro del juego
    frame:SetScript("OnClick", function() end) -- el original abriría el panel de logros con ese ID
    if frame.GuildName then frame.GuildName:Hide() end
    return true
end

local function registerNativeToast()
    if nativeToast ~= nil then return nativeToast end
    nativeToast = false
    pcall(function()
        if C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_AchievementUI")
        elseif LoadAddOn then LoadAddOn("Blizzard_AchievementUI") end -- la plantilla lo necesita
        toastSystem = AlertFrame:AddQueuedAlertFrameSubSystem("AchievementAlertFrameTemplate", nativeSetUp, 2, 6)
    end)
    nativeToast = toastSystem ~= nil
    return nativeToast
end

function UI:Toast(pet, achName, icon)
    -- Nunca el cartel nativo en combate: el panel propio no toca nada del sistema de alertas del juego.
    if not (InCombatLockdown and InCombatLockdown()) and registerNativeToast() then
        local ok = pcall(toastSystem.AddAlert, toastSystem, achName, icon or DEFAULT_ICON, L.TOAST_ACHIEVEMENT:format(pet.name))
        if ok then
            if ns.db.opt.sound and SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST then
                pcall((C_Sound and C_Sound.PlaySound) or PlaySound, SOUNDKIT.UI_EPICLOOT_TOAST)
            end
            return
        end
        nativeToast = false -- falló: a partir de ahora, siempre el panel propio
    end
    self:PanelToast(L.TOAST_ACHIEVEMENT:format(pet.name), achName, icon)
end

-- Panel propio, pequeño y arriba (también para el aviso de bestia).
function UI:PanelToast(title, name, icon)
    local t = self.toast
    if not t then
        -- Pequeño y arriba, fuera de la zona de combate; no captura el ratón.
        t = panel(UIParent)
        t:SetSize(250, 50)
        t:SetPoint("TOP", 0, -90)
        t:SetFrameStrata("DIALOG")
        t:EnableMouse(false)
        t.icon = t:CreateTexture(nil, "ARTWORK")
        t.icon:SetSize(34, 34)
        t.icon:SetPoint("LEFT", 8, 0)
        t.title = text(t, "GameFontNormalSmall")
        t.title:SetPoint("TOPLEFT", t.icon, "TOPRIGHT", 8, -2)
        t.name = text(t, "GameFontHighlight")
        t.name:SetPoint("BOTTOMLEFT", t.icon, "BOTTOMRIGHT", 8, 2)
        t.name:SetPoint("RIGHT", -8, 0)
        t:SetScript("OnUpdate", function(s, elapsed)
            s.left = s.left - elapsed
            if s.left <= 0 then s:Hide()
            elseif s.left < 1 then s:SetAlpha(s.left) end
        end)
        self.toast = t
    end
    t.icon:SetTexture(icon or DEFAULT_ICON)
    t.title:SetText(title)
    t.name:SetText(name)
    t.left = 4
    t:SetAlpha(1)
    t:Show()
    fadeIn(t, 0.3)
    if ns.db.opt.sound and SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST then
        pcall((C_Sound and C_Sound.PlaySound) or PlaySound, SOUNDKIT.UI_EPICLOOT_TOAST)
    end
end
