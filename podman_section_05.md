# Podman Lernmaterial

---

## 5 - Building and Running Containerized Applications with Podman

### 5 - Building and Running Containerized Applications with Podman

Wir kombinieren Image-Bau (Topic 4) und Container-Ausführung (Topic 2) für eine **Containerized Application**. Ein zentraler Aspekt dabei ist das Management von **Daten**, sei es Konfiguration, persistenter Anwendungszustand oder Entwicklungscode. Dieser Abschnitt behandelt verschiedene Methoden dafür: Bind Mounts, Volumes, Umgebungsvariablen (direkt und über Dateien), Secrets sowie Ressourcenlimits.

Der typische Prozess sieht so aus: Code schreiben -> `Containerfile` erstellen -> Image bauen (`podman build`) -> Volumes/Secrets erstellen/verwalten -> Container starten (`podman run` mit Optionen wie `-p`, `-v`/`--mount`, `-e`, `--env-file`, `--secret`, `--memory`, `--read-only`) -> Testen und Verwalten.

Beispiel: Python Flask App mit persistentem Zähler, Konfiguration und Secrets.

---

> ##### Exercise 1: Sharing Host Data with Bind Mounts
>
> Die einfachste Methode, Daten zwischen Host und Container zu teilen, ist ein **Bind Mount**. Dabei wird ein existierendes Verzeichnis oder eine Datei vom Host-System direkt in den Container "eingeblendet". Änderungen auf einer Seite sind sofort auf der anderen sichtbar.
>
> **Wann verwenden?** Hauptsächlich für:
> *   **Entwicklung:** Quellcode vom Host im Container verfügbar machen, um schnelle Iterationen ohne Image-Neubau zu ermöglichen.
> *   **Konfigurationsdateien:** Spezifische Konfigurationsdateien vom Host in den Container einbinden.
> *   **Zugriff auf Host-Ressourcen:** Z.B. Logs auf den Host schreiben oder auf spezielle Sockets zugreifen (vorsichtig verwenden!).
>
> **Nachteile:** Weniger portabel (Host-Pfad muss relativ zum Startpunkt des Containers existieren), potenzielle Berechtigungsprobleme (UID/GID Mismatch, SELinux).
>
> ##### Step 1: Create Host Directory and File
>
> Erstellen Sie ein neues Verzeichnis für diese Übung, z.B. `mount_exercise`, und wechseln Sie in dieses Verzeichnis. Alle folgenden Pfadangaben sind relativ zu diesem Verzeichnis.
> ```bash
> mkdir mount_exercise
> cd mount_exercise
> mkdir host_files
> echo "Hello from the Host!" > host_files/host_data.txt
> ls host_files
> ```
> Sie befinden sich nun in `mount_exercise/` und haben ein Unterverzeichnis `host_files/` mit einer Testdatei erstellt.
>
> ##### Step 2: Run Container with Bind Mount (Directory)
>
> Starten Sie einen Container und mounten Sie das **relative** Host-Verzeichnis `./host_files` nach `/mnt/host_share` im Container.
>
> **Syntax (-v):** `podman run ... -v ./relative/host/path:/container/path[:OPTIONS] ...`
>
> **Syntax (--mount):** `podman run ... --mount type=bind,source=./relative/host/path,target=/container/path[,readonly] ...`
> ```bash
> # Stellen Sie sicher, dass kein alter Container existiert
> podman rm -f binder-test
>
> # Verwenden von -v (oder --volume) mit relativem Pfad
> # Wichtig: Podman löst den relativen Pfad von Ihrem *aktuellen Arbeitsverzeichnis* auf (hier: mount_exercise/)
> podman run --name binder-test -d \
>   -v ./host_files:/mnt/host_share \
>   alpine:latest sleep 3600
>
> # Alternative Syntax mit --mount (ausführlicher, aber expliziter):
> # podman run --name binder-test -d \
> #   --mount type=bind,source=./host_files,target=/mnt/host_share \
> #   alpine:latest sleep 3600
> ```
>
> > **Wichtig: Relative Pfade:** Wenn Sie relative Pfade (wie `./host_files`) für Bind Mounts verwenden, werden diese von Podman relativ zu dem Verzeichnis aufgelöst, in dem Sie den `podman run` Befehl ausführen. Stellen Sie sicher, dass Sie sich im korrekten Verzeichnis (`mount_exercise`) befinden.
> >
> > **SELinux Hinweis:** Auf Systemen mit aktiviertem SELinux (z.B. Fedora, RHEL, CentOS) können Bind Mounts zu "Permission denied"-Fehlern führen, selbst wenn die Dateisystemberechtigungen korrekt aussehen. Dies liegt daran, dass der Containerprozess möglicherweise nicht das richtige SELinux-Label hat, um auf die Host-Dateien zuzugreifen. Um dies zu beheben, können Sie die Mount-Optionen `:z` (shared content label) oder `:Z` (private content label) an den Mount anhängen: `-v ./host_files:/mnt/host_share:z`. Verwenden Sie `:z`, wenn mehrere Container auf das Volume zugreifen sollen, und `:Z`, wenn nur dieser eine Container zugreifen soll.
>
> ##### Step 3: Verify Access Inside Container
>
> Lesen Sie die Datei aus dem Container heraus:
> ```bash
> podman exec binder-test cat /mnt/host_share/host_data.txt
> ```
> **Result:** Sie sollten "Hello from the Host!" sehen.
>
> ##### Step 4: Demonstrate Live Linking
>
> Ändern Sie die Datei **auf dem Host** (im Unterverzeichnis `host_files`):
> ```bash
> echo "Host was updated!" > host_files/host_data.txt
> ```
> Lesen Sie die Datei erneut **aus dem Container**:
> ```bash
> podman exec binder-test cat /mnt/host_share/host_data.txt
> ```
> **Result:** Sie sehen nun "Host was updated!". Die Änderung ist sofort sichtbar.
>
> ##### Step 5: Mount a Single File (Read-Only)
>
> Stoppen Sie den vorherigen Container. Erstellen Sie eine Konfigurationsdatei auf dem Host (im Verzeichnis `host_files`) und mounten Sie sie read-only mit der Option `:ro`.
> ```bash
> podman stop binder-test && podman rm binder-test
> echo "TIMEOUT=30" > host_files/app.conf
>
> podman run --name binder-file-test -d \
>   -v ./host_files/app.conf:/etc/app/config.conf:ro \
>   alpine:latest sleep 3600
> # Alternative Syntax mit --mount:
> # --mount type=bind,source=./host_files/app.conf,target=/etc/app/config.conf,readonly
> ```
> Versuchen Sie, die Datei im Container zu ändern (dies wird fehlschlagen):
> ```bash
> podman exec binder-file-test sh -c "echo 'TEST' >> /etc/app/config.conf"
> ```
> **Result:** Sie erhalten einen Fehler wie "Read-only file system".
>
> > **Hinweis:** Die Option `:ro` (oder `,readonly` bei `--mount`) macht nur diesen **einen Mountpunkt** schreibgeschützt. Der Rest des Container-Dateisystems bleibt beschreibbar. Eine spätere Übung (Exercise 8) behandelt die Option `--read-only`, die das **gesamte** Root-Dateisystem des Containers schreibgeschützt macht.
>
> ##### Step 6: Clean Up
>
> Stoppen und entfernen Sie den Container und verlassen Sie das Übungsverzeichnis. Danach können Sie das Verzeichnis löschen.
> ```bash
> podman stop binder-file-test && podman rm binder-file-test
> cd ..
> rm -rf mount_exercise
> ```
> Bind Mounts sind mächtig, aber verwenden Sie sie bewusst, insbesondere in Produktionsumgebungen.

---

> ##### Exercise 2: Achieving Data Persistence with Named Volumes
>
> Während Bind Mounts nützlich sind, um *existierende* Host-Daten einzublenden, sind für das persistente Speichern von **Anwendungsdaten** (Datenbanken, Zählerstände etc.), die vom Container selbst erzeugt werden, **benannte Volumes** die bessere Wahl.
> Podman verwaltet diese Volumes, was sie portabler und oft einfacher in Bezug auf Berechtigungen macht. Die Daten überleben das Löschen des Containers.
>
> ##### Step 1: Manage Volumes
>
> Lernen Sie die grundlegenden Befehle zur Volumenverwaltung:
> ```bash
> # 1. Volume erstellen (falls noch nicht vorhanden)
> podman volume create my_app_data
>
> # 2. Volumes auflisten
> podman volume ls
>
> # 3. Volume inspizieren (zeigt Details, inkl. Mount Point auf dem Host)
> podman volume inspect my_app_data
>
> # 4. Ungenutzte Volumes entfernen (Best Practice zur Bereinigung)
> podman volume prune
>
> # 5. Spezifisches Volume entfernen (funktioniert nur, wenn kein Container es verwendet)
> # podman volume rm my_app_data # Example, do not run yet if you want to keep it
> ```
>
> ##### Step 2: Run a Container Using a Named Volume
>
> Wir starten einen einfachen Alpine-Container, der einen Zeitstempel in eine Datei innerhalb des gemounteten Volumes schreibt. Hier verwenden wir die `-v` Syntax.
>
> **Syntax (-v):** `podman run ... -v VOLUME_NAME:CONTAINER_PATH[:OPTIONS] ... IMAGE [COMMAND]`
>
> **Syntax (--mount):** `podman run ... --mount type=volume,source=VOLUME_NAME,target=/container/path[,OPTIONS] ...`
> ```bash
> # Stellen Sie sicher, dass kein alter Container existiert
> podman rm -f data-writer-vol
> # Erstellen Sie das Volume (falls nicht vorhanden)
> podman volume create my_app_data
>
> # Startet den Container, mountet 'my_app_data' nach '/data' und schreibt die aktuelle Zeit hinein
> # Führen Sie *entweder* den folgenden Befehl mit -v *oder* den danach mit --mount aus.
> podman run --name data-writer-vol \
>   -v my_app_data:/data \
>   alpine:latest \
>   sh -c "echo $(date) > /data/timestamp.txt && echo 'Timestamp written:' && cat /data/timestamp.txt"
>
> # Alternative mit --mount Syntax:
> # podman run --name data-writer-vol \
> #  --mount type=volume,source=my_app_data,target=/data \
> #  alpine:latest \
> #  sh -c "echo $(date) > /data/timestamp.txt && echo 'Timestamp written:' && cat /data/timestamp.txt"
> ```
> **Explanation:** Sowohl `-v my_app_data:/data` als auch `--mount type=volume,source=my_app_data,target=/data` weisen Podman an, das benannte Volume `my_app_data` zu nehmen und es an den Pfad `/data` im Container zu binden. Die Datei `timestamp.txt` wird somit im Volume gespeichert.
>
> ##### Step 3: Verify Persistence
>
> Entfernen Sie den Container (aber nicht das Volume!):
> ```bash
> podman rm data-writer-vol
> ```
> Starten Sie nun einen **neuen** Container, der dasselbe Volume verwendet und versucht, die Datei zu lesen **bevor** er sie überschreibt:
> ```bash
> podman run --name data-reader-vol --rm `# --rm entfernt Container danach` \
>   -v my_app_data:/data \
>   alpine:latest \
>   sh -c "echo 'Previous content:'; cat /data/timestamp.txt || echo 'File not found'; echo '---'; sleep 2; echo 'New content:'; echo $(date) > /data/timestamp.txt && cat /data/timestamp.txt"
> ```
> **Result:** Sie sollten den Zeitstempel sehen, der vom **ersten** Container (`data-writer-vol`) geschrieben wurde, bevor der neue Zeitstempel gespeichert wird. Dies beweist, dass die Daten im Volume erhalten geblieben sind.
>
> ##### Step 4: Inspect Container Mounts
>
> Wenn ein Container läuft, können Sie seine Mounts inspizieren:
> ```bash
> # Starten Sie den Container nochmal im Hintergrund
> podman run -d --name data-inspector -v my_app_data:/data alpine:latest sleep 60
> # Inspizieren
> podman inspect data-inspector | jq '.[0].Mounts'
> ```
> **Result:** Die Ausgabe zeigt detailliert den Typ (`volume`), Namen (`my_app_data`), Zielpfad (`/data`) etc. des Mounts.
> ```bash
> # Aufräumen
> podman stop data-inspector && podman rm data-inspector
> ```
>
> ##### Step 5: Clean Up
>
> ```bash
> # Volume entfernen (falls gewünscht für einen sauberen Start der nächsten Übung)
> # podman volume rm my_app_data
> ```
> Benannte Volumes sind die Standardmethode für persistente Anwendungsdaten in Containern.

---

> #### Info: `-v` vs. `--mount` - Zwei Wege zum Ziel
>
> Sie haben in den vorherigen Übungen vielleicht beide Syntaxen gesehen: `-v` (oder `--volume`) und `--mount`. Beide können verwendet werden, um Bind Mounts und benannte Volumes zu erstellen, aber sie unterscheiden sich in ihrer Syntax und Klarheit:
>
> **`-v` / `--volume` Syntax:**
> *   **Format:** `SOURCE:TARGET[:OPTIONS]`
> *   **Typbestimmung:** Podman/Docker versucht anhand der `SOURCE` zu erraten, was gemeint ist:
>     *   Beginnt mit `/`, `.` oder `~` -> **Bind Mount** (Host-Pfad)
>     *   Ist nur ein Name -> **Benanntes Volume** (wird ggf. erstellt)
>     *   Nur `TARGET` angegeben -> **Anonymes Volume** (selten verwendet, Podman/Docker erstellt Volume mit zufälligem Namen). Diese sind schwer zu referenzieren und zu verwalten und sollten generell vermieden werden, es sei denn, man benötigt explizit temporären Speicher, der mit dem Container gelöscht wird.
> *   **Beispiele:**
>     *   `-v my-volume:/data` (Named Volume)
>     *   `-v ./src:/app:ro` (Bind Mount, read-only)
> *   **Vorteil:** Kürzer, schnell für einfache Fälle.
> *   **Nachteil:** Kann mehrdeutig sein (`mydata` ist ein Volume oder ein Verzeichnis?), anfälliger für Fehler, wenn Pfade Doppelpunkte enthalten, weniger strukturiert für Optionen.
>
> **`--mount` Syntax:**
> *   **Format:** `type=<TYPE>,source=<SOURCE>,target=<TARGET>[,OPTIONS...]` (Komma-getrennte Key-Value Paare)
> *   **Typbestimmung:** Immer **explizit** über `type=`:
>     *   `type=bind` -> **Bind Mount** (`source` ist Host-Pfad)
>     *   `type=volume` -> **Benanntes Volume** (`source` ist Volume-Name, wird ggf. erstellt)
>     *   `type=tmpfs` -> **Tmpfs Mount** (`target` ist der Mount-Punkt im Container)
> *   **Beispiele:**
>     *   `--mount type=volume,source=my-volume,target=/data`
>     *   `--mount type=bind,source=./src,target=/app,readonly`
>     *   `--mount type=tmpfs,target=/tmp`
> *   **Vorteil:** **Explizit und eindeutig**, besser lesbar, strukturierter für Optionen, robuster gegenüber Sonderzeichen in Pfaden, notwendig für `tmpfs` und erweiterte Optionen.
> *   **Nachteil:** Ausführlicher (längere Schreibweise).
>
> **Best Practice / Empfehlung:**
>
> Für Klarheit, Lesbarkeit und Robustheit, insbesondere in Skripten, Automatisierungen oder komplexeren Szenarien, wird die **Verwendung der `--mount` Syntax generell empfohlen**. Sie macht Ihre Absicht deutlich und vermeidet Mehrdeutigkeiten. Die `-v` Syntax ist für schnelle, interaktive Befehle oder sehr einfache Fälle weiterhin in Ordnung.

---

> ##### Exercise 3: Containerizing a Flask Application with Volume Persistence
>
> Nun wenden wir unser Wissen über **benannte Volumes** an, um die Flask-Anwendung mit einem persistenten Zähler zu containerisieren. Wir verwenden hier die empfohlene `--mount` Syntax.
>
> ### Step-by-Step Guide: Flask App with Volume
>
> ##### Step 1: Create Application Files
>
> Erstellen Sie ein neues Verzeichnis für diese Anwendung, z.B. `my_flask_app`, und wechseln Sie hinein.
> ```bash
> mkdir my_flask_app
> cd my_flask_app
> ```
> Erstellen Sie die Datei **`requirements.txt`** mit folgendem Inhalt:
> ```nohighlight
> Flask>=2.3,<3.1
> ```
> Erstellen Sie die Datei **`app.py`** mit folgendem Inhalt (dies ist die Flask-App, die einen Zähler in `/data/counter.txt` speichert und Umgebungsvariablen liest. **Hinweis:** Die Secret-Verarbeitung ist hier noch auskommentiert.):
> ```python
> from flask import Flask
> import os
>
> app = Flask(__name__)
> COUNTER_FILE = '/data/counter.txt'
> # SECRET_FILE = '/run/secrets/db_password' # Secret reading code is commented out below
>
> def get_counter():
>     if not os.path.exists(COUNTER_FILE): return 0
>     try:
>         with open(COUNTER_FILE, 'r') as f: return int(f.read().strip())
>     except: return 0
>
> def increment_counter():
>     count = get_counter() + 1
>     try:
>         # Ensure directory exists (important when using volumes)
>         os.makedirs(os.path.dirname(COUNTER_FILE), exist_ok=True)
>         with open(COUNTER_FILE, 'w') as f: f.write(str(count))
>         return count
>     except IOError as e:
>         print(f"Error writing counter file: {e}"); return -1
>
> # def read_secret(): # Secret reading is commented out for this exercise
> #     try:
> #         with open(SECRET_FILE, 'r') as f:
> #             return f.read().strip()
> #     except FileNotFoundError:
> #         return "Secret not found!"
> #     except IOError as e:
> #         print(f"Error reading secret file: {e}")
> #         return "Error reading secret!"
>
> @app.route('/')
> def hello():
>     count = increment_counter()
>     if count == -1: return 'Error updating counter!', 500
>     hostname = os.uname().nodename
>     greeting = os.environ.get('GREETING', 'Hello') # Read environment variable 'GREETING', default to 'Hello'
>     # db_pass_secret = read_secret() # Secret reading is commented out for this exercise
>     return f'{greeting} from Container ID: {hostname}! Visited {count} times.' # Secret is not displayed yet
>
> if __name__ == '__main__':
>     app.run(host='0.0.0.0', port=5000)
> ```
> Erstellen Sie das **`Containerfile`** mit folgendem Inhalt (dies baut das Image, installiert Abhängigkeiten, erstellt das `/data` Verzeichnis und legt den Benutzer fest):
> ```dockerfile
> # Check latest stable Python slim image on https://hub.docker.com/_/python
> FROM python:3.12-slim
>
> LABEL maintainer="Ihr Name" version="1.1" description="Flask App with Counter"
>
> WORKDIR /app
>
> COPY requirements.txt .
> # Installiere Dependencies
> RUN pip install --no-cache-dir -r requirements.txt
>
> COPY app.py .
>
> # Erstelle User/Gruppe und Datenverzeichnis
> RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
> RUN mkdir /data && chown appuser:appgroup /data
>
> USER appuser
>
> EXPOSE 5000
>
> CMD ["python", "app.py"]
> ```
> Sie haben nun alle notwendigen Dateien im Verzeichnis `my_flask_app/`.
>
> ##### Step 2: Build the Container Image
>
> Bauen Sie das Image aus dem aktuellen Verzeichnis (`my_flask_app/`):
> ```bash
> podman build -t my-flask-app:1.1 .
> ```
>
> ##### Step 3: Create Volume and Run the Container (using --mount and -e)
>
> > **Wichtig: Port/Namens-Konflikt!** Stellen Sie sicher, dass keine vorherigen Container oder Volumes Konflikte verursachen.
> > ```bash
> > podman rm -f my-persistent-app
> > # Stellen Sie sicher, dass das Volume existiert oder erstellen Sie es neu
> > podman volume rm flask_app_data # Entfernen Sie das alte Volume für einen sauberen Start
> > podman volume create flask_app_data
> > ```
>
> Starten Sie den Container und mounten Sie das Volume mit `--mount`. Wir verwenden auch die Option `-e` (oder `--env`), um eine Umgebungsvariable namens `GREETING` im Container zu setzen.
> ```bash
> podman run -d \
>   -p 5000:5000 \
>   --name my-persistent-app \
>   --mount type=volume,source=flask_app_data,target=/data `# Explizites Volume Mount` \
>   -e GREETING="Persistent Welcome" \
>   my-flask-app:1.1
> ```
>
> ##### Step 4: Access and Verify Persistence
>
> 1.  Greifen Sie auf `http://localhost:5000` zu. Zähler beginnt bei 1. Sie sollten "Persistent Welcome" sehen.
> 2.  Laden Sie die Seite mehrmals neu (z.B. bis 3).
> 3.  **Testen Sie die Persistenz:** Stoppen und entfernen Sie den Container.
>     ```bash
>     podman stop my-persistent-app && podman rm my-persistent-app
>     ```
> 4.  Starten Sie den Container **genau gleich** erneut (er wird dasselbe Volume verwenden):
>     ```bash
>     podman run -d -p 5000:5000 --name my-persistent-app --mount type=volume,source=flask_app_data,target=/data -e GREETING="Persistent Welcome Again" my-flask-app:1.1
>     ```
> 5.  Greifen Sie erneut auf `http://localhost:5000` zu.
> 6.  **Beobachten Sie:** Der Zähler sollte bei 4 (oder dem nächsten Wert) weiterzählen! Die Begrüßung ist nun "Persistent Welcome Again".
> 7.  Stoppen und entfernen Sie den Container für die nächste Übung: `podman stop my-persistent-app && podman rm my-persistent-app`
>
> Dieses Setup mit einem benannten Volume dient als Basis für die folgenden Übungen.

---

> ##### Exercise 4: Using `.env` Files for Configuration (`--env-file`)
>
> Anstatt jede Umgebungsvariable einzeln mit `-e` zu übergeben, ist es oft praktischer, sie in einer `.env`-Datei zu sammeln. Podman kann diese Datei mit der Option `--env-file` einlesen.
> Dies ist eine gängige Methode, um Konfigurationen für verschiedene Umgebungen (Entwicklung, Test, Produktion) zu verwalten, ohne die `podman run`-Befehle zu überladen.
>
> ##### Step 1: Create an `.env` File
>
> Erstellen Sie im Verzeichnis `my_flask_app/` eine Datei namens `app.env` mit folgendem Inhalt:
> ```nohighlight
> # Environment variables for Flask App
> GREETING=Hello from .env file!
> # Man kann auch Kommentare hinzufügen
> APP_MODE=development
> ```
> **Format:** Jede Zeile enthält ein `KEY=VALUE` Paar. Leerzeilen und Zeilen, die mit `#` beginnen, werden ignoriert.
>
> ##### Step 2: Modify `app.py` to Read Additional Variable (Optional but Recommended)
>
> Um den Effekt zu sehen, passen wir `app.py` leicht an, um auch die Variable `APP_MODE` aus der `.env`-Datei zu lesen und anzuzeigen. Ersetzen Sie den Inhalt Ihrer **`app.py`** Datei mit folgendem Code (die Secret-Verarbeitung bleibt hier auskommentiert):
> ```python
> from flask import Flask
> import os
>
> app = Flask(__name__)
> COUNTER_FILE = '/data/counter.txt'
> # SECRET_FILE = '/run/secrets/db_password' # Secret reading code is commented out below
>
> def get_counter():
>     if not os.path.exists(COUNTER_FILE): return 0
>     try:
>         with open(COUNTER_FILE, 'r') as f: return int(f.read().strip())
>     except: return 0
>
> def increment_counter():
>     count = get_counter() + 1
>     try:
>         os.makedirs(os.path.dirname(COUNTER_FILE), exist_ok=True)
>         with open(COUNTER_FILE, 'w') as f: f.write(str(count))
>         return count
>     except IOError as e:
>         print(f"Error writing counter file: {e}"); return -1
>
> # def read_secret(): # Secret reading is commented out for this exercise
> #     # ... (wie in Übung 3)
>
> @app.route('/')
> def hello():
>     count = increment_counter()
>     if count == -1: return 'Error updating counter!', 500
>     hostname = os.uname().nodename
>     greeting = os.environ.get('GREETING', 'Hello') # Read GREETING from environment
>     app_mode = os.environ.get('APP_MODE', 'production') # Read APP_MODE from environment, default to production
>     # db_pass_secret = read_secret() # Secret reading is commented out for this exercise
>     # Display GREETING and APP_MODE in the response
>     return f'{greeting} from Container ID: {hostname}! Visited {count} times. Mode: {app_mode}' # Secret not displayed
>
> if __name__ == '__main__':
>     app.run(host='0.0.0.0', port=5000)
> ```
> Wenn Sie die `app.py` geändert haben, müssen Sie das Image neu bauen, damit die Änderungen wirksam werden:
> ```bash
> # Nur ausführen, wenn app.py geändert wurde!
> podman build -t my-flask-app:1.1 .
> ```
>
> ##### Step 3: Run the Container with `--env-file`
>
> Stellen Sie sicher, dass der vorherige Container entfernt wurde.
> ```bash
> podman rm -f my-persistent-app my-env-app
> # Volume sollte existieren (ggf. neu erstellen, wenn es in Ex3 entfernt wurde):
> podman volume create flask_app_data
>
> # Starten Sie den Container und übergeben Sie die .env-Datei
> podman run -d \
>   -p 5000:5000 \
>   --name my-env-app \
>   --mount type=volume,source=flask_app_data,target=/data \
>   --env-file ./app.env `# Hier wird die Datei übergeben` \
>   my-flask-app:1.1
> ```
> **Wichtig:** Der Pfad zur `--env-file` ist relativ zum aktuellen Arbeitsverzeichnis auf dem Host.
>
> ##### Step 4: Verify Environment Variables
>
> 1.  Greifen Sie auf `http://localhost:5000` zu.
> 2.  **Beobachten Sie:** Sie sollten die Begrüßung "Hello from .env file!" sehen. Wenn Sie `app.py` angepasst haben, sehen Sie auch "Mode: development". Der Zähler läuft weiter.
> 3.  Überprüfen Sie die Umgebungsvariablen im Container:
>     ```bash
>     podman exec my-env-app printenv | grep -E 'GREETING|APP_MODE'
>     ```
>     **Result:** Sie sollten `GREETING=Hello from .env file!` und `APP_MODE=development` sehen.
>
> > **Priorität:** Wenn eine Variable sowohl mit `-e` als auch in `--env-file` definiert wird, hat die mit `-e` übergebene Variable Vorrang.
>
> ##### Step 5: Clean Up
>
> ```bash
> podman stop my-env-app && podman rm my-env-app
> rm app.env # Entfernen Sie die .env-Datei
> # Optional: Volume entfernen
> # podman volume rm flask_app_data
> ```
> Die Verwendung von `--env-file` ist eine saubere Methode, um Konfigurationen zu verwalten.

---

> ##### Exercise 5: Managing Secrets Securely with Podman-Managed Secrets (File Mount)
>
> Passwörter oder API-Schlüssel sollten nie direkt in Images oder Umgebungsvariablen landen. Podman bietet eine robuste Methode, um sensible Daten als **verwaltete Secrets** zu speichern und sie sicher als **Dateien** in den Container zu mounten (typischerweise unter `/run/secrets/`).
> Dies entkoppelt die Secret-Daten vom Host-Dateisystem zur Laufzeit des Containers. Diese Übung zeigt das Einbinden als Datei, was für Konfigurationsdateien oder Zertifikate nützlich ist.
>
> ##### Step 1: Create a Secret File on the Host
>
> Erstellen Sie eine Textdatei im aktuellen Verzeichnis (`my_flask_app/`).
> ```bash
> echo "MySuperSecretDBPassw0rd!" > db_password.txt
> chmod 600 db_password.txt
> ```
>
> ##### Step 2: Create a Podman-Managed Secret from the File
>
> Verwenden Sie `podman secret create`, um den Inhalt der Host-Datei als verwaltetes Secret unter einem bestimmten Namen zu registrieren.
> ```bash
> # Ggf. altes Secret entfernen
> podman secret rm db_password
>
> # Erstelle das Secret 'db_password' aus der Datei 'db_password.txt'
> podman secret create db_password ./db_password.txt
>
> # Überprüfen, ob das Secret existiert und Inhalt hat
> podman secret ls
> podman secret inspect db_password
> ```
> Das Secret mit dem Namen `db_password` wird nun von Podman verwaltet.
>
> ##### Step 3: Update Application Code to Read the Secret (Important!)
>
> Stellen Sie sicher, dass Ihre `app.py` den Code zum Lesen des Secrets enthält. Öffnen Sie **`app.py`** und stellen Sie sicher, dass die `read_secret` Funktion und ihr Aufruf aktiv sind (kommentieren Sie die entsprechenden Zeilen ein):
> ```python
> from flask import Flask
> import os
>
> app = Flask(__name__)
> COUNTER_FILE = '/data/counter.txt'
> SECRET_FILE = '/run/secrets/db_password' # Standard path for secrets
>
> def get_counter():
>     if not os.path.exists(COUNTER_FILE): return 0
>     try:
>         with open(COUNTER_FILE, 'r') as f: return int(f.read().strip())
>     except: return 0
>
> def increment_counter():
>     count = get_counter() + 1
>     try:
>         os.makedirs(os.path.dirname(COUNTER_FILE), exist_ok=True)
>         with open(COUNTER_FILE, 'w') as f: f.write(str(count))
>         return count
>     except IOError as e:
>         print(f"Error writing counter file: {e}"); return -1
>
> # === UNCOMMENT/ENABLE THIS FUNCTION ===
> def read_secret():
>     try:
>         with open(SECRET_FILE, 'r') as f:
>             return f.read().strip()
>     except FileNotFoundError:
>         # Important: Check if the target path in --secret matches SECRET_FILE
>         return f"Secret file not found at {SECRET_FILE}!"
>     except IOError as e:
>         print(f"Error reading secret file: {e}")
>         return "Error reading secret!"
> # === END FUNCTION ===
>
> @app.route('/')
> def hello():
>     count = increment_counter()
>     if count == -1: return 'Error updating counter!', 500
>     hostname = os.uname().nodename
>     greeting = os.environ.get('GREETING', 'Hello')
>     app_mode = os.environ.get('APP_MODE', 'production') # From Exercise 4
>
>     # === UNCOMMENT/ENABLE THIS LINE ===
>     db_pass_secret = read_secret()
>     # === END LINE ===
>
>     # Adjust the return string to include the secret
>     return f'{greeting} from Container ID: {hostname}! Visited {count} times. Mode: {app_mode}. DB Pass: [{db_pass_secret}]'
>
> if __name__ == '__main__':
>     app.run(host='0.0.0.0', port=5000)
> ```
> **Wichtig:** Nachdem Sie `app.py` geändert haben, müssen Sie das Image **neu bauen**, damit die Änderungen wirksam werden:
> ```bash
> # Nur ausführen, wenn app.py geändert wurde!
> podman build -t my-flask-app:1.1 .
> ```
>
> ##### Step 4: Run the Container with the Managed Secret (File Mount)
>
> Verwenden Sie nun `--secret` mit dem *Namen* des Podman-Secrets (`db_password`). Mit `target=db_password` geben wir an, dass das Secret im Container unter `/run/secrets/db_password` verfügbar sein soll (dies muss mit `SECRET_FILE` in `app.py` übereinstimmen).
> ```bash
> # Stellen Sie sicher, dass alte Container weg sind
> podman rm -f my-persistent-app my-env-app my-secret-app
> # Volume sollte noch existieren (ggf. neu erstellen):
> podman volume create flask_app_data
>
> podman run -d \
>   -p 5000:5000 \
>   --name my-secret-app \
>   --mount type=volume,source=flask_app_data,target=/data `# Volume für Zähler` \
>   -e GREETING="App with Managed Secret (File)" \
>   --secret source=db_password,target=db_password `# Standard: Mount als Datei /run/secrets/db_password` \
>   my-flask-app:1.1
> ```
> **Erläuterung:**
> *   `source=db_password`: Referenziert das von Podman verwaltete Secret namens `db_password`.
> *   `target=db_password` (Standardverhalten): Gibt den Dateinamen an, unter dem das Secret im Standard-Secret-Verzeichnis (`/run/secrets/`) im Container gemountet wird. Der vollständige Pfad im Container ist also `/run/secrets/db_password`, was mit `SECRET_FILE` in unserer `app.py` übereinstimmt.
>
> ##### Step 5: Verify Secret Access
>
> Greifen Sie auf die Anwendung zu und überprüfen Sie, ob das Secret korrekt gelesen wird:
> ```bash
> curl http://localhost:5000
> ```
> **Result:** Die Ausgabe sollte nun den Text `DB Pass: [MySuperSecretDBPassw0rd!]` (oder den Inhalt Ihrer Secret-Datei) enthalten. Der Zähler sollte ebenfalls funktionieren.
>
> Überprüfen Sie zusätzlich die Details im Container:
> ```nohighlight
> # 1. Secret sollte NICHT in Umgebungsvariablen auftauchen
> podman exec my-secret-app printenv | grep -i passw
>
> # 2. Überprüfen Sie das Secret-Verzeichnis und die Datei im Container
> podman exec my-secret-app ls -la /run/secrets/
>
> # 3. Versuchen Sie, den Inhalt der Secret-Datei direkt auszugeben
> podman exec my-secret-app cat /run/secrets/db_password
> ```
> **Erwartetes Ergebnis für Schritt 2 & 3:** Sie sollten die Datei `db_password` im Verzeichnis `/run/secrets/` sehen (oft mit `root` als Besitzer, aber für den Container-User lesbar) und der `cat`-Befehl sollte den Inhalt des Secrets anzeigen.
>
> > **Troubleshooting: Fehler beim Zugriff auf `/run/secrets/db_password`?**
> >
> > Wenn Sie einen Fehler wie `cannot resolve /nonexistent` oder "Permission denied" erhalten, obwohl Sie das Secret korrekt erstellt haben und der `ls -la /run/secrets/` Befehl die Datei anzeigt, kann dies auf ein tieferliegendes Problem mit der Podman-Konfiguration, der Version oder dem Host-System (z.B. Namespace/Mount-Setup in rootless Modus) hindeuten.
> >
> > **Workaround:** Als Alternative oder zur Fehlersuche können Sie versuchen, die Secret-Datei direkt per Bind Mount einzubinden (siehe Info-Box unten). Stoppen und entfernen Sie dazu den aktuellen Container (`podman rm -f my-secret-app`) und starten Sie ihn mit:
> > ```bash
> > # Stellen Sie sicher, dass db_password.txt im Host-Verzeichnis existiert
> > podman run -d \
> >   -p 5000:5000 \
> >   --name my-secret-app-bindmount \
> >   --mount type=volume,source=flask_app_data,target=/data \
> >   -e GREETING="App with Bind-Mounted Secret" \
> >   --mount type=bind,source=./db_password.txt,target=/run/secrets/db_password,readonly \
> >   my-flask-app:1.1
> > ```
> > Testen Sie dann erneut mit `curl http://localhost:5000` und `podman exec my-secret-app-bindmount cat /run/secrets/db_password`. Wenn dies funktioniert, liegt das Problem spezifisch an der `--secret` Implementierung in Ihrer Umgebung.
>
> ##### Step 6: Clean Up
>
> ```bash
> # Stoppen und entfernen Sie den/die Container aus dieser Übung
> podman stop my-secret-app my-secret-app-bindmount 2>/dev/null
> podman rm my-secret-app my-secret-app-bindmount 2>/dev/null
>
> # Entfernen Sie das Podman-Secret (wichtig!)
> podman secret rm db_password
> # Entfernen Sie die Host-Datei
> rm db_password.txt
> # Optional: Volume entfernen
> # podman volume rm flask_app_data
> ```
> Das Einbinden von Podman-verwalteten Secrets als Dateien ist eine sichere Methode für Konfigurationsdaten.
>
> > #### Alternative: Mounting Host Files Directly (`--secret type=mount` oder Bind Mount)
> >
> > Obwohl Podman-verwaltete Secrets empfohlen werden, gibt es Szenarien, in denen Sie eine Host-Datei direkt mounten möchten:
> > *   **Mit `--secret type=mount` (wie ursprünglich versucht):**
> >     ```bash
> >     # podman run ... --secret type=mount,source=/abs/path/to/db_password.txt,target=db_password ...
> >     ```
> >     <p>Dies <i>sollte</i> funktionieren, kann aber je nach Podman-Version und Pfadangabe (relativ vs. absolut) zu Problemen führen, wie der Fehler <code>no secret with name or id ...</code> zeigte. Wenn Sie dies verwenden, bevorzugen Sie absolute Pfade für `source`.</p>
> > *   **Mit einem regulären Bind Mount (Workaround aus Troubleshooting):**
> >     ```bash
> >     # podman run ... --mount type=bind,source=./db_password.txt,target=/run/secrets/db_password,readonly ...
> >     ```
> >     <p>Dies erreicht ein ähnliches Ergebnis, indem die Host-Datei schreibgeschützt an den erwarteten Secret-Pfad gemountet wird. Es verwendet nicht den "Secret"-Mechanismus von Podman, ist aber eine gängige und oft robustere Methode, wenn `--secret` Probleme macht.</p>
> >
> > Für Produktions- oder reproduzierbare Setups sind jedoch **Podman-verwaltete Secrets** die überlegene Wahl, wenn sie in Ihrer Umgebung korrekt funktionieren.

---

> ##### Exercise 6: Injecting Secrets as Environment Variables (DB Password Example)
>
> Eine sehr häufige Anforderung ist die Übergabe von Datenbank-Passwörtern oder API-Keys an Anwendungen. Viele Standard-Images (z.B. Datenbanken, Cloud-Tools) erwarten diese sensiblen Daten als **Umgebungsvariablen** (z.B. `MYSQL_ROOT_PASSWORD`, `AWS_SECRET_ACCESS_KEY`).
> Podman erlaubt es, verwaltete Secrets sicher als Umgebungsvariablen in den Container zu injizieren, ohne dass sie in der Container-Konfiguration im Klartext gespeichert werden.
>
> ##### Step 1: Create a Podman-Managed Secret (Simulated DB Password)
>
> Erstellen Sie ein neues Secret, das ein typisches Datenbank-Passwort repräsentiert.
> ```bash
> # Ggf. altes Secret mit gleichem Namen entfernen
> podman secret rm mysql_root_password
>
> # Erstellen Sie das Secret 'mysql_root_password'
> echo 's3cUreR00tP@ssw0rd!' | podman secret create mysql_root_password -
>
> # Überprüfen Sie das Secret
> podman secret ls
> podman secret inspect mysql_root_password
> ```
>
> ##### Step 2: Run a Container Injecting the Secret as an Environment Variable
>
> Wir starten einen einfachen Alpine-Container und verwenden die Option `type=env` beim `--secret` Flag, um das Podman-Secret `mysql_root_password` als Umgebungsvariable `MYSQL_ROOT_PASSWORD` im Container verfügbar zu machen.
> ```bash
> # Stellen Sie sicher, dass kein alter Container existiert
> podman rm -f secret-env-test
>
> # Starten Sie den Container und geben Sie die Umgebungsvariablen aus
> # --rm sorgt dafür, dass der Container danach entfernt wird
> podman run --rm --name secret-env-test \
>   --secret source=mysql_root_password,type=env,target=MYSQL_ROOT_PASSWORD \
>   alpine:latest printenv | grep MYSQL_ROOT_PASSWORD
> ```
> **Erläuterung der `--secret` Option:**
> *   `source=mysql_root_password`: Referenziert das Podman-Secret.
> *   `type=env`: Weist Podman an, das Secret als Umgebungsvariable zu injizieren (statt als Datei).
> *   `target=MYSQL_ROOT_PASSWORD`: Gibt den Namen der Umgebungsvariable an, die im Container gesetzt werden soll.
>
> ##### Step 3: Verify the Environment Variable
>
> Der vorherige Befehl sollte die Variable direkt ausgegeben haben:
> ```nohighlight
> MYSQL_ROOT_PASSWORD=s3cUreR00tP@ssw0rd!
> ```
> Die Anwendung im Container (hier `printenv`) kann nun auf die Umgebungsvariable `MYSQL_ROOT_PASSWORD` zugreifen und deren Wert (das Secret) verwenden.
>
> ##### Step 4: Verify Security (Secret Value Not in Container Config)
>
> Ein wichtiger Sicherheitsaspekt ist, dass das Secret selbst nicht Teil der persistenten Container-Konfiguration wird und dort im Klartext gespeichert ist. Führen Sie `podman inspect` auf einem *neu gestarteten* Container (ohne `--rm`) durch, der das Secret verwendet:
> ```bash
> # Starten Sie den Container im Hintergrund
> podman run -d --name secret-env-test-inspect \
>   --secret source=mysql_root_password,type=env,target=MYSQL_ROOT_PASSWORD \
>   alpine:latest sleep 60
>
> # Inspizieren Sie die Konfiguration des Containers
> podman inspect secret-env-test-inspect | jq '.[0].Config.Env'
> ```
> **Result:** Sie werden eine Ausgabe ähnlich dieser sehen:
> ```json
> [
>   "...",
>   "HOSTNAME=...",
>   "mysql_root_password=*******"
> ]
> ```
> **Beobachtung:** Podman listet einen Eintrag für das Secret in der `Config.Env` Liste auf, verwendet dabei aber den **Namen des Podman-Secrets** (`mysql_root_password`) als Schlüssel und **maskiert den eigentlichen Wert** mit Sternchen (`*******`). Der tatsächliche Name der Umgebungsvariable im Container (`MYSQL_ROOT_PASSWORD`) wird hier nicht direkt angezeigt.
> Dies bestätigt, dass das sensible Secret zur Laufzeit injiziert wird, aber der eigentliche Wert **nicht im Klartext** in der gespeicherten Container-Konfiguration verbleibt.
> Nun können Sie den temporären Container aufräumen:
> ```bash
> # Stoppen und entfernen Sie den Inspektions-Container
> podman stop secret-env-test-inspect && podman rm secret-env-test-inspect
> ```
>
> ##### Step 5: Clean Up
>
> Entfernen Sie das für diese Übung erstellte Podman-Secret:
> ```bash
> # Entfernen Sie das Podman-Secret
> podman secret rm mysql_root_password
> ```
> Das Injizieren von Secrets als Umgebungsvariablen ist eine gängige und sichere Methode, um sensible Daten wie Passwörter an Container-Anwendungen zu übergeben, die diese erwarten.
>
> > #### Wann Environment Variable, wann File Mount?
> >
> > *   **Environment Variable (`type=env`):** Ideal für einzelne Werte wie Passwörter, API-Keys, Tokens, insbesondere wenn das verwendete Image oder die Anwendung erwartet, diese über Umgebungsvariablen zu lesen (sehr üblich bei Datenbank-Images, Cloud-SDKs etc.).
> > *   **File Mount (Standard oder `type=mount`):** Besser geeignet für mehrzeilige Secrets, Konfigurationsdateien, Zertifikate, SSH-Keys oder wenn die Anwendung explizit eine Datei an einem bestimmten Ort erwartet (z.B. `/etc/app/config.yaml`, `~/.ssh/id_rsa`).

---

> ##### Exercise 7: Limiting Container Resources (`--memory`, `--cpus`)
>
> Setzen Sie Limits für CPU und Speicher, um zu verhindern, dass ein Container das System überlastet.
>
> ##### Step 1: Run With Memory Limit
>
> ```bash
> # Ensure previous containers are removed
> podman rm -f my-secret-app my-secret-app-bindmount my-limited-app secret-env-test-inspect
> # Volume sollte existieren (ggf. neu erstellen):
> podman volume create flask_app_data
>
> # Start container with 100MB memory limit
> podman run -d \
>   -p 5000:5000 \
>   --name my-limited-app \
>   --mount type=volume,source=flask_app_data,target=/data \
>   -e GREETING="Memory Limited App" \
>   --memory 100m `# Limit auf 100 MiB` \
>   my-flask-app:1.1 `# Use the image with secret (file) handling enabled`
> ```
> Überprüfen Sie die Konfiguration des Limits:
> ```bash
> # Versuchen Sie, das konfigurierte Speicherlimit auszulesen
> podman inspect my-limited-app | jq '.[0].HostConfig.Memory'
> ```
> **Mögliche Ergebnisse:**
> *   Auf Systemen mit **cgroups v2** (insbesondere rootful oder gut konfiguriertem rootless) sollte dieser Befehl den Grenzwert in Bytes anzeigen (`104857600` für 100 MiB).
> *   Auf Systemen mit älteren **cgroups v1**, besonders im **rootless-Modus**, kann dieser Wert jedoch `0` anzeigen, auch wenn das Limit an Podman übergeben wurde. Das Cgroup-Subsystem des Hosts konnte das Limit möglicherweise nicht korrekt umsetzen oder für `inspect` verfügbar machen.
>
> Unabhängig von der Ausgabe von `inspect`, wurde Podman angewiesen, das Limit anzuwenden.
> Testen Sie, ob die Anwendung noch läuft:
> ```bash
> # Test the app (secret reading will fail if secret 'db_password' doesn't exist)
> # Wenn das Secret aus Ex5 nicht existiert, wird "[Secret file not found...]" angezeigt. Das Limit gilt trotzdem.
> curl http://localhost:5000
> ```
> Bei tatsächlicher Überschreitung des Limits (sofern vom Host durchgesetzt) würde der Container durch den OOM (Out Of Memory) Killer beendet werden.
> ```bash
> # Aufräumen für diesen Schritt
> podman stop my-limited-app && podman rm my-limited-app
> ```
>
> ##### Step 2: Run With CPU Limit
>
> ```bash
> # Start container limited to 0.5 CPU cores
> podman run -d \
>   -p 5000:5000 \
>   --name my-limited-app \
>   --mount type=volume,source=flask_app_data,target=/data \
>   -e GREETING="CPU Limited App" \
>   --cpus 0.5 `# Limit auf halben CPU-Kern` \
>   my-flask-app:1.1
> ```
> Überprüfen:
> ```bash
> # Inspect CPU related settings (NanoCpus oder CpuQuota/CpuPeriod sollten gesetzt sein)
> podman inspect my-limited-app | jq '.[0].HostConfig | .CpuPeriod, .CpuQuota, .NanoCpus'
> # Test the app (performance might be slightly reduced under heavy load)
> curl http://localhost:5000
> ```
> Der Container wird bei hoher CPU-Last gedrosselt (throttled).
>
> ##### Step 3: Clean Up
>
> ```bash
> # Aufräumen für diesen Schritt
> podman stop my-limited-app && podman rm my-limited-app
> # Optional: Volume entfernen
> # podman volume rm flask_app_data
> ```
>
> > **Hinweis zu cgroups v1 vs. v2:** Die Effektivität und Granularität von Ressourcenlimits hängt vom verwendeten cgroups-Subsystem auf dem Host ab. cgroups v2 (Standard auf neueren Systemen) bietet generell bessere Unterstützung, insbesondere für rootless Container. Bei cgroups v1 (speziell rootless) werden Limits möglicherweise nicht immer wie erwartet durchgesetzt oder in `inspect` korrekt angezeigt.

---

> ##### Exercise 8: Enhancing Security with Read-Only Root Filesystem (`--read-only`)
>
> Eine wichtige Sicherheitspraxis ist es, das Hauptdateisystem des Containers als schreibgeschützt zu markieren (mit der Option `--read-only` beim Start). Dies unterscheidet sich von der Option `:ro` bei einzelnen Mounts (siehe Übung 1), da hier das **gesamte Root-Dateisystem** betroffen ist. Dies reduziert die Angriffsfläche erheblich, da ein kompromittierter Prozess keine Systemdateien oder Binaries ändern kann.
> Wenn `--read-only` verwendet wird, müssen **alle Pfade, in die geschrieben werden muss**, explizit über beschreibbare Volumes oder tmpfs-Mounts bereitgestellt werden.
>
> ##### Step 1: Attempt Write on Read-Only Filesystem
>
> Starten Sie einen einfachen Container mit `--read-only` und versuchen Sie, eine Datei im Root-Verzeichnis zu erstellen.
> ```bash
> podman run --rm --read-only --name readonly-test alpine:latest sh -c "touch /test.txt"
> ```
> **Result:** Sie erhalten einen Fehler wie `touch: /test.txt: Read-only file system`.
>
> ##### Step 2: Provide Writable Location via Volume
>
> Erstellen Sie ein temporäres Volume und starten Sie den Container erneut, wobei Sie das Volume mounten.
> ```bash
> # Ensure no conflicts
> podman rm -f readonly-vol-test
> podman volume create temp_write_data
>
> podman run --rm --read-only --name readonly-vol-test \
>   --mount type=volume,source=temp_write_data,target=/data `# Mount volume at /data` \
>   alpine:latest \
>   sh -c 'touch /data/test.txt && echo "Write successful to /data!" && ls -l /data'
> #        ^-- Single quote here           ^-- Double quotes inside --^
> ```
> **Result:** Der Befehl ist erfolgreich! Das Schreiben nach `/data` funktioniert, da es ein beschreibbares Volume ist, während der Rest des Dateisystems (`/`) schreibgeschützt bleibt.
>
> ##### Step 3: Provide Writable Location via tmpfs
>
> `tmpfs`-Mounts erstellen ein temporäres Dateisystem im Arbeitsspeicher des Containers. Es ist beschreibbar, aber die Daten gehen verloren, wenn der Container stoppt (noch flüchtiger als das Container-Dateisystem).
> **Syntax:** `podman run ... --tmpfs /path/in/container[:OPTIONS] ...`
> **Syntax (--mount):** `podman run ... --mount type=tmpfs,target=/path/in/container[,OPTIONS] ...`
> ```bash
> # Ensure no conflicts
> podman rm -f readonly-tmpfs-test
>
> podman run --rm --read-only --name readonly-tmpfs-test \
>   --mount type=tmpfs,target=/tmp `# Mount tmpfs at /tmp` \
>   alpine:latest \
>   sh -c 'touch /tmp/tempfile.txt && echo "Write successful to /tmp!" && ls -l /tmp'
> #        ^-- Single quote here           ^-- Double quotes inside --^
> ```
> **Result:** Der Befehl ist erfolgreich. `/tmp` ist beschreibbar, aber sein Inhalt würde einen Container-Stopp nicht überleben.
>
> ##### Step 4: Applying `--read-only` to the Flask App
>
> Nun wenden wir das Konzept auf unsere Flask-Anwendung an. Da unsere App nur in das `/data`-Verzeichnis schreibt (welches wir als Volume mounten) und die Secrets standardmäßig read-only gemountet werden, sollte der Start mit `--read-only` funktionieren.
> **Voraussetzungen:** Bevor Sie den nächsten Befehl ausführen, stellen Sie sicher, dass die folgenden Elemente aus den vorherigen Übungen vorhanden sind:
> 1.  Das Volume `flask_app_data` muss existieren. (Erstellt in Ex. 2 oder 3). Falls nicht:
>     ```bash
>     podman volume create flask_app_data
>     ```
> 2.  Das Secret `db_password` muss existieren. (Erstellt in Ex. 5). Falls nicht:
>     ```bash
>     echo "MySuperSecretDBPassw0rd!" | podman secret create db_password -
>     ```
> 3.  Das Image `my-flask-app:1.1` muss den Code zur Verarbeitung des Secrets enthalten. (Gebaut nach der Code-Änderung in Ex. 5, Step 3). Falls nicht, stellen Sie sicher, dass der Code in `app.py` aktualisiert wurde und führen Sie aus:
>     ```bash
>     # Nur wenn das Image nicht den Secret-Code enthält:
>     # (Im Verzeichnis my_flask_app ausführen)
>     # podman build -t my-flask-app:1.1 .
>     ```
>
> Bereinigen Sie einen eventuell vorhandenen alten Container:
> ```bash
> podman rm -f my-readonly-app
> ```
> Starten Sie nun den Flask-App-Container mit `--read-only`:
> ```bash
> # Starten Sie den Flask-App-Container schreibgeschützt
> podman run -d --read-only \
>  -p 5000:5000 \
>  --name my-readonly-app \
>  --mount type=volume,source=flask_app_data,target=/data `# Beschreibbares Volume für Zähler` \
>  -e GREETING="Read-Only Secure App" \
>  --secret source=db_password,target=db_password `# Secret wird read-only gemountet` \
>  my-flask-app:1.1
> ```
> **Verifizieren:**
> ```bash
> # Testen Sie, ob die App antwortet und der Zähler funktioniert
> sleep 2 # Give container time to start
> curl http://localhost:5000
> curl http://localhost:5000
>
> # Prüfen Sie die Logs auf Fehler (sollten keine im Zusammenhang mit Read-Only FS sein)
> podman logs my-readonly-app
> ```
> **Result:** Die App sollte funktionieren und der Zähler hochzählen, da der einzige Schreibvorgang in das explizit gemountete Volume `/data` erfolgt.
> **Aufräumen für diesen Schritt:**
> ```bash
> podman stop my-readonly-app && podman rm my-readonly-app
> ```
>
> ##### Step 5: Clean Up
>
> Bereinigen Sie die Ressourcen aus dieser Übung und potenziell übrig gebliebene Container/Volumes aus dem gesamten Abschnitt 5:
> ```bash
> # Clean up volumes from this exercise
> podman volume rm temp_write_data
>
> # Ensure all test containers from this entire section are removed
> podman rm -f my-persistent-app my-env-app my-secret-app my-secret-app-bindmount secret-env-test-inspect my-limited-app my-readonly-app readonly-test readonly-vol-test readonly-tmpfs-test binder-test binder-file-test data-writer-vol data-reader-vol data-inspector
>
> # Optionally remove the flask app volume and secrets if done with the section
> podman volume rm flask_app_data
> podman secret rm db_password
> podman secret rm mysql_root_password
> # Optional: Remove flask app directory
> cd ..
> rm -rf my_flask_app
> ```
> `--read-only` ist eine starke Sicherheitsmaßnahme, erfordert aber sorgfältige Planung der schreibbaren Pfade.

---

> #### Best Practices: Running Applications & Configuration
>
> *   **Bind Mounts:** Für Entwicklung (Code) und Host-Konfigurationsdateien. Auf Pfade und Berechtigungen achten (:z/:Z für SELinux). Relative Pfade für Portabilität innerhalb eines Projekts nutzen.
> *   **Volumes (`-v` oder `--mount`):** Verwenden Sie **benannte Volumes** für persistente Anwendungsdaten (DBs, State). Bevorzugt gegenüber Bind Mounts für Portabilität.
> *   **Volume Management:** `podman volume create/ls/inspect/rm/prune` verwenden. Volumes separat sichern.
> *   **`--mount` Syntax bevorzugen:** Ist expliziter und flexibler als die `-v` Syntax.
> *   **Konfiguration:** Extern halten (Env Vars `-e`, `--env-file`, Config Files via Bind Mount oder ConfigMaps in Kube YAML). `.env`-Dateien nicht für Secrets verwenden, die ins Repository gelangen.
> *   **Secrets Management (`--secret`):** Verwenden Sie **Podman-verwaltete Secrets** (`podman secret create`) für sensible Daten. Injizieren Sie sie als **Dateien** (Standard) oder als **Umgebungsvariablen** (`type=env`), je nachdem, was die Anwendung benötigt. Wenn Probleme auftreten, ist ein Read-Only Bind Mount eine Alternative zur Datei-Methode. Der Wert von Secrets, die als Umgebungsvariablen injiziert werden, wird in `podman inspect` maskiert.
> *   **Ressourcenlimits (`--memory`, `--cpus`):** Setzen Sie Limits für Stabilität. Die Durchsetzung und Berichterstattung (via `inspect`) kann von der cgroups-Version und dem rootless/rootful-Status abhängen.
> *   **Read-Only Root FS (`--read-only`):** Erhöht die Sicherheit signifikant. Erfordert explizite Volumes oder `--tmpfs` für alle Schreibpfade. Unterscheidet sich vom Mount-spezifischen `:ro`.
> *   **Tmpfs Mounts (`--tmpfs`):** Für temporäre In-Memory-Daten, die nicht persistiert werden müssen.
> *   **Restart Policies (`--restart`):** Definieren Sie, wie Container bei Fehlern oder Neustarts behandelt werden sollen (z.B. `unless-stopped`, `on-failure`).
> *   Healthchecks (`HEALTHCHECK` im Containerfile) definieren.

### Key Takeaways

*   Containerisierte Anwendungen benötigen sorgfältiges Datenmanagement.
*   **Bind Mounts** verbinden Host-Pfade mit Containern (gut für Dev/Config). Relative Pfade verwenden! SELinux-Kontext beachten. Die Option `:ro` / `,readonly` macht nur den Mount schreibgeschützt.
*   **Named Volumes** sind die bevorzugte Methode für persistente Anwendungsdaten (verwaltet von Podman).
*   `podman volume` dient zur Verwaltung von Volumes.
*   Die **`--mount` Syntax** ist der explizitere und empfohlene Weg, um Bind Mounts, Volumes und Tmpfs zu definieren.
*   `podman run` bietet Optionen für Ports (`-p`), Namen (`--name`), Mounts (`--mount`, `-v`), Env Vars (`-e`, `--env-file`), Secrets (`--secret`), Limits (`--memory`, `--cpus`), Read-Only FS (`--read-only`) und Tmpfs (`--tmpfs`).
*   Sicherheit durch **Podman-verwaltete Secrets** (`podman secret create`, `--secret source=NAME,target=FILE` oder `--secret source=NAME,type=env,target=ENV_VAR`) und das globale **`--read-only`** Flag (erfordert explizite writable Mounts für benötigte Pfade) erhöhen.