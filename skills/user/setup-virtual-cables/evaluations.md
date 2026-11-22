# Behavioral Evaluations — `setup-virtual-cables`

Test scenarios and known failure modes for [`SKILL.md`](SKILL.md).

---

## Scenario 1: Ubuntu 22.04 Host with Active `pipewire` Portal and Legacy `pulseaudio`

- **User Observation**: `systemctl --user is-active pipewire pipewire-pulse` outputs `active` followed by `inactive`.
- **Failure Mode to Avoid**: Assuming `pipewire` `active` means PipeWire handles audio and telling the user to run `virtual-cable-pipewire.sh` (which fails on `media.class=Audio/Source/Virtual` and `pw-link`).
- **Expected Agent Behavior**:
  1. Check `systemctl --user is-active pulseaudio pipewire-pulse.socket` and `pactl info | grep "Server Name"`.
  2. When `Server Name: pulseaudio` is returned, explain that `pipewire` is running only for desktop video/screen-cast portals while PulseAudio manages audio.
  3. Direct the user to [`virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh).

---

## Scenario 2: Isolating a Wine Game (`Star Citizen` / Lutris / Steam) Without Breaking VOIP or Post-Reboot Audio

- **User Goal**: Capture **only** a Wine game's audio on the virtual cable without capturing Discord or desktop notifications.
- **Failure Modes to Avoid**:
  1. Setting `PULSE_SINK=virtspk` in a launch script without ensuring `virtspk` exists first—after a host reboot, `virtspk` is absent and `libpulse` returns `No such entity`, causing the game to launch completely silent.
  2. Setting `PULSE_SOURCE=virtmic` alongside `PULSE_SINK=virtspk`, which loops game audio into the game's own VOIP microphone instead of keeping the player's physical mic.
  3. Switching the global OS default output to `Virtual_Speaker`, causing Discord incoming voices to echo back into the virtual cable.
- **Expected Agent Behavior**:
  1. Prepend an idempotent call to `virtual-cables-pulseaudio.sh >/dev/null` (in `sc-launch.sh`, Lutris Pre-launch script, or Steam Launch Options) before exporting `PULSE_SINK=virtspk`.
  2. Explicitly keep `PULSE_SOURCE` unset and keep global OS default output on physical headphones/speakers.

---

## Scenario 3: Running Virtual Cable Scripts Inside an Isolated Devcontainer

- **User Observation**: Running `./virtual-cables-pulseaudio.sh` inside the devcontainer terminal exits with an error.
- **Failure Mode to Avoid**: Attempting to start a system-wide root PulseAudio daemon inside the container when the user wants virtual cables for host desktop apps.
- **Expected Agent Behavior**:
  1. Recognize the script's `Cannot connect to PulseAudio server` check (`require_pulseaudio` in [`virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh)).
  2. Instruct the user to run live virtual cable commands in a **host terminal**, while using [`tests/test_virtual_cables.sh`](../../../tests/test_virtual_cables.sh) for automated testing inside the container.
