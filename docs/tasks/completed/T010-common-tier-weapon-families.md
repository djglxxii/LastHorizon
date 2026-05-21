# T010 — Common-Tier Weapon Families

| Field | Value |
|---|---|
| ID | T010 |
| State | completed |
| Phase | M4 — Weapon pickups |
| Depends on | T009 |
| Plan reference | `docs/PLAN.md` — M4 |

## Goal

Replace the single generic `debug_plasma` drop with a **5-family common-tier weapon pool**: the existing `debug_plasma` kept as a baseline reference plus **4 new common-tier families with visibly distinct handling** — Wide Spread, Piercing Lance, Heavy Slug, Rapid Stream. Carriers roll a family at spawn time and **telegraph that family via hull tint**, so the player can read the incoming family from across the playfield and decide whether to engage. This task delivers the families themselves and the per-family carrier/chip readability; the same-family refill vs different-family swap-at-full semantics remain T011's slice.

## Scope

- **In scope:**
  - **`TypedWeaponFamily` resource shape additions.** Extend `src/weapons/typed_weapon_family.gd` with:
    - `@export var display_name: String` — short readable name for HUD/event-log surfaces (e.g., `"Wide Spread"`, `"Piercing Lance"`).
    - `@export var tint_color: Color` — single load-bearing color applied to the carrier hull modulate, the chip sprite modulate, and the projectile sprite modulate so the family identity is consistent at every readability surface. Set distinct, saturated, perceptually different hues across the 5 families (see Implementation notes for the suggested palette).
    - `@export var archetype: int` (with a `WeaponArchetype` enum: `SINGLE`, `SPREAD`, `PIERCE`) — selects the per-shot firing pattern. `SINGLE` is the default (debug_plasma, Heavy, Rapid). `SPREAD` fires `spread_count` projectiles in a fan. `PIERCE` fires one projectile that does not despawn on enemy hit.
    - `@export var spread_count: int` — used only by `SPREAD`; default `1`. Each spread projectile costs the family's single `firing_cost` (one trigger = one fan = one cost), so spread does not multiply the burn rate.
    - `@export var spread_angle_degrees: float` — total fan angle in degrees, used only by `SPREAD`. Projectile angles are evenly distributed across `[-spread_angle/2, +spread_angle/2]` around straight up.
    - `@export var pierce: bool` — used only by `PIERCE`; when `true`, projectiles do not despawn on first enemy hit and may damage successive enemies until they leave the playfield.
    - Keep the existing `family_id`, `max_energy`, `firing_cost`, `fire_interval`, `projectile_speed`, `projectile_damage`, `projectile_sprite` fields and `normalized_*` helpers unchanged. Old `.tres` files with the new fields unset will default safely (`SINGLE` archetype, `spread_count = 1`, `pierce = false`).
  - **Four new common-tier weapon-family resources under `data/weapons/`.**
    - `data/weapons/common_wide_spread.tres` — `family_id = "common_wide_spread"`, `display_name = "Wide Spread"`, `archetype = SPREAD`, `spread_count = 3`, `spread_angle_degrees = 24.0`. Tuning starting point: `max_energy = 100.0`, `firing_cost = 2.0`, `fire_interval = 0.18`, `projectile_speed = 640.0`, `projectile_damage = 1.0`. **Identity:** clears baseline density; thin on single targets. Burn rate slightly higher than debug_plasma per shot (one trigger pays for 3 projectiles), so meter cycles faster.
    - `data/weapons/common_piercing_lance.tres` — `family_id = "common_piercing_lance"`, `display_name = "Piercing Lance"`, `archetype = PIERCE`, `pierce = true`. Tuning starting point: `max_energy = 100.0`, `firing_cost = 2.0`, `fire_interval = 0.20`, `projectile_speed = 980.0`, `projectile_damage = 2.0`. **Identity:** a fast straight bolt that passes through enemies in a line. Strong against vertical columns; useless against horizontal spread.
    - `data/weapons/common_heavy_slug.tres` — `family_id = "common_heavy_slug"`, `display_name = "Heavy Slug"`, `archetype = SINGLE`. Tuning starting point: `max_energy = 100.0`, `firing_cost = 6.0`, `fire_interval = 0.45`, `projectile_speed = 560.0`, `projectile_damage = 8.0`. **Identity:** slow, expensive per shot, hits like a truck. Strong against elites in M6; punishing for trash clear.
    - `data/weapons/common_rapid_stream.tres` — `family_id = "common_rapid_stream"`, `display_name = "Rapid Stream"`, `archetype = SINGLE`. Tuning starting point: `max_energy = 100.0`, `firing_cost = 0.7`, `fire_interval = 0.05`, `projectile_speed = 880.0`, `projectile_damage = 0.6`. **Identity:** a thirsty stream of low-damage bullets; meter visibly drains while held. Strong rhythm contrast against Heavy Slug.
    - All four families ship with **distinct placeholder projectile sprites** at the same quality bar as `typed-plasma-bolt.png`: see Implementation notes for suggested silhouette shapes. Reuse `typed-plasma-bolt.png` as a final fallback only if authoring per-family projectile sprites blows the slice — document the choice in the Progress log.
    - `debug_plasma.tres` stays in the pool unchanged as a 5th member. Its `tint_color` is set to a distinct hue from the four new families. No tuning changes to debug_plasma in this task.
  - **`CarrierSpawner.weapon_pool: Array[TypedWeaponFamily]`.** New export listing the 5 families eligible to drop. Selection is **uniform random** across the array entries (no per-family weight axis — that's deferred). The spawner draws once per spawn and passes the chosen family to the carrier via `set_family(family)`.
  - **`WeaponChipCarrier.family: TypedWeaponFamily` + `set_family(family)`.** New field on `src/enemies/weapon_chip_carrier.gd`. When set, the carrier's hull `Sprite2D` is `modulate`-tinted to `family.tint_color` so the silhouette telegraphs the family from across the playfield. The tint applies on top of the existing placeholder hull silhouette; no per-family hull sprite authoring this slice. On kill, the carrier passes its `family` to the spawned chip via `chip.set_family(family)`.
  - **`WeaponChip.family: TypedWeaponFamily` + `set_family(family)`.** New field on `src/pickups/weapon_chip.gd`. The chip's `Sprite2D` is `modulate`-tinted to `family.tint_color` so the catchable item is colored to match the carrier that dropped it. On collect, the chip calls `slot.apply_chip_pickup(family)` (signature change — see below).
  - **`TypedWeaponSlot.apply_chip_pickup(family)` signature change.** Replace the no-arg form with `apply_chip_pickup(family: TypedWeaponFamily)`. T010 behavior:
    - If `active_weapon == null`, `equip(family)` and emit `chip_pickup_applied(family.family_id, true)`.
    - If `active_weapon != null`, **refill `current_energy` to `max_energy` regardless of family match**, and emit `chip_pickup_applied(active_weapon.family.family_id, false)`. The "different-family swap-at-full" branch is intentionally **not** implemented in T010 — T011 adds it. This means in T010, catching a chip of a different family while equipped silently refills the held family and discards the rolled family. **Document this as a known transient gap in the Progress log; do not paper over it as if T011 were already done.**
    - The `default_pickup_family` export on `TypedWeaponSlot` is **retired**. Carriers now carry their rolled family, so the slot no longer needs a fallback. Remove the export and its wiring in `Player.tscn`.
  - **`TypedProjectile` archetype support.** Extend `src/weapons/typed_projectile.gd`:
    - `@export var pierce := false`. When `true`, `_on_hitbox_area_entered` deals damage and does **not** `queue_free()`. The projectile continues until it leaves the playfield. Maintain a small `_hit_targets: Array` and skip targets already in the array so a pierce projectile doesn't hit the same enemy twice on overlapping frames.
    - `configure_from_family(family)` reads `family.pierce` and assigns it to the projectile's `pierce` field.
    - `set_projectile_sprite` continues to handle the per-family sprite swap; additionally apply `Sprite2D.modulate = family.tint_color` for visual identity reinforcement (the per-family sprite alone may not be punchy enough at small sizes).
    - Despawn on leaving the playfield (existing behavior) is the safety net for pierce projectiles.
  - **`TypedWeaponSlot._fire_once()` archetype-aware firing.** When `family.archetype == SPREAD`, spawn `family.spread_count` projectiles in a fan around straight up, each angled by `-half + i * step` (where `step = spread_angle_degrees / max(1, spread_count - 1)`), with one `firing_cost` charge per trigger pull (not per projectile). For `PIERCE` and `SINGLE`, spawn one projectile straight up. Cost-and-expire bookkeeping is unchanged (still drives `is_expired()` via the single deduction). The projectile's `velocity()` already returns `Vector2.UP * speed`; the fan implementation can either rotate each spawned projectile's `rotation` and override `velocity()` to use the rotated forward, or add an `@export var direction := Vector2.UP` to `TypedProjectile` that the spawner sets to the rotated forward vector — implementer's call; document which approach was taken in the Progress log.
  - **`Main.tscn` wiring.** Populate `CarrierSpawner.weapon_pool` in the editor with the 5 family resources (`debug_plasma.tres`, `common_wide_spread.tres`, `common_piercing_lance.tres`, `common_heavy_slug.tres`, `common_rapid_stream.tres`). Remove the now-defunct `default_pickup_family` reference from `Player.tscn`.
  - **Headless smoke** (`tools/run_headless_smoke.sh`) continues to print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0. The new family resources, projectile sprites, and archetype branches must load and instantiate cleanly headless.

- **Out of scope:**
  - **Same-family refill / different-family swap-at-full branch logic.** T011. T010 always refills when equipped, regardless of family match. This is the load-bearing scope boundary of this task — do not implement the swap branch as a "while we're here" addition.
  - **Rare and legendary tier weapons.** Per `tasks/INDEX.md`, M4 ships common-tier only. The 2026-05-19 three-tier rarity decision applies to the larger faction pools, not to the v1 prototype's common-only pool.
  - **Per-family weighted drop rates.** Uniform random across the 5 entries is the v1 behavior. A `drop_weight` axis can be added later without restructuring; T010 deliberately does not introduce it.
  - **Per-faction or themed family rosters.** v1 has one faction. The four new families are flavor-agnostic and ship under a single shared pool.
  - **Per-family carrier hull sprites.** Tint-modulating the existing single carrier hull is the readability path. No new carrier silhouettes.
  - **Per-family chip sprites.** Tint-modulating the existing single chip sprite is the readability path. No new chip silhouettes.
  - **Enemy-fire system, collision interception, fuel-cell carriers, elite enemies, repair carriers.** Unrelated milestones.
  - **HUD changes.** EnergyMeter continues to render the current-vs-max bar; it does not need to display a family name in v1. (Display name is exposed on the resource so M7 can plumb it into the event log without rework, but T010 does not wire it into the HUD.)
  - **Audio, screen shake.**
  - **Tuning passes beyond initial values.** The five tuning starting points above are first-cut; tuning iteration belongs to M7.

## Scope changes

Leave empty if scope is unchanged. Document reductions or expansions with date and reason. Do not edit the Scope section above; record changes here.

- 2026-05-20 — User review tuning: carrier drops were far too frequent. Reduced `CarrierSpawner.spawn_interval_seconds` from `8.0` to `40.0`, then revised it to `20.0` after follow-up review feedback. This intentionally changes carrier cadence despite the original "what not to touch" note because the reviewer requested the tuning change before accepting T010.

## Pre-flight

- [x] T009 accepted; weapon-chip carrier, chip drift+collect, pickup burst, and the `apply_chip_pickup()` -> `default_pickup_family` flow are all working at HEAD.
- [x] Re-read 2026-05-15 "Large weapon pool, faction-gated primary drops" — the large-pool framing motivates per-family identity work; T010 is the first concrete authoring of that pool.
- [x] Re-read 2026-05-16 "Per-weapon-family firing cost" — confirm the four new families' `firing_cost` values land along the intended thrifty-vs-thirsty axis (Heavy Slug = thirstiest per shot; Rapid Stream = thinnest per shot but thirstiest per second).
- [x] Re-read 2026-05-18 "Typed weapons are faction-flavored sidegrades, not a power ladder" — common-tier families must read as sidegrades to each other within the tier, not as a strict ladder. Confirm the four tuning starting points don't accidentally rank one strictly above another.
- [x] Re-read 2026-05-18 "Bi-modal faction threat profile; three universal floors" — the four archetypes were chosen so no single one solves every threat (Wide can't single-target elites, Piercing can't clear horizontal spreads, Heavy can't keep up with rusher cadence, Rapid can't burst-down armored targets). v1 only has the one baseline enemy so this is currently theoretical, but the archetype set must keep the option open for M6's elites.
- [x] Re-read 2026-05-19 "Remove weapon levels; rarity tier carries the in-run power spike alone" — confirm each new family has a **single tuning**, no level fields, and lands its identity at default. This is a fresh authoring pass under the post-levels regime.
- [x] Re-read 2026-05-19 "Same-family pickup refills energy; different-family swaps at full" — confirm T011 is the swap-branch task, and confirm T010 deliberately ships without it. The temporary "always refill when equipped" gap is acceptable as a slice boundary.
- [x] Re-read `docs/PLAN.md` "Visual assets for v1" — confirm per-family projectile sprites can be authored as small placeholder pixel art (or, as a fallback, reuse the plasma bolt with tint). Programmer-rectangles are not acceptable.
- [x] Grep for callers of `apply_chip_pickup()` (no args) and `default_pickup_family` before changing signatures — confirm the only callers are `WeaponChip._try_collect_from` (which we are updating) and the T009 verifier (which we will also update).

## Implementation notes

- **Suggested tint palette** (HSV-evenly-spaced, saturated, distinct from baseline-enemy red and Defense Grid green so HUD/enemy visuals don't collide):
  - `debug_plasma`: cyan/teal (e.g., `Color(0.30, 0.95, 1.00)`).
  - Wide Spread: orange (e.g., `Color(1.00, 0.62, 0.18)`).
  - Piercing Lance: violet/magenta (e.g., `Color(0.85, 0.30, 1.00)`).
  - Heavy Slug: amber/yellow (e.g., `Color(1.00, 0.88, 0.28)`).
  - Rapid Stream: lime/chartreuse (e.g., `Color(0.55, 1.00, 0.30)`).
  Hues are starting points; the load-bearing constraint is that the five chips line up next to each other and read as five distinct colors at a glance.
- **Suggested per-family placeholder projectile sprites** under `assets/sprites/projectiles/`, all ~10×16 px to match `typed-plasma-bolt.png`:
  - `wide-spread-shard.png` — three short diagonal shards or a single fan-shaped chevron silhouette.
  - `piercing-lance-bolt.png` — a long narrow needle, taller than wide.
  - `heavy-slug-orb.png` — a chunky circular orb, visibly bigger than the plasma bolt.
  - `rapid-stream-dart.png` — a small thin dart, visibly smaller than the plasma bolt.
  Each gets a `.tres` projectile_sprite reference. If authoring all four blows the slice, the documented fallback is to reuse `typed-plasma-bolt.png` and rely on `tint_color` + size scale for differentiation — but author at least 2 of the 4 to keep the readability target.
- **WeaponArchetype enum location.** Defining the enum on `TypedWeaponFamily` (e.g., `enum Archetype { SINGLE, SPREAD, PIERCE }`) and exposing it as `@export var archetype: Archetype` is the cleanest path; `.tres` files store the integer ordinal. Document the enum values in the script's class comment so future families can be authored without reading the slot code.
- **Spread fire angle distribution.** With `spread_count = 3` and `spread_angle_degrees = 24.0`, the three projectiles fire at `-12°`, `0°`, `+12°` from straight up. With `spread_count = 1` the loop reduces to a single straight-up shot (use `step = 0` and skip the divide-by-zero).
- **Pierce hit-target tracking.** The simplest implementation: an internal `_hit_targets: Array[Node]` on `TypedProjectile` that records each target's instance ID on hit; subsequent overlaps with the same target are no-ops. Clear-on-spawn; no need to persist across frames in any other way. Pierce projectiles still despawn via the existing playfield-bounds check, so the array can't grow unboundedly.
- **Carrier tint application timing.** `set_family(family)` should be called by the spawner **before** `add_child(carrier)` if possible, so the tint is in place when `_ready` runs and the carrier never visually pops from default white to its tinted hue. If the spawner pattern requires `add_child` first to resolve the Sprite2D node, set the tint immediately after `add_child` and accept a 1-frame default modulate as a non-blocking cosmetic gap; document the choice in the Progress log.
- **Drop pool sampling.** `weapon_pool.pick_random()` is the simplest expression. If `weapon_pool` is empty (e.g., misconfigured `Main.tscn`), push a `push_warning` and skip the spawn — do not crash and do not silently spawn a no-family carrier.
- **Verifier updates.** Update `tests/evidence/T010-.../verify_weapon_pool.gd` to cover:
  1. Each of the 5 family `.tres` files loads cleanly and has non-empty `family_id`, non-zero `max_energy`, non-zero `tint_color`, and a non-empty `display_name`.
  2. A `TypedWeaponSlot` with no `active_weapon` receives `apply_chip_pickup(wide_spread)` → asserts the slot equips Wide Spread and `chip_pickup_applied("common_wide_spread", true)` fired exactly once.
  3. A `TypedWeaponSlot` equipped with Heavy Slug receives `apply_chip_pickup(rapid_stream)` → asserts `current_energy == max_energy`, the equipped family is **still** Heavy Slug (T010 does not swap), and `chip_pickup_applied("common_heavy_slug", false)` fired.
  4. A `TypedProjectile` with `pierce = true` hits a stub target twice (same target on consecutive frames) → asserts damage is applied once, not twice, and the projectile is **not** queued for deletion.
  5. A spread-archetype firing path spawns exactly `spread_count` projectiles and deducts `firing_cost` once.
  6. Prints `WEAPON_POOL_VERIFICATION_OK` and exits 0.
- **What not to touch in this slice.** EnergyMeter HUD layout (T005/T008), GridMeter HUD (T008), DefenseGrid leak path (T008), baseline enemy HP/descent (T006/T007 + the T009 scope-change to 2.5 HP), formation spawner cadence, pea shooter (T003), carrier sweep speed / sway / spawn cadence (T009), chip drift speed / sway (T009), pickup-burst visuals (T009), run-end overlay (T008).

## Acceptance evidence

**Artifacts:**

- `tests/evidence/T010-common-tier-weapon-families/family-roster.md` — short note listing all 5 families with their tuning values, display names, tint colors, and archetype. Cropped frame for each chip color side-by-side so the 5-color distinguishability is verifiable at a glance.
- `tests/evidence/T010-common-tier-weapon-families/carrier-tint-readout.png` (or stills) — frame showing carriers entering the playfield tinted to their family color. Reviewer should be able to predict the family from the hull tint before the kill.
- `tests/evidence/T010-common-tier-weapon-families/wide-spread-clip.mp4` (or stills) — clip showing Wide Spread equipped: 3-projectile fan per trigger pull, one cost per trigger, faster baseline density clear than debug_plasma.
- `tests/evidence/T010-common-tier-weapon-families/piercing-lance-clip.mp4` (or stills) — clip showing Piercing Lance equipped: a single bolt traveling through multiple enemies in a vertical line, damaging each, not despawning on first hit.
- `tests/evidence/T010-common-tier-weapon-families/heavy-slug-clip.mp4` (or stills) — clip showing Heavy Slug equipped: slow fire interval, large damage per shot, meter visibly drops in big chunks per trigger.
- `tests/evidence/T010-common-tier-weapon-families/rapid-stream-clip.mp4` (or stills) — clip showing Rapid Stream equipped: visibly faster fire interval and visibly faster meter drain than the other families.
- `tests/evidence/T010-common-tier-weapon-families/equip-from-empty-each-family.md` — note confirming that catching a chip of each of the 5 families from the no-weapon state equips that family at full energy and the typed-weapon fire input begins producing the expected per-family projectile pattern.
- `tests/evidence/T010-common-tier-weapon-families/refill-ignores-family-in-t010.md` — note explicitly confirming the T010-vs-T011 boundary: catching a chip of a different family while equipped refills the held family and discards the rolled family; the swap branch lands in T011.
- `tests/evidence/T010-common-tier-weapon-families/uniform-drop-distribution.md` — short note with the result of a headless run (or a verifier-script tally) showing rolled-family counts across ~100 carrier spawns are roughly uniform across the 5 entries (within sampling noise; no entry is structurally over- or under-represented).
- `tests/evidence/T010-common-tier-weapon-families/weapon-pool-verification.txt` — output of the verifier script ending in `WEAPON_POOL_VERIFICATION_OK`.
- `tests/evidence/T010-common-tier-weapon-families/headless-smoke.txt` — rerun of headless smoke; must still print `LAST_HORIZON_BOOT_SMOKE_OK` and exit 0.
- `tests/evidence/T010-common-tier-weapon-families/checklist.md` — manual checklist confirming all reviewer items below.
- `tests/evidence/T010-common-tier-weapon-families/git-status.txt` — `git status` after the work, demonstrating no generated Godot/editor state is included.

**Reviewer checklist:**

- [ ] Five families exist in the drop pool: `debug_plasma`, `common_wide_spread`, `common_piercing_lance`, `common_heavy_slug`, `common_rapid_stream`. Each `.tres` file loads cleanly with the expected tuning fields populated.
- [ ] Carriers entering the playfield are visibly tinted to the rolled family's color. The five tint colors are perceptually distinct against each other and against the baseline enemy and Grid colors.
- [ ] The dropped chip's color matches the carrier that dropped it. Catching a chip and seeing the equipped family in action is consistent with the pre-kill carrier tint.
- [ ] Each family's projectile behavior is readable as distinct from the others:
  - Wide Spread visibly fires 3 projectiles in a fan per trigger pull.
  - Piercing Lance visibly passes through enemies in a vertical line without despawning on first hit, and damages each enemy along the line.
  - Heavy Slug visibly fires slowly with a chunky projectile and large per-shot meter drain.
  - Rapid Stream visibly fires very quickly with thin projectiles and visibly faster meter drain than the others.
- [ ] Pierce damage is applied at most once per target (the same enemy is not double-counted across consecutive frames of overlap).
- [ ] Spread fire deducts exactly one `firing_cost` per trigger pull, not one per spawned projectile.
- [ ] First chip catch from the no-weapon state equips the rolled family at full energy. Typed-weapon fire begins working from that moment with the rolled family's behavior.
- [ ] Catching a chip of a different family while equipped silently refills the held family and discards the rolled family (T010 boundary; T011 introduces swap-at-full).
- [ ] Carrier rolls are uniform across the 5 families over a sampled run; no family is structurally over- or under-represented.
- [ ] No changes to baseline enemy behavior, formation descent, Defense Grid behavior, EnergyMeter HUD layout, pea-shooter behavior, carrier sweep speed/sway/cadence, chip drift speed/sway, pickup burst, or run-end overlay.
- [ ] `default_pickup_family` is removed from `TypedWeaponSlot` and `Player.tscn`. No code path still references it.
- [ ] Headless smoke still exits cleanly and prints `LAST_HORIZON_BOOT_SMOKE_OK`.
- [ ] `verify_weapon_pool.gd` output ends in `WEAPON_POOL_VERIFICATION_OK`.

**Rerun command:**

```bash
tools/godot/bin/godot --headless --path . --script tests/evidence/T010-common-tier-weapon-families/verify_weapon_pool.gd > tests/evidence/T010-common-tier-weapon-families/weapon-pool-verification.txt
tools/run_headless_smoke.sh > tests/evidence/T010-common-tier-weapon-families/headless-smoke.txt
tools/godot/bin/godot --display-driver x11 --rendering-method gl_compatibility --path . --script tests/evidence/T010-common-tier-weapon-families/capture_live_pool_evidence.gd > tests/evidence/T010-common-tier-weapon-families/live-capture.txt
git status > tests/evidence/T010-common-tier-weapon-families/git-status.txt
```

Visual evidence (`carrier-tint-readout.png`, `wide-spread-clip.mp4`, `piercing-lance-clip.mp4`, `heavy-slug-clip.mp4`, `rapid-stream-clip.mp4`) is produced from the live `Main.tscn` scene tree by `capture_live_pool_evidence.gd`, mirroring the T009 capture approach. The capture script may force-spawn one carrier per family in succession (bypassing the random pool draw) so each clip is deterministic.

## Progress log

| Date | Entry |
|---|---|
| 2026-05-20 | Created and activated. Pre-flight clarified with user: ship **4 new common-tier families + keep `debug_plasma` as a 5th** (5 families total), archetypes are **Wide Spread / Piercing Lance / Heavy Slug / Rapid Stream**, carrier rolls family **at spawn time** and **telegraphs via hull tint**, drop selection is **uniform random** across the 5 entries. The "different-family swap-at-full" branch is deliberately deferred to T011 — T010 always refills when equipped, even on family mismatch. |
| 2026-05-20 | Implemented the pool slice. Added family identity fields and archetype data to `TypedWeaponFamily`; created the four new common `.tres` resources and projectile PNG silhouettes; wired `CarrierSpawner.weapon_pool` in `Main.tscn`; removed `default_pickup_family` from `TypedWeaponSlot` and `Player.tscn`; added carrier/chip `set_family()` tint propagation. Spread fire uses an explicit `TypedProjectile.direction` vector with one energy deduction per trigger. T010's known transient gap is preserved: while equipped, any chip refills the held family and discards the rolled family; T011 owns the swap branch. |
| 2026-05-20 | Acceptance evidence is ready under `tests/evidence/T010-common-tier-weapon-families/`. `weapon-pool-verification.txt` ends in `WEAPON_POOL_VERIFICATION_OK`; `headless-smoke.txt` ends in `LAST_HORIZON_BOOT_SMOKE_OK`; `live-capture.txt` regenerated the carrier/chip tint stills and four family firing stills. Also reran the T009 carrier verifier after updating its compatibility calls to the new `apply_chip_pickup(family)` signature; it still ends in `CARRIER_VERIFICATION_OK`. Stop here for human review per the task workflow. |
| 2026-05-20 | Review tuning applied: carrier spawn interval changed from `8.0` to `40.0`, then follow-up review changed it to `20.0`. |
| 2026-05-21 | Human review accepted T010. Moved the task to `docs/tasks/completed/` and marked it completed. |

## Blocker

Only used when state is `blocked`.

- **Blocking system:**
- **Symptom:**
- **Minimal repro:**
- **Resolution needed:**
