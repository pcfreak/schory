#!/bin/bash

kuota_dir="/etc/klmpk/limit/ssh/kuota"
interval=60

convert_to_bytes() {
  local value="$1"
  case "$value" in
    *GB|*gb) echo $(( ${value%GB} * 1024 * 1024 * 1024 )) ;;
    *MB|*mb) echo $(( ${value%MB} * 1024 * 1024 )) ;;
    *B|*b)   echo $(( ${value%B} )) ;;
    *)       echo "$value" ;; # fallback
  esac
}

format_bytes() {
  local bytes="$1"
  if (( bytes >= 1073741824 )); then
    printf "%.2f GB" "$(bc -l <<< "$bytes/1073741824")"
  elif (( bytes >= 1048576 )); then
    printf "%.2f MB" "$(bc -l <<< "$bytes/1048576")"
  elif (( bytes >= 1024 )); then
    printf "%.2f KB" "$(bc -l <<< "$bytes/1024")"
  else
    echo "$bytes B"
  fi
}

while true; do
  for file in "$kuota_dir"/*; do
    [[ -f "$file" ]] || continue
    user=$(basename "$file")
    kuota_raw=$(cat "$file")
    kuota_byte=$(convert_to_bytes "$kuota_raw")

    # Ambil expired dari /etc/shadow
    exp_days=$(grep -w "^$user" /etc/shadow | cut -d: -f8)
    if [[ -n "$exp_days" ]]; then
      today_days=$(($(date +%s) / 86400))
      if (( today_days > exp_days )); then
        userdel -f "$user"
        rm -f "$file"
        echo "$(date '+%F %T') - $user expired, akun dihapus"
        continue
      fi
    fi

    # Hitung penggunaan
    usage_byte=$(grep -w "$user" /proc/net/dev | awk -F'[: ]+' '{rx+=$2; tx+=$10} END {print rx+tx}')
    usage_byte=${usage_byte:-0}

    if (( usage_byte >= kuota_byte )); then
      pkill -KILL -u "$user"
      echo "$(date '+%F %T') - $user melebihi kuota $(format_bytes "$kuota_byte"), disconnect"
    else
      echo "$(date '+%F %T') - $user: $(format_bytes "$usage_byte") dari $(format_bytes "$kuota_byte")"
    fi
  done
  sleep "$interval"
done
