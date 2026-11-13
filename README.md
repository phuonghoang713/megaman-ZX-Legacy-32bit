# ZX-Legacy

An original 2D action platformer prototype for **Godot 3.5**, set up like the
Mega-Man-X8-32-bit project: 398×224 resolution, Smooth Colors and CRT
filters, an Options menu, key remapping and save files.

All code, art and sound here are original. The art is drawn in code and the
sound is synthesized at startup, so there are no image or audio assets yet.
You can replace them with your own sprites and music later.

## Play

Open the folder in Godot 3.5 and press **F5**, or run:

```
godot3 --path .
```

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | Arrows | D-pad / left stick |
| Jump | Z | A |
| Shoot (hold to charge) | X | X |
| Dash | C | B |
| Slash | V | Y |
| Previous / next core | A / S | LB / RB |
| Pause | Enter / Esc | Start |

Keys can be remapped in **Options → Controls**.

## Gameplay

You play as Kite, who can run, dash, dash-jump, wall-slide and wall-kick,
charge shots to three levels and slash at close range. Kite picks up
**cores** that change their armor color, shots and abilities:

| Core | Where | Effect |
|---|---|---|
| NOVA | Start | Balanced buster; the charged shot pierces |
| EMBER | Defeat the Sentinel | Heavy fire shots, 3-way charged shot, stronger slash |
| GALE | Skyward Span | Double jump, air dash, twin wind blades |

The rooms connect left to right: Verdant Run → Broken Aqueduct → Sentinel
Gate (boss) → Skyward Span → The Summit.

## Settings (Options menu)

- **Smooth Colors:** a pixel-art smoothing shader (`src/screen/smooth_upscale.shader`), on by default. It sits on canvas layer 0, above the world and below the HUD, so text stays sharp.
- **CRT filter:** off, light or strong (`src/screen/crt.shader`).
- **Window size** (1× and up), **fullscreen**, **music and sound volume**.

Settings are saved to `user://settings.cfg` and progress to `user://save.cfg`.

## Project layout

```
src/autoload/  Settings (config + input map), Audio (synth), Screen (filters), Game (save/progress)
src/screen/    Smooth Colors and CRT shaders
src/ui/        Title, Options, Pause, HUD, menu widget, 3x5 pixel font
src/world/     World (room manager), Rooms (layout data), Tiles, Background, Door
src/actors/    Player, Enemy base, Walker, Flyer, Sentinel (boss), Bullet, Pickup, Explosion
```

To add a room, add an entry to `ROOMS` in `src/world/Rooms.gd` and link it
through a neighbor's `left`/`right` field.
