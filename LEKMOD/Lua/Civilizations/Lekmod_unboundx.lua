-- UnboundX civilization Lua
-- Author: UnboundMod
-- Handles:
--   1. UU: Mr. Wiggu ruin bonus (+10 Gold, heal 50 HP on ancient ruin discovery)
--   2. UB: Data Center DoF gold stack (dummy building count = active DoFs)
--
-- Workers cost 24 gold (half base cost) via Cost=24 on UNIT_UB_UNBOUNDX_WORKER — no Lua needed.
--
-- All handlers registered unconditionally (outside is_active guard) following
-- LekMod's Nabatea pattern. Each handler does its own civ/unit check inside.

include("Lekmod_utilities.lua")

local this_civ = GameInfoTypes["CIVILIZATION_UNBOUNDX"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

local WIGGU_PROMOTION      = GameInfoTypes["PROMOTION_UB_WIGGU_RUIN_BONUS"]
local DATA_CENTER_BUILDING = GameInfoTypes["BUILDING_UB_UNBOUNDX_DATA_CENTER"]
local DOF_STACK_BUILDING   = GameInfoTypes["BUILDING_UB_UNBOUNDX_DOF_STACK"]
local IMPROVEMENT_GOODY_HUT = GameInfoTypes["IMPROVEMENT_GOODY_HUT"]

------------------------------------------------------------------------------------------------------------------------
-- PlayerDoTurn: update DoF gold stacks.
------------------------------------------------------------------------------------------------------------------------
function unboundx_player_do_turn(player_id)
    local player = Players[player_id]
    if not player or not player:IsAlive() then return end
    if player:GetCivilizationType() ~= this_civ then return end
    unboundx_update_dof_stacks(player, player_id)
end

------------------------------------------------------------------------------------------------------------------------
-- UU: When Mr. Wiggu (or any unit with PROMOTION_UB_WIGGU_RUIN_BONUS) steps onto
-- a goody hut, award +10 Gold and heal 50 HP.
-- UnitSetXY fires as the unit arrives at the tile, before the game consumes the hut,
-- so we can check the improvement type directly — no turn-start caching needed.
------------------------------------------------------------------------------------------------------------------------
function unboundx_wiggu_on_move(player_id, unit_id, x, y)
    local player = Players[player_id]
    if not player or not player:IsAlive() then return end
    local unit = player:GetUnitByID(unit_id)
    if not unit then return end
    if not unit:IsHasPromotion(WIGGU_PROMOTION) then return end

    local plot = Map.GetPlot(x, y)
    if not plot then return end
    if plot:GetImprovementType() ~= IMPROVEMENT_GOODY_HUT then return end

    -- Award gold and healing.
    player:ChangeGold(10)
    unit:SetDamage(math.max(0, unit:GetDamage() - 50))

    -- Show popup for human player.
    if player:IsHuman() and Game.GetActivePlayer() == player_id then
        Events.GameplayAlertMessage(Locale.ConvertTextKey("TXT_KEY_UB_UNBOUNDX_WIGGU_RUIN_POPUP"))
    end
end

------------------------------------------------------------------------------------------------------------------------
-- UB: Count active DoFs and set dummy building stack in every Data Center city.
------------------------------------------------------------------------------------------------------------------------
function unboundx_update_dof_stacks(player, player_id)
    if not player or not player:IsAlive() then return end

    local dof_count = 0
    for other_id = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
        if other_id ~= player_id then
            local other = Players[other_id]
            if other and other:IsAlive() and not other:IsMinorCiv() then
                if player:IsDoF(other_id) then
                    dof_count = dof_count + 1
                end
            end
        end
    end

    for city in player:Cities() do
        if city:IsHasBuilding(DATA_CENTER_BUILDING) then
            city:SetNumRealBuilding(DOF_STACK_BUILDING, dof_count)
        else
            city:SetNumRealBuilding(DOF_STACK_BUILDING, 0)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
-- Register all handlers unconditionally. Civ/unit checks are inside each function.
------------------------------------------------------------------------------------------------------------------------
GameEvents.PlayerDoTurn.Add(unboundx_player_do_turn)
GameEvents.UnitSetXY.Add(unboundx_wiggu_on_move)
