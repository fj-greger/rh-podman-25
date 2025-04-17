# Podman Lernmaterial

---

## 9 - Using `podman play kube`

### 9 - Using `podman play kube`

Eine Kernstärke von Podman ist seine enge Integration mit Kubernetes-Konzepten. Mit **`podman play kube`** können Sie Pods und zugehörige Ressourcen direkt aus **Kubernetes YAML-Manifesten** starten. Dies bietet einen mächtigen, deklarativen Ansatz zur Verwaltung Ihrer lokalen Container-Workloads und erleichtert den Übergang zu einer echten Kubernetes-Umgebung.

Vorteile:

*   **Deklarativ:** Beschreibung des *gewünschten Zustands*.
*   **Kubernetes-kompatibel:** Standard Kubernetes YAML Syntax.
*   **Reproduzierbar & Versionierbar:** YAML in Git verwalten.
*   **Mächtiger als Compose:** Unterstützt mehr K8s-Konstrukte (Pods, Volumes, ConfigMaps, Secrets).
*   **Ermöglicht Nutzung von `podman generate kube` Output:** `play kube` ist das Werkzeug, um mit `generate kube` erzeugte YAML-Dateien (nach Bereinigung) auszuführen.

`podman play kube` interpretiert die Kubernetes-Objekte in der/den YAML-Datei(en) und erstellt die entsprechenden Podman-Ressourcen (Pods, Container, Volumes, Netzwerkkonfigurationen). Sie können eine einzelne YAML-Datei, mehrere Dateien oder ein ganzes Verzeichnis mit YAML-Dateien übergeben.

#### Mapping von Kubernetes-Konzepten zu Podman

Es ist wichtig zu verstehen, wie `podman play kube` Kubernetes-Objekte auf Podman-Ressourcen abbildet:

*   **`Pod`**: Wird direkt als Podman Pod erstellt.
*   **`PersistentVolumeClaim` (PVC)**: Wird auf ein existierendes **Podman Volume** gemappt. Der `claimName` im YAML muss dem Namen des Podman Volumes entsprechen. Das Volume muss vor dem Ausführen von `play kube` existieren.
*   **`ConfigMap`**: Die Daten aus einem ConfigMap werden normalerweise nicht direkt von Podman gespeichert. Stattdessen verwenden Sie die Option `--configmap <host_file_or_dir_path>` beim `podman play kube`-Befehl, um den Inhalt einer lokalen Datei oder eines Verzeichnisses als ConfigMap in den Pod zu mounten, wo er im YAML referenziert wird.
*   **`Secret`**: Ähnlich wie ConfigMaps. Sie können entweder die Option `--secret <host_file_path>[,opt=val]` verwenden, um eine lokale Datei als Secret zu mounten, oder (bevorzugt) ein **Podman-verwaltetes Secret** (erstellt mit `podman secret create`) verwenden. Im YAML referenzieren Sie dann den Namen des Podman-Secrets über `secretName`.
*   **`Deployment`, `StatefulSet`, `Service`**: Diese komplexeren Kubernetes-Controller und Netzwerkobjekte werden von `podman play kube` nur teilweise oder gar nicht unterstützt. `play kube` konzentriert sich primär auf das Erstellen von Pods basierend auf der Pod-Spezifikation (die auch in Deployments etc. enthalten ist). Netzwerk-Services (`kind: Service`) werden ignoriert; Port-Mapping erfolgt über die Option `--publish HOST_PORT:CONTAINER_PORT` beim `play kube` Befehl oder (nicht empfohlen für Portabilität) über `hostPort` in der Pod-Spezifikation.

---

> ##### Exercise 1: Simple Pod from Scratch
>
> Diese Übung zeigt, wie man eine minimale Kubernetes Pod YAML-Datei manuell erstellt und mit `podman play kube` startet. Dies ist der grundlegendste Anwendungsfall.
>
> ##### Step 1: Create `simple-nginx-pod.yaml`
>
> Erstellen Sie eine Datei namens `simple-nginx-pod.yaml` mit folgendem Inhalt:
> ```yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: simple-nginx-pod
>   labels:
>     app: nginx-demo
> spec:
>   containers:
>   - name: nginx-container
>     image: docker.io/library/nginx:alpine # Vollständiger Image-Name ist gute Praxis
>     ports:
>     - containerPort: 80 # Port, auf dem Nginx im Container lauscht
> ```
> **Explanation:**
> *   `apiVersion: v1`, `kind: Pod`: Standard Kubernetes Header.
> *   `metadata.name`: Name des Pods, den Podman erstellen wird.
> *   `spec.containers[]`: Liste der Container im Pod (hier nur einer).
> *   `name`: Name des Containers innerhalb des Pods.
> *   `image`: Das zu verwendende Container-Image.
> *   `ports.containerPort`: Der Port, den der Container intern bereitstellt. Wichtig für das Port-Mapping beim Start.
>
> ##### Step 2: Deploy with `podman play kube`
>
> Stellen Sie sicher, dass Port 8082 auf Ihrem Host frei ist.
> ```bash
> # Sicherstellen, dass kein alter Pod mit gleichem Namen existiert
> podman pod rm -f simple-nginx-pod
>
> # Deploy mit explizitem Port-Mapping (Host 8082 -> Container 80)
> # Das Flag --publish (oder -p) wird verwendet, um Ports zu mappen
> podman play kube --publish 8082:80 simple-nginx-pod.yaml
> ```
>
> ##### Step 3: Verify Deployment
>
> ```bash
> # Überprüfen Sie, ob der Pod läuft
> podman pod ps
> # Überprüfen Sie die Container im Pod
> podman ps --pod --filter pod=simple-nginx-pod
> ```
> > **Beobachtung: Zwei Container im Pod?**
> >
> > Sie werden feststellen, dass der Befehl `podman ps --pod` zwei Container für Ihren `simple-nginx-pod` anzeigt, obwohl Sie nur einen (`nginx-container`) in der YAML definiert haben:
> > *   Einen Container mit Ihrem definierten Image (z.B. `docker.io/library/nginx:alpine`).
> > *   Einen weiteren Container mit einem Namen wie `*-infra` und einem Image wie `localhost/podman-pause:...`.
> >
> > Dies ist **völlig normal**. Dieser zweite Container ist der **Infrastruktur-Container** (auch "Pause"-Container genannt). Er wird automatisch von Podman für jeden Pod erstellt. Seine Hauptaufgabe ist es, die gemeinsamen Linux-Namespaces (insbesondere den Netzwerk-Namespace mit der IP-Adresse und den Port-Mappings) für alle anderen Container im Pod zu halten. Sie interagieren normalerweise nicht direkt mit diesem Infra-Container.
> ```bash
> # Testen Sie den Zugriff auf Nginx über den gemappten Port
> curl http://localhost:8082
> ```
> Sie sollten die Nginx-Willkommensseite sehen.
>
> ##### Step 4: Tear Down Deployment
>
> Verwenden Sie die Option `--down`, um die durch die YAML-Datei definierten Ressourcen zu entfernen.
> ```bash
> podman play kube --down simple-nginx-pod.yaml
> ```
> Diese Übung zeigt die grundlegende Struktur einer Pod-YAML und deren Verwendung mit `play kube`, inklusive des empfohlenen Port-Mappings über `--publish`.

---

> ##### Exercise 2: Pod with Two Containers
>
> Diese Übung baut auf der vorherigen auf und zeigt, wie man einen Pod mit **zwei** verschiedenen Containern definiert und startet. Dies verdeutlicht, wie Container innerhalb eines Pods den Netzwerk-Namespace teilen, aber auf unterschiedlichen Ports lauschen können.
> Wir verwenden einen Nginx-Container und den einfachen Flask-App-Container (`my-flask-app:1.1`) aus einem früheren Topic (stellen Sie sicher, dass dieses Image existiert).
>
> ##### Step 1: Create `multi-container-pod.yaml`
>
> Erstellen Sie eine Datei namens `multi-container-pod.yaml` mit folgendem Inhalt:
> ```yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: multi-container-pod
>   labels:
>     app: multi-demo
> spec:
>   containers:
>   - name: nginx-service # Erster Container: Nginx
>     image: docker.io/library/nginx:alpine
>     ports:
>     - containerPort: 80 # Nginx lauscht auf Port 80 im Pod
>
>   - name: flask-service # Zweiter Container: Flask App
>     image: localhost/my-flask-app:1.1 # Benötigt das Image aus Topic 5
>     ports:
>     - containerPort: 5000 # Flask App lauscht auf Port 5000 im Pod
>     # Umgebungsvariablen für die Flask-App (optional, je nach App-Konfiguration)
>     # env:
>     # - name: FLASK_VARIABLE
>     #   value: "some_value"
> ```
> **Explanation:**
> *   Wir definieren einen Pod namens `multi-container-pod`.
> *   Unter `spec.containers` listen wir nun **zwei** Container auf:
>     *   `nginx-service`: Läuft Nginx und deklariert `containerPort: 80`.
>     *   `flask-service`: Läuft unsere Flask-App und deklariert `containerPort: 5000`.
> *   Beide Container werden im selben Pod laufen und teilen sich denselben Netzwerk-Namespace (dieselbe IP-Adresse innerhalb des Pods), aber sie müssen auf unterschiedlichen Ports lauschen, um Konflikte zu vermeiden.
>
> > **Voraussetzung:** Stellen Sie sicher, dass das Image `localhost/my-flask-app:1.1` (oder die Version, die Sie in Topic 5 erstellt haben) lokal verfügbar ist. Sie können es mit `podman images` überprüfen.
>
> ##### Step 2: Deploy with `podman play kube` (Multiple Ports)
>
> Stellen Sie sicher, dass die Ports 8084 und 8085 auf Ihrem Host frei sind. Wir verwenden jetzt **zwei** `--publish` Flags, um jeden Container-Port auf einen eigenen Host-Port zu mappen.
> ```bash
> # Sicherstellen, dass kein alter Pod mit gleichem Namen existiert
> podman pod rm -f multi-container-pod
>
> # Deploy mit zwei expliziten Port-Mappings:
> # Host 8084 -> Pod Port 80 (Nginx)
> # Host 8085 -> Pod Port 5000 (Flask)
> podman play kube --publish 8084:80 --publish 8085:5000 multi-container-pod.yaml
> ```
>
> ##### Step 3: Verify Deployment
>
> ```bash
> # Überprüfen Sie, ob der Pod läuft
> podman pod ps
> # Überprüfen Sie die Container im Pod (Sie sollten jetzt 3 sehen: nginx, flask, infra)
> podman ps --pod --filter pod=multi-container-pod
>
> # Testen Sie den Zugriff auf Nginx
> curl http://localhost:8084
> # Erwartete Ausgabe: Nginx Willkommensseite HTML
>
> # Testen Sie den Zugriff auf die Flask App
> curl http://localhost:8085
> # Erwartete Ausgabe: Die Ausgabe Ihrer Flask-App (z.B. "Datenbank verbunden!" oder ähnliches)
> ```
> Sie sollten beide Dienste über ihre jeweiligen Host-Ports erreichen können.
>
> ##### Step 4: Tear Down Deployment
>
> ```bash
> podman play kube --down multi-container-pod.yaml
> ```
> Diese Übung hat gezeigt, wie man eine YAML-Datei für einen Pod mit mehreren Containern erstellt und wie man mehrere Ports mit `podman play kube` veröffentlicht.

---

> ##### Exercise 3: Generating, Cleaning, and Playing Kubernetes YAML
>
> Diese Übung zeigt den Workflow, um eine bestehende Podman-Anwendung (Pod mit Containern) in ein Kubernetes-YAML-Format zu überführen (`generate kube`), diese YAML zu bereinigen und sie dann wieder bereitzustellen (`play kube`).
>
> ### Hands-on: Generating, Cleaning, and Playing
>
> ##### Step 1: Generate Kubernetes YAML (from a running Pod)
>
> Wenn Sie bereits eine geeignete Kubernetes-YAML-Datei haben, können Sie diesen Schritt überspringen. Falls nicht, können wir sie aus einem (temporär) laufenden Pod erstellen. Dieser Schritt dient nur der Generierung der YAML.
>
> > **Ziel dieses Schritts:** Nur die YAML-Datei `pod-for-generate.yaml` zu erzeugen. Die hierfür erstellten Ressourcen (`temp-pod-gen`) werden danach sofort wieder entfernt.
> >
> > **Kontext:** Dieser Ansatz (temporäre Ressourcen erstellen -> YAML generieren -> Ressourcen entfernen) ist eine Methode, um eine initiale YAML-Datei zu erhalten, wenn man von einer bestehenden (oder leicht erstellbaren) Container-Konfiguration ausgeht. Es kann komplex erscheinen, ist aber eine Möglichkeit, den `generate kube`-Befehl zu nutzen. Wenn Sie die Struktur bereits kennen, ist das manuelle Erstellen der YAML (siehe Übung 1 & 2) oft einfacher.
> >
> > **Wichtig: Konflikte vermeiden!** Wir verwenden temporär Port 8081 und ein separates Volume `mysql_data_gen`.
> > ```bash
> > # Sicherstellen, dass temporäre Ressourcen nicht existieren
> > podman pod rm -f temp-pod-gen
> > podman rm -f db-gen app-gen
> > podman volume rm -f mysql_data_gen # Altes Volume entfernen
> >
> > # Temporäres Volume für die Generierung erstellen
> > podman volume create mysql_data_gen
> > ```
>
> 1.  **Erstellen Sie temporär den Pod und die Container (auf Port 8081):**
>     ```bash
>     # Pod erstellen (mappt Host 8081 auf Pod 5000)
>     podman pod create --name temp-pod-gen -p 8081:5000
>
>     # DB-Container im Pod starten (nutzt separates Volume)
>     podman run -d --pod temp-pod-gen --name db-gen \
>     -v mysql_data_gen:/var/lib/mysql \
>     -e MYSQL_ROOT_PASSWORD=mysecretpassword -e MYSQL_DATABASE=webappdb \
>     mysql:8.0
>
>     # Webapp-Container im Pod starten (Image aus Topic 5, stellen Sie sicher, dass es existiert!)
>     # Warten Sie einen Moment, bis die DB initialisiert ist (ca. 10-20 Sekunden)
>     sleep 15
>     podman run -d --pod temp-pod-gen --name app-gen \
>     -e MYSQL_ROOT_PASSWORD=mysecretpassword -e MYSQL_DATABASE=webappdb \
>     my-flask-app:1.1 # Stellen Sie sicher, dass dieses Image lokal verfügbar ist
>     ```
> 2.  **Generieren Sie die Kubernetes YAML für den Pod:**
>     ```bash
>     # Generiert die YAML-Datei für den Pod 'temp-pod-gen'
>     podman generate kube temp-pod-gen > pod-for-generate.yaml
>     ```
> 3.  **Bereinigen Sie die temporären Ressourcen:**
>     ```bash
>     # Pod und Container entfernen
>     podman pod rm -f temp-pod-gen
>
>     # Das temporäre Volume wird NICHT automatisch entfernt, kann aber später genutzt
>     # oder manuell entfernt werden (siehe unten).
>     # podman volume rm mysql_data_gen
>     ```
>
> ##### Step 2: Inspect and Modify the Generated YAML
>
> Öffnen Sie die generierte `pod-for-generate.yaml`. Sie enthält Details des *laufenden* Pods zum Zeitpunkt der Generierung, inklusive einiger Runtime-Informationen, die wir bereinigen müssen.
>
> > **Verständnis & Notwendigkeit der Anpassung von `generate kube` Output:** `podman generate kube` erstellt einen Snapshot des *aktuellen Zustands*. Diese rohe YAML enthält oft laufzeitspezifische Details (Timestamps, interne IDs, etc.), die für eine wiederverwendbare, *deklarative* Definition stören.
> >
> > **Obwohl `podman play kube` die rohe Datei manchmal ausführt, ist eine Bereinigung entscheidend für:**
> > *   **Lesbarkeit & Wartbarkeit:** Entfernt unnötiges Rauschen.
> > *   **Vermeidung von Konflikten:** Korrigiert Namen (Pod, Container, Volumes) und potenzielle `hostPort`-Mappings.
> > *   **Korrektheit:** Behebt potenzielle Fehler in der generierten Struktur (z.B. falsch platzierte Ports).
> > *   **Wiederverwendbarkeit & Versionierung:** Erzeugt eine klare, stabile Definition für Git und verschiedene Einsatzzwecke.
> >
> > **Wichtiger Hinweis:** Auch wenn `podman play kube` die rohe `pod-for-generate.yaml` manchmal ohne Fehler ausführen *könnte*, ist dies **nicht empfohlen**. Sich darauf zu verlassen ist unzuverlässig und widerspricht dem Prinzip eines sauberen, deklarativen Manifests. Die Bereinigung ist ein kritischer Schritt für eine robuste Konfiguration.
> >
> > Es ist daher fast immer notwendig, die generierte YAML zu überprüfen und zu bereinigen.
>
> Die **original generierte YAML** (basierend auf Ihrem Beispiel) sieht etwa so aus (Details können leicht variieren):
> ```yaml
> # Created with podman-x.y.z
> apiVersion: v1
> kind: Pod
> metadata:
>   # Diese Felder sind Runtime-spezifisch und sollten entfernt werden:
>   annotations:
>     io.kubernetes.cri-o.CONTAINER_ID.db-gen: abc...
>     io.kubernetes.cri-o.CONTAINER_ID.app-gen: def...
>     io.kubernetes.cri-o.SANDBOX_ID: ghi... # Kann auch andere Felder enthalten
>   creationTimestamp: "2024-..." # Zeitstempel entfernen
>   # Dieses Label und der Name sollten überprüft und ggf. angepasst werden:
>   labels:
>     app: temp-pod-gen
>   name: temp-pod-gen # <<< Ggf. ANPASSEN für Wiederverwendung
> spec:
>   containers:
>     # --- DB Container ---
>     - name: db-gen # <<< Ggf. ANPASSEN
>       image: docker.io/library/mysql:8.0
>       env:
>         - name: MYSQL_DATABASE
>           value: webappdb
>         - name: MYSQL_ROOT_PASSWORD
>           value: mysecretpassword
>         # Von Podman hinzugefügt, oft unnötig, kann entfernt werden:
>         - name: TERM
>           value: xterm
>       volumeMounts:
>         - mountPath: /var/lib/mysql
>           name: mysql-data-gen-pvc # <<< Ggf. ANPASSEN (interner Volume-Name)
>       # Optional, kann oft entfernt werden, wenn Image CMD/ENTRYPOINT korrekt ist:
>       # args:
>       #  - mysqld
>       # securityContext: {} # Leer, kann weg
>       # workingDir: "" # Leer, kann weg
>
>     # --- Webapp Container ---
>     - name: app-gen # <<< Ggf. ANPASSEN
>       image: localhost/my-flask-app:1.1 # <<< PRÜFEN/ANPASSEN Image Name
>       env:
>         - name: MYSQL_ROOT_PASSWORD
>           value: mysecretpassword
>         - name: MYSQL_DATABASE
>           value: webappdb
>         # Von Podman hinzugefügt, oft unnötig, kann entfernt werden:
>         - name: TERM
>           value: xterm
>       ports:
>         # <<< KORREKT HIER: Port, den die App im Container öffnet! BEIBEHALTEN/PRÜFEN
>         - containerPort: 5000
>           # hostPort: 8081 # <<< ENTFERNEN! Besser --publish bei play kube verwenden
>       # securityContext: {} # Leer, kann weg
>       # workingDir: "" # Leer, kann weg
>
>   # --- Pod Volumes Definition ---
>   volumes:
>     - name: mysql-data-gen-pvc # <<< Ggf. ANPASSEN (interner Volume-Name, muss zu volumeMounts passen)
>       persistentVolumeClaim:
>         # <<< WICHTIG: ANPASSEN auf den Namen des gewünschten Podman Volumes!
>         claimName: mysql_data_gen # <<< Z.B. auf 'mysql_data' ändern, wenn dieses Volume verwendet werden soll
> ```
> **Notwendige Modifikationen für die Wiederverwendung:**
> 1.  **Kritisch: Entfernen von Runtime-Artefakten & Redundanz:** Diese Elemente **müssen** oder sollten entfernt werden.
>     *   Den gesamten `metadata.annotations:` Block.
>     *   Das Feld `metadata.creationTimestamp: ...`.
>     *   Die `env` Einträge für `TERM: xterm` in beiden Containern (normalerweise unnötig).
>     *   Den Eintrag `hostPort: ...` unter `ports:` im `app-gen` Container. Das Mapping erfolgt besser über `--publish`.
>     *   Optionale, oft leere oder redundante Felder wie `securityContext: {}`, `workingDir: ""`, `args: [...]` (wenn das Image korrekt konfiguriert ist).
> 2.  **Kritisch: Überprüfen und Anpassen von Namen & Referenzen:** Diese müssen korrekt sein.
>     *   `metadata.name`: Der gewünschte Name für den Pod (z.B. `db-app-pod`).
>     *   `metadata.labels`: Ggf. anpassen.
>     *   `spec.containers[].name`: Namen der Container (z.B. `database`, `webapp`).
>     *   `spec.containers[].image`: Sicherstellen, dass der Image-Name korrekt und das Image verfügbar ist.
>     *   `volumes.persistentVolumeClaim.claimName`: **Sehr wichtig!** Muss exakt dem Namen des Podman Volumes entsprechen, das Sie für die persistenten Daten verwenden möchten (z.B. `mysql_data`).
>     *   `volumes.name` und `volumeMounts.name`: Müssen innerhalb der YAML übereinstimmen, können aber auch angepasst werden (z.B. `db-storage`).
> 3.  **Kritisch: Sicherstellen der Port-Definition:**
>     *   Überprüfen Sie, ob `ports.containerPort` im `webapp` Container korrekt den Port angibt, auf dem die Anwendung im Container lauscht (hier `5000`).
>
> Hier ist eine **bereinigte und angepasste** YAML (gespeichert als `db-app-pod.yaml`), die für die Wiederverwendung gedacht ist:
> ```yaml
> # Bereinigte und angepasste Version für 'podman play kube'
> # Gespeichert als: db-app-pod.yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: db-app-pod # Angepasster Pod-Name
>   labels:
>     app: database-app # Angepasstes Label
> spec:
>   containers:
>     # --- DB Container ---
>     - name: database # Angepasster Container-Name
>       image: docker.io/library/mysql:8.0 # Image überprüfen
>       env:
>         - name: MYSQL_DATABASE
>           value: webappdb
>         - name: MYSQL_ROOT_PASSWORD
>           value: mysecretpassword # Besser: Secret verwenden (siehe Übung 4)
>       volumeMounts:
>         - mountPath: /var/lib/mysql
>           name: db-storage # Angepasster interner Volume-Mount-Name
>
>     # --- Webapp Container ---
>     - name: webapp # Angepasster Container-Name
>       image: localhost/my-flask-app:1.1 # Image überprüfen/anpassen
>       env:
>         - name: MYSQL_ROOT_PASSWORD
>           value: mysecretpassword # Besser: Secret verwenden
>         - name: MYSQL_DATABASE
>           value: webappdb
>       ports:
>         # Port, den die Webapp im Container bereitstellt
>         - containerPort: 5000
>
>   # --- Pod Volumes Definition ---
>   volumes:
>     # Angepasster interner Volume-Name
>     - name: db-storage
>       persistentVolumeClaim:
>         # WICHTIG: Dieser Name muss mit dem zu verwendenden Podman Volume übereinstimmen!
>         # Erstellen Sie dieses Volume vorher mit 'podman volume create mysql_data'
>         claimName: mysql_data
> ```
> > **Wichtiger Schritt: Speichern unter neuem Namen!** Speichern Sie den oben gezeigten, bereinigten und angepassten YAML-Inhalt in einer **neuen Datei**, z.B. `db-app-pod.yaml`. Verwenden Sie für die nächsten Schritte diese bereinigte Datei.
> >
> > **Beachten Sie den `claimName`!** Der kritischste Punkt nach der Bereinigung ist der `persistentVolumeClaim.claimName`. Er *muss* exakt dem Namen des Podman Volumes entsprechen, das die persistenten Daten enthalten soll (im Beispiel oben `mysql_data`). Stellen Sie sicher, dass dieses Volume existiert, bevor Sie `play kube` ausführen.
>
> ##### Step 3: Deploy with `podman play kube`
>
> Stellen Sie sicher, dass keine Konflikte bestehen (Pod-Name `db-app-pod`, Port 8080) und das in der YAML unter `claimName` referenzierte Volume (im Beispiel `mysql_data`) existiert.
>
> > **Konflikte prüfen/beheben & Volume sicherstellen:**
> > ```bash
> > # Entfernen, falls der Pod (mit diesem Namen) noch/wieder läuft
> > podman pod rm -f db-app-pod
> >
> > # Sicherstellen, dass das Ziel-Volume existiert (Name muss zum claimName in der YAML passen!)
> > # Beispiel für claimName: mysql_data (wie in der bereinigten YAML oben)
> > podman volume create mysql_data
> > ```
>
> Führen Sie den Befehl mit der **bereinigten und angepassten** YAML aus:
>
> **Syntax:** `podman play kube [OPTIONS] YAML_FILE`
> ```bash
> # Empfohlene Methode: Port Mapping explizit über --publish Flag angeben
> # Mappt Host-Port 8080 auf den containerPort 5000 der Webapp
> podman play kube --publish 8080:5000 db-app-pod.yaml
>
> # Alternative (falls hostPort in YAML definiert wäre, nicht empfohlen):
> # podman play kube db-app-pod.yaml
> ```
> **Hinweis zum Port-Mapping:** Während `hostPort` in der YAML für lokale Podman-Tests funktionieren kann, ist es für bessere Portabilität und Kubernetes-Kompatibilität generell empfohlen, `hostPort` in der Pod-Definition wegzulassen. Verwenden Sie stattdessen die Option `--publish HOST_PORT:CONTAINER_PORT` direkt beim `podman play kube`-Befehl, um das Mapping festzulegen (z.B. `--publish 8080:5000`). Dies hält Ihre YAML-Definition sauberer.
>
> Podman liest die YAML und erstellt den Pod `db-app-pod` mit den Containern `database` und `webapp`.
>
> ##### Step 4: Verify Deployment
>
> ```bash
> # Prüfen Sie den Pod-Status
> podman pod ps
> # Listen Sie Container im Pod auf
> podman ps --pod --filter pod=db-app-pod
> # Testen Sie die Webanwendung
> curl http://localhost:8080
> ```
> Die Anwendung sollte über Port 8080 erreichbar sein.
>
> ##### Step 5: Update Deployment (Example)
>
> Ändern Sie `db-app-pod.yaml` (z.B. Image-Tag der Webapp auf `localhost/my-flask-app:1.2`, falls dieses Image existiert) und wenden Sie die Änderungen an. Podman versucht, den bestehenden Pod anzupassen. Bei vielen Änderungen ist jedoch ein Ersatz (`--replace`) notwendig.
> ```bash
> # YAML bearbeiten... (z.B. image: localhost/my-flask-app:1.2)
>
> # Versuch, den Pod inplace zu aktualisieren (funktioniert nicht immer)
> # podman play kube --publish 8080:5000 db-app-pod.yaml
>
> # Besser für Updates: Ersetzt den bestehenden Pod, falls er existiert
> podman play kube --replace --publish 8080:5000 db-app-pod.yaml
> ```
> Die Option `--replace` löscht den alten Pod (und seine Container) und erstellt ihn neu basierend auf der aktualisierten YAML.
>
> ##### Step 6: Tear Down Deployment
>
> **Syntax:** `podman play kube --down YAML_FILE`
> ```bash
> podman play kube --down db-app-pod.yaml
> ```
> Dies stoppt und entfernt den Pod (`db-app-pod`) und die zugehörigen Container (`database`, `webapp`), die durch diese YAML-Datei erstellt wurden. Das referenzierte Volume (`mysql_data` im Beispiel) bleibt standardmäßig erhalten!
> ```bash
> # Optional: Volume entfernen, wenn nicht mehr benötigt
> # podman volume rm mysql_data
> ```

---

> ##### Exercise 4: Pod with ConfigMap from File (Explicit CM YAML Method)
>
> Kubernetes ConfigMaps werden verwendet, um Konfigurationsdaten von Anwendungs-Images zu entkoppeln. Wie die Fehlermeldungen und die Hilfe von `podman play kube` zeigen, erwartet die Option `--configmap` den Pfad zu einer **YAML-Datei, die den ConfigMap definiert**.
>
> ##### Step 1: Create ConfigMap Definition YAML
>
> Erstellen Sie direkt die **erforderliche** Datei, z.B. `app-config-cm.yaml`, die den Kubernetes ConfigMap definiert und die gewünschten Konfigurationsdaten enthält:
> ```yaml
> # app-config-cm.yaml
> apiVersion: v1
> kind: ConfigMap
> metadata:
>   # Dieser Name ('app-config') wird in der Pod-YAML referenziert
>   name: app-config
> data:
>   # Der Schlüssel hier ('my-app.conf') muss zum 'items.key'
>   # in der Pod-YAML passen und den gewünschten Dateinamen
>   # im gemounteten Volume repräsentieren.
>   my-app.conf: |
>     # Dies ist der Inhalt, der als Datei gemountet wird
>     GREETING="Hallo aus der ConfigMap!"
>     LOG_LEVEL=DEBUG
>     FEATURE_FLAG=true
> ```
> **Wichtig:** Der Wert unter dem Schlüssel `my-app.conf:` in dieser YAML-Datei ist der eigentliche Inhalt, der im Container als Datei erscheinen soll. Das `|` sorgt dafür, dass Zeilenumbrüche korrekt behandelt werden.
>
> ##### Step 2: Create Pod Definition YAML
>
> Erstellen Sie die Pod-Definitionsdatei `configmap-pod.yaml`, die diesen ConfigMap referenziert:
> ```yaml
> # configmap-pod.yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: configmap-test-pod
> spec:
>   containers:
>   - name: config-reader # Name des Containers in der YAML
>     image: docker.io/library/alpine:latest
>     # Befehl, der die gemountete Konfigurationsdatei liest und ausgibt, dann wartet
>     command: ["/bin/sh", "-c"]
>     args:
>       - "echo '--- ConfigMap Inhalt ---'; cat /etc/config/my-app.conf; echo '--- Ende ---'; sleep 3600"
>     volumeMounts:
>       # Mountet das Volume 'config-volume' im Container unter /etc/config
>       - name: config-volume
>         mountPath: /etc/config # Zielverzeichnis im Container
>   volumes:
>     # Definiert ein Volume namens 'config-volume', das seine Daten
>     # aus einem ConfigMap namens 'app-config' bezieht.
>     - name: config-volume
>       configMap:
>         # Dieser Name muss zum metadata.name in app-config-cm.yaml passen
>         name: app-config
>         # 'items' spezifiziert, welcher Schlüssel aus dem ConfigMap
>         # als welche Datei im Mount-Pfad erscheinen soll.
>         items:
>         - key: my-app.conf # Muss zum Schlüssel in app-config-cm.yaml passen
>           path: my-app.conf # Der Dateiname, wie er im Volume (/etc/config) erscheinen soll
> ```
>
> ##### Step 3: Deploy with `podman play kube --configmap`
>
> Jetzt verwenden wir `podman play kube` und übergeben den Pfad zur **ConfigMap-Definitionsdatei** (`app-config-cm.yaml`) an das `--configmap` Flag. Die Pod-Definition kommt als letzter Parameter.
> ```bash
> # Ggf. alten Pod entfernen
> podman pod rm -f configmap-test-pod
>
> # Deploy: Verwende app-config-cm.yaml als Quelle für den ConfigMap
> #         und configmap-pod.yaml als Pod-Manifest
> podman play kube --configmap app-config-cm.yaml configmap-pod.yaml
> ```
> **Explanation:**
> *   `--configmap app-config-cm.yaml`: Weist Podman an, die Kubernetes-Ressource zu verwenden, die in `app-config-cm.yaml` definiert ist (also den ConfigMap `app-config`).
> *   `configmap-pod.yaml`: Dies ist das Haupt-Manifest, das den Pod definiert, der diesen ConfigMap (`app-config`) referenziert und mountet.
>
> Dieser Ansatz entspricht genau der Beschreibung im `podman play kube -h` und funktioniert zuverlässig.
>
> ##### Step 4: Verify ConfigMap Mount
>
> Überprüfen Sie die Logs des Containers. Verwenden Sie den **vollständigen Namen** des Containers, wie er von `podman ps` angezeigt wird (im Format `<pod_name>-<container_name_in_yaml>`).
> ```bash
> # Finden Sie zuerst den vollständigen Namen des Containers
> podman ps --pod --filter pod=configmap-test-pod
>
> # Verwenden Sie den vollständigen Namen (z.B. configmap-test-pod-config-reader) für Logs
> podman logs configmap-test-pod-config-reader
> ```
> > **Hinweis zur Container-Benennung:** Podman erstellt den tatsächlichen Container-Namen oft, indem es den Pod-Namen und den in der YAML definierten Container-Namen kombiniert (z.B. wird aus `config-reader` im Pod `configmap-test-pod` der Container `configmap-test-pod-config-reader`). Sie müssen diesen vollständigen Namen verwenden, um mit `podman logs` oder `podman exec` auf den Container zuzugreifen.
>
> **Result:** Die Ausgabe sollte den Inhalt anzeigen, den Sie in `app-config-cm.yaml` unter dem Schlüssel `my-app.conf:` definiert haben.
>
> Sie können auch `exec` verwenden, um die Datei direkt im Container zu prüfen (ersetzen Sie den Namen falls nötig):
> ```bash
> podman exec configmap-test-pod-config-reader cat /etc/config/my-app.conf
> ```
>
> ##### Step 5: Tear Down Deployment
>
> ```bash
> # Verwenden Sie --down mit der Pod-YAML-Datei, um den Pod zu entfernen
> # Das --configmap Flag wird hier NICHT benötigt.
> podman play kube --down configmap-pod.yaml
>
> # Entfernen Sie die erstellten YAML-Dateien
> rm app-config-cm.yaml
> rm configmap-pod.yaml
> ```
> Dies zeigt den zuverlässigen Weg, ConfigMaps aus Dateien mit `podman play kube` zu verwenden, indem eine explizite ConfigMap-YAML-Definition erstellt wird.

---

> ##### Exercise 5: Pod with Secret
>
> Ähnlich wie bei ConfigMaps erstellen wir zuerst eine YAML-Datei, die das Secret definiert (mit base64-kodierten Daten), und dann eine separate Pod-YAML, die das Secret referenziert.
>
> ##### Step 1: Generate Base64 Encoded Secret Value
>
> Wählen Sie Ihr geheimes Datum und kodieren Sie es. Das `-n` bei `echo` ist wichtig.
> ```bash
> # Beispiel: Kodieren des Strings "MyVerySecureApiKey123"
> echo -n "MyVerySecureApiKey123" | base64
> ```
> **Result:** Kopieren Sie die Base64-Ausgabe (z.B. `TXlWZXJ5U2VjdXJlQXBpS2V5MTIz`). Sie benötigen diesen Wert im nächsten Schritt.
>
> ##### Step 2: Create Secret Definition YAML
>
> Erstellen Sie die Datei `api-key-secret.yaml`, die das Kubernetes Secret definiert. Fügen Sie den Base64-kodierten String ein.
> ```yaml
> # api-key-secret.yaml
> apiVersion: v1
> kind: Secret
> metadata:
>   # Dieser Name ('api-credentials') wird in der Pod-YAML referenziert
>   name: api-credentials
> type: Opaque # Standardtyp für beliebige Daten
> data:
>   # Der Schlüssel hier ('api-key') muss zum 'items.key'
>   # in der Pod-YAML passen.
>   # Fügen Sie hier den base64-kodierten Wert aus Step 1 ein:
>   api-key: IHREN_BASE64_KODIERTEN_WERT_HIER_EINFÜGEN
> ```
> **Wichtig:** Ersetzen Sie `IHREN_BASE64_KODIERTEN_WERT_HIER_EINFÜGEN` mit der Ausgabe des `base64`-Befehls.
>
> ##### Step 3: Create Pod Definition YAML
>
> Erstellen Sie die Pod-Definitionsdatei `secret-pod.yaml`, die dieses Secret referenziert:
> ```yaml
> # secret-pod.yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: secret-test-pod
> spec:
>   containers:
>   - name: secret-reader # Name des Containers in der YAML
>     image: docker.io/library/alpine:latest
>     # Befehl, der das gemountete Secret liest
>     command: ["/bin/sh", "-c"]
>     args:
>       - "echo '--- Secret Inhalt ---'; cat /etc/secrets/api-key; echo '--- Ende ---'; sleep 3600"
>     volumeMounts:
>       # Mountet das Volume 'secret-volume' im Container unter /etc/secrets
>       - name: secret-volume
>         mountPath: /etc/secrets # Zielverzeichnis im Container
>         readOnly: true # Secrets sollten immer read-only gemountet werden
>   volumes:
>     # Definiert ein Volume namens 'secret-volume', das seine Daten
>     # aus einem Secret namens 'api-credentials' bezieht.
>     - name: secret-volume
>       secret:
>         # Dieser Name muss zum metadata.name in api-key-secret.yaml passen
>         secretName: api-credentials
>         # 'items' spezifiziert, welcher Schlüssel aus dem Secret
>         # als welche Datei im Mount-Pfad erscheinen soll.
>         items:
>         - key: api-key # Muss zum Schlüssel in api-key-secret.yaml passen
>           path: api-key # Der Dateiname, wie er im Volume (/etc/secrets) erscheinen soll
> ```
> **Explanation:**
> *   `volumes.secret.secretName: api-credentials`: Referenziert den Namen des Secrets aus `api-key-secret.yaml`.
> *   `volumes.secret.items`: Mappt den Schlüssel `api-key` aus dem Secret zur Datei `api-key` im Mount-Verzeichnis `/etc/secrets`. Podman dekodiert den Base64-Wert automatisch.
>
> ##### Step 4: Deploy Secret and Pod
>
> Führen Sie `podman play kube` **zuerst** für die Secret-Datei aus und **dann** für die Pod-Datei.
> ```bash
> # Ggf. alte Ressourcen entfernen
> podman play kube --down secret-pod.yaml
> podman play kube --down api-key-secret.yaml # Versuch, altes Secret zu entfernen
> podman pod rm -f secret-test-pod
>
> # 1. Erstellen Sie das Secret
> podman play kube api-key-secret.yaml
>
> # 2. Erstellen Sie den Pod, der das Secret verwendet
> podman play kube secret-pod.yaml
> ```
> **Explanation:** Podman verarbeitet jede YAML-Datei einzeln. Zuerst wird das `Secret` erstellt, dann der `Pod`, der das Secret findet und mountet.
>
> ##### Step 5: Verify Secret Mount
>
> Überprüfen Sie die Logs des Containers mit dem **vollständigen Namen** (z.B. `secret-test-pod-secret-reader`):
> ```bash
> # Finden Sie zuerst den vollständigen Namen des Containers
> podman ps --pod --filter pod=secret-test-pod
>
> # Verwenden Sie den vollständigen Namen (z.B. secret-test-pod-secret-reader) für Logs
> podman logs secret-test-pod-secret-reader
> ```
> **Result:** Die Ausgabe sollte den **dekodierten** Inhalt Ihres ursprünglichen Secrets ("MyVerySecureApiKey123") anzeigen.
>
> Prüfen Sie die Datei direkt im Container (ersetzen Sie den Namen falls nötig):
> ```bash
> podman exec secret-test-pod-secret-reader cat /etc/secrets/api-key
> ```
> > Siehe auch den Hinweis zur Container-Benennung in Übung 4.
>
> ##### Step 6: Tear Down Deployment
>
> Verwenden Sie `podman play kube --down` für **beide** YAML-Dateien, um sowohl den Pod als auch das Secret zu entfernen.
> ```bash
> # 1. Stoppen und entfernen Sie den Pod
> podman play kube --down secret-pod.yaml
>
> # 2. Entfernen Sie das Secret
> podman play kube --down api-key-secret.yaml
>
> # 3. Entfernen Sie die lokalen YAML-Dateien
> rm api-key-secret.yaml
> rm secret-pod.yaml
> ```
> Dies zeigt den zuverlässigen Weg, Secrets aus YAML-Dateien mit `podman play kube` zu verwenden.

---

> ##### Exercise 6: Defining Resource Limits in YAML
>
> Sie können Ressourcenlimits (CPU, Speicher) direkt in der Kubernetes YAML-Datei definieren, ähnlich wie in einem vollständigen Kubernetes-Cluster. `podman play kube` wird versuchen, diese Limits über die Cgroups des Pods durchzusetzen.
>
> ##### Step 1: Create `limits-pod.yaml`
>
> Erstellen Sie eine YAML-Datei, die Limits für einen Container festlegt:
> ```yaml
> # limits-pod.yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: limits-test-pod
> spec:
>   containers:
>   - name: limited-container # Name des Containers in der YAML
>     image: docker.io/library/alpine:latest
>     # Lässt den Container eine Weile laufen, damit wir ihn inspizieren können
>     command: ["sleep", "3600"]
>     resources:
>       limits:
>         # Limitiert den Speicher auf 100 MiB (Mebibytes)
>         memory: "100Mi"
>         # Limitiert die CPU auf 0.5 (halben) Kern
>         cpu: "500m" # 500 millicores = 0.5 cores
>       # Optional: 'requests' können auch definiert werden, beeinflussen aber
>       # primär die Planung in Kubernetes, weniger die harten Limits in Podman.
>       # requests:
>       #   memory: "50Mi"
>       #   cpu: "250m"
> ```
> **Explanation:**
> *   `resources.limits.memory`: Maximaler Speicher, den der Container verwenden darf (Einheiten wie Mi, Gi, M, G). `100Mi` = 100 * 1024 * 1024 Bytes.
> *   `resources.limits.cpu`: Maximale CPU-Leistung (Einheiten wie `m` für Millicores oder ganze Zahlen für volle Kerne). `500m` = 0.5 Kerne.
>
> ##### Step 2: Deploy with `podman play kube`
>
> ```bash
> # Ggf. alten Pod entfernen
> podman pod rm -f limits-test-pod
>
> # Deploy the pod mit den definierten Limits
> podman play kube limits-pod.yaml
> ```
>
> ##### Step 3: Verify Limits
>
> Die Limits werden auf Pod-Ebene (via Cgroups) gesetzt und gelten für alle Container im Pod gemeinsam. Wir können sie indirekt über den Infra-Container des Pods oder über Pod-Statistiken überprüfen.
> ```bash
> # Finden Sie die Infra-Container-ID des Pods
> INFRA_ID=$(podman pod inspect limits-test-pod --format '{{.InfraContainerID}}')
>
> # Inspizieren Sie den Infra-Container, um die HostConfig-Limits zu sehen
> # (Beachten Sie, dass die Werte intern in Bytes und Nanocores umgerechnet werden)
> # Diese Werte gelten für den *gesamten Pod*.
> podman inspect $INFRA_ID --format 'Memory Limit: {{.HostConfig.Memory}}, CPU Limit (NanoCPUs): {{.HostConfig.NanoCpus}}'
> # Erwartete Ausgabe (ungefähre Werte, wenn cgroups v2 funktioniert):
> # Memory Limit: 104857600 (100 * 1024 * 1024 bytes), CPU Limit (NanoCPUs): 500000000 (0.5 * 1e9)
> # Bei cgroups v1 (besonders rootless) können diese Werte 0 sein! Siehe Hinweis unten.
>
> # Beobachten Sie die Pod-Statistiken (zeigt Nutzung im Verhältnis zum Limit)
> podman pod stats limits-test-pod --no-stream
> ```
>
> > **Hinweis zu `podman pod stats` und cgroups v2 (Befehlsfehler):**
> >
> > Wenn Sie Podman im **rootless-Modus** betreiben, benötigt der Befehl `podman pod stats` spezifisch **cgroups v2**, um überhaupt zu funktionieren. Sollte Ihr System noch cgroups v1 verwenden oder cgroups für Ihren Benutzer nicht korrekt konfiguriert sein, erhalten Sie wahrscheinlich die Fehlermeldung:
> > ```nohighlight
> > Error: pod stats is not supported in rootless mode without cgroups v2
> > ```
> > In diesem Fall kann der Befehl selbst nicht ausgeführt werden, unabhängig davon, ob Limits gesetzt wurden.
>
> **Observe:** Die Ausgabe von `podman inspect` sollte die gesetzten Limits (in internen Einheiten) widerspiegeln, *sofern cgroups v2 korrekt funktioniert*. `podman pod stats` (wenn es funktioniert) zeigt die aktuelle Nutzung und die Limits an. Da der Alpine-Container kaum Ressourcen verbraucht, wird die Nutzung sehr niedrig sein.
>
> > #### Hinweis zu cgroups v1 vs. v2 und Ressourcenlimits (Allgemein)
> >
> > Die Effektivität und Zuverlässigkeit von Ressourcenlimits (`memory`, `cpu`), die in der YAML definiert und über `podman play kube` angewendet werden, hängt stark vom **cgroups-Subsystem** des Host-Systems ab.
> > *   **cgroups v2** (Standard auf neueren Linux-Distributionen) bietet generell eine präzisere und zuverlässigere Durchsetzung und Berichterstattung von Limits, insbesondere für **rootless Container**.
> > *   Bei Verwendung von **cgroups v1**, speziell im **rootless-Modus**, kann es vorkommen, dass die in der YAML spezifizierten Limits vom Kernel nicht vollständig oder gar nicht durchgesetzt werden können.
> > *   Zudem kann es sein, dass Befehle wie `podman inspect $INFRA_ID` (für den Infra-Container des Pods) oder `podman pod stats` die Limits **ungenau** oder als **`0`** anzeigen, obwohl sie in der YAML korrekt definiert wurden.
> >
> > Auch wenn die Inspektion `0` anzeigt, hat Podman die Limit-Anforderung aus der YAML erhalten; das Problem liegt dann in der Fähigkeit des zugrundeliegenden cgroup v1-Systems (oder dessen Konfiguration im rootless-Kontext), dieses Limit anzuwenden und/oder korrekt zu melden.
>
> ##### Step 4: Tear Down Deployment
>
> ```bash
> # Verwenden Sie --down mit der YAML-Datei, um den Pod zu entfernen
> podman play kube --down limits-pod.yaml
>
> # Entfernen Sie die erstellte Datei
> rm limits-pod.yaml
> ```
> Das Definieren von Limits in der YAML ist der Kubernetes-konforme Weg, Ressourcen zu verwalten, und wird von `podman play kube` respektiert, wobei die tatsächliche Durchsetzung und Berichterstattung von der Cgroup-Version und -Konfiguration des Systems abhängt.

---

> ##### Exercise 7: Defining Health Probes in YAML
>
> Kubernetes verwendet Liveness-, Readiness- und Startup-Probes, um den Zustand von Containern zu überwachen und automatisch darauf zu reagieren. `podman play kube` unterstützt die Definition dieser Probes in der YAML.
> *   **Liveness Probe:** Prüft, ob der Container noch "lebt" (d.h. funktioniert). Wenn die Probe wiederholt fehlschlägt, startet Podman (wie Kubernetes) den Container neu. Ist primär dafür gedacht, hängende/nicht reagierende Prozesse zu erkennen.
> *   **Readiness Probe:** Prüft, ob der Container bereit ist, Anfragen zu bearbeiten. Wenn die Probe fehlschlägt, würde Kubernetes den Pod aus dem Load Balancing nehmen. Podman führt die Probe aus und meldet den Status (`Ready` Spalte in `podman pod ps`), simuliert aber nicht das Entfernen aus einem Service.
> *   **Startup Probe:** (Optional) Prüft, ob eine Anwendung gestartet ist. Sobald sie erfolgreich ist, übernehmen Liveness/Readiness Probes. Nützlich für langsam startende Anwendungen, um zu verhindern, dass Liveness Probes zu früh fehlschlagen.
>
> ##### Step 1: Create `probes-pod.yaml`
>
> Wir erstellen einen Nginx-Pod mit einfachen HTTP-Probes, die den Nginx-Webserver abfragen:
> ```yaml
> # probes-pod.yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: probes-test-pod
> spec:
>   containers:
>   - name: nginx-with-probes # Name des Containers in der YAML
>     image: docker.io/library/nginx:alpine
>     ports:
>     - containerPort: 80 # Nginx lauscht auf Port 80
>     # Startup Probe (optional, Beispiel)
>     startupProbe:
>       httpGet:
>         path: / # Pfad für die Prüfung
>         port: 80 # Port im Container
>       failureThreshold: 30 # Erlaube 30 Versuche (ca. 5 Min bei periodSeconds 10)
>       periodSeconds: 10 # Prüfe alle 10s
>     livenessProbe:
>       # Prüft alle 15s per HTTP GET auf Pfad '/' an Port 80
>       httpGet:
>         path: / # Pfad für die Gesundheitsprüfung
>         port: 80 # Port im Container
>       initialDelaySeconds: 5 # Warte 5s nach Container-Start (oder nach erfolgreicher StartupProbe) mit der ersten Prüfung
>       periodSeconds: 15 # Wiederhole die Prüfung alle 15s
>       timeoutSeconds: 1 # Warte max 1s auf eine Antwort
>       failureThreshold: 3 # Starte Container neu nach 3 aufeinanderfolgenden Fehlern (bei *laufendem*, aber *nicht reagierendem* Prozess)
>     readinessProbe:
>       # Prüft alle 10s per HTTP GET auf Pfad '/' an Port 80
>       httpGet:
>         path: /
>         port: 80
>       initialDelaySeconds: 5 # Warte 5s nach Start (oder nach erfolgreicher StartupProbe) mit der ersten Prüfung
>       periodSeconds: 10 # Wiederhole alle 10s
>       timeoutSeconds: 1
>       successThreshold: 1 # Gilt als 'Ready' nach 1 erfolgreichen Prüfung
>       failureThreshold: 2 # Gilt als 'Not Ready' nach 2 Fehlern
> ```
>
> ##### Step 2: Deploy with `podman play kube`
>
> Stellen Sie sicher, dass Port 8083 frei ist.
> ```bash
> # Ggf. alten Pod entfernen
> podman pod rm -f probes-test-pod
>
> # Deploy mit Port-Mapping (Host 8083 -> Container 80)
> podman play kube --publish 8083:80 probes-pod.yaml
> ```
>
> ##### Step 3: Observe Pod Status and Events (and Simulate Failure)
>
> Beobachten Sie den Pod-Status. Er sollte nach kurzer Zeit (nach den ersten erfolgreichen Startup/Readiness Probes) als "Running" und "Ready" (z.B. 1/1) angezeigt werden.
> ```bash
> # Zeigt den Pod-Status und die Anzahl der bereiten Container (z.B. 1/1 in der READY Spalte)
> podman pod ps --filter name=probes-test-pod
>
> # Detaillierte Container-Infos (inklusive Neustarts)
> # Beachten Sie den vollständigen Namen: probes-test-pod-nginx-with-probes
> podman ps --pod --filter pod=probes-test-pod
> ```
> Um die Probe-Aktivität und potenzielle Neustarts zu sehen, können Sie die Podman-Events verfolgen (am besten in einem separaten Terminal):
> ```bash
> # Zeigt Events wie 'probe', 'die', 'start' für den Pod an
> podman events --stream --filter pod=probes-test-pod
> ```
> **Simulieren Sie einen Fehler:** Stoppen Sie den Nginx-Prozess im Container manuell (verwenden Sie den **vollständigen Namen**), um zu sehen, wie der Pod reagiert.
> ```bash
> # Finden Sie den vollständigen Namen, falls unsicher
> # podman ps --pod --filter pod=probes-test-pod --format "{{.Names}}"
>
> # Stoppen Sie Nginx im Container (ersetzen Sie den Namen, falls er abweicht)
> podman exec probes-test-pod-nginx-with-probes pkill nginx
> ```
> **Observe (Revised Explanation):**
> Sie werden feststellen, dass der Container (`probes-test-pod-nginx-with-probes`) **sehr schnell neu gestartet wird**, wie Ihre `podman ps` Ausgabe zeigt (Status wechselt kurz zu `starting`, dann wieder zu `healthy`).
> **Warum passiert das so schnell, entgegen der Liveness Probe Konfiguration (`failureThreshold: 3`)?**
> *   Wenn Sie den Hauptprozess des Containers (`nginx`) direkt mit `pkill` beenden, **terminiert der Container selbst**.
> *   Podman (ähnlich wie Kubernetes) hat eine implizite **Neustart-Richtlinie (`restartPolicy`) für Container in Pods**. Der Standard ist oft `Always`.
> *   Diese Richtlinie sorgt dafür, dass Podman den Container **sofort neu startet**, sobald er eine unerwartete Terminierung feststellt (wie durch `pkill`).
> *   Die **Liveness Probe** kommt in diesem spezifischen Szenario (direkte Prozess-Terminierung) gar nicht erst dazu, mehrfach fehlzuschlagen. Ihre Hauptaufgabe ist es, Fälle zu erkennen, in denen der Prozess zwar noch *läuft*, aber *nicht mehr reagiert* (z.B. hängt, Deadlock). In solchen Fällen würde die Probe nach `failureThreshold` Fehlversuchen den Neustart auslösen.
>
> In der `podman events`-Ausgabe sehen Sie wahrscheinlich ein schnelles `die`-Event gefolgt von einem `start`-Event. Der `RESTARTS`-Zähler für den Container in der Ausgabe von `podman ps --pod --filter pod=probes-test-pod` sollte sich dennoch um 1 erhöht haben, was den Neustart bestätigt.
> Dieses Experiment zeigt also eher die Standard-Neustart-Logik von Podman-Pods bei Container-Terminierung als das Verhalten der Liveness Probe bei einem hängenden Prozess.
>
> ##### Step 4: Tear Down Deployment
>
> ```bash
> # Verwenden Sie --down mit der YAML-Datei, um den Pod zu entfernen
> podman play kube --down probes-pod.yaml
>
> # Entfernen Sie die erstellte Datei
> rm probes-pod.yaml
> ```
> Health Probes, die direkt in der YAML definiert werden, sind entscheidend für die automatische Fehlererkennung bei *laufenden, aber nicht reagierenden* Prozessen in Kubernetes und werden von `podman play kube` unterstützt. Bei direkter Prozess-Terminierung greift oft die Container-Neustart-Richtlinie zuerst.

---

> ##### Exercise 8: Using `--network` with `play kube`
>
> Standardmäßig erstellt `podman play kube` Pods im Default-Netzwerk von Podman (meist `podman`). Mit der Option `--network` können Sie einen Pod explizit beim Start in einem spezifischen, bereits existierenden Podman-Netzwerk platzieren.
>
> ##### Step 1: Create a Podman Network
>
> Erstellen Sie ein benutzerdefiniertes Netzwerk, falls noch nicht geschehen.
> ```bash
> # Erstellt das Netzwerk, falls es nicht existiert
> podman network create kube-test-net
> podman network ls
> ```
>
> ##### Step 2: Create `network-pod.yaml`
>
> Wir verwenden eine einfache Alpine-Pod-Definition, die nur einen Container startet und wartet:
> ```yaml
> # network-pod.yaml
> apiVersion: v1
> kind: Pod
> metadata:
>   name: network-test-pod
> spec:
>   containers:
>   - name: net-container # Name des Containers in der YAML
>     image: docker.io/library/alpine:latest
>     command: ["sleep", "infinity"] # Lässt den Container unendlich laufen
> ```
>
> ##### Step 3: Deploy with `podman play kube --network`
>
> Starten Sie den Pod mit der `--network`-Option und geben Sie den Namen des Zielnetzwerks an.
> ```bash
> # Ggf. alten Pod entfernen
> podman pod rm -f network-test-pod
>
> # Deploy den Pod und weise ihn dem Netzwerk 'kube-test-net' zu
> # Hier ist es oft unproblematisch, die YAML-Datei am Ende anzugeben
> podman play kube --network kube-test-net network-pod.yaml
> ```
>
> ##### Step 4: Verify Network Attachment
>
> Inspizieren Sie den Pod, um zu sehen, welchem Netzwerk er zugeordnet ist:
> ```bash
> # Prüft das Netzwerk, dem der Pod zugeordnet ist
> podman pod inspect network-test-pod --format '{{ index .InfraConfig.Networks 0 }}'
> ```
> **Result:** Sollte `"kube-test-net"` ausgeben.
>
> Inspizieren Sie das Netzwerk, um zu sehen, welche Container (insbesondere der Infra-Container des Pods) darin enthalten sind:
> ```bash
> # Zeigt Details des Netzwerks, inklusive der verbundenen Container
> podman network inspect kube-test-net
> ```
> **Observe:** Unter `Containers` sollte der Infra-Container des Pods `network-test-pod` (erkennbar am Namen oder der ID) aufgelistet sein.
>
> ##### Step 5: Tear Down Deployment
>
> ```bash
> # Verwenden Sie --down mit der YAML-Datei, um den Pod zu entfernen
> podman play kube --down network-pod.yaml
>
> # Entfernen Sie die erstellte Datei und das Netzwerk
> rm network-pod.yaml
> podman network rm kube-test-net
> ```
> Die Option `--network` ist nützlich, um Pods, die über `play kube` erstellt wurden, gezielt in dieselbe Netzwerkumgebung wie andere Podman-Container oder -Pods zu integrieren, z.B. für direkte Kommunikation über Container-Namen innerhalb dieses Netzwerks.

---

#### Weitere `podman play kube` Optionen

Zusätzlich zu den in den Übungen gezeigten Optionen gibt es weitere nützliche Flags:

*   `--network <podman_network>`: Verbindet den erstellten Pod mit einem spezifischen, bereits existierenden Podman-Netzwerk. (Siehe Exercise 8)
*   `--publish, -p HOST_PORT:CONTAINER_PORT`: Mappt einen Host-Port auf einen Container-Port im Pod. (Empfohlene Methode für Port-Mapping, siehe Exercises 1, 2, 3, 7)
*   `--replace`: Entfernt einen vorhandenen Pod (und dessen Container) mit demselben Namen, bevor der neue Pod erstellt wird. Nützlich für Updates. (Siehe Exercise 3)
*   `--down`: Stoppt und entfernt die Ressourcen (Pods, Container, Secrets, ConfigMaps etc.), die durch die angegebene YAML-Datei erstellt wurden. (Siehe alle Exercises)
*   `--configmap <configmap_yaml_path>`: **Erwartet den Pfad zu einer YAML-Datei**, die einen `kind: ConfigMap` definiert. Wird **nur** benötigt, wenn ConfigMap und Pod in separaten Dateien definiert sind und der Pod zuerst gestartet werden soll (was meist nicht der Fall ist). Normalerweise wird der ConfigMap durch `podman play kube <cm_yaml>` erstellt. (Siehe Exercise 4).
*   `--log-level=debug`: Erhöht die Ausführlichkeit der Ausgabe, um detailliert zu sehen, was Podman während der Ausführung tut. Hilfreich bei der Fehlersuche.
*   `--service-container=true|false`: (Veraltet) Gibt an, ob ein Service-Container erstellt werden soll. Normalerweise nicht benötigt.
*   `--start`: Steuert, ob der Pod nach dem Erstellen gestartet werden soll (Standard: true).
*   `--build`: Versucht, Container-Images zu bauen, falls ein `Containerfile` oder `Dockerfile` im Kontext (`--context-dir`) gefunden wird, bevor der Pod gestartet wird.
*   `--ip`, `--mac-address`: Ermöglicht das Zuweisen statischer IPs/MACs zum Pod (erfordert oft spezifische Netzwerkkonfiguration).
*   `--userns`: Konfiguriert User-Namespaces.
*   `--authfile`, `--cert-dir`, `--creds`, `--tls-verify`: Optionen zur Authentifizierung bei Container-Registries.

> #### Best Practices: Using `podman play kube`
>
> *   **Deklarative Definition Bevorzugen:** Definieren Sie Ihre Pods und deren Konfiguration primär über Kubernetes YAML-Dateien.
> *   **Version Control:** Speichern Sie Ihre YAML-Dateien in einem Versionskontrollsystem wie Git, um Änderungen nachvollziehen und wiederherstellen zu können.
> *   **`generate kube` als Startpunkt, nicht als Endpunkt:** Nützlich, um eine initiale YAML zu erhalten, aber **generierte YAML immer kritisch prüfen und bereinigen** (Runtime-Felder entfernen, Namen anpassen, Ports/Volumes prüfen, ggf. Ressourcen/Probes hinzufügen), bevor sie für `play kube` verwendet wird.
> *   **YAML Validierung:** Verwenden Sie Tools wie `kubeval`, `kubectl --dry-run=client -o yaml` oder IDE-Plugins (z.B. für VS Code mit Kubernetes-Erweiterung), um Ihre Kubernetes YAML-Syntax auf Korrektheit zu überprüfen, bevor Sie sie mit Podman verwenden.
> *   **Reihenfolge bei Abhängigkeiten:** Wenn ein Pod von einem ConfigMap oder Secret abhängt, das ebenfalls via `podman play kube` erstellt wird, führen Sie `podman play kube` zuerst für die ConfigMap/Secret-YAML und dann für die Pod-YAML aus (siehe Übung 4 & 5).
> *   **Volumes via PVC:** Verwenden Sie `PersistentVolumeClaim` in YAML (`volumes.persistentVolumeClaim.claimName`) und stellen Sie sicher, dass das entsprechende **Podman Volume** mit diesem Namen existiert, *bevor* Sie `play kube` für den Pod ausführen (`podman volume create <claimName>`).
> *   **Secrets (Managed):** Der **konzeptionell bevorzugte** Weg für sensible Daten ist die Verwendung von Podman-verwalteten Secrets (`podman secret create`) und deren Referenzierung via `volumes.secret.secretName` in der Pod-YAML. Dies vermeidet Base64-Kodierung in der YAML. Testen Sie die Zuverlässigkeit in Ihrer Umgebung.
> *   **Port Mapping:** Definieren Sie den `containerPort` in der YAML, aber verwenden Sie die Option `--publish HOST:CONTAINER` bei `podman play kube` anstelle von `hostPort` in der YAML. Dies erhöht die Portabilität und entspricht eher der Kubernetes Service/Ingress-Logik. Verwenden Sie separate `--publish` Flags für jeden Port, den Sie veröffentlichen möchten.
> *   **Ressourcenlimits & Probes:** Definieren Sie Ressourcen (`resources.limits`, `resources.requests`) und Health Probes (`livenessProbe`, `readinessProbe`) in Ihrer YAML für robustere und vorhersagbarere Pods.
> *   **Updates:** Verwenden Sie die Option `--replace` für einfache Updates, aber seien Sie sich bewusst, dass dies den Pod (und damit die Container) neu erstellt, was zu einer kurzen Unterbrechung führt.
> *   **Netzwerke:** Nutzen Sie `--network`, um Pods gezielt in benutzerdefinierte Podman-Netzwerke zu integrieren und die Kommunikation mit anderen Containern zu steuern.
> *   **Lokale Entwicklung & Test:** `podman play kube` ist ideal für lokale Entwicklungs- und Testumgebungen, die Kubernetes ähneln sollen. Es ist jedoch kein Ersatz für einen vollständigen Kubernetes-Cluster (es fehlen Controller wie Deployment/StatefulSet, komplexes Service-Networking, RBAC etc.).
> *   **Infra-Container Verstehen:** Seien Sie sich bewusst, dass jeder Podman-Pod einen automatisch verwalteten Infrastruktur- ("Pause"-) Container enthält, der Netzwerk-Namespaces und Port-Mappings hält.
> *   **Container-Namen in Pods:** Verwenden Sie für Befehle wie `podman logs` oder `podman exec` den vollständigen Container-Namen im Format `<pod_name>-<container_name_in_yaml>`, wie er von `podman ps --pod` angezeigt wird.

### Key Takeaways

*   `podman play kube`: Führt Pods und abhängige Ressourcen (Volumes, ConfigMaps, Secrets etc.) aus Kubernetes YAML-Dateien aus. Erkennt den Ressourcentyp über `kind:`.
*   `podman generate kube`: Erstellt eine Kubernetes YAML-Repräsentation aus laufenden Podman Pods/Containern. Der Output **muss fast immer bereinigt und angepasst werden**, bevor er mit `play kube` sinnvoll wiederverwendet werden kann.
*   Jeder Pod enthält einen **Infra-Container**, der für das Namespace-Sharing verantwortlich ist.
*   Container in Pods werden oft als `<pod_name>-<container_name_in_yaml>` benannt; dieser vollständige Name wird für `logs`/`exec` benötigt.
*   YAML ermöglicht deklaratives, versionierbares Management lokaler Pods, das näher an Kubernetes-Praktiken ist als imperative Befehle oder Docker Compose.
*   Verstehen Sie das Mapping: K8s `Pod` -> Podman Pod, K8s `PVC` -> Podman Volume (`claimName`), K8s `ConfigMap`/`Secret` -> Erstellt durch `podman play kube <resource.yaml>`, referenziert via `name`/`secretName` im Pod.
*   Wichtige Flags für `play kube`: `--publish` (Port-Mapping), `--down`, `--replace`, `--network`. Die Kube-YAML-Datei kommt am Ende. Flags wie `--configmap` sind selten nötig.
*   Der bevorzugte deklarative Ansatz in Podman für die Verwaltung von Pods, insbesondere wenn ein späterer Übergang zu Kubernetes geplant ist oder Kubernetes-Workflows lokal simuliert werden sollen.