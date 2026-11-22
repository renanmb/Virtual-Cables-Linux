#!/usr/bin/env bash
# Automated container-safe test & conformance suite for Virtual-Cables-Linux.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo "=== 1. Bash Syntax & Executable Permission Checks ==="
for script in \
    virtual-cables-pulseaudio.sh \
    virtual-cable-pipewire.sh \
    .devcontainer/init_agent_workspace.sh \
    tests/test_virtual_cables.sh; do
    bash -n "${script}"
    if [[ ! -x "${script}" ]]; then
        echo "[FAIL] ${script} is not executable" >&2
        exit 1
    fi
    echo "[PASS] ${script} (syntax + executable)"
done

if command -v shellcheck >/dev/null 2>&1; then
    echo "=== 1b. ShellCheck Lint ==="
    shellcheck virtual-cables-pulseaudio.sh .devcontainer/init_agent_workspace.sh tests/test_virtual_cables.sh
    echo "[PASS] shellcheck"
fi

echo "=== 2. PulseAudio Script Mock E2E Lifecycle Checks ==="
TMPMOCK="$(mktemp -d)"
trap 'rm -rf "${TMPMOCK}"' EXIT

cat <<'EOF' > "${TMPMOCK}/pactl"
#!/usr/bin/env bash
set -euo pipefail
STATE="${TMPMOCK_STATE}"
touch "${STATE}"
case "$1" in
  info)
    if [[ "${TMPMOCK_DOWN:-0}" == "1" ]]; then
      exit 1
    fi
    echo "Server Name: pulseaudio"
    echo "Default Sink: alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo"
    ;;
  load-module)
    shift
    MOD="$1"; shift
    ID=$(( $(wc -l < "${STATE}") + 27 ))
    printf "%s\t%s\t%s\t\n" "${ID}" "${MOD}" "$*" >> "${STATE}"
    echo "${ID}"
    ;;
  unload-module)
    awk -v id="$2" '$1 != id' "${STATE}" > "${STATE}.tmp" && mv "${STATE}.tmp" "${STATE}"
    ;;
  list)
    if [[ "$2" == "short" && "$3" == "modules" ]]; then
      cat "${STATE}"
    elif [[ "$2" == "short" && "$3" == "sinks" ]]; then
      printf "1\talsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo\n"
      awk '$2 == "module-null-sink" && match($0, /sink_name=[^ \t]+/) { print "2\t" substr($0, RSTART+10, RLENGTH-10) }' "${STATE}"
    elif [[ "$2" == "short" && "$3" == "sources" ]]; then
      awk '$2 == "module-remap-source" && match($0, /source_name=[^ \t]+/) { print "3\t" substr($0, RSTART+12, RLENGTH-12) }' "${STATE}"
    fi
    ;;
esac
EOF
chmod +x "${TMPMOCK}/pactl"

# 2a. Help output
./virtual-cables-pulseaudio.sh --help >/dev/null
echo "[PASS] --help"

# 2b. Graceful error when PulseAudio server is unreachable
if PATH="${TMPMOCK}:${PATH}" TMPMOCK_STATE="${TMPMOCK}/state" TMPMOCK_DOWN=1 ./virtual-cables-pulseaudio.sh status >/dev/null 2>&1; then
    echo "[FAIL] Expected non-zero exit when PulseAudio server is unreachable" >&2
    exit 1
fi
echo "[PASS] Unreachable PulseAudio error handling"

# 2c. Start (3 modules: null-sink, remap-source, loopback)
PATH="${TMPMOCK}:${PATH}" TMPMOCK_STATE="${TMPMOCK}/state" ./virtual-cables-pulseaudio.sh start >/dev/null
[[ "$(wc -l < "${TMPMOCK}/state")" -eq 3 ]]
echo "[PASS] start loads 3 modules (virtspk, virtmic, loopback)"

# 2d. Idempotent repeat start does not stack duplicate modules
PATH="${TMPMOCK}:${PATH}" TMPMOCK_STATE="${TMPMOCK}/state" ./virtual-cables-pulseaudio.sh start >/dev/null
[[ "$(wc -l < "${TMPMOCK}/state")" -eq 3 ]]
echo "[PASS] idempotent start prevents duplicate sinks"

# 2e. Restart with --no-loopback (2 modules)
PATH="${TMPMOCK}:${PATH}" TMPMOCK_STATE="${TMPMOCK}/state" ./virtual-cables-pulseaudio.sh restart --no-loopback >/dev/null
[[ "$(wc -l < "${TMPMOCK}/state")" -eq 2 ]]
echo "[PASS] restart --no-loopback loads 2 modules"

# 2f. Stop removes all virtual cable modules
PATH="${TMPMOCK}:${PATH}" TMPMOCK_STATE="${TMPMOCK}/state" ./virtual-cables-pulseaudio.sh stop >/dev/null
[[ "$(wc -l < "${TMPMOCK}/state")" -eq 0 ]]
echo "[PASS] stop unloads all virtual cable modules"

echo "=== 3. .agents Workspace Conformance Audit ==="
python3 - <<'PY'
import pathlib, re, subprocess

root = pathlib.Path.cwd()
checks = {
    "AGENTS.md exists": (root / "AGENTS.md").is_file(),
    "CLAUDE.md imports @AGENTS.md": (root / "CLAUDE.md").is_file() and "@AGENTS.md" in (root / "CLAUDE.md").read_text(),
    ".agent relative symlink": (root / ".agent").is_symlink() and not (root / ".agent").readlink().is_absolute() and (root / ".agent").exists(),
    ".claude/skills relative symlink": (root / ".claude/skills").is_symlink() and not (root / ".claude/skills").readlink().is_absolute() and (root / ".claude/skills").exists(),
    ".agents 4 pillars exist": all((root / ".agents" / d).is_dir() for d in ("memory", "references", "scratch", "skills")),
    ".agents/skills symlinks relative & valid": all(
        not p.readlink().is_absolute() and p.exists()
        for p in (root / ".agents/skills").iterdir() if p.is_symlink()
    ),
}

probe = root / ".agents/skills/_external_probe/SKILL.md"
probe.parent.mkdir(parents=True, exist_ok=True)
probe.write_text("probe\n")
try:
    ignored_ext = subprocess.run(["git", "check-ignore", "-q", str(probe.relative_to(root))]).returncode == 0
    tracked_ok = all(
        subprocess.run(["git", "check-ignore", "-q", p]).returncode != 0
        for p in (
            "AGENTS.md",
            "CLAUDE.md",
            ".agent",
            ".claude/skills",
            ".agents/skills/commit-and-pr",
            ".agents/skills/run-tests",
            ".agents/skills/dev-container",
            ".agents/skills/setup-virtual-cables",
            ".agents/skills/session-memory/SKILL.md",
        )
    )
    checks["gitignore ignores external skills & keeps first-party"] = ignored_ext and tracked_ok
finally:
    probe.unlink(missing_ok=True)
    probe.parent.rmdir()

bad_link_re = re.compile(r"\]\((?:file://|/[^)\s]+)")
rel_link_re = re.compile(r"\]\(([^)#\s]+)")
bad_links = []
broken_links = []
for md in list((root / ".agents").rglob("*.md")) + list((root / "skills").rglob("*.md")) + [root / "AGENTS.md", root / "README.md"]:
    if md.is_file():
        stripped = re.sub(r"```.*?```", "", md.read_text(errors="ignore"), flags=re.S)
        stripped_no_inline = re.sub(r"`[^`]*`", "", stripped)
        if bad_link_re.search(stripped_no_inline):
            bad_links.append(str(md.relative_to(root)))
        for m in rel_link_re.finditer(stripped_no_inline):
            target = m.group(1)
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            if not (md.parent / target).resolve().exists():
                broken_links.append(f"{md.relative_to(root)} -> {target}")
checks["zero absolute or file-URI Markdown links"] = len(bad_links) == 0
checks["all relative Markdown links resolve on disk"] = len(broken_links) == 0

for name, ok in checks.items():
    print(f"[{'PASS' if ok else 'FAIL'}] {name}")
if bad_links:
    print("  Violating files:", bad_links)
if broken_links:
    print("  Broken links:", broken_links)
assert all(checks.values()), "One or more conformance checks failed"
PY

echo "=== All Checks Passed ==="
