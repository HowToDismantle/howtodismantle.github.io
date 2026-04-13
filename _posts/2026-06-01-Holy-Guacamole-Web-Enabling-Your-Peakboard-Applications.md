---
layout: post
title: Holy Guacamole - Web-Enabling Your Peakboard Applications
date: 2023-03-01 00:00:00 +0200
tags: administration
image: /assets/2026-06-01/title.png
image_header: /assets/2026-06-01/title.png
bg_alternative: true
read_more_links:
  - name: Look Ma, No GUI! Automating Peakboard Installs from the Command Line
    url: /Look-Ma-No-GUI-Automating-Peakboard-Installs-from-the-Command-Line.html
  - name: Side-by-Side - Making Peakboard BYOD Play Nice among other Windows Apps
    url: /Side-by-Side-Making-Peakboard-BYOD-Play-Nice-among-other-Windows-Apps.html
  - name: Apache Guacamole Project
    url: https://guacamole.apache.org/
downloads:
  - name: guacamole-setup.sh
    url: /assets/2026-06-01/guacamole-setup.sh
---
Here's a question that comes up surprisingly often: Can we show a Peakboard dashboard in a web browser without installing anything on the viewer's machine? The answer is yes, and the secret ingredient is Apache Guacamole, a clientless remote desktop gateway that turns any RDP session into a browser-accessible HTML5 stream. No plugins, no Java applets, no client software at all. Just a URL.

In this article, we'll walk through the entire setup: a Windows VM running the Peakboard BYOD Runtime in Azure, a Linux VM running Guacamole, and a clean landing page that auto-connects visitors straight to the live dashboard. The Peakboard installation itself is covered in the [command line installation article](/Look-Ma-No-GUI-Automating-Peakboard-Installs-from-the-Command-Line.html), so we'll focus on the Guacamole side of things here.

## The architecture

The setup involves two VMs talking to each other inside the same Azure virtual network:

{% highlight text %}
[Browser] --> [GuacServer:80 Nginx] --> [GuacServer:8080 Guacamole] --> [PeakboardVM:3389 RDP]
{% endhighlight %}

**PeakboardVM** is a Windows 11 VM running the Peakboard BYOD Runtime. It has auto-login configured so the desktop is always ready with the runtime running. **GuacServer** is a lightweight Ubuntu VM running Apache Guacamole via Docker. Nginx sits in front as a reverse proxy, serving a branded landing page at the root and proxying Guacamole requests behind the scenes.

The beauty of this approach is that the browser user never knows they're looking at an RDP session. They just see the dashboard.

![The end result: A Peakboard dashboard running in a plain browser window, fully interactive, no client software needed.](/assets/2026-06-01/peakboard-dashboard-browser-guacamole-rdp-session.png)

## Setting up the Guacamole server

Here's what the resource group looks like in the Azure portal with both VMs and their associated resources:

![The Azure resource group containing both the PeakboardVM and the GuacServer with all their network components.](/assets/2026-06-01/azure-resource-group-peakboard-guacamole-vms.png)

We need a Linux VM. Nothing fancy, a Standard_B2s (2 vCPUs, 4 GB RAM) on Ubuntu 24.04 LTS is more than enough. After creating the VM, we install Docker:

{% highlight bash %}
apt-get update -qq
apt-get install -y ca-certificates curl
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
apt-get install -y docker-ce docker-ce-cli \
  containerd.io docker-compose-plugin
{% endhighlight %}

## The Docker Compose stack

Guacamole consists of three components that we run as Docker containers: **guacd** (the connection daemon that speaks RDP, VNC, and SSH), **guacamole** (the Java web application), and **MySQL** (for storing connections and user accounts). We add **Nginx** as a fourth container to serve our landing page and reverse-proxy to Guacamole.

{% highlight yaml %}
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
      MYSQL_ROOT_PASSWORD: YourRootPassword
      MYSQL_DATABASE: guacamole_db
      MYSQL_USER: guacamole_user
      MYSQL_PASSWORD: YourGuacPassword
    volumes:
      - mysql-data:/var/lib/mysql
      - ./initdb:/docker-entrypoint-initdb.d
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
      MYSQL_PASSWORD: YourGuacPassword
    ports: ["8080:8080"]
    networks: [guac-net]

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: always
    ports: ["80:80"]
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - ./html:/usr/share/nginx/html
    depends_on: [guacamole]
    networks: [guac-net]

volumes:
  mysql-data:
networks:
  guac-net:
    driver: bridge
{% endhighlight %}

## Initializing the database

Before we spin up the stack, we need to generate the Guacamole database schema. The Guacamole Docker image ships with a handy script for that:

{% highlight bash %}
mkdir -p initdb
docker run --rm guacamole/guacamole \
  /opt/guacamole/bin/initdb.sh --mysql > initdb/001-schema.sql
{% endhighlight %}

This gives us the complete schema including tables for users, connections, and permissions. MySQL picks up any `.sql` file in `/docker-entrypoint-initdb.d` on first start, so we just need to drop our files in the `initdb` folder.

## Pre-configuring the RDP connection

Here's where things get interesting. Instead of logging into Guacamole and manually creating a connection, we can bake it right into the database initialization. We create a second SQL file that runs after the schema:

{% highlight sql %}
USE guacamole_db;

INSERT INTO guacamole_connection (connection_name, protocol)
  VALUES ('Peakboard RDP', 'rdp');

SET @cid = LAST_INSERT_ID();

INSERT INTO guacamole_connection_parameter
  (connection_id, parameter_name, parameter_value) VALUES
  (@cid, 'hostname',    '10.0.0.4'),
  (@cid, 'port',        '3389'),
  (@cid, 'username',    'YourUser'),
  (@cid, 'password',    'YourPassword'),
  (@cid, 'security',    'nla'),
  (@cid, 'ignore-cert', 'true'),
  (@cid, 'width',       '1920'),
  (@cid, 'height',      '1080'),
  (@cid, 'dpi',         '96');

INSERT INTO guacamole_connection_permission
  (entity_id, connection_id, permission)
  SELECT entity_id, @cid, 'READ'
  FROM guacamole_entity WHERE name = 'guacadmin';
{% endhighlight %}

We use the private IP (`10.0.0.4`) because both VMs sit in the same Azure virtual network. The `ignore-cert` parameter is set to `true` because we're connecting to a self-signed RDP certificate. The resolution is set to 1920x1080, but we can adjust that to whatever fits the dashboard best.

## Setting up Nginx

Nginx does double duty: it serves our landing page at `/` and proxies everything under `/guacamole/` to the Guacamole web application. The WebSocket upgrade headers are essential here because Guacamole uses WebSockets for the live session stream:

{% highlight nginx %}
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
{% endhighlight %}

The `proxy_read_timeout` of 86400 seconds (24 hours) prevents Nginx from killing idle connections. Without that, the RDP session would drop after the default 60-second timeout.

## The auto-connect landing page

We don't want visitors to see the Guacamole login screen. Instead, we build a complete HTML page that authenticates against the Guacamole API behind the scenes and immediately loads the RDP session in a full-viewport iframe. This page goes into the `html` folder that Nginx serves at the root. Here's the full `index.html`:

{% highlight html %}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
      content="width=device-width, initial-scale=1.0">
    <title>Peakboard Runtime Demo</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont,
              "Segoe UI", Roboto, sans-serif;
            background: #1a1a2e; color: #e0e0e0;
            height: 100vh;
            display: flex; flex-direction: column;
        }
        header {
            background: #16213e; padding: 12px 24px;
            display: flex; align-items: center;
            justify-content: space-between;
            border-bottom: 2px solid #0f3460;
            flex-shrink: 0;
        }
        header h1 {
            font-size: 1.3rem; font-weight: 600;
            color: #e94560; letter-spacing: 0.5px;
        }
        header .status {
            font-size: 0.85rem; color: #53c28b;
            display: flex; align-items: center; gap: 6px;
        }
        header .status::before {
            content: ""; width: 8px; height: 8px;
            background: #53c28b; border-radius: 50%;
            display: inline-block;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.4; }
        }
        #loading {
            flex: 1; display: flex; flex-direction: column;
            align-items: center; justify-content: center;
            gap: 20px;
        }
        #loading .spinner {
            width: 48px; height: 48px;
            border: 4px solid #0f3460;
            border-top-color: #e94560;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        #loading p { color: #8899aa; font-size: 0.95rem; }
        #rdp-frame {
            flex: 1; border: none;
            width: 100%; display: none;
        }
        footer {
            background: #16213e; padding: 8px 24px;
            text-align: center; font-size: 0.75rem;
            color: #556677;
            border-top: 1px solid #0f3460;
            flex-shrink: 0;
        }
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
    <footer>
        Powered by <a href="https://peakboard.com"
          target="_blank">Peakboard</a>
    </footer>

    <script>
        async function connect() {
            const statusEl = document.getElementById("status");
            const loadingEl = document.getElementById("loading");
            const frameEl = document.getElementById("rdp-frame");

            try {
                // Get auth token from Guacamole API
                const resp = await fetch("/guacamole/api/tokens", {
                    method: "POST",
                    headers: { "Content-Type":
                      "application/x-www-form-urlencoded" },
                    body: "username=guacadmin&password=guacadmin"
                });
                const data = await resp.json();
                const token = data.authToken;

                // Look up available connections
                const connResp = await fetch(
                    "/guacamole/api/session/data/mysql/connections"
                    + "?token=" + token);
                const connections = await connResp.json();
                const connId = Object.keys(connections)[0];

                if (!connId) {
                    statusEl.textContent = "No connection configured";
                    statusEl.style.color = "#e94560";
                    return;
                }

                // Build the Guacamole client identifier
                // Format: Base64(connectionId + \0 + "c" + \0 + "mysql")
                const clientId = btoa(connId + "\0c\0mysql")
                    .replace(/\+/g, "-")
                    .replace(/\//g, "_")
                    .replace(/=/g, ".");

                // Load the session into the iframe
                frameEl.src = "/guacamole/#/client/"
                    + clientId + "?token=" + token;

                loadingEl.style.display = "none";
                frameEl.style.display = "block";
                statusEl.textContent = "Connected";
            } catch (err) {
                statusEl.textContent = "Connection failed - retrying...";
                statusEl.style.color = "#e9a645";
                setTimeout(connect, 5000);
            }
        }

        // Wait a few seconds for Guacamole to be ready
        setTimeout(connect, 3000);
    </script>
</body>
</html>
{% endhighlight %}

The page has a dark header with a status indicator, a loading spinner that shows while the connection is being established, and a full-viewport iframe where the RDP session appears. The JavaScript handles the entire authentication flow: it grabs a session token from the Guacamole REST API, looks up the first available connection, builds the client identifier (a URL-safe Base64-encoded string combining the connection ID, the type `c` for connection, and the data source `mysql`), and loads the Guacamole client into the iframe. If the connection fails, it retries every five seconds.

## Preparing the Windows VM

For a seamless experience, the Windows VM needs to auto-login so that the desktop and the Peakboard Runtime are always ready when someone connects. We set this up through the Windows registry:

{% highlight powershell %}
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path $regPath -Name "DefaultUserName" -Value "YourUser"
Set-ItemProperty -Path $regPath -Name "DefaultPassword" -Value "YourPassword"
{% endhighlight %}

We also want the Peakboard Runtime to launch automatically at login. The cleanest way is a registry entry in the Run key:

{% highlight powershell %}
Set-ItemProperty `
  -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
  -Name "PeakboardRuntime" `
  -Value '"C:\Program Files\Peakboard\Runtime\Peakboard.Runtime.WPF.exe"'
{% endhighlight %}

Once the Peakboard management ports are open, the VM shows up in the Peakboard Designer just like any other box. We can upload applications, monitor the runtime, and manage everything remotely, while Guacamole handles the browser-facing side independently.

![The PeakboardVM appearing in the Peakboard Designer with a live preview of the running dashboard.](/assets/2026-06-01/peakboard-designer-remote-vm-box-settings.png)

## Firewall and network security

On the Azure side, we need to open the right ports. The Guacamole server needs ports 80 and 443 (HTTP/HTTPS) open to the public. The Windows VM needs port 3389 (RDP) accessible from within the virtual network, but not necessarily from the public internet, since Guacamole connects over the private network. We should also open the Peakboard management ports (40404, 40405, 40408, 40409) if we want to manage the runtime remotely via the Peakboard Designer.

## Launching and testing

Once everything is in place, we start the stack with a single command:

{% highlight bash %}
cd /opt/guacamole
docker compose up -d
{% endhighlight %}

After about 30 seconds for the containers to initialize and MySQL to process the init scripts, we can verify that everything is running:

{% highlight text %}
$ docker ps
NAMES        STATUS                 PORTS
nginx        Up 2 hours             0.0.0.0:80->80/tcp
guacamole    Up 2 hours             0.0.0.0:8080->8080/tcp
guac-mysql   Up 2 hours             3306/tcp, 33060/tcp
guacd        Up 2 hours (healthy)   4822/tcp
{% endhighlight %}

All four containers should be running and `guacd` should report as healthy. Now we can point a browser at the server's public IP. The landing page loads, auto-authenticates against Guacamole, and a few seconds later, the Peakboard dashboard appears right there in the browser, fully interactive with mouse and keyboard support.

## Wrapping up

What we end up with is a zero-install, browser-based window into a live Peakboard dashboard. The viewer doesn't need RDP, doesn't need any Peakboard software, and doesn't even need to know that there's a Windows machine behind the scenes. They just open a URL and see the dashboard.

The complete setup script is available for download below. It takes care of the entire Guacamole installation, including Docker, the database, the Nginx proxy, and the landing page. Just pass the RDP host, username, and password as arguments and you're good to go.
