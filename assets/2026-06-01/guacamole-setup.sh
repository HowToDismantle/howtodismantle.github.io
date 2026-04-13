#!/bin/bash
# ============================================================
# Guacamole Setup Script for Azure VM
# Sets up Apache Guacamole with Docker Compose,
# Nginx reverse proxy, and a branded landing page.
# ============================================================

set -e

GUAC_DIR="/opt/guacamole"
RDP_HOST="${1:-10.0.0.4}"
RDP_USER="${2:-YourUser}"
RDP_PASS="${3:-YourPassword}"
MYSQL_ROOT_PW="GuacR00tPw_$(openssl rand -hex 4)"
MYSQL_USER_PW="GuacDbPw_$(openssl rand -hex 4)"

echo "=== Guacamole Setup ==="
echo "RDP Target: $RDP_HOST"
echo "RDP User:   $RDP_USER"
echo ""

# --- Install Docker ---
echo "[1/5] Installing Docker..."
apt-get update -qq
apt-get install -y -qq ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo ${VERSION_CODENAME}) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli \
  containerd.io docker-compose-plugin
systemctl enable docker && systemctl start docker
echo "Docker $(docker --version) installed."

# --- Create directory structure ---
echo "[2/5] Creating directory structure..."
mkdir -p $GUAC_DIR/{initdb,nginx,html}

# --- Generate Guacamole DB schema ---
echo "[3/5] Generating database schema..."
docker run --rm guacamole/guacamole \
  /opt/guacamole/bin/initdb.sh --mysql \
  > $GUAC_DIR/initdb/001-schema.sql

# --- Create connection SQL ---
cat > $GUAC_DIR/initdb/002-connection.sql << ENDSQL
USE guacamole_db;
INSERT INTO guacamole_connection (connection_name, protocol)
  VALUES ('Peakboard RDP', 'rdp');
SET @cid = LAST_INSERT_ID();
INSERT INTO guacamole_connection_parameter
  (connection_id, parameter_name, parameter_value) VALUES
  (@cid, 'hostname',    '$RDP_HOST'),
  (@cid, 'port',        '3389'),
  (@cid, 'username',    '$RDP_USER'),
  (@cid, 'password',    '$RDP_PASS'),
  (@cid, 'security',    'nla'),
  (@cid, 'ignore-cert', 'true'),
  (@cid, 'width',       '1920'),
  (@cid, 'height',      '1080'),
  (@cid, 'dpi',         '96');
INSERT INTO guacamole_connection_permission
  (entity_id, connection_id, permission)
  SELECT entity_id, @cid, 'READ'
  FROM guacamole_entity WHERE name = 'guacadmin';
ENDSQL

# --- Create Docker Compose ---
cat > $GUAC_DIR/docker-compose.yml << ENDYML
version: "3.8"
services:
  guacd:
    image: guacamole/guacd:latest
    container_name: guacd
    restart: always
    networks: [guac-net]

  mysql:
    image: mysql:8.0
    container_name: guac-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PW
      MYSQL_DATABASE: guacamole_db
      MYSQL_USER: guacamole_user
      MYSQL_PASSWORD: $MYSQL_USER_PW
    volumes:
      - mysql-data:/var/lib/mysql
      - $GUAC_DIR/initdb:/docker-entrypoint-initdb.d
    networks: [guac-net]

  guacamole:
    image: guacamole/guacamole:latest
    container_name: guacamole
    restart: always
    depends_on: [guacd, mysql]
    environment:
      GUACD_HOSTNAME: guacd
      MYSQL_HOSTNAME: mysql
      MYSQL_DATABASE: guacamole_db
      MYSQL_USER: guacamole_user
      MYSQL_PASSWORD: $MYSQL_USER_PW
    ports: ["8080:8080"]
    networks: [guac-net]

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: always
    ports: ["80:80"]
    volumes:
      - $GUAC_DIR/nginx/default.conf:/etc/nginx/conf.d/default.conf
      - $GUAC_DIR/html:/usr/share/nginx/html
    depends_on: [guacamole]
    networks: [guac-net]

volumes:
  mysql-data:
networks:
  guac-net:
    driver: bridge
ENDYML

# --- Create Nginx config ---
cat > $GUAC_DIR/nginx/default.conf << 'ENDNGINX'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /guacamole/ {
        proxy_pass http://guacamole:8080/guacamole/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }
}
ENDNGINX

# --- Create landing page ---
cat > $GUAC_DIR/html/index.html << 'ENDHTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Peakboard Runtime Demo</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont,
              "Segoe UI", Roboto, sans-serif;
            background: #1a1a2e; color: #e0e0e0;
            height: 100vh; display: flex; flex-direction: column;
        }
        header {
            background: #16213e; padding: 12px 24px;
            display: flex; align-items: center;
            justify-content: space-between;
            border-bottom: 2px solid #0f3460; flex-shrink: 0;
        }
        header h1 { font-size: 1.3rem; font-weight: 600;
            color: #e94560; letter-spacing: 0.5px; }
        header .status { font-size: 0.85rem; color: #53c28b;
            display: flex; align-items: center; gap: 6px; }
        header .status::before {
            content: ""; width: 8px; height: 8px;
            background: #53c28b; border-radius: 50%;
            display: inline-block; animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; } 50% { opacity: 0.4; }
        }
        #loading { flex: 1; display: flex; flex-direction: column;
            align-items: center; justify-content: center; gap: 20px; }
        #loading .spinner { width: 48px; height: 48px;
            border: 4px solid #0f3460; border-top-color: #e94560;
            border-radius: 50%; animation: spin 1s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }
        #loading p { color: #8899aa; font-size: 0.95rem; }
        #rdp-frame { flex: 1; border: none;
            width: 100%; display: none; }
        footer { background: #16213e; padding: 8px 24px;
            text-align: center; font-size: 0.75rem;
            color: #556677; border-top: 1px solid #0f3460;
            flex-shrink: 0; }
        footer a { color: #e94560; text-decoration: none; }
    </style>
</head>
<body>
    <header>
        <h1>Peakboard Runtime Demo</h1>
        <div class="status" id="status">Connecting...</div>
    </header>
    <div id="loading">
        <div class="spinner"></div>
        <p>Connecting to Peakboard Runtime...</p>
    </div>
    <iframe id="rdp-frame" allowfullscreen></iframe>
    <footer>Powered by <a href="https://peakboard.com"
      target="_blank">Peakboard</a></footer>
    <script>
        async function connect() {
            const s = document.getElementById("status");
            const l = document.getElementById("loading");
            const f = document.getElementById("rdp-frame");
            try {
                const r = await fetch("/guacamole/api/tokens", {
                    method: "POST",
                    headers: {"Content-Type":
                      "application/x-www-form-urlencoded"},
                    body: "username=guacadmin&password=guacadmin"
                });
                const d = await r.json();
                const cr = await fetch(
                  "/guacamole/api/session/data/mysql/connections?token="
                  + d.authToken);
                const c = await cr.json();
                const id = Object.keys(c)[0];
                if (!id) { s.textContent = "No connection"; return; }
                const cid = btoa(id + "\0c\0mysql")
                  .replace(/\+/g,"-").replace(/\//g,"_")
                  .replace(/=/g,".");
                f.src = "/guacamole/#/client/" + cid
                  + "?token=" + d.authToken;
                l.style.display = "none";
                f.style.display = "block";
                s.textContent = "Connected";
            } catch(e) {
                s.textContent = "Retrying...";
                s.style.color = "#e9a645";
                setTimeout(connect, 5000);
            }
        }
        setTimeout(connect, 3000);
    </script>
</body>
</html>
ENDHTML

# --- Start everything ---
echo "[4/5] Starting containers..."
cd $GUAC_DIR
docker compose up -d

echo "[5/5] Waiting for services..."
sleep 30

echo ""
echo "=== Setup Complete ==="
echo "Landing page: http://$(curl -s ifconfig.me)"
echo "Guacamole:    http://$(curl -s ifconfig.me)/guacamole/"
echo "Default login: guacadmin / guacadmin"
echo ""
echo "MySQL root password:     $MYSQL_ROOT_PW"
echo "MySQL guac user password: $MYSQL_USER_PW"
echo ""
echo "IMPORTANT: Change the default guacadmin password!"
