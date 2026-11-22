#!/usr/bin/env bash
# Manage PulseAudio virtual audio cables on Linux:
#   1. Virtual_Speaker (virtspk)      - Null sink where apps/OBS send audio output
#   2. Virtual_Microphone (virtmic)   - Remapped mic source for Zoom / Jitsi / Discord
#   3. Virtual_Speaker_Loopback       - Optional loopback so you hear Virtual_Speaker locally
#
# Recommended GUI mixer for routing per-app audio:
#   Ubuntu/Debian: sudo apt install pavucontrol
#   Fedora:        sudo dnf install pavucontrol

set -euo pipefail

SINK_NAME="virtspk"
SINK_DESC="Virtual_Speaker"
MIC_NAME="virtmic"
MIC_DESC="Virtual_Microphone"
LOOPBACK_LATENCY_MS=30

usage() {
    cat <<EOF
Usage: $(basename "$0") [start|stop|restart|status] [--no-loopback]

Commands:
  start          Create Virtual_Speaker, Virtual_Microphone, and headphone loopback (default)
  stop           Unload virtual cable modules without restarting PulseAudio
  restart        Recreate the virtual cable modules cleanly
  status         Show loaded virtual cable modules and devices

Options:
  --no-loopback  Do not load local speaker/headphone monitoring loopback
  -h, --help     Show this help message
EOF
}

require_pulseaudio() {
    if ! command -v pactl >/dev/null 2>&1; then
        echo "Error: 'pactl' not found. Install it with: sudo apt install pulseaudio-utils" >&2
        exit 1
    fi
    if ! pactl info >/dev/null 2>&1; then
        echo "Error: Cannot connect to PulseAudio server. Run this script on your host session (not an isolated container)." >&2
        exit 1
    fi
}

find_cable_module_ids() {
    pactl list short modules | awk '
        $2 == "module-loopback" && $0 ~ /(^|[ \t])source=virtspk\.monitor([ \t]|$)/ { print $1 }
        $2 == "module-remap-source" && $0 ~ /(^|[ \t])source_name=virtmic([ \t]|$)/ { print $1 }
        $2 == "module-null-sink" && $0 ~ /(^|[ \t])sink_name=(virtspk|virtmic)([ \t]|$)/ { print $1 }
    ' | sort -rn
}

sink_exists() {
    pactl list short sinks | awk -v name="$1" '$2 == name { found=1 } END { exit !found }'
}

source_exists() {
    pactl list short sources | awk -v name="$1" '$2 == name { found=1 } END { exit !found }'
}

stop_cables() {
    local ids
    ids="$(find_cable_module_ids)"
    if [[ -z "${ids}" ]]; then
        echo "No virtual cable modules are currently loaded."
        return 0
    fi

    local id
    for id in ${ids}; do
        pactl unload-module "${id}"
        echo "Unloaded PulseAudio module #${id}"
    done
    echo "Virtual audio cables removed."
}

start_cables() {
    local enable_loopback="$1"

    if sink_exists "${SINK_NAME}" || source_exists "${MIC_NAME}"; then
        echo "Virtual cable is already active. Run '$0 restart' to recreate or '$0 stop' to remove."
        return 0
    fi

    local default_sink
    default_sink="$(pactl info | sed -n 's/^Default Sink: //p')"

    local sink_mod_id mic_mod_id loopback_mod_id

    echo "Creating virtual output sink: ${SINK_DESC} (${SINK_NAME})..."
    sink_mod_id="$(pactl load-module module-null-sink \
        "sink_name=${SINK_NAME}" \
        "sink_properties=device.description=${SINK_DESC}")"
    echo "  Loaded module #${sink_mod_id}"

    echo "Creating virtual microphone: ${MIC_DESC} (${MIC_NAME} <- ${SINK_NAME}.monitor)..."
    mic_mod_id="$(pactl load-module module-remap-source \
        "master=${SINK_NAME}.monitor" \
        "source_name=${MIC_NAME}" \
        "source_properties=device.description=${MIC_DESC}")"
    echo "  Loaded module #${mic_mod_id}"

    if [[ "${enable_loopback}" == "true" ]]; then
        echo "Creating local monitoring loopback (${SINK_NAME}.monitor -> ${default_sink:-default output})..."
        local loopback_args=(
            "source=${SINK_NAME}.monitor"
            "latency_msec=${LOOPBACK_LATENCY_MS}"
            "source_dont_move=true"
            "sink_input_properties=media.name=Virtual_Speaker_Loopback"
        )
        if [[ -n "${default_sink}" && "${default_sink}" != "${SINK_NAME}" && "${default_sink}" != "auto_null" ]]; then
            loopback_args+=("sink=${default_sink}")
        fi
        loopback_mod_id="$(pactl load-module module-loopback "${loopback_args[@]}")"
        echo "  Loaded module #${loopback_mod_id}"
    fi

    cat <<EOF

Virtual audio cable is ready:
  - Send app/OBS audio output to: ${SINK_DESC} (${SINK_NAME})
  - Select microphone in Zoom/Discord/Jitsi: ${MIC_DESC} (${MIC_NAME})
  - Adjust per-app routing or loopback playback device in 'pavucontrol'
  - Remove anytime with: $0 stop
EOF
}

status_cables() {
    local ids
    ids="$(find_cable_module_ids)"
    if [[ -z "${ids}" ]]; then
        echo "Status: inactive (no virtual cable modules loaded)"
        return 0
    fi

    echo "Status: active"
    echo
    echo "Loaded virtual cable modules:"
    pactl list short modules | awk '
        $2 == "module-loopback" && $0 ~ /(^|[ \t])source=virtspk\.monitor([ \t]|$)/ { print "  " $0 }
        $2 == "module-remap-source" && $0 ~ /(^|[ \t])source_name=virtmic([ \t]|$)/ { print "  " $0 }
        $2 == "module-null-sink" && $0 ~ /(^|[ \t])sink_name=(virtspk|virtmic)([ \t]|$)/ { print "  " $0 }
    '
}

ACTION="start"
ENABLE_LOOPBACK="true"

for arg in "$@"; do
    case "${arg}" in
        start|stop|restart|status)
            ACTION="${arg}"
            ;;
        --no-loopback)
            ENABLE_LOOPBACK="false"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option or command: ${arg}" >&2
            usage >&2
            exit 1
            ;;
    esac
done

require_pulseaudio

case "${ACTION}" in
    start)
        start_cables "${ENABLE_LOOPBACK}"
        ;;
    stop)
        stop_cables
        ;;
    restart)
        stop_cables
        start_cables "${ENABLE_LOOPBACK}"
        ;;
    status)
        status_cables
        ;;
esac
