# Podman Lernmaterial

---

## 2 - Managing Containerized Services with Podman

### 2 - Managing Containerized Services with Podman

Nach dem Starten (Topic 1) ist das Management des **Lifecycles** von Services entscheidend: Überwachen, Steuern, Warten.

#### Was sind Containerized Services?

Applikationen in Containern, die Isolation, Portability, Consistency bieten (Webserver, DBs, APIs).

#### Why Podman for Managing Services?

Podman bietet Commands zur Kontrolle laufender Container (Status, Logs, Start/Stop/Restart, Remove) ohne Daemon.

---

> ##### Exercise 1: Managing a Running Service
>
> Wir verwenden den `my-web-server` (Port 8080) aus Abschnitt 1.
> ```nohighlight
> # Sicherstellen, dass er läuft:
> podman start my-web-server || podman run -d -p 8080:80 --name my-web-server httpd:alpine
> ```
>
> > **Info: `command1 || command2`:** Der `||`-Operator (logisches ODER in Shells) führt `command2` nur aus, wenn `command1` fehlschlägt (non-zero Exit Code). Hier: Wenn `podman start` fehlschlägt (weil der Container nicht existiert oder schon läuft), wird `podman run` versucht.
>
> ##### Step 1: Checking Service Status
>
> Überprüfen Sie den Status.
>
> **Syntax:** `podman ps [OPTIONS]`
>
> **Command:**
> ```bash
> podman ps # Zeigt laufende Container
> podman ps -a # Zeigt alle Container (auch gestoppte)
> ```
> **Explanation:** Listet Container mit ID, Namen, Image, Status, Ports etc.
>
> > **Info: Container ID vs. Name:** Viele Podman-Befehle akzeptieren Name oder (abgekürzte) ID.
>
> ##### Step 2: Inspecting Service Details
>
> Holen Sie Detail-Infos.
>
> **Syntax:** `podman inspect [OPTIONS] NAME|ID [...]`
>
> **Command:**
> ```bash
> podman inspect my-web-server
> ```
> **Explanation:** JSON-Ausgabe mit Konfiguration (Image, Mounts, Netzwerk, Env Vars etc.).
>
> **Tip:** Mit `jq` filtern (Installation: `sudo apt/dnf/snap install jq`) um z.B. die Port-Mappings anzuzeigen:
> ```bash
> podman inspect my-web-server | jq '.[0].NetworkSettings.Ports."80/tcp"'
> ```
> Dies zeigt die Host-Port-Bindungen für den Container-Port 80/tcp an.
>
> ##### Step 3: Viewing Service Logs
>
> Sehen Sie die Container-Ausgabe.
>
> **Syntax:** `podman logs [OPTIONS] NAME|ID`
>
> **Command:**
> ```bash
> podman logs my-web-server
> ```
> Live verfolgen:
> ```bash
> podman logs -f my-web-server
> ```
>
> ##### Step 4: Controlling the Service Lifecycle
>
> Stoppen, Starten, Neustarten, Entfernen.
>
> *   **Stop:** Sendet SIGTERM, dann SIGKILL.
>     **Syntax:** `podman stop [OPTIONS] NAME|ID [...]`
>     ```bash
>     podman stop my-web-server
>     ```
> *   **Start:** Startet gestoppten Container.
>     **Syntax:** `podman start [OPTIONS] NAME|ID [...]`
>     ```bash
>     podman start my-web-server
>     ```
> *   **Restart:** Stoppt und startet neu.
>     **Syntax:** `podman restart [OPTIONS] NAME|ID [...]`
>     ```bash
>     podman restart my-web-server
>     ```
> *   **Remove:** Löscht **gestoppten** Container.
>     **Syntax:** `podman rm [OPTIONS] NAME|ID [...]`
>     ```bash
>     podman stop my-web-server
>     podman rm my-web-server
>     ```
>     Erzwungenes Entfernen (`-f`):
>     ```bash
>     podman rm -f my-web-server
>     ```
>
> ##### Step 5: Running Multiple Instances
>
> Starten einer zweiten Instanz auf anderem Port.
>
> > **Wichtig: Port-Konflikt!** Verwenden Sie einen freien Host-Port (z.B. 8081).
> > ```bash
> > # Ggf. laufenden my-web-server auf 8080 stoppen
> > # podman stop my-web-server
> > ```
>
> **Command:**
> ```bash
> podman run -d -p 8081:80 --name my-web-server-2 httpd:alpine
> ```
> **Access:** `http://localhost:8081`
>
> Bereinigen:
> ```bash
> podman stop my-web-server-2 && podman rm my-web-server-2
> ```
> (Starten Sie `my-web-server` wieder: `podman start my-web-server`)
>
> #### Container Networking Basics Recap
>
> *   Port Mapping (`-p HOST:CONTAINER`).
> *   Default Bridge Network (`podman`).
>
> > ##### Best Practices aus diesem Abschnitt
> >
> > *   Logs regelmäßig prüfen (`logs`, `logs -f`).
> > *   Graceful Shutdown (`stop`) bevorzugen.
> > *   Host-Port-Konflikte vermeiden (planen oder `-P`).
> > *   `inspect` für Details nutzen (ggf. `jq`).
> > *   Namen oder IDs konsistent verwenden.
>
> ### Key Takeaways
>
> *   Service Management: Start, Stop, Status, Logs.
> *   Core Commands: `ps`, `inspect`, `logs`, `stop`, `start`, `restart`, `rm`.
> *   Multiple Instances: Via Namen & Host-Ports.

---

> ##### Exercise 2: Viewing Processes Inside a Container (`podman top`)
>
> Manchmal möchten Sie sehen, welche Prozesse *innerhalb* eines laufenden Containers aktiv sind, ohne eine Shell mit `podman exec` starten zu müssen. Der Befehl `podman top` bietet hierfür eine schnelle Übersicht.
>
> ##### Step 1: Ensure the Service is Running
>
> Wir verwenden wieder unseren Webserver-Container. Stellen Sie sicher, dass er läuft:
> ```nohighlight
> podman start my-web-server || podman run -d -p 8080:80 --name my-web-server httpd:alpine
> ```
>
> ##### Step 2: Use `podman top`
>
> Führen Sie `podman top` mit dem Namen des Containers aus.
>
> **Syntax:** `podman top CONTAINER_NAME_OR_ID [TOP_OPTIONS]`
>
> **Command:**
> ```bash
> podman top my-web-server
> ```
> **Explanation:**
> *   `podman top`: Zeigt die laufenden Prozesse im angegebenen Container an.
> *   `my-web-server`: Der Name unseres Containers.
>
> **Result:** Sie sehen eine Liste der Prozesse, die im `httpd:alpine` Container laufen. Dies beinhaltet typischerweise den Apache `httpd` Prozess selbst und eventuelle Kindprozesse.
>
> > **Tipp:** Sie können auch Optionen übergeben, die der `top`-Befehl selbst versteht (abhängig vom `top`-Programm im Container-Image), z.B. `podman top my-web-server -aux` für ein detaillierteres Format, falls das `ps`-Kommando im Container dies unterstützt.
>
> `podman top` ist nützlich für eine schnelle Diagnose, um zu überprüfen, ob der erwartete Hauptprozess läuft oder ob unerwartete Prozesse aktiv sind.

---

> ##### Exercise 3: Understanding Restart Policies
>
> Für Dienste, die immer verfügbar sein sollen, ist es wichtig zu definieren, was passiert, wenn der Container (oder der Podman-Dienst selbst) unerwartet beendet wird oder neu startet. Podman bietet hierfür Restart Policies über die Option `--restart` beim `podman run` Befehl.
>
> ##### Step 1: Run a Container with a Restart Policy
>
> Wir starten einen einfachen Container, der sich nach kurzer Zeit selbst beendet, aber mit einer Restart Policy, die ihn automatisch neu starten soll.
>
> **Wichtige Restart Policies:**
> *   `no` (Standard): Container wird nicht automatisch neu gestartet.
> *   `on-failure[:N]`: Container wird neu gestartet, wenn er mit einem Fehlercode (nicht 0) beendet wird, maximal N Mal (Standard: unbegrenzt).
> *   `always`: Container wird immer neu gestartet (bei Fehler, bei manuellem Stopp, bei Systemneustart, wenn Podman als Systemd-Service läuft).
> *   `unless-stopped`: Ähnlich wie `always`, aber startet nicht neu, wenn der Container explizit gestoppt wurde (`podman stop`).
>
> **Command:**
> ```bash
> # Ggf. alten Container entfernen
> podman rm -f restart-test
>
> # Startet einen Container, der nach 3s "crasht" (exit 1), mit 'on-failure' Policy
> podman run -d --name restart-test --restart on-failure alpine:latest /bin/sh -c "sleep 3 && exit 1"
> ```
> **Explanation:**
> *   `--restart on-failure`: Weist Podman an, den Container neu zu starten, wenn er mit einem Fehlercode (hier `exit 1`) beendet wird.
> *   `/bin/sh -c "sleep 3 && exit 1"`: Der Befehl im Container wartet 3 Sekunden und beendet sich dann mit einem Fehler.
>
> ##### Step 2: Observe the Restart Behavior
>
> Beobachten Sie den Status des Containers über einige Sekunden hinweg.
>
> **Command:**
> ```bash
> watch podman ps -a --filter name=restart-test
> ```
> (Beenden Sie `watch` mit `Ctrl+C`)
>
> **Result:** Sie werden sehen, dass der Container kurz läuft ("Up ... seconds"), dann kurz in den "Exited" Status wechselt und sofort wieder neu gestartet wird ("Up ... seconds ago"). Die `RESTARTS`-Zahl in der `podman ps` Ausgabe sollte ansteigen.
>
> ##### Step 3: Test the `always` Policy (Optional, erfordert Systemd-Setup für vollen Effekt)
>
> Die `always` Policy ist besonders nützlich, wenn Podman-Container über Systemd verwaltet werden, da sie dann auch nach einem Systemneustart wieder hochkommen.
> ```bash
> # Stoppen und entfernen Sie den alten Container
> podman stop restart-test && podman rm restart-test
>
> # Starten mit 'always' (dieser Container läuft einfach)
> podman run -d --name always-test --restart always alpine:latest sleep infinity
>
> # Stoppen Sie den Container manuell
> podman stop always-test
>
> # Prüfen Sie den Status (sollte neu gestartet sein)
> podman ps --filter name=always-test
> ```
> **Hinweis:** Das Verhalten nach einem Systemneustart hängt davon ab, ob Podman selbst als Dienst (z.B. via `systemctl --user enable --now podman.socket`) konfiguriert ist.
>
> ##### Step 4: Clean Up
> ```bash
> podman rm -f restart-test always-test
> ```
> Restart Policies sind fundamental, um die Verfügbarkeit von containerisierten Diensten sicherzustellen.

---