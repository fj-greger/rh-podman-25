# Podman Lernmaterial

---

## 3 - Managing Containers and Images via Basic Diagnostics

### 3 - Managing Containers and Images via Basic Diagnostics

Wir vertiefen Container-Management, führen **Image Management** ein und lernen grundlegende Diagnostik.

#### Container Management Recap & Expansion

##### Checking Status (`ps`)
Zeigt Container an (`ps`, `ps -a`).

##### Inspecting (`inspect`)
Detaillierte JSON-Infos (`inspect <name_or_id>`).

##### Viewing Logs (`logs`)
Zeigt stdout/stderr (`logs <name_or_id>`).

##### Executing Commands (`exec`)
Führt Befehl in laufendem Container aus.

**Syntax:** `podman exec [OPTIONS] CONTAINER_NAME|ID COMMAND [ARG...]`

> ##### Exercise 1: Using `exec`
>
> Starten Sie `my-web-server` (`podman start my-web-server`) und prüfen Sie die Apache-Version *innerhalb* des Containers:
> ```bash
> podman exec my-web-server httpd -v
> ```
> Zeigen Sie die Umgebungsvariablen an:
> ```bash
> podman exec my-web-server env
> ```

##### Pulling Common Images (Example)
Holen Sie sich Beispiele.

**Syntax:** `podman pull [OPTIONS] [REGISTRY/]REPOSITORY[:TAG|@DIGEST]`

Images kommen von Registries (z.B. [Docker Hub](https://hub.docker.com/), [Quay.io](https://quay.io/)). Podman sucht in konfigurierten Registries (siehe `registries.conf`).

```bash
podman pull redis:alpine
podman pull nginx:stable-alpine
```

Kurz testen mit `--rm`:

```bash
podman run --rm redis:alpine redis-server --version
```

> ##### Best Practice: Ephemeral Containers with `--rm`
>
> Die Option `--rm` ist nützlich für:
> *   Einmalige Befehle (Tools ausführen).
> *   Tests (schnell starten/verwerfen).
> *   Debugging (Shell in Image starten).
>
> Verwenden Sie `--rm`, wann immer ein Container nur temporär benötigt wird.

> ##### Exercise 2: Container Image Management & Basic Diagnostics
>
> ### Container Image Management
>
> Lokale Images verwalten.
>
> ##### Listing Local Images (`images`)
>
> **Syntax:** `podman images [OPTIONS] [REPOSITORY[:TAG]]`
> ```bash
> podman images
> ```
>
> ##### Removing Images (`rmi`)
>
> Löscht ein Image.
>
> **Syntax:** `podman rmi [OPTIONS] IMAGE[:TAG|@DIGEST] [...]`
> ```bash
> podman rmi redis:alpine
> ```
> *   Nur möglich, wenn kein Container das Image nutzt (oder mit `-f`).
>
> ##### Pruning Unused Images (`image prune`)
>
> Gibt Speicherplatz frei.
>
> **Syntax:** `podman image prune [OPTIONS]`
> ```bash
> podman image prune     # Entfernt dangling images
> podman image prune -a  # Entfernt alle ungenutzten images
> ```
>
> > ##### Best Practices: Image Management
> >
> > *   Regelmäßig `prune`.
> > *   Vorsicht mit `prune -a`.
> > *   Spezifische Tags verwenden.
> > *   Image-Größe optimieren.
>
> ### Basic Diagnostic Procedures
>
> ##### Monitoring Resource Usage (`stats`)
>
> Zeigt Live-Ressourcenverbrauch.
>
> **Syntax:** `podman stats [OPTIONS] [CONTAINER...]`
> ```bash
> podman stats my-web-server # Spezifisch
> podman stats             # Alle laufenden
> ```
>
> > **Hinweis zu `podman stats` (Rootless & cgroups v2):**
> >
> > Benötigt **cgroups v2** für volle Funktionalität (insb. Speicher) im Rootless-Modus. Bei cgroups v1 kann es fehlschlagen.
> >
> > Prüfen: `stat -fc %T /sys/fs/cgroup/`. Lösung: System auf cgroups v2 umstellen oder Einschränkung akzeptieren. Warnung ausblenden: `export PODMAN_IGNORE_CGROUPSV1_WARNING=true`.
>
> *   `Ctrl+C` zum Beenden.
>
> > ##### Best Practices: Diagnostics
> >
> > *   `stats` für Performance-Checks (cgroups v2 beachten).
> > *   Tools kombinieren.
> > *   Systematisch vorgehen.
> > *   `exec` für gezielte Untersuchung.
>
> ##### Debugging Container Start Issues (Workflow Recap)
>
> Systematischer Ansatz:
> 1.  Check Status & Exit Code (`ps -a`).
> 2.  Check Logs (`logs`).
> 3.  Check Config (`inspect`).
> 4.  Run Interactively (`run -it --rm --entrypoint sh`).
>
> ### Key Takeaways
>
> *   Container Lifecycle & Diagnostics: `ps`, `inspect`, `logs`, `exec`, `stats`.
> *   Image Management: `pull`, `images`, `rmi`, `image prune`.
> *   Troubleshooting Workflow.
> *   Rootless Considerations (`stats`).

> ##### Exercise 3: Tagging an Existing Image (`podman tag`)
>
> Tags sind menschenlesbare Bezeichner für spezifische Versionen eines Images (z.B. `:latest`, `:3.18`, `:stable`). Sie können einem vorhandenen Image zusätzliche Tags zuweisen, z.B. um es für eine bestimmte Umgebung zu kennzeichnen oder bevor Sie es in eine andere Registry pushen.
>
> ##### Step 1: Identify an Image to Tag
>
> Wir verwenden wieder das `httpd:alpine` Image.
> ```bash
> podman images | grep httpd
> ```
>
> ##### Step 2: Add a New Tag
>
> Verwenden Sie `podman tag`, um dem Image einen neuen Namen und/oder Tag zu geben.
>
> **Syntax:** `podman tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]`
>
> **Command:**
> ```bash
> podman tag httpd:alpine my-webserver-image:v1.0
> ```
> **Explanation:**
> *   `podman tag`: Weist einen neuen Tag zu.
> *   `httpd:alpine`: Das Quell-Image.
> *   `my-webserver-image:v1.0`: Der neue Name und Tag, den wir zuweisen.
>
> **Wichtig:** `podman tag` erstellt *keine Kopie* des Images. Es fügt lediglich einen weiteren Verweis (Pointer) auf dieselben zugrundeliegenden Image-Layer hinzu. Das ist sehr effizient.
>
> ##### Step 3: Verify the New Tag
>
> Listen Sie die Images erneut auf.
>
> **Command:**
> ```bash
> podman images
> ```
> **Result:** Sie sollten nun sowohl `httpd:alpine` als auch `my-webserver-image:v1.0` in der Liste sehen. Beachten Sie, dass sie dieselbe `IMAGE ID` haben, was bestätigt, dass sie auf denselben Daten basieren.
>
> ##### Step 4: Remove the New Tag (Optional)
>
> Sie können einen spezifischen Tag mit `podman rmi` entfernen, ohne das Original-Image zu löschen (solange noch andere Tags darauf verweisen).
> ```bash
> podman rmi my-webserver-image:v1.0
> ```
> Überprüfen Sie mit `podman images` erneut. `my-webserver-image:v1.0` sollte weg sein, aber `httpd:alpine` ist noch da.
>
> Tagging ist essenziell für die Versionierung und Organisation Ihrer Images.