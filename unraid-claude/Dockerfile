# Claude Code, served as a browser terminal, for managing an Unraid server.
#
# Ships: Node (for @anthropic-ai/claude-code), ttyd (web terminal), tmux
# (persistent sessions so you can reconnect from your phone), the Docker CLI
# (to manage other containers via the mounted docker.sock), plus ssh/git and
# the everyday diagnostic tools Claude will reach for.
FROM node:22-bookworm-slim

ARG TTYD_VERSION=1.7.7

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git openssh-client tmux jq less nano vim-tiny \
        iproute2 iputils-ping dnsutils procps rsync unzip \
    # Docker CLI only (no daemon) — it talks to the host's docker.sock.
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli \
    # ttyd static binary (web terminal front-end).
    && curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.$(uname -m)" \
        -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLI.
RUN npm install -g @anthropic-ai/claude-code

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Guardrails template, seeded into /workspace/CLAUDE.md on first run.
COPY claude-guardrails.md /opt/claude/CLAUDE.md

WORKDIR /workspace
EXPOSE 7681
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
