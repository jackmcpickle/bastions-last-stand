# Bastion's Last Stand
## Game Design Document v1.0

**Genre:** Tower Defense  
**Platform:** Mobile (iOS & Android)  
**Engine:** Godot 4.6  
**Target Audience:** Casual to mid-core strategy gamers  

---

## 1. Game Overview

### 1.1 Core Concept

A top-down tower defense game where players protect a sacred Shrine by building mazes of walls and towers. Enemies pathfind through player-created layouts, creating emergent puzzle-strategy gameplay. Features deep tower upgrade trees with branching specializations.

### 1.2 Unique Selling Points

- **Dynamic Maze Building**: Place your Shrine anywhere, then construct defenses around it
- **Intelligent Pathfinding**: Enemies navigate around obstacles (except Breakers and Flyers)
- **Deep Progression**: Each tower has 2-tier branching upgrades (7 final specializations per tower)
- **Special Rounds**: Rush waves test AOE, Smash waves destroy your maze

### 1.3 Core Loop

```
Place Shrine → Build Maze/Towers → Start Wave → Enemies Pathfind → 
Earn Gold → Upgrade/Expand → Next Wave → Repeat
```

---

## 2. Core Mechanics

### 2.1 The Shrine

The Shrine is the player's core objective to protect.

| Property | Value |
|----------|-------|
| Base HP | 100 |
| Placement | Player chooses location at start of each map |
| Healing | Cannot be healed during waves |
| Game Over | Shrine HP reaches 0 |

**Design Intent**: Allowing Shrine placement creates replayability. Corner placement = longer paths but limited expansion. Center = multiple approach angles but shorter paths.

### 2.2 Pathfinding System

Enemies use A* pathfinding with the following rules:

**Standard Enemies**
- Calculate shortest path from spawn to Shrine
- Recalculate when path is blocked
- If NO valid path exists → Attack nearest wall/tower blocking path
- Will not attack walls if ANY valid path exists

**Wall Breakers (Smash Rounds)**
- Ignore pathfinding
- Move directly toward Shrine
- Destroy walls and towers in their path
- High HP, moderate damage to structures

**Flyers**
- Ignore all ground obstacles
- Fly directly toward Shrine
- Cannot be blocked by walls
- Lower HP than ground equivalents

**Path Blocking Rule**: Players CAN completely wall off the Shrine, but this triggers "Siege Mode" where ALL enemies attack walls. This is a valid (if expensive) strategy.

### 2.3 Economy System

| Source | Gold Amount |
|--------|-------------|
| Base kill reward | Varies by enemy type |
| Early start bonus | +10% per 5 seconds early (max +50%) |
| Perfect wave (no damage) | +25% bonus |
| Interest (unlockable) | +5% of banked gold per wave (max 50 gold) |

**Tower Selling**: Towers can be sold for 90% of total invested value (base cost + all upgrade costs).

### 2.4 Upgrade System

All towers follow this upgrade structure:

```
        [Base Tower]
            │
     ┌──────┴──────┐
     │             │
 [Branch A]    [Branch B]
     │             │
  ┌──┴──┐       ┌──┴──┐
  │     │       │     │
[A1]  [A2]    [B1]  [B2]
```

- **Tier 1 (Base)**: Available immediately
- **Tier 2 (Branch)**: Choose A or B specialization
- **Tier 3 (Final)**: Choose between two masteries

Once a branch is chosen, the other is locked. This creates 4 possible final forms per tower.

---

## 3. Towers

### 3.1 Archer Tower

**Role**: Fast single-target damage, anti-priority  
**Base Cost**: 100 gold

| Tier | Name | Stats | Special |
|------|------|-------|---------|
| 1 | Archer Tower | 15 dmg, 0.8s attack speed, 5 range | Basic arrows |
| 2A | Marksman | 25 dmg, 1.0s, 7 range | +50% crit chance |
| 2B | Rapid Fire | 12 dmg, 0.4s, 4.5 range | Double shot speed |
| 3A1 | Sniper | 80 dmg, 2.0s, 12 range | Instakill enemies <100 HP |
| 3A2 | Hunter | 35 dmg, 0.8s, 7 range | +100% dmg to Fast enemies |
| 3B1 | Machine Bow | 8 dmg, 0.15s, 4 range | Extreme fire rate |
| 3B2 | Splinter Shot | 15 dmg, 0.5s, 5 range | Arrows pierce 3 enemies |

**Upgrade Costs**: T2: 150g | T3: 300g

---

### 3.2 Cannon Tower

**Role**: AOE damage, anti-cluster  
**Base Cost**: 150 gold

| Tier | Name | Stats | Special |
|------|------|-------|---------|
| 1 | Cannon | 40 dmg, 2.0s, 4 range, 1.5 AOE | Splash damage |
| 2A | Mortar | 60 dmg, 3.0s, 5 range, 2.5 AOE | Larger blast |
| 2B | Artillery | 45 dmg, 2.5s, 7 range, 1.5 AOE | Extended range |
| 3A1 | Siege Cannon | 150 dmg, 4.0s, 5 range, 3.5 AOE | Can damage Breakers for 2x |
| 3A2 | Cluster Bomb | 30×4 dmg, 3.5s, 5 range | 4 mini-explosions |
| 3B1 | Railgun | 100 dmg, 3.0s, 10 range | Line damage, pierces all |
| 3B2 | Howitzer | 25 dmg/s, 6 range | Rains shells over 3s in area |

**Upgrade Costs**: T2: 200g | T3: 400g

---

### 3.3 Frost Tower

**Role**: Crowd control, slow/freeze  
**Base Cost**: 125 gold

| Tier | Name | Stats | Special |
|------|------|-------|---------|
| 1 | Frost Tower | 30% slow, 3.5 range | AOE slow field |
| 2A | Blizzard | 40% slow, 4.5 range | Larger slow field |
| 2B | Ice Shard | 20 dmg + 25% slow, 1.5s, 4 range | Adds damage |
| 3A1 | Permafrost | 50% slow, 5 range | 10% chance to freeze 2s |
| 3A2 | Frostbite | 40% slow, 4.5 range | Slowed enemies take +30% dmg |
| 3B1 | Cryo Cannon | 45 dmg + 35% slow, 1.2s, 5 range | High damage + slow |
| 3B2 | Shatter | 25 dmg + 25% slow | Frozen enemies explode for 80 AOE dmg |

**Upgrade Costs**: T2: 175g | T3: 350g

---

### 3.4 Lightning Tower

**Role**: Chain damage, anti-swarm  
**Base Cost**: 175 gold

| Tier | Name | Stats | Special |
|------|------|-------|---------|
| 1 | Lightning Tower | 25 dmg, 1.2s, 4 range | Chains to 3 enemies |
| 2A | Tesla Coil | 20 dmg, 1.0s, 5 range | Chains to 5 enemies |
| 2B | Arc Pylon | 15 dps beam, 4.5 range | Continuous damage |
| 3A1 | Storm Spire | 25 dmg, 0.8s, 6 range | Chains to 8, 0.5s stun |
| 3A2 | Overload | 60 dmg, 1.5s, 4 range | Chains to 2, massive dmg |
| 3B1 | Disruptor | 12 dps, 5 range | Disables enemy abilities |
| 3B2 | Capacitor | Special, 5 range | Charges 5s, discharges 200 AOE |

**Upgrade Costs**: T2: 225g | T3: 450g

---

### 3.5 Flame Tower

**Role**: DOT damage, area denial  
**Base Cost**: 150 gold

| Tier | Name | Stats | Special |
|------|------|-------|---------|
| 1 | Flame Tower | 10 dmg + 8 dps burn (3s), cone | Burn DOT |
| 2A | Inferno | 15 dmg + 10 dps burn, larger cone | Wider flames |
| 2B | Focused Flame | 25 dmg + 12 dps burn, single target | Higher damage |
| 3A1 | Hellfire | 15 dmg, ground burns 5s | Creates fire patches |
| 3A2 | Napalm | 12 dmg + 15 dps burn (5s) | DOT stacks 3x |
| 3B1 | Plasma Torch | 40 dmg + 8 dps, ignores 50% armor | Melts armor |
| 3B2 | Dragon Breath | 60 dmg + 10 dps, 6 range | Long range burst |

**Upgrade Costs**: T2: 200g | T3: 400g

---

### 3.6 Support Tower

**Role**: Buffs allies, debuffs enemies  
**Base Cost**: 200 gold

| Tier | Name | Stats | Special |
|------|------|-------|---------|
| 1 | Support Tower | 3 range aura | +15% damage to nearby towers |
| 2A | War Banner | 4 range aura | +20% damage, +10% speed |
| 2B | Tech Relay | 4 range, marks enemies | Marked enemies take +15% dmg |
| 3A1 | Command Post | 5 range aura | +25% dmg, +15% speed, +1 range |
| 3A2 | Rally Point | 4 range aura | +20% dmg, towers regen 2 HP/s |
| 3B1 | Scanner | 5 range | Reveals stealth, +40% crit vs marked |
| 3B2 | EMP Field | 4 range | -30% enemy speed, disables shields |

**Upgrade Costs**: T2: 250g | T3: 500g

---

### 3.7 Wall Block

**Role**: Path manipulation, defense  
**Base Cost**: 25 gold

| Tier | Name | Stats | Special |
|------|------|-------|---------|
| 1 | Wall | 100 HP | Blocks path |
| 2A | Reinforced | 250 HP | +Self repair 5 HP/s out of combat |
| 2B | Reactive | 100 HP | Utility effects |
| 3A1 | Fortress Wall | 500 HP | +Self repair 10 HP/s always |
| 3A2 | Thorned Wall | 300 HP | Reflects 20% melee damage |
| 3B1 | Shock Wall | 150 HP | Stuns attackers 1s (5s cooldown) |
| 3B2 | Tar Wall | 150 HP | 40% slow in 2 tile radius |

**Upgrade Costs**: T2: 40g | T3: 80g

---

## 4. Enemies

### 4.1 Standard Enemies

| Enemy | HP | Speed | Armor | Gold | Special |
|-------|-----|-------|-------|------|---------|
| Grunt | 50 | 1.0 | 0 | 5 | None |
| Runner | 30 | 2.0 | 0 | 8 | Fast movement |
| Tank | 200 | 0.5 | 30% | 20 | Damage reduction |
| Swarm | 10 | 1.5 | 0 | 1 | Spawns in groups of 15-25 |
| Flyer | 40 | 1.2 | 0 | 12 | Ignores pathing/walls |
| Healer | 60 | 0.8 | 0 | 15 | Heals nearby enemies 5 HP/s |
| Shielded | 80 | 0.9 | 0 | 18 | 50 HP shield regenerates |
| Stealth | 45 | 1.3 | 0 | 15 | Invisible until attacked or at Shrine |
| Splitter | 80 | 0.8 | 0 | 12 | Splits into 3 Minis (25 HP) on death |
| Regen | 120 | 0.7 | 0 | 22 | Regenerates 8 HP/s |

### 4.2 Smash Round Enemies

| Enemy | HP | Speed | Armor | Gold | Special |
|-------|-----|-------|-------|------|---------|
| Breaker | 400 | 0.4 | 40% | 50 | Ignores pathing, attacks walls for 50 dmg/hit |
| Siege Golem | 800 | 0.3 | 50% | 100 | Smashes walls in 2 hits, immune to slow |
| Battering Ram | 300 | 0.6 | 20% | 40 | Charges walls, +200% damage on impact |

### 4.3 Boss Enemies

Appear every 10 waves.

| Boss | HP | Speed | Gold | Mechanics |
|------|-----|-------|------|-----------|
| **Swarm Queen** | 1500 | 0.5 | 200 | Spawns 5 Swarmlings every 3s |
| **Phase Phantom** | 1000 | 1.0 | 200 | Teleports every 5s, goes stealth 2s after |
| **Iron Colossus** | 3000 | 0.3 | 250 | 60% armor, immune to CC, slow but devastating |
| **Frost Wyrm** | 1200 | 0.8 | 200 | Freezes towers in range for 3s |
| **Necromancer** | 800 | 0.6 | 200 | Resurrects dead enemies at 50% HP |

---

## 5. Wave System

### 5.1 Wave Structure

Each level consists of 30 waves with escalating difficulty.

| Waves | Composition | Special |
|-------|-------------|---------|
| 1-5 | Grunts only | Tutorial |
| 6-10 | Grunts + Runners | Introduce speed |
| 11-15 | Mixed standard | First Flyers |
| 16-20 | Complex mixes | First Smash (W18) |
| 21-25 | Heavy enemies | Rush + Smash |
| 26-30 | Everything | Boss every 10th |

### 5.2 Special Round Types

**Rush Round** (Waves 8, 14, 20, 26)
- 3x normal enemy count
- Primarily Runners and Swarm
- Reduced spawn interval (0.3s vs 0.8s)
- Tests AOE and chain damage
- Early start bonus is 2x during Rush

**Smash Round** (Waves 18, 24, 28)
- Introduces Breakers and Siege enemies
- Mixed with Tanks for distraction
- Walls WILL be destroyed
- Strategic consideration: Where will breach occur?
- Walls destroyed during Smash do NOT rebuild automatically

### 5.3 Wave Spawning

- Spawn points marked on map edges
- Later waves have multiple spawn points
- Spawn interval: 0.8s base (0.3s during Rush)
- All enemies must be spawned before wave completion

---

## 6. Progression Systems

### 6.1 Level Progression

**Star Rating** (per level)
- ⭐ Complete level
- ⭐⭐ Shrine HP > 50%
- ⭐⭐⭐ Shrine HP = 100% (no damage)

Stars unlock new levels and provide currency.

### 6.2 Meta Progression

**Commander Upgrades** (permanent, unlocked with stars)

| Category | Upgrades |
|----------|----------|
| Economy | Interest unlocked (+5%), Starting gold +50, Sell value +5% |
| Towers | +5% base damage, +5% attack speed, +10% range |
| Walls | +20% HP, Repair cost -25% |
| Shrine | +25 HP, Damage reduction 10% |

### 6.3 Unlockables

| Unlock | Requirement |
|--------|-------------|
| Cannon Tower | Complete Level 3 |
| Frost Tower | Complete Level 5 |
| Lightning Tower | Complete Level 8 |
| Flame Tower | Complete Level 12 |
| Support Tower | Complete Level 16 |
| Tier 3 Upgrades | Complete Level 20 |
| Endless Mode | 3-star Level 30 |

---

## 7. Map Design

### 7.1 Map Elements

- **Spawn Points**: Fixed edges where enemies enter
- **Shrine Placement Zone**: Area where player can place Shrine
- **Obstacles**: Pre-placed rocks/water that cannot be built on
- **Terrain Modifiers**: Some tiles slow enemies or boost towers

### 7.2 Map Types

| Type | Description |
|------|-------------|
| Open Field | Large buildable area, 2 spawn points |
| Narrow Pass | Choke points, limited building space |
| Island | Shrine in center, 4 spawn points |
| Maze Starter | Pre-built partial walls, player completes |
| Dual Path | Two distinct routes to Shrine |

### 7.3 Grid System

- Tile-based grid (maps are 20x30 to 30x40 tiles)
- Towers occupy 2x2 tiles
- Walls occupy 1x1 tile
- Enemies occupy 1x1 space (bosses 2x2)

---

## 8. User Interface

### 8.1 HUD Elements

```
┌─────────────────────────────────────┐
│ Wave: 15/30    Gold: 850    ♥ 100   │
├─────────────────────────────────────┤
│                                     │
│           GAME AREA                 │
│                                     │
│                                     │
├─────────────────────────────────────┤
│ [🏹][💣][❄️][⚡][🔥][📡][🧱] [▶️]  │
└─────────────────────────────────────┘
```

### 8.2 Tower Placement Flow

1. Tap tower icon in build bar
2. Valid tiles highlight green
3. Drag to position
4. Release to place (gold deducted)
5. Tap placed tower to open upgrade menu

### 8.3 Upgrade Interface

```
┌────────────────────────┐
│    Archer Tower Lv2    │
│    Marksman Branch     │
├────────────────────────┤
│  [Sniper]    [Hunter]  │
│   300g         300g    │
│                        │
│  [Sell: 225g]          │
└────────────────────────┘
```

### 8.4 Mobile Controls

- **Tap**: Select tower/tile
- **Drag**: Pan camera
- **Pinch**: Zoom in/out
- **Double-tap**: Center on Shrine
- **Long press**: Tower info popup

---

## 9. Audio Design

### 9.1 Sound Categories

| Category | Examples |
|----------|----------|
| UI | Button clicks, gold collect, upgrade complete |
| Towers | Unique attack sounds per tower type |
| Enemies | Footsteps, death cries, boss roars |
| Ambient | Wind, battle atmosphere |
| Music | Dynamic layers based on intensity |

### 9.2 Music System

- Calm music during build phase
- Intensity increases with enemy count
- Boss music override
- Victory/defeat stingers

---

## 10. Visual Style

### 10.1 Art Direction

- Clean, readable top-down view
- Stylized/slightly cartoony (not realistic)
- High contrast for enemy visibility
- Clear visual hierarchy: Shrine > Towers > Walls > Enemies
- Distinct color coding per tower type

### 10.2 Visual Feedback

| Event | Visual |
|-------|--------|
| Enemy damage | Flash white, damage number popup |
| Tower attack | Projectile/effect animation |
| Slow effect | Blue tint on enemy |
| Burn effect | Orange particles |
| Stun | Stars above enemy |
| Shield | Blue bubble overlay |
| Low Shrine HP | Screen edge red pulse |

---

## 11. Technical Specifications

### 11.1 Godot 4.6 Architecture

```
res://
├── scenes/
│   ├── main/
│   │   ├── game.tscn          # Main game scene
│   │   ├── main_menu.tscn     # Menu
│   │   └── level_select.tscn  # Level selection
│   ├── towers/
│   │   ├── base_tower.tscn    # Tower base class
│   │   └── [tower_type].tscn  # Each tower type
│   ├── enemies/
│   │   ├── base_enemy.tscn    # Enemy base class
│   │   └── [enemy_type].tscn  # Each enemy type
│   ├── ui/
│   │   ├── hud.tscn           # In-game HUD
│   │   └── tower_panel.tscn   # Build/upgrade panel
│   └── effects/
│       └── [effect].tscn      # Visual effects
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd    # Global game state
│   │   ├── wave_manager.gd    # Wave spawning
│   │   └── economy.gd         # Gold management
│   ├── towers/
│   │   ├── tower_base.gd      # Tower logic base
│   │   └── [tower].gd         # Specific tower logic
│   ├── enemies/
│   │   ├── enemy_base.gd      # Enemy logic base
│   │   └── [enemy].gd         # Specific enemy logic
│   └── systems/
│       ├── pathfinding.gd     # A* pathfinding
│       └── targeting.gd       # Tower targeting
├── resources/
│   ├── tower_data/            # Tower stats as resources
│   ├── enemy_data/            # Enemy stats as resources
│   └── wave_data/             # Wave composition
└── assets/
    ├── sprites/
    ├── audio/
    └── fonts/
```

### 11.2 Key Systems

**Pathfinding**
- Use Godot's built-in NavigationServer2D
- AStarGrid2D for tile-based pathfinding
- Recalculate paths when walls placed/destroyed
- Cache paths per spawn point

**Object Pooling**
- Pool projectiles, enemies, and effects
- Essential for mobile performance
- Pre-spawn pools at level load

**Signal-Based Architecture**
```gdscript
# Example signals
signal enemy_killed(enemy, gold_value)
signal wave_completed(wave_number)
signal tower_upgraded(tower, new_tier)
signal shrine_damaged(amount, current_hp)
```

### 11.3 Performance Targets

| Metric | Target |
|--------|--------|
| Frame Rate | 60 FPS |
| Max Enemies | 200 simultaneous |
| Max Towers | 50 placed |
| Load Time | < 3 seconds |
| Memory | < 500 MB |

### 11.4 Mobile Export Settings

**Android**
- Min SDK: 24 (Android 7.0)
- Target SDK: 34
- Vulkan with GLES3 fallback
- ARM64 + ARMv7

**iOS**
- Min iOS: 14.0
- Metal renderer
- ARM64 only

---

## 12. Monetization (Optional)

### 12.1 Model Options

**Premium ($2.99-$4.99)**
- One-time purchase
- All content included
- No ads

**Free-to-Play (if chosen)**
- Energy system for levels
- Optional ad watching for bonuses
- IAP for cosmetics only
- NO pay-to-win mechanics

### 12.2 Cosmetic Options

- Tower skins
- Shrine designs
- Projectile effects
- Enemy death effects

---

## 13. Future Considerations

### 13.1 Co-op Mode (Future Update)

- 2-player shared map
- Split economy or shared
- Larger maps
- More spawn points

### 13.2 PvP Mode (Future Update)

- Asynchronous or real-time
- Send enemies to opponent
- Defend your own Shrine
- Ranked matchmaking

### 13.3 Content Updates

- New tower types
- New enemy types
- New maps
- Seasonal events
- Challenge modes

---

## 14. Development Milestones

### Phase 1: Prototype (4 weeks)
- [ ] Basic grid system
- [ ] Shrine placement
- [ ] Wall placement
- [ ] Pathfinding
- [ ] 1 tower type (Archer)
- [ ] 1 enemy type (Grunt)
- [ ] Basic wave spawning

### Phase 2: Core Gameplay (6 weeks)
- [ ] All 6 tower types (base only)
- [ ] All standard enemies
- [ ] Economy system
- [ ] Full upgrade trees
- [ ] 5 playable levels

### Phase 3: Polish (4 weeks)
- [ ] All special rounds
- [ ] Boss enemies
- [ ] Visual effects
- [ ] Audio implementation
- [ ] UI polish
- [ ] Tutorial

### Phase 4: Content (4 weeks)
- [ ] 30 levels
- [ ] Meta progression
- [ ] All unlockables
- [ ] Endless mode
- [ ] Balancing pass

### Phase 5: Release (2 weeks)
- [ ] Mobile optimization
- [ ] Store assets
- [ ] Beta testing
- [ ] Bug fixes
- [ ] Launch

---

## Appendix A: Balance Spreadsheet Reference

### Tower DPS Comparison (Base Level)

| Tower | Single Target DPS | AOE DPS | Cost Efficiency |
|-------|-------------------|---------|-----------------|
| Archer | 18.75 | 18.75 | 0.19 DPS/gold |
| Cannon | 20 | 60* | 0.13-0.40 DPS/gold |
| Frost | 0 (utility) | - | N/A |
| Lightning | 20.8 | 62.5* | 0.12-0.36 DPS/gold |
| Flame | 34 (with DOT) | 102* | 0.23-0.68 DPS/gold |
| Support | 0 (+15% multiplier) | - | Force multiplier |

*AOE DPS assumes 3 enemies hit

### Enemy HP Scaling by Wave

```
Wave 1-10:  Base HP
Wave 11-20: Base HP × 1.5
Wave 21-30: Base HP × 2.5
Boss HP:    Base × Wave/10
```

---

## Appendix B: Godot-Specific Implementation Notes

### Pathfinding Setup
```gdscript
# Using AStarGrid2D for tile-based pathfinding
var astar = AStarGrid2D.new()
astar.region = Rect2i(0, 0, map_width, map_height)
astar.cell_size = Vector2(tile_size, tile_size)
astar.update()

# Mark walls as solid
func set_wall(pos: Vector2i):
    astar.set_point_solid(pos, true)
    recalculate_all_paths()
```

### Tower Targeting Priority
```gdscript
enum TargetPriority { FIRST, LAST, STRONGEST, WEAKEST, CLOSEST }

func get_target(enemies: Array, priority: TargetPriority) -> Enemy:
    match priority:
        FIRST: return enemies.reduce(func(a, b): return a if a.progress > b.progress else b)
        CLOSEST: return enemies.reduce(func(a, b): return a if a.position.distance_to(position) < b.position.distance_to(position) else b)
        # etc.
```

### Signal-Based Wave System
```gdscript
# wave_manager.gd
signal wave_started(wave_number)
signal enemy_spawned(enemy)
signal wave_cleared
signal all_waves_complete

func start_wave(wave_num: int):
    wave_started.emit(wave_num)
    var wave_data = load_wave_data(wave_num)
    for spawn in wave_data.spawns:
        await get_tree().create_timer(spawn.delay).timeout
        spawn_enemy(spawn.type, spawn.point)
```

---

*Document Version 1.0 - January 2026*
*Created for development with Godot 4.6*
