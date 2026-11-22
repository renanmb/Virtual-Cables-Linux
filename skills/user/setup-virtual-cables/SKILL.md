---
name: setup-virtual-cables
description: Detect PulseAudio vs. PipeWire on a Linux host, set up virtual audio cables, verify signal flow with pavucontrol, and isolate OBS, browser, or Wine/Star Citizen game audio.
---

# Setup Virtual Cables (`Virtual-Cables-Linux`)

Guide users or configure a Linux desktop to route isolated application/OBS/Wine audio into a virtual microphone (`Virtual_Microphone` / `VirtualMic`) while optionally monitoring audio in physical headphones.

See [`evaluations.md`](evaluations.md) for behavioral test scenarios and known edge cases.

## 1. Detect the Active Host Audio Server

Always run this check **on the Linux host** (not inside an isolated container):

```bash
systemctl --user is-active pulseaudio pipewire pipewire-pulse pipewire-pulse.socket
pactl info | grep "Server Name"
```

- **`Server Name: pulseaudio`** -> Use [`./virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh).
  *(Ubuntu 22.04 Pitfall: `pipewire.service` is often `active` for Wayland screen-sharing portals even when `pulseaudio.service` handles all audio and `pipewire-pulse` is `inactive`. Always rely on `Server Name`.)*
- **`Server Name: PulseAudio (on PipeWire ...)`** -> Use [`./virtual-cable-pipewire.sh`](../../../virtual-cable-pipewire.sh).

## 2. Install Host Prerequisites

```bash
# Ubuntu / Debian
sudo apt install pulseaudio-utils pavucontrol

# Fedora
sudo dnf install pulseaudio-utils pavucontrol
```

## 3. Create, Inspect, and Remove the Virtual Cable (PulseAudio)

```bash
# Create Virtual_Speaker (virtspk), Virtual_Microphone (virtmic), and headphone loopback
./virtual-cables-pulseaudio.sh start

# Omit headphone loopback if routing your own microphone via OBS (avoids sidetone echo)
./virtual-cables-pulseaudio.sh restart --no-loopback

# Inspect loaded PulseAudio modules
./virtual-cables-pulseaudio.sh status

# Unload virtual cable modules cleanly without restarting PulseAudio
./virtual-cables-pulseaudio.sh stop
```

## 4. Verify Signal Flow with `pavucontrol`

1. Keep the system's **global default output** set to physical headphones/speakers in Ubuntu Sound Settings / `pavucontrol` (*Output Devices* green checkmark) so Zoom/Discord incoming voices do not echo into the virtual mic.
2. Open `pavucontrol` -> **Input Devices** -> **Show: All Input Devices**.
3. Play a test sound into the virtual sink:
   ```bash
   paplay --device=virtspk /usr/share/sounds/alsa/Front_Center.wav
   ```
4. Confirm you both **hear** the clip in your physical headphones (via `Virtual_Speaker_Loopback`) and **see the input level meter bounce** on `Virtual_Microphone`.

## 5. Isolate a Single Source (Wine Games, Browsers, or OBS)

### Wine / Star Citizen (`LUG`) / Steam / Lutris (`PULSE_SINK=virtspk`)
Prefer `PULSE_SINK=virtspk` over `pavucontrol` for Wine games so `module-stream-restore` does not group unrelated `wine64-preloader` processes together and zero startup audio leaks:

1. **Always ensure `virtspk` exists before launching** (if `virtspk` is missing, `libpulse` fails stream creation and the game launches silent):
   ```bash
   ./virtual-cables-pulseaudio.sh >/dev/null && PULSE_SINK=virtspk wine Game.exe
   ```
2. **Leave `PULSE_SOURCE` unset** so in-game VOIP (e.g., Star Citizen voice chat) keeps using the user's real physical microphone.
3. Keep the in-game Audio Output setting on **Default / System Default**.

### Dedicated Browser Instance
Pass a dedicated profile so the browser does not merge into an already-running desktop browser process:
- Firefox: `PULSE_SINK=virtspk firefox --new-instance -P stream`
- Chromium/Chrome: `PULSE_SINK=virtspk google-chrome --user-data-dir="$HOME/.config/chrome-cable"`

### Capturing Isolated Audio in OBS Studio
1. Mute/disable `Desktop Audio` in OBS.
2. Add an **Audio Output Capture (PulseAudio)** source targeting **`Virtual_Speaker`** (or **Audio Input Capture** targeting **`Virtual_Microphone`**).
