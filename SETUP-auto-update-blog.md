# Auto-Update für `llms-full.txt` einrichten — Blog-Variante

Diese Anleitung beschreibt, wie das automatische Regenerieren der `llms-full.txt` für den Blog `how-to-dismantle-a-peakboard-box.com` aufgesetzt wird. Nach dem Setup aktualisiert sich die Datei selbstständig, sobald neue Blogposts veröffentlicht werden.

**Was wird gebraucht:** Push-Zugriff auf das Repository hinter dem Blog (vermutlich ein Jekyll- oder ähnliches Static-Site-Repo) und ein paar Minuten Zeit. Keine zusätzlichen Tools, keine Secrets.

---

## TL;DR

Drei Dateien ins Repo legen, ein Häkchen in den GitHub-Settings setzen, einmal manuell triggern. Fertig.

---

## Voraussetzungen

- Push-Zugriff (oder Collaborator-Status mit Write-Rechten) auf das Repository hinter how-to-dismantle-a-peakboard-box.com
- Die Site liefert eine erreichbare Sitemap unter `https://how-to-dismantle-a-peakboard-box.com/sitemap.xml` (existiert bereits)
- GitHub Actions ist für das Repo aktiviert

---

## Setup in 5 Schritten

### Schritt 1 — Dateien ins Repo legen

Folgende Datei-Struktur im Repo anlegen:

```
<repo-root>/
├── llms.txt                           ← die kompakte Variante
├── llms-full.txt                      ← die vollständige (wird automatisiert)
├── scripts/
│   └── update-llms-txt-blog.py        ← der Generator
└── .github/
    └── workflows/
        └── update-llms-txt-blog.yml   ← der CI-Workflow
```

Konkret:

1. Die Datei `llms.txt` ins Repo-Root kopieren.
2. Die Datei `llms-full.txt` ins Repo-Root kopieren.
3. Den Ordner `scripts/` erstellen und `update-llms-txt-blog.py` dort hineinlegen.
4. Den Ordner `.github/workflows/` erstellen und `update-llms-txt-blog.yml` dort hineinlegen.

### Schritt 2 — Site-Generator-Konfiguration

Falls das Repo Jekyll verwendet (vermutlich, da auch templates.peakboard.com Jekyll nutzt), in `_config.yml` folgenden Eintrag ergänzen, damit die Dateien als statische Files ausgeliefert werden:

```yaml
include:
  - llms.txt
  - llms-full.txt
```

Falls ein anderer Static-Site-Generator verwendet wird (Hugo, Astro, etc.), entsprechend dort sicherstellen, dass `.txt`-Dateien im Root als statische Assets behandelt werden.

### Schritt 3 — Workflow-Berechtigungen prüfen

Der Workflow committet automatisch zurück. Dafür braucht er Schreibrechte:

Im Repo unter **Settings → Actions → General**:

1. Bei *Workflow permissions* die Option **„Read and write permissions"** auswählen
2. Speichern

### Schritt 4 — Posts-Ordner-Pfad im Workflow prüfen

Der Workflow triggert auf Pushes, die `_posts/**` ändern (Jekyll-Standard). Falls der Blog Posts in einem anderen Ordner ablegt (z. B. `content/posts/` bei Hugo, `src/content/blog/` bei Astro), den Pfad in `update-llms-txt-blog.yml` anpassen:

```yaml
on:
  push:
    branches: [main, master]
    paths:
      - '_posts/**'                  ← hier ggf. anpassen
      - 'scripts/update-llms-txt-blog.py'
```

Der wöchentliche Schedule und der manuelle Trigger funktionieren unabhängig davon — selbst wenn der Push-Trigger den falschen Pfad hat, läuft das Update spätestens am Montag.

### Schritt 5 — Alles committen, pushen, Workflow triggern

```bash
git add llms.txt llms-full.txt scripts/update-llms-txt-blog.py .github/workflows/update-llms-txt-blog.yml _config.yml
git commit -m "feat: add llms.txt and auto-update for llms-full.txt"
git push
```

Dann im Repo unter **Actions → Update llms-full.txt from sitemap → Run workflow** den Workflow einmal von Hand starten, um zu prüfen, dass alles läuft.

---

## Verifikation

Nach dem Deploy diese drei Dinge prüfen:

**1. Beide Dateien sind öffentlich erreichbar:**

```bash
curl -I https://how-to-dismantle-a-peakboard-box.com/llms.txt
curl -I https://how-to-dismantle-a-peakboard-box.com/llms-full.txt
```

Erwartet: `HTTP/2 200` und `content-type: text/plain`.

**2. Der Workflow ist erfolgreich gelaufen:** im Actions-Tab sollte der erste manuelle Run einen grünen Haken haben.

**3. Bei einem Test-Post triggert der Workflow:** einen kleinen Test-Post im `_posts/`-Ordner anlegen, pushen, und prüfen ob der Workflow im Actions-Tab automatisch startet. (Den Test-Post danach wieder löschen.)

---

## Wartung im Alltag

**Was läuft automatisch:**

- Jeden Montag früh (04:00 UTC) wird die Sitemap geprüft und `llms-full.txt` regeneriert
- Bei jedem Push, der `_posts/` ändert, läuft der Workflow ebenfalls
- Wenn sich der Inhalt nicht geändert hat, wird kein Commit erstellt

**Was du manuell machst, wenn nötig:**

- **Disclaimer, Themenübersicht, Learning Paths, LLM-Hinweise ändern:** in `llms.txt` editieren. Wenn die Änderung auch in `llms-full.txt` stehen soll, dort ebenfalls editieren — aber **außerhalb** der `<!-- AUTOGEN:START -->` / `<!-- AUTOGEN:END -->`-Marker. Alles innerhalb der Marker wird beim nächsten Workflow-Lauf überschrieben.
- **Workflow von Hand triggern:** Actions → Update llms-full.txt from sitemap → Run workflow.

**Wann muss `llms.txt` (kurze Version) angepasst werden?**

Die kurze Version enthält statische Inhalte, die sich nur selten ändern:
- Recurring series (wenn eine neue mehrteilige Reihe gestartet wird)
- Categories und Collections (nur wenn neue auf der Site eingeführt werden)
- Disclaimer und LLM-Hinweise (nur bei grundlegenden Änderungen)

Bei normalem Posting-Rhythmus muss die kurze Version vielleicht alle paar Monate mal angefasst werden — die lange aktualisiert sich automatisch.

---

## Lokal testen vor dem Push

```bash
# Im Repo-Root
python3 scripts/update-llms-txt-blog.py --dry-run
```

Erwartete Ausgabe:

```
Fetching https://how-to-dismantle-a-peakboard-box.com/sitemap.xml ...
Parsing URLs ...
  Blog posts: 149
  Newest: 2026-05-04 — Advanced-OPC-UA-Orchestrating-and-Processing-Complex-Nodes
  Oldest: 2022-12-15 — How-to-make-the-SAP-system-fit-for-report-execution

--- DRY RUN: would write the following changes ---
...
```

Wenn die Zahlen plausibel sind, ohne `--dry-run` echt ausführen.

---

## Troubleshooting

**„Marker not found"-Fehler im Workflow:**
Das Script sucht in `llms-full.txt` nach exakt diesen Zeilen:
```
<!-- AUTOGEN:START — content between the AUTOGEN markers is regenerated from sitemap.xml; do not edit by hand -->
<!-- AUTOGEN:END -->
```
Wenn die Marker beim manuellen Editieren versehentlich gelöscht wurden, das Script bricht ab. Marker exakt wiederherstellen.

**Workflow läuft, aber kein Commit:**
Das ist normal, wenn die Sitemap keine neuen Einträge hat. Im Log steht „No changes to llms-full.txt — sitemap and snapshot are in sync."

**Push schlägt fehl mit „permission denied":**
Settings → Actions → General → Workflow permissions auf „Read and write permissions" stellen.

**Sitemap liefert weniger Posts als erwartet:**
Wenn ein neu veröffentlichter Post noch nicht in der Sitemap erscheint, einen Re-Build der Site triggern oder kurz warten. Bei Jekyll wird die Sitemap beim Build neu generiert.

**Posts werden falsch erkannt:**
Der Filter im Script geht davon aus, dass Blog-Posts unter dem Schema `https://how-to-dismantle-a-peakboard-box.com/<slug>.html` liegen — also direkt im Root, nicht in einem Unterordner. Falls der Blog seine URL-Struktur ändert (z. B. zu `/posts/<slug>.html`), muss die `parse_posts`-Funktion im Script angepasst werden. Konkret: in `update-llms-txt-blog.py` die Zeile `if path.count("/") != 1:` und ggf. `SKIP_PREFIXES` aktualisieren.

**Eine `category/`-Seite oder `learning/`-Seite landet in der Liste:**
Sollte durch `SKIP_PREFIXES` ausgeschlossen sein. Falls neue Meta-Pfade dazukommen (z. B. `/tags/`), die Liste in der Script-Konstante `SKIP_PREFIXES` ergänzen.

---

## Was passiert, wenn das Auto-Update mal ausfällt?

Kein Drama. Die `llms-full.txt` enthält ein Datum in der Snapshot-Überschrift („as of YYYY-MM-DD") und einen expliziten Hinweis darauf, dass die Sitemap die kanonische Quelle ist. Selbst wenn die Datei mehrere Wochen veraltet ist, finden LLMs über den Sitemap-Verweis trotzdem die aktuellen Posts.

Im schlimmsten Fall: einmal manuell triggern (Actions → Run workflow) — das holt den Stand wieder ein.
