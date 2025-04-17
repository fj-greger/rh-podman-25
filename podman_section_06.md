# Podman Lernmaterial

---

## 6 - Building and Running Multi-Container Applications (Pods)

### 6 - Building and Running Multi-Container Applications (Pods)

Moderne Applikationen bestehen oft aus mehreren zusammenarbeitenden Diensten (Microservices), z.B. einem Web Frontend, einem Backend API und einer Database. Solche **Multi-Container Applications** erfordern ein koordiniertes Management der einzelnen Container, insbesondere hinsichtlich ihres Netzwerks und Lifecycles.

#### Grundlagen des Podman Networking

Bevor wir uns Pods genauer ansehen, ist es wichtig, einige grundlegende Netzwerk-Konzepte in Podman zu verstehen, da Pods diese nutzen:

*   **Network Namespace:** Jeder Container läuft standardmäßig in seinem eigenen isolierten Netzwerk-Namespace mit eigener IP-Adresse, Routing-Tabelle etc., getrennt vom Host und anderen Containern.
*   **Default Bridge Network (`podman`):** Ohne spezielle Konfiguration werden Container mit diesem Netzwerk verbunden. Sie erhalten eine IP, können aber standardmäßig nicht direkt über Namen kommunizieren. Ausgehende Verbindungen sind möglich.
*   **Port Mapping (`-p HOST:CONTAINER`):** Ermöglicht externen Zugriff auf einen Container-Dienst über einen Host-Port.

#### User-Defined Networks für verbesserte Kommunikation

Für eine bessere Kontrolle und einfachere Kommunikation zwischen Containern, die *nicht* in einem Pod laufen, können Sie eigene Netzwerke erstellen. Der Hauptvorteil ist das **eingebaute DNS**: Podman stellt für jedes benutzerdefinierte Netzwerk einen internen DNS-Server bereit. Container, die mit demselben benutzerdefinierten Netzwerk verbunden sind, können sich gegenseitig über ihren **Containernamen** als Hostnamen erreichen. Podman registriert den Namen und die IP-Adresse jedes Containers bei diesem netzwerkspezifischen DNS-Dienst.

**Syntax:** `podman network create [OPTIONS] NAME`

---

> ##### Exercise 1: Container Communication via Custom Network
>
> Diese Übung demonstriert die Namensauflösung in einem benutzerdefinierten Netzwerk. Wir starten einen Nginx-Server und einen Client-Container und lassen den Client den Server über seinen Namen kontaktieren.
>
> **Schritte:**
>
> 1.  **Aufräumen (Vorher):** Stoppen und entfernen Sie zuerst alle möglicherweise vorhandenen alten Ressourcen mit diesen Namen, um Konflikte zu vermeiden.
>     ```bash
>     # Stop and remove potentially conflicting resources
>     podman stop webserver client
>     podman rm webserver client
>     podman network rm my-web-net
>     ```
> 2.  **Netzwerk erstellen:** Erstellen Sie ein neues Bridge-Netzwerk namens `my-web-net` und überprüfen Sie dessen Erstellung.
>     ```bash
>     # Create a new bridge network
>     podman network create my-web-net
>
>     # Verify network creation
>     podman network ls
>     ```
> 3.  **Nginx-Server starten:** Starten Sie einen Nginx-Container im Hintergrund, verbunden mit dem neuen Netzwerk. Ein Port-Mapping ist nicht nötig, da wir nur intern zugreifen.
>     ```bash
>     # Start an Nginx container attached to the custom network
>     podman run -d --network my-web-net --name webserver nginx:alpine
>     ```
> 4.  **Client-Container starten:** Starten Sie einen Alpine-Container, der dauerhaft läuft (`sleep infinity`), ebenfalls im selben Netzwerk.
>     ```bash
>     # Start an Alpine container that runs indefinitely
>     podman run -d --network my-web-net --name client alpine sleep infinity
>     ```
> 5.  **Container überprüfen:** Zeigen Sie die laufenden Container an; `webserver` und `client` sollten sichtbar sein.
>     ```bash
>     # List running containers
>     podman ps
>     ```
> 6.  **Kommunikation testen (via `exec`):** Führen Sie Befehle innerhalb des `client`-Containers aus. Installieren Sie zuerst `curl` (nicht standardmäßig in Alpine enthalten) und verwenden Sie es dann, um die Webseite vom `webserver` über dessen Namen abzurufen.
>     ```bash
>     # Execute commands inside the 'client' container
>     # a) Install 'curl'
>     podman exec client apk add --no-cache curl
>
>     # b) Use 'curl' to access the 'webserver' by its name
>     podman exec client curl http://webserver
>     ```
>     **Erwartete Ausgabe:** Sie sollten den HTML-Quellcode der Nginx-Standard-Willkommensseite sehen. Dies bestätigt die Namensauflösung und Kommunikation über das benutzerdefinierte Netzwerk.
> 7.  **Netzwerk inspizieren:** Zeigen Sie Details zum Netzwerk und den verbundenen Containern an.
>     ```bash
>     # Inspect the network to see connected containers
>     podman network inspect my-web-net
>     ```
> 8.  **Aufräumen (Nachher):** Stoppen und entfernen Sie die Container und das Netzwerk.
>     ```bash
>     # Stop the containers
>     podman stop webserver client
>     # Remove the containers
>     podman rm webserver client
>     # Remove the network
>     podman network rm my-web-net
>     ```
>
> Diese Übung zeigt, wie benutzerdefinierte Netzwerke die Kommunikation zwischen Containern vereinfachen.

---

#### Einführung in Pods

Pods gruppieren Container, die wichtige Ressourcen wie den **Network Namespace** teilen.

*   **Network Namespace:** Alle Container im Pod teilen sich IP-Adresse und Port-Raum, können über `localhost` kommunizieren. Ports werden auf Pod-Ebene gemappt.

Ein unsichtbarer **Infra-Container** hält den Namespace aufrecht.

#### Sharing Other Namespaces (Optional)

Mit `--share NAMESPACE` können auch andere Namespaces (`pid`, `ipc`, `uts`) geteilt werden für engere Kopplung.

*   **`pid`:** Gemeinsame Prozess-Sichtbarkeit und Signalversand.
*   **`ipc`:** Gemeinsame Inter-Process Communication Ressourcen.
*   **`uts`:** Gemeinsamer Hostname/Domainname.

> **Pod: 'db-app-pod' (IP: 10.x.x.x, Port 5000->Host 8080)**
>
> > Container: 'webapp'
> > (Lauscht auf :5000)
> > -> localhost:3306
>
> > Container: 'database'
> > (Lauscht auf :3306)
>
> > Infra Container (dotted border)
>
> Visualisierung eines Pods mit geteiltem Netzwerk.

> **Info: `|| true`:** Unterdrückt Fehler, wenn ein Kommando fehlschlägt (z.B. beim Entfernen nicht existierender Ressourcen).

---

> ##### Exercise 2: Creating a Multi-Container Pod (Flask + MySQL)
>
> Erstellung eines Pods mit einer Flask-Webanwendung und einer MySQL-Datenbank, die über `localhost` kommunizieren.
>
> ##### Step 1: Creating a Pod
>
> Stellen Sie sicher, dass Host-Port 8080 frei ist und räumen Sie alte Ressourcen auf.
>
> > **Wichtig: Cleanup!** Entfernen Sie alle früheren Pods/Container mit diesen Namen oder Ports.
> > ```bash
> > # Stop and remove previous resources
> > podman pod rm -f db-app-pod
> > podman stop webapp database
> > podman rm webapp database
> > podman volume rm mysql_data # Remove potentially existing volume
> > ```
>
> Erstellen Sie einen leeren Pod namens `db-app-pod` und mappen Sie Host-Port 8080 auf Pod-Port 5000.
> ```bash
> # Create an empty pod named 'db-app-pod', mapping host port 8080 to pod port 5000
> podman pod create --name db-app-pod -p 8080:5000
> ```
> Prüfen Sie die erstellten Pods.
> ```bash
> # List existing pods
> podman pod ps
> ```
>
> ##### Step 2: Running Containers inside the Pod
>
> Fügen Sie Container mit `podman run --pod <pod_name> ...` hinzu.
>
> 1.  **Datenbank-Container (MySQL) starten:** Erstellen Sie ein Volume für persistente Daten und starten Sie den MySQL-Container im Pod. Achten Sie auf die Umgebungsvariablen.
>     ```bash
>     # Create a volume for MySQL data (if it doesn't exist)
>     podman volume create mysql_data
>     # Optional: Verify volume creation
>     podman volume ls | grep mysql_data
>
>     # Start the MySQL container inside the pod, using the volume
>     # Note the environment variables for configuration
>     podman run -d --pod db-app-pod --name database \
>         -v mysql_data:/var/lib/mysql \
>         -e MYSQL_ROOT_PASSWORD=mysecretpassword \
>         -e MYSQL_DATABASE=webappdb \
>         mysql:8.0
>     ```
>     > **Hinweis zu Underscores:** Achten Sie auf korrekte Underscores in Variablennamen.
>     **Wichtig:** Warten Sie auf die DB-Initialisierung (~10-20s+). Beobachten Sie die Logs mit `podman logs -f database` bis "ready for connections" erscheint.
>
> 2.  **Web-Applikations-Container (Flask) starten:** Starten Sie den Flask-App-Container (aus Topic 5) im selben Pod.
>     ```bash
>     # Start the Flask application container inside the pod
>     # Ensure the image 'my-flask-app:1.1' exists
>     podman run -d --pod db-app-pod --name webapp \
>         -e MYSQL_ROOT_PASSWORD=mysecretpassword \
>         -e MYSQL_DATABASE=webappdb \
>         -e GREETING="Pod App" \
>         my-flask-app:1.1
>     ```
>     *   Die App verbindet sich mit `localhost:3306` (MySQL im selben Pod).
>     *   Sie lauscht auf Port 5000, der auf Host 8080 gemappt ist.
>
> ##### Step 3: Verify the Setup and Communication
>
> Überprüfen Sie den Pod und die laufenden Container.
> ```bash
> # List pods
> podman pod ps
> # List containers associated with pods
> podman ps --pod
> # List all containers (including infra) associated with pods
> podman ps -a --pod
> ```
> Zeigen Sie detaillierte Pod-Informationen an.
> ```bash
> # Inspect the pod for details
> podman pod inspect db-app-pod
> ```
> Testen Sie die Webanwendung. Warten Sie kurz, damit die App Zeit zum Starten hat.
> ```bash
> # Wait a few seconds for the app to initialize
> sleep 5
> # Access the web application via the mapped host port
> curl http://localhost:8080
> ```
> **Erwartetes Ergebnis:** "Pod App from Container ID..." und Zählerstand.
>
> ##### Step 4: Verify Data Persistence within the Pod
>
> Testen der Datenbank-Persistenz über einen Pod-Neustart.
> 1.  Verbinden Sie sich mit der Datenbank via `exec`.
>     ```bash
>     # Execute mysql client inside the database container
>     podman exec -it database mysql -uroot -pmysecretpassword webappdb
>     ```
> 2.  Erstellen Sie eine Tabelle und fügen Sie Testdaten ein.
>     ```sql
>     # SQL commands to create a table and insert data
>     CREATE TABLE IF NOT EXISTS pod_test (id INT PRIMARY KEY, message VARCHAR(50));
>     INSERT INTO pod_test (id, message) VALUES (1, 'Hello from Pod!') ON DUPLICATE KEY UPDATE message='Hello again!';
>     SELECT * FROM pod_test;
>     exit
>     ```
> 3.  Starten Sie den gesamten Pod neu.
>     ```bash
>     # Restart the entire pod
>     podman pod restart db-app-pod
>     ```
> 4.  Verbinden Sie sich erneut und überprüfen Sie die Daten. Warten Sie nach dem Neustart einen Moment, bis die Datenbank wieder bereit ist.
>     ```bash
>     # Wait for the database to become ready after restart
>     sleep 15
>     # Execute a query inside the database container to verify data persistence
>     podman exec -it database mysql -uroot -pmysecretpassword webappdb -e "SELECT * FROM pod_test;"
>     ```
>     Die Daten sollten noch vorhanden sein.
>
> ##### Step 5: Managing the Pod Lifecycle & Resources
>
> Pod als Einheit verwalten:
> *   **Auflisten:** `podman pod ps` / `ls`
> *   **Inspizieren:** `podman pod inspect <pod_name|id>`
> *   **Stoppen:** `podman pod stop <pod_name|id>`
> *   **Starten:** `podman pod start <pod_name|id>`
> *   **Neustarten:** `podman pod restart <pod_name|id>`
> *   **Beenden (erzwungen):** `podman pod kill <pod_name|id>`
> *   **Entfernen:** `podman pod rm <pod_name|id>` (nach Stop)
> *   **Logs anzeigen:** `podman pod logs <pod_name|id>`
> *   **Statistiken anzeigen:** `podman pod stats <pod_name|id>`
> *   **Prozesse anzeigen:** `podman pod top <pod_name|id>`
>
> Entfernen Sie abschließend den Pod und das Volume für diese Übung.
> ```bash
> # Cleanup for this exercise
> podman pod rm -f db-app-pod
> podman volume rm mysql_data
> ```

---

> ##### Exercise 3: 3-Tier Pod (Text API, Frontend, Logger Sidecar) with Healthchecks
>
> Ein Pod mit API, Frontend (Nginx Proxy) und Logger, inklusive Healthchecks.
> **Wichtig:** Erstellen Sie die Verzeichnisse und Dateien manuell.
>
> **1. Vorbereitung: Verzeichnisse und Dateien erstellen**
> *   `api/` (`requirements.txt`, `app.py`, `Containerfile`)
> *   `frontend/` (`index.html`, `script.js`, `nginx.conf`, `Containerfile`)
>
> **2. Dateien mit Inhalt füllen:**
> **Datei: `api/requirements.txt`**
> ```nohighlight
> Flask>=2.3
> Flask-CORS>=4.0
> ```
> **Datei: `api/app.py`** (Mit `/health` Endpunkt)
> ```python
> # ... (Python code as before) ...
> import random
> from flask import Flask, jsonify
> from flask_cors import CORS
> import time
> import os
> import signal
> import sys
>
> app = Flask(__name__)
> CORS(app) # Allow Cross-Origin requests
>
> # Simple text snippets
> text_snippets = [
>     "Podman makes containers easy!",
>     "Pods share a network namespace.",
>     "Communication via localhost is possible in a pod.",
>     "This is sample text from the API.",
>     "Containerization is efficient."
> ]
>
> # Graceful shutdown handler
> def handle_signal(signum, frame):
>     print(f'Received signal {signum}, shutting down gracefully...')
>     sys.exit(0)
>
> signal.signal(signal.SIGTERM, handle_signal)
> signal.signal(signal.SIGINT, handle_signal)
>
> @app.route('/text', methods=['GET'])
> def get_text():
>     snippet = random.choice(text_snippets)
>     container_id = os.uname().nodename # Hostname often is the (short) container ID
>     response_text = f"{snippet} (from {container_id})"
>     print(f"API [{container_id}] served: {snippet}") # Log in container
>     time.sleep(0.1) # Simulate work
>     return jsonify({"text": response_text})
>
> # --- NEW: Health Check Endpoint ---
> @app.route('/health', methods=['GET'])
> def health_check():
>     # Simple health check endpoint
>     return jsonify({"status": "ok"}), 200
>
> if __name__ == '__main__':
>     print("Starting Text API server on port 5001...")
>     app.run(host='0.0.0.0', port=5001, use_reloader=False)
> ```
> **Datei: `api/Containerfile`** (Mit `curl` Installation und `HEALTHCHECK`)
> ```dockerfile
> # ... (Dockerfile content as before) ...
> FROM python:3.12-slim
> LABEL maintainer="Podman Training" version="1.1" description="Simple Text API with Healthcheck"
>
> # --- NEW: Install curl for the Healthcheck ---
> RUN apt-get update \
>     && apt-get install -y --no-install-recommends curl \
>     && apt-get clean \
>     && rm -rf /var/lib/apt/lists/*
>
> WORKDIR /app
> COPY requirements.txt .
> RUN pip install --no-cache-dir -r requirements.txt
> COPY app.py .
> EXPOSE 5001
>
> # --- NEW: Define the Healthcheck ---
> HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
>   CMD curl -f http://localhost:5001/health || exit 1
>
> CMD ["python", "app.py"]
> ```
> **Datei: `frontend/index.html`**
> ```html
> <!DOCTYPE html>
> <html lang="de">
> <head>
>     <meta charset="UTF-8">
>     <title>Text Frontend</title>
>     <style>
>         body { font-family: sans-serif; padding: 20px; }
>         #textDisplay { margin-top: 15px; padding: 15px; background-color: #e9ecef; border-radius: 5px; min-height: 40px; font-style: italic; }
>         button { padding: 10px 15px; cursor: pointer; }
>         #error { color: red; margin-top: 10px; font-weight: bold; }
>     </style>
> </head>
> <body>
>     <h1>Text von der API</h1>
>     <button onclick="fetchText()">Neuen Text holen</button>
>     <div id="textDisplay">...</div>
>     <div id="error"></div>
>     <script src="script.js"></script>
> </body>
> </html>
> ```
> **Datei: `frontend/nginx.conf`** (Mit Logging)
> ```nginx
> # ... (Nginx config as before) ...
> upstream api_server {
>     server localhost:5001;
> }
>
> server {
>     listen 80;
>     server_name localhost;
>
>     access_log /var/log/nginx/access.log;
>     error_log /var/log/nginx/error.log warn;
>
>     location / {
>         root   /usr/share/nginx/html;
>         index  index.html index.htm;
>         try_files $uri $uri/ /index.html;
>     }
>
>     location /api/ {
>         proxy_pass http://api_server/;
>         proxy_set_header Host $host;
>         proxy_set_header X-Real-IP $remote_addr;
>         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
>         proxy_set_header X-Forwarded-Proto $scheme;
>         proxy_connect_timeout 5s;
>         proxy_send_timeout 10s;
>         proxy_read_timeout 10s;
>         proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
>         proxy_next_upstream_timeout 5s;
>         proxy_next_upstream_tries 3;
>     }
>
>     error_page   500 502 503 504  /50x.html;
>     location = /50x.html {
>         root   /usr/share/nginx/html;
>     }
> }
> ```
> **Datei: `frontend/script.js`** (Mit verbesserter Fehlerbehandlung)
> ```javascript
> // ... (JavaScript code as before) ...
> const apiUrl = '/api/text';
> const textDisplay = document.getElementById('textDisplay');
> const errorDiv = document.getElementById('error');
>
> async function fetchText() {
>     errorDiv.textContent = '';
>     textDisplay.textContent = 'Loading...';
>     let controller;
>     try {
>         controller = new AbortController();
>         const timeoutId = setTimeout(() => { console.warn('Request timed out.'); controller.abort(); }, 8000);
>
>         const response = await fetch(apiUrl, { signal: controller.signal });
>         clearTimeout(timeoutId);
>
>         if (!response.ok) {
>              let errorDetails = '';
>              try { errorDetails = await response.text(); } catch (e) {}
>              let errorMsg = `HTTP error! Status: ${response.status} ${response.statusText}`;
>              if (errorDetails) { errorMsg += ` - Response: ${errorDetails.substring(0, 150)}...`; }
>              throw new Error(errorMsg);
>         }
>         const data = await response.json();
>         textDisplay.textContent = data.text;
>     } catch (error) {
>         console.error('Error fetching text:', error);
>         let userMessage = `Error: ${error.message}. `;
>          if (error.name === 'AbortError') { userMessage += 'Timeout (>8s). Is the API running and responding quickly? Check `podman logs text-api`.'; }
>          else if (error instanceof TypeError && error.message.includes('fetch')) { userMessage += 'Network error or connection refused. Can the browser reach localhost:8089? Is `text-frontend` running?'; }
>          else if (error.message.includes('502')) { userMessage += 'Bad Gateway - Nginx (`text-frontend`) could not get a valid response from the API (`text-api` at localhost:5001). Is `text-api` running and healthy? Check `podman ps --pod` and logs (`podman logs text-api`, `podman logs text-frontend`).'; }
>          else if (error.message.includes('504')) { userMessage += 'Gateway Timeout - The API (`text-api`) took too long to respond. Check `podman logs text-api` for slow operations or errors.'; }
>          else if (error instanceof SyntaxError || (error.message && error.message.toLowerCase().includes('json'))) { userMessage += 'Invalid JSON response from API. Check `podman logs text-api` for errors. Did the API return HTML or unexpected text?'; }
>          else { userMessage += 'Unknown error. Check browser console (F12) and container logs (`podman logs text-api`, `podman logs text-frontend`).'; }
>         errorDiv.textContent = userMessage;
>         textDisplay.textContent = 'Error loading data.';
>     }
> }
> document.addEventListener('DOMContentLoaded', fetchText);
> ```
> **Datei: `frontend/Containerfile`** (Mit `HEALTHCHECK`)
> ```dockerfile
> # ... (Dockerfile content as before) ...
> FROM nginx:1.25-alpine
> LABEL maintainer="Podman Training" version="1.2" description="Simple Text Frontend with API Proxy and Healthcheck"
>
> RUN rm /etc/nginx/conf.d/default.conf
> COPY nginx.conf /etc/nginx/conf.d/default.conf
> COPY index.html /usr/share/nginx/html/
> COPY script.js /usr/share/nginx/html/
> EXPOSE 80
>
> # --- NEW: Healthcheck for Nginx ---
> HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
>   CMD pgrep nginx || exit 1
> ```
>
> **3. Images bauen (mit `--format docker`)**
>
> Bauen Sie die Images für API und Frontend. Denken Sie daran, `--format docker` zu verwenden, damit die `HEALTHCHECK`-Anweisung funktioniert.
>
> > **Wichtig: `--format docker`!**
>
> ```bash
> # Build the API image (Docker format required for HEALTHCHECK)
> podman build --format docker -t my-text-api:latest ./api
>
> # Build the Frontend image (Docker format required for HEALTHCHECK)
> podman build --format docker -t my-text-frontend:latest ./frontend
>
> # Verify image creation
> podman images | grep my-text-
> ```
>
> **4. Pod und Container starten**
>
> Stellen Sie sicher, dass der Host-Port 8089 frei ist. Räumen Sie zuerst alle möglicherweise vorhandenen alten Ressourcen auf.
> ```bash
> # Cleanup: Remove old pod and specific containers if they exist
> podman pod rm -f text-app-pod
> podman rm -f text-api text-frontend text-logger
> ```
> 1.  Erstellen Sie den Pod namens `text-app-pod`, der Host-Port 8089 auf Pod-Port 80 mappt.
>     ```bash
>     # Create the Pod
>     podman pod create --name text-app-pod -p 8089:80
>     ```
> 2.  Starten Sie den **API-Container** (`text-api`) innerhalb des Pods.
>     ```bash
>     # Start the API container
>     podman run -d --pod text-app-pod --name text-api my-text-api:latest
>     ```
> 3.  Starten Sie den **Frontend-Container** (`text-frontend`) innerhalb des Pods.
>     ```bash
>     # Start the Frontend container
>     podman run -d --pod text-app-pod --name text-frontend my-text-frontend:latest
>     ```
> 4.  Starten Sie den **Logger-Sidecar-Container** (`text-logger`) innerhalb des Pods.
>     ```bash
>     # Start the Logger sidecar container
>     podman run -d --pod text-app-pod --name text-logger alpine /bin/sh -c "while true; do echo Logger: \$(date); sleep 10; done"
>     ```
> 5.  Überprüfen Sie den Pod-Status. Warten Sie etwa 20 Sekunden, damit die Container starten und die ersten Healthchecks ausgeführt werden können.
>     ```bash
>     # Wait for containers to start and initial health checks
>     sleep 20
>
>     # Check pod status overview
>     podman pod ps
>     ```
>     Listen Sie die laufenden Container im Pod auf und achten Sie auf den Gesundheitszustand (`(healthy)`).
>     ```bash
>     # List running containers within the pod, including health status
>     podman ps --pod --filter status=running
>     ```
>     Überprüfen Sie gezielt, ob Container als `unhealthy` markiert sind (die Ausgabe sollte leer sein).
>     ```bash
>     # Specifically check for any unhealthy containers (should be empty)
>     podman ps --pod --filter health=unhealthy
>     ```
>
> **5. Anwendung testen**
>
> > **Hinweis:** Es dauert nach dem Start einige Sekunden (`start-period` + `interval`), bis der Status in `podman ps` von `(starting)` zu `(healthy)` wechselt. Bei Fehlern, warten Sie 20-30 Sekunden und laden Sie die Seite neu.
>
> Öffnen Sie [http://localhost:8089](http://localhost:8089) im Browser.
> *   Die Weboberfläche sollte erscheinen.
> *   Ein Text von der API sollte angezeigt werden. Stellen Sie sicher, dass `text-api` und `text-frontend` in `podman ps` den Status `(healthy)` haben.
> *   Klicken Sie auf "Neuen Text holen".
> *   Prüfen Sie die Logger-Ausgabe: `podman logs text-logger`.
> *   Bei Fehlern, überprüfen Sie Health Status und Logs:
>     *   `podman ps --pod`: Sind Container `running` und `(healthy)`?
>     *   `podman healthcheck run text-api` (Erfolg = Exit Code 0?)
>     *   `podman healthcheck run text-frontend` (Erfolg = Exit Code 0?)
>     *   `podman logs text-api` (Python-Fehler?)
>     *   `podman logs text-frontend` (Nginx-Fehler?)
>
> **6. Kommunikationsfluss verstehen (mit Reverse Proxy)**
>
> Der Ablauf ist wie zuvor, aber Healthchecks überwachen zusätzlich den Zustand der Dienste.
> *   Browser -> Port 8089 -> Nginx (`text-frontend`).
> *   Nginx -> `localhost:5001` -> Flask API (`text-api`).
> *   Flask API antwortet -> Nginx antwortet -> Browser.
> *   Podman prüft parallel den `/health` Endpunkt der API und den `nginx` Prozess im Frontend.
>
> **Pod-Struktur (mit Healthchecks):**
> > **Pod: 'text-app-pod' (IP: 10.x.x.y, Port 80->Host 8089)**
> >
> > > Container: 'text-frontend' (Nginx)
> > > (Lauscht auf :80)
> > > -> localhost:5001
> > > **(HEALTHCHECK: pgrep nginx)**
> >
> > > Container: 'text-api' (Flask)
> > > (Lauscht auf :5001)
> > > **(HEALTHCHECK: curl /health)**
> >
> > > Container: 'text-logger' (Alpine)
> > > (Läuft unabhängig)
> > > (Kein Healthcheck definiert)
> >
> > > Infra Container (dotted border)
> >
> > **Erläuterung:** Der Kommunikationsfluss ist wie zuvor. Zusätzlich führt Podman die definierten Healthchecks für 'text-frontend' und 'text-api' aus, um deren Zustand zu überwachen.
>
> **7. Aufräumen**
>
> Stoppen und entfernen Sie den Pod und die zugehörigen Container.
> ```bash
> # Stop and remove the pod and its containers
> podman pod rm -f text-app-pod
>
> # Optionally remove the built images
> # podman image rm my-text-api:latest my-text-frontend:latest
> ```
> Diese Übung demonstrierte einen Pod mit Healthchecks zur Überwachung der Dienste.

---

> ##### Exercise 4: Setting Pod-Level Resource Limits
>
> Festlegen von Ressourcenlimits (Speicher, CPU) für einen gesamten Pod.
>
> ##### Step 1: Create a Pod with Resource Limits
>
> Räumen Sie zuerst alte Ressourcen auf.
> ```bash
> # Cleanup potentially conflicting resources
> podman pod rm -f limited-pod
> podman rm -f limited-c1 limited-c2
> ```
> Erstellen Sie einen Pod mit einem Speicherlimit von 200MB und einem CPU-Limit von 1.0 Kernen. Beachten Sie, dass die **zuverlässige Durchsetzung** dieser Limits auf Pod-Ebene eine funktionierende **cgroup v2** Hierarchie auf Ihrem System voraussetzt, insbesondere im rootless Modus.
>
> > **Hinweis: cgroup v2 Abhängigkeit für Pod-Limits**
> >
> > Die Flags `--memory` und `--cpus` für `podman pod create` setzen Ressourcenlimits für den gesamten Pod. Damit diese Limits korrekt durchgesetzt werden, benötigt Podman (besonders im rootless Betrieb) die moderne cgroup v2 Funktionalität Ihres Linux-Kernels. Auf Systemen mit cgroup v1 funktionieren Pod-Level-Limits möglicherweise nicht wie erwartet.
> >
> > Sie können prüfen, ob Ihr System cgroup v2 verwendet (oft standardmäßig bei neueren Linux-Distributionen), z.B. mit: `stat -fc %T /sys/fs/cgroup/` (Ausgabe sollte `cgroup2fs` sein).
>
> ```bash
> # Create a pod with memory and CPU limits (Requires cgroup v2 for enforcement)
> podman pod create --name limited-pod \
>   --memory 200m \
>   --cpus 1.0 \
>   -p 8082:80
> ```
> **Hinweis:** Das Port-Mapping `-p 8082:80` ist hier nur optional.
>
> ##### Step 2: Add Containers to the Limited Pod
>
> Fügen Sie zwei einfache Alpine-Container hinzu, die nur im Hintergrund laufen.
> ```bash
> # Start simple containers inside the limited pod
> podman run -d --pod limited-pod --name limited-c1 alpine sleep infinity
> podman run -d --pod limited-pod --name limited-c2 alpine sleep infinity
> ```
>
> ##### Step 3: Inspect Pod Limits and Stats
>
> Überprüfen Sie die angewendeten Limits. Wie in Schritt 1 erwähnt, hängt die Durchsetzung von cgroup v2 ab. Das Inspizieren der Konfiguration des einzelnen Infra-Containers zeigt die Pod-Level-Limits möglicherweise nicht direkt an, auch wenn sie durch die Pod-Cgroup erzwungen werden.
> ```bash
> # Find the ID of the pod's infra container
> INFRA_ID=$(podman pod inspect limited-pod | jq -r '.[0].InfraContainerID')
>
> # Inspect the infra container's configuration
> # Note: With cgroup v2, these values might not reflect the actual enforced pod-level limits.
> podman inspect ${INFRA_ID} | jq '.[0].HostConfig | {Memory: .Memory, NanoCpus: .NanoCpus, CpuQuota: .CpuQuota, CpuPeriod: .CpuPeriod}'
> ```
> Falls der obere Befehl fehlschlägt, hier die Variante 2:
> ```bash
> # Find the ID of the pod's infra container
> INFRA_ID=$(podman pod inspect limited-pod | jq -r '.InfraContainerID')
>
> # Inspect the infra container's configuration
> # Note: With cgroup v2, these values might not reflect the actual enforced pod-level limits.
> podman inspect ${INFRA_ID} | jq '.[0].HostConfig | {Memory: .Memory, NanoCpus: .NanoCpus, CpuQuota: .CpuQuota, CpuPeriod: .CpuPeriod}'
> ```
> Die bevorzugte Methode zur Überwachung der Ressourcennutzung im Verhältnis zu den Pod-Limits ist `podman pod stats`.
>
> > **Wichtiger Hinweis zu `podman pod stats` und cgroup v2:**
> >
> > *   Wie die Durchsetzung der Limits selbst, benötigt auch der Befehl `podman pod stats` eine funktionierende **cgroup v2** Hierarchie, um aggregierte Statistiken und Limits korrekt anzuzeigen, insbesondere im **rootless Modus**.
> > *   Ohne cgroup v2 erhalten Sie wahrscheinlich einen Fehler wie:
> >     `Error: pod stats is not supported in rootless mode without cgroups v2`
>
> Führen Sie den Befehl aus, um die Statistiken anzuzeigen (setzt funktionierendes cgroup v2 voraus):
> ```bash
> # Display pod resource usage statistics (CPU%, MEM USAGE / LIMIT)
> # This command requires cgroup v2 for accurate reporting and limit display.
> podman pod stats limited-pod --no-stream
> ```
> **Observe:** Wenn cgroup v2 verfügbar ist, zeigt die Ausgabe die kombinierte Nutzung und die gesetzten Pod-Limits. Die Limits sollten auch tatsächlich durchgesetzt werden.
>
> ##### Step 4: Clean Up
>
> Entfernen Sie den Pod.
> ```bash
> # Remove the pod
> podman pod rm -f limited-pod
> ```
> Limits auf Pod-Ebene helfen bei der Verwaltung von Ressourcengruppen, sind aber von cgroup v2 abhängig.

---

> ##### Exercise 5: Sharing the PID Namespace (`--share pid`)
>
> Demonstriert, wie Container in einem Pod den PID-Namespace teilen.
>
> ##### Step 1: Create a Pod with Shared PID Namespace
>
> Räumen Sie alte Ressourcen auf.
> ```bash
> # Cleanup potentially conflicting resources
> podman pod rm -f pid-share-pod
> podman rm -f process-holder process-viewer
> ```
> Erstellen Sie einen Pod mit der Option `--share pid`.
> ```bash
> # Create a pod sharing the PID namespace
> podman pod create --name pid-share-pod --share pid
> ```
>
> ##### Step 2: Run a Container with a Long-Running Process
>
> Starten Sie einen Container, der einfach nur schläft.
> ```bash
> # Start a container that just sleeps
> podman run -d --pod pid-share-pod --name process-holder alpine sleep 3600
> ```
>
> ##### Step 3: Run a Second Container to View Processes
>
> Starten Sie einen temporären Container im selben Pod und listen Sie alle Prozesse auf, die im geteilten PID-Namespace sichtbar sind.
> ```bash
> # Run a temporary container in the pod to list processes
> podman run --rm --pod pid-share-pod --name process-viewer alpine ps aux
> ```
> **Observe:** Sie sollten den `ps aux`-Prozess und den `sleep 3600`-Prozess sehen.
>
> ##### Step 4: Send a Signal Between Containers
>
> Da die Prozesse sichtbar sind, kann ein Container Signale an Prozesse in einem anderen Container senden.
> 1.  **PID identifizieren:** Sehen Sie sich die Ausgabe von `ps aux` aus Schritt 3 genau an. Finden Sie die Zeile, die den Befehl `sleep 3600` enthält. Die Zahl in der zweiten Spalte dieser Zeile ist die Prozess-ID (PID) des Schlafprozesses.
>     ```bash
>     # Führen Sie diesen Befehl erneut aus, falls Sie die Ausgabe nicht mehr sehen:
>     podman run --rm --pod pid-share-pod --name process-viewer-again alpine ps aux
>     ```
>     *Beispielausgabe (Ihre PIDs werden anders sein):*
>     ```nohighlight
>     PID   USER     TIME  COMMAND
>         1 root      0:00 /pause
>         8 root      0:00 sleep 3600  <-- Suchen Sie diese Zeile, die PID hier ist '8'
>        15 root      0:00 ps aux
>     ```
> 2.  **Signal senden:** Starten Sie nun einen weiteren temporären Container im Pod. Verwenden Sie den Befehl `kill` zusammen mit der PID, die Sie gerade identifiziert haben, um ein Signal (standardmäßig TERM) an den `sleep`-Prozess zu senden. Ersetzen Sie `<PID>` im folgenden Befehl durch die tatsächliche Nummer aus Ihrer Ausgabe.
>     ```bash
>     # Ersetzen Sie <PID> durch die gefundene Prozess-ID von 'sleep 3600'
>     # Beispiel: Wenn die PID 8 war, führen Sie 'kill 8' aus
>     podman run --rm --pod pid-share-pod alpine kill <PID>
>     ```
>     (Wenn `kill` ohne Signalnummer verwendet wird, sendet es standardmäßig SIGTERM (15), was normalerweise ausreicht, um den Prozess zu beenden. `kill -9 <PID>` würde SIGKILL senden.)
> 3.  **Status überprüfen:** Überprüfen Sie den Status des `process-holder`-Containers. Da sein Hauptprozess (`sleep 3600`) das TERM-Signal erhalten und sich beendet hat, sollte der gesamte Container ebenfalls beendet sein.
>     ```bash
>     # Prüfen Sie den Status des Containers (sollte 'Exited' sein)
>     podman ps --filter name=process-holder --all
>     ```
>     **Observe:** Der Container `process-holder` sollte nun den Status "Exited" haben, was bestätigt, dass der Signalversand vom einen Container zum Prozess im anderen erfolgreich war.
>
> ##### Step 5: Clean Up
>
> Entfernen Sie den Pod.
> ```bash
> # Remove the pod
> podman pod rm -f pid-share-pod
> ```
> Das Teilen von Namespaces ermöglicht fortgeschrittene Interaktionen.

---

#### Declarative Management Approaches

Für komplexere Setups sind deklarative Ansätze besser:

*   **`podman play kube` (Kubernetes YAML):** Bevorzugt. Siehe **Topic 9**.
*   **`podman-compose` (Compose YAML):** Externes Tool. Siehe **Topic 8**.

> #### Best Practices: Pods & Multi-Container Apps
>
> *   **Pods** für eng gekoppelte Container (Netzwerk, Lifecycle).
> *   **Nicht alles in einen Pod;** lose Kopplung -> separate Pods/Netzwerke.
> *   **Deklaratives Management** bevorzugen (Kube YAML, Compose).
> *   **Health Checks** definieren (`HEALTHCHECK` im Containerfile mit `--format docker`, oder in Kube YAML).
> *   **Persistenz** via Volumes sichern.
> *   **Secrets Management** verwenden.
> *   **Ressourcenlimits** definieren (Pod-Level Limits erfordern cgroup v2 für zuverlässige Durchsetzung).
> *   Pods und Container **benennen**.
> *   **Explizites Aufräumen** vor Neuerstellung (`podman rm -f`, `podman pod rm -f`).

### Key Takeaways

*   Pods gruppieren Container mit geteiltem Network Namespace (`localhost`). Andere Namespaces (`pid`, `ipc`, `uts`) optional via `--share`.
*   Ports werden auf Pod-Ebene gemappt (`podman pod create -p`).
*   Ressourcenlimits auf Pod-Ebene (`podman pod create --memory/--cpus`) erfordern **cgroup v2** für zuverlässige Durchsetzung, besonders rootless.
*   Container hinzufügen mit `podman run --pod <pod_name> ...`.
*   `HEALTHCHECK` im Containerfile (benötigt `--format docker`) für automatische Zustandsprüfungen (Status in `podman ps`, manuell mit `podman healthcheck run`).
*   `podman pod stats` zur Überwachung von Pod-Ressourcen benötigt ebenfalls **cgroup v2**.
*   Vorhandene Container können `podman run` blockieren; mit `podman rm -f` aufräumen.
*   Pod-Management mit `podman pod` Subbefehlen.
*   Deklarative Ansätze (`play kube`, `compose`) sind oft Best Practice.