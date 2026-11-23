# Project Documentation (`docs/`)

Operational, architectural, and audio-routing guides for **`Virtual-Cables-Linux`** and its integration with **`renanmb/lug-wine-experimental`** and **Steam**.

---

## Documentation Guides

1. [**`standard_devcontainer_and_agent_architecture.md`** — Standard Devcontainer & Multi-Agent Architecture](standard_devcontainer_and_agent_architecture.md)
   - Four-pillar `.agents/` topology, canonical `skills/` layout, relative discovery symlinks, and Ubuntu 22.04 Jammy multi-agent devcontainer boundaries.
2. [**`04_audio_isolation_and_obs_streaming_guide.md`** — Audio Configuration, Virtual Cable Isolation & OBS Streaming Guide](04_audio_isolation_and_obs_streaming_guide.md)
   - End-to-end PulseAudio virtual-cable routing (`PULSE_SINK=virtspk`) synced with `renanmb/lug-wine-experimental` (`docs/01`–`04`) and extended for **Steam** (Proton `winepulse.drv` & Native Linux `%command%` Launch Options, `pressure-vessel`, Snap/Flatpak, and `SDL_AUDIODRIVER=pulse`).
   - Covers OBS Studio setup, Discord/Zoom `Virtual_Microphone` routing, headphone vs. speaker local monitoring (`Virtual_Speaker_Loopback`), and live `pactl` / `pavucontrol` troubleshooting.

---

## Related Directories in `.agents/references/`

- [**`notes/`**](../notes/20261122_virtual_cable_wine_and_window_routing_handoff.md): Investigation reports, per-window isolation notes, and cross-session handoffs.
- [**`plans/`**](../plans/README.md): Active and archived implementation plans.
