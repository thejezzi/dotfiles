#!/usr/bin/env bash

# Reads a tab-separated manifest and emits data rows only.
# Fields are intentionally opaque here; policy belongs to the caller.
manifest_rows() {
  local manifest="$1"
  awk -F '\t' '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    { print }
  ' "$manifest"
}

# Prints a field from a manifest row selected by its first field.
# field is one-based, including the key column.
manifest_lookup() {
  local manifest="$1"
  local key="$2"
  local field="$3"

  awk -F '\t' -v key="$key" -v field="$field" '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    $1 == key { print $field; exit }
  ' "$manifest"
}
