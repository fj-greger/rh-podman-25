# Podman Lernmaterial

---

## 4 - Creating Custom Container Images

### 4 - Creating Custom Container Images

Wir erstellen eigene **Custom Images**, um Applikationen zu packagen.

#### Was sind Custom Container Images?

Ein **Container Image** ist ein leichtes, unveränderliches Paket. Ein **Custom Image** wird spezifisch für eigene Bedürfnisse erstellt.

**Why create?** Packaging, Consistency, Reproducibility, Automation, Optimization.

#### Das `Containerfile` (oder `Dockerfile`)

Der Bauplan mit Instructions (`FROM`, `COPY`, `RUN`, etc.), der Layer für Layer das Image aufbaut.

---

> ##### Exercise 1: Building a Custom HTML Image
>
> ### Step-by-Step Guide: Custom HTML Image
>
> ##### Step 1: Projekt-Setup und `Containerfile`
>
> 1.  Verzeichnis `my_html_image/` erstellen, hineinwechseln.
> 2.  `index.html` erstellen:
>     ```html
>     <!DOCTYPE html>
>     <html>
>       <head>
>         <title>Meine Custom Seite</title>
>       </head>
>       <body>
>         <h1>Hallo von meinem Custom Container Image!</h1>
>         <p>Diese Seite wird von einem Podman-Container ausgeliefert.</p>
>       </body>
>     </html>
>     ```
> 3.  `Containerfile` erstellen:
>     ```dockerfile
>     # Base Image (mit spezifischem Tag)
>     FROM httpd:2.4-alpine
>
>     # Metadaten (Best Practice)
>     LABEL maintainer="Ihr Name <ihre@email.com>" \
>           version="1.0" \
>           description="Einfaches Custom Apache Image mit statischer Seite."
>
>     # Kopiere Inhalt vom Build Context ins Image
>     COPY index.html /usr/local/apache2/htdocs/
>
>     # Dokumentiere Port
>     EXPOSE 80
>     ```
>     **Explanation of Instructions:**
>     *   `FROM ...`: Basis-Image.
>     *   `LABEL ...`: Metadaten.
>     *   `COPY <src> <dest>`: Kopiert vom Build Context (`<src>`) ins Image (`<dest>`).
>     *   `EXPOSE <port>`: **Dokumentation** des Ports, auf dem die Anwendung *im Container* lauscht. Öffnet den Port *nicht* am Host (dafür ist `-p` bei `podman run` zuständig).
>
> ##### Step 2: Das Custom Image builden
>
> Im Verzeichnis `my_html_image/`:
>
> **Syntax:** `podman build [OPTIONS] CONTEXT_DIRECTORY`
> ```bash
> podman build -t my-custom-webserver .
> ```
> *   `-t my-custom-webserver`: Taggt das Image.
> *   `.` (Dot): Der **Build Context**. Pfade in `COPY`/`ADD` sind relativ zu diesem Verzeichnis. **Best Practice:** Halten Sie den Kontext klein und nutzen Sie `.containerignore`.
>
> ##### Step 3: Das Image verifizieren
>
> ```bash
> podman images
> podman inspect localhost/my-custom-webserver | jq '.[0].Labels'
> ```
>
> ##### Step 4: Einen Container aus dem Image starten
>
> > **Wichtig: Port-Konflikt!** Stellen Sie sicher, dass Host-Port 8080 frei ist.
> > ```bash
> > podman stop my-web-server
> > ```
>
> ```bash
> podman run -d -p 8080:80 --name my-custom-run my-custom-webserver
> ```
> **Testen:** Öffnen Sie `http://localhost:8080`.
>
> Bereinigen:
> ```bash
> podman stop my-custom-run && podman rm my-custom-run
> ```
>
> > ##### Best Practices für Custom Images (Zusammenfassung)
> >
> > *   Minimal Base Image & Specific Tags.
> > *   Multi-Stage Builds.
> > *   Minimize Layers & Clean Up.
> > *   Run as Non-Root User (`USER`).
> > *   Order matters for Cache.
> > *   `.containerignore`.
> > *   Security Scans (`Trivy` etc.).
> > *   Metadaten (`LABEL`).
>
> ### Tagging und Versioning
>
> ```bash
> podman build -t myapp:1.0.1 -t myapp:latest .
> podman tag myapp:1.0.1 registry.example.com/username/myapp:1.0.1
> ```
>
> ### Images in eine Registry pushen
>
> ```bash
> podman login registry.example.com
> podman push registry.example.com/username/myapp:1.0.1
> ```
> **Understanding Full Image Names for Registries:**
>
> Wenn Sie ein Image in eine Registry (wie Docker Hub, Quay.io oder eine private Registry) pushen möchten, benötigt Podman den vollständigen Namen des Images im Format:
>
> `<registry_host>/<namespace_or_username>/<repository_name>:<tag>`
>
> *   `<registry_host>`: Die Adresse der Registry (z.B. `docker.io`, `quay.io`, `registry.example.com`). Für Docker Hub wird `docker.io` oft weggelassen, wenn es die Standard-Registry ist.
> *   `<namespace_or_username>`: Ihr Benutzername oder der Name der Organisation/des Projekts in der Registry. Für offizielle Docker Hub Images ist dies oft `library` (kann auch weggelassen werden).
> *   `<repository_name>`: Der Name Ihres Images/Ihrer Anwendung (z.B. `myapp`, `my-webserver`).
> *   `<tag>`: Die spezifische Version (z.B. `1.0.1`, `latest`, `stable`).
>
> Da Sie Ihr Image lokal oft nur mit einem einfachen Namen wie `myapp:1.0.1` bauen, müssen Sie Podman mitteilen, wohin genau dieses Image gepusht werden soll. Der Befehl `podman tag` wird verwendet, um Ihrem lokalen Image diesen vollständigen Registry-Pfad als zusätzlichen Tag zuzuweisen. Erst danach weiß `podman push`, an welche Zieladresse in welcher Registry das Image gesendet werden soll.
>
> Beispiel:
> ```bash
> # Lokales Image: myapp:1.0.1
> # Ziel: Docker Hub unter Ihrem Benutzernamen 'meinuser'
> podman tag myapp:1.0.1 docker.io/meinuser/myapp:1.0.1
> podman push docker.io/meinuser/myapp:1.0.1
> ```
>
> ### Key Takeaways
>
> *   Custom Images -> Eigene Apps containerisieren.
> *   `Containerfile` -> Bauplan (`FROM`, `COPY`, `RUN`...).
> *   `podman build -t name:tag .` -> Image erstellen.
> *   Best Practices -> Effiziente, sichere Images.
> *   Tags & Registries -> Versionierung & Teilen.

---

> ##### Exercise 2: Excluding Files with `.containerignore`
>
> Ähnlich wie `.gitignore` bei Git, können Sie eine `.containerignore`-Datei verwenden, um zu verhindern, dass bestimmte Dateien oder Verzeichnisse Teil des **Build Context** werden, der an die Podman Engine gesendet wird. Dies ist wichtig, um:
> *   Den Build Context klein zu halten (schnellere Übertragung).
> *   Unnötige Dateien (Logs, temporäre Dateien) auszuschließen.
> *   Sensible Daten (Secrets, Konfigurationsdateien mit Passwörtern, `.git`-Verzeichnis) nicht versehentlich ins Image zu kopieren.
>
> ##### Step 1: Setup Project Files
>
> 1.  Erstellen Sie ein Verzeichnis `ignore_test/` und wechseln Sie hinein.
> 2.  Erstellen Sie einige Dateien:
>     ```bash
>     echo "Wichtiger App-Code" > app.py
>     echo "Dies ist eine temporäre Log-Datei" > temp.log
>     echo "Mein super geheimes Passwort" > secret.key
>     mkdir .git # Simuliere ein Git-Verzeichnis
>     echo "Git-Objekt" > .git/config
>     ```
> 3.  Erstellen Sie ein einfaches `Containerfile`, das alles kopiert:
>     ```dockerfile
>     FROM alpine:latest
>
>     # WORKDIR setzt das Arbeitsverzeichnis für nachfolgende RUN, CMD, ENTRYPOINT, COPY, ADD Befehle.
>     WORKDIR /app
>
>     # Kopiert ALLES aus dem Build Context nach /app im Image
>     COPY . .
>     CMD ["ls", "-la", "/app"]
>     ```
>     **Hinweis zu `WORKDIR`:** Diese Anweisung setzt das Standardverzeichnis für alle nachfolgenden Befehle im Containerfile. Es ist eine gute Praxis, ein `WORKDIR` zu definieren, anstatt sich auf absolute Pfade in `RUN`, `COPY` etc. zu verlassen.
>
> ##### Step 2: Build Without `.containerignore`
>
> Bauen Sie das Image und sehen Sie nach, was kopiert wurde.
> ```bash
> podman build -t ignore-demo:v1 .
> podman run --rm ignore-demo:v1
> ```
> **Result:** Sie sehen `app.py`, `temp.log`, `secret.key` und das `.git` Verzeichnis in der Ausgabe. Alles wurde kopiert!
>
> ##### Step 3: Create `.containerignore`
>
> Erstellen Sie eine Datei namens `.containerignore` im Verzeichnis `ignore_test/` mit folgendem Inhalt:
> ```nohighlight
> # Ignoriere Log-Dateien
> *.log
>
> # Ignoriere Schlüsseldateien
> *.key
>
> # Ignoriere das gesamte .git Verzeichnis
> .git/
>
> # Ignoriere die Containerfile selbst (oft sinnvoll)
> Containerfile
> .containerignore
> ```
> Die Syntax ist ähnlich wie bei `.gitignore`.
>
> ##### Step 4: Rebuild With `.containerignore`
>
> Bauen Sie das Image erneut.
> ```bash
> podman build -t ignore-demo:v2 .
> podman run --rm ignore-demo:v2
> ```
> **Result:** Jetzt sehen Sie nur noch `app.py` in der Ausgabe. Die ignorierten Dateien und das `.git`-Verzeichnis wurden nicht Teil des Build Context und somit nicht ins Image kopiert.
>
> ##### Step 5: Clean Up
>
> ```bash
> podman rmi ignore-demo:v1 ignore-demo:v2
> cd ..
> rm -rf ignore_test/
> ```
> Die Verwendung von `.containerignore` ist eine wichtige Best Practice für saubere und sichere Builds.

---

> ##### Exercise 3: Understanding Build Cache and Layering (`podman history`)
>
> Wie erwähnt, bestehen Images aus Layern. Podman nutzt einen Build-Cache: Wenn Sie ein Image erneut bauen und sich eine Anweisung (und die Dateien, die sie verwendet, wie bei `COPY`) nicht geändert hat, verwendet Podman den zwischengespeicherten Layer aus dem vorherigen Build, anstatt die Anweisung erneut auszuführen. Dies beschleunigt den Build-Prozess erheblich. Änderungen in einer Anweisung machen den Cache für *diese* und *alle nachfolgenden* Anweisungen ungültig.
> Wir verwenden `podman history`, um die Layer zu sehen, und beobachten das Cache-Verhalten.
>
> ##### Step 1: Create Files and Containerfile
>
> 1.  Erstellen Sie ein neues Verzeichnis, z.B. `layer_test/`, und wechseln Sie hinein.
> 2.  Erstellen Sie zwei einfache Textdateien:
>     ```bash
>     echo "Inhalt von Datei 1" > file1.txt
>     echo "Inhalt von Datei 2" > file2.txt
>     ```
> 3.  Erstellen Sie ein `Containerfile`:
>     ```dockerfile
>     # Base Image
>     FROM alpine:latest
>
>     LABEL description="Demo für Layer und Cache"
>
>     # Erste Aktion: Paket installieren
>     RUN apk add --no-cache curl
>
>     # Zweite Aktion: Verzeichnis erstellen
>     RUN mkdir /data
>
>     # Dritte Aktion: Erste Datei kopieren
>     COPY file1.txt /data/
>
>     # Vierte Aktion: Zweite Datei kopieren
>     COPY file2.txt /data/
>
>     CMD ["ls", "-l", "/data"]
>     ```
>
> ##### Step 2: First Build
>
> Bauen Sie das Image zum ersten Mal.
> **Command:**
> ```bash
> podman build -t layer-demo:v1 .
> ```
> **Observe:** Achten Sie auf die Build-Ausgabe. Jeder Schritt (`RUN`, `COPY`, `LABEL`, `CMD`) wird ausgeführt.
>
> ##### Step 3: Inspect History
>
> Sehen Sie sich die Layer an, die erstellt wurden.
> **Command:**
> ```bash
> podman history layer-demo:v1
> ```
> **Result:** Sie sehen die Layer, die den Anweisungen im Containerfile entsprechen (`CMD` und `LABEL` erzeugen oft 0-Byte-Layer, die nur Metadaten ändern).
>
> ##### Step 4: Modify a File and Rebuild
>
> 1.  Ändern Sie nur den Inhalt der *zweiten* Datei:
>     ```bash
>     echo "Geänderter Inhalt von Datei 2" > file2.txt
>     ```
> 2.  Bauen Sie das Image erneut mit einem neuen Tag:
>     **Command:**
>     ```bash
>     podman build -t layer-demo:v2 .
>     ```
>     **Observe:** Achten Sie genau auf die Ausgabe! Sie werden sehen, dass die Schritte für `FROM`, `LABEL`, die beiden `RUN`-Befehle und das erste `COPY file1.txt` den Cache verwenden (z.B. "Using cache ..."). Erst ab dem Schritt `COPY file2.txt` (da sich `file2.txt` geändert hat) und für alle *nachfolgenden* Schritte (hier nur `CMD`) wird der Build tatsächlich ausgeführt und neue Layer werden erstellt.
>
> ##### Step 5: Clean Up
>
> ```bash
> podman rmi layer-demo:v1 layer-demo:v2
> cd ..
> rm -rf layer_test/
> ```

---

> ##### Exercise 4: Optimizing Layer Order for Cache
>
> Die Reihenfolge der Anweisungen in Ihrem `Containerfile` hat einen großen Einfluss darauf, wie effektiv der Build-Cache genutzt werden kann. Da der Cache bei der ersten Änderung invalidiert wird, sollten Anweisungen, die sich selten ändern (wie die Installation von Systempaketen oder Abhängigkeiten), möglichst früh stehen. Anweisungen, die sich häufig ändern (wie das Kopieren Ihres Anwendungscodes), sollten später stehen.
> Wir demonstrieren dies am Beispiel einer Python-Anwendung.
>
> ##### Step 1: Setup Project Files
>
> 1.  Erstellen Sie ein Verzeichnis `cache_order_test/` und wechseln Sie hinein.
> 2.  Erstellen Sie `requirements.txt`:
>     ```nohighlight
>     Flask>=2.3
>     ```
> 3.  Erstellen Sie `app.py`:
>     ```python
>     from flask import Flask
>     app = Flask(__name__)
>     @app.route('/')
>     def hello():
>         return "Version 1 der App"
>     if __name__ == '__main__':
>         app.run(host='0.0.0.0', port=5000)
>     ```
>
> ##### Step 2: Build with Suboptimal Order
>
> Erstellen Sie `Containerfile.bad`:
> ```dockerfile
> # Suboptimal Order
> FROM python:3.12-slim
> WORKDIR /app
> # 1. Code kopieren (ändert sich oft)
> COPY . .
> # 2. Dependencies installieren (ändert sich selten)
> RUN pip install --no-cache-dir -r requirements.txt
> CMD ["python", "app.py"]
> ```
> Bauen Sie das Image:
> ```bash
> podman build -t cache-order:bad -f Containerfile.bad .
> ```
> Ändern Sie nun `app.py` (z.B. ändern Sie "Version 1" zu "Version 2").
> ```bash
> # Bearbeiten Sie app.py...
> podman build -t cache-order:bad-rebuild -f Containerfile.bad .
> ```
> **Observe:** Achten Sie auf die Build-Ausgabe. Da sich der `COPY . .` Schritt geändert hat (wegen `app.py`), wird der Cache invalidiert, und der nachfolgende `RUN pip install...` Schritt wird **erneut ausgeführt**, obwohl sich `requirements.txt` nicht geändert hat. Das ist ineffizient.
>
> ##### Step 3: Build with Optimal Order
>
> Erstellen Sie `Containerfile.good`:
> ```dockerfile
> # Optimal Order
> FROM python:3.12-slim
> WORKDIR /app
>
> # 1. Dependencies installieren (ändert sich selten)
> # Kopiere zuerst nur die requirements.txt
> COPY requirements.txt .
> # Installiere Dependencies und räume den Cache im selben RUN-Schritt auf
> # --no-cache-dir verhindert, dass pip einen Cache schreibt
> # Alternativ bei apt: rm -rf /var/lib/apt/lists/*
> RUN pip install --no-cache-dir -r requirements.txt
>
> # 2. Code kopieren (ändert sich oft)
> # Kopiere den Rest der Anwendung erst jetzt
> COPY . .
>
> CMD ["python", "app.py"]
> ```
> Stellen Sie sicher, dass `app.py` immer noch die "Version 2" enthält. Bauen Sie das Image:
> ```bash
> podman build -t cache-order:good -f Containerfile.good .
> ```
> Ändern Sie nun `app.py` erneut (z.B. zu "Version 3").
> ```bash
> # Bearbeiten Sie app.py...
> podman build -t cache-order:good-rebuild -f Containerfile.good .
> ```
> **Observe:** Achten Sie auf die Build-Ausgabe. Der Schritt `COPY requirements.txt .` und der `RUN pip install...` Schritt verwenden den Cache ("Using cache..."). Nur der letzte `COPY . .` Schritt (und `CMD`) wird neu ausgeführt. Die Installation der Abhängigkeiten wurde übersprungen, was den Build viel schneller macht.
>
> ##### Step 4: Clean Up
>
> ```bash
> podman rmi cache-order:bad cache-order:bad-rebuild cache-order:good cache-order:good-rebuild
> cd ..
> rm -rf cache_order_test/
> ```
> Die richtige Reihenfolge der Anweisungen ist entscheidend für schnelle und effiziente Builds.

---

> ##### Exercise 5: Optimizing Layers with RUN Chaining and Cleanup
>
> Jede `RUN` Anweisung in einem Containerfile erstellt einen neuen Layer im Image. Um die Image-Größe zu minimieren und Builds effizienter zu gestalten, ist es Best Practice, zusammengehörige Befehle mit `&&` zu verketten und unnötige Dateien (wie Paket-Caches) innerhalb derselben `RUN` Anweisung zu entfernen.
>
> ##### Step 1: Create Containerfile with Separate RUNs (Suboptimal)
>
> Erstellen Sie ein Verzeichnis `run_chain_test/`, wechseln Sie hinein und erstellen Sie `Containerfile.separate`:
> ```dockerfile
> # Suboptimal: Separate RUN commands
> FROM ubuntu:latest
>
> # Update package list
> RUN apt-get update
>
> # Install curl
> RUN apt-get install -y curl
>
> # Install wget
> RUN apt-get install -y wget
>
> # (Cleanup would be in another layer, ineffective)
> CMD ["curl", "--version"]
> ```
> Bauen Sie dieses Image:
> ```bash
> podman build -t run-separate -f Containerfile.separate .
> ```
> Überprüfen Sie die Layer:
> ```bash
> podman history run-separate
> ```
> **Observe:** Sie sehen separate Layer für `apt-get update` und jede `apt-get install` Anweisung. Der Paket-Cache von `apt-get update` bleibt in einem früheren Layer, auch wenn er später nicht mehr benötigt wird.
>
> ##### Step 2: Create Containerfile with Chained RUN (Optimal)
>
> Erstellen Sie nun `Containerfile.chained` im selben Verzeichnis:
> ```dockerfile
> # Optimal: Chained RUN command with cleanup
> FROM ubuntu:latest
>
> RUN apt-get update && \
>     apt-get install -y curl wget && \
>     rm -rf /var/lib/apt/lists/*
>
> CMD ["curl", "--version"]
> ```
> **Explanation:**
> *   `&&`: Verkettet die Befehle. Wenn ein Befehl fehlschlägt, werden die nachfolgenden nicht ausgeführt.
> *   `\`: Zeilenfortsetzungszeichen für bessere Lesbarkeit.
> *   `apt-get install -y curl wget`: Installiert beide Pakete in einem Schritt.
> *   `rm -rf /var/lib/apt/lists/*`: Entfernt den APT-Cache **im selben Layer**, in dem die Pakete installiert wurden, wodurch die Image-Größe reduziert wird.
>
> Bauen Sie dieses Image:
> ```bash
> podman build -t run-chained -f Containerfile.chained .
> ```
> Überprüfen Sie die Layer und die Größe:
> ```bash
> podman history run-chained
> podman images | grep run-
> ```
> **Observe:** Sie sehen deutlich weniger Layer als bei `run-separate`. Das `run-chained` Image sollte auch merklich kleiner sein, da der APT-Cache entfernt wurde.
>
> ##### Step 3: Clean Up
>
> ```bash
> podman rmi run-separate run-chained
> cd ..
> rm -rf run_chain_test/
> ```
> Das Verketten von `RUN`-Befehlen und das Aufräumen im selben Schritt ist eine fundamentale Technik zur Optimierung von Container-Images.

---

> ##### Exercise 6: Understanding CMD vs. ENTRYPOINT Interaction
>
> Diese Übung verdeutlicht den Unterschied und das Zusammenspiel von `CMD` und `ENTRYPOINT` bei der Definition des Startbefehls eines Containers.
>
> ##### Step 1: Containerfile with only CMD
>
> Erstellen Sie ein Verzeichnis `cmd_entry_test/`, wechseln Sie hinein und erstellen Sie `Containerfile.cmd`:
> ```dockerfile
> FROM alpine:latest
> # Standardbefehl ist 'echo Hello World'
> CMD ["echo", "Hello World"]
> ```
> Bauen Sie das Image:
> ```bash
> podman build -t cmd-only -f Containerfile.cmd .
> ```
> Führen Sie den Container ohne Argumente aus:
> ```bash
> podman run --rm cmd-only
> ```
> **Result:** Gibt "Hello World" aus (der Standard-CMD wird ausgeführt).
> Führen Sie den Container mit einem Argument aus:
> ```bash
> podman run --rm cmd-only ls -l /
> ```
> **Result:** Gibt die Verzeichnisliste von `/` aus. Der gesamte Standard-CMD (`echo Hello World`) wurde durch `ls -l /` überschrieben.
>
> ##### Step 2: Containerfile with ENTRYPOINT and CMD
>
> Erstellen Sie `Containerfile.entry` im selben Verzeichnis:
> ```dockerfile
> FROM alpine:latest
> # Hauptbefehl ist 'echo'
> ENTRYPOINT ["echo"]
> # Standardargument für echo ist 'Hello Entrypoint'
> CMD ["Hello Entrypoint"]
> ```
> Bauen Sie das Image:
> ```bash
> podman build -t entry-cmd -f Containerfile.entry .
> ```
> Führen Sie den Container ohne Argumente aus:
> ```bash
> podman run --rm entry-cmd
> ```
> **Result:** Gibt "Hello Entrypoint" aus (ENTRYPOINT + CMD).
> Führen Sie den Container mit einem Argument aus:
> ```bash
> podman run --rm entry-cmd Goodbye World
> ```
> **Result:** Gibt "Goodbye World" aus. Nur der `CMD`-Teil (das Argument für `echo`) wurde durch "Goodbye World" überschrieben; das `ENTRYPOINT` (`echo`) blieb bestehen.
>
> ##### Step 3: Clean Up
>
> ```bash
> podman rmi cmd-only entry-cmd
> cd ..
> rm -rf cmd_entry_test/
> ```
> Diese Übung zeigt, wie `ENTRYPOINT` das Hauptkommando festlegt und `CMD` überschreibbare Standardargumente liefert.

---

> ##### Exercise 7: Running as Non-Root User (`USER`)
>
> Aus Sicherheitsgründen ist es eine wichtige Best Practice, Container-Prozesse nicht als Root-Benutzer (UID 0) laufen zu lassen. Die `USER`-Anweisung im `Containerfile` ermöglicht es Ihnen, einen Benutzer und optional eine Gruppe anzugeben, unter dem der Hauptprozess des Containers (und alle nachfolgenden `RUN`, `CMD`, `ENTRYPOINT` Anweisungen) ausgeführt werden soll.
>
> ##### Step 1: Create Containerfile with `USER`
>
> Erstellen Sie ein Verzeichnis `user_test/`, wechseln Sie hinein und erstellen Sie ein `Containerfile`:
> ```dockerfile
> FROM alpine:latest
>
> # Erstelle eine Gruppe 'appgroup' und einen User 'appuser' ohne Login-Shell und Home-Verzeichnis
> # Die UID/GID (hier 1001) sollte idealerweise außerhalb des Bereichs liegen,
> # der typischerweise für Systembenutzer verwendet wird.
> RUN addgroup -g 1001 appgroup && \
>     adduser -u 1001 -G appgroup -D -s /sbin/nologin appuser
>
> # Wechsle zum neu erstellten Benutzer
> USER appuser
>
> # Zeige an, wer der aktuelle Benutzer ist
> CMD ["whoami"]
> ```
> **Explanation:**
> *   `RUN addgroup... && adduser...`: Erstellt die Gruppe und den Benutzer innerhalb des Images. `-D` (oder `--disabled-password`) erstellt einen Benutzer ohne Passwort, `-s /sbin/nologin` verhindert eine interaktive Shell.
> *   `USER appuser`: Legt fest, dass alle folgenden Befehle als `appuser` ausgeführt werden.
> *   `CMD ["whoami"]`: Der Standardbefehl, der beim Start des Containers ausgeführt wird.
>
> ##### Step 2: Build and Run the Image
>
> Bauen Sie das Image und führen Sie einen Container daraus aus.
> ```bash
> podman build -t user-demo .
> podman run --rm user-demo
> ```
> **Result:** Die Ausgabe sollte `appuser` sein, was bestätigt, dass der `CMD`-Befehl als der angegebene Non-Root-Benutzer ausgeführt wurde.
>
> ##### Step 3: Test Permissions (Optional)
>
> Versuchen Sie, als `appuser` in ein Verzeichnis zu schreiben, für das nur Root Rechte hat.
> ```bash
> # Dieser Befehl wird fehlschlagen
> podman run --rm user-demo touch /test.txt
> ```
> **Result:** Sie erhalten einen Fehler wie `touch: /test.txt: Permission denied`, da `appuser` keine Berechtigung hat, im Root-Verzeichnis zu schreiben.
>
> ##### Step 4: Clean Up
>
> ```bash
> podman rmi user-demo
> cd ..
> rm -rf user_test/
> ```
> Die Verwendung von `USER` ist ein fundamentaler Schritt zur Erhöhung der Sicherheit Ihrer Container.

---

> ##### Exercise 8: Defining Container Health Checks (`HEALTHCHECK`)
>
> Ein laufender Container bedeutet nicht unbedingt, dass die darin enthaltene Anwendung korrekt funktioniert. Die `HEALTHCHECK`-Anweisung im `Containerfile` ermöglicht es Ihnen, einen Befehl zu definieren, den Podman periodisch ausführt, um den Gesundheitszustand des Containers zu überprüfen.
> Wenn der Healthcheck fehlschlägt, wird der Container als "unhealthy" markiert. Dies ist besonders nützlich für Orchestrierungstools oder wenn Sie Restart Policies verwenden.
>
> ##### Step 1: Setup Project and Create Files
>
> Wir verwenden das einfache Apache-Image als Basis und fügen `curl` hinzu, um den Webserver zu überprüfen.
> 1.  Erstellen Sie ein Verzeichnis `healthcheck_test/` und wechseln Sie hinein:
>     ```bash
>     mkdir healthcheck_test
>     cd healthcheck_test
>     ```
> 2.  Erstellen Sie eine (leere) `index.html` Datei in diesem Verzeichnis. Der `COPY`-Befehl im nächsten Schritt benötigt diese Datei:
>     ```bash
>     touch index.html
>     ```
> 3.  Erstellen Sie das `Containerfile`:
>     ```dockerfile
>     FROM httpd:2.4-alpine
>
>     LABEL maintainer="Podman Training" description="Apache with Healthcheck"
>
>     # Installiere curl für den Healthcheck
>     # Wichtig: Führen Sie dies *vor* dem HEALTHCHECK aus
>     RUN apk add --no-cache curl
>
>     # Kopiere eine einfache Seite (optional, Standardseite reicht auch)
>     # Wenn eine index.html im Build-Kontext existiert, wird sie kopiert.
>     # Andernfalls wird die Standardseite des httpd-Images verwendet.
>     COPY index.html /usr/local/apache2/htdocs/
>
>     EXPOSE 80
>
>     # Definiere den Healthcheck
>     # --interval=10s: Führe den Check alle 10 Sekunden aus
>     # --timeout=3s: Warte maximal 3 Sekunden auf eine Antwort
>     # --start-period=5s: Warte 5 Sekunden nach Containerstart, bevor der erste Check als Fehler zählt
>     # --retries=3: Versuche es 3 Mal, bevor der Container als unhealthy markiert wird
>     # CMD: Der Befehl zum Ausführen. Muss 0 für healthy, 1 für unhealthy zurückgeben.
>     #      'curl -f' prüft, ob der Server einen erfolgreichen HTTP-Statuscode (2xx, 3xx) zurückgibt.
>     #      ' || exit 1' stellt sicher, dass der Check fehlschlägt (Exit 1), wenn curl fehlschlägt.
>     HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
>       CMD curl -f http://localhost:80 || exit 1
>
>     # Der Standard-CMD von httpd wird verwendet, um den Server zu starten
>     ```
>
> ##### Step 2: Build the Image (Using Docker Format)
>
> **Wichtig:** Damit die `HEALTHCHECK`-Anweisung von Podman berücksichtigt wird, muss das Image im Docker-v2-Format gebaut werden, da das standardmäßige OCI-Format diese Anweisung (noch) nicht unterstützt. Fügen Sie die Option `--format docker` hinzu:
> ```bash
> podman build --format docker -t healthcheck-demo .
> ```
>
> > **OCI vs. Docker Format:** OCI (Open Container Initiative) ist ein offener Standard für Container-Images und Runtimes. Docker v2 ist das ältere, von Docker entwickelte Format. Während Podman beide unterstützt und OCI bevorzugt, implementieren noch nicht alle Tools (oder alle Features in Podman selbst) die volle OCI-Spezifikation, weshalb für bestimmte Features wie `HEALTHCHECK` manchmal das Docker-Format erforderlich ist.
>
> ##### Step 3: Run the Container and Verify Health Status
>
> Starten Sie den Container.
> ```bash
> podman run -d --name healthy-server -p 8081:80 healthcheck-demo
> ```
> Beobachten Sie den Status mit `podman ps` über einige Zeit, um die automatische Überprüfung zu sehen:
> ```bash
> # Warten Sie ca. 10-15 Sekunden...
> watch podman ps --filter name=healthy-server
> ```
> **Observe (watch):** Nach der `start-period` (5s) *sollte* der Status in der `podman ps`-Ausgabe von `(starting)` zu `(healthy)` wechseln. (Beenden Sie `watch` mit `Ctrl+C`).
> Führen Sie zusätzlich den Healthcheck manuell aus, um den aktuellen Zustand explizit abzufragen:
> ```bash
> podman healthcheck run healthy-server
> # Überprüfen Sie den Exit-Code (sollte 0 sein)
> echo $? # (oder die Entsprechung für Ihre Shell)
> ```
> **Observe (manual):** Der Befehl sollte erfolgreich sein (keine Fehlermeldung) und der Exit-Code sollte 0 sein, was den Status "healthy" bestätigt.
>
> ##### Step 4: Simulate Failure and Verify Status Change
>
> Um einen Fehler zu sehen, können wir den Zugriff auf die `index.html`-Datei verhindern, sodass Apache einen Fehler zurückgibt:
> ```bash
> # Ändert die Berechtigungen, sodass Apache die Datei nicht lesen kann
> podman exec healthy-server chmod 000 /usr/local/apache2/htdocs/index.html
> ```
> Beobachten Sie nun erneut den Status mit `podman ps`. Warten Sie etwas länger als das Intervall multipliziert mit den Retries (z.B. 10s * 3 = 30 Sekunden, plus etwas Puffer), damit Podman Zeit hat, den Fehler zu erkennen.
> ```bash
> # Warten Sie ca. 35-40 Sekunden und beobachten Sie die Ausgabe...
> watch podman ps --filter name=healthy-server
> ```
> **Observe (watch):** Da Apache die Datei nicht lesen kann (403 Forbidden), schlägt der `curl -f`-Befehl im Healthcheck fehl. Nach der konfigurierten Anzahl von `retries` (3) *sollte* der Status des Containers in der `podman ps`-Ausgabe von `(healthy)` zu `(unhealthy)` wechseln. (Beenden Sie `watch` mit `Ctrl+C`).
> Führen Sie zusätzlich den Healthcheck manuell aus:
> ```bash
> podman healthcheck run healthy-server
> # Überprüfen Sie den Exit-Code (sollte 1 sein)
> echo $? # (oder die Entsprechung für Ihre Shell)
> ```
> **Observe (manual):** Der Befehl `podman healthcheck run` sollte nun fehlschlagen und der Exit-Code sollte 1 sein, was den Status "unhealthy" bestätigt.
>
> > **Hinweis:** Wenn der Status in `podman ps` nicht zuverlässig auf `(unhealthy)` wechselt, ist der Exit-Code von `podman healthcheck run` (oder die Logs in `podman inspect`) die zuverlässigste Methode, um den Fehlschlag zu überprüfen.
>
> (Optional: Setzen Sie die Berechtigungen zurück: `podman exec healthy-server chmod 644 /usr/local/apache2/htdocs/index.html`)
>
> ##### Step 5: Clean Up
>
> ```bash
> podman rm -f healthy-server
> podman rmi healthcheck-demo
> cd ..
> rm -rf healthcheck_test/
> ```
> `HEALTHCHECK` ist entscheidend für robuste Container-Deployments.

---

> ##### Exercise 9: Using Build Arguments (`ARG`)
>
> Mit der `ARG`-Anweisung können Sie Variablen definieren, die Benutzer zur Build-Zeit mit der Option `--build-arg <varname>=<value>` an den Builder übergeben können. Dies ist nützlich, um Builds anzupassen, ohne das `Containerfile` direkt ändern zu müssen, z.B. um Versionen von Abhängigkeiten oder Basis-Images festzulegen.
> **Wichtig:** `ARG`-Variablen sind nur während des Build-Prozesses verfügbar und nicht Teil des finalen Images oder der laufenden Container-Umgebung (im Gegensatz zu `ENV`).
>
> ##### Step 1: Create Containerfile with `ARG`
>
> Erstellen Sie ein Verzeichnis `arg_test/`, wechseln Sie hinein und erstellen Sie ein `Containerfile`:
> ```dockerfile
> # Definiere Build-Argumente mit Standardwerten
> ARG BASE_IMAGE=alpine
> ARG BASE_TAG=latest
> ARG APP_VERSION=1.0-snapshot
>
> # Verwende ARG-Werte in FROM und LABEL
> FROM ${BASE_IMAGE}:${BASE_TAG}
>
> # Re-declare ARGs after FROM to make them available in this build stage
> # Their values will be the ones passed via --build-arg or the initial defaults
> ARG BASE_IMAGE
> ARG BASE_TAG
> ARG APP_VERSION
>
> LABEL maintainer="Podman Training" \
>       version="${APP_VERSION}" \
>       base="${BASE_IMAGE}:${BASE_TAG}"
>
> # Definiere ein weiteres ARG *nach* FROM (optional, nur hier gültig)
> ARG BUILD_MESSAGE="Default Build"
>
> # Gib die Werte während des Builds aus (nur zur Demo)
> RUN echo "Building version ${APP_VERSION} based on ${BASE_IMAGE}:${BASE_TAG}"
> RUN echo "Build message: ${BUILD_MESSAGE}"
>
> # Zeige die Werte im laufenden Container (nur zur Demo, ARG ist hier nicht mehr direkt verfügbar)
> # Wir verwenden die Labels, um die Werte zu sehen, die *während des Builds* gesetzt wurden.
> # Dieses CMD funktioniert in Alpine nicht direkt, da podman/jq nicht installiert sind.
> # Es dient nur der Veranschaulichung des Konzepts.
> CMD ["sh", "-c", "echo '--- Runtime Info ---' && echo 'Labels:' && cat /proc/self/environ | tr '\\0' '\\n' | grep PODMAN_LABELS && echo 'Actual OS:' && cat /etc/os-release | grep PRETTY_NAME"]
> ```
>
> > **Hinweis zum CMD:** Das `CMD` in diesem Beispiel versucht, die zur Build-Zeit gesetzten Labels über Umgebungsvariablen zu finden, die Podman manchmal setzt, oder liest die OS-Release-Datei. Dies dient nur dazu, die Auswirkungen der `ARG`-Werte zu demonstrieren, da die `ARG`-Werte selbst zur Laufzeit nicht verfügbar sind. Ein realistischeres `CMD` würde die über `ARG` konfigurierten Werte nicht direkt benötigen.
>
> ##### Step 2: Build with Default Arguments
>
> Bauen Sie das Image ohne `--build-arg`.
> ```bash
> podman build -t arg-demo:default .
> ```
> **Observe:** Achten Sie auf die `RUN echo` Ausgaben während des Builds. Sie sollten die Standardwerte sehen ("1.0-snapshot", "alpine:latest", "Default Build").
> ```bash
> # Prüfen Sie die Labels des Images
> podman inspect arg-demo:default | jq '.[0].Config.Labels'
> ```
> **Result:** Die Labels zeigen die Standardwerte.
>
> ##### Step 3: Build with Custom Arguments
>
> Bauen Sie das Image erneut und übergeben Sie Werte mit `--build-arg`.
> ```bash
> podman build \
>   --build-arg BASE_TAG=3.18 \
>   --build-arg APP_VERSION=2.1-final \
>   --build-arg BUILD_MESSAGE="Release Build" \
>   -t arg-demo:custom .
> ```
> **Observe:** Die `RUN echo` Ausgaben zeigen nun die übergebenen Werte.
> ```bash
> # Prüfen Sie die Labels des Images
> podman inspect arg-demo:custom | jq '.[0].Config.Labels'
> ```
> **Result:** Die Labels zeigen die benutzerdefinierten Werte. Das Basis-Image wäre nun `alpine:3.18`.
>
> ##### Step 4: Clean Up
>
> ```bash
> podman rmi arg-demo:default arg-demo:custom
> cd ..
> rm -rf arg_test/
> ```
> `ARG` ermöglicht flexible und anpassbare Builds.

---

> ##### Exercise 10: Setting Environment Variables (`ENV`)
>
> Die `ENV`-Anweisung setzt Umgebungsvariablen innerhalb des Images. Diese Variablen sind sowohl für nachfolgende Anweisungen im `Containerfile` (wie `RUN`) als auch für die Anwendung verfügbar, die im Container läuft.
> Im Gegensatz zu `ARG` (Build-Zeit) sind `ENV`-Variablen Teil des finalen Images und der Laufzeitumgebung des Containers.
>
> ##### Step 1: Create Containerfile with `ENV`
>
> Erstellen Sie ein Verzeichnis `env_test/`, wechseln Sie hinein und erstellen Sie ein `Containerfile`:
> ```dockerfile
> FROM alpine:latest
>
> # Setze Umgebungsvariablen (zwei Schreibweisen)
> ENV APP_NAME="My Awesome App"
> ENV APP_VERSION="1.0" \
>     LOG_LEVEL="info"
>
> # Verwende ENV-Variablen in einer RUN-Anweisung
> RUN echo "Building ${APP_NAME} version ${APP_VERSION}..."
> RUN echo "Default log level set to: ${LOG_LEVEL}"
>
> # Setze eine Variable basierend auf einer anderen
> ENV CONFIG_PATH="/etc/${APP_NAME}/config"
> RUN echo "Config path will be: ${CONFIG_PATH}"
>
> # Der CMD kann die ENV-Variablen direkt nutzen
> CMD ["sh", "-c", "echo \"Running ${APP_NAME} v${APP_VERSION}. Log level: ${LOG_LEVEL}. Config: ${CONFIG_PATH}\""]
> ```
>
> ##### Step 2: Build and Run the Image
>
> Bauen Sie das Image und starten Sie einen Container.
> ```bash
> podman build -t env-demo .
> podman run --rm env-demo
> ```
> **Result:** Die Ausgabe des Containers zeigt die Werte der Umgebungsvariablen, die im `Containerfile` gesetzt wurden: "Running My Awesome App v1.0. Log level: info. Config: /etc/My Awesome App/config".
>
> ##### Step 3: Override `ENV` at Runtime
>
> Sie können die im Image gesetzten `ENV`-Variablen beim Starten des Containers mit der Option `-e` (oder `--env`) überschreiben.
> ```bash
> podman run --rm -e LOG_LEVEL="debug" -e APP_NAME="My Updated App" env-demo
> ```
> **Result:** Die Ausgabe spiegelt die zur Laufzeit überschriebenen Werte wieder: "Running My Updated App v1.0. Log level: debug. Config: /etc/My Awesome App/config". Beachten Sie, dass `CONFIG_PATH` nicht überschrieben wurde und seinen zur Build-Zeit festgelegten Wert behält (der auf dem ursprünglichen `APP_NAME` basierte).
>
> ##### Step 4: Clean Up
>
> ```bash
> podman rmi env-demo
> cd ..
> rm -rf env_test/
> ```
> `ENV` ist der Standardweg, um Konfigurationsparameter oder Standardeinstellungen für Ihre Anwendung im Image zu definieren.

---

> ##### Exercise 11: Building a Simple Go Application (Single-Stage)
>
> Bevor wir uns Multi-Stage Builds ansehen, erstellen wir dieselbe Go-Anwendung mit einem einfachen **Single-Stage Build**. Dies hilft zu verstehen, warum Multi-Stage Builds oft bevorzugt werden.
> Bei einem Single-Stage Build verwenden wir dasselbe Basis-Image sowohl für das Kompilieren als auch für das Ausführen der Anwendung. Das bedeutet, dass das finale Image alle Build-Werkzeuge (wie den Go-Compiler) enthält, auch wenn sie zur Laufzeit nicht mehr benötigt werden.
>
> ##### Step 1: Reuse Go Application Source
>
> Wir verwenden dieselbe `main.go` Datei wie in der nächsten Übung (Multi-Stage). Stellen Sie sicher, dass Sie sich in einem Arbeitsverzeichnis befinden (z.B. `go_single_stage/`) und die folgende `main.go` Datei vorhanden ist:
> ```go
> package main
>
> import "fmt"
>
> func main() {
>     fmt.Println("Hallo von einem Go Single-Stage Build!")
> }
> ```
>
> ##### Step 2: Create the Single-Stage Containerfile
>
> Erstellen Sie in Ihrem Arbeitsverzeichnis (`go_single_stage/`) eine Datei namens `Containerfile`:
> ```dockerfile
> # Single-Stage Build (Less Optimal)
> # Uses the full Go SDK image as the final image
> FROM golang:1.21-alpine
>
> LABEL maintainer="Podman Training" version="1.0" description="Simple Go App - Single Stage Build"
>
> WORKDIR /src
>
> COPY main.go .
>
> # Build the application
> # No need for static build flags here as we stay in the Go environment
> RUN go build -o /app/hello-go-single main.go
>
> # Define the command to run the application
> # Note: The working directory is still /src, so use absolute path
> CMD ["/app/hello-go-single"]
> ```
> **Explanation:**
> *   `FROM golang:1.21-alpine`: Wir verwenden das Go-SDK-Image als Basis.
> *   `COPY main.go .`: Kopiert den Quellcode.
> *   `RUN go build...`: Kompiliert die Anwendung. Das Ergebnis liegt in `/app/hello-go-single`.
> *   `CMD ["/app/hello-go-single"]`: Führt die kompilierte Anwendung beim Start aus.
> *   **Wichtig:** Das finale Image basiert immer noch auf `golang:1.21-alpine` und enthält das gesamte Go SDK!
>
> ##### Step 3: Build the Single-Stage Image
>
> **Command:**
> ```bash
> podman build -t go-hello-single .
> ```
>
> ##### Step 4: Run the Container
>
> **Command:**
> ```bash
> podman run --rm go-hello-single
> ```
> **Result:** Sie sehen die Ausgabe "Hallo von einem Go Single-Stage Build!".
>
> ##### Step 5: Check Image Size (Observation)
>
> **Command:**
> ```bash
> podman images | grep -E "go-hello-single|golang.*alpine"
> ```
> **Observation:** Vergleichen Sie die Größe von `go-hello-single` mit `golang:1.21-alpine`. Sie werden feststellen, dass sie sehr ähnlich (groß) sind. Das finale Image enthält unnötigerweise das gesamte Go-Build-Environment.
> Dies ist der Hauptnachteil von Single-Stage Builds für kompilierte Sprachen: Die resultierenden Images sind oft unnötig groß und enthalten Werkzeuge, die ein potenzielles Sicherheitsrisiko darstellen können. Die nächste Übung zeigt, wie Multi-Stage Builds dieses Problem lösen.
>
> ##### Step 6: Clean Up
>
> ```bash
> podman rmi go-hello-single
> cd ..
> rm -rf go_single_stage/
> ```

---

> ##### Exercise 12: Multi-Stage Builds for Optimization
>
> Oft benötigen Sie zum Bauen Ihrer Anwendung Werkzeuge oder Bibliotheken (Compiler, Entwicklungs-Header), die zur Laufzeit nicht mehr gebraucht werden. Ein **Multi-Stage Build** ermöglicht es, eine Build-Umgebung in einer ersten Stufe ("builder stage") zu verwenden und dann nur die notwendigen Artefakte (z.B. die kompilierte Anwendung) in eine schlanke finale Stufe zu kopieren. Das Ergebnis ist ein deutlich kleineres und sichereres finales Image.
> Wir demonstrieren dies mit einer einfachen Go-Anwendung.
>
> ##### Step 1: Create Go Application and Containerfile
>
> 1.  Erstellen Sie ein neues Verzeichnis, z.B. `go_multistage/`, und wechseln Sie hinein.
> 2.  Erstellen Sie die Go-Quelldatei `main.go`:
>     ```go
>     package main
>
>     import "fmt"
>
>     func main() {
>         fmt.Println("Hallo von einem Go Multi-Stage Build!")
>     }
>     ```
> 3.  Erstellen Sie das `Containerfile` mit zwei Stufen:
>     ```dockerfile
>     # ----- Stufe 1: Builder -----
>     # Verwendet das offizielle Go-Image, das alle Build-Tools enthält
>     FROM golang:1.21-alpine AS builder
>
>     # Setze Arbeitsverzeichnis
>     WORKDIR /src
>
>     # Kopiere den Go-Quellcode
>     COPY main.go .
>
>     # Baue die Anwendung statisch (wichtig für Alpine als Basis in der nächsten Stufe)
>     # CGO_ENABLED=0 verhindert die Verlinkung mit C-Bibliotheken
>     # -ldflags "-s -w" entfernt Debug-Infos und Symboltabellen -> kleineres Binary
>     RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/hello-go main.go
>
>     # ----- Stufe 2: Finales Image -----
>     # Startet mit einem minimalen Alpine-Image
>     FROM alpine:latest
>
>     # Kopiere *nur* die kompilierte Anwendung aus der Builder-Stufe
>     COPY --from=builder /app/hello-go /hello-go
>
>     # Definiere den Befehl zum Ausführen der Anwendung
>     ENTRYPOINT ["/hello-go"]
>     ```
>     **Explanation:**
>     *   `FROM golang... AS builder`: Definiert die erste Stufe und gibt ihr den Namen "builder".
>     *   `RUN go build...`: Kompiliert die Go-Anwendung innerhalb der Builder-Stufe.
>     *   `FROM alpine:latest`: Startet die zweite, finale Stufe mit einem schlanken Basis-Image.
>     *   `COPY --from=builder ...`: Kopiert die kompilierte Datei `/app/hello-go` aus der "builder"-Stufe in das finale Image. Das Go-SDK und der Quellcode bleiben zurück!
>     *   `ENTRYPOINT`: Legt fest, dass unser kompiliertes Programm beim Start des Containers ausgeführt wird.
>
> ##### Step 2: Build the Multi-Stage Image
>
> **Command:**
> ```bash
> podman build -t go-hello-multi .
> ```
> Podman führt beide Stufen aus, aber das finale Image basiert nur auf der letzten `FROM`-Anweisung und den darauf folgenden Befehlen.
>
> ##### Step 3: Run the Container
>
> **Command:**
> ```bash
> podman run --rm go-hello-multi
> ```
> **Result:** Sie sehen die Ausgabe "Hallo von einem Go Multi-Stage Build!".
>
> ##### Step 4: Check Image Size
>
> Vergleichen Sie die Größe des finalen Images mit der Größe des Go-SDK-Images.
> **Command:**
> ```bash
> podman images | grep -E "go-hello-multi|golang.*alpine"
> ```
> **Result:** Sie werden feststellen, dass das `go-hello-multi` Image signifikant kleiner ist als das `golang:1.21-alpine` Image, da es nur die kompilierte Anwendung und die Alpine-Basis enthält, nicht das gesamte Go-SDK.
>
> ##### Step 5: Understanding Layer Reuse
>
> Das finale Image (`go-hello-multi`) basiert auf `alpine:latest`. Wenn Sie ein anderes Image bauen würden, das ebenfalls `FROM alpine:latest` verwendet, würde Podman die bereits heruntergeladenen Layer von Alpine wiederverwenden und nur die neuen Layer für die andere Anwendung hinzufügen. Multi-Stage-Builds helfen also nicht nur, Images klein zu halten, sondern fördern auch die Wiederverwendung gemeinsamer Basis-Layer.
>
> ##### Step 6: Clean Up
>
> ```bash
> podman rmi go-hello-multi
> cd ..
> rm -rf go_multistage/
> ```

---