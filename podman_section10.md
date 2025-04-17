# Podman Lernmaterial

---

## 10 - Podman Desktop

### 10 - Podman Desktop

#### Introduction to Podman Desktop

Neben der Kommandozeile (CLI) gibt es **Podman Desktop**, eine grafische Benutzeroberfläche (GUI), die Ihnen hilft, Ihre Container, Images, Pods und die gesamte Container-Umgebung visuell zu verwalten.

Zielgruppe:

*   Benutzer, die eine grafische Oberfläche bevorzugen.
*   Einsteiger, die eine visuelle Hilfe zum Verständnis der Konzepte suchen.
*   Entwickler, die eine schnelle Übersicht über ihre lokale Umgebung wünschen.
*   Umsteiger von anderen Tools wie Docker Desktop.

Podman Desktop integriert sich mit Ihrer installierten Podman Engine (oder anderen Engines wie Docker) und stellt viele der über die CLI verfügbaren Funktionen in einer zugänglichen grafischen Form dar.

#### Podman Machine (Wichtig für Windows/macOS)

Da Container nativ unter Linux laufen, benötigt Podman auf Windows und macOS eine Linux-Umgebung. Podman Desktop verwaltet hierfür oft eine virtuelle Maschine (VM), die als **Podman Machine** bezeichnet wird. Diese VM (basierend auf Technologien wie WSL2 unter Windows oder QEMU/Lima unter macOS) enthält die eigentliche Podman Engine.

Podman Desktop kümmert sich um:

*   Die Initialisierung und Konfiguration der Podman Machine.
*   Das Starten und Stoppen der VM.
*   Die Kommunikation zwischen der GUI und der Podman Engine in der VM.

In den Einstellungen von Podman Desktop (`Settings > Resources`) können Sie den Status der Podman Machine sehen und verwalten.

> **Hinweis:** Wenn Sie Podman Desktop unter Linux verwenden, läuft die Podman Engine normalerweise direkt auf Ihrem Host-System, und es ist keine separate Podman Machine erforderlich.

#### Was ist Podman Desktop? Key Features

*   **Dashboard Overview:** Zeigt eine Zusammenfassung Ihrer Ressourcen (laufende Container, Pods, Images, Volumes).
*   **Container Management:** Auflisten, Starten, Stoppen, Neustarten, Löschen, Inspizieren von Containern. Zugriff auf Logs und Terminal.
*   **Image Management:** Auflisten, Pullen, Bauen (Build), Taggen, Pushen und Löschen von Images.
*   **Pod Management:** Erstellen, Auflisten, Starten, Stoppen, Löschen und Inspizieren von Pods.
*   **Volume Management:** Auflisten, Erstellen und Löschen von Volumes.
*   **Registry Management:** Konfigurieren von Verbindungen zu Container-Registries.
*   **Kubernetes Integration:** Möglichkeit, Kubernetes YAML-Dateien anzuwenden (`podman play kube`) und YAML aus bestehenden Pods zu generieren (`podman generate kube`). Kann sich auch mit bestehenden Kubernetes-Clustern verbinden.
*   **Extensions:** Ermöglicht das Hinzufügen von Drittanbieter-Funktionen (z.B. Security Scanner, spezielle Registry-Integrationen).
*   **Multi-Engine Support:** Kann oft nicht nur mit Podman, sondern auch mit einer vorhandenen Docker Engine interagieren.

#### Why Use Podman Desktop?

*   **User-friendliness:** Einfacher Einstieg und Bedienung ohne tiefe CLI-Kenntnisse.
*   **Visual Insight:** Grafische Darstellung von Ressourcen und deren Beziehungen.
*   **Discoverability:** Hilft, verfügbare Optionen und Funktionen zu entdecken.
*   **Workflow Integration:** Kann Entwicklungsworkflows durch schnelle Aktionen beschleunigen.
*   **Kubernetes Bridge:** Vereinfacht das Arbeiten mit Kubernetes-Manifesten für lokale Entwicklung.

#### Getting Started with Podman Desktop

##### Step 1: Install

Laden Sie den Installer für Ihr Betriebssystem von der offiziellen Website herunter: [podman-desktop.io/downloads](https://podman-desktop.io/downloads).

Alternativ können Paketmanager verwendet werden:

```bash
# Beispiel für Linux mit Flatpak:
flatpak install flathub io.podman_desktop.PodmanDesktop

# Beispiel für macOS mit Homebrew:
brew install podman-desktop
```

##### Step 2: Ensure Engine Running

Podman Desktop benötigt eine laufende Podman Engine. Stellen Sie sicher, dass Podman installiert ist und funktioniert (ggf. muss die Podman Machine unter Windows/macOS gestartet werden, was Podman Desktop oft automatisch anbietet oder beim ersten Start initialisiert).

```bash
# Überprüfen Sie die Podman-Version über die CLI
podman version
```

##### Step 3: Launch & Connect

Starten Sie Podman Desktop. Es sollte automatisch versuchen, sich mit Ihrer lokalen Podman Engine (oder der Podman Machine) zu verbinden. Den Verbindungsstatus und die Engine-Details finden Sie normalerweise prominent im Dashboard oder unter **Settings > Resources**.

---

> ##### Exercise 1: Basic Container Management via GUI
>
> Diese Übung zeigt die grundlegenden Schritte zum Verwalten eines einfachen Containers über die Podman Desktop Oberfläche.
>
> **Aufgaben:**
>
> 1.  **Image Pullen:**
>     *   Navigieren Sie zum Bereich **Images** (links in der Seitenleiste).
>     *   Klicken Sie auf den Button **Pull an image** (oft oben rechts oder als primäre Aktion sichtbar).
>     *   Ein Dialog oder eine Seitenleiste öffnet sich. Geben Sie im Feld "Image to Pull" den Namen `nginx:alpine` ein (oder `docker.io/library/nginx:alpine`).
>     *   Stellen Sie sicher, dass die richtige Registry ausgewählt ist (oft "docker.io").
>     *   Klicken Sie auf den **Pull image** Button *innerhalb des Dialogs/der Seitenleiste*.
>     *   Warten Sie, bis der Download im Benachrichtigungsbereich oder in der Image-Liste als abgeschlossen angezeigt wird.
> 2.  **Container Starten:**
>     *   Navigieren Sie zum Bereich **Containers** (links).
>     *   Klicken Sie auf den Button **Create container** (oft oben rechts).
>     *   Ein Dialog wird angezeigt. Wählen Sie unter "Select image" das zuvor gepullte `nginx:alpine` Image aus der Liste aus.
>     *   Geben Sie unter "Container name" einen Namen ein, z.B. `my-nginx-gui`.
>     *   Konfigurieren Sie das Port-Mapping: Suchen Sie den Abschnitt "Ports" oder "Port mapping". Geben Sie `8080` in das Feld für den **Host Port** und `80` in das Feld für den **Container Port** ein und fügen Sie das Mapping hinzu (oft durch einen "+"-Button).
>     *   Klicken Sie auf den Button **Create and Start container** (oder ähnlich benannt) am unteren Rand des Dialogs.
> 3.  **Überprüfen:**
>     *   Der Container `my-nginx-gui` sollte nun in der Liste im Bereich **Containers** mit dem Status "Running" erscheinen.
>     *   Klicken Sie auf den Namen des Containers (`my-nginx-gui`), um seine Detailansicht zu öffnen. Hier finden Sie Reiter oder Abschnitte für **Logs**, **Inspect** (zeigt die JSON-Konfiguration), **Kube** (zeigt generiertes Kube YAML), **Terminal** (öffnet eine Shell im Container) usw.
>     *   Öffnen Sie Ihren Webbrowser und rufen Sie die Adresse `http://localhost:8080` auf. Sie sollten die Nginx-Willkommensseite sehen.
> 4.  **Stoppen & Löschen:**
>     *   Gehen Sie zurück zur Liste der Container (Bereich **Containers**).
>     *   Suchen Sie den Container `my-nginx-gui`.
>     *   Bewegen Sie den Mauszeiger über den Container oder markieren Sie ihn (je nach UI). Es sollten Aktions-Symbole erscheinen.
>     *   Klicken Sie auf das **Stop**-Symbol (oft ein Quadrat). Warten Sie, bis der Status zu "Exited" wechselt.
>     *   Klicken Sie anschließend auf das **Delete**-Symbol (oft ein Mülleimer) und bestätigen Sie die Löschung im erscheinenden Dialog.
>
> Diese Übung deckt den grundlegenden Lebenszyklus eines Containers in Podman Desktop ab.

---

> ##### Exercise 2: Building an Image via GUI
>
> Podman Desktop kann auch Images aus einem `Containerfile` bauen.
>
> **Vorbereitung:**
> *   Erstellen Sie ein Verzeichnis auf Ihrem Computer, z.B. `gui_build_test/`.
> *   Erstellen Sie darin eine einfache Datei **`index.html`** mit dem Inhalt:
>     ```html
>     <!DOCTYPE html>
>     <html>
>     <head><title>GUI Build Test</title></head>
>     <body><h1>Hello from GUI Build!</h1></body>
>     </html>
>     ```
> *   Erstellen Sie darin ein **`Containerfile`** (ohne Dateiendung) mit dem Inhalt:
>     ```dockerfile
>     FROM docker.io/library/nginx:alpine
>     COPY index.html /usr/share/nginx/html/index.html
>     EXPOSE 80
>     ```
>
> **Aufgaben:**
>
> 1.  Navigieren Sie in Podman Desktop zum Bereich **Images**.
> 2.  Klicken Sie auf den Button **Build an image**.
> 3.  Im erscheinenden Dialog/Bereich "Build Image from Containerfile":
>     *   Klicken Sie neben "Containerfile path" auf den **Browse**-Button (oder ein Ordner-Symbol), um den Dateibrowser zu öffnen. Navigieren Sie zu Ihrem Verzeichnis `gui_build_test/` und wählen Sie das `Containerfile` aus.
>     *   Das Feld "Build context directory" sollte automatisch mit dem Pfad zu `gui_build_test/` gefüllt werden. Überprüfen Sie dies.
>     *   Geben Sie im Feld "Image Name" einen Namen für das zu bauende Image ein, z.B. `my-custom-webserver-gui:latest`.
> 4.  Klicken Sie auf den **Build** Button am unteren Rand des Dialogs.
> 5.  Beobachten Sie die Build-Logs, die normalerweise im unteren Bereich des Fensters oder in einem eigenen Tab erscheinen.
> 6.  Nach erfolgreichem Build sollte das Image `my-custom-webserver-gui:latest` in der Liste im Bereich **Images** erscheinen.
> 7.  (Optional) Starten Sie einen Container aus diesem neuen Image, wie in Exercise 1 gezeigt (verwenden Sie `my-custom-webserver-gui:latest` als Image und mappen Sie Host-Port `8080` auf Container-Port `80`). Überprüfen Sie das Ergebnis unter `http://localhost:8080` im Browser (sollte "Hello from GUI Build!" anzeigen).
> 8.  **Aufräumen:**
>     *   Im Bereich **Images**, suchen Sie `my-custom-webserver-gui:latest`.
>     *   Wählen Sie es aus oder bewegen Sie den Mauszeiger darüber und klicken Sie auf das **Delete**-Symbol (Mülleimer). Bestätigen Sie die Löschung.
>     *   Entfernen Sie das Verzeichnis `gui_build_test/` manuell von Ihrem Computer.

---

> ##### Exercise 3: Creating a Pod from Existing Containers via GUI
>
> Diese Übung folgt dem Workflow aus der Podman Desktop Dokumentation, um einen Pod aus bereits vorhandenen Containern zu erstellen.
>
> **Ziel:** Einen Pod erstellen, der einen Nginx-Container und einen einfachen Alpine-Container enthält.
>
> **Aufgaben:**
>
> 1.  **Individuelle Container Erstellen (Vorbereitung):**
>     *   **Nginx Container:**
>         *   Gehen Sie zum Bereich **Containers** und klicken Sie auf **Create container**.
>         *   Image: `nginx:alpine` (oder `docker.io/library/nginx:alpine`).
>         *   Name: `temp-nginx-for-pod`.
>         *   Port Mapping: Host `8084`, Container `80`.
>         *   Klicken Sie auf **Create and Start container**.
>     *   **Alpine Logger Container:**
>         *   Klicken Sie erneut auf **Create container**.
>         *   Image: `alpine:latest` (oder `docker.io/library/alpine:latest`).
>         *   Name: `temp-logger-for-pod`.
>         *   Command: `sleep` (im Command-Feld), `infinity` (im Arguments-Feld).
>         *   **Kein** Port Mapping.
>         *   Klicken Sie auf **Create and Start container**.
>     *   **Überprüfen:** Stellen Sie sicher, dass beide Container (`temp-nginx-for-pod`, `temp-logger-for-pod`) in der Liste im Bereich **Containers** als "Running" angezeigt werden. Testen Sie kurz, ob Nginx unter `http://localhost:8084` erreichbar ist.
> 2.  **Pod aus den Containern erstellen:**
>     *   Bleiben Sie im Bereich **Containers**.
>     *   Markieren Sie die **beiden** zuvor erstellten Container (`temp-nginx-for-pod` und `temp-logger-for-pod`), indem Sie die Checkboxen daneben anklicken.
>     *   Sobald mehrere Container ausgewählt sind, sollte oben oder in einer Aktionsleiste der Button **Create Pod** erscheinen. Klicken Sie darauf.
>     *   Ein Dialog "Create Pod from selected containers" öffnet sich:
>         *   (Optional) Ändern Sie den vorgeschlagenen Pod-Namen, z.B. in `my-containers-pod`.
>         *   Überprüfen Sie den Abschnitt "Ports". Das Mapping `8084:80` sollte automatisch vom `temp-nginx-for-pod` Container übernommen worden sein.
>     *   Klicken Sie auf den Button **Create Pod** am unteren Rand des Dialogs.
> 3.  **Überprüfen des Pods:**
>     *   Wechseln Sie zum Bereich **Pods** (links). Sie sollten den neu erstellten Pod `my-containers-pod` sehen.
>     *   Klicken Sie auf den Namen des Pods (`my-containers-pod`), um seine Detailansicht zu öffnen.
>     *   In der Detailansicht sollten die ursprünglichen Container (jetzt Teil des Pods, eventuell leicht umbenannt, z.B. `my-containers-pod-temp-nginx-for-pod`) aufgelistet sein.
>     *   Testen Sie erneut den Nginx-Zugriff über den Port, der nun vom Pod verwaltet wird: Öffnen Sie `http://localhost:8084` im Browser. Es sollte weiterhin funktionieren.
>     *   Beobachten Sie die Liste im Bereich **Containers**. Die ursprünglichen, einzelnen Container (`temp-nginx-for-pod`, `temp-logger-for-pod`) sind möglicherweise nicht mehr sichtbar oder haben einen anderen Status, da sie nun Teil des Pods sind.
> 4.  **Aufräumen:**
>     *   Gehen Sie zum Bereich **Pods**.
>     *   Suchen Sie den Pod `my-containers-pod`.
>     *   Wählen Sie den Pod aus (Checkbox oder Mauszeiger).
>     *   Klicken Sie auf das **Stop**-Symbol und warten Sie.
>     *   Klicken Sie anschließend auf das **Delete**-Symbol (Mülleimer) und bestätigen Sie. Das Löschen des Pods entfernt auch automatisch die darin enthaltenen Container.
>
> Dieser Workflow zeigt, wie man bestehende Container nachträglich zu einem Pod zusammenfasst.

---

> ##### Exercise 4: Playing Kube YAML via GUI
>
> Podman Desktop bietet eine einfache Möglichkeit, Kubernetes YAML-Dateien anzuwenden (entspricht `podman play kube`).
>
> **Wichtiger Hinweis zum Port-Mapping in der GUI:** Die "Play Kubernetes YAML"-Funktion in Podman Desktop bietet keine Möglichkeit, während des Ausführens ein Port-Mapping anzugeben (wie der `--publish`-Flag in der CLI). Wenn Sie einen Port direkt beim Erstellen des Pods über diese GUI-Funktion veröffentlichen möchten, **muss das Mapping direkt in der YAML-Datei** mittels `hostPort` definiert werden.
>
> **Vorbereitung:**
> *   Erstellen oder passen Sie eine Kubernetes Pod YAML-Datei an, z.B. `simple-nginx-pod-gui.yaml`. Fügen Sie `hostPort` hinzu, um das Port-Mapping direkt in der Datei zu definieren:
>     ```yaml
>     apiVersion: v1
>     kind: Pod
>     metadata:
>       name: simple-nginx-pod-gui # Geänderter Name zur Unterscheidung
>     spec:
>       containers:
>       - name: nginx-container
>         image: docker.io/library/nginx:alpine
>         ports:
>         - containerPort: 80
>           hostPort: 8082
>     ```
>     (Beachten Sie, dass die Verwendung von `hostPort` zwar in Podman funktioniert, aber in echten Kubernetes-Umgebungen weniger gebräuchlich ist und die Portabilität einschränken kann. Für lokale Tests mit der GUI ist es jedoch oft der einfachste Weg).
> *   Stellen Sie sicher, dass keine Pods oder Container mit dem Namen `simple-nginx-pod-gui` bereits laufen und dass Host-Port 8082 frei ist.
>
> **Aufgaben:**
>
> 1.  Navigieren Sie zum Bereich **Pods**.
> 2.  Suchen Sie nach einem Button oder Menüpunkt namens **Play Kubernetes YAML** (oft oben rechts oder unter einem "+"-Menü). Klicken Sie darauf.
> 3.  Ein Dialog erscheint. Klicken Sie auf den Button, um eine Datei auszuwählen ("Select YAML file" oder ähnlich).
> 4.  Navigieren Sie zu Ihrer angepassten `simple-nginx-pod-gui.yaml`-Datei und wählen Sie sie aus.
> 5.  Podman Desktop zeigt möglicherweise eine Vorschau der zu erstellenden Ressourcen an.
> 6.  Klicken Sie auf den **Play** oder **Apply** Button im Dialog.
> 7.  Der Pod `simple-nginx-pod-gui` sollte erstellt und gestartet werden. Sie finden ihn in der Liste im Bereich **Pods**.
> 8.  **Überprüfen:**
>     *   Finden Sie den Pod `simple-nginx-pod-gui` in der Liste. Klicken Sie darauf, um die Details zu sehen.
>     *   Öffnen Sie Ihren Webbrowser und rufen Sie die Adresse `http://localhost:8082` auf. Da `hostPort: 8082` nun in der YAML definiert war, sollte die Nginx-Willkommensseite direkt erreichbar sein.
>     *   In der Pod-Detailansicht der GUI sehen Sie das Port-Mapping (8082:80) ebenfalls aufgeführt.
> 9.  **Aufräumen:** Wählen Sie den Pod `simple-nginx-pod-gui` in der Liste aus und klicken Sie auf **Delete** (Mülleimer-Symbol). Bestätigen Sie die Aktion. Speichern oder löschen Sie die YAML-Datei nach Bedarf.
>
> Diese Übung zeigt, wie `hostPort` in der YAML genutzt werden kann, um Ports direkt über die "Play Kubernetes YAML"-Funktion der GUI zu veröffentlichen.

---

> #### Best Practices for Using Podman Desktop
>
> *   **Als Ergänzung, nicht Ersatz:** Nutzen Sie die GUI für Visualisierung, schnelle Aktionen und Entdeckung, aber verstehen Sie die zugrundeliegenden CLI-Konzepte für tiefere Kontrolle und Automatisierung.
> *   **Einstellungen Erkunden:** Machen Sie sich mit den Optionen unter `Settings` vertraut (Resources, Registries, Extensions, Proxy-Einstellungen).
> *   **Extensions mit Bedacht:** Installieren Sie nur Erweiterungen von vertrauenswürdigen Quellen, die Sie wirklich benötigen.
> *   **K8s-Features Nutzen:** Die Integration mit `play kube` und `generate kube` (oft über Kontextmenüs oder Detailansichten erreichbar) ist eine Stärke für lokale K8s-Workflows.
> *   **Kombination mit CLI:** Oft ist es effizient, komplexe Setups oder Automatisierungen über die CLI zu steuern und die GUI zur Überwachung und für schnelle Einzelaktionen zu nutzen.
> *   **Updates:** Halten Sie Podman Desktop und die Podman Engine aktuell, um von Bugfixes und neuen Features zu profitieren.
> *   **Ressourcenverbrauch:** Seien Sie sich bewusst, dass die GUI selbst und insbesondere die Podman Machine (falls unter Windows/macOS verwendet) Systemressourcen (CPU, RAM) benötigen.

### Key Takeaways

*   Podman Desktop bietet eine grafische Oberfläche zur Verwaltung von Podman-Ressourcen (Container, Images, Pods, Volumes).
*   Vereinfacht gängige Aufgaben wie Container-/Pod-Lifecycle-Management, Image-Builds und das Anwenden von Kube YAML über eine intuitive UI.
*   Verwaltet oft automatisch die Podman Machine (Linux VM) unter Windows/macOS für die Podman Engine.
*   Gut geeignet für Einsteiger, visuell orientierte Benutzer und als Ergänzung zur Kommandozeile für Entwickler.
*   Bietet Integration mit Kubernetes-Konzepten (`play kube`, `generate kube`) und ein Erweiterungsmodell zur Funktionserweiterung.
