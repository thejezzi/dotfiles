#!/usr/bin/env bash

# Compatibility loader. Keep this file free of bootstrap policy and concrete
# package/plugin/repository data; callers receive reusable mechanisms only.
LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/lib" && pwd)"

for module in \
  log.sh \
  os.sh \
  manifest.sh \
  pkg.sh \
  vcs.sh \
  stow.sh \
  shell.sh \
  bin.sh; do
  # shellcheck source=/dev/null
  source "${LIB_DIR}/${module}"
done
