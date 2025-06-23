# Podman Lernmaterial

---

## 9 - Using `podman / skopeo`

### 9 - Using `podman / skopeo`

Das Tool **skopeo** läuft als binär Programm und somit daemon-less und im User Kontext (kein root notwendig).
Vorteile: 

*  **gemeinsamer Image Speicher** : buildah, skopeo und podman nutzen den selben lokalen Image-Speicher.
*  **Keine Daemons, rootless**
*  **Formatvielfalt**: Skopeo unterstützt **zahlreiche Speicher- und Registry-Formate** (Docker, OCI, Archive, Directory, etc.) und kann Images zwischen diesen Formaten konvertieren.
*  **Synchronisation**: Skopeo kann komplette Repositories synchronisieren, etwa zur Spiegelung von Images in interne Registries für abgesicherte Netzwerke.
*  **Sicherheit und Compliance**: Durch das Signieren und Verifizieren von Images wird die Integrität und Authentizität der Images sichergestellt.
*  **Effiziente Inspektion und Verwaltung**: Images können in entfernten Registries inspizieren werden, ohne sie zu pullen/downladen. Das erleichtert die Analyse und Qualitätssicherung, vor allem bei großen Images oder limitierten Speicher.



Vorteile:

*   **Deklarativ:** Beschreibung des *gewünschten Zustands*.
*   **Kubernetes-kompatibel:** Standard Kubernetes YAML Syntax.
*   **Reproduzierbar & Versionierbar:** YAML in Git verwalten.
*   **Mächtiger als Compose:** Unterstützt mehr K8s-Konstrukte (Pods, Volumes, ConfigMaps, Secrets).
*   **Ermöglicht Nutzung von `podman generate kube` Output:** `play kube` ist das Werkzeug, um mit `generate kube` erzeugte YAML-Dateien (nach Bereinigung) auszuführen.

`podman play kube` interpretiert die Kubernetes-Objekte in der/den YAML-Datei(en) und erstellt die entsprechenden Podman-Ressourcen (Pods, Container, Volumes, Netzwerkkonfigurationen). Sie können eine einzelne YAML-Datei, mehrere Dateien oder ein ganzes Verzeichnis mit YAML-Dateien übergeben.


### Installation von  skopeo
* Fedora: To install Skopeo on Fedora, run the following dnf command:
```bash
$ sudo dnf -y install skopeo
```
*  Debian, Ubuntu: To install Skopeo on Debian / Ubuntu, run the
following apt-get commands:
```bash
$ sudo apt-get update
$ sudo apt-get -y install skopeo
```
*  RHEL 8/9, CentOS 8 and CentOS Stream 8/9: To install Skopeo on RHEL,
CentOS, and CentOS Stream, run the following dnf command:
```bash
$ sudo dnf -y install skopeo
```

Verifizierung der Installation
```bash
skopeo --version
skopeo version 1.13.3
 # bei Ubuntu 24.02
 # Stand 2025.06: v1.19.0
```

---

> ##### Exercise 1: Remote-Image inspizieren ohne Download
>
> Ziel: Ein öffentliches Container-Image analysieren, ohne es lokal zu speichern.
>
> skopeo inspect docker://docker.io/library/ubuntu:22.04
>
> Ausgabe:
```json
> {
>    "Name": "docker.io/library/ubuntu",
>    "Digest": "sha256:01a3ee0b5e413cefaaffc6abe68c9c37879ae3cced56a8e088b1649e5b269eee",
>    "RepoTags": [
>        "10.04",
> ...
>        "22.04",
>        "22.10",
>        "23.04",
>        "23.10",
> ... 
>     ],
>     "Created": "2025-05-30T22:30:45.500168088Z",
>     "DockerVersion": "24.0.7",
>     "Labels": {
>         "org.opencontainers.image.ref.name": "ubuntu",
>         "org.opencontainers.image.version": "22.04"
>     },
>     "Architecture": "amd64",
>     "Os": "linux",
>     "Layers": [
>         "sha256:89dc6ea4eae2b38a3550534ece4983005a7d2e90e4fa503ed04dcfc58ee71159"
>     ],
>     "LayersData": [
>         {
>             "MIMEType": "application/vnd.oci.image.layer.v1.tar+gzip",
>             "Digest": "sha256:89dc6ea4eae2b38a3550534ece4983005a7d2e90e4fa503ed04dcfc58ee71159",
>             "Size": 29533003,
>             "Annotations": null
>         }
>     ],
>     "Env": [
>         "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
>     ]
> }
```
> Es werden Details aufgelistet wie:
> * Digest (SHA)
> * Architektur
> * Labels
> * Layerstruktur
>

Und mittels Paramter **config** kann man sich die Konfiguraton des Image anschauen (Env, mcmd, History, ...)

```bash
skopeo inspect --config docker://docker.io/ubuntu:22.04
```
```json
{
    "created": "2025-05-30T22:30:45.500168088Z",
    "architecture": "amd64",
    "os": "linux",
    "config": {
        "Env": [
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        ],
        "Cmd": [
            "/bin/bash"
        ],
        "Labels": {
            "org.opencontainers.image.ref.name": "ubuntu",
            "org.opencontainers.image.version": "22.04"
        }
    },
    "rootfs": {
        "type": "layers",
        "diff_ids": [
            "sha256:f862e1968e4b4c3c3af141e37d2ec22b19ec0fd50d6a8aaf683de6729e296226"
        ]
    },
    "history": [
        {
            "created": "2025-05-30T22:30:42.898627637Z",
            "created_by": "/bin/sh -c #(nop)  ARG RELEASE",
            "empty_layer": true
        },
        {
            "created": "2025-05-30T22:30:42.9234878Z",
            "created_by": "/bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH",
            "empty_layer": true
        },
        {
            "created": "2025-05-30T22:30:42.946285582Z",
            "created_by": "/bin/sh -c #(nop)  LABEL org.opencontainers.image.ref.name=ubuntu",
            "empty_layer": true
        },
        {
            "created": "2025-05-30T22:30:42.971145847Z",
            "created_by": "/bin/sh -c #(nop)  LABEL org.opencontainers.image.version=22.04",
            "empty_layer": true
        },
        {
            "created": "2025-05-30T22:30:45.205253722Z",
            "created_by": "/bin/sh -c #(nop) ADD file:82f38ebced7b2756311fb492d3d44cc131b22654e8620baa93883537a3e355aa in / "
        },
        {
            "created": "2025-05-30T22:30:45.500168088Z",
            "created_by": "/bin/sh -c #(nop)  CMD [\"/bin/bash\"]",
            "empty_layer": true
        }
    ]
}
```



---
> ##### Übung 2: Image von Docker Hub in eine Private Registry kopieren


>
> Ziel: Ein ubuntu:22.04-Image in ein internes Repository übertragen.
> ```bash
> skopeo copy \
>   docker://docker.io/library/ubuntu:22.04 \
>   docker://myregistry.example.com/myproject/ubuntu:22.04
> ```
> hat es geklappt ?
> Wenn nein, warum ?
> Wir spielen mit Container .. 
> .. können wir eine Registry zum Laufen bringen (zB "registry:2")?
> 
> Lösung am Ende ...

---

> ##### Übung 3: Ubuntu-Image signieren und signierte Quelle verifizieren

> Ziel: Supply Chain Security – sicherstellen, dass ein Image authentisch ist.

Funktionalität steht bei "Ubuntu 24.04.2 LTS" noch nicht zur Verfügung
* skopeo --version : 1.13.3
* aktuelle Version (Stand Juni 2025) : v1.19.0
```bash
skopeo inspect --verify-signature docker://docker.io/library/ubuntu:22.04
FATA[0000] unknown flag: --verify-signature
```

---
> ##### Übung 4: Repository-Mirroring: Ubuntu-Images lokal synchronisieren

Ziel: Ein ganzes Ubuntu-Image-Repository lokal spiegeln (z. B. für Air-Gapped-Umgebungen)


mkdir -p /tmp/repo/ubuntu 

> ```bash
skopeo sync \
  --src docker \
  --dest dir \
  docker.io/library/ubuntu \
  /tmp/repo/ubuntu
INFO[0000] Tag presence check                            imagename=docker.io/library/ubuntu tagged=false
INFO[0000] Getting tags                                  image=docker.io/library/ubuntu
INFO[0000] Copying image ref 1/674                       from="docker://ubuntu:10.04" to="dir:/tmp/repo/ubuntu/ubuntu:10.04"
Getting image source signatures
Copying blob 86b54f4b6a4e done
Copying blob a3ed95caeb02 done
Copying blob a3ed95caeb02 done
Writing manifest to image destination
INFO[0005] Copying image ref 2/674                       from="docker://ubuntu:12.04" to="dir:/tmp/repo/ubuntu/ubuntu:12.04"
Getting image source signatures
Copying blob 6d93b41cfc6b done   |
Copying blob d8868e50ac4c done   |
Copying blob 83251ac64627 done   |
Copying blob 589bba2f1b36 done   |
Copying blob d62ecaceda39 done   |
Copying config 5b117edd0b done   |
Writing manifest to image destination
INFO[0006] Copying image ref 3/674                       from="docker://ubuntu:12.04.5" to="dir:/tmp/repo/ubuntu/ubuntu:12.04.5"
Getting image source signatures
Copying blob 6d93b41cfc6b done   |
Copying blob d8868e50ac4c done   |
Copying blob 83251ac64627 done   |
Copying blob 589bba2f1b36 done   |
Copying blob d62ecaceda39 done   |
Copying config 5b117edd0b done   |
Writing manifest to image destination
INFO[0008] Copying image ref 4/674                       from="docker://ubuntu:12.10" to="dir:/tmp/repo/ubuntu/ubuntu:12.10"
Getting image source signatures
Copying blob 1a0d911d83d1 done
Copying blob a3ed95caeb02 done
Copying blob b3d68acd1381 done
Copying blob 6b4d7481ec7a done
Copying blob 6256ff031770 done
Writing manifest to image destination
INFO[0011] Copying image ref 5/674                       from="docker://ubuntu:13.04" to="dir:/tmp/repo/ubuntu/ubuntu:13.04"
Getting image source signatures
Copying blob 89d0f0874176 done
Copying blob a3ed95caeb02 done
Copying blob 727520c5e30b done
Copying blob 2e8f7add78f9 done
Copying blob 4600be257a84 done
Writing manifest to image destination
INFO[0015] Copying image ref 6/674                       from="docker://ubuntu:13.10" to="dir:/tmp/repo/ubuntu/ubuntu:13.10"
Getting image source signatures
Copying blob 7db00e6b6e5e done
Copying blob a3ed95caeb02 done
Copying blob 0d8710fc57fd done
Copying blob 5037c5cd623d done
Copying blob 83b53423b49f done
Copying blob e9e8bd3b94ab done
Writing manifest to image destination
INFO[0018] Copying image ref 7/674                       from="docker://ubuntu:14.04" to="dir:/tmp/repo/ubuntu/ubuntu:14.04"
Getting image source signatures
Copying blob 512123a864da done   |
Copying blob 2e6e20c8e2e6 done   |
Copying blob 0551a797c01d done   |
Copying config 13b66b4875 done   |
Writing manifest to image destination
INFO[0020] Copying image ref 8/674                       from="docker://ubuntu:14.04.1" to="dir:/tmp/repo/ubuntu/ubuntu:14.04.1"
^C
# Abbruch mit Ctrl-C  
> ```



---

#### Lösung , falls  Fehler bei Übung 2

```bash
skopeo copy \
  docker://docker.io/library/ubuntu:22.04 \
  docker://myregistry.example.com/myproject/ubuntu:22.04

Getting image source signatures
FATA[0001] copying system image from manifest list: trying to reuse blob sha256:89dc6ea4eae2b38a3550534ece4983005a7d2e90e4fa503ed04dcfc58ee71159 at destination: pinging container registry myregistry.example.com: Get "https://myregistry.example.com/v2/": dial tcp: lookup myregistry.example.com on 127.0.0.53:53: no such host
```

Die Registry **myregistry.example.com** gibt es nicht.

Wir können eine lokale Registry (zB "registry:2") zum Laufen bringen (Port 5000, Standard-Port für registry)
```bash
podman run -d -p 5000:5000 --name registry registry:2
```

und neuer Versuch mit skopeo copy

```bash
skopeo copy   docker://docker.io/library/ubuntu:22.04   docker://localhost:5000/myproject/ubuntu:22.04
Getting image source signatures
FATA[0001] copying system image from manifest list: trying to reuse blob sha256:89dc6ea4eae2b38a3550534ece4983005a7d2e90e4fa503ed04dcfc58ee71159 at destination: pinging container registry localhost:5000: Get "https://localhost:5000/v2/": http: server gave HTTP response to HTTPS client
```

Der Registry Server antwortet per HTTP.
Die Konfiguration ist zu ändern!

```bash
vi /etc/containers/registries.conf
### Zeilen Ergänzen:
# Konfiguration für die lokale, unsichere Registry auf localhost
[[registry]]
location = "localhost:5000"
insecure = true

### und damit diese registry auch durchsucht wird, ist am Ende Zeile zu ergänzen:
unqualified-search-registries = [ 'docker.io', 'quay.io', 'ghcr.io', 'registry.access.redhat.com', 'registry.centos.org' , 'localhost:5000']
```
und neuer copy Versuch

```bash
skopeo copy   docker://docker.io/library/ubuntu:22.04   docker://localhost:5000/myproject/ubuntu:22.04
Getting image source signatures
Copying blob 89dc6ea4eae2 skipped: already exists
Copying config b103ac8bf2 done   |
Writing manifest to image destination

## und Überprüfung mittels Suche
podman search localhost:5000/ubuntu
NAME                             DESCRIPTION
localhost:5000/myproject/ubuntu


## oder die Tags mit skopeo auflisten
 skopeo list-tags docker://localhost:5000/myproject/ubuntu
{
    "Repository": "localhost:5000/myproject/ubuntu",
    "Tags": [
        "22.04",
        "24.04"
    ]
}
```

---

#### Weitere `skopeo` Optionen

Zusätzlich zu den in den Übungen gezeigten Aktionen gibt es weitere :

*  **delete** Images 
* **login** to a registry
```bash
skopeo login -u admin -p p0dman4Dev0ps# --tls-verify=false localhost:500
```


Zusätzlich zu den in den Übungen gezeigten Optionen gibt es weitere nützliche Flags:

*   `--tls-verify=false`: Überprüfe nicht die tls Zertifikate bei lokalen CAs


#### Best Practices: Using `skopeo`

 *  

### Key Takeaways

*   