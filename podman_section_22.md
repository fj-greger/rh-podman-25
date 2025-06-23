# Podman Lernmaterial

---

## 22 - Tipps zu  `podman / skopeo`

### 22 - Tipps zu  `podman / skopeo`



#### registries,conf

* zentral, systemweit : /etc/containers/registries.conf
* User bezogen: $HOME/.config/containers/registries.conf

---

#### Aufräumen von Ressourcen

Auf Servern sollte das Filesystem gemonitored werden.

Auf lokalen Rechnern kann auf die Schnelle ungenutzte Ressourcen frei geräumt werden

 * container
   * alle Pods stoppen und löschen
     * podman stop $(podman ps -qa)
   * auf löschen
     * podman rm $(podman container ls -qa)
     * podman container prune # ungenutzte Container aufräumen
 
 * images
   * podman rmi $(podman images -qa)
   * podman image prune -af

 * volumes
    * podman volume prune

 * network
    * podman network prune

