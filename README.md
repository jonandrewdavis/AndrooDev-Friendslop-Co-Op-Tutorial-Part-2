# AndrooDev Friendslop Co-Op Tutorial PART 2

The complete tutorial project from the [Godot Multiplayer Friendslop Co-Op Tutorial Part 2 on YouTube](https://www.youtube.com/watch?v=wgIqB6JNcro). Uses WebRTC via the Tube https://github.com/koopmyers/tube to make it easy to make a true peer-to-peer and play with your friends. See [Part 1 on YouTube here](https://youtu.be/NvG08tA06xQ) to build up your multiplayer fundamentals like syncing and spawning.

|             Twitch             |              Youtube               |            Play now on Itch (Send to a friend!)             |
| :----------------------------: | :--------------------------------: | :---------------------------------------------------------: |
| https://www.twitch.tv/andoodev | https://www.youtube.com/@AndrooDev | https://androodev.itch.io/androodev-friendslop-co-op-sample |

<img src="assets/docs/androodev-finished-part-2.png" width="500">

## Local Development:

#### NOTE: You may need to allow WebRTC extension in your security settings when the project starts on local! See the official https://github.com/godotengine/webrtc-native package for more information.

- Clone this project
- Import in Godot 4.6
- You may need to disable Game Embed.
  - Open Godot menu -> Select Editor Settings
  - Search Embed
  - Window Placement
  - Game Embed Mode: Disabled
- Select Debug -> Select Customize Run Instances
  - Set 3 instances
- Play
  - Launched windows should tile
- Create session (Copies Session ID)
- Join on client (Paste session)
- Join on client (Paste session)

## Controls

- Tab to open menu
- WASD to Move
- Mouse to look
- Left Click to shoot ball

|         Game Embed Mode: Disabled         |               Customize Run Instances               |
| :---------------------------------------: | :-------------------------------------------------: |
| ![](assets/docs//template_settings_2.png) | ![](assets/docs/customize-run-instances-part-2.png) |
