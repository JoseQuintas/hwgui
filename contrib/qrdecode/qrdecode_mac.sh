#!/bin/bash
#
# Simple script to wait until successful decoded QR code
#
function scan_qr() {
  local result=""
  while true; do
    imagesnap -q -w 1 /tmp/snap.jpg
    result="$(zbarimg -1 --raw -q -Sbinary /tmp/snap.jpg)"
    [[ -n $result ]] && break
    sleep 1
  done
  echo "${result}"
}
scan_qr

# --------------- EOF of qrdecode_mac.sh --------------------