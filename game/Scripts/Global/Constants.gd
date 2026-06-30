extends Node

# ─── Game Phases ───
enum GamePhase { MAIN_MENU, HERO_SELECT, LOBBY, WAVE, DUEL, RESULTS, GAME_OVER }

# ─── Heroes ───
enum HeroType { WARRIOR, ARCHER, MAGE, ASSASSIN, PALADIN, NECROMANCER, BERSERKER, SHAMAN, GUNSLINGER, SPELLBLADE }

# ─── Attributes ───
enum AttrType { STR, AGI, INT }
const MAX_LEVEL := 30
const ATTR_POINTS_PER_LEVEL := 2

# ─── Timing ───
const LOBBY_TIME := 60.0
const WAVE_TIME := 60.0
const DUEL_TIME := 60.0
const HERO_SELECT_TIME := 30.0
const RESULTS_TIME := 5.0
const RESPAWN_DELAY := 3.0
const DISCONNECT_TIMEOUT := 15.0
const RECONNECT_WINDOW := 180.0
const LOBBY_READY_SKIP := false

# ─── Network ───
const DEFAULT_PORT := 25565
const MAX_PLAYERS := 8
const HEARTBEAT_INTERVAL := 30.0
const HEARTBEAT_TIMEOUT := 120.0
const MAX_COMMANDS_PER_SEC := 20
const LOBBY_SYNC_RATE := 20
const SPECTATOR_SYNC_RATE := 10

# ─── Economy ───
const STARTING_GOLD := 200
const BASE_HP := 200.0
const BASE_MANA := 50.0
const HP_PER_STR := 22.0
const HP_REGEN_PER_STR := 0.1
const MANA_PER_INT := 12.0
const MANA_REGEN_PER_INT := 0.05
const ATK_SPD_PER_AGI := 0.01
const ARMOR_PER_AGI := 0.16
const ABL_DMG_PER_INT := 0.02
const CRIT_DMG_MULTI := 2.0
const SELL_RATIO := 0.5

# ─── Lives ───
const STARTING_LIVES := 2
const LIVES_LOST_ON_DEATH := 1
const LIVES_THRESHOLD_DUEL := 4

# ─── Wave ───
const WAVE_BONUSES := [80, 60, 45, 35, 25, 20, 15, 10]
const OVERTIME_DMG_PER_SEC := 0.02
const OVERTIME_SPD_PER_SEC := 0.01
const BOSS_INTERVAL := 10
const DUEL_INTERVAL := 5

# ─── Monsters ───
const MONSTER_BASE_COUNT := 3
const MONSTER_COUNT_PER_WAVE := 2
const MONSTER_HP_MULT := 0.12
const MONSTER_DMG_MULT := 0.10

# ─── Duel ───
const DUEL_WINNER_GOLD := 50
const MIN_BET := 10
const MAX_BET := 100
const BET_MULTIPLIER := 2.0

# ─── MMR ───
const BASE_MMR := 1000
const MMR_CHANGES := [35, 20, 10, 0, -5, -10, -20, -35]
