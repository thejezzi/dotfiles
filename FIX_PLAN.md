# Fix-Plan: Schichten trennen, `lib.sh` entrümpeln

Korrektur an meiner eigenen Arbeit aus den Commits `9637d52`, `312bd8d`, `64fd192`.
Der Bootstrap funktioniert (48/48 im Container), aber er sitzt an der falschen Stelle.

## Befund

`lib.sh` ist von 218 auf 403 Zeilen gewachsen und vermischt inzwischen vier Dinge:

| Schicht | Beispiele | Zeilen |
| --- | --- | --- |
| Generische Primitive | `color`, `log_*`, `has_command`, `as_root`, `ask` | 1–45, 113–122 |
| OS-/Paketmanager-Abstraktion | `is_macos`, `is_fedora`, `system_install`, `ensure_brew` | 94–192 |
| **Konkrete Daten** | `TOOL_COMMANDS`, `ZSH_PLUGINS`, `pkg_name_for` | 147–162, 194, 303–309 |
| **Konkrete Policy** | `ensure_oh_my_zsh`, `ensure_zsh_plugins`, `ensure_tpm`, `ensure_default_shell` | 227–353 |

Die konkreten Probleme daraus:

1. **Daten stehen als Code in der Library.** Um ein zsh-Plugin hinzuzufügen, muss man
   eine Bash-Array-Literal-Zeile in einer 400-Zeilen-Library editieren. Paketnamen liegen
   als `case`-Zweige in `pkg_name_for` (Zeile 147–162), die Plattform-Unterschiede sind
   damit Code statt Tabelle.
2. **Hardcodierte URLs verstreut über die Library:** `ohmyzsh.git` (297), TPM (344),
   `${repo}.git` (328), Homebrew-Installer (128), `mise.run` (137). Vier verschiedene
   Stellen, kein gemeinsamer Ort.
3. **Mechanismus und Policy vermischt.** `ensure_zsh_plugins` weiß *wie* man ein Repo
   idempotent klont **und** *welche* fünf Plugins es gibt. Das erste ist Library, das
   zweite Konfiguration.
4. **Datenduplikat mit Drift-Risiko.** `TOOL_COMMANDS` (lib.sh:194) und die Toolliste in
   `tests/smoke.sh:70` sind zwei getrennte Wahrheiten. Genauso die fünf Plugin-Namen und
   die tmux-Plugin-Namen (die eigentlich in `.tmux.conf` stehen). Wer eins ändert,
   vergisst das andere — der Test wird dann grün oder rot, ohne dass es was bedeutet.
5. **Waisen ohne Aufrufer.** `install_bin`, `ensure_in_path`, `mise_use` werden von
   nichts im Repo benutzt. Sie waren mal Utility-Sammlung, sind jetzt toter API-Ballast
   in derselben Datei wie der aktive Bootstrap.
6. **`WORKDIR` als implizites Global** (355, gelesen in 372) besteht weiter.
7. **`lib.sh` ist der Name einer Bibliothek**, aber die Datei führt Policy aus.
   `source lib.sh` bedeutet aktuell: „ich bekomme Logging *und* die Meinung, dass
   Dracula-tmux installiert werden soll".

## Zielarchitektur

```text
apply.sh                  # Orchestrierung: sourced lib/, liest manifest/, ruft ensure_* auf
lib/
  log.sh                  # color, log_info/success/warn/error
  os.sh                   # is_macos, is_fedora, as_root, current_login_shell, has_command
  pkg.sh                  # system_install, is_pkg_installed, ensure_brew (nimmt Paketnamen als Argument)
  vcs.sh                  # clone_or_update <url> <dest> [label]  -- generisch, kennt keine URLs
  stow.sh                 # apply_dotfiles, migrate_stow_links
  shell.sh                # ensure_default_shell <shell-path>
  manifest.sh             # Parser: read_manifest <datei> -> Zeilen ohne Kommentare
manifest/
  tools.tsv               # command  fedora-pkg  macos-pkg
  zsh-plugins.tsv         # plugin-name  github-repo
  repos.tsv               # logischer Name  URL   (oh-my-zsh, tpm)
tests/
  smoke.sh                # liest manifest/ statt eigener Listen
  lib.bats                # Unit-Tests für die reinen Funktionen
```

`lib.sh` verschwindet als Sammelbecken. Entweder ersatzlos (apply.sh sourced `lib/*.sh`)
oder es bleibt als **reiner Loader**, der nichts anderes tut als die Module zu sourcen.

### Schichtenregeln (die Leitplanken, damit das nicht wieder passiert)

- `lib/` enthält **keine** URLs, **keine** Paketnamen, **keine** Plugin-Namen.
  Prüfbar per grep-Test in der CI.
- `manifest/` enthält **keine** Logik — nur Tabellen mit Kommentarzeilen.
- Jede `ensure_*`-Funktion bekommt ihre Daten als **Argument**, nicht aus einem Global.
- `apply.sh` ist die einzige Stelle, die Manifest und Library zusammenführt.
- Tests lesen dieselben Manifeste wie der Code. Keine zweite Liste. Nirgends.

### Manifest-Format

```text
# manifest/tools.tsv
# command   fedora        macos
zsh         zsh           zsh
stow        stow          stow
rg          ripgrep       ripgrep
fd          fd-find       fd
```

Damit wird `pkg_name_for` von einer `case`-Kaskade zu einem Tabellen-Lookup, und die
macOS-Spalte ist sichtbar statt in einem `if is_macos` versteckt.

## Migrationsschritte

Jeder Schritt ist ein eigener Commit und muss `make test-container` grün lassen
(aktuell 48 Assertions). Kein Schritt darf Verhalten ändern — das ist reines Refactoring,
abgesichert durch den bestehenden Test.

### Schritt 1 — Daten aus dem Code ziehen

**Status: umgesetzt.**

- `manifest/tools.tsv`, `manifest/zsh-plugins.tsv`, `manifest/repos.tsv` sind angelegt.
- `lib/manifest.sh` mit `manifest_rows()` und `manifest_lookup()` überspringt
  Kommentar- und Leerzeilen.
- `TOOL_COMMANDS`, `ZSH_PLUGINS`, `pkg_name_for` sind aus `lib.sh` entfernt.
- `apply.sh` und `tests/smoke.sh` lesen dieselben Manifeste.
- Verifiziert: Container-Test bleibt 48/48.

### Schritt 2 — Library in Module splitten

**Status: umgesetzt.**

- `lib.sh` ist ein reiner Loader; die Module liegen in `lib/`:
  `log.sh`, `os.sh`, `manifest.sh`, `pkg.sh`, `vcs.sh`, `stow.sh`, `shell.sh`,
  `bin.sh`.
- `apply.sh` sourced die Module über den Loader.
- `DOTFILES_ROOT` wird in `apply.sh` gesetzt und an `apply_dotfiles` sowie
  `migrate_stow_links` übergeben.
- Die Utilities `install_bin`, `ensure_in_path`, `ensure_path` und `mise_use`
  bleiben in `lib/bin.sh` erhalten.
- Verifiziert: Container-Test bleibt 48/48.

### Schritt 3 — Policy von Mechanismus trennen

**Status: umgesetzt.**

- Generisches `clone_or_update <url> <dest> [label]` liegt in `lib/vcs.sh`.
- `ensure_oh_my_zsh`, `ensure_zsh_plugins` und `ensure_tpm` liegen als
  Orchestrierung in `apply.sh` und lesen ihre Daten aus den Manifesten.
- Die `_OMZ_ENSURED`-Krücke ist entfernt.
- `ensure_default_shell` bekommt den Ziel-Shell-Pfad als Argument.
- Verifiziert: Container-Test bleibt 48/48.

### Schritt 4 — Waisen entscheiden

**Status: entschieden und umgesetzt.** Alle Utilities bleiben erhalten und liegen
jetzt isoliert in `lib/bin.sh`:

- `install_bin <url> [name] [dir]`
- `ensure_in_path [dir]`
- `ensure_path [dir]` als kurzer Kompatibilitäts-Alias
- `mise_use <version> <installer-url>`

Die Funktionen enthalten keine konkreten Provider-URLs. Die URL wird vom Aufrufer
übergeben; damit bleibt `lib/bin.sh` wiederverwendbar und frei von Bootstrap-Daten.
Als nächster Testschritt kommen Unit-Tests für diese vier Funktionen in `lib.bats`.

### Schritt 5 — Drift-Guard

**Status: teilweise umgesetzt.**

- `tests/smoke.sh` liest die erwarteten Tools/Plugins aus `manifest/`.
- tmux-Plugins werden aus `packages/common/.tmux.conf` geparst
  (`set -g @plugin '...'`), nicht mehr per Hand aufgelistet.
- Offen: Ein expliziter Architekturtest, der sicherstellt, dass in `lib/` kein
  `github.com`, kein Paketname aus `manifest/tools.tsv` und kein Pluginname steht.
  Die manuelle Prüfung ist aktuell sauber; der automatische Guard folgt mit den
  Unit-Tests.

### Schritt 6 — Unit-Tests für die Primitive

`lib.bats` (aktuell komplett auskommentiert) füllen für die reinen Funktionen, die nach
dem Split sauber testbar sind: `read_manifest`, Paketnamen-Lookup, `log_*`-Format,
`has_command`, `migrate_stow_links` gegen ein temporäres `HOME`.

## Definition of Done

- `lib/` enthält keine URL, keinen Paketnamen, keinen Plugin-Namen (per Test geprüft).
- Ein neues Tool/Plugin hinzuzufügen heißt: **eine Zeile in einer `.tsv`** — kein Code.
- Es gibt keine zweite Liste in den Tests.
- `make test-container` weiter grün (aktuell 49 Assertions),
  `shellcheck lib/*.sh apply.sh` sauber.
- `wc -l` der einzelnen Library-Module: jeweils deutlich unter 100 Zeilen.

## Nicht-Ziele

- Kein Wechsel des Werkzeugs (kein Nix, kein chezmoi) — Stow bleibt.
- Kein `--dry-run`/`--unstow` in diesem Plan (steht als Improvement 2 in `PLAN.md`).
- Keine CI in diesem Plan (Improvement 1). Der Container-Test bleibt vorerst das
  Sicherheitsnetz für die Migration.
