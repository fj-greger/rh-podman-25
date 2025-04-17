# Podman Lernmaterial

---

## 1 - Understanding Containerization Concepts

### 1 - Understanding Containerization Concepts

#### Willkommen zu diesem hands-on Training für Podman!

Dieses Training ist für Personen konzipiert, die noch keine Erfahrung mit Podman haben, und folgt dem "Learning by Doing"-Prinzip. Sie werden aktiv mit den Tools und Konzepten durch praktische Übungen arbeiten. In diesem ersten Thema, **Understanding Containerization Concepts**, legen wir die Foundation, indem wir die Basics der Containerisierung und die Rolle von Podman exploren.

#### Introduction

In diesem Abschnitt lernen Sie, was Containerisierung ist, wie sie sich von traditioneller Virtualisierung unterscheidet und warum sie ein leistungsstarker Approach für das Management von Applikationen ist. Sie erhalten zudem eine Introduction in Podman, ein Tool zur Verwaltung von Containern, und führen Ihre ersten Container aus, um die Konzepte praktisch zu erleben.

#### Was sind Container?

Container sind eine Methode, um Software zu packagen, sodass sie konsistent über verschiedene Environments hinweg ausgeführt werden kann. Stellen Sie sich einen Container als eine lightweight, portable Box vor – ähnlich einem Shipping Container –, die eine Applikation zusammen mit allem enthält, was sie zum Laufen braucht:

*   Den Code der Applikation
*   Das Runtime Environment
*   Libraries
*   Dependencies

Diese "Box" kann vom Laptop zu einem Server oder in die Cloud verschoben werden, ohne dass Sie sich um Compatibility Issues sorgen müssen.

#### Container vs. Virtual Machines (VMs)

Um Container besser zu verstehen, vergleichen wir sie mit Virtual Machines (VMs):

##### VMs

*   Emulieren komplette Hardware & OS (eigener Kernel).
*   Laufen auf Hypervisor.
*   Ressourcenintensiv, langsamer Start.
*   Starke Isolation.

##### Container

*   Teilen den Kernel des Host OS.
*   Enthalten nur App & Dependencies.
*   Leichtgewichtig, schneller Start, effizienter.
*   Prozess-Level Isolation.

**Summary:** Container sind für die meisten Anwendungsfälle effizienter als VMs.

#### Benefits der Containerisierung

*   **Konsistenz:** Dev, Test, Prod sind gleich.
*   **Isolation:** Keine Konflikte zwischen Apps.
*   **Skalierbarkeit:** Einfache Replikation.
*   **Portabilität:** Läuft überall dort, wo eine Container Engine läuft.

#### Introduction zu Podman

Podman ist eine OCI-kompatible Container Engine zum Entwickeln, Managen und Ausführen von Containern und Images auf Linux-Systemen.

*   **Daemonless:** Kein zentraler Daemon, erhöht Sicherheit und Flexibilität. Jeder Podman-Befehl läuft als eigener Prozess.
*   **Rootless Focus:** Standardmäßig für Betrieb ohne Root-Rechte konzipiert.
*   **Docker CLI Kompatibilität:** `podman` Befehle ähneln stark `docker` Befehlen.
*   **Pods:** Unterstützt das Konzept von Pods (Gruppen von Containern), ähnlich wie Kubernetes.

**Wie funktioniert "Daemonless"?** Im Gegensatz zu Docker, das ein Client-Server-Modell verwendet (die `docker` CLI kommuniziert mit einem ständig laufenden Docker-Daemon, der die Container verwaltet), nutzt Podman ein traditionelles Fork/Exec-Modell, ähnlich wie andere Linux-Befehle. Wenn Sie `podman run` ausführen, startet Podman direkt die Container-Laufzeitumgebung (wie `crun` oder `runc`) als Kindprozess. Es gibt keinen zentralen Prozess, der ständig im Hintergrund laufen muss. Dies reduziert den Ressourcenverbrauch, eliminiert einen potenziellen Single Point of Failure und ermöglicht eine bessere Integration mit Systemd für die Verwaltung von Container-Lebenszyklen.

---

> ##### Exercise 1: Running Your First Containers
>
> Jetzt wird's praktisch!
>
> ##### Step 1: Podman installieren
>
> Installieren Sie Podman über Ihren Paketmanager.
>
> **Für Ubuntu/Debian:**
> ```bash
> sudo apt-get update && sudo apt-get install -y podman
> ```
> **Für Fedora:**
> ```bash
> sudo dnf install -y podman
> ```
> **Verification:**
> ```bash
> podman --version
> ```
> **Output:** Sollte eine Version anzeigen (z.B. `podman version 5.x.y`).
>
> ##### Step 1.1: (Optional) Install Latest Podman Version
>
> Falls die Standardversion veraltet ist, können Sie aktuellere Versionen aus Drittquellen beziehen (siehe vorherige Antworten für Details zu Copr/OBS Repositories). Seien Sie sich der potenziellen Risiken bewusst.
>
> ##### Step 2: Einen Webserver-Container ausführen
>
> Der grundlegende Befehl zum Starten eines Containers ist `podman run`.
>
> **Syntax:** `podman run [OPTIONS] IMAGE [COMMAND [ARG...]]`
>
> **Command:**
> ```bash
> podman run -d -p 8080:80 --name my-web-server httpd:alpine
> ```
> **Explanation:**
> *   `podman run`: Hauptbefehl zum Erstellen und Starten.
> *   `-d` / `--detach`: Startet im Hintergrund.
> *   `-p 8080:80` / `--publish 8080:80`: Mappt Host-Port auf Container-Port.
> *   `--name my-web-server`: Gibt Container einen Namen. **(Best Practice!)**
> *   `httpd:alpine`: Image (`REPOSITORY:TAG`).
>
> ##### Step 3: Auf den Webserver zugreifen (Access)
>
> Öffnen Sie im Browser: `http://localhost:8080`
>
> **Result:** Apache Default Page ("It works!").
>
> ##### Step 4: Einen interaktiven Container ausführen
>
> Starten Sie eine temporäre Shell.
>
> **Command:**
> ```bash
> podman run -it --rm ubuntu:latest bash
> ```
> **Explanation:**
> *   `-it`: Interaktiv mit TTY.
> *   `--rm`: Entfernt Container nach Beendigung. **(Best Practice!)**
> *   `ubuntu:latest`: Image.
> *   `bash`: Auszuführender Befehl im Container.
>
> Testen Sie im Container:
> ```bash
> id
> ls -l /
> exit
> ```
> Der Container wird nach `exit` automatisch entfernt.
>
> > ##### Best Practices aus diesem Abschnitt
> >
> > *   Container benennen (`--name`).
> > *   Temporäre Container entfernen (`--rm`).
> > *   Rootless verwenden.
> > *   Spezifische Image Tags verwenden (`httpd:alpine` statt `httpd`).
>
> ### Key Takeaways
>
> *   Container: Lightweight, portable Softwarepakete.
> *   Podman: Daemonless, Rootless-fokussierte Container Engine.
> *   `podman run`: Startet Container (`-d`, `-p`, `--name`, `-it`, `--rm`).
> *   Images: Vorlagen (`REPOSITORY:TAG`).

---

> ##### Exercise 2: Finding and Pulling an Image
>
> Bevor Sie einen Container starten, benötigen Sie ein Image. Images sind Vorlagen für Container und werden in Registries gespeichert (wie Docker Hub oder Quay.io). Sie können nach Images suchen und sie explizit herunterladen (pullen).
>
> ##### Step 1: Searching for an Image
>
> Verwenden Sie `podman search`, um nach verfügbaren Images zu suchen.
>
> **Command:**
> ```bash
> podman search alpine
> ```
> **Explanation:**
> *   `podman search`: Sucht in den konfigurierten Registries (siehe `/etc/containers/registries.conf`).
> *   `alpine`: Der Suchbegriff (ein populäres, kleines Linux-Image).
>
> **Result:** Sie sehen eine Liste von Images, die "alpine" enthalten, oft mit Namen wie `docker.io/library/alpine`.
>
> ##### Step 2: Pulling an Image Explicitly
>
> Obwohl `podman run` ein Image automatisch herunterlädt, wenn es lokal nicht vorhanden ist, können Sie es auch explizit mit `podman pull` holen.
>
> **Syntax:** `podman pull [REGISTRY/]REPOSITORY[:TAG]`
>
> **Command:**
> ```bash
> podman pull alpine:latest
> ```
> **Explanation:**
> *   `podman pull`: Lädt ein Image herunter.
> *   `alpine`: Der Name des Repositories.
> *   `:latest`: Der Tag, der eine spezifische Version des Images angibt (`latest` ist oft die aktuellste stabile Version, aber es ist Best Practice, spezifischere Tags wie `alpine:3.18` zu verwenden, wenn möglich).
>
> ##### Step 3: Listing Local Images
>
> Überprüfen Sie, ob das Image heruntergeladen wurde.
>
> **Command:**
> ```bash
> podman images
> ```
> **Result:** Sie sollten das `alpine` Image mit dem Tag `latest` in der Liste Ihrer lokalen Images sehen.

---

> ##### Exercise 3: Running a Simple Command Container
>
> Nicht jeder Container muss ein langlebiger Dienst wie ein Webserver sein. Sie können Container auch verwenden, um schnell einen einzelnen Befehl in einer isolierten Umgebung auszuführen.
>
> ##### Step 1: Run a Container to Execute a Command
>
> Wir verwenden das zuvor gepullte `alpine` Image, um einen einfachen Befehl auszuführen. Der Container startet, führt den Befehl aus und beendet sich sofort wieder. Mit `--rm` wird er danach automatisch entfernt.
>
> **Command:**
> ```bash
> podman run --rm alpine:latest echo 'Hello from a simple Alpine container!'
> ```
> **Explanation:**
> *   `podman run`: Startet einen neuen Container.
> *   `--rm`: Sorgt dafür, dass der Container nach der Beendigung automatisch gelöscht wird (gut für Einweg-Aufgaben).
> *   `alpine:latest`: Das zu verwendende Image.
> *   `echo '...'`: Der Befehl, der *innerhalb* des Containers ausgeführt werden soll.
>
> **Result:** Sie sehen die Ausgabe "Hello from a simple Alpine container!" direkt in Ihrem Terminal.
>
> ##### Step 2: Run Another Simple Command
>
> Versuchen wir einen anderen Befehl, z.B. das Anzeigen der Umgebungsvariablen innerhalb des minimalen Alpine-Containers.
>
> **Command:**
> ```bash
> podman run --rm alpine:latest printenv
> ```
> **Result:** Sie sehen eine Liste der Standard-Umgebungsvariablen, die im Alpine-Container gesetzt sind (z.B. `PATH`, `HOSTNAME`).
>
> Diese Art von "Wegwerf"-Containern ist nützlich, um Tools auszuführen, die Sie nicht auf Ihrem Host installieren möchten, oder um schnell etwas in einer sauberen Umgebung zu testen.

---

> ##### Exercise 4: Removing a Stopped Container
>
> In den vorherigen Übungen haben wir `--rm` verwendet, um Container nach Gebrauch automatisch zu löschen. Was aber, wenn wir einen Container ohne `--rm` starten und ihn später manuell entfernen möchten?
>
> ##### Step 1: Run a Container Without `--rm`
>
> Starten wir einen einfachen Alpine-Container, der nur kurz läuft, aber diesmal *ohne* die Option `--rm`.
>
> **Command:**
> ```bash
> podman run --name temp-alpine alpine:latest sleep 5
> ```
> **Explanation:**
> *   `--name temp-alpine`: Wir geben ihm einen Namen, um ihn leichter zu finden.
> *   `alpine:latest`: Das Image.
> *   `sleep 5`: Der Container führt diesen Befehl aus (wartet 5 Sekunden) und beendet sich dann.
>
> Warten Sie ein paar Sekunden, bis der Container sich beendet hat.
>
> ##### Step 2: List All Containers (Including Stopped)
>
> Verwenden Sie `podman ps -a`, um *alle* Container anzuzeigen, auch die gestoppten.
>
> **Command:**
> ```bash
> podman ps -a
> ```
> **Result:** Sie sollten den Container `temp-alpine` in der Liste sehen, mit dem Status "Exited". Ohne `--rm` bleibt der Container-Eintrag bestehen, auch wenn der Prozess darin beendet ist.
>
> ##### Step 3: Remove the Stopped Container
>
> Nun entfernen wir den gestoppten Container mit `podman rm`.
>
> **Syntax:** `podman rm CONTAINER_NAME_OR_ID`
>
> **Command:**
> ```bash
> podman rm temp-alpine
> ```
> **Result:** Podman gibt den Namen des entfernten Containers zurück.
>
> > **Hinweis:** `podman rm` funktioniert nur bei gestoppten Containern. Um einen laufenden Container zu stoppen und zu entfernen, müssten Sie zuerst `podman stop` verwenden oder `podman rm -f` (force) nutzen, was aber weniger sauber ist.
>
> ##### Step 4: Verify Removal
>
> Überprüfen Sie erneut mit `podman ps -a`.
>
> **Command:**
> ```bash
> podman ps -a
> ```
> **Result:** Der Container `temp-alpine` sollte nun nicht mehr in der Liste erscheinen.
>
> Das manuelle Entfernen ist wichtig, um Speicherplatz freizugeben und die Liste der Container übersichtlich zu halten.

---