local mod	= DBM:NewMod("LichKing", "DBM-Icecrown", 5)
local L		= mod:GetLocalizedStrings()

local UnitGUID, UnitName, GetSpellInfo = UnitGUID, UnitName, GetSpellInfo
local UnitInRange, UnitIsUnit, UnitInVehicle, IsInRaid = UnitInRange, UnitIsUnit, UnitInVehicle, DBM.IsInRaid
local sformat = string.format

mod:SetRevision("20250812223135")
mod:SetCreatureID(36597)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6, 7)
mod:SetHotfixNoticeRev(20250723000000)
mod:SetMinSyncRevision(20220921000000)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 68981 74270 74271 74272 72259 74273 74274 74275 72143 72146 72147 72148 72262 70358 70498 70541 73779 73780 73781 72762 73539 73650 72350 69242 73800 73801 73802",
	"SPELL_CAST_SUCCESS 70337 73912 73913 73914 69409 73797 73798 73799 69200 68980 74325 74326 74327 73654 74295 74296 74297 69037 74361",
	"SPELL_DISPEL",
	"SPELL_AURA_APPLIED 28747 72754 73708 73709 73710", -- 73650 commented out, no longer needed
	"SPELL_AURA_APPLIED_DOSE 70338 73785 73786 73787",
--	"SPELL_AURA_REMOVED 73655", -- 68980 74325 is 10N and 25N, not needed for FM
	"SPELL_SUMMON 69037 70372",
	"SPELL_DAMAGE 68983 73791 73792 73793",
	"SPELL_MISSED 68983 73791 73792 73793",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_HEALTH target focus",
	"UNIT_AURA_UNFILTERED",
	"UNIT_DIED"
)

-- switching to faster less cpu wasting UNIT_TARGET scanning method is not reliable, since this event only fires for LK if is target/focus. Such approach would require syncs to minimize risk of not catching the mechanic, with the downside of the performance gain being questionable
--Shadow Trap UNIT_TARGET looks reliable
-- "<29.57 21:04:20> [UNIT_SPELLCAST_START] The Lich King(player1) - Summon Shadow Trap - 0.5s [[boss1:Summon Shadow Trap::0:]]", -- [2616]
-- "<29.57 21:04:20> [DBM_Debug] Boss target scan started for 36597:2:", -- [2617]
-- "<29.57 21:04:20> [DBM_TimerStart] Timer73539next:Next Summon Shadow Trap:15.5:Interface\\Icons\\Spell_Shadow_GatherShadows:next:73539:3:LichKing:nil:nil:Summon Shadow Trap:nil:", -- [2618]
-- "<29.58 21:04:20> [CLEU] SPELL_CAST_START:0xF130008EF5000861:The Lich King:0x0000000000000000:nil:73539:Summon Shadow Trap:nil:nil:", -- [2619]
-- "<29.58 21:04:20> [UNIT_TARGET] boss1#The Lich King#Target: player2#TargetOfTarget: The Lich King", -- [2621]
-- "<29.60 21:04:20> [DBM_Debug] BossTargetScanner has ended for 36597:2:", -- [2622]

--Defile UNIT_TARGET is NOT reliable (one log only fired 2 UNIT_TARGET out of 7 defiles)
--no UNIT_TARGET for defile
-- "<247.54 21:12:30> [UNIT_SPELLCAST_START] The Lich King(player1) - Defile - 2s [[boss1:Defile::0:]]", -- [20743]
-- "<247.54 21:12:30> [DBM_Debug] Boss target scan started for 36597:2:", -- [20744]
-- "<247.54 21:12:30> [DBM_TimerStart] Timer72762next:Next Defile:32.5:Interface\\Icons\\Ability_Rogue_EnvelopingShadows:next:72762:3:LichKing:nil:nil:Defile:nil:", -- [20745]
-- "<247.54 21:12:30> [CLEU] SPELL_CAST_START:0xF130008EF5000861:The Lich King:0x0000000000000000:nil:72762:Defile:nil:nil:", -- [20746]
-- "<247.57 21:12:30> [DBM_Announce] Defile on >player3<:Interface\\Icons\\Ability_Rogue_EnvelopingShadows:target:72762:LichKing:false:", -- [20747]
-- "<247.57 21:12:30> [DBM_Debug] BossTargetScanner has ended for 36597:2:", -- [20748]

--with UNIT_TARGET for defile
-- "<529.67 21:17:12> [UNIT_SPELLCAST_START] The Lich King(player1) - Defile - 2s [[boss1:Defile::0:]]", -- [42820]
-- "<529.67 21:17:12> [DBM_Debug] Boss target scan started for 36597:2:", -- [42821]
-- "<529.67 21:17:12> [DBM_TimerStart] Timer72762next:Next Defile:32.5:Interface\\Icons\\Ability_Rogue_EnvelopingShadows:next:72762:3:LichKing:nil:nil:Defile:nil:", -- [42822]
-- "<529.67 21:17:12> [CLEU] SPELL_CAST_START:0xF130008EF5000861:The Lich King:0x0000000000000000:nil:72762:Defile:nil:nil:", -- [42823]
-- "<529.67 21:17:12> [UNIT_TARGET] boss1#The Lich King#Target: player4#TargetOfTarget: The Lich King", -- [42825]
-- "<529.70 21:17:12> [DBM_Announce] Defile on >player4<:Interface\\Icons\\Ability_Rogue_EnvelopingShadows:target:72762:LichKing:false:", -- [42826]
-- "<529.70 21:17:12> [DBM_Debug] BossTargetScanner has ended for 36597:2:", -- [42827]

-- General
local timerCombatStart		= mod:NewCombatTimer(55)
local berserkTimer			= mod:NewBerserkTimer(900)

mod:AddBoolOption("RemoveImmunes")
mod:AddMiscLine(L.FrameGUIDesc)
mod:AddBoolOption("ShowFrame", true)
mod:AddBoolOption("FrameLocked", false)
mod:AddBoolOption("FrameClassColor", true, nil, function()
	mod:UpdateColors()
end)
mod:AddBoolOption("FrameUpwards", false, nil, function()
	mod:ChangeFrameOrientation()
end)
mod:AddButton(L.FrameGUIMoveMe, function() mod:CreateFrame() end, nil, 130, 20)

-- Stage One
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1))
local warnShamblingSoon				= mod:NewSoonAnnounce(70372, 2) --Phase 1 Add
local warnShamblingHorror			= mod:NewSpellAnnounce(70372, 3) --Phase 1 Add
local warnDrudgeGhouls				= mod:NewSpellAnnounce(70358, 2) --Phase 1 Add
local warnShamblingEnrage			= mod:NewTargetNoFilterAnnounce(72143, 3, nil, "Tank|Healer|RemoveEnrage") --Phase 1 Add Ability
local warnNecroticPlague			= mod:NewTargetNoFilterAnnounce(70337, 3) --Phase 1+ Ability
local warnNecroticPlagueJump		= mod:NewAnnounce("WarnNecroticPlagueJump", 4, 70337, nil, nil, nil, 70337) --Phase 1+ Ability
local warnInfest					= mod:NewCountAnnounce(70541, 3, nil, "Healer|RaidCooldown") --Phase 1 & 2 Ability
local warnTrapCast					= mod:NewTargetDistanceAnnounce(73539, 4, nil, nil, nil, nil, nil, nil, true) --Phase 1 Heroic Ability

local specWarnNecroticPlague		= mod:NewSpecialWarningMoveAway(70337, nil, nil, nil, 1, 2) --Phase 1+ Ability
local specWarnInfest				= mod:NewSpecialWarningCount(70541, nil, nil, nil, 1) --Phase 1+ Ability
local specWarnTrap					= mod:NewSpecialWarningYou(73539, nil, nil, nil, 3, 2, 3) --Heroic Ability
local yellTrap						= mod:NewYellMe(73539)
local specWarnTrapNear				= mod:NewSpecialWarningClose(73539, nil, nil, nil, 3, 2, 3) --Heroic Ability
local specWarnEnrage				= mod:NewSpecialWarningSpell(72143, "Tank")
local specWarnEnrageLow				= mod:NewSpecialWarningSpell(28747, false)

local timerInfestCD					= mod:NewVarCountTimer("v21-24.1", 70541, nil, "Healer|RaidCooldown", nil, 5, nil, DBM_COMMON_L.HEALER_ICON, true) -- ~3s variance [21.05-24.10]. SPELL_CAST_START: (Aura 3.3.5: 25H [2025-07-23]@[11:02:02] || 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Infestar-73781-npc:36597-7800691 = pull:7.33, 23.60, 21.62, 21.74, 21.87, 87.27, 21.59, 23.52, 21.36, 21.68, 23.18, 23.63, 23.98" || 	"Infestar-73781-npc:36597-10363499 = pull:5.08/[Stage 1/0.00] 5.08, 23.29, 21.29, 24.10, 22.62, 21.15, Stage 1.5/21.70, Stage 2/62.53, 7.45/69.98/91.67, 22.39, 22.88, 22.86, 21.70, 22.31, 21.39, 22.54, Stage 2.5/14.94, Stage 3/62.46, Left Frostmourne/59.50, Left Frostmourne/104.39" || "Infestar-73781-npc:36597-10363499 = pull:4.92/[Stage 1/0.00] 4.92, 22.15, 22.99, 23.70, 23.18, 21.05, Stage 1.5/10.28, Stage 2/62.43, 7.48/69.91/80.19, 23.27, 23.67, 22.79, 21.61, 22.95, 23.77, 22.47, 22.43, 23.97, Stage 2.5/10.32, Stage 3/62.41, Left Frostmourne/59.75, Left Frostmourne/109.96, Left Frostmourne/101.56, Left Frostmourne/108.75, Left Frostmourne/108.73"
local timerNecroticPlagueCleanse	= mod:NewTimer(5, "TimerNecroticPlagueCleanse", 70337, "Healer", nil, 5, DBM_COMMON_L.HEALER_ICON, nil, nil, nil, nil, nil, nil, 70337)
local timerNecroticPlagueCD			= mod:NewVarTimer("v30-32.67", 70337, nil, nil, nil, 3, nil, DBM_COMMON_L.DISEASE_ICON, true) -- ~3s variance [29.96-32.67]. SPELL_CAST_SUCCESS: (Aura 3.3.5: 25H [2025-07-23]@[11:02:02] || 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Peste necrótica-73914-npc:36597-7800691 = pull:10.36, 31.95, 31.39, 32.67" || "Peste necrótica-73914-npc:36597-10363499 = pull:31.66/[Stage 1/0.00] 31.66, 60.98, 30.80 || "Peste necrótica-73914-npc:36597-10363499 = pull:29.96/[Stage 1/0.00] 29.96, 30.17, 31.07, 31.06
local timerEnrageCD					= mod:NewCDCountTimer("dv20-25", 72143, nil, "Tank|RemoveEnrage", nil, 5, nil, DBM_COMMON_L.ENRAGE_ICON) -- String timer starting with "d" means "allowDouble". 5s variance [20.14-24.79]. Cast can be stun-skipped. SPELL_CAST_START: (Aura 3.3.5: 25H [2025-07-23]@[11:02:02] || 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Enfurecer-72148-npc:37698-7807834 = pull:12.78, 20.99, 23.83" || "Enfurecer-72148-npc:37698-10368537 = pull:34.44/[Stage 1/0.00] 34.44, 21.64, 22.96, 23.92, 20.14 ; "Enfurecer-72148-npc:37698-10371026 = pull:94.66/[Stage 1/0.00] 94.66, 24.69 || "Enfurecer-72148-npc:37698-10392671 = pull:33.19/[Stage 1/0.00] 33.19, 21.62, 24.09, 20.26, 24.01 ; "Enfurecer-72148-npc:37698-10393695 = pull:93.91/[Stage 1/0.00] 93.91, 24.79
local timerShamblingHorror			= mod:NewNextTimer(60, 70372, nil, nil, nil, 1) -- Initial timer: 20s, then fixed timer: 60s. SPELL_CAST_START: (Aura 3.3.5: 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Invocar horror desgarbado-70372-npc:36597-10363499 = pull:20.03/[Stage 1/0.00] 20.03, 60.10 || "Invocar horror desgarbado-70372-npc:36597-10363499 = pull:19.94/[Stage 1/0.00] 19.94, 59.99"
local timerDrudgeGhouls				= mod:NewNextTimer(30, 70358, nil, nil, nil, 1) -- Initial timer: 10s, then fixed timer: 30s. SPELL_CAST_START: (Aura 3.3.5: 25H [2025-07-24]@[10:58:24]) - "Invocar braceros necrófagos-70358-npc:36597-10363499 = pull:10.08/[Stage 1/0.00] 10.08, 30.02, 30.06, 30.10, 30.04
local timerTrapCD					= mod:NewNextTimer(15.5, 73539, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, nil, 1, 4) -- Fixed timer: 15.5s. SPELL_CAST_START: (Aura 3.3.5: 25H [2025-07-23]@[11:02:02] || 25H [2025-07-24]@[10:58:24]) - "Invocar trampa de las Sombras-73539-npc:36597-7800691 = pull:9.47, 15.57, 15.50, 15.56, 15.52, 15.51, 15.54 || "Invocar trampa de las Sombras-73539-npc:36597-10363499 = pull:15.50/[Stage 1/0.00] 15.50, 15.53, 15.60, 15.66, 15.50, 15.53, 15.56, 15.49"

local soundInfestSoon				= mod:NewSoundSoon(70541, nil, "Healer|RaidCooldown")
local soundNecroticOnYou			= mod:NewSoundYou(70337)

mod:AddSetIconOption("NecroticPlagueIcon", 70337, true, 0, {1})
mod:AddSetIconOption("TrapIcon", 73539, true, 0, {7})
mod:AddArrowOption("TrapArrow", 73539, true)
mod:AddBoolOption("AnnouncePlagueStack", false, nil, nil, nil, nil, 70337)

-- Stage Two
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2))
local warnPhase2					= mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local valkyrGrabWarning				= mod:NewAnnounce("ValkyrWarning", 3, 71844, nil, nil, nil, 69037)--Phase 2 Ability
local warnDefileSoon				= mod:NewSoonCountAnnounce(72762, 3)	--Phase 2+ Ability
local warnSoulreaper				= mod:NewTargetCountAnnounce(69409, 4) --Phase 2+ Ability
local warnDefileCast				= mod:NewTargetCountDistanceAnnounce(72762, 4, nil, nil, nil, nil, nil, nil, true) --Phase 2+ Ability
local warnSummonValkyr				= mod:NewCountAnnounce(69037, 3, 71844) --Phase 2 Add

local specWarnYouAreValkd			= mod:NewSpecialWarning("SpecWarnYouAreValkd", nil, nil, nil, 1, 2, nil, 71844, 69037) --Phase 2+ Ability
local specWarnDefileCast			= mod:NewSpecialWarningMoveAway(72762, nil, nil, nil, 3, 2) --Phase 2+ Ability
local yellDefile					= mod:NewYellMe(72762)
local specWarnDefileNear			= mod:NewSpecialWarningClose(72762, nil, nil, nil, 1, 2) --Phase 2+ Ability
local specWarnSoulreaper			= mod:NewSpecialWarningDefensive(69409, nil, nil, nil, 1, 2) --Phase 2+ Ability
local specwarnSoulreaper			= mod:NewSpecialWarningTarget(69409, true) --phase 2+
local specWarnSoulreaperOtr			= mod:NewSpecialWarningTaunt(69409, false, nil, nil, 1, 2) --phase 2+; disabled by default, not standard tactic
local specWarnValkyrLow				= mod:NewSpecialWarning("SpecWarnValkyrLow", nil, nil, nil, 1, 2, nil, 71844, 69037)

local timerSoulreaper				= mod:NewTargetTimer(5.1, 69409, nil, "Tank|Healer|TargetedCooldown")
local timerSoulreaperCD				= mod:NewVarCountTimer("v34.16-35.85", 69409, nil, "Tank|Healer|TargetedCooldown", nil, 5, nil, DBM_COMMON_L.TANK_ICON, true) -- ~2s variance [34.16-35.85]. Added "keep" arg since one log skipped one of the casts (Aura 3.3.5: 25H [2025-07-23]@[11:02:02] || 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Segador de almas-73799-npc:36597-7800691 = pull:207.53, 34.16, 35.85, 34.88, 290.78, 34.39" || "Segador de almas-73799-npc:36597-10363499 = pull:233.74/[Stage 1/0.00, Stage 1.5/139.24, Stage 2/62.53] 31.98/94.50/233.74, 33.53, 34.80, 34.50, 34.65, Stage 2.5/9.02, Stage 3/62.46, Left Frostmourne/59.50, 43.04/102.53/164.99/174.02, Left Frostmourne/61.35, 8.72/70.07, 33.13" || "Segador de almas-73799-npc:36597-10363499 = pull:223.53/[Stage 1/0.00, Stage 1.5/128.28, Stage 2/62.43] 32.82/95.25/223.53, 34.03, 67.85, 35.34, 35.02, Stage 2.5/19.68, Stage 3/62.41, Left Frostmourne/59.75, 43.06/102.81/165.23/184.91, Left Frostmourne/66.90, 8.66/75.56, 33.07, Left Frostmourne/59.83, Left Frostmourne/108.75, 11.48/120.24/180.07, 33.96, Left Frostmourne/63.29"
local timerDefileCD					= mod:NewVarCountTimer("v32.35-35.7", 72762, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON, true, 1, 4) -- ~3s variance [32.35-35.7]. Added "keep" arg, but might need sync for Normal Harvest Soul since CLEU could be OOR - need Normal log from a harvested soul. Don't use SPELL_CAST_START, use EMOTE instead! SCS is logged for first 3 logs, EMOTE is shown on 3rd for comparison: (Aura 3.3.5: 25H [2025-07-23]@[11:02:02] || 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Profanar-72762-npc:36597-7800691 = pull:210.50, 64.94, 33.32, 35.70, 141.67, 34.20, 74.53, 34.79, 69.54, 32.35" || "Profanar-72762-npc:36597-10363499 = pull:236.18/[Stage 1/0.00, Stage 1.5/139.24, Stage 2/62.53] 34.42/96.95/236.18, 33.01, 33.99, 34.81, 33.81, Stage 2.5/8.44, Stage 3/62.46, Left Frostmourne/59.50, 34.16/93.66/156.12/164.56, Left Frostmourne/70.23, 36.98/107.20" || "Profanar-72762-npc:36597-10363499 = pull:225.27/[Stage 1/0.00, Stage 1.5/128.28, Stage 2/62.43] 34.55/96.98/225.27, 32.52, 33.89, 34.05, 35.01, 32.89, Stage 2.5/21.80, Stage 3/62.41, Left Frostmourne/59.75, 1.33/61.08/123.50/145.30, 32.51, Left Frostmourne/76.12, 1.41/77.53, 34.82, Left Frostmourne/65.34, 33.64/98.98, Left Frostmourne/75.11, 1.49/76.60, 33.95, Left Frostmourne/73.30, 1.51/74.81" ; "?-¡%s comienza a lanzar Profanar!-npc:El Rey Exánime = pull:225.27/[Stage 1/0.00, Stage 1.5/128.28, Stage 2/62.43] 34.55/96.98/225.27, 32.52, 33.89, 34.05, 35.01, 32.89, Stage 2.5/21.81, Stage 3/62.41, Left Frostmourne/59.75, 1.33/61.08/123.50/145.30, 32.51, Left Frostmourne/76.13, 1.40/77.53, 34.82, Left Frostmourne/65.34, 1.39/66.73, 32.25, Left Frostmourne/75.11, 1.48/76.59, 33.95, Left Frostmourne/73.30, 1.51/74.81"
local timerSummonValkyr				= mod:NewVarCountTimer("v45-50", 69037, nil, nil, nil, 1, 71844, DBM_COMMON_L.DAMAGE_ICON, true, 2, 3) -- 5s variance [45-50]. Added "keep" arg. (Aura 3.3.5: 25H [2025-07-23]@[11:02:02]) - "Invocar Val'kyr-69037-npc:36597-7800691 = pull:191.48, 49.69, 47.92, 46.65"

local soundDefileOnYou				= mod:NewSoundYou(72762)
local soundSoulReaperSoon			= mod:NewSoundSoon(69409, nil, "Tank|Healer|TargetedCooldown")

mod:AddSetIconOption("DefileIcon", 72762, true, 0, {7})
mod:AddSetIconOption("ValkyrIcon", 69037, true, 5, {2, 3, 4}) -- Despite icon convention, keep 2,3,4 for grabIcon backwards compatibility, since iconSetter may be an old DBM/BW user, and detect target marker on a loop would be too CPU heavy for just this
mod:AddArrowOption("DefileArrow", 72762, true)
mod:AddBoolOption("AnnounceValkGrabs", false, nil, nil, nil, nil, 69037)

-- Stage Three
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(3))
local warnPhase3					= mod:NewPhaseAnnounce(3, 2, nil, nil, nil, nil, nil, 2)
local warnSummonVileSpirit			= mod:NewSpellAnnounce(70498, 2) --Phase 3 Add
local warnHarvestSoul				= mod:NewTargetNoFilterAnnounce(68980, 3) --Phase 3 Ability
local warnRestoreSoul				= mod:NewCastAnnounce(73650, 2) --Phase 3 Heroic

local specWarnHarvestSoul			= mod:NewSpecialWarningYou(68980, nil, nil, nil, 1, 2) --Phase 3+ Ability
local specWarnHarvestSouls			= mod:NewSpecialWarningSpell(73654, nil, nil, nil, 1, 2, 3) --Heroic Ability

local timerHarvestSoul				= mod:NewTargetTimer(6, 68980)
local timerHarvestSoulCD			= mod:NewNextTimer(75, 68980, nil, nil, nil, 6)
local timerVileSpirit				= mod:NewNextTimer(30.5, 70498, nil, nil, nil, 1)
local timerRestoreSoul				= mod:NewCastTimer(40, 73650, nil, nil, nil, 6)
local timerRoleplay					= mod:NewTimer(162, "TimerRoleplay", 72350, nil, nil, 6)

mod:AddSetIconOption("HarvestSoulIcon", 68980, false, 0, {5})

-- Intermission
mod:AddTimerLine(DBM_COMMON_L.INTERMISSION)
local warnRemorselessWinter			= mod:NewSpellAnnounce(68981, 3) --Phase Transition Start Ability
local warnQuake						= mod:NewSpellAnnounce(72262, 4) --Phase Transition End Ability
local warnRagingSpirit				= mod:NewTargetNoFilterAnnounce(69200, 3) --Transition Add
local warnIceSpheresTarget			= mod:NewTargetAnnounce(69103, 3, 69712, nil, 69090) -- icon: spell_frost_frozencore; shortText "Ice Sphere"
local warnPhase2Soon				= mod:NewPrePhaseAnnounce(2)
local warnPhase3Soon				= mod:NewPrePhaseAnnounce(3)

local specWarnRagingSpirit			= mod:NewSpecialWarningYou(69200, nil, nil, nil, 1, 2) --Transition Add
local specWarnIceSpheresYou			= mod:NewSpecialWarningMoveAway(69103, nil, 69090, nil, 1, 2) -- shortText "Ice Sphere"
local specWarnGTFO					= mod:NewSpecialWarningGTFO(68983, nil, nil, nil, 1, 8)

local timerPhaseTransition			= mod:NewTimer(62.5, "PhaseTransition", 72262, nil, nil, 6) -- Fixed timer: 62.5s
local timerRagingSpiritCD			= mod:NewVarCountTimer("v22.13-23.11", 69200, nil, nil, nil, 1) -- 1s variance [22.13-23.11] SPELL_CAST_SUCCESS: (Aura 3.3.5: 25H [2025-07-23]@[11:02:02] || 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Espíritu enfurecido-69200-npc:36597-7800691 = pull:116.50, 23.05, 22.98, 204.92, 23.07, 22.13" || "Espíritu enfurecido-69200-npc:36597-10363499 = pull:142.17/[Stage 1/0.00, Stage 1.5/139.24] 2.94/142.17, 22.58, 22.48, Stage 2/14.53, Stage 2.5/178.47, 4.95/183.42/197.96, 22.24, 23.11, Stage 3/12.16 || "Espíritu enfurecido-69200-npc:36597-10363499 = pull:131.23/[Stage 1/0.00, Stage 1.5/128.28] 2.94/131.23, 22.92, 22.47, Stage 2/14.10, Stage 2.5/224.72, 4.95/229.68/243.77, 22.68, 22.63, Stage 3/12.16
local timerSoulShriekCD				= mod:NewCDTimer(14.81, 69242, nil, nil, nil, 1) -- (Aura 3.3.5: 25H [2025-07-24]@[11:14:31]) - "Chillido de alma-73802-npc:36701-10402308 = pull:433.21/[Stage 1/0.00, Stage 1.5/128.28, Stage 2/62.43, Stage 2.5/224.72] 17.77/242.50/304.93/433.21, 14.81"

mod:AddRangeFrameOption(8, 72133)
mod:AddSetIconOption("RagingSpiritIcon", 69200, false, 0, {6})

-- P1 variables
mod.vb.warned_preP2 = false
mod.vb.infestCount = 0
-- Intermission variables
mod.vb.ragingSpiritCount = 0
-- P2 variables
mod.vb.warned_preP3 = false
mod.vb.defileCount = 0
mod.vb.soulReaperCount = 0
mod.vb.valkyrWaveCount = 0
mod.vb.valkIcon = 2
local shamblingHorrorsGUIDs = {}
local iceSpheresGUIDs = {}
local ragingSpiritsGUIDs = {}
local warnedValkyrGUIDs = {}
local valkyrTargets = {}
local plagueHop = DBM:GetSpellInfo(70338)--Hop spellID only, not cast one.
-- local soulshriek = GetSpellInfo(69242)
local plagueExpires = {}
local grabIcon = 2
--	local lastValk = 0
--	local maxValks = mod:IsDifficulty("normal25", "heroic25") and 3 or 1
local warnedAchievement = false
local lastPlague

--[[
local function numberOfValkyrTargets(tbl)
	if not tbl then return 0 end
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

local function scanValkyrTargets(self)
	if numberOfValkyrTargets(valkyrTargets) < maxValks and (time() - lastValk) < 10 then	-- scan for like 10secs, but exit earlier if all the valks have spawned and grabbed their players
		for uId in DBM:GetGroupMembers() do		-- for every raid member check ..
			DBM:Debug("Valkyr check for "..  UnitName(uId) ..": UnitInVehicle is returning " .. (UnitInVehicle(uId) or "nil") .. " and UnitInRange is returning " .. (UnitInRange(uId) or "nil") .. " with distance: " .. DBM.RangeCheck:GetDistance(uId) .."yd. Checking if it is already cached: " .. (valkyrTargets[uId] and "true" or "nil."), 3)
			if UnitInVehicle(uId) and not valkyrTargets[uId] then	  -- if person #i is in a vehicle and not already announced
				valkyrGrabWarning:Show(UnitName(uId))
				valkyrTargets[uId] = true
				local raidIndex = UnitInRaid(uId)
				local name, _, subgroup, _, _, fileName = GetRaidRosterInfo(raidIndex + 1)
				if name == UnitName(uId) then
					local grp = subgroup
					local class = fileName
					mod:AddEntry(name, grp or 0, class, grabIcon)
				end
				if UnitIsUnit(uId, "player") then
					specWarnYouAreValkd:Show()
					specWarnYouAreValkd:Play("targetyou")
				end
				if DBM:IsInGroup() and self.Options.AnnounceValkGrabs and DBM:GetRaidRank() > 1 then
					local channel = (IsInRaid() and "RAID") or "PARTY"
					if self.Options.ValkyrIcon then
						SendChatMessage(L.ValkGrabbedIcon:format(grabIcon, UnitName(uId)), channel)
					else
						SendChatMessage(L.ValkGrabbed:format(UnitName(uId)), channel)
					end
				end
				grabIcon = grabIcon + 1--Makes assumption discovery order of vehicle grabs will match combat log order, since there is a delay
			end
		end
		self:Schedule(0.5, scanValkyrTargets, self)  -- check for more targets in a few
	else
		table.wipe(valkyrTargets)	   -- no more valkyrs this round, so lets clear the table
		grabIcon = 2
		self.vb.valkIcon = 2
	end
end
--]]

local function RemoveImmunes(self)
	if self.Options.RemoveImmunes then -- cancelaura bop bubble iceblock Dintervention
		CancelUnitBuff("player", (GetSpellInfo(10278)))
		CancelUnitBuff("player", (GetSpellInfo(642)))
		CancelUnitBuff("player", (GetSpellInfo(45438)))
		CancelUnitBuff("player", (GetSpellInfo(19752)))
	end
end

local function NextPhase(self, delay)
	self.vb.infestCount = 0
	self.vb.defileCount = 0
	self.vb.valkyrWaveCount = 0
	self.vb.soulReaperCount = 0
	if self.vb.phase == 1 then
		berserkTimer:Start(-delay)
		warnShamblingSoon:Schedule(15-delay)
		timerShamblingHorror:Start(20-delay)
		timerDrudgeGhouls:Start(10-delay)
		if self:IsHeroic() then
			timerTrapCD:Start(-delay)
		end
		timerNecroticPlagueCD:Start(-delay) -- no difference between N and H.
		timerInfestCD:Start(sformat("v%s-%s", 4.92-delay, 5.08-delay), self.vb.infestCount+1) -- ~1s variance [4.92-5.08].
	elseif self.vb.phase == 2 then
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		if self.Options.ShowFrame then
			self:CreateFrame()
		end
		timerSummonValkyr:Start(15.5, self.vb.valkyrWaveCount+1) -- REVIEW! Fixed timer? (Aura 3.3.5: 25H [2025-07-23]@[11:02:02]) - 15.5
		timerSoulreaperCD:Start(31.6, self.vb.soulReaperCount+1) -- REVIEW! Fixed timer? (Aura 3.3.5: 25H [2025-07-23]@[11:02:02]) - 31.6
		soundSoulReaperSoon:Schedule(31.6-2.5, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\soulreaperSoon.mp3")
		timerDefileCD:Start("v34.42-34.57", self.vb.defileCount+1) -- ~0.2s variance (Aura 3.3.5: 25H [2025-07-23]@[11:02:02] || 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - 34.57 || 34.42 || 34.55
		timerInfestCD:Start(7.5, self.vb.infestCount+1) -- REVIEW! Fixed timer? (Aura 3.3.5: 25H [2025-07-23]@[11:02:02]) - 7.5
		soundInfestSoon:Schedule(7.5-2, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\infestSoon.mp3")
		warnDefileSoon:Schedule(34.57-5, self.vb.defileCount+1)
		warnDefileSoon:ScheduleVoice(34.57-5, "scatter") -- Voice Pack - Scatter.ogg: "Spread!"
		self:RegisterShortTermEvents(
			"UNIT_ENTERING_VEHICLE",
			"UNIT_EXITING_VEHICLE"
		)
	elseif self.vb.phase == 3 then
		warnPhase3:Show()
		warnPhase3:Play("pthree")
		timerVileSpirit:Start(17)
		timerSoulreaperCD:Start(37.5, self.vb.soulReaperCount+1)
		soundSoulReaperSoon:Schedule(37.5-2.5, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\soulreaperSoon.mp3")
		timerDefileCD:Start(nil, self.vb.defileCount+1) -- REVIEW! Need Normal log
		warnDefileSoon:Schedule(32-5, self.vb.defileCount+1)
		warnDefileSoon:ScheduleVoice(32-5, "scatter")
		timerHarvestSoulCD:Start(11.1) -- (Aura 3.3.5: 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Recolectar almas-74297-npc:36597-10363499 = 11.07 || 11.17

--		if self:IsHeroic() then
--			self:RegisterShortTermEvents(
--				"ZONE_CHANGED"
--			)
--		end
	end
end

local function leftFrostmourne(self)
	DBM:Debug("Left Frostmourne")
	DBM:AddSpecialEventToTranscriptorLog("Left Frostmourne")
	timerHarvestSoulCD:Start("v53-61.41") -- ~8s variance [53.00-61.41]. SPELL_CAST_SUCCESS: (Aura 3.3.5: 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Recolectar almas-74297-npc:36597-10363499 = pull:453.77/[Stage 1/0.00, Stage 1.5/139.24, Stage 2/62.53, Stage 2.5/178.47, Stage 3/62.46] 11.07/73.54/252.01/314.54/453.77, Left Frostmourne/48.42, 56.07/104.49, Left Frostmourne/48.32, 58.12/106.43" || "Recolectar almas-74297-npc:36597-10363499 = pull:489.02/[Stage 1/0.00, Stage 1.5/128.28, Stage 2/62.43, Stage 2.5/224.72, Stage 3/62.41] 11.17/73.58/298.30/360.74/489.02, Left Frostmourne/48.59, 61.41/109.99, Left Frostmourne/48.55, 53.00/101.55, Left Frostmourne/48.56, 60.29/108.86, Left Frostmourne/48.46, 60.26/108.72, Left Frostmourne/48.47"
	timerDefileCD:Start(1.3, self.vb.defileCount+1) -- As soon as the group leaves FM.
	warnDefileSoon:Show(self.vb.defileCount+1)
	warnDefileSoon:Play("scatter") -- Voice Pack - Scatter.ogg: "Spread!"
	timerSoulreaperCD:Start(3.5, self.vb.soulReaperCount+1) -- After Defile cast (+2s)
	soundSoulReaperSoon:Schedule(3.5-2.5, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\soulreaperSoon.mp3")
	timerVileSpirit:Start(18) -- REVIEW! Unknown script. SPELL_CAST_START: (Aura 3.3.5: 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - "Espíritus malvados-70498-npc:36597-10363499 = pull:549.74/[Stage 1/0.00, Stage 1.5/139.24, Stage 2/62.53, Stage 2.5/178.47, Stage 3/62.46, Left Frostmourne/59.50] 47.55/107.04/169.50/347.98/410.50/549.74, Left Frostmourne/56.84, 31.33/88.17" || "Espíritus malvados-70498-npc:36597-10363499 = pull:581.03/[Stage 1/0.00, Stage 1.5/128.28, Stage 2/62.43, Stage 2.5/224.72, Stage 3/62.41, Left Frostmourne/59.75] 43.42/103.17/165.59/390.31/452.74/581.03, Left Frostmourne/66.54, 18.85/85.39, Left Frostmourne/82.71, 41.65/124.36, Left Frostmourne/67.11, 18.00/85.11, 36.35, Left Frostmourne/54.39"
end

local function RestoreWipeTime(self)
	self:SetWipeTime(5) --Restore it after frostmourn room.
end

function mod:OnCombatStart(delay)
	self:DestroyFrame()
	self:SetStage(1)
	self.vb.valkIcon = 2
	self.vb.warned_preP2 = false
	self.vb.warned_preP3 = false
	self.vb.ragingSpiritCount = 0
	NextPhase(self, delay)
	table.wipe(shamblingHorrorsGUIDs)
	table.wipe(iceSpheresGUIDs)
	table.wipe(ragingSpiritsGUIDs)
	table.wipe(warnedValkyrGUIDs)
	table.wipe(plagueExpires)
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
	self:DestroyFrame()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:DefileTarget(targetname, uId)
	if not targetname and not uId then return end
	if self.Options.DefileIcon then
		self:SetIcon(targetname, 7, 4)
	end
	if targetname == UnitName("player") then
		specWarnDefileCast:Show()
		specWarnDefileCast:Play("runout")
		soundDefileOnYou:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\defileOnYou.mp3")
		yellDefile:Yell()
	elseif self:CheckNearby(11, targetname) then
		specWarnDefileNear:Show(targetname)
	end
	warnDefileCast:Show(self.vb.defileCount, targetname, DBM.RangeCheck:GetDistance(uId)) -- Always show announcement, regardless of distance
	if self.Options.DefileArrow then
		local x, y = GetPlayerMapPosition(uId)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(uId)
			end
		DBM.Arrow:ShowRunAway(x, y, 10, 5)
	end
end

function mod:TrapTarget(targetname, uId)
	if not targetname and not uId then return end
	if self.Options.TrapIcon then
		self:SetIcon(targetname, 7, 4)
	end
	if targetname == UnitName("player") then
		specWarnTrap:Show()
		specWarnTrap:Play("watchstep")
		yellTrap:Yell()
	elseif self:CheckNearby(15, targetname) then
		specWarnTrapNear:Show(targetname)
		specWarnTrapNear:Play("watchstep")
	end
	warnTrapCast:Show(targetname, DBM.RangeCheck:GetDistance(uId)) -- Always show announcement, regardless of distance
	if self.Options.TrapArrow then
		local x, y = GetPlayerMapPosition(uId)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(uId)
			end
		DBM.Arrow:ShowRunAway(x, y, 10, 5)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if args:IsSpellID(68981, 74270, 74271, 74272) or args:IsSpellID(72259, 74273, 74274, 74275) then -- Remorseless Winter (phase transition start)
		self:SetStage(self.vb.phase + 0.5) -- Intermission. Use + 0.5 workaround to differentiate between intermissions.
		self.vb.ragingSpiritCount = 1
		warnRemorselessWinter:Show()
		timerPhaseTransition:Start()
		if self.vb.phase == 1.5 then -- Fixed timers. SPELL_CAST_SUCCESS: (Aura 3.3.5: 25H [2025-07-24]@[10:58:24] || 25H [2025-07-24]@[11:14:31]) - 2.94, Stage 2.5/178.47, 4.95 || 2.94, Stage 2.5/224.72, 4.95
			timerRagingSpiritCD:Start(2.94, self.vb.ragingSpiritCount)
		else
			timerRagingSpiritCD:Start(4.95, self.vb.ragingSpiritCount)
		end
		warnShamblingSoon:Cancel()
		timerShamblingHorror:Cancel()
		timerDrudgeGhouls:Cancel()
		timerSummonValkyr:Cancel()
		timerInfestCD:Cancel()
		soundInfestSoon:Cancel()
		timerNecroticPlagueCD:Cancel()
		timerTrapCD:Cancel()
		timerDefileCD:Cancel()
		warnDefileSoon:Cancel()
		warnDefileSoon:CancelVoice()
		timerSoulreaperCD:Cancel()
		soundSoulReaperSoon:Cancel()
		self:RegisterShortTermEvents(
			"UPDATE_MOUSEOVER_UNIT",
			"UNIT_TARGET_UNFILTERED"
		)
		self:DestroyFrame()
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(8)
		end
	elseif args:IsSpellID(72143, 72146, 72147, 72148) then -- Shambling Horror enrage effect.
		local shamblingCount = DBM:tIndexOf(shamblingHorrorsGUIDs, args.sourceGUID)
		warnShamblingEnrage:Show(args.sourceName)
		specWarnEnrage:Show()
		timerEnrageCD:Stop(shamblingCount, args.sourceGUID) -- Stop/Unschedule required for multi arg timers, instead of Restart/Cancel - Core bug with mismatched args
		timerEnrageCD:Unschedule(nil, shamblingCount, args.sourceGUID)
		timerEnrageCD:Start(nil, shamblingCount, args.sourceGUID)
		timerEnrageCD:Schedule(25, nil, shamblingCount, args.sourceGUID) -- has to be the highest possible timer
	elseif spellId == 72262 then -- Quake (phase transition end)
		self.vb.ragingSpiritCount = 0
		warnQuake:Show()
		timerRagingSpiritCD:Cancel()
		self:SetStage(self.vb.phase + 0.5) -- Return back to whole number
		self:UnregisterShortTermEvents()
		NextPhase(self) -- keep this after UnregisterShortTermEvents for P2 vehicle events
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
	elseif spellId == 70358 then -- Drudge Ghouls
		warnDrudgeGhouls:Show()
		timerDrudgeGhouls:Start()
	elseif spellId == 70498 then -- Vile Spirits
		warnSummonVileSpirit:Show()
		timerVileSpirit:Start()
	elseif args:IsSpellID(70541, 73779, 73780, 73781) then -- Infest
		self.vb.infestCount = self.vb.infestCount + 1
		warnInfest:Show(self.vb.infestCount)
		specWarnInfest:Show(self.vb.infestCount)
		timerInfestCD:Start(nil, self.vb.infestCount+1)
		soundInfestSoon:Cancel()
		soundInfestSoon:Schedule(22.5-2, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\infestSoon.mp3")
	elseif spellId == 72762 then -- Defile
		-- self.vb.defileCount = self.vb.defileCount + 1
		self:BossTargetScanner(36597, "DefileTarget", 0.02, 15)
		-- warnDefileSoon:Cancel()
		-- warnDefileSoon:CancelVoice()
		-- warnDefileSoon:Schedule(27, self.vb.defileCount+1)
		-- warnDefileSoon:ScheduleVoice(27, "scatter")
		-- timerDefileCD:Start(nil, self.vb.defileCount+1)
	elseif spellId == 73539 then -- Shadow Trap (Heroic)
		self:BossTargetScanner(36597, "TrapTarget", 0.02, 10)
		timerTrapCD:Start()
	elseif spellId == 73650 then -- Restore Soul (Heroic)
		warnRestoreSoul:Show()
		timerRestoreSoul:Start()
		self:Schedule(40, leftFrostmourne, self) -- Always 40s
		if self.Options.RemoveImmunes then
			self:Schedule(39.99, RemoveImmunes, self)
		end
	elseif spellId == 72350 then -- Fury of Frostmourne
		self:SetWipeTime(190) --Change min wipe time mid battle to force dbm to keep module loaded for this long out of combat roleplay, hopefully without breaking mod.
		self:Stop()
		self:ClearIcons()
		timerRoleplay:Start()
	elseif args:IsSpellID(69242, 73800, 73801, 73802) then -- Soul Shriek Raging spirits
		timerSoulShriekCD:Start(args.sourceGUID)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args:IsSpellID(70337, 73912, 73913, 73914) then -- Necrotic Plague (SPELL_AURA_APPLIED is not fired for this spell)
		lastPlague = args.destName
		warnNecroticPlague:Show(lastPlague)
		timerNecroticPlagueCD:Start()
		timerNecroticPlagueCleanse:Start()
		if args:IsPlayer() then
			specWarnNecroticPlague:Show()
			soundNecroticOnYou:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\necroticOnYou.mp3")
		end
		if self.Options.NecroticPlagueIcon then
			self:SetIcon(lastPlague, 4, 5)
		end
	elseif args:IsSpellID(69409, 73797, 73798, 73799) then -- Soul reaper (MT debuff)
		self.vb.soulReaperCount = self.vb.soulReaperCount + 1
		timerSoulreaperCD:Cancel()
		warnSoulreaper:Show(self.vb.soulReaperCount, args.destName)
		specwarnSoulreaper:Show(args.destName)
		timerSoulreaper:Start(args.destName)
		timerSoulreaperCD:Start(nil, self.vb.soulReaperCount+1)
		soundSoulReaperSoon:Schedule(30.5-2.5, "Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\soulreaperSoon.mp3")
		if args:IsPlayer() then
			specWarnSoulreaper:Show()
			specWarnSoulreaper:Play("defensive")
		else
			specWarnSoulreaperOtr:Show(args.destName)
			specWarnSoulreaperOtr:Play("tauntboss")
		end
	elseif spellId == 69200 then -- Raging Spirit
		self.vb.ragingSpiritCount = self.vb.ragingSpiritCount + 1
		tinsert(ragingSpiritsGUIDs, "unknownSpiritGUID") -- spirit GUID is unknown, and it would be expensive to both retrieve it later and to manipulate the timer, so we just use a dummy GUID to cancel later
		timerSoulShriekCD:Start(14, "unknownSpiritGUID") -- Diff between SPELL_CAST_START/73802 (Soul Shriek) and SPELL_CAST_SUCCESS/69200 (Raging Spirit). 14.13
		if args:IsPlayer() then
			specWarnRagingSpirit:Show()
			specWarnRagingSpirit:Play("targetyou")
		else
			warnRagingSpirit:Show(args.destName)
		end
--		if self.vb.phase == 1.5 then
			timerRagingSpiritCD:Start(nil, self.vb.ragingSpiritCount) -- same variant timer for both intermissions
--		else
--			timerRagingSpiritCD:Start(15.0, self.vb.ragingSpiritCount)
--		end
		if self.Options.RagingSpiritIcon then
			self:SetIcon(args.destName, 6, 5)
		end
	elseif args:IsSpellID(69037, 74361) then -- Summon Val'kyr Periodic (10H, 25H) | Summon Val'kyr (10N, 25N)
		table.wipe(valkyrTargets)	-- reset valkyr cache for next round
		grabIcon = 2
		self.vb.valkIcon = 2
		self.vb.valkyrWaveCount = self.vb.valkyrWaveCount + 1
		warnSummonValkyr:Show(self.vb.valkyrWaveCount)
		timerSummonValkyr:Start(nil, self.vb.valkyrWaveCount+1)
		-- Schedule a defile (or reschedule it) if next defile event doesn't exist ( now > next defile ) or defile is coming too soon
-- 		local minTime = self:IsDifficulty("normal25", "heroic25") and 5 or 4
--		local defileTimerStarted = timerDefileCD:IsStarted() -- REIVEW! I think I do not need this, since GetRemaining will return 0 if no timer is started
-- 		if --[[not defileTimerStarted or defileTimerStarted and]] timerDefileCD:GetRemaining() < minTime then
-- 			DBM:Debug("Defile timer adjusted since it was too close to Val'kyr summons")
-- 			timerDefileCD:Restart(minTime) -- Belongs to EVENT_GROUP_ABILITIES
-- 		end
	elseif args:IsSpellID(68980, 74325, 74326, 74327) then -- Harvest Soul
		timerHarvestSoul:Start(args.destName)
		timerHarvestSoulCD:Start()
		if args:IsPlayer() then
			specWarnHarvestSoul:Show()
			specWarnHarvestSoul:Play("targetyou")
		else
			warnHarvestSoul:Show(args.destName)
		end
		if self.Options.HarvestSoulIcon then
			self:SetIcon(args.destName, 5, 5)
		end
	elseif args:IsSpellID(73654, 74295, 74296, 74297) then -- Harvest Souls (Heroic)
		specWarnHarvestSouls:Show()
		--specWarnHarvestSouls:Play("phasechange")
--		timerHarvestSoulCD:Start(106.1) -- Custom edit to make Harvest Souls timers work again. REVIEW! 1s variance? (25H Lordaeron 2022/09/03 || 25H Lordaeron 2022/11/16) - 106.4, 107.5, 106.5 || 106.1, 106.3, 106.6
		timerVileSpirit:Cancel()
		timerSoulreaperCD:Cancel()
		soundSoulReaperSoon:Cancel()
		timerDefileCD:Cancel()
		warnDefileSoon:Cancel()
		warnDefileSoon:CancelVoice()
		self:SetWipeTime(50)--We set a 45 sec min wipe time to keep mod from ending combat if you die while rest of raid is in frostmourn
		self:Schedule(50, RestoreWipeTime, self)
--		self:Schedule(48.55, leftFrostmourne, self) -- Subtract [48.55]s from Exit FM to last CAST_SUCCESS diff. Timestamps: Harvest cast success > Enter Frostmourne (SAA 73655) > Exit FM (SAR 73655) > Exit FM (ZONE_CHANGED) > Harvest cast. (25H Lordaeron [2023-08-23]@[22:14:48]) - "Harvest Souls-74297-npc:36597-3706 = pull:452.4/Stage 3/14.0, 107.3, 107.2" => '107.3 calculation as follows': 452.42 > 458.44 [6.02] > 500.97 [42.53/48.55] > 501.39 [0.42/42.95/48.97] > 559.69 [58.30/58.72/101.25/107.27]
	end
end

function mod:SPELL_DISPEL(args)
	local extraSpellId = args.extraSpellId
	if type(extraSpellId) == "number" and (extraSpellId == 70337 or extraSpellId == 73912 or extraSpellId == 73913 or extraSpellId == 73914 or extraSpellId == 70338 or extraSpellId == 73785 or extraSpellId == 73786 or extraSpellId == 73787) then
		if self.Options.NecroticPlagueIcon then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
--	if args:IsSpellID(72143, 72146, 72147, 72148) then -- Shambling Horror enrage effect. Disabled on AURA_APPLIED since it is earlier (and therefore better) on CAST_START. Also prevents double announce
--		timerEnrageCD:Cancel(args.sourceGUID)
--		warnShamblingEnrage:Show(args.destName)
--		timerEnrageCD:Start(args.sourceGUID)
	if spellId == 28747 then -- Shambling Horror enrage effect on low hp
		specWarnEnrageLow:Show()
	elseif args:IsSpellID(72754, 73708, 73709, 73710) and args:IsPlayer() and self:AntiSpam(2, 1) then		-- Defile Damage
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
		soundDefileOnYou:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\defileOnYou.mp3")
--[[ -- no longer needed since we use SPELL_CAST_START scheduling for leftFrostmourne. Unsure as to when this
	elseif spellId == 73650 and self:AntiSpam(3, 2) then		-- Restore Soul (Heroic)
		-- DBM:AddMsg("Restore Soul SPELL_AURA_APPLIED unhidden from combat log. Notify Zidras on Discord or GitHub") -- no longer valid, at least from 18/04/2025 on Warmane.
		timerHarvestSoulCD:Start(60) -- this is slighly innacurate
		timerVileSpirit:Start(10)--May be wrong too but we'll see, didn't have enough log for this one.
]]
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(70338, 73785, 73786, 73787) then	--Necrotic Plague (hop IDs only since they DO fire for >=2 stacks, since function never announces 1 stacks anyways don't need to monitor LK casts/Boss Whispers here)
		if self.Options.AnnouncePlagueStack and DBM:GetRaidRank() > 0 then
			if args.amount % 10 == 0 or (args.amount >= 10 and args.amount % 5 == 0) then		-- Warn at 10th stack and every 5th stack if more than 10
				SendChatMessage(L.PlagueStackWarning:format(args.destName, (args.amount or 1)), "RAID")
			elseif (args.amount or 1) >= 30 and not warnedAchievement then						-- Announce achievement completed if 30 stacks is reached
				SendChatMessage(L.AchievementCompleted:format(args.destName, (args.amount or 1)), "RAID_WARNING")
				warnedAchievement = true
			end
		end
	end
end

--[[ This would probably fail on early UNIT_DIED, so schedule it instead
function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 73655 and args:IsPlayer() then -- Harvest Soul (25H)
		timerHarvestSoulCD:Start(57.5) -- Subtract [48.56]s to CAST_SUCCESS diff. Timestamps: Harvest cast > Enter Frostmourne > Exit FM > Harvest cast. (25H Lordaeron [2023-08-23]@[22:14:48]) - "Harvest Souls-74297-npc:36597-3706 = pull:452.4/Stage 3/14.0, 107.3, 107.2" => '107.3 calculation as follows': 452.42 > 458.87 [6.45] > 500.98 > 501.39 [0.41/42.52/48.97] > 559.69 [58.30/58.71/100.82/107.27]
	end
end
]]

function mod:SPELL_SUMMON(args)
	local spellId = args.spellId
	if spellId == 69037 then -- Summon Val'kyr
		if self.Options.ShowFrame then
			self:CreateFrame()
		end
		if self.Options.ValkyrIcon then
			self:ScanForMobs(args.destGUID, 2, self.vb.valkIcon, 1, nil, 12, "ValkyrIcon")
		end
		self.vb.valkIcon = self.vb.valkIcon + 1
--[[		self.vb.valkyrWaveCount = self.vb.valkyrWaveCount + 1
		if time() - lastValk > 15 then -- show the warning and timer just once for all three summon events
			warnSummonValkyr:Show(self.vb.valkyrWaveCount)
			timerSummonValkyr:Start(nil, self.vb.valkyrWaveCount+1)
			lastValk = time()
			scanValkyrTargets(self)
			--if self.Options.ValkyrIcon then
			--	local cid = self:GetCIDFromGUID(args.destGUID)
			--	if self:IsDifficulty("normal25", "heroic25") then
			--		self:ScanForMobs(args.destGUID, 1, 2, 3, nil, 20, "ValkyrIcon")--mod, scanId, iconSetMethod, mobIcon, maxIcon,
			--	else
			--		self:ScanForMobs(args.destGUID, 1, 2, 1, nil, 20, "ValkyrIcon")
			--	end
			--end
		end--]]
	elseif spellId == 70372 then -- Shambling Horror
		tinsert(shamblingHorrorsGUIDs, args.destGUID) -- Spawn order. Idea was to somehow distinguish shamblings, so let's do this on the assumption that it's visually easy to differentiate them due to HP diff.
		local shamblingCount = DBM:tIndexOf(shamblingHorrorsGUIDs, args.destGUID)
		warnShamblingSoon:Cancel()
		warnShamblingHorror:Show()
		warnShamblingSoon:Schedule(55)
		timerShamblingHorror:Start()
		timerEnrageCD:Start(11.32, shamblingCount, args.destGUID) -- REVIEW! 11.32s from Shambling Enrage summon. summon > enrage [diff]. (Aura 3.3.5: 25H [2025-07-23]@[11:02:02]) - (59.61 summon -> 70.93 scstart [11.32])
		timerEnrageCD:Schedule(11.32+2, nil, shamblingCount, args.destGUID) -- apparently on Warmane if you stun on pre-cast, it skips the Enrage. Couldn't repro on test server nor validate it, but doesn't really hurt because SCS has Restart method
	end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
	if (spellId == 68983 or spellId == 73791 or spellId == 73792 or spellId == 73793) and destGUID == UnitGUID("player") and self:AntiSpam(2, 3) then		-- Remorseless Winter
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:UNIT_HEALTH(uId)
	if self:IsHeroic() and self:GetUnitCreatureId(uId) == 36609 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.55 and not warnedValkyrGUIDs[UnitGUID(uId)] then
		warnedValkyrGUIDs[UnitGUID(uId)] = true
		specWarnValkyrLow:Show()
		specWarnValkyrLow:Play("stopattack")
	end
	if self.vb.phase == 1 and not self.vb.warned_preP2 and self:GetUnitCreatureId(uId) == 36597 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.73 then
		self.vb.warned_preP2 = true
		warnPhase2Soon:Show()
	elseif self.vb.phase == 2 and not self.vb.warned_preP3 and self:GetUnitCreatureId(uId) == 36597 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.43 then
		self.vb.warned_preP3 = true
		warnPhase3Soon:Show()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.LKPull or msg:find(L.LKPull) then
		self:SendSync("CombatStart")
		if self.Options.ShowFrame then
			self:CreateFrame()
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.EmoteDefileCast or msg:find(L.EmoteDefileCast) then -- necessary to overcome bug in the server script where boss won't cast Defile (I assume due to running and interrupts internal cast)
		self.vb.defileCount = self.vb.defileCount + 1
--		self:BossTargetScanner(36597, "DefileTarget", 0.02, 15) -- This will be deferred to SPELL_CAST_START, since it ensures that boss is indeed casting
		warnDefileSoon:Cancel()
		warnDefileSoon:CancelVoice()
		warnDefileSoon:Schedule(27, self.vb.defileCount+1)
		warnDefileSoon:ScheduleVoice(27, "scatter")
		timerDefileCD:Start(nil, self.vb.defileCount+1)
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 37698 then--Shambling Horror
		local shamblingCount = DBM:tIndexOf(shamblingHorrorsGUIDs, args.sourceGUID)
		timerEnrageCD:Stop(shamblingCount, args.sourceGUID)
		timerEnrageCD:Unschedule(nil, shamblingCount, args.sourceGUID)
	elseif cid == 36701 then -- Raging Spirit
		timerSoulShriekCD:Cancel(args.sourceGUID)
	end
end

function mod:UNIT_AURA_UNFILTERED(uId)
	local name = DBM:GetUnitFullName(uId)
	if (not name) or (name == lastPlague) then return end
	local _, _, _, _, _, _, expires, _, _, _, spellId = DBM:UnitDebuff(uId, plagueHop)
	if not spellId or not expires then return end
	if (spellId == 73787 or spellId == 70338 or spellId == 73785 or spellId == 73786) and expires > 0 and not plagueExpires[expires] then
		plagueExpires[expires] = true
		warnNecroticPlagueJump:Show(name)
		timerNecroticPlagueCleanse:Restart() -- prevent timer debug, since dispel can (and should) happen before the 5s expires
		if name == UnitName("player") and not mod:IsTank() then
			specWarnNecroticPlague:Show()
			soundNecroticOnYou:Play("Interface\\AddOns\\DBM-Core\\sounds\\RaidAbilities\\necroticOnYou.mp3")
		end
		if self.Options.NecroticPlagueIcon then
			self:SetIcon(uId, 4, 5)
		end
	end
end

function mod:UNIT_ENTERING_VEHICLE(uId)
	local unitName = UnitName(uId)
	DBM:Debug("UNIT_ENTERING_VEHICLE Val'kyr check for "..  unitName .. " (" .. uId .. "): UnitInVehicle is returning " .. (UnitInVehicle(uId) or "nil") .. " and UnitInRange is returning " .. (UnitInRange(uId) or "nil") .. " with distance: " .. DBM.RangeCheck:GetDistance(uId) .."yd. Checking if it is already cached: " .. (valkyrTargets[unitName] and "true" or "nil."), 3)
--		DBM:Debug(unitName .. " (" .. uId .. ") has entered a vehicle. Confirming API: " .. (UnitInVehicle(uId) or "nil"))
	if UnitInVehicle(uId) and not valkyrTargets[unitName] then	  -- if person is in a vehicle and not already announced (API is probably unneeded, need more logs to confirm. Cache check is required to prevent this event from multifiring for the same raid member with more than one uId)
		valkyrGrabWarning:Show(DBM:GetUnitRoleIcon(uId), unitName, DBM:IconNumToTexture(grabIcon)) -- roleIcon, name, raid target icon
		valkyrTargets[unitName] = true
		local raidIndex = UnitInRaid(uId)
		local name, _, subgroup, _, _, fileName = GetRaidRosterInfo(raidIndex + 1)
		if name == unitName then
			local grp = subgroup
			local class = fileName
			self:AddEntry(name, grp or 0, class, grabIcon)
		end
		if UnitIsUnit(uId, "player") then
			specWarnYouAreValkd:Show()
			specWarnYouAreValkd:Play("targetyou")
		end
		if DBM:IsInGroup() and self.Options.AnnounceValkGrabs and DBM:GetRaidRank() > 1 then
			local channel = (IsInRaid() and "RAID") or "PARTY"
			if self.Options.ValkyrIcon then
				SendChatMessage(L.ValkGrabbedIcon:format(grabIcon, unitName), channel)
			else
				SendChatMessage(L.ValkGrabbed:format(unitName), channel)
			end
		end
		grabIcon = grabIcon + 1--Makes assumption discovery order of vehicle grabs will match combat log order, since there is a delay
	end
end

function mod:UNIT_EXITING_VEHICLE(uId)
	local unitName = UnitName(uId)
	DBM:Debug(unitName .. " (" .. uId .. ") has exited a vehicle. Confirming API: " .. (UnitInVehicle(uId) or "nil"))
	if valkyrTargets[unitName] then -- on Val'kyr passenger drop, it sometimes fires twice in one second succession, so check cache (AntiSpam was a bit too much for this)
		valkyrTargets[unitName] = nil
		self:RemoveEntry(unitName)
	end
end

function mod:UPDATE_MOUSEOVER_UNIT()
	if DBM:GetUnitCreatureId("mouseover") == 36633 then -- Ice Sphere
		local sphereGUID = UnitGUID("mouseover")
		local sphereTarget = UnitName("mouseovertarget")
		if sphereGUID and sphereTarget and not iceSpheresGUIDs[sphereGUID] then
			local sphereString = ("%s\t%s"):format(sphereTarget, sphereGUID)
			self:SendSync("SphereTarget", sphereString)
		end
	elseif DBM:GetUnitCreatureId("mouseover") == 36701 then -- Raging Spirit
		local spiritGUID = UnitGUID("mouseover")
		if spiritGUID and not tContains(ragingSpiritsGUIDs, spiritGUID) then
			local spiritIndex = DBM:tIndexOf(ragingSpiritsGUIDs, "unknownSpiritGUID")
			if spiritIndex then
				ragingSpiritsGUIDs[spiritIndex] = spiritGUID -- replace the dummy GUID with the real one
				local totalTime = timerSoulShriekCD:Time("unknownSpiritGUID")
				local elapsedTime = timerSoulShriekCD:GetTime("unknownSpiritGUID")
				timerSoulShriekCD:Cancel("unknownSpiritGUID") -- cancel the dummy timer
				timerSoulShriekCD:Update(elapsedTime, totalTime, spiritGUID) -- restart the timer with the real GUID
			end
		end
	end
end

function mod:UNIT_TARGET_UNFILTERED(uId)
	if DBM:GetUnitCreatureId(uId.."target") == 36633 then -- Ice Sphere
		local sphereGUID = UnitGUID(uId.."target")
		local sphereTarget = UnitName(uId.."targettarget")
		if sphereGUID and sphereTarget and not iceSpheresGUIDs[sphereGUID] then
			iceSpheresGUIDs[sphereGUID] = sphereTarget
			warnIceSpheresTarget:Show(sphereTarget)
			if sphereTarget == UnitName("player") then
				specWarnIceSpheresYou:Show()
				specWarnIceSpheresYou:Play("iceorbmove")
			end
		end
	elseif DBM:GetUnitCreatureId(uId.."target") == 36701 then -- Raging Spirit
		local spiritGUID = UnitGUID(uId.."target")
		if spiritGUID and not tContains(ragingSpiritsGUIDs, spiritGUID) then
			local spiritIndex = DBM:tIndexOf(ragingSpiritsGUIDs, "unknownSpiritGUID")
			if spiritIndex then
				ragingSpiritsGUIDs[spiritIndex] = spiritGUID -- replace the dummy GUID with the real one
				local totalTime = timerSoulShriekCD:Time("unknownSpiritGUID")
				local elapsedTime = timerSoulShriekCD:GetTime("unknownSpiritGUID")
				timerSoulShriekCD:Cancel("unknownSpiritGUID") -- cancel the dummy timer
				timerSoulShriekCD:Update(elapsedTime, totalTime, spiritGUID) -- restart the timer with the real GUID
			end
		end
	end
end

--[[
-- "<673.50 22:26:02> [DBM_Debug] Indoor/SubZone changed on zoneID: 605 and subZone: Frostmourne:nil:"
-- "<673.51 22:26:02> [ZONE_CHANGED_INDOORS] The Frozen Throne:Icecrown Citadel:Frostmourne:"

-- "<715.75 22:26:44> [DBM_Debug] Indoor/SubZone changed on zoneID: 605 and subZone: The Frozen Throne:nil:"
-- "<715.76 22:26:44> [ZONE_CHANGED] Icecrown Citadel:Icecrown Citadel:The Frozen Throne:"

-- This would probably fail on early UNIT_DIED, and is personal event, so schedule it instead
function mod:ZONE_CHANGED() -- [ZONE_CHANGED] Icecrown Citadel:Icecrown Citadel:The Frozen Throne:
	timerHarvestSoulCD:Start(58.3)
end
]]

function mod:OnSync(msg, target)
	if msg == "CombatStart" then
		timerCombatStart:Start()
--	elseif msg == "SoulShriek" then
--		timerSoulShriekCD:Start(target)
	elseif msg == "SphereTarget" then
		local sphereTarget, sphereGUID = strsplit("\t", target)
		if sphereTarget and sphereGUID and not iceSpheresGUIDs[sphereGUID] then
			iceSpheresGUIDs[sphereGUID] = sphereTarget
			warnIceSpheresTarget:Show(sphereTarget)
			if sphereTarget == UnitName("player") then
				specWarnIceSpheresYou:Show()
				specWarnIceSpheresYou:Play("iceorbmove")
			end
		end
	end
end
