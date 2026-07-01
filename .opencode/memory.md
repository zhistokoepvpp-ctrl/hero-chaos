# Project Memory: Hero Chaos

## Tech Stack
- **Engine:** Godot 4.6 Standard (GL Compatibility, 1280x720, 2D)
- **Language:** GDScript only (no C#, no GDExtension)
- **Network:** ENet P2P via ENetMultiplayerPeer (port 25565, max 8 players)
- **Master Server:** Python/FastAPI planned — `master-server/` directory empty
- **Assets:** None — all visuals are ColorRect placeholders. `AudioManager` is a stub.

## Project Structure
```
game/
├── Scenes/          — 6 .tscn files (flat, no subdirs)
├── Scripts/
│   ├── Global/      — 9 autoload singletons (GameManager, NetworkManager, Constants, etc.)
│   ├── Heroes/      — HeroBase + 10 hero scripts (most abilities are `pass` stubs)
│   ├── UI/          — 6 UI controllers (one per scene)
│   └── Enemies/     — MonsterBase + WaveManager
├── Assets/          — empty placeholders
└── Resources/       — empty placeholders
master-server/       — empty (planned FastAPI)
tools/               — md_to_docx.py
```

## Architecture
- **State Machine:** `GameManager.phase` (setter -> emits `phase_changed` signal). Phases: MAIN_MENU → HERO_SELECT → LOBBY → WAVE/DUEL → RESULTS → GAME_OVER
- **Singletons:** 9 autoloads registered in project.godot, available globally
- **OOP:** HeroBase (extends Node) → 10 heroes. MonsterBase (extends Node2D). PlayerData (extends RefCounted, not a Node)
- **Network:** Host authoritative (economy, timers, lives). Client simulates arena locally. AntiCheat validates reports.
- **Signals:** Used for phase changes, monster events, network events. UI connects in _ready()
- **Data:** Hardcoded dictionaries in _ready() (ItemDatabase, HeroDatabase). Resources/ dirs planned but empty.
- **Scene Switching:** `get_tree().change_scene_to_file()` — autoloads persist across scenes

## Naming Conventions
- **Files/Classes:** PascalCase (`GameManager.gd`, `HeroBase.gd`)
- **Hero files:** `Hero<Name>.gd` prefix
- **UI scripts:** `<Scene>UI.gd` suffix
- **Base classes:** `<Name>Base.gd` suffix
- **Scenes:** PascalCase (`Arena.tscn`)
- **Variables/Functions:** snake_case, private with `_` prefix
- **Constants:** UPPER_SNAKE_CASE
- **Enums:** PascalCase names, UPPER_SNAKE_CASE values
- **RPC methods:** `rpc_` prefix

## Git (35 commits, single author `zhistokoepvpp-ctrl`)
- **Only `master` branch** — linear trunk-based, no feature branches, no tags
- **Commit format:** Conventional Commits (`feat:`, `fix:`, `phaseN:`), no scope, no body
- **No hooks** — only default .sample files
- **.gitignore:** Covers Godot, Python, OS, IDE, builds

## Game Loop
1. MainMenu → Host/Join
2. HeroSelect → Pick hero (30s timer, defaults Warrior)
3. Lobby → Shop (B), Attributes (U), READY, 60s timer, free-roam movement
4. Wave (arena) → Kill monsters, 60s + overtime scaling, RMB move/attack
5. Duel (every 5th wave) → 1v1 AI, 60s timer, win by kill or higher HP%
6. Repeat from Lobby until 1 player remains → Game Over

## Economy (Phase 4)
- 15 base items (in ItemDatabase) + 10 recipes (auto-combine)
- Shop (B) buy/sell (50% ratio)
- Attributes (U): STR/AGI/INT, 2 points per level
- Items affect: max_hp, max_mana, damage, armor, speed, atk_speed, etc.
- Inventory: 6 slots (3×2 GridContainer)
- Wave bonus by placement (80/60/45/35/25/20/15/10 gold)

## HUD Layout (all 3 game scenes)
- **Hotbar centered:** Portrait at x=412 (56w), HP/MP bars at x=468 (400w), Q/W at x=610
- **Inventory 3×2:** InvBox GridContainer at x=1130, 42px cells
- **Gold/Shop:** x=1130, gold at y=696, Shop button at y=714
- **Lives:** `♥♥` at top-left

## Known Issues & Fixes
- **HeroSelect → Lobby crash:** `@onready` nodes for hotbar might be null during transition. Added null guards in `_spawn_hero()`, `_process()`, `_update_inv_slots()`, `_update_hotbar()`.
- **Duel cooldowns:** Fixed by adding `_hero` to scene tree (`arena_view.add_child(_hero)`).
- **Target highlight:** Yellow ColorRect ring (not modulate — invisible on dark colors).
- **Monster separation:** `_separate()` pushes monsters apart when distance < 24px.
- **Auto-attack:** After killing target, auto-switches to nearest monster (no passive auto-acquire).

## Commands
- **Run game:** `& "C:\Users\SystemX\Desktop\Godot_v4.6-stable_win64.exe" --path "C:\Users\SystemX\Desktop\delaem\game"`
- **Run multiple instances:** Godot Debug → Run Multiple Instances
- **UID files:** Generated automatically by Godot

## What's NOT Implemented (Stubs/Empty)
- Hero abilities (all Q/W are `pass`)
- Boss behaviors
- Betting system
- Spectator mode
- Chat system
- Wave Results screen
- Game Over screen
- Master server (Python/FastAPI)
- Audio/music/SFX
- Sprites (ColorRect only)
- MMR/ranking
- Disconnect/reconnect logic
- AI bot on disconnect
- Multiplayer sync (RPCs mostly stubs)
- MultiplayerSpawner/Synchronizer not configured

## AGENTS.md Instructions
- Challenge decisions if approach is bad
- Structure responses: what was done, what's needed from user, next step
- Suggest improvements/automation after each task
