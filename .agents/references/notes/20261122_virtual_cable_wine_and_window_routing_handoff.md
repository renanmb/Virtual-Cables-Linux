# Pre-Rebuild Handoff & Audio Routing Notes (Virtual Cable, Wine, and Per-Window Isolation)

- **Date**: 2026-11-22
- **Session ID**: `a2cdfc85`
- **Context**: Written right before the **first devcontainer rebuild** under the new `.agents` multi-assistant architecture so the next session can resume seamlessly.

---

## 1. Where We Stopped (Current State)

1. **Host Audio Server Confirmed**:
   - Host runs Ubuntu 22.04.5 LTS (`7.2.10-zabbly+` kernel) with **legacy PulseAudio (`Server Name: pulseaudio`)** actively managing audio.
   - `pipewire.service` is `active` only for desktop Wayland screen-sharing portals (`pipewire-pulse` is `inactive`), so [`virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh) is the active script for this machine (not [`virtual-cable-pipewire.sh`](../../../virtual-cable-pipewire.sh)).
2. **PulseAudio Virtual Cable Overhauled & Verified Live on Host**:
   - Rewrote [`virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh) with `start` (default), `stop`, `restart`, `status`, and `--no-loopback`.
   - Fixed the original script's disconnected sinks and broken monitor name:
     - Loads `module-null-sink` -> `virtspk` (`Virtual_Speaker`).
     - Loads `module-remap-source` -> `virtmic` (`Virtual_Microphone` reading `master=virtspk.monitor`) so Zoom, Discord, and Jitsi list it as a real microphone.
     - Loads `module-loopback` (`Virtual_Speaker_Loopback`) reading `virtspk.monitor` (`latency_msec=30`, `source_dont_move=true`) and automatically targeting the host's pre-existing default physical sink (`alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo`) so local headphone monitoring works without feedback loops.
   - Verified live on the host (`Loaded module #27`, `#28`, `#29` and `./virtual-cables-pulseaudio.sh status`).
3. **Documentation & `.agents` Multi-Assistant Workspace Scaffolded**:
   - Updated [`README.md`](../../../README.md) with signal-flow diagram and `pavucontrol` end-to-end verification steps.
   - Created [`AGENTS.md`](../../../AGENTS.md), [`CLAUDE.md`](../../../CLAUDE.md), [`.gitignore`](../../../.gitignore), [`skills/`](../../../skills), [`.agents/`](../../../.agents), and [`tests/test_virtual_cables.sh`](../../../tests/test_virtual_cables.sh).
   - Adapted [`.devcontainer/Dockerfile`](../../../.devcontainer/Dockerfile), [`.devcontainer/devcontainer.json`](../../../.devcontainer/devcontainer.json), and [`.devcontainer/init_agent_workspace.sh`](../../../.devcontainer/init_agent_workspace.sh) to Ubuntu 22.04 Jammy with `lug-wine-experimental`, `lug-helper`, and `Games` bind mounts.
   - **Git state**: All changes are currently unstaged/uncommitted in the working tree awaiting user branch confirmation after testing the container rebuild.

---

## 2. Configuring Isolated Audio for Wine Games (`LUG` / Star Citizen / Lutris / Steam)

For Wine applications (`winepulse.drv`), launching with **`PULSE_SINK=virtspk`** is preferred over manually switching streams in `pavucontrol`:

### Why `PULSE_SINK=virtspk` Is Better for Wine
- **Prevents Wine cross-contamination**: PulseAudio's `module-stream-restore` (`pavucontrol`) often keys off generic binary names like `wine64-preloader`, which can unintentionally route *other* Wine prefixes/games into `Virtual_Speaker`. `PULSE_SINK=virtspk` isolates **only that launched process tree** (e.g., `RSI Launcher.exe` + `StarCitizen.exe`).
- **Zero startup audio leak**: Audio is routed to `virtspk` from millisecond zero, surviving cutscene/map-load stream recreations.
- **Preserves in-game VOIP microphone**: Leaving `PULSE_SOURCE` **unset** keeps the player's physical microphone active for in-game voice chat (e.g., Star Citizen VOIP) instead of looping game audio into the game's mic.

### Critical Wine Setup Rules
1. **Always ensure `virtspk` exists *before* launching Wine with `PULSE_SINK=virtspk`**:
   - If `virtspk` is missing (for example, right after a host reboot), `libpulse` fails `pa_stream_connect_playback()` with `No such entity` and the game launches **completely silent** rather than falling back to the headset.
   - Because `virtual-cables-pulseaudio.sh` is idempotent (fast no-op when already active), always call it prior to exporting `PULSE_SINK=virtspk`:
     - **Launch script (`sc-launch.sh` `# ENVIRONMENT VARIABLES` block)**:
       ```bash
       /home/tarfy/Documents/GitHub/renanmb/Virtual-Cables-Linux/virtual-cables-pulseaudio.sh >/dev/null
       export PULSE_SINK="virtspk"
       ```
     - **Direct CLI**:
       ```bash
       /home/tarfy/Documents/GitHub/renanmb/Virtual-Cables-Linux/virtual-cables-pulseaudio.sh >/dev/null && \
       PULSE_SINK=virtspk WINEPREFIX="/path/to/prefix" wine "/path/to/Game.exe"
       ```
     - **Lutris**: Set *Pre-launch script* to `virtual-cables-pulseaudio.sh` and add environment variable `PULSE_SINK=virtspk`.
     - **Steam Launch Options**:
       ```bash
       /path/to/virtual-cables-pulseaudio.sh >/dev/null && PULSE_SINK=virtspk %command%
       ```
2. **In-Game Windows Audio Settings**:
   - Keep the game's internal Audio Output / Speakers setting on **Default / System Default** (`winepulse.drv` passes `dev=NULL` to `pa_stream_connect_playback()`, which `libpulse` routes to `PULSE_SINK=virtspk`; `Virtual_Speaker` also appears in the game's endpoint list if direct selection is ever needed).
3. **Keep Global Host OS Output on the Physical Headset**:
   - Never set `Virtual_Speaker` as the host's system-wide fallback output; keeping the USB headset as global default ensures Discord/Zoom incoming voices and desktop notifications stay out of `Virtual_Speaker`.

---

## 3. Isolating Specific Windows & Individual App Instances on the Desktop

When capturing **only one specific window** (such as a single browser window, media player window, or already-running app) without capturing other windows on the device:

### A. Isolating One Specific Browser Window (`Firefox` / `Chrome` / `Brave`)
Browsers normally merge new windows into an already-running main browser process (ignoring `PULSE_SINK` on the second launch, and sharing a single app entry in `pavucontrol`). To isolate **one specific browser window** onto `Virtual_Speaker` while your main browser stays on normal desktop audio:

- **Firefox (dedicated profile + `--new-instance`)**:
  ```bash
  # One-time profile creation if needed: firefox -P
  ./virtual-cables-pulseaudio.sh >/dev/null && PULSE_SINK=virtspk firefox --new-instance -P stream
  ```
- **Chrome / Chromium / Brave (dedicated `--user-data-dir`)**:
  ```bash
  ./virtual-cables-pulseaudio.sh >/dev/null && PULSE_SINK=virtspk google-chrome --user-data-dir="$HOME/.config/chrome-cable"
  ```

### B. Routing an Already-Open Window via `pavucontrol` (GUI)
1. Make sure that window is actively playing audio (PulseAudio only lists active playback streams).
2. Open `pavucontrol` -> **Playback** tab.
3. Set **Show:** at the bottom to **All Streams** (or **Applications**):
   - When multiple windows/tabs create separate streams (such as separate `mpv`/`VLC` instances or Firefox `AudioIPC` media streams), each active stream has its own output dropdown.
   - Switch only the target stream's dropdown to **`Virtual_Speaker`**.

### C. Targeting a Specific X11 Window by Clicking It (`xprop` + `pactl` CLI)
To dynamically move an already-running native window into `virtspk` by PID from a host terminal:
1. Click the target window to get its `_NET_WM_PID`:
   ```bash
   xprop _NET_WM_PID
   ```
2. Find the matching PulseAudio `Sink Input #<ID>` whose `application.process.id` matches that PID (or child audio process):
   ```bash
   pactl list sink-inputs
   ```
3. Move **only that stream** to `virtspk` on the fly:
   ```bash
   pactl move-sink-input <SINK_INPUT_ID> virtspk
   ```

### D. Capturing the Isolated Feed in OBS / Discord / Zoom
- **OBS Studio**: Mute/disable `Desktop Audio` and add **Audio Output Capture (PulseAudio)** -> **`Virtual_Speaker`** (or **Audio Input Capture** -> **`Virtual_Microphone`**).
- **Zoom / Discord / Jitsi**: Select **`Virtual_Microphone`** as the input microphone.
- **Local Headphone Monitoring**: `Virtual_Speaker_Loopback` automatically plays `Virtual_Speaker` into your physical headset so you still hear the isolated game/window. (Use `./virtual-cables-pulseaudio.sh restart --no-loopback` if routing your own voice via OBS to avoid hearing yourself.)

---

## 4. Post-Rebuild Resumption Checklist (Next Session)

Immediately after **Dev Containers: Rebuild Container** completes:
1. **Verify newly built image tools & MCP server**:
   ```bash
   which agy claude codex hermes mcp-server-filesystem shellcheck pactl uv uvx gh
   ```
2. **Verify LUG bind mounts & `/workspaces` symlinks**:
   ```bash
   ls -ld /lug-wine-experimental /lug-helper /home/tarfy/Games /workspaces/lug-wine-experimental /workspaces/lug-helper
   ```
3. **Run full automated verification (now including `shellcheck`)**:
   ```bash
   bash tests/test_virtual_cables.sh
   ```
4. **Resume next user goals**:
   - Confirm whether to commit the `Virtual-Cables-Linux` overhaul + `.agents` workspace (`git commit -s` via [`commit-and-pr`](../../../skills/developer/commit-and-pr/SKILL.md)).
   - Optionally integrate an opt-in virtual-cable toggle in Star Citizen's `sc-launch.sh` or test live per-window / Wine capture with `pavucontrol` and OBS on the host.
