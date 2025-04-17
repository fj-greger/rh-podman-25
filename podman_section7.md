# Podman Lernmaterial

---

## 7 - Troubleshooting and Resolving Container Issues

### 7 - Troubleshooting and Resolving Container Issues

Selbst bei sorgfältiger Planung können bei der Arbeit mit Containern Probleme auftreten. In diesem Abschnitt lernen Sie **systematische Ansätze und Werkzeuge zur Fehlerbehebung (Troubleshooting)** in Podman.

Strukturierter Troubleshooting-Prozess:

1.  Problem beobachten & beschreiben (Was funktioniert nicht wie erwartet?).
2.  Informationen sammeln (Status, Logs, Konfiguration, Events).
3.  Hypothesen bilden (Was könnte die Ursache sein?).
4.  Hypothesen testen (Gezielte Änderungen oder Diagnosen).
5.  Lösung implementieren & verifizieren.

#### Common Container Issues and Solutions

##### 1. Container Fails to Start

*   **Symptoms**: `podman ps -a` zeigt "Exited" mit einem non-zero Exit Code; Container erscheint nicht in `podman ps`.
*   **Workflow**:
    1.  Check Exit Code: `podman ps -a` (Spalte `STATUS`).
    2.  Check Logs: `podman logs <container_name_or_id>`.
    3.  Check Config: `podman inspect <container_name_or_id>`.
    4.  Test Image Interactively: `podman run -it --rm --entrypoint sh <image_name>`.
    5.  Check Permissions: Sind Dateien/Volumes für den Container-User les-/schreibbar?

##### 2. Networking Problems

*   **Symptoms**: Connection refused/timeout; DNS-Fehler; Port-Mapping funktioniert nicht.
*   **Workflow**:
    1.  Check Port Mapping: `podman ps`, `podman inspect <container> | jq '.[0].NetworkSettings.Ports'`. Lauscht der Prozess im Container? (`podman exec <container> ss -tulnp`).
    2.  Check Host Firewall: `sudo firewall-cmd --list-all` / `sudo ufw status`.
    3.  Test Connectivity from Host: `curl http://localhost:<host_port>`.
    4.  Test Connectivity within Container/Pod: `podman exec <container> curl http://localhost:<container_port>`.
    5.  Test Inter-Container Connectivity: `podman exec <client_container> curl http://<server_container_name>:<server_port>` (in custom network/pod).
    6.  Check Network Config: `podman network ls`, `podman network inspect <network_name>`.

##### 3. Permission Errors (Volumes, Ports)

*   **Symptoms**: "Permission denied" in Logs; Fehler bei Ports < 1024 (rootless).
*   **Workflow**:
    1.  **Volumes:**
        *   Host Permissions: `ls -ld ./host/path`.
        *   UID/GID Mismatch: `podman exec <container> id` vs. `ls -ln ./host/path`. Rootless Solution: `:U`.
        *   SELinux: `sudo ausearch -m avc -ts recent`. Solution: `:z` oder `:Z`.
    2.  **Rootless Ports (<1024):** Lösung: Höheren Host-Port mappen (`-p 8080:80`) oder Systemeinstellung anpassen.

> **Info zu Volume Mount Optionen (:U, :z, :Z):**
>
> *   **`:U` (Rootless User Mapping):** Passt Besitzerrechte des Mounts *im Container* an Container-Prozess-UID an. Ändert Host-Rechte *nicht*.
> *   **`:z` (SELinux Shared Label):** Labelt Host-Pfad für Zugriff durch mehrere Container.
> *   **`:Z` (SELinux Private Label):** Labelt Host-Pfad für exklusiven Zugriff durch einen Container.
>
> Verwenden Sie `:z` oder `:Z` nur bei SELinux-bedingten Fehlern.

#### Überwachen von Podman-Ereignissen mit `podman events`

`podman events` zeigt Echtzeit-Ereignisse der Engine (create, start, stop, die, oom, pull, remove etc.). Nützlich für die Diagnose unerwarteter Stopps oder Engine-Probleme.

```bash
# Live-Stream der Ereignisse
podman events --stream

# Ereignisse der letzten Stunde filtern
podman events --filter 'event=die' --filter 'event=oom' --since 1h
```

> #### Best Practices: Troubleshooting
>
> *   Systematisch vorgehen.
> *   Logs prüfen (`podman logs`).
> *   Problem isolieren.
> *   Root vs. Rootless beachten.
> *   SELinux prüfen (`ausearch`, `:z`/`:Z`).
> *   `podman events` nutzen (OOM etc.).
> *   Doku/Community konsultieren.

#### Key Troubleshooting Commands Recap

*   `podman ps -a` (Status/Exit Code)
*   `podman logs <container>` (App-Fehler)
*   `podman inspect <resource>` (Konfiguration)
*   `podman exec -it <container> sh` (Interaktiv)
*   `podman stats` (Ressourcen)
*   `podman events` (Engine/OOM)
*   Host-Tools: `ss`, `firewall-cmd`, `ufw status`, `ausearch`, `ls -Z`

---

> ##### Exercise 1: Troubleshooting Rootless Volume Permissions with `:U`
>
> **Kontext:** Ein häufiges Problem im Rootless-Betrieb tritt auf, wenn ein Container als non-root User (definiert im Image mit `USER`) auf ein Volume zugreifen muss, das vom Host-User gemountet wurde. Die `:U`-Option löst dies, indem sie die Besitzrechte des Volumes *innerhalb des Containers* anpasst.
>
> ---
>
> **Vorbereitung:**
>
> 1.  Stellen Sie sicher, dass Sie als **normaler (nicht-root) User** arbeiten.
> 2.  Erstellen Sie ein Verzeichnis für diese Übung und wechseln Sie hinein:
>     ```bash
>     # Create and enter a directory for this exercise
>     mkdir exercise1_volperms
>     cd exercise1_volperms
>     ```
> 3.  Erstellen Sie **innerhalb** von `exercise1_volperms` ein Unterverzeichnis für das Volume-Mounting:
>     ```bash
>     # Create the subdirectory to be mounted
>     mkdir ./podman_user_test
>     # Verify its ownership (shows your host user/group)
>     ls -ld ./podman_user_test
>     ```
> 4.  Erstellen Sie die Datei `Containerfile.writer` **innerhalb** von `exercise1_volperms`:
>     ```dockerfile
>     FROM alpine:latest
>     # Create a test user 'appuser' with UID 1001
>     RUN adduser -u 1001 -D appuser
>     # Switch to this user
>     USER appuser
>     # Command that tries to write to the /data directory
>     CMD ["sh", "-c", "echo 'Written as appuser' > /data/output.txt && echo 'File written!' && cat /data/output.txt"]
>     ```
> 5.  Builden Sie das Image aus dem `Containerfile.writer` im aktuellen Verzeichnis (`exercise1_volperms`):
>     ```bash
>     # Build the image from the current directory
>     podman build -t user-writer -f Containerfile.writer .
>     ```
>
> **Aufgaben:**
>
> 1.  Versuchen Sie, den Container zu starten und das Host-Verzeichnis `./podman_user_test` **ohne** die `:U` Option zu mounten. Da Sie sich in `exercise1_volperms` befinden, zeigt `./podman_user_test` auf das richtige Unterverzeichnis.
>     ```bash
>     # This attempt will fail due to permissions
>     podman run --name writer_test_no_u --rm -v ./podman_user_test:/data:rw user-writer
>     ```
>     **Beobachten Sie:** Fehler wie `Permission denied`.
> 2.  **Analysieren:** `/data` im Container gehört UID 0, Prozess läuft als UID 1001.
> 3.  **Lösung mit `:U`:** Starten Sie den Container erneut mit der `:U` Option.
>     ```bash
>     # Retry with the ':U' option
>     podman run --name writer_test_with_u --rm -v ./podman_user_test:/data:U,rw user-writer
>     ```
> 4.  **Beobachten Sie:** Der Container läuft erfolgreich durch.
> 5.  Prüfen Sie den Besitzer der Datei auf dem **Host**:
>     ```bash
>     # Check file ownership on the host (inside ./podman_user_test)
>     ls -ln ./podman_user_test/output.txt
>     ```
>     **Beobachtung:** Gehört Ihrem Host-User. `:U` wirkt nur containerintern.
>
> **Erkenntnis:** `:U` löst rootless Volume-Berechtigungsprobleme für non-root Container-User.
>
> **Aufräumen:** Wechseln Sie zurück ins übergeordnete Verzeichnis und entfernen Sie das Übungsverzeichnis, die Testcontainer und das Image.
> ```bash
> # Go back to the parent directory
> cd ..
> # Cleanup the test containers (use -f in case they failed/exist)
> podman rm -f writer_test_no_u writer_test_with_u
> # Cleanup the exercise directory and image
> rm -rf ./exercise1_volperms
> podman image rm user-writer
> ```

---

> ##### Exercise 2: Debugging Container Start Failures
>
> Diagnose von Containern, die nicht starten oder sich sofort beenden.
>
> ---
>
> **Vorbereitung:**
>
> 1.  Erstellen Sie ein Verzeichnis `exercise2_fail_test/` im aktuellen Arbeitsverzeichnis und wechseln Sie hinein.
>     ```bash
>     # Create and enter a directory for this exercise
>     mkdir ./exercise2_fail_test
>     cd ./exercise2_fail_test
>     ```
> 2.  Erstellen Sie **innerhalb** von `exercise2_fail_test` die Datei `Containerfile.fail` mit einem absichtlichen Fehler:
>     ```dockerfile
>     FROM alpine:latest
>     # This command does not exist by default
>     CMD ["my-nonexistent-command"]
>     ```
> 3.  Bauen Sie das Image im aktuellen Verzeichnis (`exercise2_fail_test`):
>     ```bash
>     # Build the image from the current directory
>     podman build -t fail-image -f Containerfile.fail .
>     ```
>
> **Aufgaben:**
>
> 1.  Versuchen Sie, den Container zu starten:
>     ```bash
>     podman run --name fail-container fail-image
>     ```
>     **Beobachten Sie:** Der Befehl kehrt sofort zurück, evtl. mit Fehler.
> 2.  **Status/Exit Code prüfen:**
>     ```bash
>     podman ps -a --filter name=fail-container
>     ```
>     **Beobachten Sie:** Status "Exited" oder "Created", Exit Code != 0 (z.B. 127).
> 3.  **Logs prüfen:**
>     ```bash
>     podman logs fail-container
>     ```
>     **Beobachten Sie:** Fehlermeldung (z.B. "executable file not found") oder leere Ausgabe bei sehr frühem Fehler.
> 4.  (Optional) **Interaktiv testen:**
>     ```bash
>     podman run -it --rm --entrypoint sh fail-image
>     ```
>     Versuchen Sie in der Shell `my-nonexistent-command`. Bestätigt den Fehler. Mit `exit` verlassen.
>
> **Erkenntnis:** `podman ps -a` + `podman logs` sind essentiell für die Diagnose von Startfehlern.
>
> **Aufräumen:** Wechseln Sie aus dem Übungsverzeichnis heraus und entfernen Sie es, zusammen mit Container und Image.
> ```bash
> # Go back to the parent directory
> cd ..
> # Cleanup the container, image, and exercise directory
> podman rm fail-container
> podman rmi fail-image
> rm -rf ./exercise2_fail_test/
> ```

---

> ##### Exercise 3: Debugging Container Networking
>
> Analyse von Netzwerkproblemen zwischen Containern. Diese Übung benötigt keine lokalen Dateien.
>
> ---
>
> **Vorbereitung:**
>
> 1.  Erstellen Sie ein benutzerdefiniertes Netzwerk:
>     ```bash
>     podman network create debug-net
>     ```
> 2.  Starten Sie einen Nginx-Server im Netzwerk:
>     ```bash
>     podman run -d --network debug-net --name debug-server nginx:alpine
>     ```
> 3.  Starten Sie einen Client-Container im selben Netzwerk:
>     ```bash
>     podman run -d --network debug-net --name debug-client alpine sleep infinity
>     ```
> 4.  Installieren Sie `curl` im Client:
>     ```bash
>     podman exec debug-client apk add --no-cache curl
>     ```
>
> **Aufgaben:**
>
> 1.  **Erfolgreichen Zugriff testen:** Versuchen Sie vom Client aus auf den Server über dessen Namen zuzugreifen.
>     ```bash
>     podman exec debug-client curl http://debug-server
>     ```
>     **Beobachten Sie:** Nginx-Seite wird angezeigt.
> 2.  **Fehler simulieren (falscher Port):** Versuchen Sie, auf einen Port zuzugreifen, auf dem der Server nicht lauscht (z.B. 8080 statt 80).
>     ```bash
>     podman exec debug-client curl http://debug-server:8080
>     ```
>     **Beobachten Sie:** "Connection refused".
> 3.  **Diagnose (falscher Port):** Bei "Connection refused":
>     *   Kann der Name aufgelöst werden? (Ja, sonst gäbe es einen DNS-Fehler).
>     *   Ist der Server-Container erreichbar? (`ping` falls verfügbar).
>     *   Lauscht der Server auf dem erwarteten Port? Dazu müssen wir im *Server*-Container nachsehen. Das Tool `ss` ist in `nginx:alpine` nicht standardmäßig enthalten, wir müssen es zuerst installieren.
>     Installieren Sie das Paket `iproute2` (welches `ss` enthält) im `debug-server` Container:
>     ```bash
>     # Update package list and install iproute2 inside the running container
>     podman exec debug-server apk update
>     podman exec debug-server apk add iproute2
>     ```
>     Prüfen Sie nun die lauschenden Ports im Server-Container mit `ss`:
>     ```bash
>     # Now check listening TCP/UDP ports (numeric) in the server
>     podman exec debug-server ss -tulnp | grep LISTEN
>     ```
>     **Beobachten Sie:** Die Ausgabe sollte zeigen, dass der Server auf Port 80 lauscht, aber *nicht* auf Port 8080. Dies bestätigt, warum der Zugriff auf Port 8080 fehlschlug.
> 4.  **Fehler simulieren (falsches Netzwerk):** Stoppen und entfernen Sie den Client und starten Sie ihn ohne Angabe des Netzwerks neu (er landet im Default-`podman`-Netzwerk).
>     ```bash
>     podman stop debug-client && podman rm debug-client
>     podman run -d --name debug-client-wrongnet alpine sleep infinity
>     podman exec debug-client-wrongnet apk add --no-cache curl
>     ```
>     Versuchen Sie nun den Zugriff vom neuen Client aus:
>     ```bash
>     podman exec debug-client-wrongnet curl http://debug-server
>     ```
>     **Beobachten Sie:** DNS-Fehler ("Could not resolve host").
>
> **Erkenntnis:** Netzwerkdiagnose umfasst Konnektivitätstests und Überprüfung der Netzwerkkonfiguration.
>
> **Aufräumen:**
> ```bash
> # Cleanup containers and network
> podman stop debug-server debug-client-wrongnet
> podman rm debug-server debug-client-wrongnet
> podman network rm debug-net
> ```

---