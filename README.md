<p align="center">
  <img src="https://github.com/user-attachments/assets/2bb17574-4131-49f3-aae9-8fe32eaea2b9" alt="mazilkata-playerlist - NPV Inspired PlayerList" width="100%">
</p>

# mazilkata-playerlist

**NPV Inspired PlayerList** for FiveM by **Mazilkata Development**. A fast, clean player list menu with profile pictures, live ping, proximity counts, 3D head IDs and speaking highlights. Pure **HTML / CSS / JS** NUI (no build step) and a multi-framework bridge for **QBox, QBCore, ESX and Standalone**.

<p align="center">
  <img src="https://github.com/user-attachments/assets/3cc0d615-ae43-4193-9be5-cb0bb0648ad7" alt="Online tab" width="340">
  &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/e4bc470b-cb81-4744-b400-a6db328c2d94" alt="Disconnected tab" width="340">
</p>

---

## ✨ Features

- **⚡ 0.00ms Idle Resmon**: Zero loops or background threads run while the menu is closed. When opened, a single optimized thread dynamically handles head tags and area proximity scanning.
- **🎨 Sleek Sports-Style UI**: Exact visual match to modern esports/racing aesthetics with high-contrast cyan accents, dual stat widgets, condensed display typography, and smooth CSS animations.
- **🛠️ Pure Vanilla NUI (No Build Step Required)**: Built with pure `html/index.html`, `html/style.css`, and `html/script.js`. Edit styles and logic directly in any code editor with instant reloads.
- **👥 Live Online & Disconnected History**:
  - **ONLINE**: Real-time list of connected players, slot IDs, ping (ms), and optional identifiers.
  - **DISCONNECTED**: Ring buffer of recently disconnected players with relative departure timestamps ("left 2 min ago"), capped and expired automatically.
- **🏷️ Proximity 3D Head IDs**: Overhead floating player tags appear while the menu is open (within `Config.HeadIdDistance`).
- **🎙️ Real-time Speech Highlighting**: When a player talks, their overhead tag turns neon cyan/blue and reveals their identifier (if authorized), while their row in the menu pulses with audio wave bars.
- **🔑 Dual Navigation (Keys & Click)**:
  - Default `F6` keybind registered via `ox_lib` (fully rebindable in FiveM Key Bindings settings).
  - `ESC` or the open key again to close.
  - `Q` and `E` keyboard shortcuts to toggle between `ONLINE` and `DISCONNECTED` tabs (with badges shown beside tabs), plus full mouse-click support.
- **🔍 Instant Search Filter**: Filter players instantly by name, server slot ID, or identifier.
- **🔒 Privacy & Identifier Security**: Identifiers (SteamID64, Discord, License, FiveM) are protected server-side. The server only transmits identifiers to authorized clients based on `Config.ShowIdentifiersTo` (`'everyone' | 'admins' | 'none'`).
- **🖼️ Discord Profile Pictures**: Each player's profile picture (Cfx.re by default, Discord optional) is shown in their row, with a default-icon fallback. See Avatars below.
- **🌐 Comprehensive Locales**: Fully translatable UI strings with included English (`en`) and Bulgarian (`bg`) locale packs.
- **🌉 Universal Multi-Framework Bridge**: Auto-detects QBox (`qbx_core`), QBCore (`qb-core`), ESX (`es_extended`), or falls back to Standalone. Open and unescrowed bridge files allow effortless customization.

---

## 📁 Directory Structure

```
mazilkata-playerlist/
├── fxmanifest.lua          # Resource manifest and file declarations
├── LICENSE                 # Void Development License
├── config.lua              # Complete resource configuration
├── locales/
│   ├── en.lua              # English translations
│   └── bg.lua              # Bulgarian translations
├── bridge/
│   ├── loader.lua          # Framework detector and bridge dispatcher
│   ├── qbx.lua             # QBox bridge (character names & permissions)
│   ├── qb.lua              # QBCore bridge (character names & permissions)
│   ├── esx.lua             # ESX bridge (character names & permissions)
│   └── standalone.lua      # Standalone fallback (Steam/FiveM names & ACE permissions)
├── client/
│   ├── head_ids.lua        # Optimized 3D text renderer and voice detection
│   └── main.lua            # ox_lib keybind, thread lifecycle, and NUI callbacks
├── server/
│   ├── utils.lua           # Identifier conversion (Steam Hex -> Steam64) & permission checks
│   └── main.lua            # Online cache, disconnected queue, viewer tracking, ping sync
├── html/                   # Pure Vanilla NUI (No build step required)
│   ├── fonts/              # Bundled OFL Rajdhani fonts
│   ├── index.html          # Clean HTML structure
│   ├── style.css           # Pure responsive CSS styling
│   ├── script.js           # Vanilla JavaScript logic & NUI event handlers
└── README.md
```

---

## 🚀 Installation

1. Ensure **[ox_lib](https://github.com/overextended/ox_lib)** is installed and started before this resource.
2. Put the `mazilkata-playerlist` folder into your server's `resources` directory (e.g. `E:\scripts+mlos-fixed\mazilkata-playerlist`).
3. Add the resource to your `server.cfg`:
   ```cfg
   ensure ox_lib
   ensure mazilkata-playerlist
   ```
4. Adjust options in `config.lua` to match your server's preferences.
5. If using ACE permissions for admin identifier visibility, grant the permission in your `server.cfg`:
   ```cfg
   add_ace group.admin playerlist.admin allow
   ```

---

## 🖼️ Avatars

Works out of the box with **no token and no setup** (`Config.AvatarSource = 'cfx'`): the player's Cfx.re (FiveM forum) profile picture is shown, resolved from their `fivem:` identifier with the same public endpoint txAdmin uses. This endpoint is unofficial; if it ever changes, rows simply fall back to the default icon.

```
`Config.ShowAvatarsTo = 'admins'` hides avatars from normal players (links can reveal usernames / Discord IDs).

---

## ⚙️ Configuration (`config.lua`)

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `Config.Framework` | `string` | `'auto'` | `'auto'`, `'qbx'`, `'qb'`, `'esx'`, or `'standalone'` |
| `Config.Locale` | `string` | `'en'` | Active language (`'en'`, `'bg'`) |
| `Config.OpenKey` | `string` | `'F6'` | Default toggle key (rebindable in client settings) |
| `Config.DisplayNameMode` | `string` | `'character'` | `'character'` (RP name) or `'account'` (FiveM name) |
| `Config.IdentifierType` | `string` | `'steam'` | Primary identifier (`'steam'`, `'license'`, `'discord'`, `'fivem'`) |
| `Config.ConvertSteamTo64`| `boolean`| `true` | Convert Steam hex ID to standard 17-digit SteamID64 |
| `Config.ShowIdentifiersTo`| `string`| `'admins'` | `'everyone'`, `'admins'`, or `'none'` |
| `Config.AdminAcePermission`| `string`| `'playerlist.admin'` | ACE permission verified for admin rights |
| `Config.HeadIdDistance` | `number` | `15.0` | Range (meters) to draw 3D tags above player heads |
| `Config.AreaRadius` | `number` | `25.0` | Radius (meters) for "PLAYERS IN AREA" count |
| `Config.MaxDisconnected` | `number` | `20` | Max entries in the recently disconnected history |
| `Config.DisconnectedMaxAge`| `number`| `15` | Minutes before disconnected entries are pruned |
| `Config.ShowSearch` | `boolean` | `false` | Show the search bar under the tabs |
| `Config.ShowAvatars` | `boolean` | `true` | Show Discord profile pictures |
| `Config.AvatarSource` | `string` | `'cfx'` | `'cfx'` (no token), `'discord'`, or `'auto'` |
| `Config.ShowAvatarsTo` | `string` | `'everyone'` | `'everyone'`, `'admins'`, or `'none'` |
| `Config.AvatarCacheMinutes` | `number` | `30` | Avatar cache time on the server |
| `Config.PingRefreshInterval`| `number`| `5000` | Sync rate (ms) for ping updates to open menus |

---

## 📜 Credits & License
- Developed by **Mazilkata Development** for the FiveM Community.
- Licensed under the **Mazilkata Development License** (see `LICENSE`).
- Fonts bundled: **Saira Extra Condensed** and **Rajdhani** (SIL Open Font License, see `html/fonts/`).


