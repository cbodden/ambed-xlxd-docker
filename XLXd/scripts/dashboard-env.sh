#!/bin/sh
## helpers for the dashboard switches - sourced by customize.sh and the vnstatd run script
## a bad value logs a warning and falls back to the default, so a typo can't break the dashboard

## env_bool <value> <default true|false> <name> : prints true / false
env_bool() {
  case "$(printf '%s' "$1" | tr 'A-Z' 'a-z')" in
    on|true|enable|enabled|yes|1)    echo true ;;
    off|false|disable|disabled|no|0) echo false ;;
    "")                              echo "$2" ;;
    *)
      echo "WARNING : $3='$1' is not on/off - using $2" >&2
      echo "$2" ;;
  esac
}

## env_int <value> <default> <min> <max> <name> : prints a whole number in [min, max]
env_int() {
  case "$1" in
    "")                echo "$2"; return ;;
    *[!0-9]*)          echo "WARNING : $5='$1' is not a whole number - using $2" >&2; echo "$2"; return ;;
  esac
  if [ "$1" -lt "$3" ] || [ "$1" -gt "$4" ]; then
    echo "WARNING : $5='$1' is outside $3-$4 - using $2" >&2
    echo "$2"
    return
  fi
  echo "$1"
}

## env_ipmodus <value> : prints a dashboard IPModus value (hide | last1 | last2 | last3 | full)
env_ipmodus() {
  case "$(printf '%s' "$1" | tr 'A-Z' 'a-z')" in
    ""|hide|hideip)     echo HideIP ;;
    last1)              echo ShowLast1ByteOfIP ;;
    last2)              echo ShowLast2ByteOfIP ;;
    last3)              echo ShowLast3ByteOfIP ;;
    full|showfullip)    echo ShowFullIP ;;
    *)
      echo "WARNING : IP_DISPLAY='$1' is not hide/last1/last2/last3/full - using hide" >&2
      echo HideIP ;;
  esac
}
