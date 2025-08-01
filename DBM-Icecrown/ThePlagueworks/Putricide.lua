local mod	= DBM:NewMod("Putricide", "DBM-Icecrown", 2)
local L		= mod:GetLocalizedStrings()
local sformat = string.format

mod:SetRevision("20250801233610")
mod:SetCreatureID(36678)
mod:SetUsedIcons(1, 2, 3, 4)
mod:SetHotfixNoticeRev(20250801000000)
mod:SetMinSyncRevision(20220908000000)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 70351 71966 71967 71968 71617 72842 72843 72851 72852 71621 72850 70672 72455 72832 72833 73121 73122 73120 71893",
	"SPELL_CAST_SUCCESS 70341 71255 72855 72856 70911 72615 72295 74280 74281",
	"SPELL_AURA_APPLIED 70447 72836 72837 72838 70672 72455 72832 72833 72451 72463 72671 72672 70542 70539 72457 72875 72876 70352 74118 70353 74119 72855 72856 70911",
	"SPELL_AURA_APPLIED_DOSE 72451 72463 72671 72672 70542",
	"SPELL_AURA_REFRESH 70539 72457 72875 72876 70542",
	"SPELL_AURA_REMOVED 70447 72836 72837 72838 70672 72455 72832 72833 72855 72856 70911 71615 70539 72457 72875 72876 70542",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_HEALTH"
--	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

-- General
local berserkTimer					= mod:NewBerserkTimer(600)

-- buffs from "Drink Me"
local timerMutatedSlash				= mod:NewTargetTimer(20, 70542, nil, false, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerRegurgitatedOoze			= mod:NewTargetTimer(20, 70539, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)

-- Stage One
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": 100% – 80%")
local warnSlimePuddle				= mod:NewSpellAnnounce(70341, 2)
local warnUnstableExperimentSoon	= mod:NewSoonAnnounce(70351, 3)
local warnUnstableExperiment		= mod:NewSpellAnnounce(70351, 4)
local warnVolatileOozeAdhesive		= mod:NewTargetNoFilterAnnounce(70447, 3)
local warnGaseousBloat				= mod:NewTargetNoFilterAnnounce(70672, 3)
local warnUnboundPlague				= mod:NewTargetNoFilterAnnounce(70911, 3, nil, false, nil, nil, nil, true)		-- Heroic Ability, sound muted

local specWarnVolatileOozeAdhesive	= mod:NewSpecialWarningYou(70447, nil, nil, nil, 1, 2)
local specWarnVolatileOozeAdhesiveT	= mod:NewSpecialWarningMoveTo(70447, nil, nil, nil, 1, 2)
local specWarnGaseousBloat			= mod:NewSpecialWarningRun(70672, nil, nil, nil, 4, 2)
local specWarnGaseousBloatCast		= mod:NewSpecialWarningMove(72833, nil, nil, nil, 1, 2)		-- Gaseous Bloat (cast)
local specWarnUnboundPlague			= mod:NewSpecialWarningYou(70911, nil, nil, nil, 1, 2, 3)	-- Heroic Ability
local yellUnboundPlague				= mod:NewYellMe(70911, false)	-- Heroic Ability, disabled by default to reduce chat bubble spam

local timerGaseousBloat				= mod:NewTargetTimer(20, 70672, nil, nil, nil, 3)			-- Duration of debuff
local timerGaseousBloatCast			= mod:NewCastTimer(3, 70672, nil, nil, nil, 3)				-- Cast duration
local timerSlimePuddleCD			= mod:NewNextTimer(35, 70341, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON) -- Almost no variance. SPELL_CAST_SUCCESS: (Aura 3.3.5: 25H [2025-07-23]@[16:15:59]) - "Charco de baba-70341-npc:36678-8412675 = pull:9.88/[Stage 1/0.15] 9.74, 0.00, Intermission 1/25.46, Stage 1.5/35.01, 4.51/39.52/64.98, 0.00, 35.04, 0.00, 35.10, 0.00, 35.07, 0.00, Intermission 2/36.03, Stage 2/28.02, 1.01/29.02/65.05, 0.00, 35.14, 0.00, 35.07, 0.00"
local timerUnstableExperimentCD		= mod:NewVarTimer("v35-40", 70351, nil, nil, nil, 1, nil, DBM_COMMON_L.DEADLY_ICON, true) -- 5s variance [35-40]. Added "keep" arg. SPELL_CAST_START: (Aura 3.3.5: 25H [2025-07-23]@[16:15:59]) - "Experimento inestable-71968-npc:36678-8412675 = pull:30.66/[Stage 1/0.15] 30.52, Intermission 1/4.68, Stage 1.5/35.01, 27.12/62.14/66.81, 35.96, 38.84, 38.19, Intermission 2/5.64, Stage 2/28.02",
local timerUnboundPlagueCD			= mod:NewNextTimer(90, 70911, nil, nil, nil, 3, nil, DBM_COMMON_L.HEROIC_ICON) -- REVIEW! SPELL_CAST_SUCCESS: (Aura 3.3.5: 25H [2025-07-23]@[16:15:59]) - "Peste desatada-72856-npc:36678-8412675 = pull:19.82/[Stage 1/0.15] 19.68, Intermission 1/15.52, Stage 1.5/35.01, 69.58/104.59/120.11, Intermission 2/76.17, Stage 2/28.02, 15.86/43.88/120.05"
local timerUnboundPlague			= mod:NewBuffActiveTimer(12, 70911, nil, nil, nil, 3)		-- Heroic Ability: we can't keep the debuff 60 seconds, so we have to switch at 12-15 seconds. Otherwise the debuff does to much damage!

local soundSlimePuddle				= mod:NewSound(70341)

mod:AddSetIconOption("OozeAdhesiveIcon", 70447, true, 0, {4})--green icon for green ooze
mod:AddSetIconOption("GaseousBloatIcon", 70672, true, 0, {2})--Orange Icon for orange/red ooze
mod:AddSetIconOption("UnboundPlagueIcon", 70911, true, 0, {3})

-- Stage Two
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": 80% – 35%")
local warnPhase2					= mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnChokingGasBombSoon		= mod:NewPreWarnAnnounce(71255, 5, 3, nil, "Melee")
local warnChokingGasBomb			= mod:NewSpellAnnounce(71255, 3, nil, "Melee")		-- Phase 2 ability

--local specWarnMalleableGoo			= mod:NewSpecialWarningYou(72295, nil, nil, nil, 1, 2)
--local yellMalleableGoo				= mod:NewYellMe(72295)
--local specWarnMalleableGooNear		= mod:NewSpecialWarningClose(72295, nil, nil, nil, 1, 2)
local specWarnChokingGasBomb		= mod:NewSpecialWarningMove(71255, "Melee", nil, nil, 1, 2)
local specWarnMalleableGooCast		= mod:NewSpecialWarningSpell(72295, "Ranged", nil, nil, 2, 2)

local timerChokingGasBombCD			= mod:NewVarTimer("v35-40", 71255, nil, nil, nil, 3, nil, nil, true) -- 5s variance [35-40]. Added "keep" arg. SPELL_CAST_SUCCESS: (Aura 3.3.5: 25H [2025-07-23]@[16:15:59]) - "Bomba de gas asfixiante-71255-npc:36678-8412675 = pull:82.48/[Stage 1/0.15, Intermission 1/35.20, Stage 1.5/35.01] 12.12/47.14/82.33, 36.28, 37.85, 38.72, Intermission 2/20.77, Stage 2/28.02, 20.54/48.56/69.33, 39.98",
local timerChokingGasBombExplosion	= mod:NewCastTimer(12, 71279, nil, nil, nil, 2)
local timerMalleableGooCD			= mod:NewVarTimer("v28-32", 72295, nil, nil, nil, 3, nil, nil, true) -- REVIEW! ~4s variance [28-32]? Added "keep" arg. CHAT_MSG_RAID_BOSS_EMOTE: (Aura 3.3.5: 25H [2025-07-23]@[16:15:59]) - "?-|TInterface\\Icons\\inv_misc_herb_evergreenmoss.blp:16|t ¡%s lanza |cFF00FF00Moco maleable!|r-npc:Profesor Putricidio = pull:94.75/[Stage 1/0.15, Intermission 1/35.20, Stage 1.5/35.01] 24.40/59.41/94.61, 28.53, 29.87, 28.68, 31.23, Intermission 2/3.04, Stage 2/28.02, 26.38/54.40/57.44, 29.56",

local soundSpecWarnMalleableGoo		= mod:NewSound(72295, nil, "Ranged")
local soundMalleableGooSoon			= mod:NewSoundSoon(72295, nil, "Ranged")
local soundSpecWarnChokingGasBomb	= mod:NewSound(71255, nil, "Melee")
local soundChokingGasSoon			= mod:NewSoundSoon(71255, nil, "Melee")

--mod:AddSetIconOption("MalleableGooIcon", 72295, true, 0, {1})
--mod:AddArrowOption("GooArrow", 72295)

-- Stage Three
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(3)..": 35% – 0%")
local warnPhase3					= mod:NewPhaseAnnounce(3, 2, nil, nil, nil, nil, nil, 2)
local warnMutatedPlague				= mod:NewStackAnnounce(72451, 3, nil, "Tank|Healer|RemoveEnrage") -- Phase 3 ability

local timerMutatedPlagueCD			= mod:NewNextTimer(10, 72451, nil, "Tank|Healer|RemoveEnrage", nil, 5, nil, DBM_COMMON_L.TANK_ICON) -- 10 to 11. SPELL_AURA_APPLIED: (Aura 3.3.5: 25H [2025-07-23]@[16:15:59]) - "Peste mutada-72672-npc:36678-8412675 = pull:248.85/[Stage 1/0.15, Intermission 1/35.20, Stage 1.5/35.01, Intermission 2/145.75, Stage 2/28.02] 4.73/32.75/178.49/213.51/248.70, 10.00, 10.06, 10.06, 10.09, 10.05, 10.07, 10.09, 10.13"

-- Intermission
mod:AddTimerLine(DBM_COMMON_L.INTERMISSION)
local warnPhase2Soon				= mod:NewPrePhaseAnnounce(2)
local warnPhase3Soon				= mod:NewPrePhaseAnnounce(3)
local warnTearGas					= mod:NewSpellAnnounce(71617, 2)		-- Phase transition normal
local warnVolatileExperiment		= mod:NewSpellAnnounce(72843, 4)		-- Phase transition heroic
local warnReengage					= mod:NewAnnounce("WarnReengage", 6, 1180)

local specWarnOozeVariable			= mod:NewSpecialWarningYou(70352, nil, nil, nil, nil, nil, 3)	-- Heroic Ability
local specWarnGasVariable			= mod:NewSpecialWarningYou(70353, nil, nil, nil, nil, nil, 3)	-- Heroic Ability

local timerNextPhase				= mod:NewPhaseTimer(30)
local timerReengage					= mod:NewTimer(20, "TimerReengage", 1180, nil, nil, 6)
--local timerTearGas					= mod:NewBuffFadesTimer(16, 71617, nil, nil, nil, 6)
--local timerPotions					= mod:NewBuffActiveTimer(30, 71621, nil, nil, nil, 6)

mod:GroupSpells(71255, 71279) -- Choking Gas Bomb, Choking Gas Explosion

local redOozeGUIDsCasts = {}
local firstIntermisisonUnboundElapsed = 0
local timerDelay = 30
mod.vb.warned_preP2 = false
mod.vb.warned_preP3 = false
mod.vb.unboundCount = 0

local function NextPhase(self)
	self:SetStage(self.vb.phase + 0.5)
	if self.vb.phase == 2 then
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		timerUnstableExperimentCD:Start(30+7)
		warnUnstableExperimentSoon:Schedule(25+7)
		-- EVENT_PHASE_TRANSITION - scheduled for Create Concoction cast + 100 ms (will fire [CHAT_MSG_MONSTER_YELL] Hrm, I don't feel a thing. Wha?! Where'd those come from?)
		timerMalleableGooCD:Start(15) -- Fixed timer after phase 2: 15s
		soundMalleableGooSoon:Schedule(15-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable_soon.mp3")
		timerChokingGasBombCD:Start(25) -- timer after phasing: 5s variance [25-30s]
		soundChokingGasSoon:Schedule(25-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\choking_soon.mp3")
		warnChokingGasBombSoon:Schedule(25-5)
	--	self:UnregisterShortTermEvents() -- UnregisterShortTermEvents moved here to ensure UNIT_TARGET is unregistered (previously was running on sync, which is not always used)
	elseif self.vb.phase == 3 then
		warnPhase3:Show()
		warnPhase3:Play("pthree")
		-- EVENT_PHASE_TRANSITION - scheduled for Guzzle Potions cast + 100 ms (will fire [CHAT_MSG_MONSTER_YELL] Tastes like... Cherry! OH! Excuse me!)
	--	self:UnregisterShortTermEvents() -- UnregisterShortTermEvents moved here to ensure UNIT_TARGET is unregistered (previously was running on sync, which is not always used)
	end
end

-- This does not work on Warmane - boss never swaps targets to throw malleable (last checked on 14/07/2021)
--[[function mod:MalleableGooTarget(targetname, uId)
	if not targetname then return end
		if self.Options.MalleableGooIcon then
			self:SetIcon(targetname, 1, 10)
		end
	if targetname == UnitName("player") then
		specWarnMalleableGoo:Show()
		specWarnMalleableGoo:Play("targetyou")
		yellMalleableGoo:Yell()
		soundSpecWarnMalleableGoo:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable.mp3")
	else
		if self:CheckNearby(11, targetname) then
			specWarnMalleableGooNear:Show(targetname)
			specWarnMalleableGooNear:Play("watchstep")
			soundSpecWarnMalleableGoo:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable.mp3")
		else
			specWarnMalleableGooCast:Show()
			specWarnMalleableGooCast:Play("watchstep")
			soundSpecWarnMalleableGoo:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable.mp3")
		end
		if self.Options.GooArrow then
			local x, y = GetPlayerMapPosition(uId)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(uId)
			end
			DBM.Arrow:ShowRunAway(x, y, 10, 5)
		end
	end
end]]

function mod:OnCombatStart(delay)
	self:SetStage(1)
	berserkTimer:Start(-delay)
	timerSlimePuddleCD:Start(10-delay)
	timerUnstableExperimentCD:Start(sformat("v%s-%s", 30-delay, 35-delay))
	warnUnstableExperimentSoon:Schedule(25-delay)
	table.wipe(redOozeGUIDsCasts)
	firstIntermisisonUnboundElapsed = 0
	self.vb.warned_preP2 = false
	self.vb.warned_preP3 = false
	self.vb.unboundCount = 0
	if self:IsHeroic() then
		timerUnboundPlagueCD:Start(20-delay)
	end
end

--[[function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
end]]

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if args:IsSpellID(70351, 71966, 71967, 71968) then	-- Unstable Experiment
		warnUnstableExperimentSoon:Cancel()
		warnUnstableExperiment:Show()
		timerUnstableExperimentCD:Start()
		warnUnstableExperimentSoon:Schedule(30)
	elseif spellId == 71617 then				--Tear Gas (stun all on Normal phase) (Normal intermission)
		self:SetStage(self.vb.phase + 0.5) -- ACTION_CHANGE_PHASE
		warnTearGas:Show()
		local puddleElapsed = timerSlimePuddleCD:GetTime()
		timerSlimePuddleCD:Update(puddleElapsed, 59) -- the next Normal Slime Puddle will always be [59.03:25N/59.03:10N]s after the previous Slime Puddle cast, so calculate elapsed time and update timer
		if self.vb.phase == 2.5 then -- Usual timer delta is not reliable for Malleable Goo, it's a different logic, commented below
			local gooElapsed = timerMalleableGooCD:GetTime() -- On second Normal intermission, the next Malleable Goo will always be [44:25N/44:10N]s after the previous Malleable Goo cast, so calculate elapsed time and update timer
			timerMalleableGooCD:Update(gooElapsed, 44)
			soundMalleableGooSoon:Schedule(44-gooElapsed-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable_soon.mp3")
			local chokingElapsed = timerChokingGasBombCD:GetTime() -- On second Normal intermission, the next Choking Gas Bomb will always be [59.28-61.10:25N/60.17:10N]s after the previous Choking Gas Bomb cast, so calculate elapsed time and update timer
			timerChokingGasBombCD:Update(chokingElapsed, 59)
			soundChokingGasSoon:Schedule(59-chokingElapsed-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\choking_soon.mp3")
			warnChokingGasBombSoon:Schedule(59-chokingElapsed-5)
		end
	elseif args:IsSpellID(72842, 72843) then		--Volatile Experiment (Heroic intermission)
		DBM:AddMsg("Volatile Experiment SPELL_CAST_START script fixed. Notify Zidras on Discord or GitHub")
		self:SetStage(self.vb.phase + 0.5) -- ACTION_CHANGE_PHASE
		warnVolatileExperiment:Show()
		warnUnstableExperimentSoon:Cancel()
		timerUnstableExperimentCD:Cancel()
		local puddleElapsed = timerSlimePuddleCD:GetTime()
		local puddleMaxTimePerDifficulty = self:IsDifficulty("heroic25") and 75 or self:IsDifficulty("heroic10") and 85 or 59 -- the next Heroic Slime Puddle will always be [75.05:25H/84.99:10H]s after the previous Slime Puddle cast, so calculate elapsed time and update timer
		timerSlimePuddleCD:Update(puddleElapsed, puddleMaxTimePerDifficulty)
		local unboundElapsed = timerUnboundPlagueCD:GetTime()
		if self.vb.phase == 1.5 then
			firstIntermisisonUnboundElapsed = unboundElapsed -- cache for second intermission if necessary
			timerUnboundPlagueCD:Update(unboundElapsed, 130)
		elseif self.vb.phase == 2.5 then
			if self.vb.unboundCount == 1 then -- only 1 Unbound Plague cast during whole raid (rushed phase 2)
				timerUnboundPlagueCD:Update(firstIntermisisonUnboundElapsed, 170) -- 170s between Unbound Plague from Phase 1 and Phase 3
			else
				timerUnboundPlagueCD:Update(unboundElapsed, 130) -- REVIEW! One log had 220.04 (25H Lordaeron [2024-05-21]@[21:15:56]), it needs investigation
			end
			local gooElapsed = timerMalleableGooCD:GetTime() -- On second Heroic intermission, the next Malleable Goo will always be [60:25H/70:10H]s after the previous Malleable Goo cast, so calculate elapsed time and update timer
			local gooMaxTimePerDifficulty = self:IsDifficulty("heroic25") and 60 or self:IsDifficulty("heroic10") and 70 or 44 -- REVIEW! 25H confirmed, 10H need more data, 25N only one log, 10N only one log
			timerMalleableGooCD:Update(gooElapsed, gooMaxTimePerDifficulty)
			soundMalleableGooSoon:Schedule(gooMaxTimePerDifficulty-gooElapsed-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable_soon.mp3")
			local chokingElapsed = timerChokingGasBombCD:GetTime() -- On second Heroic intermission, the next Choking Gas Bomb will always be [75-80:25H/89.39:10H]s after the previous Choking Gas Bomb cast, so calculate elapsed time and update timer
			local chokingMaxTimePerDifficulty = self:IsDifficulty("heroic25") and 75 or self:IsDifficulty("heroic10") and 85 or 59 -- REVIEW! 25H confirmed, 10H only one log, 25N only two log, 10N only one log
			timerChokingGasBombCD:Update(chokingElapsed, chokingMaxTimePerDifficulty)
			soundChokingGasSoon:Schedule(chokingMaxTimePerDifficulty-chokingElapsed-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\choking_soon.mp3")
			warnChokingGasBombSoon:Schedule(chokingMaxTimePerDifficulty-chokingElapsed-5)
		end
	elseif args:IsSpellID(72851, 72852, 71621, 72850) then		--Create Concoction (phase2 change)
		local castTime = self:IsHeroic() and 30 or 4 -- Normal and Heroic have different cast times, so hardcode the cast time in seconds. DO NOT USE GetSpellInfo API here, as it is affected by player Haste.
		warnUnstableExperimentSoon:Cancel()
		timerUnstableExperimentCD:Cancel()
		timerNextPhase:Start(castTime) -- Script phasing happens right after UNIT_SPELLCAST_SUCCEEDED. Boss re-engage is timed to account for the remaining time (check YELL)
		self:Schedule(castTime, NextPhase, self) -- prefer scheduling over UNIT_SPELLCAST_SUCCEEDED because on Normal difficulty Create Concoction does not fire UNIT_SPELLCAST_SUCCEEDED, only _STOP. This has the benefit of also being cross-server
		if self:IsHeroic() then
--			if self:IsDifficulty("heroic10") then -- Apply to both 10H and 25H (reason below)
				-- self:Schedule(35.63, NextPhase, self) -- using longest timer found, since this is a schedule
				self:RegisterShortTermEvents(
					"UNIT_TARGET"
				)
--			end
		end
	elseif args:IsSpellID(70672, 72455, 72832, 72833) then	--Red Slime
		timerGaseousBloatCast:Start(args.sourceGUID) -- account for multiple red oozes
		if not redOozeGUIDsCasts[args.sourceGUID] then
			redOozeGUIDsCasts[args.sourceGUID] = 1
		else
			redOozeGUIDsCasts[args.sourceGUID] = redOozeGUIDsCasts[args.sourceGUID] + 1
		end
		if redOozeGUIDsCasts[args.sourceGUID] > 1 then -- Red Ooze retarget
			specWarnGaseousBloatCast:Show()
			specWarnGaseousBloatCast:Play("targetchange")
		end
	elseif args:IsSpellID(73121, 73122, 73120, 71893) then		--Guzzle Potions (phase3 change)
		local castTime = self:IsDifficulty("heroic25") and 20 or self:IsDifficulty("heroic10") and 30 or 4 -- Normal, Heroic10 and Heroic25 have different cast times, so hardcode the cast time in seconds. DO NOT USE GetSpellInfo API here, as it is affected by player Haste.
		timerUnstableExperimentCD:Cancel()
		timerNextPhase:Start(castTime) -- Script phasing happens right after UNIT_SPELLCAST_SUCCEEDED. Boss re-engage is timed to account for the remaining time (check YELL)
		self:Schedule(castTime, NextPhase, self) -- prefer scheduling over UNIT_SPELLCAST_SUCCEEDED because on Normal difficulty Guzzle Potions does not fire UNIT_SPELLCAST_SUCCEEDED, only _STOP. This has the benefit of also being cross-server
		if self:IsHeroic() then
			--self:Schedule(38.69, NextPhase, self) -- REVIEW! using longest timer found, since this is a schedule
			--timerNextPhase:Start(38.67) -- (10H Lordaeron [2023-08-12]@[20:34:20]) - 38.67
			self:RegisterShortTermEvents(
				"UNIT_TARGET"
			)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 70341 and self:AntiSpam(5, 1) then
		warnSlimePuddle:Show()
		soundSlimePuddle:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\puddle_cast.mp3")
		timerSlimePuddleCD:Start()
	elseif spellId == 71255 then -- Choking Gas
		warnChokingGasBomb:Show()
		specWarnChokingGasBomb:Show()
		soundSpecWarnChokingGasBomb:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\choking.mp3")
		soundChokingGasSoon:Cancel()
		soundChokingGasSoon:Schedule(35.5-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\choking_soon.mp3")
		timerChokingGasBombCD:Start()
		timerChokingGasBombExplosion:Start()
		warnChokingGasBombSoon:Schedule(30.5)
	elseif args:IsSpellID(72855, 72856, 70911) then
		self.vb.unboundCount = self.vb.unboundCount + 1
		timerUnboundPlagueCD:Start()
	elseif args:IsSpellID(72615, 72295, 74280, 74281) then -- Malleable Goo
		DBM:AddMsg("Malleable Goo SPELL_CAST_SUCCESS unhidden from combat log. Notify Zidras on Discord or GitHub") -- It does not fire on this server script. Replaced with CHAT_MSG_RAID_BOSS_EMOTE
		--self:BossTargetScanner(36678, "MalleableGooTarget", 0.05, 6)
		specWarnMalleableGooCast:Show()
		--specWarnMalleableGooCast:Play("watchstep")
		timerMalleableGooCD:Start()
		soundSpecWarnMalleableGoo:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable.mp3")
		soundMalleableGooSoon:Cancel()
		soundMalleableGooSoon:Schedule(20-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable_soon.mp3")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if args:IsSpellID(70447, 72836, 72837, 72838) then--Green Slime
		if args:IsPlayer() then--Still worth warning 100s because it does still do knockback
			specWarnVolatileOozeAdhesive:Show()
		elseif not self:IsTank() then
			specWarnVolatileOozeAdhesiveT:Show(args.destName)
			specWarnVolatileOozeAdhesiveT:Play("helpsoak")
		else
			warnVolatileOozeAdhesive:Show(args.destName)
		end
		if self.Options.OozeAdhesiveIcon then
			self:SetIcon(args.destName, 1)
		end
	elseif args:IsSpellID(70672, 72455, 72832, 72833) then	--Red Slime
		timerGaseousBloat:Start(args.destName)
		if args:IsPlayer() then
			specWarnGaseousBloat:Show()
			specWarnGaseousBloat:Play("justrun")
			specWarnGaseousBloat:ScheduleVoice(1.5, "keepmove")
		else
			warnGaseousBloat:Show(args.destName)
		end
		if self.Options.GaseousBloatIcon then
			self:SetIcon(args.destName, 2)
		end
	--elseif args:IsSpellID(71615, 71618) then	--71615 used in 10 and 25 normal, 71618?
	--	timerTearGas:Start()
	elseif args:IsSpellID(72451, 72463, 72671, 72672) then	-- Mutated Plague
		warnMutatedPlague:Show(args.destName, args.amount or 1)
		timerMutatedPlagueCD:Start()
	elseif spellId == 70542 then
		timerMutatedSlash:Show(args.destName)
	elseif args:IsSpellID(70539, 72457, 72875, 72876) then
		timerRegurgitatedOoze:Show(args.destName)
	elseif args:IsSpellID(70352, 74118) then	--Ooze Variable
		if args:IsPlayer() then
			specWarnOozeVariable:Show()
		end
	elseif args:IsSpellID(70353, 74119) then	-- Gas Variable
		if args:IsPlayer() then
			specWarnGasVariable:Show()
		end
	elseif args:IsSpellID(72855, 72856, 70911) then	 -- Unbound Plague
		if self.Options.UnboundPlagueIcon then
			self:SetIcon(args.destName, 3)
		end
		if args:IsPlayer() then
			specWarnUnboundPlague:Show()
			specWarnUnboundPlague:Play("targetyou")
			timerUnboundPlague:Start()
			yellUnboundPlague:Yell()
		else
			warnUnboundPlague:Show(args.destName)
		end
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(72451, 72463, 72671, 72672) then	-- Mutated Plague
		warnMutatedPlague:Show(args.destName, args.amount or 1)
		timerMutatedPlagueCD:Start()
	elseif args.spellId == 70542 then
		timerMutatedSlash:Show(args.destName)
	end
end

function mod:SPELL_AURA_REFRESH(args)
	if args:IsSpellID(70539, 72457, 72875, 72876) then
		timerRegurgitatedOoze:Show(args.destName)
	elseif args.spellId == 70542 then
		timerMutatedSlash:Show(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if args:IsSpellID(70447, 72836, 72837, 72838) then
		if self.Options.OozeAdhesiveIcon then
			self:SetIcon(args.destName, 0)
		end
	elseif args:IsSpellID(70672, 72455, 72832, 72833) then
		timerGaseousBloat:Cancel(args.destName)
		if self.Options.GaseousBloatIcon then
			self:SetIcon(args.destName, 0)
		end
	elseif args:IsSpellID(72855, 72856, 70911) then						-- Unbound Plague
		timerUnboundPlague:Stop(args.destName)
		if self.Options.UnboundPlagueIcon then
			self:SetIcon(args.destName, 0)
		end
	elseif spellId == 71615 and (self.vb.phase == 1.5 or self.vb.phase == 2.5) then	-- Tear Gas Removal. Requires phase check because sometimes Tear Gas is removed from Abomination much later than the rest of the raid, during phase 2, causing another phasing to 2.5 (Logs: 10N Frostmourne [2023-01-07]@[17:20:22] and [2023-01-07]@[17:42:33] || 10N Icecrown [2023-04-05]@[22:54:25])
		DBM:Debug("Re-engaged")
		--	NextPhase(self)
	elseif args:IsSpellID(70539, 72457, 72875, 72876) then
		timerRegurgitatedOoze:Cancel(args.destName)
	elseif spellId == 70542 then
		timerMutatedSlash:Cancel(args.destName)
	elseif (args:IsSpellID(70352, 74118) or args:IsSpellID(70353, 74119)) and (self.vb.phase == 1.5 or self.vb.phase == 2.5) then	-- Ooze Variable / Gas Variable (Heroic 25 - Phase 2 and 3). Disabled for two main reasons: raid member dying will trigger this event, and I have found multiple logs with early SAR
		DBM:Debug("Variable phasing time marker")
--		NextPhase(self)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.HeroicIntermission or msg:find(L.HeroicIntermission) then -- ACTION_CHANGE_PHASE. Workaround to script not firing Volatile Experiment.
		self:SetStage(self.vb.phase + 0.5)
		warnUnstableExperimentSoon:Cancel()
		timerSlimePuddleCD:AddTime(timerDelay)
		timerUnboundPlagueCD:AddTime(timerDelay)
		if self.vb.phase == 1.5 then -- _phase == 2
			timerUnstableExperimentCD:AddTime(timerDelay)
			warnUnstableExperimentSoon:Schedule(timerUnstableExperimentCD:GetRemaining()-3)
			timerMalleableGooCD:Start(50) -- 3s variance [25-28] + heroicDelay (25 on Heroic) = [50-53]
			soundMalleableGooSoon:Schedule(50-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable_soon.mp3")
			timerChokingGasBombCD:Start(60) -- 5s variance [35-40] + heroicDelay (25 on Heroic) = [60-65]
			soundChokingGasSoon:Schedule(60-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\choking_soon.mp3")
			warnChokingGasBombSoon:Schedule(60-5)
		elseif self.vb.phase == 2.5 then -- _phase == 3
			timerUnstableExperimentCD:Cancel()
			timerMalleableGooCD:AddTime(timerDelay)
			soundMalleableGooSoon:Cancel()
			soundMalleableGooSoon:Schedule(timerMalleableGooCD:GetRemaining()-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable_soon.mp3")
			timerChokingGasBombCD:AddTime(timerDelay)
			local chokingRemaining = timerChokingGasBombCD:GetRemaining()
			soundChokingGasSoon:Cancel()
			soundChokingGasSoon:Schedule(chokingRemaining-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\choking_soon.mp3")
			warnChokingGasBombSoon:Cancel()
			warnChokingGasBombSoon:Schedule(chokingRemaining-5)
		end
	-- EVENT_RESUME_ATTACK
	elseif msg == L.YellTransform1 or msg:find(L.YellTransform1) then
		warnReengage:Schedule(5.5, L.name)
		timerReengage:Start(5.5)
	elseif msg == L.YellTransform2 or msg:find(L.YellTransform2) then
		warnReengage:Schedule(8.5, L.name)
		timerReengage:Start(8.5)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg:find(L.MalleableGooCastEmote) then -- Malleable Goo. Workaround to missing CLEU event
		specWarnMalleableGooCast:Show()
		timerMalleableGooCD:Start() -- Belongs to EVENT_GROUP_ABILITIES
		soundSpecWarnMalleableGoo:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable.mp3")
		soundMalleableGooSoon:Cancel()
		soundMalleableGooSoon:Schedule(20-3, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\malleable_soon.mp3")
	end
end

--values subject to tuning depending on dps and his health pool
function mod:UNIT_HEALTH(uId)
	if self.vb.phase == 1 and not self.vb.warned_preP2 and self:GetUnitCreatureId(uId) == 36678 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.83 then
		self.vb.warned_preP2 = true
		warnPhase2Soon:Show()
		warnPhase2Soon:Play("nextphasesoon")
	elseif self.vb.phase == 2 and not self.vb.warned_preP3 and self:GetUnitCreatureId(uId) == 36678 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.38 then
		self.vb.warned_preP3 = true
		warnPhase3Soon:Show()
		warnPhase3Soon:Play("nextphasesoon")
	elseif self:GetUnitCreatureId(uId) == 36678 and UnitHealth(uId) / UnitHealthMax(uId) == 0.35 then
		warnUnstableExperimentSoon:Cancel()
		warnChokingGasBombSoon:Cancel()
		soundMalleableGooSoon:Cancel()
		soundChokingGasSoon:Cancel()
	end
end

-- On 10 Heroic, there is no event we can use to accurately trigger phasing. On 25 Heroic, we could use SPELL_AURA_REMOVED, but not reliable without UnitBuff checks or table management which would add unnecessary overhead (see above)
-- UNIT_TARGET only fires if boss is targeted or focused (sync'ed below)
function mod:UNIT_TARGET(uId)
	if self:GetUnitCreatureId(uId) ~= 36678 then return end
	-- Attempt to catch when boss phases by checking for Putricide's target being a raid member
	if UnitExists(uId.."target") then
		if self.vb.phase == --[[1.5]]2 then -- new script phases before boss reengage
			self:SendSync("ProfessorPhase2") -- Sync phasing with raid since UNIT_TARGET event requires boss to be target/focus, which not all members do
		elseif self.vb.phase == --[[2.5]]3 then -- new script phases before boss reengage
			self:SendSync("ProfessorPhase3") -- Sync phasing with raid since UNIT_TARGET event requires boss to be target/focus, which not all members do
		else
			self:UnregisterShortTermEvents()
			DBM:Debug("UNIT_TARGET phasing did not work since phase was wrongly set: " .. self.vb.phase)
		end
	end
end

--[[function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if spellName == GetSpellInfo(72851) or spellName == GetSpellInfo(73121) then -- Create Concoction (phase 2) or Guzzle Potion (phase 3). Cast Succeeded triggers new phase
		NextPhase(self)
	end
end]]

function mod:OnSync(msg)
	if not self:IsInCombat() then return end
	if msg == "ProfessorPhase2" and self.vb.phase == --[[1.5]]2 then
		--self:Unschedule(NextPhase)
		--NextPhase(self)
		self:UnregisterShortTermEvents()
		DBM:Debug("Putricide (phase 2) re-engaged via UNIT_TARGET sync")
	elseif msg == "ProfessorPhase3" and self.vb.phase == --[[2.5]]3 then
		--self:Unschedule(NextPhase)
		--NextPhase(self)
		self:UnregisterShortTermEvents()
		DBM:Debug("Putricide (phase 3) re-engaged via UNIT_TARGET sync")
	end
end
