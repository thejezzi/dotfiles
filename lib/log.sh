#!/usr/bin/env bash

ANSI_RESET=$'\033[0m'
ANSI_RED=$'\033[31m'
ANSI_GREEN=$'\033[32m'
ANSI_YELLOW=$'\033[33m'
ANSI_BLUE=$'\033[34m'

color() {
  local code="$1"
  local msg="$2"
  printf '%b' "${code}${msg}${ANSI_RESET}"
}

log_info() {
  printf '[%s] %s\n' "$(color "${ANSI_BLUE}" "INFO")" "$*"
}

log_success() {
  printf '[%s] %s\n' "$(color "${ANSI_GREEN}" "OK")" "$*"
}

log_warn() {
  printf '[%s] %s\n' "$(color "${ANSI_YELLOW}" "WARN")" "$*"
}

log_error() {
  printf '[%s] %s\n' "$(color "${ANSI_RED}" "ERROR")" "$*" >&2
}

ask() {
  local question="$1"
  local answer
  printf "[%s] %s " "$(color "${ANSI_GREEN}" "?")" "$question"
  read -r -p "[y/N] " answer
  case "${answer,,}" in
    y | yes) return 0 ;;
    *) return 1 ;;
  esac
}
