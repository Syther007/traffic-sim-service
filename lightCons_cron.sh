#!/usr/bin/env bash

set -u

# Service-oriented traffic simulator.
# Runs continuously until stopped by systemd or a signal.

BASE_DIR="${BASE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
LOG_DIR="${LOG_DIR:-${BASE_DIR}/logs}"
STATS_FILE="${STATS_FILE:-${BASE_DIR}/statistics.txt}"
DEBUG_LOG="${DEBUG_LOG:-${LOG_DIR}/debug.log}"
ERROR_LOG="${ERROR_LOG:-${LOG_DIR}/error.log}"
MAX_LOG_SIZE_BYTES="${MAX_LOG_SIZE_BYTES:-20971520}" # 20 MB
DELAY_SECONDS="${DELAY_SECONDS:-${1:-5}}"
REQUEST_TIMEOUT_SECONDS="${REQUEST_TIMEOUT_SECONDS:-5}"
PROXY_ADDR="${PROXY_ADDR:-127.0.0.1:443}"

mkdir -p "${LOG_DIR}"
touch "${DEBUG_LOG}" "${ERROR_LOG}" "${STATS_FILE}"

allThreads=(
  "https://www.asite.com"
  "https://icanhazip.com"
  "https://cats.com"
  "https://cat.com"
  "https://fish.com"
  "https://www.dog.com"
  "https://api.ipify.org"
  "https://puginarug.com/"
  "https://optical.toys/"
  "https://sliding.toys/mystic-square/8-puzzle/daily/"
  "https://clicking.toys/peg-solitaire/english/"
  "https://longdogechallenge.com/"
  "https://weirdorconfusing.com/"
  "https://alwaysjudgeabookbyitscover.com/"
  "https://paint.toys/zen-garden/"
  "https://checkbox.toys/catch/"
  "https://memory.toys/classic/easy/"
  "https://mondrianandme.com/"
  "https://binarypiano.com/"
  "https://patience.toys/"
  "https://onesquareminesweeper.com/"
  "https://maze.toys/mazes/mini/daily/"
  "https://heeeeeeeey.com/"
  "https://cant-not-tweet-this.com/"
  "https://paint.toys/sand/"
  "https://thatsthefinger.com/"
  "https://musical.toys/toys/snapegiator/"
  "https://cursoreffects.com/"
  "https://floatingqrcode.com/"
  "https://ant.toys/"
  "https://toms.toys/"
  "https://thevintageweb.com/"
  "https://smashthewalls.com/"
  "https://drawing.garden/"
  "https://burymewithmymoney.com/"
  "https://xn--gi8h42h.ws/"
  "https://duckstreet.net/"
  "https://paint.toys/symmetry/"
  "https://www.movenowthinklater.com/"
  "https://cruel.toys/maze/"
  "https://jacksonpollock.org/"
  "https://checkboxrace.com/"
  "https://www.everydayim.com/"
  "https://trypap.com/"
  "https://maninthedark.com/"
  "https://www.koalastothemax.com/"
  "https://www.cachemonet.com/"
  "https://randomsitesontheweb.com/sites/comicmoves/"
  "https://en.wikipedia.org/wiki/CNN"
  "https://en.wikipedia.org/wiki/Ngogo_chimpanzee_war"
  "https://en.wikipedia.org/wiki/1978_Georgian_demonstrations"
  "https://en.wikipedia.org/wiki/Land_reclamation_in_Macau"
  "https://en.wikipedia.org/wiki/Microorganism"
  "https://www.ident.me/"
  "https://kubiobuilder.com/"
)

SUC=0
FAL=0
TOL=0
ArrCnt=0
totalDownloaded=0
lastError="none"
lastStatus="starting"
startTimeEpoch=$(date +%s)
isRunning=1
total=$((${#allThreads[@]} - 1))

ts_now() {
  date "+%Y-%m-%d %H:%M:%S"
}

log_debug() {
  printf '%s [DEBUG] %s\n' "$(ts_now)" "$1" >> "${DEBUG_LOG}"
}

log_error() {
  printf '%s [ERROR] %s\n' "$(ts_now)" "$1" >> "${ERROR_LOG}"
}

enforce_log_limit() {
  local file="$1"
  if [[ -f "${file}" ]]; then
    local size
    size=$(wc -c < "${file}" | tr -d ' ')
    if ((size > MAX_LOG_SIZE_BYTES)); then
      mv "${file}" "${file}.1" 2>/dev/null || true
      : > "${file}"
      printf '%s [DEBUG] Log rotated due to size cap (%s bytes)\n' "$(ts_now)" "${MAX_LOG_SIZE_BYTES}" >> "${DEBUG_LOG}"
    fi
  fi
}

write_statistics() {
  local now uptimeSeconds totalDownloadedMB
  now=$(ts_now)
  uptimeSeconds=$(($(date +%s) - startTimeEpoch))
  totalDownloadedMB=$(awk "BEGIN {printf \"%.2f\", ${totalDownloaded}/1024/1024}")

  {
    echo "timestamp=${now}"
    echo "status=${lastStatus}"
    echo "uptime_seconds=${uptimeSeconds}"
    echo "total_requests=${TOL}"
    echo "successful_requests=${SUC}"
    echo "failed_requests=${FAL}"
    echo "total_downloaded_mb=${totalDownloadedMB}"
    echo "current_target_url=${allThreads[$ArrCnt]}"
    echo "delay_seconds=${DELAY_SECONDS}"
    echo "proxy_addr=${PROXY_ADDR}"
    echo "last_error=${lastError}"
  } > "${STATS_FILE}"
}

shutdown() {
  isRunning=0
  lastStatus="stopping"
  log_debug "Received stop signal, shutting down."
  write_statistics
}

trap shutdown INT TERM

log_debug "Traffic simulator service starting."
write_statistics

while ((isRunning)); do
  targetUrl="${allThreads[$ArrCnt]}"
  tempFile=$(mktemp)

  curlOutput=$(curl -x "${PROXY_ADDR}" --max-time "${REQUEST_TIMEOUT_SECONDS}" -sS -w 'http_code=%{http_code}' -o "${tempFile}" "${targetUrl}" 2>&1)
  curlExit=$?

  if ((curlExit == 0)); then
    ((SUC = SUC + 1))
    downloadedSize=$(wc -c < "${tempFile}" | tr -d ' ')
    totalDownloaded=$((totalDownloaded + downloadedSize))
    lastStatus="running"
    lastError="none"
    log_debug "request_success target=${targetUrl} ${curlOutput} bytes=${downloadedSize}"
  else
    ((FAL = FAL + 1))
    lastStatus="running_with_errors"
    lastError="${curlOutput}"
    log_error "request_failed target=${targetUrl} exit=${curlExit} message=${curlOutput}"
  fi

  ((TOL = TOL + 1))
  write_statistics

  rm -f "${tempFile}"

  enforce_log_limit "${DEBUG_LOG}"
  enforce_log_limit "${ERROR_LOG}"

  ((ArrCnt = ArrCnt + 1))
  if ((ArrCnt > total)); then
    ArrCnt=0
  fi

  sleep "${DELAY_SECONDS}"
done

lastStatus="stopped"
log_debug "Traffic simulator service stopped."
write_statistics