local LAIO = {}
local Wrap = require("scripts.modules.WrapUtility")
LAIO.optionHeroSF = Menu.AddOptionBool({"Герои", "[TEST] СФ"}, "Включить", false)
LAIO.optionHeroSFEulCombo = Menu.AddKeyOption({"Герои", "[TEST] СФ"}, "Еул-Блинк-Ульт Комбо ", Enum.ButtonCode.KEY_NONE)
LAIO.optionHeroSFDrawReqDMG = Menu.AddOptionBool({"Герои", "[TEST] СФ"}, "Показывать урон", false)
LAIO.skywrathFont = Renderer.LoadFont("Tahoma", 12, Enum.FontWeight.EXTRABOLD)
function LAIO.OnDraw()
	if not Menu.IsEnabled(LAIO.optionHeroSF) then return end
	local myHero = Heroes.GetLocal()
        	if not myHero then return end
			
	if not Wrap.EIsAlive(myHero) then return end
	if NPC.GetUnitName(myHero) == "npc_dota_hero_nevermore" then
		LAIO.SFComboDrawRequiemDamage(myHero)
	end
end

function LAIO.getComboTarget(myHero)

	if not myHero then return end

	local targetingRange = 400
	local mousePos = Input.GetWorldCursorPos()

	local enemyTable = Wrap.HInRadius(mousePos, targetingRange, Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
		if #enemyTable < 1 then return end

	local nearestTarget = nil
	local distance = 99999

	for i, v in ipairs(enemyTable) do
		if v and Entity.IsHero(v) then
			if LAIO.targetChecker(v) ~= nil then
				local enemyDist = (Entity.GetAbsOrigin(v) - mousePos):Length2D()
				if enemyDist < distance then
					nearestTarget = v
					distance = enemyDist
				end
			end
		end
	end

	return nearestTarget or nil

end

function LAIO.OnUpdate()

	local LockedTarget = nil
	if not Menu.IsEnabled(LAIO.optionHeroSF) then return end
	if GameRules.GetGameState() < 4 then return end
	if GameRules.GetGameState() > 5 then return end
	local myHero = Heroes.GetLocal()
	local myUnitName = nil
	if not myHero then return end
	if not Wrap.EIsAlive(myHero) then return end
	if myUnitName == nil then
		myUnitName = NPC.GetUnitName(myHero)
	end
	local enemy = LAIO.getComboTarget(myHero)
	if Menu.IsKeyDown(LAIO.optionHeroSFEulCombo) then
		if enemy then
			LockedTarget = enemy
		else
			LockedTarget = nil
		end
	else
		LockedTarget = nil
	end
	if LockedTarget ~= nil then
		if not Wrap.EIsAlive(LockedTarget) then
			LAIO.LockedTarget = nil
		elseif Entity.IsDormant(LockedTarget) then
			LockedTarget = nil
		elseif not NPC.IsEntityInRange(myHero, LockedTarget, 3000) then
			LockedTarget = nil
		end
	end
	
	local comboTarget
		if LockedTarget ~= nil then
			comboTarget = LockedTarget
		else
			if not Menu.IsKeyDown(LAIO.optionHeroSFEulCombo ) then
				comboTarget = enemy
			end
		end
	if myUnitName == "npc_dota_hero_nevermore" then
		LAIO.SFCombo(myHero, comboTarget)
	end
end


function LAIO.heroCanCastSpells(myHero, enemy)

	if not myHero then return false end
	if not Wrap.EIsAlive(myHero) then return false end

	if NPC.IsSilenced(myHero) then return false end 
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

	if enemy then
		if NPC.HasModifier(enemy, "modifier_item_aeon_disk_buff") then return false end
	end

	return true	

end
	
	
function LAIO.SFCombo(myHero, enemy)
	if not Menu.IsEnabled(LAIO.optionHeroSF) then return end

	local razeShort = NPC.GetAbilityByIndex(myHero, 0)
    local razeMid = NPC.GetAbilityByIndex(myHero, 1)
    local razeLong = NPC.GetAbilityByIndex(myHero, 2)
	local requiem = NPC.GetAbility(myHero, "nevermore_requiem")
	local myMana = NPC.GetMana(myHero)

	local blink = NPC.GetItem(myHero, "item_blink", true)
	local eul = NPC.GetItem(myHero, "item_cyclone", true)
	if enemy then
		if eul and requiem and Ability.IsCastable(requiem, myMana) then
			if Menu.IsKeyDown(LAIO.optionHeroSFEulCombo) and Entity.GetHealth(enemy) > 0 then
				if not NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) and LAIO.heroCanCastSpells(myHero, enemy) == true then
					local possibleRange = 0.80 * NPC.GetMoveSpeed(myHero)
					if not NPC.IsEntityInRange(myHero, enemy, possibleRange) then
						if blink and Ability.IsReady(blink) and NPC.IsEntityInRange(myHero, enemy, 1175 + 0.75 * possibleRange) then
							Ability.CastPosition(blink, (Entity.GetAbsOrigin(enemy) + (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Normalized()))
							return
						end
					else
						if Ability.IsCastable(eul, myMana) then
							Ability.CastTarget(eul, enemy)
							return
						end
						if NPC.HasModifier(enemy, "modifier_eul_cyclone") then
								local cycloneDieTime = Modifier.GetDieTime(NPC.GetModifier(enemy, "modifier_eul_cyclone"))
								if cycloneDieTime - GameRules.GetGameTime() <= 1.63 then
									Ability.CastNoTarget(requiem)
									return
							end
						end
					end	
				end
			end
		end
	end
end
function LAIO.targetChecker(genericEnemyEntity)

	local myHero = Heroes.GetLocal()
		if not myHero then return end

	if genericEnemyEntity and not Entity.IsDormant(genericEnemyEntity) and not NPC.IsIllusion(genericEnemyEntity) and Entity.GetHealth(genericEnemyEntity) > 0 then
	return genericEnemyEntity
	end	
end
function LAIO.SFComboDrawRequiemDamage(myHero)

	if not myHero then return end
	if not Menu.IsEnabled(LAIO.optionHeroSFDrawReqDMG) then return end

	local enemy = LAIO.targetChecker(Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY))
		if not enemy then return end
		if not NPC.IsPositionInRange(enemy, Input.GetWorldCursorPos(), 500, 0) then return end

	local pos = Entity.GetAbsOrigin(enemy)
	local posY = NPC.GetHealthBarOffset(enemy)
		pos:SetZ(pos:GetZ() + posY)
			
	local x, y, visible = Renderer.WorldToScreen(pos)

	local requiem = NPC.GetAbility(myHero, "nevermore_requiem")
	local myMana = NPC.GetMana(myHero)

	local stackCounter = 0
		if NPC.HasModifier(myHero, "modifier_nevermore_necromastery") then
			stackCounter = Modifier.GetStackCount(NPC.GetModifier(myHero, "modifier_nevermore_necromastery"))
		end

	local aghanims = NPC.GetItem(myHero, "item_ultimate_scepter", true)

	local requiemDamage = Ability.GetDamage(requiem) * (math.floor(stackCounter/2))
		if aghanims or NPC.HasModifier(myHero, "modifier_item_ultimate_scepter_consumed") then
			requiemDamage = requiemDamage + Ability.GetLevelSpecialValueForFloat(requiem, "requiem_damage_pct_scepter") * (math.floor(stackCounter/2))
		end
	local requiemTrueDamage = (1 - NPC.GetMagicalArmorValue(enemy)) * (requiemDamage + requiemDamage * (Hero.GetIntellectTotal(myHero) / 14 / 100))

	local remainingHP = math.floor(Entity.GetHealth(enemy) - requiemTrueDamage)
		if remainingHP < 0 then
			remainingHP = 0
		end

	if requiem and Ability.IsCastable(requiem, myMana) then
		if visible then
			if Entity.GetHealth(enemy) > requiemTrueDamage then
				Renderer.SetDrawColor(255,102,102,255)
			else
				Renderer.SetDrawColor(50,205,50,255)
			end
			Renderer.DrawText(LAIO.skywrathFont, x-60, y-70, "Полный урон ульты:   " .. math.floor(requiemTrueDamage) .. "  (" .. remainingHP .. ")", 0)
		end
	end	

end

return LAIO