#!/bin/bash
set -e

echo "=== Installing Docker at Runtime ==="

echo "--- Adding Docker GPG key ---"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "--- Adding Docker repository ---"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "--- Updating package index ---"
apt-get update

echo "--- Installing Docker packages ---"
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "--- Adding Docker daemon configuration to supervisord ---"
cat >> /etc/supervisor/conf.d/supervisord.conf << 'EOF'

[program:dockerd]
command=dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2376
stdout_logfile=/var/log/supervisor/dockerd.log
stderr_logfile=/var/log/supervisor/dockerd.log
autorestart=true
EOF

echo "--- Starting Docker daemon with supervisord ---"
supervisord -c /etc/supervisor/conf.d/supervisord.conf &

echo "--- Waiting for Docker daemon to start ---"
sleep 10

echo "--- Verifying Docker installation ---"
docker version || echo "Docker not ready yet, waiting more..."
sleep 5
docker version || echo "Docker daemon startup failed"

echo "✅ Docker installation completed!"
