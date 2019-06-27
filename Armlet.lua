local Armlet = {}

Armlet.MenuPath = {"Utility", "Items Helper", "Armlet"}

Armlet.ArmletEnabled = Menu.AddOptionBool(Armlet.MenuPath, "Enable", false)
Armlet.HPTreshold = Menu.AddOptionSlider(Armlet.MenuPath, "HP threshold", 100, 500, 50)
Armlet.RightClick = Menu.AddOptionBool(Armlet.MenuPath, "Right click activation", false)
Armlet.RightClickStyle = Menu.AddOptionCombo(Armlet.MenuPath, "Right click style", {' Single click', ' Double click'},0)
Armlet.Illusion = Menu.AddOptionBool(Armlet.MenuPath, "Illusion activation", false)
Armlet.ManuallyOverride = Menu.AddOptionBool(Armlet.MenuPath, "Manual override", false)

-- Vars --

local ArmletSettings = require "scripts.modules.settings.Armlet";
function Armlet.ResetVars()
	Armlet.RawDamageAbilityEstimation = ArmletSettings:GetRawDamage();
	Armlet.armletDotTickTable = ArmletSettings:GetDotTick();
	Armlet.armletDotTickTableAOE = ArmletSettings:GetDotTickAOE();
	Armlet.attackPointTable = ArmletSettings:GetAttackPoint();

	Armlet.armletDamageInstanceTable = {}
	Armlet.creepAttackPointData = {}


	Armlet.isArmletManuallyToggled = false
	Armlet.isArmletManuallyToggledTime = 0
	Armlet.armletDelayer = 0
	Armlet.armletRightClickToggle = false
	Armlet.armletRightClickToggleTimer = 0
	Armlet.armletRightClickDoubleClick = 0
	Armlet.isArmletActive = false
	Armlet.armletCurrentHPGain = 0
	Armlet.armletToggleTime = 0
	Armlet.armletToggleTimePingAdjuster = 0
	Armlet.armletProjectileAdjustmentTick = 0
end
-- /\ Vars /\ --
Armlet.ResetVars()
-- Utility --

function Armlet.utilityRoundNumber(number, digits)

	if not number then return end

  	local mult = 10^(digits or 0)
  	return math.floor(number * mult + 0.5) / mult

end

function Armlet.dodgeIsTargetMe(myHero, unit, radius, castrange)

	if not myHero then return false end
	if not unit then return false end

	local angle = Entity.GetRotation(unit)

	local direction = angle:GetForward()
    	local name = NPC.GetUnitName(unit)
    		direction:SetZ(0)

    	local origin = Entity.GetAbsOrigin(unit)

	if radius == 0 then
		radius = 100
	end

    	local pointsNum = math.floor(castrange/50) + 1
    	for i = pointsNum,1,-1 do 
        	direction:Normalize()
        	direction:Scale(50*(i-1))
        	local pos = origin + direction
        	if NPC.IsPositionInRange(myHero, pos, radius + NPC.GetHullRadius(myHero), 0) then 
            		return true 
        	end
    	end 
    	return false

end

function Armlet.heroCanCastItems(myHero)

	if not myHero then return false end
	if not Entity.IsAlive(myHero) then return false end

	if NPC.IsStunned(myHero) then return false end
	if NPC.HasModifier(myHero, "modifier_bashed") then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVULNERABLE) then return false end	
	if NPC.HasModifier(myHero, "modifier_eul_cyclone") then return false end
	if NPC.HasModifier(myHero, "modifier_obsidian_destroyer_astral_imprisonment_prison") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_demon_disruption") then return false end	
	if NPC.HasModifier(myHero, "modifier_invoker_tornado") then return false end
	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_HEXED) then return false end
	if NPC.HasModifier(myHero, "modifier_legion_commander_duel") then return false end
	if NPC.HasModifier(myHero, "modifier_axe_berserkers_call") then return false end
	if NPC.HasModifier(myHero, "modifier_winter_wyvern_winters_curse") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_fiends_grip") then return false end
	if NPC.HasModifier(myHero, "modifier_bane_nightmare") then return false end
	if NPC.HasModifier(myHero, "modifier_faceless_void_chronosphere_freeze") then return false end
	if NPC.HasModifier(myHero, "modifier_enigma_black_hole_pull") then return false end
	if NPC.HasModifier(myHero, "modifier_magnataur_reverse_polarity") then return false end
	if NPC.HasModifier(myHero, "modifier_pudge_dismember") then return false end
	if NPC.HasModifier(myHero, "modifier_shadow_shaman_shackles") then return false end
	if NPC.HasModifier(myHero, "modifier_techies_stasis_trap_stunned") then return false end
	if NPC.HasModifier(myHero, "modifier_storm_spirit_electric_vortex_pull") then return false end
	if NPC.HasModifier(myHero, "modifier_tidehunter_ravage") then return false end
	if NPC.HasModifier(myHero, "modifier_windrunner_shackle_shot") then return false end
	if NPC.HasModifier(myHero, "modifier_item_nullifier_mute") then return false end

	return true	

end

function Armlet.IsHeroInvisible(myHero)

	if not myHero then return false end
	if not Entity.IsAlive(myHero) then return false end

	if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then return true end
	if NPC.HasModifier(myHero, "modifier_invoker_ghost_walk_self") then return true end
	if NPC.HasAbility(myHero, "invoker_ghost_walk") then
		if Ability.SecondsSinceLastUse(NPC.GetAbility(myHero, "invoker_ghost_walk")) > -1 and Ability.SecondsSinceLastUse(NPC.GetAbility(myHero, "invoker_ghost_walk")) < 1 then 
			return true
		end
	end

	if NPC.HasItem(myHero, "item_invis_sword", true) then
		if Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_invis_sword", true)) > -1 and Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_invis_sword", true)) < 1 then 
			return true
		end
	end
	if NPC.HasItem(myHero, "item_silver_edge", true) then
		if Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_silver_edge", true)) > -1 and Ability.SecondsSinceLastUse(NPC.GetItem(myHero, "item_silver_edge", true)) < 1 then 
			return true
		end
	end

	return false
		
end
-- /\ Utility /\--


function Armlet.getAbilityDamageInstances(myHero)

	if not myHero then return end
	local HeroesInRadius = Entity.GetHeroesInRadius(myHero, 2000, Enum.TeamType.TEAM_ENEMY)
	if HeroesInRadius == nil or #HeroesInRadius == 0 then return end
	for i, v in ipairs(HeroesInRadius) do
		if v and Entity.IsNPC(v) and Entity.IsHero(v) and not Entity.IsDormant(v) then
			for ability, info in pairs(Armlet.RawDamageAbilityEstimation) do
				if NPC.HasAbility(v, ability) and Ability.IsInAbilityPhase(NPC.GetAbility(v, ability)) then
					local abilityStyle = info[1]
					local abilityRange = math.max(Ability.GetCastRange(NPC.GetAbility(v, ability)), info[2])
					local abilityRadius = info[3]
					local abilityDamage = math.max(Ability.GetDamage(NPC.GetAbility(v, ability)), Ability.GetLevel(NPC.GetAbility(v, ability)) * info[4] * 1.1)
					local abilityDelay = Ability.GetCastPoint(NPC.GetAbility(v, ability)) + info[6]
					local projectileInfo = info[5]
					local curTime = Armlet.utilityRoundNumber(GameRules.GetGameTime(), 3)
					if projectileInfo < 1 then
						if Armlet.dodgeIsTargetMe(myHero, v, abilityRadius, abilityRange) then
							if #Armlet.armletDamageInstanceTable < 1 then
								table.insert(Armlet.armletDamageInstanceTable, { instanceindex = ability, time = Armlet.utilityRoundNumber(curTime + abilityDelay, 3), casttime = abilityDelay, type = "ability", damage = abilityDamage, isProjectile = false })
							else
								local inserted = false
								for k, info in ipairs(Armlet.armletDamageInstanceTable) do
									if info.instanceindex == ability then
										inserted = true
									end
								end
								if not inserted then
									table.insert(Armlet.armletDamageInstanceTable, { instanceindex = ability, time = Armlet.utilityRoundNumber(curTime + abilityDelay, 3), casttime = abilityDelay, type = "ability", damage = abilityDamage, isProjectile = false })
								end
							end
						end
					else
						if Armlet.dodgeIsTargetMe(myHero, v, abilityRadius, abilityRange) then
							local myProjectedPosition = Entity.GetAbsOrigin(myHero)
							local projectileTiming = ((Entity.GetAbsOrigin(v) - myProjectedPosition):Length2D() - NPC.GetHullRadius(myHero)) / projectileInfo
								if ability == "beastmaster_wild_axes" then
									projectileTiming = math.min(projectileTiming, 1)
								end
							if #Armlet.armletDamageInstanceTable < 1 then
								table.insert(Armlet.armletDamageInstanceTable, { instanceindex = ability, time = Armlet.utilityRoundNumber(curTime + abilityDelay + projectileTiming - 0.035, 3), casttime = abilityDelay, type = "ability", damage = abilityDamage, projectileorigin = Entity.GetAbsOrigin(v), projectilestarttime = GameRules.GetGameTime() + abilityDelay - 0.035, projectilespeed = projectileInfo, isProjectile = true })
							else
								local inserted = false
								for k, info in ipairs(Armlet.armletDamageInstanceTable) do
									if info.instanceindex == ability then
										inserted = true
									end
								end
								if not inserted then
									table.insert(Armlet.armletDamageInstanceTable, { instanceindex = ability, time = Armlet.utilityRoundNumber(curTime + abilityDelay + projectileTiming - 0.035, 3), casttime = abilityDelay, type = "ability", damage = abilityDamage, projectileorigin = Entity.GetAbsOrigin(v), projectilestarttime = GameRules.GetGameTime() + abilityDelay - 0.035, projectilespeed = projectileInfo, isProjectile = true })
								end
							end
						end
					end
				end
			end
		end
	end

	return

end


function Armlet.armletProcessInstanceTable(myHero)

	if not myHero then
		Armlet.armletDamageInstanceTable = {}
		return
	end

	if #Armlet.armletDamageInstanceTable < 1 then return end
	if #Armlet.armletDamageInstanceTable > 1 then
		table.sort(Armlet.armletDamageInstanceTable, function(a, b)
       			return a.time < b.time
    		end)
	end

	for i, info in ipairs(Armlet.armletDamageInstanceTable) do
		if info then	
			if info.isProjectile == true then
				local originPos = info.projectileorigin
				local myHullSize = NPC.GetHullRadius(myHero)
				local projectileStart = info.projectilestarttime
				local projectileSpeed = info.projectilespeed
				local timeElapsed = math.max((GameRules.GetGameTime() - projectileStart), 0)
				local projectilePos = originPos + (Entity.GetAbsOrigin(myHero) - originPos):Normalized():Scaled(timeElapsed*projectileSpeed)
				local myDisToOrigin = (Entity.GetAbsOrigin(myHero) - originPos):Length2D() - myHullSize
				local projectilDisToOrigin = (projectilePos - originPos):Length2D()
				if projectilDisToOrigin < myDisToOrigin and timeElapsed > 0 then
					local myDisToProjectile = (Entity.GetAbsOrigin(myHero) - projectilePos):Length2D() - myHullSize
					if myDisToProjectile > 1 then
						local remainingTravelTime = math.max(myDisToProjectile / projectileSpeed, 0)
						local processImpactTime = GameRules.GetGameTime() + remainingTravelTime
						if math.abs(info.time - processImpactTime) > 0.01 then
							local insert = table.remove(Armlet.armletDamageInstanceTable, i)
							insert.time = Armlet.utilityRoundNumber(processImpactTime, 3)
							table.insert(Armlet.armletDamageInstanceTable, insert)
							break
							return
						end
					end
				end
			end
			if GameRules.GetGameTime() > info.time then
				local backSwingCheck = 0
					if info.backswingend ~= nil then
						backSwingCheck = info.backswingend - info.time
					end
				if GameRules.GetGameTime() > info.time + math.max(backSwingCheck, 0) + 0.25 then
					table.remove(Armlet.armletDamageInstanceTable, i)
					break
					return
				end
			end
		end
	end
	
	return	

end


function Armlet.getDotDamageTicks(myHero)

	if not myHero then return end

	for dotMod, tickRate in pairs(Armlet.armletDotTickTable) do
		if NPC.HasModifier(myHero, dotMod) then
			local creationTime = Armlet.utilityRoundNumber(Modifier.GetCreationTime(NPC.GetModifier(myHero, dotMod)), 3) + 0.035
			local nextTick = creationTime + math.max(math.ceil((GameRules.GetGameTime() - creationTime) / tickRate), 1) * tickRate
			if #Armlet.armletDamageInstanceTable < 1 then
				table.insert(Armlet.armletDamageInstanceTable, { instanceindex = dotMod, time = nextTick, casttime = tickRate, type = "dot", damage = 50, isProjectile = false })
			else
				local inserted = false
				for k, info in ipairs(Armlet.armletDamageInstanceTable) do
					if info and info.instanceindex == dotMod and info.time == nextTick then
						inserted = true
					end
				end
				if not inserted then
					table.insert(Armlet.armletDamageInstanceTable, { instanceindex = dotMod, time = nextTick, casttime = tickRate, type = "dot", damage = 50, isProjectile = false })
				end
			end
		else
			for i, info in ipairs(Armlet.armletDamageInstanceTable) do
				if info.instanceindex == dotMod then
					table.remove(Armlet.armletDamageInstanceTable, i)
				end
			end	

		end
	end
	local HeroesInRadius = Entity.GetHeroesInRadius(myHero, 1351, Enum.TeamType.TEAM_ENEMY)
	if HeroesInRadius == nil or #HeroesInRadius == 0 then return end
	for i, v in ipairs(HeroesInRadius) do
		if v and Entity.IsNPC(v) and Entity.IsHero(v) and not Entity.IsDormant(v) and not NPC.IsIllusion(v) then
			for mod, info in pairs(Armlet.armletDotTickTableAOE) do
				if NPC.HasModifier(v, mod) then
					local effectRadius = info[1]
					local tickRate = info[2]
					if NPC.IsEntityInRange(myHero, v, effectRadius) then
						local creationTime = Armlet.utilityRoundNumber(Modifier.GetCreationTime(NPC.GetModifier(v, mod)), 2) + 0.035
						local nextTick = creationTime + math.ceil((GameRules.GetGameTime() - creationTime) / tickRate) * tickRate
						if #Armlet.armletDamageInstanceTable < 1 then
							table.insert(Armlet.armletDamageInstanceTable, { instanceindex = mod, time = nextTick, casttime = tickRate, type = "dot", damage = 50, isProjectile = false })
						else
							local inserted = false
							for k, info in ipairs(Armlet.armletDamageInstanceTable) do
								if info.instanceindex == mod then
									inserted = true
								end
							end
							if not inserted then
								table.insert(Armlet.armletDamageInstanceTable, { instanceindex = mod, time = nextTick, casttime = tickRate, type = "dot", damage = 50, isProjectile = false })
							end
						end
					else
						for i, info in ipairs(Armlet.armletDamageInstanceTable) do
							if info.instanceindex == mod then
								table.remove(Armlet.armletDamageInstanceTable, i)
							end
						end	
					end
				else
					for i, info in ipairs(Armlet.armletDamageInstanceTable) do
						if info.instanceindex == mod then
							table.remove(Armlet.armletDamageInstanceTable, i)
						end
					end
				end
			end
		end
	end

	return 

end

function Armlet.getAdjustedMaxTrueDamage(unit, target)

	if not unit then return 0 end
	if not target then return 0 end

	if Entity.IsDormant(unit) then return 0 end
	if Entity.IsDormant(target) then return 0 end

	local maxDamage = NPC.GetTrueMaximumDamage(unit)
	local maxTrueDamage = NPC.GetDamageMultiplierVersus(unit, target) * maxDamage * NPC.GetArmorDamageMultiplier(target)

	local bonusDamage = 0
	if NPC.HasModifier(unit, "modifier_storm_spirit_overload") and not NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
		local overload = NPC.GetAbility(unit, "storm_spirit_overload")
		local bonus = 0
		if overload and Ability.GetLevel(overload) > 0 then
			bonus = Ability.GetDamage(overload)
		end
		local bonusTrue = (1 - NPC.GetMagicalArmorValue(target)) * bonus + bonus * (Hero.GetIntellectTotal(unit) / 14 / 100)
		bonusDamage = bonusDamage + bonusTrue
	end

	if NPC.HasAbility(unit, "clinkz_searing_arrows") then
		local orb = NPC.GetAbility(unit, "clinkz_searing_arrows")
		if orb and Ability.IsCastable(orb, NPC.GetMana(unit)) and Ability.GetLevel(orb) > 0 then
			local bonus = 20 + 10 * Ability.GetLevel(orb)
				if NPC.HasAbility(unit, "special_bonus_unique_clinkz_1") then
					if Ability.GetLevel(NPC.GetAbility(unit, "special_bonus_unique_clinkz_1")) > 0 then
						bonus = bonus + 30
					end
				end
			local bonusTrue = NPC.GetDamageMultiplierVersus(unit, target) * bonus * NPC.GetArmorDamageMultiplier(target)
			bonusDamage = bonusDamage + bonusTrue
		end
	end

	if NPC.HasAbility(unit, "obsidian_destroyer_arcane_orb") and not NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
		local orb = NPC.GetAbility(unit, "obsidian_destroyer_arcane_orb")
		if orb and Ability.IsCastable(orb, NPC.GetMana(unit)) and Ability.GetLevel(orb) > 0 then
			local bonus = (0.05 + (0.01 * Ability.GetLevel(orb))) * NPC.GetMana(unit)
			local bonusTrue = bonus
			bonusDamage = bonusDamage + bonusTrue
		end
	end

	if NPC.HasAbility(unit, "silencer_glaives_of_wisdom") and not NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
		local orb = NPC.GetAbility(unit, "silencer_glaives_of_wisdom")
		if orb and Ability.IsCastable(orb, NPC.GetMana(unit)) and Ability.GetLevel(orb) > 0 then
			local bonus = 0.15 * Ability.GetLevel(orb) * Hero.GetIntellectTotal(unit)
				if NPC.HasAbility(unit, "special_bonus_unique_silencer_3") then
					if Ability.GetLevel(NPC.GetAbility(unit, "special_bonus_unique_silencer_3")) > 0 then
						bonus = (0.2 + 0.15 * Ability.GetLevel(orb)) * Hero.GetIntellectTotal(unit)
					end
				end
			local bonusTrue = bonus
			bonusDamage = bonusDamage + bonusTrue
		end
	end

	if NPC.HasAbility(unit, "kunkka_tidebringer") then
		local orb = NPC.GetAbility(unit, "kunkka_tidebringer")
		if orb and Ability.IsCastable(orb, NPC.GetMana(unit)) and Ability.GetLevel(orb) > 0 then
			local bonus = Ability.GetLevelSpecialValueFor(orb, "damage_bonus")
			local bonusTrue = NPC.GetDamageMultiplierVersus(unit, target) * bonus * NPC.GetArmorDamageMultiplier(target)
			bonusDamage = bonusDamage + bonusTrue
		end
	end

	if NPC.HasAbility(unit, "enchantress_impetus") then
		local orb = NPC.GetAbility(unit, "enchantress_impetus")
		if orb and Ability.IsCastable(orb, NPC.GetMana(unit)) and Ability.GetLevel(orb) > 0 then
			local distance = (Entity.GetAbsOrigin(unit) - Entity.GetAbsOrigin(target)):Length2D() * 1.35
				if distance > 1750 then
					distance = 1750
				end
			local distanceDamage = Ability.GetLevelSpecialValueForFloat(orb, "distance_damage_pct")
				if NPC.HasAbility(unit, "special_bonus_unique_enchantress_4") then
					if Ability.GetLevel(NPC.GetAbility(unit, "special_bonus_unique_enchantress_4")) > 0 then
						distanceDamage = distanceDamage + 8
					end
				end
			local bonus = distance * (distanceDamage / 100)
			local bonusTrue = bonus
			bonusDamage = bonusDamage + bonusTrue
		end
	end

	if Entity.IsSameTeam(unit, target) then
		bonusDamage = 0
	end

	if NPC.IsStructure(target) then
		bonusDamage = 0
	end
	
	return math.ceil(maxTrueDamage + bonusDamage)

end


function Armlet.armletShouldBeToggledOff(myHero)

	if not myHero then return true end

	if Armlet.isArmletActive == false then return false end
	if Armlet.armletCurrentHPGain < 250 then return false end

	if Menu.IsEnabled(Armlet.ManuallyOverride) then
		if Armlet.isArmletManuallyToggled == true then 
			return false 
		end
	end

	local hpTreshold = Menu.GetValue(Armlet.HPTreshold)
	local curTime = GameRules.GetGameTime()

	if #Armlet.armletDamageInstanceTable < 1 then
		if Menu.IsEnabled(Armlet.RightClick) then
			if Armlet.armletRightClickToggle then
				return false
			end
		end
		local gettingFaced = false
		local UnitsInRadius = Entity.GetUnitsInRadius(myHero, 1000, Enum.TeamType.TEAM_ENEMY)
		if UnitsInRadius ~= nil and #UnitsInRadius > 0 then
			for i, v in ipairs(UnitsInRadius) do
				if v and Entity.IsNPC(v) and not Entity.IsDormant(v) and not NPC.IsWaitingToSpawn(v) and NPC.GetUnitName(v) ~= "npc_dota_neutral_caster" then
					if NPC.FindFacingNPC(v) == myHero then
						if NPC.IsRanged(v) then
							if NPC.IsEntityInRange(myHero, v, NPC.GetAttackRange(v) + 145) then
								gettingFaced = true
							end
						else
							if NPC.IsEntityInRange(myHero, v, 285) then
								gettingFaced = true
							end
						end
					end
				end
			end
		end
		if gettingFaced then
			if Entity.GetHealth(myHero) > hpTreshold then
				return false
			end
		end
		return true
	else
		local nextDamageInstance = 9999
			for i, v in ipairs(Armlet.armletDamageInstanceTable) do
				if v and v.time - GameRules.GetGameTime() > 0.0 then
					if i < nextDamageInstance then
						nextDamageInstance = i
					end
				end
			end
		if nextDamageInstance > 999 then
			if Menu.IsEnabled(Armlet.RightClick) then
				if Armlet.armletRightClickToggle then
					if Entity.GetHealth(myHero) > hpTreshold then
						return false
					end
				end
			end
			local gettingFaced = false
			local UnitsInRadius = Entity.GetUnitsInRadius(myHero, 1000, Enum.TeamType.TEAM_ENEMY)
			if UnitsInRadius ~= nil and #UnitsInRadius > 0 then
				for i, v in ipairs(UnitsInRadius) do
					if v and Entity.IsNPC(v) and not Entity.IsDormant(v) and not NPC.IsWaitingToSpawn(v) and NPC.GetUnitName(v) ~= "npc_dota_neutral_caster" then
						if NPC.FindFacingNPC(v) == myHero then
							if NPC.IsRanged(v) then
								if NPC.IsEntityInRange(myHero, v, NPC.GetAttackRange(v) + 145) then
									gettingFaced = true
								end
							else
								if NPC.IsEntityInRange(myHero, v, 285) then
									gettingFaced = true
								end
							end
						end
					end
				end
			end
			if gettingFaced then
				if Entity.GetHealth(myHero) > hpTreshold then
					return false
				end
			end
			
			local inBackSwing = true
				for k, l in ipairs(Armlet.armletDamageInstanceTable) do
					if l.backswingstart ~= nil and l.backswingend ~= nil then
						if GameRules.GetGameTime() < l.backswingstart or GameRules.GetGameTime() > l.backswingend - 0.15 then
							inBackSwing = false
							break
						end
					end
				end

			if not inBackSwing then
				return false
			end

			local lastDamageInstanceTime = Armlet.armletDamageInstanceTable[#Armlet.armletDamageInstanceTable]["time"]
			if GameRules.GetGameTime() > lastDamageInstanceTime + 0.075 then
				return true
			end
		else
			local safeToggle = false
			local emergencyToggle = false
			for i, instance in ipairs(Armlet.armletDamageInstanceTable) do
				local instanceTiming = instance.time
				local instanceDamage = instance.damage + math.ceil((instanceTiming - curTime) / 0.11) * 6	
				local toggleTreshold = math.max(instanceDamage, hpTreshold)
				if instanceDamage > Entity.GetHealth(myHero) then
					if i > 1 then
						if GameRules.GetGameTime() - Armlet.armletDamageInstanceTable[i-1]["time"] > 0.075 then
							emergencyToggle = true
							break
						end
					else
						emergencyToggle = true
						break
					end
				else
					if Entity.GetHealth(myHero) <= toggleTreshold then
						if instanceTiming - GameRules.GetGameTime() > 0.42 then
							local inBackSwing = true
								for k, l in ipairs(Armlet.armletDamageInstanceTable) do
									if l.backswingstart ~= nil and l.backswingend ~= nil then
										if GameRules.GetGameTime() < l.backswingstart or GameRules.GetGameTime() > l.backswingend - 0.15 then
											if l.casttime < 0.25 then
												inBackSwing = false
												break
											end
										end
									end
								end
							if inBackSwing then
								if i > 1 then
									if GameRules.GetGameTime() - Armlet.armletDamageInstanceTable[i-1]["time"] > 0.075 then
										safeToggle = true
										break
									end
								else
									safeToggle = true
									break
								end	
							end
						end
					else
						local adjustedHP = math.max((Entity.GetHealth(myHero) - Armlet.armletCurrentHPGain), 1)
						if adjustedHP > toggleTreshold and Armlet.armletRightClickToggle then 
							safeToggle = true
						end
					end
				end	
			end

			if emergencyToggle then
				return true
			end

			if safeToggle then
				return true
			end
		end
	end

	return false
end


function Armlet.armletShouldBeToggledOn(myHero)

	if not myHero then return false end

	if Armlet.isArmletActive == true then return false end

	if Menu.IsEnabled(Armlet.ManuallyOverride) then
		if Armlet.isArmletManuallyToggled == true then 
			return false 
		end
	end

	if NPC.HasModifier(myHero, "modifier_ice_blast") then
		return false
	end

	local hpTreshold = Menu.GetValue(Armlet.HPTreshold)
	local myHP = Entity.GetHealth(myHero)


	if myHP < hpTreshold then
	local UnitsInRadius = Entity.GetUnitsInRadius(myHero, 1000, Enum.TeamType.TEAM_ENEMY)
		if UnitsInRadius ~= nil and #UnitsInRadius > 0 then
			for i, v in ipairs(UnitsInRadius) do
				if v and Entity.IsNPC(v) and not Entity.IsDormant(v) and not NPC.IsWaitingToSpawn(v) and NPC.GetUnitName(v) ~= "npc_dota_neutral_caster" then
					if NPC.FindFacingNPC(v) == myHero then
						if NPC.IsRanged(v) then
							if NPC.IsEntityInRange(myHero, v, NPC.GetAttackRange(v) + 145) then
								return true
							end
						else
							if NPC.IsEntityInRange(myHero, v, 285) then
								return true
							end
						end
					end
				end
			end
		end
	end

	if Menu.IsEnabled(Armlet.RightClick) then
		if Armlet.armletRightClickToggle then
			return true
		end
	end

	for i, info in ipairs(Armlet.armletDamageInstanceTable) do
		if info then
			local nextInstance = info.time
			local nextDamage = info.damage
			local triggerTreshold = math.max(hpTreshold, nextDamage)
			if nextInstance > GameRules.GetGameTime() then
				if nextInstance - GameRules.GetGameTime() <= 1.0 then
					if myHP <= triggerTreshold then	
						return true
					end
				end
			end
		end
	end

	return false
end


function Armlet.armletHandler(myHero)

	if not myHero then return end

	local armlet = NPC.GetItem(myHero, "item_armlet", true)
		if not armlet then return end

	Armlet.armletProcessInstanceTable(myHero)
	Armlet.getDotDamageTicks(myHero)
	Armlet.getAbilityDamageInstances(myHero)

	if Ability.GetToggleState(armlet) then
		if os.clock() - Armlet.armletToggleTimePingAdjuster <= (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING)) / 2 + 0.05 then
			Armlet.isArmletActive = Armlet.isArmletActive
		else
			Armlet.isArmletActive = true
		end
	else
		if os.clock() - Armlet.armletToggleTimePingAdjuster <= (NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) + NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING)) / 2 + 0.05 then
			Armlet.isArmletActive = Armlet.isArmletActive
		else
			Armlet.isArmletActive = false
		end
		if Armlet.isArmletManuallyToggled == true and GameRules.GetGameTime() - Armlet.isArmletManuallyToggledTime >= 0.1 then
			Armlet.isArmletManuallyToggled = false
		end
	end

	local armletModifier = NPC.GetModifier(myHero, "modifier_item_armlet_unholy_strength")
	local maxHPGain = 464
	if armletModifier ~= nil then
		local armletStartTime = Modifier.GetCreationTime(armletModifier)
		if GameRules.GetGameTime() - armletStartTime > 0.6 then
			Armlet.armletCurrentHPGain = maxHPGain
		else
			if GameRules.GetGameTime() - armletStartTime > 0 then
				Armlet.armletCurrentHPGain = math.floor((GameRules.GetGameTime() - armletStartTime) * (maxHPGain/0.6))
			end
		end
	else
		Armlet.armletCurrentHPGain = 0
	end

	if os.clock() < Armlet.armletDelayer then return end

	if Menu.IsEnabled(Armlet.ManuallyOverride) then
		if Armlet.isArmletManuallyToggled then 
			return 
		end
	end

	if Armlet.heroCanCastItems(myHero) == false then return end
	if Armlet.IsHeroInvisible(myHero) == true then return end

	if os.clock() < Armlet.armletToggleTime then return end

	if Armlet.armletShouldBeToggledOn(myHero) then
		Ability.Toggle(armlet)
		Armlet.isArmletActive = true
		Armlet.armletToggleTime = os.clock() + 0.65 + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
		Armlet.armletToggleTimePingAdjuster = os.clock()
		return
	end

	if Armlet.armletShouldBeToggledOff(myHero) then
		if os.clock() - Armlet.armletToggleTime > 0.04 then
			Ability.Toggle(armlet)
			Armlet.isArmletActive = false
			Armlet.armletToggleTime = os.clock() + 0.01
			Armlet.armletToggleTimePingAdjuster = os.clock()
			Armlet.armletToggleTimePingAdjuster = os.clock()
			return
		end
	end

end



function Armlet.OnUnitAnimation( animation )
	if not animation then return end
	if not Heroes.GetLocal() then return end
	
	
	if animation.unit and Entity.IsNPC(animation.unit) and not Entity.IsSameTeam(Heroes.GetLocal(), animation.unit) and animation.type == 1 then
		if not NPC.IsRanged(animation.unit) then
			local attackRange = NPC.GetAttackRange(animation.unit) + 155
			if NPC.IsEntityInRange(Heroes.GetLocal(), animation.unit, attackRange) and NPC.FindFacingNPC(animation.unit) == Heroes.GetLocal() then
				local damage = Armlet.getAdjustedMaxTrueDamage(animation.unit, Heroes.GetLocal())
				table.insert(Armlet.armletDamageInstanceTable, { instanceindex = Entity.GetIndex(animation.unit), time = Armlet.utilityRoundNumber((GameRules.GetGameTime() + animation.castpoint - 0.035 - NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING)), 3), casttime = animation.castpoint, backswingstart = GameRules.GetGameTime() + animation.castpoint - 0.035, backswingend = GameRules.GetGameTime() + NPC.GetAttackTime(animation.unit) - 0.035, type = "attack", damage = damage, isProjectile = false })
			end
		else
			local attackRange = NPC.GetAttackRange(animation.unit) + 264
			if Entity.IsHero(animation.unit) and NPC.IsEntityInRange(Heroes.GetLocal(), animation.unit, attackRange) and NPC.FindFacingNPC(animation.unit) == Heroes.GetLocal() then
				local myProjectedPosition = Entity.GetAbsOrigin(Heroes.GetLocal())
				local projectileTiming = ((Entity.GetAbsOrigin(animation.unit) - myProjectedPosition):Length2D() - NPC.GetHullRadius(Heroes.GetLocal())) / Armlet.attackPointTable[NPC.GetUnitName(animation.unit)][3]
				local damage = Armlet.getAdjustedMaxTrueDamage(animation.unit, Heroes.GetLocal())
				table.insert(Armlet.armletDamageInstanceTable, { instanceindex = Entity.GetIndex(animation.unit), time = Armlet.utilityRoundNumber((GameRules.GetGameTime() + animation.castpoint + projectileTiming - 0.035 - NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING)), 3), casttime = animation.castpoint, backswingstart = GameRules.GetGameTime() + animation.castpoint - 0.035, backswingend = GameRules.GetGameTime() + NPC.GetAttackTime(animation.unit) - 0.035, type = "rangeattack", damage = damage, projectileorigin = Entity.GetAbsOrigin(animation.unit), projectilestarttime = GameRules.GetGameTime() + animation.castpoint - 0.035, projectilespeed = Armlet.attackPointTable[NPC.GetUnitName(animation.unit)][3], isProjectile = true })
			end
		end
	end
end

function Armlet.OnProjectile(projectile)
	if not projectile then return end
	local myHero = Heroes.GetLocal()
	if not myHero then return end
	
	local armletProjectileList = ArmletSettings:GetProjectile()
	
	if projectile.source and Entity.IsNPC(projectile.source) and NPC.IsRanged(projectile.source) and not Entity.IsSameTeam(Heroes.GetLocal(), projectile.source) and projectile.isAttack then
		local attackRange = NPC.GetAttackRange(projectile.source)
		if not Entity.IsHero(projectile.source) then
			if projectile.target == Heroes.GetLocal() then
				local casttime = 0.5
					if Armlet.creepAttackPointData[NPC.GetUnitName(projectile.source)] ~= nil then
						casttime = Armlet.creepAttackPointData[NPC.GetUnitName(projectile.source)]
					end
				local myProjectedPosition = Entity.GetAbsOrigin(myHero)
				local projectileTiming = ((Entity.GetAbsOrigin(projectile.source) - myProjectedPosition):Length() - NPC.GetHullRadius(projectile.target)) / projectile.moveSpeed
				local damage = Armlet.getAdjustedMaxTrueDamage(projectile.source, Heroes.GetLocal())
				table.insert(Armlet.armletDamageInstanceTable, { instanceindex = Entity.GetIndex(projectile.source), time = Armlet.utilityRoundNumber((GameRules.GetGameTime() + projectileTiming - 0.035 - NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING)), 3), casttime = casttime, backswingstart = GameRules.GetGameTime() - 0.035, backswingend = GameRules.GetGameTime() + NPC.GetAttackTime(projectile.source) - casttime - 0.035, type = "rangeattack", damage = damage, projectileorigin = Entity.GetAbsOrigin(projectile.source), projectilestarttime = GameRules.GetGameTime() - 0.035, projectilespeed = projectile.moveSpeed, isProjectile = true })
			end
		else
			if projectile.target == Heroes.GetLocal() then
				local myProjectedPosition = Entity.GetAbsOrigin(myHero)
				local projectileTiming = ((Entity.GetAbsOrigin(projectile.source) - myProjectedPosition):Length2D() - NPC.GetHullRadius(projectile.target)) / projectile.moveSpeed
				local damage = Armlet.getAdjustedMaxTrueDamage(projectile.source, Heroes.GetLocal())
				local inserted = false
				for k, info in ipairs(Armlet.armletDamageInstanceTable) do
					if info and info.instanceindex == Entity.GetIndex(projectile.source) then
						if math.abs(info.time - Armlet.utilityRoundNumber((GameRules.GetGameTime() + projectileTiming - 0.035 - NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING)), 3)) < NPC.GetAttackTime(projectile.source) * 0.75 then
							inserted = true
						end
					end
				end
				if not inserted then
					local casttime = Armlet.attackPointTable[NPC.GetUnitName(projectile.source)][1] / (1 + NPC.GetIncreasedAttackSpeed(projectile.source))
					table.insert(Armlet.armletDamageInstanceTable, { instanceindex = Entity.GetIndex(projectile.source), time = Armlet.utilityRoundNumber((GameRules.GetGameTime() + projectileTiming - 0.035 - NetChannel.GetAvgLatency(Enum.Flow.FLOW_INCOMING)), 3), casttime = casttime, backswingstart = GameRules.GetGameTime() - 0.035, backswingend = GameRules.GetGameTime() + NPC.GetAttackTime(projectile.source) - casttime - 0.035, type = "rangeattack", damage = damage, projectileorigin = Entity.GetAbsOrigin(projectile.source), projectilestarttime = GameRules.GetGameTime() - 0.035, projectilespeed = projectile.moveSpeed, isProjectile = true })
				end	
			end
		end
	end
	
end

function Armlet.OnUpdate()

	if not Engine.IsInGame() then
		Armlet.ResetGlobalVariables()
	end
	
	if GameRules.GetGameState() < 4 then return end
	if GameRules.GetGameState() > 5 then return end
	
	local myHero = Heroes.GetLocal()
	if not myHero then return end
	if not Entity.IsAlive(myHero) then return end
		
	if Menu.IsEnabled(Armlet.ArmletEnabled) then
		Armlet.armletHandler(myHero)
	end
end

function Armlet.OnPrepareUnitOrders(orders)
	if not orders then return true end
	if orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_TRAIN_ABILITY then return true end

	local myHero = Heroes.GetLocal()
    		if not myHero then return true end
			
	if Menu.IsEnabled(Armlet.ArmletEnabled) and Menu.IsEnabled(Armlet.Illusion) then
		local armlet = NPC.GetItem(myHero, "item_armlet", true)
		if armlet and not Ability.GetToggleState(armlet) then
			local manta = NPC.GetItem(myHero, "item_manta", true)
			local ckUlt = NPC.GetAbility(myHero, "chaos_knight_phantasm")
			local terrorImg = NPC.GetAbility(myHero, "terrorblade_conjure_image")
			if manta or ckUlt or terrorImg then
				if orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET then
					if orders.ability == manta or orders.ability == terrorImg then
						Ability.Toggle(armlet, false)
						Armlet.armletDelayer = os.clock() + 0.25
						return true
					elseif orders.ability == ckUlt then
						Ability.Toggle(armlet, false)
						Armlet.armletDelayer = os.clock() + 0.75
						return true
					end
				end
			end
			local lsUlt = NPC.GetAbility(myHero, "life_stealer_infest")
			if lsUlt then
				if orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET then
					if orders.ability == lsUlt then
						if orders.target and Entity.IsHero(orders.target) and Entity.IsSameTeam(myHero, orders.target) then
							Ability.Toggle(armlet, false)
							Armlet.armletDelayer = os.clock() + (math.max(((Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(orders.target)):Length2D() - 150), 0) / NPC.GetMoveSpeed(myHero)) + 0.25
							return true
						end
					end
				end
			end
		end
		if armlet and Ability.GetToggleState(armlet) then
			local lsConsume = NPC.GetAbility(myHero, "life_stealer_consume")
			if lsConsume and not Ability.IsHidden(lsConsume) then
				if orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET then
					if orders.ability == lsConsume then
						Armlet.armletDelayer = os.clock() + 1.5
						return true
					end
				end
			end
		end
	end
	
	if Menu.IsEnabled(Armlet.ArmletEnabled) and Menu.IsEnabled(Armlet.RightClick) then
		local armlet = NPC.GetItem(myHero, "item_armlet", true)
		if armlet then
			if not Armlet.armletRightClickToggle then
				if orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET then
					if not Entity.IsSameTeam(myHero, orders.target) then
						if Menu.GetValue(Armlet.RightClickStyle) > 0 then
							if os.clock() - Armlet.armletRightClickDoubleClick > 0.3 then
								Armlet.armletRightClickDoubleClick = os.clock()
								return true
							else
								if os.clock() - Armlet.armletRightClickDoubleClick > 0.05 then
									Armlet.armletRightClickToggle = true
									Armlet.armletRightClickToggleTimer = os.clock()
									return true
								end
							end
						else
							Armlet.armletRightClickToggle = true
							Armlet.armletRightClickToggleTimer = os.clock()
							return true
						end
					end
				end
			else
				if os.clock() - Armlet.armletRightClickToggleTimer > 0.6 then
					if orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION then
						Armlet.armletRightClickToggle = false
						return true
					end
				end
			end
		end
	end
	
end

return Armlet
