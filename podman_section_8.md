# Podman Lernmaterial

---

## 8 - Using Podman Compose

### 8 - Using Podman Compose

Während `podman play kube` (siehe nächstes Topic) Kubernetes YAML nutzt, bietet **`podman-compose`** eine Alternative für Nutzer, die mit der **Docker Compose** Syntax vertrauter sind. Es ist ein separates, community-getriebenes Python-Tool, das versucht, eine ähnliche Erfahrung wie `docker-compose` für Podman bereitzustellen.

Es liest eine `docker-compose.yml` oder `compose.yaml` Datei (standardmäßig im aktuellen Verzeichnis) und übersetzt die Anweisungen in Podman-Befehle, oft indem es implizit einen Pod für die definierten Dienste erstellt.

#### Installation von `podman-compose`

`podman-compose` ist nicht Teil von Podman selbst und muss separat installiert werden. Die empfohlene Methode ist die Verwendung des Paketmanagers Ihrer Distribution.

**Methode 1: System Package Manager (Empfohlen)**

Prüfen Sie, ob `podman-compose` in den Repositories Ihrer Distribution verfügbar ist:

<u>Für Debian/Ubuntu:</u>
```bash
sudo apt update
sudo apt install podman-compose
```

<u>Für Fedora:</u>
```bash
sudo dnf install podman-compose
```

**Methode 2: `pipx` (Gute Alternative für isolierte Installation)**

`pipx` installiert Python CLI-Tools in isolierten Umgebungen.

1.  Installieren Sie `pipx` (falls nötig):
    ```bash
    sudo apt update && sudo apt install pipx # Debian/Ubuntu
    # Oder: sudo dnf install pipx # Fedora
    ```
    Stellen Sie sicher, dass der Pfad von `pipx` in Ihrer `PATH`-Variable enthalten ist:
    ```bash
    pipx ensurepath
    ```
    (Evtl. Shell neu starten).
2.  Installieren Sie `podman-compose` mit `pipx`:
    ```bash
    pipx install podman-compose
    ```

**Methode 3: `pip` (Kann zu Fehlern führen!)**

Die direkte Installation mit `pip install podman-compose` kann fehlschlagen (PEP 668).
```bash
pip install podman-compose
```

> **Fehler "externally-managed-environment":** Verwenden Sie stattdessen Methode 1 (apt/dnf) oder Methode 2 (pipx).

**Überprüfung der Installation:**
```bash
podman-compose --version
```
Sollte die installierte Version anzeigen.

> **Hinweis zur Kompatibilität:** `podman-compose` ist ein Community-Projekt und hinkt möglicherweise hinter Docker Compose oder Podman her. Testen ist wichtig.

---

> ##### Exercise 1: Using `podman-compose up` and `down`
>
> Wir definieren unsere Web-App + Datenbank-Anwendung aus Topic 6 nun in einer Compose-Datei und starten sie.
>
> ##### Step 1: Create `compose.yaml`
>
> Erstellen Sie eine Datei namens `compose.yaml` im Projektverzeichnis:
> ```yaml
> version: '3.8'
>
> services:
>   webapp:
>     image: my-flask-app:1.1 # Aus Topic 5
>     container_name: compose-webapp
>     ports:
>       - "8080:5000"
>     environment:
>       MYSQL_ROOT_PASSWORD: mysecretpassword
>       MYSQL_DATABASE: webappdb
>       GREETING: "Hello from Compose"
>     volumes:
>       - compose_flask_data:/data # Mounts the named volume
>     depends_on:
>       - database
>
>   database:
>     image: mysql:8.0
>     container_name: compose-database
>     environment:
>       MYSQL_ROOT_PASSWORD: mysecretpassword
>       MYSQL_DATABASE: webappdb
>     volumes:
>       - compose_mysql_data:/var/lib/mysql # Mounts the named volume
>
> # Definition der benannten Volumes (Top Level)
> volumes:
>   compose_mysql_data:
>   compose_flask_data:
> ```
> **Wie funktionieren die Volumes hier?** Die Top-Level Sektion `volumes:` deklariert die benannten Volumes. `podman-compose up` weist Podman an, diese automatisch zu erstellen, falls sie nicht existieren. Die Service-Level `volumes:` hängen diese Podman-verwalteten Volumes dann in den Container ein.
>
> ##### Step 2: Start the Application with `podman-compose up -d`
>
> Stellen Sie sicher, dass keine anderen Container/Pods die Ports oder Namen verwenden.
>
> > **Wichtig: Port/Namens-Konflikt & Cleanup!**
> > ```bash
> > # Ggf. vorherige Pods/Container stoppen/entfernen
> > podman pod rm -f db-app-pod projectname_default # Ersetze projectname ggf.
> > podman stop compose-webapp compose-database
> > podman rm compose-webapp compose-database
> > podman volume rm -f compose_mysql_data compose_flask_data
> > ```
>
> Führen Sie im Verzeichnis mit der `compose.yaml` Datei aus:
>
> **Befehl:** `podman-compose up -d`
> *   `up`: Dieser Befehl erstellt (falls nicht vorhanden) die Netzwerke, Volumes und Container, die in der `compose.yaml` definiert sind, und startet die Container. Wenn die Container bereits existieren, aber gestoppt sind, startet er sie neu. Wenn sie bereits laufen, führt er ggf. Aktualisierungen durch (z.B. wenn sich das Image geändert hat und kein `build:` verwendet wird).
> *   `-d`: (Detached Mode) Führt die Container im Hintergrund aus und gibt die Kontrolle an Ihr Terminal zurück. Ohne `-d` würden die Logs aller Container im Vordergrund angezeigt.
>
> ```bash
> podman-compose up -d
> ```
> `podman-compose` erstellt nun implizit einen Pod, die benötigten Volumes und startet die Container.
>
> ##### Step 3: Verify the Setup (`ps`, `logs`)
>
> Überprüfen Sie die von `podman-compose` verwalteten Dienste:
>
> **Befehl:** `podman-compose ps`
> *   Zeigt den Status der Dienste an, die in der aktuellen `compose.yaml`-Datei definiert und von `podman-compose` gestartet wurden.
>
> ```bash
> podman-compose ps
> ```
> Überprüfen Sie die zugrundeliegenden Podman-Ressourcen:
> ```bash
> podman ps --pod
> podman pod ps
> podman volume ls
> ```
> Testen Sie die Webanwendung (warten Sie einige Sekunden):
> ```bash
> sleep 15 # Warte auf DB/App Start
> curl http://localhost:8080
> ```
> Sie sollten "Hello from Compose..." sehen.
>
> Überprüfen Sie die Logs eines oder aller Dienste:
>
> **Befehl:** `podman-compose logs [SERVICE...]`
> *   Zeigt die gesammelten Logs der angegebenen Dienste (oder aller Dienste, wenn keiner angegeben ist).
>
> **Option:** `-f` (Follow)
> *   Zeigt die Logs live an, ähnlich wie `tail -f`.
>
> ```bash
> podman-compose logs webapp # Logs nur vom Webapp-Dienst
> podman-compose logs -f database # Live-Logs vom Datenbank-Dienst
> ```
>
> ##### Step 4: Stop and Remove the Application (`down`)
>
> Der Befehl `down` ist das Gegenstück zu `up`. Er stoppt und entfernt die Container und standardmäßig auch das zugehörige Netzwerk.
>
> **Befehl:** `podman-compose down [-v]`
> *   `down`: Stoppt die Container der Dienste und entfernt sie. Entfernt auch das von `podman-compose` erstellte Netzwerk.
> *   `-v`: Entfernt zusätzlich die im Top-Level `volumes:` der `compose.yaml` definierten benannten Volumes. **Vorsicht:** Dies löscht die Daten in diesen Volumes!
>
> Stoppen und entfernen Sie die Container und das Netzwerk:
> ```bash
> podman-compose down
> ```
> Überprüfen Sie, dass die Container entfernt wurden:
> ```bash
> podman-compose ps # Sollte keine Dienste mehr anzeigen
> podman ps -a --filter name=compose- # Sollte leer sein
> ```
> Überprüfen Sie, dass die Volumes **noch existieren**:
> ```bash
> podman volume ls | grep compose_
> ```
> Führen Sie nun `down` mit `-v` aus, um auch die Volumes zu entfernen:
> ```bash
> podman-compose down -v
> ```
> Überprüfen Sie erneut die Volumes:
> ```bash
> podman volume ls | grep compose_ # Sollte nun leer sein
> ```

---

> ##### Exercise 1.5: Stopping and Starting Services (`stop`, `start`)
>
> Manchmal möchten Sie die Container nur anhalten, ohne sie und das Netzwerk zu entfernen, um sie später schnell wieder zu starten. Dafür gibt es `stop` und `start`.
>
> ##### Step 1: Start the Application Again
>
> Stellen Sie sicher, dass die Anwendung aus Exercise 1 mit `podman-compose down -v` vollständig entfernt wurde. Starten Sie sie dann erneut:
> ```bash
> # Cleanup (falls noch nicht geschehen)
> podman rm -f compose-webapp compose-database
> podman volume rm -f compose_mysql_data compose_flask_data
>
> # Starten
> podman-compose up -d
> ```
> Warten Sie kurz und überprüfen Sie mit `podman-compose ps`, dass die Dienste laufen.
> ```bash
> sleep 5
> podman-compose ps
> ```
>
> ##### Step 2: Stop the Services
>
> **Befehl:** `podman-compose stop [SERVICE...]`
> *   Hält die Container der angegebenen Dienste (oder aller Dienste) an, ohne sie zu entfernen.
>
> ```bash
> podman-compose stop
> ```
> Überprüfen Sie den Status erneut:
> ```bash
> podman-compose ps # Zeigt nun den Status 'exited' o.ä. an
> podman ps -a --filter name=compose- # Zeigt die gestoppten Container
> ```
> Ein `curl http://localhost:8080` würde jetzt fehlschlagen.
>
> ##### Step 3: Start the Services Again
>
> **Befehl:** `podman-compose start [SERVICE...]`
> *   Startet die zuvor mit `stop` angehaltenen Container der angegebenen Dienste (oder aller Dienste).
>
> ```bash
> podman-compose start
> ```
> Überprüfen Sie den Status:
> ```bash
> podman-compose ps # Sollte wieder 'running'/'up' anzeigen
> ```
> Testen Sie die Anwendung erneut (ggf. kurz warten):
> ```bash
> sleep 5
> curl http://localhost:8080 # Sollte wieder funktionieren
> ```
>
> ##### Step 4: Final Cleanup
>
> Entfernen Sie die Anwendung und die Volumes endgültig.
> ```bash
> podman-compose down -v
> ```
> **Erkenntnis:** `stop`/`start` sind nützlich, um Dienste temporär anzuhalten, während `down` sie entfernt (mit `-v` auch die Volumes).

---

> ##### Exercise 2: Building Images with `podman-compose` (`build`)
>
> Compose kann Images direkt aus Quellcode und einem `Containerfile` bauen (`build:`-Direktive).
>
> ##### Step 1: Create Application Files
>
> 1.  Erstellen Sie ein Verzeichnis `compose_build_test/` und wechseln Sie hinein.
>     ```bash
>     mkdir compose_build_test
>     cd compose_build_test
>     ```
> 2.  Erstellen Sie einen Unterordner `simple_server/`.
>     ```bash
>     mkdir simple_server
>     ```
> 3.  Erstellen Sie `simple_server/server.py` (achten Sie auf Einrückung):
>     ```python
>     # compose_build_test/simple_server/server.py
>     import http.server
>     import socketserver
>     import os
>
>     PORT = 8000
>     MESSAGE = os.environ.get('SERVER_MESSAGE', 'Hallo von Compose Build!')
>
>     class Handler(http.server.SimpleHTTPRequestHandler):
>         def do_GET(self):
>             self.send_response(200)
>             self.send_header("Content-type", "text/plain; charset=utf-8")
>             self.end_headers()
>             self.wfile.write(MESSAGE.encode('utf-8'))
>
>     with socketserver.TCPServer(("", PORT), Handler) as httpd:
>         print(f"Server läuft auf Port {PORT}...")
>         httpd.serve_forever()
>     ```
> 4.  Erstellen Sie `simple_server/Containerfile`:
>     ```dockerfile
>     # compose_build_test/simple_server/Containerfile
>     FROM python:3.12-slim
>     WORKDIR /app
>     COPY server.py .
>     EXPOSE 8000
>     CMD ["python", "server.py"]
>     ```
>
> ##### Step 2: Create `compose.yaml` with `build`
>
> Erstellen Sie `compose.yaml` im Hauptverzeichnis (`compose_build_test/`):
> ```yaml
> version: '3.8'
>
> services:
>   builder_service:
>     build:
>       context: ./simple_server # Pfad zum Verzeichnis mit Containerfile
>     container_name: compose-built-server
>     ports:
>       - "8888:8000"
>     environment:
>       SERVER_MESSAGE: "Dynamisch gebaut und gestartet!"
> ```
>
> ##### Step 3: Build and Start with `podman-compose up`
>
> Führen Sie `podman-compose up` aus. Das Image wird gebaut, da es nicht existiert.
> ```bash
> # Cleanup
> podman stop compose-built-server
> podman rm compose-built-server
>
> # Build (if needed) and start
> podman-compose up -d
> ```
> **Observe:** Sie sollten die Build-Ausgabe sehen.
>
> **Überprüfen Sie den Container-Status & Logs:**
> ```bash
> podman ps -a --filter name=compose-built-server
> # Falls 'Exited', Logs prüfen:
> # podman logs compose-built-server
> ```
> Wenn der Container läuft, prüfen Sie das Image und testen Sie den Server:
> ```bash
> podman images | grep compose_build_test
> curl http://localhost:8888
> ```
> **Result:** "Dynamisch gebaut und gestartet!"
>
> ##### Step 4: Modify Code and Rebuild (`--build`)
>
> 1.  Ändern Sie `simple_server/server.py` (z.B. die `print`-Nachricht).
> 2.  Führen Sie `podman-compose up` erneut aus, diesmal mit der Option `--build`.
>
> **Option:** `up --build`
> *   Erzwingt einen Neubau des Images für Dienste, die mit `build:` definiert sind, auch wenn das Image bereits existiert. Nützlich nach Code-Änderungen.
>
> ```bash
> podman-compose up -d --build
> ```
> **Observe:** Das Image wird neu gebaut. Prüfen Sie die Logs (`podman logs compose-built-server`), um die geänderte `print`-Nachricht zu sehen.
>
> ##### Step 5: Clean Up
>
> ```bash
> podman-compose down
> # Optional: Entfernen Sie das gebaute Image
> # IMAGE_NAME=$(podman images --filter label=io.podman.compose.project=compose_build_test --format "{{.Repository}}_{{.Tag}}")
> # if [ -n "$IMAGE_NAME" ]; then podman rmi $IMAGE_NAME; fi
> cd ..
> rm -rf compose_build_test/
> ```

---

> ##### Exercise 3: Using `.env` Files for Configuration
>
> Konfiguration über `.env`-Dateien auslagern.
>
> ##### Step 1: Create `.env` File
>
> Erstellen Sie im Verzeichnis `compose_build_test/` eine Datei namens `.env`:
> ```bash
> # Ggf. cd compose_build_test
>
> # Erstelle .env Datei
> cat > .env << EOF
> # Diese Variablen werden in compose.yaml verwendet
> TAG=latest
> HOST_PORT=9999
> DEFAULT_MESSAGE="Hallo aus der .env Datei!"
> EOF
> ```
>
> ##### Step 2: Modify `compose.yaml` to Use Variables
>
> Bearbeiten Sie die `compose.yaml` und ersetzen Sie Werte durch Variablen:
> ```yaml
> version: '3.8'
>
> services:
>   builder_service:
>     build:
>       context: ./simple_server
>     container_name: compose-built-server
>     ports:
>       # Variable für Host-Port
>       - "${HOST_PORT}:8000"
>     environment:
>       # Variable für Server-Nachricht
>       SERVER_MESSAGE: ${DEFAULT_MESSAGE}
> ```
>
> ##### Step 3: Start with `podman-compose up`
>
> Entfernen Sie den alten Container und starten Sie neu. Die `.env`-Datei wird automatisch gelesen.
> ```bash
> podman stop compose-built-server
> podman rm compose-built-server
>
> podman-compose up -d
> ```
>
> ##### Step 4: Verify the Configuration
>
> Prüfen Sie Status und Logs wie zuvor, falls nötig.
> ```bash
> podman ps -a --filter name=compose-built-server
> ```
> Überprüfen Sie das Port-Mapping:
> ```bash
> podman ps --filter name=compose-built-server --format "{{.Ports}}"
> ```
> **Result:** Sollte Host-Port `9999` zeigen.
>
> Testen Sie den Server:
> ```bash
> curl http://localhost:9999
> ```
> **Result:** Sollte die Nachricht aus der `.env`-Datei ausgeben.
>
> ##### Step 5: Clean Up
>
> ```bash
> podman-compose down
> rm .env # Entfernen Sie die .env Datei
> # Optional: cd .. ; rm -rf compose_build_test/
> ```

---

#### Wichtige Konzepte und Unterschiede

*   **Implizite Pod-Erstellung:** `podman-compose` erstellt i.d.R. einen Pod.
*   **Netzwerk:** Container im Pod teilen Netzwerk-Namespace.
*   **`.env`-Datei:** Wird automatisch geladen, Variablen mit `${VARIABLE}` verwenden.
*   **Dateiname:** Standardmäßig `compose.yaml` oder `docker-compose.yml`. Mit `-f DATEINAME` kann eine andere Datei angegeben werden (z.B. `podman-compose -f prod.compose.yaml up`).
*   **Unterschiede zu Docker Compose:** Verhalten kann abweichen, testen!
*   **Debugging:** `podman --log-level=debug compose ...` zeigt ausgeführte Podman-Befehle.

> #### Best Practices: Using `podman-compose`
>
> *   **Compose für Entwicklung:** Gut für lokale Setups.
> *   **Version Control (`compose.yaml`):** Immer einchecken.
> *   **Version Control (`.env`):** Sensible Daten **nie** einchecken (`.gitignore`), ggf. Vorlage (`.env.example`) erstellen.
> *   **Spezifische Image-Tags** verwenden.
> *   **Externe Konfiguration:** `.env`-Dateien nutzen.
> *   **Secrets Management:** Podmans `--secret` ist sicherer als `.env`.
> *   **Grenzen kennen:** Testen!
> *   **Healthchecks definieren** (wenn vom Tool unterstützt & korrekt übersetzt).
> *   **`build:` vs `image:`:** Entwicklung vs. fertige Images.
> *   **Alternative prüfen:** `podman play kube` (Topic 9).

### Key Takeaways

*   `podman-compose`: Separates Tool, `docker-compose`-ähnlich.
*   Installation via Paketmanager oder `pipx`.
*   Liest `compose.yaml` (oder via `-f`) und `.env`, startet Dienste (oft im Pod).
*   Unterstützt `build:` und `image:`.
*   Variablen aus `.env` mit `${VARIABLE}`.
*   Hauptbefehle: `up -d` (Start/Create), `down [-v]` (Stop/Remove[/Volumes]), `stop` (Stop), `start` (Start), `ps` (Status), `logs [-f]` (Logs[/Follow]), `--build` (Force Rebuild).
*   Nützlich für lokale Entwicklung, aber `podman play kube` oft robuster.
