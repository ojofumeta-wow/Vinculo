local ADDON, ns = ...
local L = ns.L

-- check(pet) devuelve si se cumple y, de paso, el valor actual, la meta y si son segundos.
local function stat(name, goal, seconds)
    return function(pet)
        local v = pet.stats[name] or 0
        return v >= goal, v, goal, seconds
    end
end

local function field(name, goal)
    return function(pet)
        local v = pet[name] or 0
        return v >= goal, v, goal
    end
end

ns.ACHIEVEMENTS = {
    { id = "victory_1",    icon = "Ability_Hunter_Pet_Wolf",         check = stat("victories", 1) },
    { id = "victory_100",  icon = "Ability_Hunter_Pet_Cat",          check = stat("victories", 100) },
    { id = "victory_1000", icon = "Ability_Hunter_Pet_Bear",         check = stat("victories", 1000) },
    { id = "victory_5000", icon = "Ability_Hunter_BeastMastery",     check = stat("victories", 5000) },
    { id = "streak_250",   icon = "Spell_Holy_DivineIntervention",   check = stat("bestStreak", 250) },
    { id = "level_20",     icon = "Ability_Hunter_Pet_Boar",         check = field("level", 20) },
    { id = "level_40",     icon = "Ability_Hunter_Pet_Gorilla",      check = field("level", 40) },
    { id = "level_60",     icon = "Ability_Hunter_Pet_Raptor",       check = field("level", 60) },
    { id = "boss_1",       icon = "INV_Misc_Head_Dragon_01",         check = stat("bosses", 1) },
    { id = "boss_10",      icon = "INV_Misc_Head_Dragon_Black",      check = stat("bosses", 10) },
    { id = "boss_50",      icon = "INV_Misc_Head_Dragon_Red",        check = stat("bosses", 50) },
    { id = "zones_5",      icon = "INV_Misc_Map_01",                 check = field("zoneCount", 5) },
    { id = "zones_20",     icon = "INV_Misc_Map02",                  check = field("zoneCount", 20) },
    { id = "zones_40",     icon = "INV_Misc_Spyglass_03",            check = field("zoneCount", 40) },
    { id = "time_10h",     icon = "INV_Misc_PocketWatch_01",         check = stat("timeTogether", 10 * 3600, true) },
    { id = "time_100h",    icon = "INV_Misc_PocketWatch_02",         check = stat("timeTogether", 100 * 3600, true) },
    { id = "loyalty_max",  icon = "Ability_Hunter_BeastTaming",      check = field("loyalty", 6) },
    { id = "feeds_100",    icon = "INV_Misc_Food_14",                check = stat("feeds", 100) },
    { id = "revive_10",    icon = "Ability_Hunter_BeastSoothe",      check = stat("revives", 10) },
    { id = "anniv_1m",     icon = "INV_Misc_Note_01",                check = field("months", 1) },
    { id = "anniv_1y",     icon = "INV_Misc_Gift_01",                check = field("months", 12) },
}

for _, a in ipairs(ns.ACHIEVEMENTS) do
    a.icon = "Interface\\Icons\\" .. a.icon
end

function ns:AchievementText(id)
    local t = L.ACH[id]
    if t then return t[1], t[2] end
    return id, ""
end

function ns:CheckAchievements(pet)
    if not pet or pet.retired then return end
    for _, a in ipairs(ns.ACHIEVEMENTS) do
        if not pet.achievements[a.id] and a.check(pet) then
            pet.achievements[a.id] = time()
            local name = self:AchievementText(a.id)
            self:Log(pet, "EV_ACHIEVEMENT", name)
            local opt = ns.db and ns.db.opt
            if opt and opt.toasts then
                if opt.chatOnly or not ns.UI then
                    self:Print(L.ACH_CHAT:format(pet.name, name))
                else
                    ns.UI:Toast(pet, name, a.icon)
                end
            end
        end
    end
end
