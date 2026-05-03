# Plan: `.zsh.local` Blueprint für Secrets in dotfiles

## Ziel
Eine lokale, **nicht versionierte** `~/.zsh.local` soll einmalig aus einem Blueprint erstellt werden und anschließend Secrets sicher laden (wenn verfügbar), inkl. Beispiele für **GPG**, **Bitwarden** und **1Password**.

## Ist-Zustand
- Zentrale Shell-Konfiguration: `packages/common/.zshrc`
- Bereits vorhanden: GPG-basierte Secret-Loads (`gemini.gpg`, `openrouter.gpg`)
- Noch nicht vorhanden:
  - Kein `.zsh.local`-Include in `.zshrc`
  - Kein versionierter Blueprint (`.zsh.local.example`)
  - Keine One-Time-Bootstrap-Logik

## Zielbild
1. `packages/common/.zshrc` sourced `~/.zsh.local` nur, wenn Datei existiert.
2. Ein Blueprint wird versioniert (`packages/common/.zsh.local.example`).
3. Bootstrap erstellt `~/.zsh.local` **einmalig** aus `~/.zsh.local.example` (nur falls nicht vorhanden).
4. Dateirechte für lokale Secret-Datei: `chmod 600 ~/.zsh.local`.
5. Secret-Loader verhalten sich robust (kein Fehler, wenn Tool/Session/Datei fehlt).

## Umsetzungsschritte

### 1) `.zsh.local` in `.zshrc` einbinden
- Datei: `packages/common/.zshrc`
- Ergänzung: bedingtes `source "$HOME/.zsh.local"`
- Platzierung: im Bereich Environment/Secrets (vor Aliasen sinnvoll)

### 2) Blueprint anlegen
- Neue Datei: `packages/common/.zsh.local.example`
- Inhalt:
  - Kommentarhinweise (`chmod 600`, nicht committen von echten Secrets)
  - Helper für defer/fallback (`zsh-defer` optional)
  - Funktionen:
    - `_load_gpg_secret VAR FILE`
    - `_load_bw_secret VAR ITEM [FIELD]`
    - `_load_op_secret VAR OP_REFERENCE`
  - Beispiel-Exports für API Keys

### 3) One-Time-Copy beim Bootstrap
- Datei: `lib.sh` (oder `apply.sh` via Funktionsaufruf)
- Neue Funktion, z. B. `ensure_zsh_local()`:
  - Wenn `~/.zsh.local` fehlt und `~/.zsh.local.example` existiert → kopieren
  - `chmod 600 ~/.zsh.local`
  - Logging via `log_info` / `log_success`
- Aufruf in `apply.sh` nach `apply_dotfiles`

### 4) Tool-spezifische Hinweise im Blueprint
- **GPG**
  - Beispiel: `gpg -q -d ~/.secrets/openai_api_key.gpg`
- **Bitwarden (`bw`)**
  - Voraussetzung: `bw login`, `bw unlock`, `BW_SESSION`
  - Optionaler Hinweis auf `jq` für Custom-Felder
- **1Password (`op`)**
  - Beispielreferenz: `op://Private/OpenRouter/api_key`
  - Voraussetzung: `op signin` / Desktop-Integration

### 5) Sicherheits- und UX-Checks
- Keine Hard-Fails bei fehlenden CLIs oder Sessions
- Keine Ausgabe von Secret-Werten
- Klare Kommentare, wie lokale Datei gepflegt wird

## Akzeptanzkriterien
- `~/.zsh.local` wird beim ersten Bootstrap automatisch erstellt, danach nicht überschrieben.
- Shell startet fehlerfrei, auch wenn `gpg`, `bw`, `op` fehlen.
- Secrets werden gesetzt, sobald Tool + Session + Quelle verfügbar sind.
- Keine Secret-Daten im Repository.

## Optional (später)
- `.gitignore`-Regel ergänzen (falls künftig lokale Dateien im Repo-Root entstehen)
- Validierungsskript (`check-secrets-setup.sh`) für Tool-Verfügbarkeit und Session-Status
- Migration bestehender GPG-Loads aus `.zshrc` vollständig in `.zsh.local`
