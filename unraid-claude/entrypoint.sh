#!/usr/bin/env bash
# Launch Claude Code inside a persistent tmux session and expose it over a
# password-protected web terminal. Reconnecting (e.g. from your phone) drops
# you back into the same running session instead of a fresh one.
set -euo pipefail

WORKDIR="${WORKDIR:-/workspace}"
TTYD_PORT="${TTYD_PORT:-7681}"
SESSION="claude"

cd "$WORKDIR"

# Seed the Unraid guardrails file into the workspace on first run so Claude
# always reads it. Edit /workspace/CLAUDE.md on the host to customise.
if [[ ! -f "$WORKDIR/CLAUDE.md" && -f /opt/claude/CLAUDE.md ]]; then
    cp /opt/claude/CLAUDE.md "$WORKDIR/CLAUDE.md"
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "WARNING: ANTHROPIC_API_KEY is not set — Claude Code will not authenticate." >&2
fi

# Start (or reuse) a detached tmux session running Claude Code. When Claude
# exits you land in a shell rather than killing the session.
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -c "$WORKDIR" \
        'claude || echo "claude exited — type \"claude\" to restart."; exec bash -l'
fi

# ttyd auth: set TTYD_CREDENTIAL="user:pass" (strongly recommended). Even so,
# only expose port 7681 over Tailscale / your LAN — never to the internet.
AUTH_ARGS=()
if [[ -n "${TTYD_CREDENTIAL:-}" ]]; then
    AUTH_ARGS+=(-c "$TTYD_CREDENTIAL")
else
    echo "WARNING: TTYD_CREDENTIAL unset — the web terminal has NO password." >&2
fi

exec ttyd -p "$TTYD_PORT" -W "${AUTH_ARGS[@]}" \
    tmux attach-session -t "$SESSION"
