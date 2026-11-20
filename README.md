# The Lazy Eye

The Lazy Eye is a first-person horror game built with Godot. It combines PSX-inspired visuals, atmospheric audio, exploration, interaction, and stealth-oriented movement across dark interior environments.

> **Development status:** Work in progress. Scenes, mechanics, and content are still being iterated on.

## Requirements

- [Godot 4.7](https://godotengine.org/) or a compatible Godot 4 release
- A desktop platform supported by Godot

## Getting started

1. Clone or download this repository.
2. Open the `maaack's-minimal-game-template` folder in Godot.
3. Import the project and wait for Godot to finish importing assets.
4. Press **Run Project** (`F6`/`F5`, depending on your Godot setup) to launch the game.

The Godot project file is located at:

```text
maaack's-minimal-game-template/project.godot
```

## Controls

| Action | Keyboard |
| --- | --- |
| Move | `W` `A` `S` `D` |
| Look | Mouse |
| Interact | `E` |
| Jump | `Space` |
| Crouch | `Ctrl` |
| Reload current scene | `R` |
| Quit | `Backspace` |

Controller inputs are also configured for movement, interaction, and menu confirmation.

## Project structure

```text
maaack's-minimal-game-template/
├── assets/       # Models, textures, audio, environments, and reusable assets
├── scenes/       # Player, map, enemy, interaction, menu, and test scenes
├── addons/       # Godot template and supporting plugins
├── *.gd          # Gameplay, audio, level, and menu scripts
├── *.tscn        # Godot scenes and playable levels
└── project.godot # Project configuration and input actions
```

Notable gameplay components include:

- First-person player movement with jumping and crouching
- Mouse-look camera controls
- Interactable 3D areas and scene transitions
- Enemy and field-of-view scenes for stealth gameplay
- Audio management and level-specific music
- CRT/PSX-style visual effects and atmospheric environments

## Development

Open the project in the Godot editor to modify scenes, scripts, input actions, and imported assets. New gameplay scenes should be added under `scenes/`, while reusable art and audio should be kept under `assets/`.

The project uses the GL Compatibility renderer, making it suitable for a broad range of desktop hardware.

## Credits and third-party content

This project includes the Maaack's Minimal Game Template and supporting plugins. Refer to the attribution and license files inside `maaack's-minimal-game-template/addons/` for third-party credits and terms.
