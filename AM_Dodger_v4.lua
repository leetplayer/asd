local Utility = require("Utility")
-- local Invoker = require("Invoker")

local Dodge = {}

Dodge.option = Menu.AddOption({"Utility", "Am dodge"}, "Enable", "On/Off")

local msg_queue = {}
local DELTA = 0.05 -- maximun gap for equality
local ERROR = 0.2 -- systematic error

function Dodge.OnProjectile(projectile)
	if not Menu.IsEnabled(Dodge.option) then return end
	if not projectile or not projectile.source or not projectile.target then return end
	-- if not projectile.dodgeable then return end
	-- if not Entity.IsHero(projectile.source) then return end
	if projectile.isAttack then return end

	local myHero = Heroes.GetLocal()
	if not myHero then return end

	if projectile.target ~= myHero then return end
	if Entity.IsSameTeam(projectile.source, projectile.target) then return end

	local projectile_collision_size = 150
	local hero_collision_size = 24
	local vec1 = Entity.GetAbsOrigin(projectile.source)
	local vec2 = Entity.GetAbsOrigin(projectile.target)
	local dis = (vec1 - vec2):Length() - projectile_collision_size - hero_collision_size
	local delay = math.abs(dis) / (projectile.moveSpeed + 1)

	Dodge.Update({time = GameRules.GetGameTime(); delay = delay; desc = ""; source = projectile.source})
end

function Dodge.OnLinearProjectileCreate(projectile)
	if not Menu.IsEnabled(Dodge.option) then return end
	if not projectile or not projectile.origin or not projectile.velocity then return end

	local myHero = Heroes.GetLocal()
	if not myHero then return end
	if not projectile.source or Entity.IsSameTeam(myHero, projectile.source) then return end

	local pos = Entity.GetAbsOrigin(myHero)
	local vec1 = pos - projectile.origin
	local vec2 = projectile.velocity
	local cos_theta = vec1:Dot(vec2) / (vec1:Length() * vec2:Length())

	-- assume hit when cos(theta) = 1
	if math.abs(cos_theta - 1) > 0.05 then return end

	local projectile_collision_size = 150
	local hero_collision_size = 24
	local dis = vec1:Length() - projectile_collision_size - hero_collision_size
	local speed = projectile.velocity:Length()
	local delay = math.abs(dis) / (speed+1)

	Dodge.Update({time = GameRules.GetGameTime(); delay = delay; desc = ""; source = projectile.source})
end

function Dodge.OnUnitAnimation(animation)
	if not Menu.IsEnabled(Dodge.option) then return end
	if not animation or not animation.unit then return end

	local myHero = Heroes.GetLocal()
	if not myHero then return end
	if Entity.IsSameTeam(myHero, animation.unit) then return end

	local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(animation.unit)):Length()
	local hero_collision_size = 24
	distance = distance - hero_collision_size

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_bloodseeker" then
		local radius = 1052
		if animation.sequenceName == "cast4_rupture_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_crystal_maiden" then
		local radius = 702
		if animation.sequenceName == "frostbite_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_juggernaut" then
		local radius = 350 + 425
		if animation.sequenceName == "attack_omni_cast" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end
	
	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_lina" then
		local radius = 725
		if animation.sequenceName == "laguna_blade_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_lion" then
		local radius1 = 902
		if animation.sequenceName == "impale_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius1) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end

		local radius2 = 952
		if animation.sequenceName == "finger_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius2) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint+0.2; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_luna" then
		local radius = 852
		if animation.sequenceName == "moonfall_cast1_lucent_beam_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_necrolyte" then
		local radius = 702
		if animation.sequenceName == "cast_ult_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_ogre_magi" then
		local radius = 600
		if animation.sequenceName == "cast1_fireblast_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_pudge" then
		local radius = 250
		if animation.sequenceName == "pudge_dismember_start" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_rubick" then
		local radius = 700
		if animation.sequenceName == "rubick_cast_telekinesis_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_shadow_shaman" then
		local radius = 500
		if animation.sequenceName == "cast_channel_shackles_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_tinker" then
		local radius = 725 + 220
		if animation.sequenceName == "laser_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_vengefulspirit" then
		local radius = 560
		if animation.sequenceName == "magic_missile_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_winter_wyvern" then
		local radius = 800 + 500
		if animation.sequenceName == "cast04_winters_curse_flying_low_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_skeleton_king" then
		local radius = 577
		if animation.sequenceName == "cast1_hellfire_blast" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end

	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_zuus" then
		local radius = 900 + 375
		if animation.sequenceName == "zeus_cast2_lightning_bolt" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
		if animation.sequenceName == "zeus_cast4_thundergods_wrath" then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
		end
	end
	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_silencer" then
		local radius = 952
		if animation.sequenceName == "cast_LW_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
			end
		end
		if NPC.GetUnitName(animation.unit) == "npc_dota_hero_bane" then
		local radius = 777
		if animation.sequenceName == "fiends_grip_cast_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
			end
		end
		if NPC.GetUnitName(animation.unit) == "npc_dota_hero_lich" then
		local radius = 827
		if animation.sequenceName == "frost_nova_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
			end
		end
		if NPC.GetUnitName(animation.unit) == "npc_dota_hero_sven" then
		local radius = 650
		if animation.sequenceName == "shield_storm_bolt" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
			end
		end
		if NPC.GetUnitName(animation.unit) == "npc_dota_hero_spirit_breaker" then
		local radius = 700
		if animation.sequenceName == "ultimate_anim" and NPC.IsEntityInRange(myHero, animation.unit, radius) then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
			end
		end
	if NPC.GetUnitName(animation.unit) == "npc_dota_hero_axe" then
		local radius = 600
		if animation.sequenceName == "culling_blade_anim" then
			Dodge.Update({time = GameRules.GetGameTime(); delay = animation.castpoint; desc = ""; source = animation.unit})
			end
		end
end
function Dodge.OnUpdate()
	if not Menu.IsEnabled(Dodge.option) then return end
	local myHero = Heroes.GetLocal()
	if not myHero then return end

	Dodge.TaskManagement(myHero)

	-- when kunkka's X mark expire
	if NPC.HasModifier(myHero, "modifier_kunkka_x_marks_the_spot") then
		local mod = NPC.GetModifier(myHero, "modifier_kunkka_x_marks_the_spot")
		local timeLeft = Modifier.GetDieTime(mod) - GameRules.GetGameTime()
		-- make sure not be X_marked by teammate; 0.3s delay works
		if Modifier.GetDuration(mod) <= 5 and timeLeft <= 0.3 then
			Dodge.Update({time = GameRules.GetGameTime(); delay = 0; desc = ""})
		end
	end

	-- for few cases that fail in OnUnitAnimation()
	for i = 1, Heroes.Count() do
		local enemy = Heroes.Get(i)
		if enemy and not NPC.IsIllusion(enemy)
			and not Entity.IsSameTeam(myHero, enemy)
			and not Entity.IsDormant(enemy)
			and Entity.IsAlive(enemy) then

			-- axe's call
			local axe_call = NPC.GetAbility(enemy, "axe_berserkers_call")
			local call_range = 300
			if axe_call and Ability.IsInAbilityPhase(axe_call)
				and NPC.IsEntityInRange(myHero, enemy, call_range) then
				Dodge.Update({time = GameRules.GetGameTime(); delay = Ability.GetCastPoint(axe_call)/2; desc = ""; source = enemy})
				-- Dodge.DefendWithDelay(Ability.GetCastPoint(axe_call)/2)
			end

			-- shadow fiend's raze
			local raze_1 = NPC.GetAbility(enemy, "nevermore_shadowraze1")
			local raze_2 = NPC.GetAbility(enemy, "nevermore_shadowraze2")
			local raze_3 = NPC.GetAbility(enemy, "nevermore_shadowraze3")
			local range_1, range_2, range_3 = 200, 450, 700
			local direction = Entity.GetAbsRotation(enemy):GetForward():Normalized()
			local pos_1 = Entity.GetAbsOrigin(enemy) + direction:Scaled(range_1)
			local pos_2 = Entity.GetAbsOrigin(enemy) + direction:Scaled(range_2)
			local pos_3 = Entity.GetAbsOrigin(enemy) + direction:Scaled(range_3)
			local radius = 250
			if (raze_1 and Ability.IsInAbilityPhase(raze_1) and NPC.IsPositionInRange(myHero, pos_1, radius, 0))
				or (raze_2 and Ability.IsInAbilityPhase(raze_2) and NPC.IsPositionInRange(myHero, pos_2, radius, 0))
				or (raze_3 and Ability.IsInAbilityPhase(raze_3) and NPC.IsPositionInRange(myHero, pos_3, radius, 0))
				then
				Dodge.Update({time = GameRules.GetGameTime(); delay = Ability.GetCastPoint(raze_1)-0.2; desc = ""; source = enemy})
				-- Dodge.DefendWithDelay(Ability.GetCastPoint(raze_1)/2)
			end

		end
	end

end

function Dodge.TaskManagement(myHero)
	if not msg_queue or #msg_queue <= 0 then return end

	local info = table.remove(msg_queue, 1)
	if not info or not info.time or not info.delay then return end

	local currentTime = GameRules.GetGameTime()
	local diff = info.delay - ERROR -- should consider backswing for specific hero
	local executeTime = info.time + math.max(diff, 0)


	if currentTime > executeTime + DELTA then return end
	if currentTime < executeTime - DELTA then Dodge.Update(info) return end

	-- executeTime - DELTA <= currentTime <= executeTime + DELTA
	Dodge.Defend(myHero, info.source)
end

-- info: {time; delay; desc; source}
function Dodge.Update(info)
	if not info then return end

	local myHero = Heroes.GetLocal()
	if not myHero then return end

	-- no delay for invoker's spells
	if NPC.GetUnitName(myHero) == "npc_dota_hero_invoker" then
		info.delay = 0
	end

	if NPC.GetUnitName(myHero) == "npc_dota_hero_obsidian_destroyer" then
		info.delay = info.delay - 0.25 -- imprison has 0.25s castpoint
	end

	table.insert(msg_queue, info)
end

function Dodge.Defend(myHero, source)
	if not myHero then return end
	if NPC.IsSilenced(myHero) then return end
	local myMana = NPC.GetMana(myHero)
		if NPC.GetUnitName(myHero) == "npc_dota_hero_antimage" then
		local ant = NPC.GetAbilityByIndex(myHero, 2)
		if ant and Ability.IsCastable(ant, myMana) then
			Ability.CastNoTarget(ant)
		end
	end
end

return Dodge
