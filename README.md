# Virtual-Cables-Linux

Scripts to create virtual audio cables on Linux—ideal for routing audio from **OBS Studio**, browsers, media players, or games/Wine into conferencing and voice apps like **Zoom, Discord, and Jitsi**, while still hearing the audio locally in your headphones.

```text
[App / OBS Output] ──► Virtual_Speaker (virtspk) ──┬──► Virtual_Microphone (virtmic) ──► [Zoom / Discord / Jitsi]
                                                   └──► Virtual_Speaker_Loopback     ──► [Your Headphones / Speakers]
```

Two scripts are included:
- `virtual-cables-pulseaudio.sh` — for **PulseAudio** systems (supports `start`, `stop`, `restart`, `status`, and `--no-loopback`)
- `virtual-cable-pipewire.sh` — for **PipeWire** (`pipewire-pulse`) systems

---

## 1. Check Which Audio Server You Use

Run this on your host terminal:

```bash
pactl info | grep "Server Name"
```

- **`Server Name: pulseaudio`** → Your system uses PulseAudio. Use `./virtual-cables-pulseaudio.sh`.
  *(Note: On Ubuntu 22.04, `pipewire` may appear active for desktop screen-sharing portals while `pulseaudio` still manages audio—always trust `Server Name` above.)*
- **`Server Name: PulseAudio (on PipeWire ...)`** → Your system uses PipeWire. Use `./virtual-cable-pipewire.sh`.

---

## 2. Prerequisites

Install `pulseaudio-utils` (provides `pactl` / `paplay`) and `pavucontrol` (**PulseAudio Volume Control**):

- **Ubuntu / Debian:**
  ```bash
  sudo apt install pulseaudio-utils pavucontrol
  ```
- **Fedora:**
  ```bash
  sudo dnf install pulseaudio-utils pavucontrol
  ```

**Why install `pavucontrol`?**
Desktop sound settings usually switch your *entire system's* default speaker/mic. `pavucontrol` lets you route **individual apps** into `Virtual_Speaker` without affecting the rest of your desktop audio, and provides live level meters to verify signal flow.

---

## 3. Creating & Managing the Virtual Cable

### PulseAudio (`virtual-cables-pulseaudio.sh`)

```bash
# Start virtual cable (creates Virtual_Speaker, Virtual_Microphone, and headphone loopback)
./virtual-cables-pulseaudio.sh

# Start WITHOUT local headphone loopback (useful if routing your own mic via OBS to avoid hearing yourself)
./virtual-cables-pulseaudio.sh restart --no-loopback

# Check active virtual cable modules
./virtual-cables-pulseaudio.sh status

# Cleanly remove the virtual cable without restarting PulseAudio
./virtual-cables-pulseaudio.sh stop
```

### PipeWire (`virtual-cable-pipewire.sh`)

Run when no audio apps are actively holding devices:

```bash
./virtual-cable-pipewire.sh
```

To reset PipeWire virtual devices:

```bash
systemctl --user restart pipewire pipewire-pulse
```

---

## 4. Testing & Routing Audio with `pavucontrol`

### Step A: Verify the Virtual Cable End-to-End

1. Start the virtual cable (`./virtual-cables-pulseaudio.sh`).
2. Launch PulseAudio Volume Control:
   ```bash
   pavucontrol
   ```
3. Go to the **Input Devices** tab and set the bottom **Show:** dropdown to **All Input Devices**—you will see **`Virtual_Microphone`** (for PulseAudio) or **`VirtualMic`** (for PipeWire) with a live volume bar.
4. In a terminal, play a test sound directly into the virtual speaker:
   ```bash
   # PulseAudio:
   paplay --device=virtspk /usr/share/sounds/alsa/Front_Center.wav

   # PipeWire:
   paplay --device=VirtualSpeaker /usr/share/sounds/alsa/Front_Center.wav
   ```
5. Confirm two things happen simultaneously:
   - You **hear** `"Front Center"` in your physical headphones/speakers (via the loopback).
   - You **see the level meter bounce** under `Virtual_Microphone` in `pavucontrol`.

### Step B: Route Specific Apps into the Virtual Cable

Keep your global OS Sound Output set to your **physical speakers/headphones** (so incoming voices from Zoom/Discord don't echo back into the virtual mic), and route only the apps you want to share:

- **Any desktop app (Firefox, Chrome, VLC, Spotify, Wine/Games):**
  1. Start playing audio in the app so it appears as an active stream.
  2. In `pavucontrol`, open the **Playback** tab and set **Show:** to **Applications**.
  3. Next to that app, change its output dropdown to **`Virtual_Speaker`**.
- **OBS Studio:**
  1. Open **Settings → Audio → Advanced** and set **Monitoring Device** to **`Virtual_Speaker`**.
  2. Click **Edit → Advanced Audio Properties** and set **Audio Monitoring** to **Monitor and Output** (or **Monitor Only**) for each audio source you want sent to the virtual mic.
- **Adjusting where you hear the loopback:**
  1. In `pavucontrol`, open the **Playback** tab and set **Show:** to **All Streams**.
  2. Find **`Virtual_Speaker_Loopback`** (or `Loopback from Monitor of VirtualSpeaker`) and select your preferred physical headset/speakers.

### Step C: Use the Virtual Microphone in Zoom / Discord / Jitsi

1. In your conferencing app's audio settings, set **Microphone / Input Device** to **`Virtual_Microphone`** (or **`VirtualMic`** on PipeWire).
2. Alternatively, while the app is actively capturing audio, open `pavucontrol` → **Recording** tab and assign that app's input stream to **`Virtual_Microphone`**.
