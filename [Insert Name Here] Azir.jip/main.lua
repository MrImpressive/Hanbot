local internalPred = module.internal("pred/main")
local alib = module.load("avada_lib")

local common = alib.common
local ts = alib.targetSelector

objHolder = {}
objTimeHolder = {}

local lastFarmRequest = 0
local TIME_BETWEEN_FARM_REQUESTS = 0.2

local enemies = common.GetEnemyHeroes()
local allies = common.GetAllyHeroes()

local SpellQ = {range = 740, speed = 2500, delay = 0.25, width = 25, hitbox = 100, collision = false, aoe = false, mana = 70, boundingRadiusMod = 0}
local SpellW = {range = 500, speed = 750, delay = 0.25, width = 315, radius = 162.5, hitbox = 325, collision = false, mana = 40, boundingRadiusMod = 0}
local SpellE = {range = 1100, speed = 1200, delay = 0.25, width = 315, hitbox = 60, collision = false, aoe = false, mana = 60, boundingRadiusMod = 0}
local SpellR = {range = 250, speed = 1300, delay = 0.20, width = 600, hitbox = 600, collision = true, aoe = true, mana = 100}

local AzirAA = {range = 525}
local SoldiersAA = {range = 315}

local version = 0.01

-- Menu --
local menu = menuconfig("AzirMenu", "[Insert Name Here] Azir")

ts = ts(menu, 1200)

menu:menu("qsettings", "Q Settings")
	menu.qsettings:boolean("qw", "Use Q If Out Of W Range", true)

menu:menu("rsettings", "R Settings")
	menu.rsettings:header("fill", "Offensive")
	menu.rsettings:boolean("smartr", "Use Smart R For Kill",  true)
	menu.rsettings:header("fill", "Defensive")
	menu.rsettings:boolean("protectcombo", "Protect In Combo Mode Only", true)
	menu.rsettings:dropdown("fill", "", 1, {""})
	menu.rsettings:boolean("protectgap", "Protect From Gap Closers", true)
	menu.rsettings:dropdown("fill", "", 1, {""})
	menu.rsettings:boolean("protectenemy", "Protect From Enemies In Range", true)
	menu.rsettings:slider("protectnumenemy", "Protect If X Enemies In Range", 1, 1, 5, 1)

menu:menu("combo", "Combo")
	menu.combo:boolean("qcombo", "Use Q", true)
	menu.combo:boolean("ecombo", "Use E", true)
	menu.combo:dropdown("fill", "", 1, {""})
	menu.combo:slider("qmana", "Q Minimum % Mana", 0, 0, 100, 1)
	menu.combo:slider("emana", "E Minimum % Mana", 0, 0, 100, 1)

menu:menu("harass", "Harass")
	menu.harass:boolean("qharass", "Use Q", true)
	menu.harass:boolean("eharass", "Use E", false)
	menu.harass:dropdown("fill", "", 1, {""})
	menu.harass:slider("qmana", "Q Minimum % Mana", 40, 0, 100, 1)
	menu.harass:slider("emana", "E Minimum % Mana", 40, 0, 100, 1)

menu:menu("laneclear", "Lane Clear")
	menu.laneclear:boolean("qlaneclear", "Use Q", true)
	menu.laneclear:dropdown("fill", "", 1, {""})
	menu.laneclear:boolean("smartclear", "Use Smart Clear", true)
	menu.laneclear:dropdown("fill", "", 1, {""})
	menu.laneclear:slider("qmana", "Q Minimum % Mana", 60, 0, 100, 1)
	menu.laneclear:slider("wmana", "W Minimum % Mana", 40, 0, 100, 1)

menu:menu("lasthit", "Last Hit")
	menu.lasthit:boolean("qlasthit", "Use Q", true)

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
	menu.draws:header("fill", "Miscellaneous Draws")
	menu.draws:boolean("drawsoldier", "Draw Soldiers", true)
	menu.draws:boolean("drawsoldiertime", "Draw Soldier Death Time", true)

menu:menu("key", "Key Settings")
    menu.key:header("fill", "Spell Keys")
    menu.key:keybind("combokey", "Combo Key", "Space", nil)
	menu.key:keybind("harasskey", "Harass Key", "X", nil)
	menu.key:keybind("clearkey", "Lane Clear Key", "A", nil)
	menu.key:keybind("lasthitkey", "Last Hit Key", "S", nil)
    menu.key:header("fill", "Miscellaneous Keys")
	menu.key:keybind("fleekey", "Flee Key", "Z", nil)
	menu.key:keybind("inseckey", "Insec Key", "C", nil)

ts:addToMenu()

function OnLoad()
    print("Welcome " .. hanbot.username)
end

function OnTick()
    Combo()
    Harass()
    Insec()
    LaneClear()
    LastHit()
    UltProtect()
    Flee()
end

-- Counting Soldiers --
function CreateObj(object)
    if object and object.name then
        if object.name == "AzirSoldier" then
			if UnderTower(object) then
				objHolder[object.networkID] = object
				objTimeHolder[object.networkID] = os.clock() + 6
			else
				objHolder[object.networkID] = object
				objTimeHolder[object.networkID] = os.clock() + 11
			end
        end
    end
end

function CountSoldiers(unit)
    soldiers = 0
    for _, obj in pairs(objHolder) do
        if objTimeHolder[obj.networkID] and objTimeHolder[obj.networkID] > os.clock() and (not unit or common.GetDistance(obj, unit) < 350) then
            soldiers = soldiers + 1
        end
    end
    return soldiers
end

function GetSoldier(i)
    soldiers = 0
    for _,obj in pairs(objHolder) do
        if objTimeHolder[obj.networkID] and objTimeHolder[obj.networkID] > os.clock() then
            soldiers = soldiers + 1
            if i == soldiers then
                return obj
            end
        end
    end
end

function GetSoldiers()
    soldiers = {}
    for _,obj in pairs(objHolder) do
        if objTimeHolder[obj.networkID] and objTimeHolder[obj.networkID] > os.clock() then
            table.insert(soldiers, obj)
        end
    end
    return soldiers
end

function Combo()
    local target = ts.target

    if not target then
        return
    end

    if menu.key.combokey:get() then
		for i, enemy in ipairs(enemies) do

        	-- Casting Soldiers --
			if CountObjectsInCircle(player, 2000, enemy) <= 3 then
				if IsReady(1) and common.GetDistance(player, target) < (SpellW.range + (SoldiersAA.range / 2)) then
                    local pos = internalPred.circular.get_prediction(SpellW, target)
					if pos then
						game.cast("pos", 1, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
					end
				elseif IsReady(0) and IsReady(1) and common.GetDistance(player, target) < (SpellQ.range + SoldiersAA.range) and common.GetDistance(player, target) > (SpellW.range) + (SoldiersAA.range / 2) then
					if menu.qsettings.qw:get() then
						if player.mana > menu.combo.qmana:get() and player.mana >= (SpellQ.mana + SpellW.mana) then
							local pos = internalPred.linear.get_prediction(SpellQ, target)
							if pos then
								game.cast("self", 1)
						        common.DelayAction(game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y)), 0.25)
							end
						end
					end
				end
			elseif CountObjectsInCircle(player, 2000, enemy) >= 4 then
				if IsReady(1) and common.GetDistance(player, target) < (SpellW.range + (SoldiersAA.range / 2)) then
					local pos = internalPred.circular.get_prediction(SpellW, target)
					if pos then
						game.cast("pos", 1, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
					end
				elseif IsReady(0) and IsReady(1) and common.GetDistance(player, target) < (SpellQ.range) + (SoldiersAA.range / 2) and common.GetDistance(player, target) > (SpellW.range) + (SoldiersAA.range / 2) then
					if menu.qsettings.qw:get() then
						if player.mana > menu.combo.qmana:get() and player.mana >= (SpellQ.mana + SpellW.mana) then
							if CountEnemyHitOnLine(0, player, target, enemy) >= 1 then
								local pos = internalPred.linear.get_prediction(SpellQ, target)
								if pos then
									game.cast(1)
							        common.DelayAction(game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y)), 0.25)
								end
							end
						end
					end
				end
			end

			-- Force Soldiers to Attack Target --
			if CountSoldiers() > 0 then
				for _,k in pairs(GetSoldiers()) do
					if common.GetDistance(target, k) < SoldiersAA.range then
						game.issue("attack", target)
					elseif common.GetDistance(target, k) > SoldiersAA.range and common.GetDistance(enemy, k) < SoldiersAA.range then
						game.issue("attack", enemy)
					end
				end
			end

	-- Actual Combo --
		-- One Champion In Range --
			if CountObjectsInCircle(player, 2000, enemy) >= 1 then
				if CountSoldiers() > 0 then
					for _,k in pairs(GetSoldiers()) do
						if menu.combo.qcombo:get() then
							if IsReady(0) then
								if common.GetDistance(k, target) > SoldiersAA.range and common.GetDistance(player, target) < (SpellQ.range + (SoldiersAA.range / 2)) then
									local pos = internalPred.linear.get_prediction(SpellQ, target)
									if pos then
										game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
									end
								elseif common.GetDistance(k, target) < SoldiersAA.range and common.GetDistance(player, target) < (SpellQ.range + (SoldiersAA.range / 2)) then
									if target.health < GetDmg(0, target) - 5 then
										local pos = internalPred.linear.get_prediction(SpellQ, target)
										if pos then
											game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
										end
									end
								end
							end
						end
						if menu.combo.qcombo:get() and menu.combo.ecombo:get() then
							if IsReady(1) and IsReady(3) then
								if player.mana > menu.combo.qmana:get() and player.mana > menu.combo.emana:get() and player.mana >= (SpellQ.mana + SpellE.mana) then
									if common.GetDistance(k, target) > SoldiersAA.range and  common.GetDistance(player, target) > SpellQ.range then
										if common.GetDistance(k, target) < SpellQ.range and common.GetDistance(k, player) < SpellE.range then
											if ECheck() == true and towerCheck() == true then
												game.cast("self", 2)
												local pos = internalPred.linear.get_prediction(SpellQ, target)
												if pos then
													game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
												end
											end
										end
									end
								end
							end
						end
						-- E For Auto AA --
						if menu.combo.ecombo:get() then
							if IsReady(2) then
								if common.GetDistance(k, target) < AzirAA.range and common.GetDistance(k, target) > SoldiersAA.range and common.GetDistance(k, player) < SpellE.range then
									if ECheck() == true and towerCheck() == true then
										game.cast("self", 2)
                                        game.issue("attack", target)
									end
								end
							end
							-- Enemy Directly Infront --
							if IsReady(2) then
								if common.GetDistance(player, enemy) < (player.boundingRadius + 100) then
                                    for i, ally in pairs(allies) do
    									if CountObjectsInCircle(player, AzirAA.range, ally) <= 1 and player.health < enemy.health then
    										game.cast("self", 2)
    									end
                                    end
								end
							end
                            -- E For Kil --
							if IsReady(2) then
								if common.GetDistance(k, target) < SoldiersAA.range then
									if ECheck() == true and towerCheck() == true then
										if target.health < GetDmg(2, target) - 5 then
											local x, y = VectorPointProjectionOnLineSegment(player, k, target)
								        	if y and common.GetDistanceSqr(target, x) < (SpellE.hitbox ^ 2) then
												game.cast("self", 2)
											end
										end
								    end
								end
							end
                            -- E To Try And Avoid Death --
                            if IsReady(2) then
                                if common.GetPercentHealth(player) < 10 then
                                    game.cast("self", 2)
                                end
                            end
						end
					end
				end

                -- R For Kill --
				if menu.rsettings.smartr:get() then
					if IsReady(3) and not IsReady(1) then
						if target.health < GetDmg(3, target) - 5 then
                            if CountSoldiers() == 0 then
								if common.GetDistance(player, target) < SpellR.range then
									game.cast("obj", 3, target)
								end
							elseif CountSoldiers() > 0 then
								if common.GetDistance(player, target) > SoldiersAA.range then
									if common.GetDistance(player, target) < SpellQ.range and not IsReady(0) then
										if common.GetDistance(player, target) < SpellW.range and not IsReady(1) then
											if common.GetDistance(player, target) < SpellR.range and IsReady(3) then
												game.cast("obj", 3, target)
											end
										end
									end
								end
							end
						end
					end
				end
		-- Two Champion In Range --
			--elseif CountObjectsInCircle(myHero, 2000, enemies) >= 2 then
				--if CountSoldiers() > 0 then
					--for _,k in pairs(GetSoldiers()) do

					--end
				--end
			end
		end
	end
end

function Harass()
    local target = ts.target

    if not target then
        return
    end

	if menu.key.harasskey:get() then
		for i, enemy in ipairs(enemies) do

            -- Casting Soldiers --
			if CountObjectsInCircle(player, 2000, enemy) <= 3 then
				if IsReady(1) and common.GetDistance(player, target) < (SpellW.range + (SoldiersAA.range / 2)) then
                    local pos = internalPred.circular.get_prediction(SpellW, target)
					if pos then
						game.cast("pos", 1, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
					end
				elseif IsReady(0) and IsReady(1) and common.GetDistance(player, target) < (SpellQ.range + SoldiersAA.range) and common.GetDistance(player, target) > (SpellW.range) + (SoldiersAA.range / 2) then
					if menu.qsettings.qw:get() then
						if player.mana > menu.harass.qmana:get() and player.mana >= (SpellQ.mana + SpellW.mana) then
                            local pos = internalPred.linear.get_prediction(SpellQ, target)
							if pos then
								game.cast("self", 1)
						        common.DelayAction(game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y)), 0.25)
							end
						end
					end
				end
			elseif CountObjectsInCircle(player, 2000, enemy) >= 4 then
				if IsReady(1) and common.GetDistance(player.target) < (SpellW.range + (SoldiersAA.range / 2)) then
                    local pos = internalPred.circular.get_prediction(SpellW, target)
					if pos then
						game.cast("pos", 1, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
					end
				elseif IsReady(0) and IsReady(1) and common.GetDistance(player, target) < (SpellQ.range) + (SoldiersAA.range / 2) and common.GetDistance(player, target) > (SpellW.range) + (SoldiersAA.range / 2) then
					if menu.qsettings.qw:get() then
						if player.mana > menu.harass.qmana:get() and player.mana >= (SpellQ.mana + SpellW.mana) then
							if CountEnemyHitOnLine(0, player, target, enemy) >= 1 then
                                local pos = internalPred.linear.get_prediction(SpellQ, target)
    							if pos then
    								game.cast("self", 1)
    						        common.DelayAction(game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y)), 0.25)
    							end
							end
						end
					end
				end
			end

            -- Force Soldiers to Attack Target --
			if CountSoldiers() > 0 then
				for _,k in pairs(GetSoldiers()) do
					if common.GetDistance(target, k) < SoldiersAA.range then
						game.issue("attack", target)
					elseif common.GetDistance(target, k) > SoldiersAA.range and common.GetDistance(enemy, k) < SoldiersAA.range then
						game.issue("attack", enemy)
					end
				end
			end

			-- Actual Harass --
		-- One Champion In Range --
			if CountObjectsInCircle(player, 2000, enemy) >= 1 then
				if CountSoldiers() > 0 then
					for _,k in pairs(GetSoldiers()) do
						if menu.harass.qharass:get() then
							if IsReady(0) then
								if common.GetDistance(k, target) > SoldiersAA.range and common.GetDistance(player, target) < (SpellQ.range + (SoldiersAA.range / 2)) then
                                    local pos = internalPred.linear.get_prediction(SpellQ, target)
                                    if pos then
                                        game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
                                    end
								elseif common.GetDistance(k, target) < SoldiersAA.range and common.GetDistance(player, target) < (SpellQ.range + (SoldiersAA.range / 2)) then
									if target.health < GetDmg(0, target) - 5 then
                                        local pos = internalPred.linear.get_prediction(SpellQ, target)
										if pos then
											game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
										end
									end
								end
							end
						end
						if menu.harass.qharass:get() and menu.harass.eharass:get() then
							if IsReady(0) and IsReady(2) then
								if player.mana > menu.harass.qmana:get() and player.mana > menu.harass.emana:get() and player.mana >= (SpellQ.mana + SpellE.mana) then
									if common.GetDistance(k, target) > SoldiersAA.range and  common.GetDistance(player, target) > SpellQ.range then
										if common.GetDistance(k, target) < SpellQ.range and common.GetDistance(k, player) < SpellE.range then
											if ECheck() == true and towerCheck() == true then
                                                game.cast("self", 2)
												local pos = internalPred.linear.get_prediction(SpellQ, target)
												if pos then
													game.cast("pos", 0, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
												end
											end
										end
									end
								end
							end
						end
						-- E For Auto AA --
						if menu.harass.eharass:get() then
							if not IsReady(0) and IsReady(2) then
								if common.GetDistance(k, target) < AzirAA.range and common.GetDistance(k, target) > SoldiersAA.range and common.GetDistance(k, player) < SpellE.range then
									if ECheck() == true and towerCheck() == true then
										game.cast("self", 2)
                                        game.issue("attack", target)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function LaneClear()
    local enemyMinions = common.GetMinionsInRange(1000, enum.team.enemy)

    if not enemyMinions then
        return
    end

	if menu.key.clearkey:get() then
		if menu.laneclear.smartclear:get() then
			if common.GetPercentPar(player) >= menu.laneclear.wmana:get() and os.clock() - lastFarmRequest > TIME_BETWEEN_FARM_REQUESTS then

				-- Casting Soldiers --
				for i, minion in pairs(enemyMinions) do
					if CountObjectsInCircle(player, SpellW.range, minion) <= 5 and not minion.isDead then
						if CountSoldiers() > 0 then
							for _,k in pairs(GetSoldiers()) do
								if common.GetDistance(k, minion) < SoldiersAA.range and CountSoldiers() >= 1 then
									return
								elseif common.GetDistance(k, minion) > SoldiersAA.range and not IsReady(0) and CountSoldiers() >= 1 then
									return
								end
							end
						end

						if IsReady(1) then
							local BestPos, BestHit = GetBestFarmPosition(SpellW.range + SoldiersAA.range / 2)
							if BestPos and BestHit >= 2 then
                                game.cast("pos", 1, vec3(BestPos.x, BestPos.y, BestPos.z))
							end
						end
					elseif CountObjectsInCircle(player, SpellW.range, minion) >= 6 and not minion.isDead then

						if CountSoldiers() > 0 then
							for _,k in pairs(GetSoldiers()) do
								if common.GetDistance(k, minion) < SoldiersAA.range and CountSoldiers() >= 2 then
									return
								elseif common.GetDistance(k, minion) > SoldiersAA.range and not IsReady(0) and CountSoldiers() >= 2 then
									return
								end
							end
						end

						if IsReady(1) then
							local BestPos, BestHit = GetBestFarmPosition(SpellW.range + SoldiersAA.range / 2)
							if BestPos and BestHit >= 3 then
								game.cast("pos", 1, vec3(BestPos.x, BestPos.y, BestPos.z))
							end
						end
					end

					-- Force Soldiers to Attack Minions --
					if CountSoldiers() > 0 then
						for _,k in pairs(GetSoldiers()) do
							if common.GetDistance(minion, k) < SoldiersAA.range then
								game.issue("attack", minion)
							end
						end
					end

					-- Lane Clear Logic --
					if CountSoldiers() > 0 then
						for _,k in pairs(GetSoldiers()) do
							for _, obj in pairs(objHolder) do
								if objTimeHolder[obj.networkID] and objTimeHolder[obj.networkID] < math.huge and obj.team == player.team then
									if objTimeHolder[obj.networkID] > os.clock() then
										for i, enemy in ipairs(enemies) do
											if not enemy or common.GetDistance(player, enemy) > 2000 and ClosestMinionToSoldier() > SoldiersAA.range and not minion.isDead then
												local soldierTime = math.floor(objTimeHolder[obj.networkID] - os.clock())
												if soldierTime > 2 then
													if menu.laneclear.qlaneclear:get() and IsReady(0) then
														local BestPos, BestHit = GetBestFarmPosition(SpellQ.range + SoldiersAA.range / 2)
														if BestPos and BestHit >= 2 then
															if CountObjectsInCircle(BestPos, AzirAA.range, minion) > CountObjectsInCircle(k, AzirAA.range, minion) then
																game.cast("pos", 0, vec3(BestPos.x, BestPos.y, BestPos.z))
															end
														end
													end
												end
											end
										end
									end
								end
							end
						end
					end
		        end
			LastFarmRequest = os.clock()
			end
		else
			if common.GetPercentPar(player) >= menu.laneclear.wmana:get() then

				-- Casting Soldiers --
				for i, minion in pairs(enemyMinions) do
					if CountSoldiers() > 0 then
						for _,k in pairs(GetSoldiers()) do
							if IsReady(1) then
								local BestPos, BestHit = GetBestFarmPosition(SoldiersAA.range)
								if BestPos and BestHit >= 0 then
                                    game.cast("pos", 1, vec3(Normalize(BestPos, player, SoldiersAA.range).x, Normalize(BestPos, player, SoldiersAA.range).y))
								end
							end
						end
					end

					-- Force Soldiers to Attack Minions --
					if CountSoldiers() > 0 then
						for _,k in pairs(GetSoldiers()) do
							if common.GetDistance(minion, k) < SoldiersAA.range then
								game.issue("attack", minion)
							end
						end
					end

					-- Lane Clear Logic --
					if CountSoldiers() > 0 then
						for _,k in pairs(GetSoldiers()) do
							for i, enemy in ipairs(enemies) do
								if not enemy or common.GetDistance(player, enemy) > 2000 and common.GetDistance(k, minion) > SoldiersAA.range and not minion.isDead then
									if menu.laneclear.qlaneclear:get() and IsReady(0) then
										local BestPos, BestHit = GetBestFarmPosition(SpellQ.range + SoldiersAA.range / 2)
										if BestPos and BestHit >= 1 then
											game.cast("pos", 0, vec3(BestPos.x, BestPos.y, BestPos.z))
										end
									end
								end
							end
						end
					end
		        end
			end
		end
	end
end

function LastHit()
    local enemyMinions = common.GetMinionsInRange(1000, enum.team.enemy)

    if not enemyMinions then
        return
    end

	if menu.key.lasthitkey:get() and menu.lasthit.qlasthit:get() then
		if CountSoldiers() > 0 then
			for _,k in pairs(GetSoldiers()) do
				for i, minion in pairs(enemyMinions) do
					if common.GetDistance(minion, k) > SoldiersAA.range and common.GetDistance(player, k) > AzirAA.range and common.GetDistance(player, minion) < SpellQ.range then
						if IsReady(0) and GetDmg(0, minion) > minion.health then
                            game.cast("pos", 0, vec3(minion.x, minion.y, minion.z))
						end
					end
				end
			end
		end
	end
end

function UltProtect()
	for i, enemy in ipairs(enemies) do
		if menu.rsettings.protectenemy:get() and not menu.rsettings.protectcombo:get() then
			if CountObjectsInCircle(player, SpellR.range, enemy) >= menu.rsettings.protectnumenemy:get() then
				if common.GetDistance(player, enemy) < SpellR.range then
					game.cast("obj", 3, enemy)
				end
			end
		elseif menu.rsettings.protectenemy:get() and menu.rsettings.protectcombo:get() then
			if menu.key.combokey:get() then
				if CountObjectsInCircle(player, SpellR.range, enemy) >= menu.rsettings.protectnumenemy:get() then
					if common.GetDistance(enemy) < SpellR.range then
						game.cast("obj", 3, enemy)
					end
				end
			end
		end
	end
end

function Insec()
    local target = ts.target

    if not target then
        return
    end

	if menu.key.inseckey:get() then
        if CountSoldiers() == 0 then
            if IsReady(0) and IsReady(1) and IsReady(2) and IsReady(3) then
                local pos = target.pos:lerp(player.pos, -200 / target.pos:dist(player.pos))
                if pos then
                    if common.GetDistance(player, pos) < SpellW.range then
                        game.cast("pos", 1, vec3(pos.x, pos.y, pos.z))
                    end
                end
            end
        else
            local pos = target.pos:lerp(player.pos, -200 / target.pos:dist(player.pos))
			if pos then
                if common.GetDistance(player, pos) < SpellQ.range then
                    game.cast("pos", 0, vec3(pos.x, pos.y, pos.z))
                    InsecR(player, target)
					game.cast("self", 2)
                end
    		end
        end
	game.issue("move", vec3(game.mousePos))
	end
end

function InsecR(pos, obj)
	if common.IsValidTarget(obj) and common.GetDistance(player, obj) < 250 then
		game.cast("obj", 3, player)
	else
		common.DelayAction(InsecR, 0.03)
	end
end

function Flee()
	if menu.key.fleekey:get() then
	    if CountSoldiers() == 0 then
			if IsReady(0) and IsReady(1) and IsReady(2) and player.mana > (SpellQ.mana + SpellW.mana + SpellE.mana) then
			    local movePos = player + (vec3(game.mousePos) - player) * SpellQ.range
			    game.cast("pos", 1, vec3(game.mousePos))
				game.cast("self", 2)
				game.cast("pos", 0, vec3(game.mousePos))
			end
		elseif CountSoldiers() > 0 then
			if IsReady(0) and IsReady(2) and player.mana > (SpellQ.mana + SpellE.mana) then
                game.cast("self", 2)
				game.cast("pos", 0, vec3(game.mousePos))
			end
		end
    game.issue("move", vec3(game.mousePos))
	end
end

function ECheck()
    local target = ts.target

    if not target then
        return
    end

    for i, enemy in ipairs(enemies) do
        for _, ally in ipairs(allies) do
            if CountObjectsInCircle(target, 2000, ally) >= CountObjectsInCircle(target, 2000, enemy) then
                if AllyHPPercent(2000) - EnemyHPPercent(2000) > 30 then
                  return true
                end
                if EnemyHPPercent(2000) < AllyHPPercent(2000) and EnemyHPPercent(2000) < 50 then
                  return true
                end
            end
        end
    end
    return false
end

function towerCheck()
    local target = ts.target

    if not target then
        return
    end

    if UnderTower(target) then
        if target.health > GetDmg(2, target) - 5 then
    		return false
    	elseif target.health < GetDmg(2, target) - 5 and common.GetPercentHealth(player) > 35 then
    		return true
        end
    else
        return true
    end
end

-- Drawing Shit --
function OnDraw()
    if menu.draws.drawq:get() and IsReady(0) then
        glx.world.circle(player.pos, SpellQ.range, 2, menu.draws.colorq:get(), 100)
	end
	if menu.draws.draww:get() and IsReady(1) then
		glx.world.circle(player.pos, SpellW.range, 2, menu.draws.colorw:get(), 100)
	end
	if menu.draws.drawe:get() and IsReady(2) then
		glx.world.circle(player.pos, SpellE.range, 2, menu.draws.colore:get(), 100)
	end

    if menu.draws.drawsoldier:get() then
		local pi = math.pi
		local pointsSmall = {}
		local pointsLarge = {}
		local drawPoints = {}
		local resolution = 35
		for i=1,resolution do
			local PX, PZ = A2V(pi*i/(resolution/3.5), 300)
			pointsSmall[#pointsSmall+1] = {x = PX, z = PZ}
			local PX, PZ = A2V(pi*i/(resolution/3.5)+(resolution/70), 325)
			pointsLarge[#pointsLarge+1] = {x = PX, z = PZ}
		end

		if CountSoldiers() > 0 then
			for _,k in pairs(GetSoldiers()) do
				local X,Y,Z = k.x, k.y, k.z
				if k.team == player.team and common.GetDistance(player, k) < 660 then
					local X,Y,Z = player.x, player.y, player.z
                    glx.world.circle2(k.x, k.y, k.z, 325, 1, glx.argb(255, 102, 255, 179), 100)
                    glx.world.circle2(k.x, k.y, k.z, 300, 1, glx.argb(255, 102, 255, 179), 100)
				else
                    glx.world.circle2(k.x, k.y, k.z, 325, 1, glx.argb(255, 234, 153, 153), 100)
                    glx.world.circle2(k.x, k.y, k.z, 300, 1, glx.argb(255, 234, 153, 153), 100)
				end
				for i,v in ipairs(pointsSmall) do
					if i > 1 and i < #pointsSmall then
						local nextPointL = pointsLarge[i-1]
						local nextPointS = pointsSmall[i+1]
						if k.team == player.team and common.GetDistance(player, k) < 660 then
                            glx.world.line(vec3(X+v.x, Y, Z+v.z), vec3(X+nextPointL.x, Y, Z+nextPointL.z), 1, glx.argb(255, 102, 255, 179))
                            glx.world.line(vec3(X+nextPointL.x, Y, Z+nextPointL.z), vec3(X+nextPointS.x, Y, Z+nextPointS.z), 1, glx.argb(255, 102, 255, 179))
						else
                            glx.world.line(vec3(X+v.x, Y, Z+v.z), vec3(X+nextPointL.x, Y, Z+nextPointL.z), 1, glx.argb(255, 234, 153, 153))
                            glx.world.line(vec3(X+nextPointL.x, Y, Z+nextPointL.z), vec3(X+nextPointS.x, Y, Z+nextPointS.z), 1, glx.argb(255, 234, 153, 153))
						end
					end
				end
			end
		end
	end

    if menu.draws.drawsoldiertime:get() then
		for _, obj in pairs(objHolder) do
		    if objTimeHolder[obj.networkID] and objTimeHolder[obj.networkID] < math.huge and obj.team == player.team then
			    if objTimeHolder[obj.networkID] > os.clock() then
                    local pos = glx.world.toscreen(vec3(obj.x, obj.y, obj.z))
			    	if obj.name:find("AzirSoldier") and (objTimeHolder[obj.networkID] - os.clock()) >= 4 then
                        glx.screen.drawText("Death:" ..math.floor(objTimeHolder[obj.networkID] - os.clock()).."s", 20, pos.x - 20, pos.y + 40, glx.argb(255, 102, 255, 179))
			    	elseif obj.name:find("AzirSoldier") and (objTimeHolder[obj.networkID] - os.clock()) < 4 then
                        glx.screen.drawText("Death:" ..math.floor(objTimeHolder[obj.networkID] - os.clock()).."s", 20, pos.x - 20, pos.y + 40, glx.argb(255, 234, 153, 153))
					end
				else
					objHolder[obj.networkID] = nil
					objTimeHolder[obj.networkID] = nil
				end
			end
	    end
	end
end

-- Check If Spell Is Ready --
function IsReady(spell)
    return player:spellslot(spell).state == 0
end

--Damage Calcs --
function GetDmg(spell, unit)
	local lvl = player:spellslot(spell).level
	if spell == 0 and IsReady(0) then
		local baseDamageQ = {65, 85, 105, 125, 145}
		local trueDamageQ = (baseDamageQ[lvl] + (player.ap * 0.5))
		return common.CalculateMagicDamage(unit, trueDamageQ, player)
	elseif spell == 2 and IsReady(2) then
		local baseDamageE = {60, 90, 120, 150, 180}
		local trueDamageE = (baseDamageE[lvl] + (player.ap * 0.4))
		return common.CalculateMagicDamage(unit, trueDamageE, player)
	elseif spell == 3 and IsReady(3) then
		local baseDamageR = {150, 225, 300}
		local trueDamageR = (baseDamageR[lvl] + (player.ap * 0.6))
		return common.CalculateMagicDamage(unit, trueDamageR, player)
	end
end

-- Check Percent Health --
function EnemyHPPercent(range)
	local h = 0
	local mh = 0
	for _,v in pairs(enemies) do
		if v.visible and range > common.GetDistance(player, v) then
			h = h + v.health
			mh = mh + v.maxHealth
		end
			h = h / #enemies
			mh = mh / #enemies
	return h / mh  *100 -- Percent
	end
end

function AllyHPPercent(range)
	local h = 0
	local mh = 0
	for _,v in pairs(allies) do
		if v.isVisible and range > common.GetDistance(player, v) then
			h = h + v.health
			mh = mh + v.maxHealth
		end
			h = h / #allies
			mh = mh / #allies
	return h / mh * 100 -- Percent
	end
end

-- Count # Objects In Circle --
function CountObjectsInCircle(pos, radius, pos2)
	if not pos then return -1 end
	if not pos2 then return -1 end

	local n = 0
	if common.GetDistance(pos, pos2) <= radius and not pos2.isDead then
        n = n + 1
    end

    return n
end

-- Find Best Position To Cast Spell For Enemy Heroes --
function CountEnemyOnLineSegment(StartPos, EndPos, width, objects)
    local n = 0
    for i, enemy in ipairs(enemies) do
		if not enemy and not enemy.isDead then
			local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, enemy)
			if isOnSegment and common.GetDistanceSqr(pointSegment, enemy) < width * width and common.GetDistanceSqr(StartPos, EndPos) > common.GetDistanceSqr(StartPos, enemy) then
				n = n + 1
			end
		end
    end
    return n
end

function CountEnemyHitOnLine(slot, from, target, enemy)
	return CountEnemyOnLineSegment(from, Normalize(target, from, SoldiersAA.range), SpellW.hitbox, enemy)
end

-- See If Enemy Is Under Tower --
function UnderTower(unit)
    enemyTowers = common.GetEnemyTowers()
    for i = 1, #enemyTowers do
		local tower = enemyTowers[i]
        if common.GetDistance(player, tower) < 775 + SpellW.range then
            if common.GetDistance(unit, tower) <= 775 then -- Tower range
                return true
            else
                return false
            end
        end
    end
end

-- Gets Best Position To Cast Spell For Farming --
function GetBestFarmPosition(range)
    local BestPos
    local BestHit = 0
    local enemyMinions = common.GetMinionsInRange(1000, enum.team.enemy)
    for i, object in ipairs(enemyMinions) do
        local hit = CountMinionsInCircle(object, range, enemyMinions)
        if hit > BestHit then
            BestHit = hit
            BestPos = object
            if BestHit == #enemyMinions then
               break
            end
         end
    end
    return BestPos, BestHit
end

function CountMinionsInCircle(pos, radius, objects)
    local n = 0
    for i, object in ipairs(objects) do
        if common.GetDistanceSqr(pos, object) <= radius * radius then
            n = n + 1
        end
    end
    return n
end

function ClosestMinionToSoldier()
	local distanceMinion = math.huge
    local enemyMinions = common.GetMinionsInRange(1000, enum.team.enemy)
	if CountSoldiers() > 0 then
		for _,k in pairs(GetSoldiers()) do
			for i, cminion in ipairs(enemyMinions) do
				if cminion and not cminion.isDead then
					if common.GetDistance(k, cminion) < distanceMinion then
						distanceMinion = common.GetDistance(k, cminion)
					end
				end
			end
		end
	end
	return distanceMinion
end

-- Random Calcs --
function Normalize(pos, start, range)
	local castX = start.x + range * ((pos.x - start.x) / common.GetDistance(pos))
	local castZ = start + range * ((pos.y - start.y) / common.GetDistance(pos))

	return {x = castX, z = castZ}
end

function VectorPointProjectionOnLineSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

function A2V ( a, m )
	m = m or 1
	local x = math.cos ( a ) * m
	local y = math.sin ( a ) * m
	return x, y
end

callback.add(enum.callback.load, OnLoad)
callback.add(enum.callback.tick, OnTick)
callback.add(enum.callback.draw, OnDraw)
callback.add(enum.callback.recv.createobj, CreateObj)
