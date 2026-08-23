# Plan: Die nächsten 5 Improvements

Stand: Repo enthält 12 versionierte Dateien (`apply.sh`, `lib.sh`, `lib.bats`,
`.markdownlint.json`, `README.md`, 8 Configs unter `packages/`). Stow-basiert, Fedora + macOS.

## Befundübersicht

Konkrete Probleme, die in der Analyse aufgefallen sind:

- Keine CI, kein Linter-Lauf, `lib.bats` ist vollständig auskommentiert.
  `.markdownlint.json` existiert, wird aber von nichts ausgeführt.
- `alias dotsync="$HOME/dotfiles/sync.sh"` zeigt auf eine Datei, die es nicht mehr gibt
  (`sync.sh` wurde in `chore: remove unused files` entfernt).
- `.zshrc` exportiert `PATH="$GOROOT/bin:$PATH"` und `PATH="$GOPATH/bin:$PATH"`, obwohl beide
  Variablen auskommentiert sind → es landet zweimal `/bin` vorne im `PATH`.
- `packages/macos/.config/opencode/opencode.json` ist **byte-identisch** zur Common-Variante.
  Die gesamte `--override`-Sonderbehandlung in `apply_dotfiles()` ist damit ohne Wirkung.
- `kitty.conf` enthält `include current-theme.conf`, diese Datei ist nicht versioniert →
  auf einer frischen Maschine bricht Kitty beim Start. Zusätzlich liegt in `~/.config/kitty`
  ein toter Symlink `kitty.conf.bak` auf eine nicht mehr existierende Repo-Datei.
- `system_install` installiert nur `stow fzf ripgrep`. Die `.zshrc` erwartet aber
  `eza`, `bat`, `fd`, `zoxide`, `starship`, `nvim`, oh-my-zsh + 5 Custom-Plugins und TPM.
  Frisches System ⇒ kaputte Shell (aktuell fehlt z. B. `eza` und die Shell schreibt bei
  **jedem** Start eine Fehlermeldung).
- `is_pkg_installed` nimmt Paketname == Kommandoname an; das gilt für `ripgrep`/`rg` oder
  brew-Formeln nicht zuverlässig.
- `apply_dotfiles()` setzt `WORKDIR` als globale Variable, `migrate_stow_links()` liest sie
  implizit. Der zweite Parameter beim macOS-Aufruf wird stillschweigend ignoriert.
- `lib.sh` enthält noch `say_hello()` als Überrest.
- `compinit` läuft zweimal (oben mit `-C`, danach erneut im mise-Block) → langsamer Start.
- `tmux-sessionizer` hat Shebang `#!/bin/zsh` (auf macOS/brew falscher Pfad) und läuft `find`
  über Pfade wie `$HOME/code/check24`, ohne Existenz zu prüfen.
- `.tmux.conf`: `default-terminal "screen-256color"` ist veraltet und passt nicht zum
  `terminal-features ",xterm-256color:RGB"`. Kommentare sprechen von Prefix `C-i`,
  gesetzt ist `C-z`.
- Kein `.gitignore`, kein `.editorconfig`, keine `LICENSE`.
- Drei verwaiste Remote-Branches (`plan`, `install_bin`, `improovements-mac`). Auf
  `improovements-mac` liegt ungemergte Arbeit (`install_dependencies.sh`, längere README,
  nvim-Submodule, 2459-Zeilen `kitty.conf.bak`). In der History steckt ein doppelter Commit
  (`feat: add install_bin and ensure_in_path utility functions`, 2×).

---

## Improvement 1 — Qualitätsnetz: Lint, Format, Tests, CI

**Warum:** Der einzige Code im Repo ist Bash, der auf `$HOME` schreibt. Genau da ist ein Fehler
am teuersten, und genau da gibt es aktuell null Absicherung. `.markdownlint.json` und `lib.bats`
zeigen, dass das schon geplant war.

**Aufgaben:**

1. `lib.bats` mit echten Tests füllen (reine Funktionen zuerst):
   - `color`, `log_*` → Format/Exit-Code
   - `has_command` → true/false
   - `ensure_in_path` → Rückgabewert für vorhanden/fehlend
   - `install_bin` → Fehlerfälle (leere URL, kein curl/wget) via Stub im `PATH`
   - `migrate_stow_links` → Testfall in `BATS_TMPDIR` mit `HOME`-Override:
     toter Symlink wird entfernt, echte Datei bleibt unangetastet
2. `Makefile` (oder `justfile`) mit Targets `lint`, `fmt`, `test`, `check`.
3. `shellcheck` für `apply.sh` + `lib.sh`, `shfmt -d -i 2 -ci`, `markdownlint` für `*.md`.
4. `.github/workflows/ci.yml`: Matrix `ubuntu-latest` + `macos-latest`, führt `make check` aus
   und zusätzlich einen Smoke-Test `apply.sh --dry-run` gegen ein temporäres `HOME`.
5. Dev-Tools (`shellcheck`, `shfmt`, `bats`) in `system_install` als optionale Gruppe ergänzen.

**Fertig, wenn:** `make check` lokal und in CI grün ist und mindestens `migrate_stow_links`
durch einen Test abgedeckt ist.

---

## Improvement 2 — `apply.sh` härten: `--dry-run`, `--unstow`, echte Idempotenz

**Warum:** Das Skript verlinkt unbesehen in `$HOME` und benutzt `--override='^.*'`. Es gibt keinen
Weg, vorher zu sehen was passiert, und keinen Weg zurück.

**Aufgaben:**

1. Argument-Parsing in `apply.sh`:
   - `--dry-run` → `stow --simulate --verbose`, keine Schreiboperation
   - `--unstow` / `--delete` → Links wieder entfernen
   - `--packages a,b` → Paketauswahl überschreiben
   - `--verbose`, `--help`
2. `apply_dotfiles()` refaktorieren:
   - `WORKDIR` als `local` bzw. als Parameter durchreichen, nicht als implizites Global
   - Paketliste über eine `detect_packages()`-Funktion bestimmen (siehe Improvement 5)
   - ungenutzten zweiten Parameter von `migrate_stow_links` entfernen
   - `--override='^.*'` auf konkrete, notwendige Pfade eingrenzen
3. `system_install` korrigieren: Mapping Kommandoname → Paketname pro Plattform
   (z. B. `rg` ⇒ `ripgrep`), `dnf install -y` bzw. `--assumeyes` nicht-interaktiv machen.
4. Preflight-Check `require_tools()`: prüft `stow`, `git`, `curl` und bricht mit klarer
   Meldung ab, statt später mitten im Lauf zu scheitern.
5. `say_hello()` aus `lib.sh` entfernen.

**Fertig, wenn:** `./apply.sh --dry-run` auf einem sauberen Container ausgeführt werden kann,
nichts verändert, und `./apply.sh --unstow` einen vorherigen Lauf vollständig rückgängig macht.

---

## Improvement 3 — Bootstrap, das eine leere Maschine wirklich fertigstellt

**Status: umgesetzt** (siehe `install_tools`, `ensure_oh_my_zsh`,
`ensure_zsh_plugins`, `ensure_tpm`, `ensure_default_shell` in `lib.sh`;
verifiziert durch `make test-container` mit 48 Assertions). Offen bleiben
optional: `--minimal`/`--full`-Modi und ein `make doctor`-Target.

**Warum:** Aktuell ist „`./apply.sh`, das war's" laut README nur die halbe Wahrheit. Symlinks
werden gelegt, aber oh-my-zsh, die 5 Custom-Plugins, `zsh-defer`, TPM und die im Alias-Block
erwarteten CLIs fehlen. Deshalb steht in der laufenden Shell derzeit auch
`eza is not installed`.

**Aufgaben:**

1. `packages.toml` bzw. Arrays in `lib.sh` als eine Quelle der Wahrheit:
   - Basis: `stow git curl fzf ripgrep`
   - Shell-UX: `eza bat fd zoxide starship`
   - Optional: `lazygit yt-dlp glow jq`
   - Dev: `shellcheck shfmt bats`
2. `ensure_oh_my_zsh()` + `ensure_zsh_plugins()`: klont/aktualisiert idempotent
   `zsh-autosuggestions`, `fast-syntax-highlighting`, `fzf-tab`, `shellfirm`, `zsh-defer`
   nach `$ZSH_CUSTOM/plugins`.
3. `ensure_tpm()`: klont `tmux-plugins/tpm` und führt `install_plugins` headless aus.
4. `apply.sh --minimal` (nur Symlinks) vs. `apply.sh --full` (Symlinks + Tooling), damit
   der schnelle Pfad erhalten bleibt.
5. `.zshrc` defensiv machen: fehlende Tools führen nie zu Ausgaben auf `stderr` beim Start —
   stattdessen ein separates `doctor`-Target (`make doctor`), das fehlende Tools auflistet.

**Fertig, wenn:** Fedora- und macOS-Container von null auf eine Shell ohne Warnungen kommen
und `tmux` mit installierten Plugins startet.

---

## Improvement 4 — Secrets- und Maschinen-Layer über `.zsh.local`

**Warum:** Die versionierte `.zshrc` enthält maschinenspezifische Dinge: die drei
`*.gpg`-Pfade in `$HOME`, `TMUX_SESSIONIZER_PATHS` mit Arbeitgeber-Pfad
(`$HOME/code/check24`), `killforti` (FortiClient), Dresden als Wetter-Ort in `.tmux.conf`.
Das gehört nicht ins öffentliche Repo und blockiert die Nutzung auf einer zweiten Maschine.
Der `plan`-Branch hat dazu bereits einen Entwurf, der nie gemergt wurde.

**Aufgaben:**

1. `packages/common/.zshrc` am Ende: `[[ -f "$HOME/.zsh.local" ]] && source "$HOME/.zsh.local"`.
2. `packages/common/.zsh.local.example` versionieren, mit Loader-Helpern für GPG,
   Bitwarden (`bw`) und 1Password (`op`) — alle failen still, wenn CLI/Session fehlt, und
   geben nie Secret-Werte aus.
3. `ensure_zsh_local()` in `lib.sh`: kopiert das Example einmalig nach `~/.zsh.local`,
   setzt `chmod 600`, überschreibt niemals eine bestehende Datei. Aufruf in `apply.sh`.
4. Maschinenspezifisches aus der versionierten `.zshrc` nach `.zsh.local.example` verschieben:
   `TMUX_SESSIONIZER_PATHS`, `killforti`, die konkreten GPG-Dateinamen.
   In `.tmux.conf` `@dracula-fixed-location` über eine überschreibbare Variable lösen.
5. `.gitignore` + `.gitattributes` anlegen; Guard in CI, der committete Secret-Muster
   (`sk-`, `tvly-`, `ghp_`, private Keys) via `gitleaks` oder simplem `grep`-Job blockt.

**Fertig, wenn:** Die versionierte Config keine persönlichen Pfade/Firmennamen mehr enthält
und `.zsh.local` nach einem `apply.sh` mit Rechten `600` existiert.

---

## Improvement 5 — Paket-Layout aufräumen und Lücken füllen

**Warum:** Die Plattform-Trennung existiert, trägt aber aktuell nichts: Die macOS-Datei ist
identisch zur Common-Datei, ein Linux-/Fedora-Paket fehlt komplett, und wichtige Configs
(Kitty-Theme, git, starship) sind gar nicht versioniert — Kitty startet auf einer frischen
Maschine mit Fehler.

**Aufgaben:**

1. `packages/macos/.config/opencode/opencode.json` entweder löschen (Duplikat) oder mit einem
   echten macOS-Unterschied füllen. Danach `--override`-Logik entsprechend anpassen.
2. `packages/linux/` einführen (Fedora-spezifisch: `xdg-open`-Aliase, Clipboard via `xclip`)
   und `detect_packages()` → `common` + `macos|linux`.
3. Fehlende Configs versionieren:
   - `packages/common/.config/kitty/current-theme.conf` (Include ist sonst kaputt)
   - `packages/common/.gitconfig` bzw. `.config/git/config` (+ `.gitignore_global`)
   - `packages/common/.config/starship.toml` — wird per `starship init` genutzt,
     ist aber nirgends abgelegt
   - optional: nvim-Config als Submodul, wie auf `improovements-mac` angefangen
4. `.tmux.conf` modernisieren: `default-terminal "tmux-256color"`,
   `terminal-features ",*:RGB"`, veraltete `C-i`-Kommentare korrigieren.
5. `tmux-sessionizer`: Shebang auf `#!/usr/bin/env zsh`, nicht existierende Pfade
   herausfiltern, `fzf-tmux`-Fallback auf `fzf` außerhalb von tmux.
6. Repo-Hygiene: `improovements-mac` reviewen und die brauchbaren Teile
   (`install_dependencies.sh`, ausführliche README) nach `main` überführen, dann die drei
   verwaisten Remote-Branches löschen. `.editorconfig` und `LICENSE` ergänzen.
   README um Sektionen „Requirements", „Uninstall", „Per-Machine Overrides" erweitern.

**Fertig, wenn:** Jedes Paket hat einen belegbaren Zweck, Kitty/tmux/zsh starten auf einer
frischen Maschine warnungsfrei, und `main` ist der einzige lebende Branch.

---

## Reihenfolge

Improvement 1 zuerst — danach ist jede weitere Änderung durch CI abgesichert. Dann 2 (macht
Änderungen an der Verlinkung sicher testbar), dann 4 (entfernt Persönliches, bevor mehr
Configs dazukommen), dann 3 und 5 parallel.
