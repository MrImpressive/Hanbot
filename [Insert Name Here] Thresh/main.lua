local internalPred = module.internal('pred')
local alib = module.lib('avada_lib')
local TS = module.internal('TS')

local common = alib.common
local enemies = common.GetEnemyHeroes()
local allies = common.GetAllyHeroes()
local t = {}

t.pos = mousePos

local spellQ = {
    range = 1100,
    delay = 0.5,
    width = 60,
    speed = 1900,
    boundingRadiusMod = 1,
    collision = {
        hero = false,
        minion = true
    }
}

local spellW = {
    range = 950,
    delay = 0,
    radius = 150,
    speed = 1000,
    boundingRadiusMod = 0
}

local spellE = {
    range = 450,
    delay = 0.33,
    width = 100,
    speed = 1200,
    boundingRadiusMod = 0
}

local spellR = {
    range = 500
}

local interruptableSpells = {
	["anivia"] = {
		{menuslot = "R", slot = 3, spellname = "glacialstorm", channelduration = 6}
	},
	["caitlyn"] = {
		{menuslot = "R", slot = 3, spellname = "caitlynaceinthehole", channelduration = 1}
	},
	["ezreal"] = {
		{menuslot = "R", slot = 3, spellname = "ezrealtrueshotbarrage", channelduration = 1}
	},
	["fiddlesticks"] = {
		{menuslot = "W", slot = 1, spellname = "drain", channelduration = 5},
		{menuslot = "R", slot = 3, spellname = "crowstorm", channelduration = 1.5}
	},
	["gragas"] = {
		{menuslot = "W", slot = 1, spellname = "gragasw", channelduration = 0.75}
	},
	["janna"] = {
		{menuslot = "R", slot = 3, spellname = "reapthewhirlwind", channelduration = 3}
	},
	["karthus"] = {
		{menuslot = "R", slot = 3, spellname = "karthusfallenone", channelduration = 3}
	},
	["katarina"] = {
		{menuslot = "R", slot = 3, spellname = "katarinar", channelduration = 2.5}
	},
	["lucian"] = {
		{menuslot = "R", slot = 3, spellname = "lucianr", channelduration = 2}
	},
	["lux"] = {
		{menuslot = "R", slot = 3, spellname = "luxmalicecannon", channelduration = 0.5}
	},
	["malzahar"] = {
		{menuslot = "R", slot = 3, spellname = "malzaharr", channelduration = 2.5}
	},
	["masteryi"] = {
		{menuslot = "W", slot = 1, spellname = "meditate", channelduration = 4}
	},
	["missfortune"] = {
		{menuslot = "R", slot = 3, spellname = "missfortunebullettime", channelduration = 3}
	},
	["nunu"] = {
		{menuslot = "R", slot = 3, spellname = "absolutezero", channelduration = 3}
	},
	["pantheon"] = {
		{menuslot = "R", slot = 3, spellname = "pantheonrjump", channelduration = 2}
	},
	["shen"] = {
		{menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3}
	},
    ["tristana"] = {
		{menuslot = "W", slot = 1, spellname = "tristanaw", channelduration = 1.5}
	},
	["twistedfate"] = {
		{menuslot = "R", slot = 3, spellname = "gate", channelduration = 1.5}
	},
	["varus"] = {
		{menuslot = "Q", slot = 0, spellname = "varusq", channelduration = 4}
	},
	["warwick"] = {
		{menuslot = "R", slot = 3, spellname = "warwickr", channelduration = 1.5}
	},
	["xerath"] = {
		{menuslot = "R", slot = 3, spellname = "xerathlocusofpower2", channelduration = 3}
	}
}

local menu = menu("ThreshMenu", "[Insert Name Here] Thresh")

menu:menu("qsettings", "Q Settings")
    menu.qsettings:boolean("q2", "Use Second Q", true)
	menu.qsettings:boolean("blacklisttoggle", "Use Blacklist", true)
    for i, enemy in pairs(enemies) do
        menu.qsettings:boolean(enemy.charName, "Do Not Grab "..enemy.charName, false)
    end
    menu.qsettings:slider("blacklisthp", "Unless < X% HP", 10, 0, 100, 1)

menu:menu("wsettings", "W Settings")
    menu.wsettings:boolean("autow", "Auto W", true)
    menu.wsettings:dropdown("fill", "", 1, {""})
    for i, ally in pairs(allies) do
        menu.wsettings:boolean(ally.charName, "Do Not Shield ".. ally.charName, false)
        menu.wsettings:slider("shieldbelowhp", "Shield < X% HP", 75, 0, 100, 1)
    end
    menu.wsettings:dropdown("fill", "", 1, {""})
    menu.wsettings:slider("blacklisthp", "Shield Blacklist < X% HP", 10, 0, 100, 1)
    menu.wsettings:dropdown("fill", "", 1, {""})
    menu.wsettings:boolean("engage", "Use To Engage", true)
    menu.wsettings:boolean("saveally", "Save Ally From Enemies", true)

menu:menu("rsettings", "R Settings")
    menu.rsettings:slider("rmin", "Minimum Enemies In Combo", 1, 0, 5, 1)
    menu.rsettings:dropdown("fill", "", 1, {""})
    menu.rsettings:boolean("autor", "Automatically Ult", true)
    menu.rsettings:slider("autornum", "Minimum Enemies To Auto Ult", 1, 0, 5, 1)

menu:menu("combo", "Combo")
	menu.combo:boolean("qcombo", "Use Q", true)
	menu.combo:boolean("ecombo", "Use E", true)
    menu.combo:boolean("rcombo", "Use R", true)
	menu.combo:dropdown("fill", "", 1, {""})
	menu.combo:slider("qmana", "Q Minimum % Mana", 0, 0, 100, 1)
	menu.combo:slider("emana", "E Minimum % Mana", 0, 0, 100, 1)
    menu.combo:slider("rmana", "R Minimum % Mana", 0, 0, 100, 1)

menu:menu("harass", "Harass")
	menu.harass:boolean("qharass", "Use Q", true)
	menu.harass:boolean("eharass", "Use E", true)
    menu.harass:boolean("rharass", "Use R", true)
	menu.harass:dropdown("fill", "", 1, {""})
	menu.harass:slider("qmana", "Q Minimum % Mana", 0, 0, 100, 1)
	menu.harass:slider("emana", "E Minimum % Mana", 0, 0, 100, 1)
    menu.harass:slider("rmana", "R Minimum % Mana", 0, 0, 100, 1)

menu:menu("interrupt", "Auto Interrupt")
menu.interrupt:boolean("useq", "Use Q To Interrupt", true)
menu.interrupt:boolean("usee", "Use E To Interrupt", true)
menu.interrupt:dropdown("fill", "", 1, {""})
menu.interrupt:header("fill", "Interruptible Spells")
    for i = 1, #common.GetEnemyHeroes() do
        local enemy = common.GetEnemyHeroes()[i]
        local name = string.lower(enemy.charName)
        if enemy and interruptableSpells[name] then
            for v = 1, #interruptableSpells[name] do
                local spell = interruptableSpells[name][v]
                menu.interrupt:boolean(string.format(tostring(enemy.charName) .. tostring(spell.menuslot)), "Interrupt " .. tostring(enemy.charName) .. " " .. tostring(spell.menuslot), true)
            end
        end
    end

menu:menu("draws", "Draw Settings")
	menu.draws:header("fill", "Spell Draws")
	menu.draws:boolean("drawq", "Draw Q", true)
	menu.draws:color("colorq", "Color Q", 255, 255, 255, 255)
	menu.draws:dropdown("fill", "", 1, {""})
	menu.draws:boolean("draww", "Draw W", true)
	menu.draws:color("colorw", "Color W", 255, 0x66, 0x33, 0x00 )
	menu.draws:dropdown("fill", "", 1, {""})
	menu.draws:boolean("drawe", "Draw E", true)
	menu.draws:color("colore", "Color E", 255, 0x66, 0x33, 0x00)
    menu.draws:dropdown("fill", "", 1, {""})
    menu.draws:boolean("drawr", "Draw R", true)
	menu.draws:color("colorr", "Color R", 255, 0x66, 0x33, 0x00)
	menu.draws:header("fill", "Miscellaneous Draws")
    menu.draws:boolean("drawtarget", "Draw Target", true)
    menu.draws:color("colortarget", "Color Target", 255, 0x66, 0x33, 0x00)

menu:menu("key", "Key Settings")
    menu.key:header("fill", "Spell Keys")
    menu.key:keybind("combokey", "Combo Key", "Space", nil)
	menu.key:keybind("harasskey", "Harass Key", "X", nil)
    menu.key:header("fill", "Miscellaneous Keys")
	menu.key:keybind("desperationKey", "Desperation Key", "Z", nil)

TS.load_to_menu(menu)

-- Miscellaneous fucntions --
local function IsReady(spell)
    return player:spellSlot(spell).state == 0
end

local function GetDistance(one, two)
    if (not one or not two) then
        return math.huge
    end

    return one.pos:dist(two)
end

local function IsValidTarget(object)
    return object and not object.isDead and object.isTargetable and object.isVisible
end

local function TargetSelection(res, obj, dist)
    if dist < 2000 then
      res.obj = obj
      return true
    end
end

local function GetTarget()
    return TS.get_result(TargetSelection).obj
end

local function AngleDifference(from, p1, p2)
	local p1Z = p1.z - from.z
	local p1X = p1.x - from.x
	local p1Angle = math.atan2(p1Z , p1X) * 180 / math.pi

	local p2Z = p2.z - from.z
	local p2X = p2.x - from.x
	local p2Angle = math.atan2(p2Z , p2X) * 180 / math.pi

	return math.sqrt((p1Angle - p2Angle) ^ 2)
end

local function CountObjectsInCircle(pos, radius, array)
	if not pos then return -1 end
	if not array then return -1 end

	local n = 0
	for _, object in pairs(array) do
		if GetDistance(pos, object) <= radius and not object.isDead then
            n = n + 1
        end
	end

    return n
end

local function GetLowestAlly(range)
	lowestAlly = nil
	for _, ally in pairs(allies) do
		if ally.team == player.team and not ally.isDead and GetDistance(player ,ally) <= range then
			if lowestAlly == nil then
				lowestAlly = ally
			elseif not lowestAlly.isDead and (ally.health/ally.maxHealth) < (lowestAlly.health/lowestAlly.maxHealth) then
				lowestAlly = ally
			end
		end
	end
	return lowestAlly
end

local function Interrupt(spell)
	if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
		local enemyName = string.lower(spell.owner.charName)
		if interruptableSpells[enemyName] then
			for i = 1, #interruptableSpells[enemyName] do
				local spellCheck = interruptableSpells[enemyName][i]
				if menu.interrupt[spell.owner.charName .. spellCheck.menuslot]:get() and string.lower(spell.name) == spellCheck.spellname then
                    if menu.interrupt.usee:get() and IsReady(2) then
                        if GetDistance(player, spell.owner) < spellE.range and common.IsValidTarget(spell.owner) then
                            local pos = player.pos:lerp(spell.owner.pos, -200 / player.pos:dist(spell.owner.pos))
                            player:castSpell("pos", 2, vec3(pos.x, pos.y, pos.z))
                        end
                    elseif menu.interrupt.useq:get() and IsReady(0) then
                        if GetDistance(player, spell.owner) < spellQ.range and common.IsValidTarget(spell.owner) then
                            local pos = internalPred.linear.get_prediction(spellQ, spell.owner)
                            player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        end
					end
				end
			end
		end
	end
end

local function QCheck(pos)
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if internalPred.trace.newpath(target, 0.033, 0.500) and not internalPred.collision.get_prediction(spellQ, pos, target) then
      return true
    end

end

local function CastQ2()
	if IsReady(0) and menu.qsettings.q2:get() and player:spellSlot(0).name == "threshqleap" then
		if menu.key.comboKey:get() or menu.key.harassKey:get() then
            player:castSpell("self", 0)
		end
	end
end

local function AutoW(spell)
    for _, ally in pairs(allies) do
        if ally.type == player.type and not ally.isDead and not player.isRecalling then
            if menu.wsettings.autow:get() and not menu.wsettings[ally.charName]:get() then
                if IsReady(1) and GetDistance(player, ally) <= spellW.range then

                    -- For hard cc --
                    if not common.CanPlayerMove(ally) then
                        player:castSpell("obj", 1, ally)
                    end
                end
            elseif menu.wsettings.autow:get() and menu.wsettings[ally.charName]:get() and menu.wsettings.blacklisthp:get() <  common.GetPercentHealth(ally) then
                if IsReady(1) and GetDistance(player, ally) <= spellW.range then

                    -- For hard cc --
                    if not common.CanPlayerMove(ally) then
                        player:castSpell("obj", 1, ally)
                    end
                end
            end

            -- Low HP --
            if common.GetPercentHealth(ally) < 25 and GetDistance(player, ally) < spellW.range then
                player:castSpell("obj", 1, ally)
            end
        end
    end
end

local function OnProcessSpell(spell)
    if spell then
        for _, ally in pairs(allies) do
            if ally.type == player.type and not ally.isDead and not player.isRecalling then
                if menu.wsettings.autow:get() and menu.wsettings.shieldbelowhp:get() > common.GetPercentHealth(ally) and not menu.wsettings[ally.charName]:get() then

                    if spell.name:find("BasicAttack") or spell.name:find("CritAttack") then
                        if common.GetPercentHealth(ally) > 10 then
                            return
                        end
                    end

                    local owner = spell.owner
                    if spell.owner.team == TEAM_ENEMY and spell.owner.type == player.type then
                        if spell.target and spell.target.ptr == ally.ptr then
                            if IsReady(1) and GetDistance(player, ally) <= spellW.range then
                                player:castSpell("obj", 1, ally)
                            end
                        end
                    end
                elseif menu.wsettings.autow:get() and menu.wsettings.shieldbelowhp:get() > common.GetPercentHealth(ally) and menu.wsettings[ally.charName]:get() then
                    if common.GetPercentHealth(ally) < menu.wsettings.blacklisthp:get() then
                        if spell.name:find("BasicAttack") or spell.name:find("CritAttack") then
                            if common.GetPercentHealth(ally) > 10 then
                                return
                            end
                        end

                        local owner = spell.owner
                        if spell.owner.team == TEAM_ENEMY and spell.owner.type == player.type then
                            if spell.target and spell.target.ptr == ally.ptr then
                                if IsReady(1) and GetDistance(player, ally) <= spellW.range then
                                    player:castSpell("obj", 1, ally)
                                end
                            end
                        end
                    end
                end
            end
        end
        Interrupt(spell)
    end
end

local function EngageW()
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if menu.key.combokey:get() and IsReady(1) then
        if GetDistance(player, target) < spellE.range or player:spellSlot(0).name == "threshqleap" then
            for _, ally in pairs(allies) do
                if GetDistance(ally, target) < spellW.range + spellE.range and ally.charName ~= "Thresh" then
                    player:castSpell("obj", 1, ally)
                end
            end
        end
    end
end

local function SaveAllyW()
    if menu.wsettings.saveally:get() and IsReady(1) then
        for _, ally in pairs(allies) do
            if not ally.isDead and GetDistance(player, ally) < spellW.range then
                if CountObjectsInCircle(ally, 600, allies) < CountObjectsInCircle(ally, 600, enemies) then
                    if common.GetPercentHealth(ally) < 50 then
                        player:castSpell("obj", 1, ally)
                    end
                end
            end
        end
    end
end

local function DesperationW()
	if menu.key.desperationKey:get() then
        if IsReady(1) then
            for _, ally in pairs(allies) do
    			if ally.type == player.type and not ally.isDead and GetDistance(player, ally) < spellW.range + 500 and CountObjectsInCircle(ally, 600, enemies) > CountObjectsInCircle(ally, 600, allies) and GetDistance(player, ally) > 800 then
                    player:castSpell("obj", 1, ally)
                else
                    lowAlly = GetLowestAlly(spellW.range)
                    player:castSpell("obj", 1, ally)
                end
            end
        end
        player:move(vec3(t.pos.x, t.pos.y, t.pos.z))
    end
end

local function CastE()
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if player:spellSlot(0).name == "threshqleap" then
        return
    end

    for _, ally in pairs(allies) do
        if ally and GetDistance(player, ally) > 300 and not ally.isDead then
            if target and GetDistance(player, target) < spellE.range and not target.isDead then
                local predPos = internalPred.linear.get_prediction(spellE, target)
                if AngleDifference(target, ally, player) > 90 then
                    local pos = player.pos:lerp(target.pos, -200 / player.pos:dist(target.pos))
                    player:castSpell("pos", 2, vec3(pos.x, pos.y, pos.z))
                else
                    player:castSpell("pos", 2, vec3(predPos.endPos.x, t.pos.y, predPos.endPos.y))
                end
            end
        else
            if player.health > target.health then
                local pos = player.pos:lerp(target.pos, -200 / player.pos:dist(target.pos))
                player:castSpell("pos", 2, vec3(pos.x, pos.y, pos.z))
            else
                local predPos = internalPred.linear.get_prediction(spellE, target)
                player:castSpell("pos", 2, vec3(predPos.endPos.x, t.pos.y, predPos.endPos.y))
            end
        end
    end
end

local function AutoR()
    if menu.rsettings.autor:get() and IsReady(3) then
        for i, enemy in ipairs(enemies) do
			if CountObjectsInCircle(player, spellR.range, enemy) >= menu.rsettings.autornum:get() then
				if GetDistance(player, enemy) < spellR.range then
					player:castSpell("self", 3)
				end
			end
        end
    end
end

-- Combo --
local function Combo()
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if menu.key.combokey:get() then

        -- E logic --
        if IsReady(2) and GetDistance(player, target) < spellE.range then
            if menu.combo.ecombo:get() and (100 * player.mana / player.maxMana) >= menu.combo.emana:get() then
                local pos = internalPred.linear.get_prediction(spellE, target)
                CastE()
            end
        end

        -- Q logic --
        if IsReady(0) and GetDistance(player, target) < spellQ.range then
            if menu.combo.qcombo:get() and (100 * player.mana / player.maxMana) >= menu.combo.qmana:get() then

                if IsReady(2) and GetDistance(player, target) < spellE.range then
                    return
                end

                if menu.qsettings.blacklisttoggle:get() and not menu.qsettings[target.charName]:get() then
                    local pos = internalPred.linear.get_prediction(spellQ, target)
                    if pos and QCheck(pos) then
                        player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        common.DelayAction(CastQ2(), 1.4 + spellQ.delay)
                    end
                elseif not menu.qsettings.blacklisttoggle:get() then
                    local pos = internalPred.linear.get_prediction(spellQ, target)
                    if pos and QCheck(pos) then
                        player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        common.DelayAction(CastQ2(), 1.4 + spellQ.delay)
                    end
                end

                -- Q if target below % --
                if menu.qsettings.blacklisttoggle:get() and menu.qsettings[target.charName]:get() and (100 * target.health / target.maxHealth) <= menu.qsettings.blacklisthp:get() then
                    local pos = internalPred.linear.get_prediction(spellQ, target)
                    if pos and QCheck(pos) then
                        player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        common.DelayAction(CastQ2(), 1.4 + spellQ.delay)
                    end
                end
            end
        end

        -- W logic --
        if IsReady(1) and menu.wsettings.engage:get() then
            for _, ally in pairs(allies) do
                if ally.type == player.type and GetDistance(player, ally) < spellW.range then
    		        EngageW()
                end
            end
    	end

        -- R logic --
        if menu.combo.rcombo:get() and menu.rsettings.rmin:get() <= CountObjectsInCircle(player, spellR.range, enemies) and (100 * player.mana / player.maxMana) >= menu.combo.rmana:get() then
            if IsReady(3) and GetDistance(player, target) < spellR.range then
    			player:castSpell("self", 3)
    		end
        end
    end
end

-- Harass --
local function Harass()
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if menu.key.harasskey:get() then

        -- E logic --
        if IsReady(2) and GetDistance(player, target) < spellE.range then
            if menu.harass.eharass:get() and (100 * player.mana / player.maxMana) >= menu.harass.emana:get() then
                local pos = internalPred.linear.get_prediction(spellE, target)
                CastE()
            end
        end

        -- Q logic --
        if IsReady(0) and GetDistance(player, target) < spellQ.range then
            if menu.harass.qharass:get() and (100 * player.mana / player.maxMana) >= menu.harass.qmana:get() then

                if IsReady(2) and GetDistance(player, target) < spellE.range then
                    return
                end

                if menu.qsettings.blacklisttoggle:get() and not menu.qsettings[target.charName]:get() then
                    local pos = internalPred.linear.get_prediction(spellQ, target)
                    if pos and QCheck(pos) then
                        player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        common.DelayAction(CastQ2(), 1.4 + spellQ.delay)
                    end
                elseif not menu.qsettings.blacklisttoggle:get() then
                    local pos = internalPred.linear.get_prediction(spellQ, target)
                    if pos and QCheck(pos) then
                        player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        common.DelayAction(CastQ2(), 1.4 + spellQ.delay)
                    end
                end

                -- Q if target below % --
                if menu.qsettings.blacklisttoggle:get() and menu.qsettings[target.charName]:get() and (100 * target.health / target.maxHealth) <= menu.qsettings.blacklisthp:get() then
                    local pos = internalPred.linear.get_prediction(spellQ, target)
                    if pos and QCheck(pos) then
                        player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        common.DelayAction(CastQ2(), 1.4 + spellQ.delay)
                    end
                end
            end
        end

        -- W logic --
        if IsReady(1) and menu.wsettings.engage:get() then
            for _, ally in pairs(allies) do
                if ally.type == player.type and GetDistance(player, ally) < spellW.range then
    		        EngageW()
                end
            end
    	end

        -- R logic --
        if menu.harass.rharass:get() and menu.rsettings.rmin:get() <= CountObjectsInCircle(player, spellR.range, enemies) and (100 * player.mana / player.maxMana) >= menu.harass.rmana:get() then
            if IsReady(3) and GetDistance(player, target) < spellR.range then
    			player:castSpell("self", 3)
    		end
        end
    end
end


local function OnDraw()
    if menu.draws.drawq:get() and IsReady(0) then
        graphics.draw_circle(player.pos, spellQ.range, 2, menu.draws.colorq:get(), 100)
	end
	if menu.draws.draww:get() and IsReady(1) then
		graphics.draw_circle(player.pos, spellW.range, 2, menu.draws.colorw:get(), 100)
	end
	if menu.draws.drawe:get() and IsReady(2) then
		graphics.draw_circle(player.pos, spellE.range, 2, menu.draws.colore:get(), 100)
	end
    if menu.draws.drawr:get() and IsReady(3) then
		graphics.draw_circle(player.pos, spellR.range, 2, menu.draws.colorr:get(), 100)
	end

    if menu.draws.drawtarget:get() then
        local target = GetTarget()

        if not IsValidTarget(target) then
            return
        end

        graphics.draw_circle(target.pos, target.boundingRadius, 2, menu.draws.colortarget:get(), 100)
    end
end

local function OnTick()
    AutoW()
    AutoR()
    Combo()
    DesperationW()
    Harass()
    OnProcessSpell(spell)
    SaveAllyW()
end

cb.add(cb.tick, OnTick)
cb.add(cb.spell, OnProcessSpell)
cb.add(cb.draw, OnDraw)
