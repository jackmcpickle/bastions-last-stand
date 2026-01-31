# Bastion's Last Stand
## Art Direction & Faction Design Document v1.0

---

## 1. Visual Style Overview

### 1.1 3D Pixel Art Aesthetic

The game uses **3D pixel art rendering** - 3D models rendered at low resolution with specific post-processing to achieve a handcrafted pixel art look while maintaining the benefits of 3D (dynamic lighting, camera angles, depth).

**Target Resolution**: 384×216 internal → upscaled to device resolution
**Aspect Ratio**: 16:9
**Camera**: Orthographic, top-down at 45-60° angle

### 1.2 Core Visual Pillars

| Pillar | Description |
|--------|-------------|
| **Readability** | Enemies, towers, and paths must be instantly distinguishable |
| **Charm** | Chunky pixels, bold outlines, satisfying animations |
| **Atmosphere** | Dynamic lighting sells the medieval fantasy mood |
| **Faction Identity** | Light and Dark themes are visually distinct at a glance |

### 1.3 Medieval Fantasy Theme

- Stone castles, wooden palisades, thatched roofs
- Knights, archers, mages, siege weapons
- Enchanted forests, rolling hills, ancient ruins
- Magic effects: glowing runes, ethereal particles, elemental bursts

---

## 2. 3D Pixel Art Technical Implementation

Based on techniques from David Holland and t3ssel8r, adapted for Godot 4.6.

### 2.1 Render Pipeline Overview

```
┌─────────────────────────────────────────────────────────┐
│  1. Render 3D scene at LOW RESOLUTION (384×216)         │
│     - Orthographic camera                               │
│     - Toon shading on all materials                     │
│     - Depth + Normal buffers captured                   │
├─────────────────────────────────────────────────────────┤
│  2. Post-Processing (at low res)                        │
│     - Outline shader (depth + normal edge detection)    │
│     - Edge highlights on convex edges                   │
│     - Color quantization (optional)                     │
├─────────────────────────────────────────────────────────┤
│  3. Upscale to device resolution                        │
│     - Nearest-neighbor sampling (crisp pixels)          │
│     - Sub-pixel camera offset for smooth movement       │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Camera System

**Pixel-Perfect Camera Snapping**

The camera must snap to texel-aligned positions to prevent "pixel creep" (swimming/jittering pixels during movement).

```gdscript
# camera_3d_pixel_perfect.gd
extends Camera3D

@export var pixels_per_unit: float = 16.0
var snap_offset: Vector2 = Vector2.ZERO

func _process(_delta):
    # Snap camera to pixel grid
    var texel_size = 1.0 / pixels_per_unit
    var snapped_pos = Vector3(
        snappedf(global_position.x, texel_size),
        global_position.y,
        snappedf(global_position.z, texel_size)
    )

    # Calculate sub-pixel offset for smooth scrolling
    snap_offset = Vector2(
        (global_position.x - snapped_pos.x) * pixels_per_unit,
        (global_position.z - snapped_pos.z) * pixels_per_unit
    )

    global_position = snapped_pos

# Apply snap_offset in post-processing to shift final image
```

### 2.3 Outline Shader

```glsl
// outline_post_process.gdshader
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D normal_texture : hint_normal_roughness_texture;

uniform vec4 outline_color : source_color = vec4(0.1, 0.08, 0.12, 1.0);
uniform float depth_threshold = 0.001;
uniform float normal_threshold = 0.5;

void fragment() {
    vec2 pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));

    // Sample depth in cardinal directions
    float depth_c = texture(depth_texture, UV).r;
    float depth_u = texture(depth_texture, UV + vec2(0, -pixel_size.y)).r;
    float depth_d = texture(depth_texture, UV + vec2(0, pixel_size.y)).r;
    float depth_l = texture(depth_texture, UV + vec2(-pixel_size.x, 0)).r;
    float depth_r = texture(depth_texture, UV + vec2(pixel_size.x, 0)).r;

    // Depth edge detection
    float depth_diff = abs(depth_u - depth_c) + abs(depth_d - depth_c)
                     + abs(depth_l - depth_c) + abs(depth_r - depth_c);
    float depth_edge = step(depth_threshold, depth_diff);

    // Normal edge detection
    vec3 normal_c = texture(normal_texture, UV).rgb * 2.0 - 1.0;
    vec3 normal_u = texture(normal_texture, UV + vec2(0, -pixel_size.y)).rgb * 2.0 - 1.0;
    vec3 normal_d = texture(normal_texture, UV + vec2(0, pixel_size.y)).rgb * 2.0 - 1.0;
    vec3 normal_l = texture(normal_texture, UV + vec2(-pixel_size.x, 0)).rgb * 2.0 - 1.0;
    vec3 normal_r = texture(normal_texture, UV + vec2(pixel_size.x, 0)).rgb * 2.0 - 1.0;

    float normal_diff = (1.0 - dot(normal_c, normal_u)) + (1.0 - dot(normal_c, normal_d))
                      + (1.0 - dot(normal_c, normal_l)) + (1.0 - dot(normal_c, normal_r));
    float normal_edge = step(normal_threshold, normal_diff);

    // Combine edges
    float edge = max(depth_edge, normal_edge);

    // Output
    vec4 scene_color = texture(screen_texture, UV);
    COLOR = mix(scene_color, outline_color, edge);
}
```

### 2.4 Toon Shader for Models

```glsl
// toon_material.gdshader
shader_type spatial;
render_mode ambient_light_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color;
uniform float shadow_threshold = 0.5;
uniform float shadow_softness = 0.02;
uniform vec4 shadow_color : source_color = vec4(0.2, 0.15, 0.25, 1.0);

void fragment() {
    ALBEDO = albedo.rgb * texture(albedo_texture, UV).rgb;
}

void light() {
    // Calculate light intensity
    float NdotL = dot(NORMAL, LIGHT);

    // Sharp toon shading with slight softness
    float light_intensity = smoothstep(
        shadow_threshold - shadow_softness,
        shadow_threshold + shadow_softness,
        NdotL
    );

    // Apply shadow color in dark areas
    vec3 shaded_color = mix(shadow_color.rgb * ALBEDO, ALBEDO, light_intensity);

    DIFFUSE_LIGHT += shaded_color * LIGHT_COLOR * ATTENUATION;
}
```

### 2.5 Low-Poly Model Guidelines

| Element | Poly Budget | Notes |
|---------|-------------|-------|
| Tower (base) | 50-100 tris | Simple geometric shapes |
| Tower (upgraded) | 100-200 tris | Added detail for progression feel |
| Enemy (standard) | 30-80 tris | Silhouette must be readable |
| Enemy (boss) | 150-300 tris | More detail justified |
| Wall block | 20-40 tris | Very simple |
| Shrine | 200-400 tris | Centerpiece, more detail |
| Props | 10-50 tris | Rocks, trees, decorations |

**Modeling Rules**:
- Hard edges preferred over smoothing (shows better in outlines)
- Avoid very thin geometry (disappears at low res)
- Exaggerate proportions for readability
- Keep UV islands simple for clean texturing

### 2.6 Color Palette Approach

Use **limited, curated palettes** per faction to maintain cohesion.

**Palette Size**: 16-32 colors per faction (including shades)

```
Light Faction Base Palette:
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ #F8 │ #E8 │ #C8 │ #90 │ #60 │ #40 │ #28 │ #18 │  Neutrals
│ F8F8│ E0D8│ B8A8│ 8078│ 5048│ 3830│ 2018│ 1010│
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ #FF │ #E8 │ #C0 │ #80 │     │     │     │     │  Gold/Holy
│ F0A0│ D080│ A060│ 6840│     │     │     │     │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ #80 │ #60 │ #40 │ #30 │     │     │     │     │  Blue/Ice
│ C8FF│ A0E0│ 80C0│ 6090│     │     │     │     │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘

Dark Faction Base Palette:
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ #D8 │ #A8 │ #78 │ #50 │ #38 │ #28 │ #18 │ #10 │  Neutrals
│ D0D0│ 9898│ 6868│ 4040│ 2828│ 1818│ 1010│ 0808│
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ #FF │ #E0 │ #C0 │ #80 │     │     │     │     │  Fire/Lava
│ 4020│ 3010│ 2000│ 1000│     │     │     │     │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ #80 │ #60 │ #40 │ #30 │     │     │     │     │  Purple/Void
│ 40A0│ 3080│ 2060│ 1840│     │     │     │     │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ #40 │ #30 │ #20 │ #18 │     │     │     │     │  Poison/Acid
│ FF40│ C030│ 9020│ 6818│     │     │     │     │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

---

## 3. Faction System

### 3.1 Overview

Players choose their faction at the start of a campaign. This affects:
- Tower visual appearance (models, textures, effects)
- Projectile and ability visuals
- Shrine design
- Wall appearance
- UI theme colors

**Gameplay mechanics remain identical** - this is purely cosmetic.

### 3.2 The Radiant Order (Light Faction)

**Theme**: Holy knights, divine magic, righteous defense
**Color Scheme**: Gold, white, silver, sky blue
**Architecture**: White stone, golden trim, blue banners, crystalline elements
**Magic Style**: Glowing light, holy symbols, cleansing fire, protective barriers

#### Tower Reskins

| Base Tower | Radiant Name | Visual Description |
|------------|--------------|---------------------|
| Archer | **Lightbow Spire** | Elegant white stone tower, golden bow motif, archers in silver armor |
| Cannon | **Divine Ballista** | Ornate siege weapon with holy symbols, fires golden bolts |
| Frost | **Crystal Sanctum** | Shimmering ice-blue crystals, protective holy magic that slows |
| Lightning | **Judgment Pillar** | Tall golden obelisk, calls down holy lightning |
| Flame | **Radiant Pyre** | Sacred brazier with cleansing white-gold flames |
| Support | **Blessed Altar** | Floating holy book/relic, radiates golden aura |
| Wall | **Sanctified Bulwark** | White stone blocks with golden runes |

#### Upgrade Visual Progression

**Lightbow Spire (Archer)**
```
Tier 1: Simple white stone tower, single archer
   │
   ├─ Marksman → Tier 2A: Taller spire, scope/lens mounted
   │      ├─ Sniper → Tier 3A1: Massive crystalline telescope, glowing sight
   │      └─ Hunter → Tier 3A2: Beast motifs, tracking runes on arrows
   │
   └─ Rapid Fire → Tier 2B: Multiple bow slots, mechanical elements
          ├─ Machine Bow → Tier 3B1: Spinning golden mechanism, arrow storm
          └─ Splinter Shot → Tier 3B2: Split-tip crystalline arrows
```

**Judgment Pillar (Lightning)**
```
Tier 1: Golden obelisk with single crystal cap
   │
   ├─ Tesla Coil → Tier 2A: Ring of floating crystals
   │      ├─ Storm Spire → Tier 3A1: Massive crystal crown, constant arcs
   │      └─ Overload → Tier 3A2: Single huge crystal, charges visibly
   │
   └─ Arc Pylon → Tier 2B: Beam-focusing lens array
          ├─ Disruptor → Tier 3B1: Holy symbol projects, silencing aura
          └─ Capacitor → Tier 3B2: Pulsing core, dramatic charge/release
```

#### Projectiles & Effects

| Tower | Projectile/Effect |
|-------|-------------------|
| Archer | Golden arrow with light trail |
| Cannon | Golden bolt with holy explosion (white-gold burst) |
| Frost | Crystalline shards, blue-white frost aura |
| Lightning | White-gold lightning bolts, holy symbols flash |
| Flame | White-gold cleansing fire, purifying sparks |
| Support | Golden light rays, floating holy symbols |

#### Shrine Design

**The Lightwell**
- Elegant white marble fountain
- Floating golden orb at center
- Radiating light beams
- Angel wing motifs on base
- Damage state: Cracks appear, light dims, wings chip

---

### 3.3 The Shadow Covenant (Dark Faction)

**Theme**: Dark sorcerers, forbidden magic, corrupted power
**Color Scheme**: Purple, black, dark red, sickly green
**Architecture**: Dark stone, bone/skull motifs, twisted metal, glowing runes
**Magic Style**: Dark energy, fire and brimstone, poison clouds, void portals

#### Tower Reskins

| Base Tower | Shadow Name | Visual Description |
|------------|-------------|---------------------|
| Archer | **Hex Crossbow** | Dark iron tower, skull decorations, fires cursed bolts |
| Cannon | **Doom Mortar** | Jagged metal and bone, launches explosive skulls |
| Frost | **Soul Cage** | Spectral prison that drains speed, ghostly chains |
| Lightning | **Void Obelisk** | Black stone pillar, purple void lightning |
| Flame | **Hellfire Spout** | Demonic brazier, dark red and orange flames |
| Support | **Dark Altar** | Floating grimoire, skull totems, purple aura |
| Wall | **Blighted Barrier** | Black stone with purple veins, skull spikes |

#### Upgrade Visual Progression

**Hex Crossbow (Archer)**
```
Tier 1: Dark iron tower, hooded cultist with crossbow
   │
   ├─ Marksman → Tier 2A: Larger crossbow, glowing purple scope
   │      ├─ Sniper → Tier 3A1: Massive soul-seeking bolt launcher
   │      └─ Hunter → Tier 3A2: Beast skull mount, tracking hexes
   │
   └─ Rapid Fire → Tier 2B: Multiple rotating crossbows
          ├─ Machine Bow → Tier 3B1: Mechanical nightmare, bolt storm
          └─ Splinter Shot → Tier 3B2: Bolts split into shadow shards
```

**Void Obelisk (Lightning)**
```
Tier 1: Black stone pillar, single void crack
   │
   ├─ Tesla Coil → Tier 2A: Multiple void rifts orbiting
   │      ├─ Storm Spire → Tier 3A1: Full void portal crown, chaos arcs
   │      └─ Overload → Tier 3A2: Massive void eye, devastating pulse
   │
   └─ Arc Pylon → Tier 2B: Focused dark beam lens
          ├─ Disruptor → Tier 3B1: Silencing runes, draining aura
          └─ Capacitor → Tier 3B2: Void heart charges, implosion release
```

#### Projectiles & Effects

| Tower | Projectile/Effect |
|-------|-------------------|
| Archer | Purple-black bolt with shadow trail, curse particles |
| Cannon | Flaming skull projectile, dark explosion with bone shrapnel |
| Frost | Ghostly chains, spectral fog, souls drain speed |
| Lightning | Purple void lightning, dark rifts flash |
| Flame | Dark red/orange hellfire, ember particles, smoke |
| Support | Purple energy rays, floating skulls, dark runes |

#### Shrine Design

**The Soul Crucible**
- Dark iron cauldron/vessel
- Swirling purple soul energy inside
- Skull pedestals around base
- Chains and dark runes
- Damage state: Cracks leak soul energy, chains break, flames gutter

---

## 4. Shared Elements

### 4.1 Enemies (Universal Design)

Enemies are NOT faction-specific - they're the invading force both factions defend against.

**Enemy Theme**: Corrupted creatures, twisted beasts, elemental horrors

| Enemy | Visual Description |
|-------|---------------------|
| Grunt | Goblin-like creature, tattered armor, crude weapon |
| Runner | Lean wolf-like beast, fast and feral |
| Tank | Armored ogre/troll, heavy plating, slow lumber |
| Swarm | Tiny imps/rats, flood of small bodies |
| Flyer | Bat-winged demon, gargoyle-like |
| Healer | Floating eye/wisp with healing tendrils |
| Shielded | Knight with magical barrier, bubble visible |
| Stealth | Shadow creature, semi-transparent, red eyes |
| Splitter | Slime/blob creature, visibly unstable |
| Regen | Mushroom creature with regenerating caps |

**Breakers & Bosses**
- Larger, more detailed models
- Unique silhouettes for instant recognition
- Boss health bars with portrait

### 4.2 Map Terrain (Universal)

Maps are neutral ground - both factions can be placed on any map.

**Terrain Types**:
- Grass/dirt paths
- Stone/cobblestone
- Water (impassable)
- Rocks (impassable)
- Trees (decoration, maybe impassable)
- Ruins (pre-placed walls, decoration)

### 4.3 UI Theme Variants

| Element | Light Faction | Dark Faction |
|---------|---------------|--------------|
| Primary BG | Cream/off-white | Dark gray/charcoal |
| Secondary BG | Light gold | Dark purple |
| Accent | Bright gold | Deep red |
| Text | Dark brown | Off-white |
| Buttons | Gold with white text | Purple with gold text |
| Icons | Gold outlines | Purple outlines |
| Health bar | Gold fill | Red fill |

---

## 5. Animation Guidelines

### 5.1 Frame Counts (at 60 FPS)

| Animation | Frames | Notes |
|-----------|--------|-------|
| Tower idle | 4-8 | Subtle breathing/glow |
| Tower attack | 6-12 | Snappy, impactful |
| Enemy walk | 6-8 | Loop, matches speed |
| Enemy death | 8-12 | Satisfying pop |
| Projectile travel | Continuous | Particle trail |
| Impact effect | 6-10 | Burst, fade |

### 5.2 Animation Principles

- **Snappy attacks**: Anticipation frame → fast action → slight settle
- **Readable silhouettes**: Key poses must be distinct even at low res
- **Satisfying feedback**: Enemies flash white on hit, pop on death
- **Looping subtlety**: Idle animations should be nearly invisible but add life

### 5.3 Particle Effects

Use **screen-space particles** for certain effects (rain, ambient dust) and **world-space billboards** for gameplay effects (projectiles, impacts).

| Effect | Type | Faction Variants |
|--------|------|------------------|
| Projectile trail | World billboard | Gold sparkles / Purple smoke |
| Impact burst | World billboard | Light flash / Dark explosion |
| AOE indicator | Ground decal | Gold circle / Purple runes |
| Slow effect | Enemy overlay | Blue tint / Green tint (poison theme) |
| Buff aura | World billboard | Golden rays / Purple energy |

---

## 6. Technical Art Checklist

### 6.1 Godot 4.6 Setup

```
Project Settings:
├── Display
│   ├── Window Size: 384 × 216 (test) or device native
│   ├── Stretch Mode: canvas_items
│   └── Stretch Aspect: keep
├── Rendering
│   ├── Textures → Default Texture Filter: Nearest
│   ├── Anti-Aliasing → MSAA: Disabled
│   └── Anti-Aliasing → TAA: Disabled
└── Quality
    └── Adjust for mobile performance
```

### 6.2 Asset Checklist Per Tower

- [ ] Base model (low-poly, hard edges)
- [ ] Tier 2A model variant
- [ ] Tier 2B model variant
- [ ] Tier 3A1 model variant
- [ ] Tier 3A2 model variant
- [ ] Tier 3B1 model variant
- [ ] Tier 3B2 model variant
- [ ] Texture atlas (palette-based)
- [ ] Idle animation
- [ ] Attack animation
- [ ] Projectile model/sprite
- [ ] Impact effect
- [ ] Placement preview ghost
- [ ] UI icon (each tier)

**× 2 for both factions = 14 model variants per tower type**

### 6.3 Faction Asset Matrix

| Asset | Light | Dark | Shared |
|-------|-------|------|--------|
| 7 Tower types × 7 tiers | 49 models | 49 models | - |
| Shrine | 1 model | 1 model | - |
| Walls × 4 tiers | 4 models | 4 models | - |
| UI theme | 1 set | 1 set | - |
| Enemies | - | - | ~15 models |
| Maps/terrain | - | - | ~10 sets |
| Projectiles | 7 types | 7 types | - |
| Effects | ~20 | ~20 | ~10 |

**Total unique models**: ~100 Light + ~100 Dark + ~30 Shared = **~230 models**

---

## 7. Reference & Inspiration

### 7.1 3D Pixel Art References

- **t3ssel8r** (YouTube) - Original 3D pixel art techniques
- **David Holland** - Godot-specific implementation
- **Octopath Traveler** - 2D-3D hybrid aesthetic
- **Minecraft** - Voxel pixel art (different but related)

### 7.2 Tower Defense Visual References

- **Kingdom Rush** series - Readable, charming, clear upgrade progression
- **Bloons TD 6** - Excellent tower variety and upgrade visuals
- **Dungeon Defenders** - 3D tower defense with strong themes

### 7.3 Medieval Fantasy References

- **Dark Souls** (dark faction mood)
- **Diablo** series (both factions)
- **Warcraft 3** (readable RTS units)
- **Heroes of Might and Magic** (faction theming)

---

## 8. Production Pipeline

### 8.1 Recommended Workflow

```
1. Blockout (Blender)
   └── Simple shapes, correct scale, test in engine

2. Low-poly Model (Blender)
   └── Final geo, hard edges, clean topology

3. UV Mapping (Blender)
   └── Efficient islands, palette-based texturing

4. Texturing (Aseprite or similar)
   └── Pixel art texture on atlas, limited palette

5. Rigging/Animation (Blender)
   └── Simple bones, keyframe animation

6. Export to Godot
   └── GLTF format, test with shaders

7. VFX (Godot)
   └── Particle systems, shader effects

8. Polish
   └── Iterate based on in-game appearance
```

### 8.2 Tools

| Task | Tool |
|------|------|
| 3D Modeling | Blender (free) |
| Pixel Textures | Aseprite, Pixelorama, GIMP |
| Animated Sprites | Aseprite, Pixel Composer |
| Particle Effects | Godot built-in, Pixel Composer for sprites |
| UI Design | Figma (mockups), Godot (implementation) |

---

## Appendix: Quick Faction Reference Card

```
╔═══════════════════════════════════════════════════════════════╗
║  THE RADIANT ORDER              THE SHADOW COVENANT           ║
╠═══════════════════════════════════════════════════════════════╣
║  Colors: Gold, White, Blue      Colors: Purple, Black, Red    ║
║  Stone: White marble            Stone: Dark basalt            ║
║  Metal: Gold, Silver            Metal: Dark iron, Bronze      ║
║  Magic: Holy light, Crystals    Magic: Void, Fire, Poison     ║
╠═══════════════════════════════════════════════════════════════╣
║  Archer → Lightbow Spire        Archer → Hex Crossbow         ║
║  Cannon → Divine Ballista       Cannon → Doom Mortar          ║
║  Frost  → Crystal Sanctum       Frost  → Soul Cage            ║
║  Lightning → Judgment Pillar    Lightning → Void Obelisk      ║
║  Flame  → Radiant Pyre          Flame  → Hellfire Spout       ║
║  Support → Blessed Altar        Support → Dark Altar          ║
║  Wall   → Sanctified Bulwark    Wall   → Blighted Barrier     ║
╠═══════════════════════════════════════════════════════════════╣
║  Shrine: The Lightwell          Shrine: The Soul Crucible     ║
║  (Marble fountain, golden orb)  (Iron cauldron, soul energy)  ║
╚═══════════════════════════════════════════════════════════════╝
```

---

*Art Direction Document v1.0 - January 2026*
*For use with Bastion's Last Stand GDD*
