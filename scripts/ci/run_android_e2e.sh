#!/usr/bin/env bash
# Runs an app's emulator tests. Called by the shared android-e2e.yml (from a second
# checkout of this repository) while the emulator is up; the working directory is the
# app's root.
#
# Configuration, all from the environment:
#   E2E_PACKAGE             required. The app's Android application id.
#   E2E_FILES               required. Space-separated integration_test file names, one
#                           `flutter test` process each (a plugin that may initialise only
#                           once per process would fail on the second file otherwise).
#   E2E_INFORMATIONAL_FILES optional. Run after E2E_FILES in their own calls; the result is
#                           reported, never gating.
#   E2E_LOCAL_STREAM        "true" starts loop_stream.py (the emulator reaches it as
#                           10.0.2.2:8099).
#   E2E_TOOLS_DIR           where loop_stream.py lives; defaults to this script's folder.
#   E2E_DEVICE              adb serial, default emulator-5554.
#   E2E_HOOK_GRACE          seconds to wait for the hook after its test file ends, default 60.
#   E2E_AUDIO_GREP          egrep pattern for the audio-engine evidence lines in logcat.
#
# App hook: if scripts/ci/e2e_hook.sh exists in the app and is executable, it is started
# in the background before each test file as `e2e_hook.sh <file name>`, with OUT, DEVICE,
# PKG and LOGCAT exported, and waited for after the file finishes. Its exit status gates the
# job like a test's, and so does running past E2E_HOOK_GRACE. It may write
# $OUT/summary_extra.md, which is appended to the summary.
#
# Exit codes are captured without pipes, and every file runs before the script reports,
# so one failure does not hide the others. Output goes to e2e-out/ (uploaded by the
# workflow).
set -u

OUT=${OUT:-e2e-out}
DEVICE=${E2E_DEVICE:-emulator-5554}
PKG=${E2E_PACKAGE:?E2E_PACKAGE is required}
FILES=${E2E_FILES:?E2E_FILES is required}
INFORMATIONAL_FILES=${E2E_INFORMATIONAL_FILES:-}
HERE=$(cd "$(dirname "$0")" && pwd)
TOOLS_DIR=${E2E_TOOLS_DIR:-$HERE}
HOOK=scripts/ci/e2e_hook.sh
HOOK_GRACE=${E2E_HOOK_GRACE:-60}
AUDIO_GREP=${E2E_AUDIO_GREP:-soloud|miniaudio|aaudio|opensl|audiotrack|exoplayer}
APK=build/app/outputs/flutter-apk/app-debug.apk

mkdir -p "$OUT"
: > "$OUT/status.txt"
failed=0
stream_pid=""
LOGCAT="$OUT/logcat.txt"
export OUT DEVICE PKG LOGCAT

adb -s "$DEVICE" wait-for-device
for _ in $(seq 1 90); do
  [ "$(adb -s "$DEVICE" shell getprop sys.boot_completed | tr -d '\r')" = "1" ] && break
  sleep 2
done

{
  echo "sdk=$(adb -s "$DEVICE" shell getprop ro.build.version.sdk | tr -d '\r')"
  echo "abi=$(adb -s "$DEVICE" shell getprop ro.product.cpu.abi | tr -d '\r')"
  echo "model=$(adb -s "$DEVICE" shell getprop ro.product.model | tr -d '\r')"
} > "$OUT/device.txt"
adb -s "$DEVICE" shell dumpsys media.audio_flinger > "$OUT/audio_flinger.txt" 2>&1 || true
adb -s "$DEVICE" shell dumpsys audio > "$OUT/dumpsys_audio.txt" 2>&1 || true

adb -s "$DEVICE" logcat -c
adb -s "$DEVICE" logcat -v threadtime > "$LOGCAT" 2>&1 &
logcat_pid=$!

# Install with every runtime permission granted (POST_NOTIFICATIONS on API 33+).
# The later `flutter test` installs replace the package and keep the grants.
s=0
adb -s "$DEVICE" install -g -r "$APK" > "$OUT/install.txt" 2>&1 || s=$?
echo "install -g exit=$s" >> "$OUT/status.txt"
adb -s "$DEVICE" shell dumpsys package "$PKG" > "$OUT/package_before.txt" 2>&1 || true

# `flutter test` reinstalls the app and removes it afterwards, so the grant is
# sampled while the tests run (a record, not a gate).
(
  while true; do
    echo "$(date +%T) $(adb -s "$DEVICE" shell dumpsys package "$PKG" | grep -m1 'POST_NOTIFICATIONS: granted' | tr -d '\r')"
    sleep 4
  done
) > "$OUT/post_notifications_samples.txt" 2>&1 &
sampler_pid=$!

# A local stand-in station on the runner; the emulator reaches it as 10.0.2.2:8099.
# Its request log shows the emulator's `GET /stream`.
if [ "${E2E_LOCAL_STREAM:-false}" = "true" ]; then
  python3 "$TOOLS_DIR/loop_stream.py" --log "$OUT/stream_server.log" > "$OUT/stream_server.out" 2>&1 &
  stream_pid=$!
  for _ in $(seq 1 20); do
    (exec 3<>/dev/tcp/127.0.0.1/8099) 2>/dev/null && break
    sleep 0.5
  done
  echo "stream server pid=$stream_pid" >> "$OUT/status.txt"
fi

# Runs one test file, and the app's hook around it if there is one. Sets file_status
# (the flutter test exit code) and file_hook_status ("" when there was no hook).
run_file() {
  local f=$1 hook_pid="" i
  file_status=0
  file_hook_status=""
  if [ -x "$HOOK" ]; then
    "$HOOK" "$f" > "$OUT/hook_$f.txt" 2>&1 &
    hook_pid=$!
  elif [ -e "$HOOK" ]; then
    echo "$HOOK exists but is not executable, so it was not run" >> "$OUT/status.txt"
    failed=1
  fi
  flutter test "integration_test/$f" -d "$DEVICE" --reporter expanded > "$OUT/$f.txt" 2>&1 || file_status=$?
  cat "$OUT/$f.txt"
  if [ -n "$hook_pid" ]; then
    # The test is over; the hook gets E2E_HOOK_GRACE seconds to finish, then it is killed.
    for i in $(seq 1 "$HOOK_GRACE"); do
      kill -0 "$hook_pid" 2>/dev/null || break
      sleep 1
    done
    if kill -0 "$hook_pid" 2>/dev/null; then
      kill "$hook_pid" 2>/dev/null || true
      wait "$hook_pid" 2>/dev/null || true
      file_hook_status="timeout after ${HOOK_GRACE}s"
    else
      file_hook_status=0
      wait "$hook_pid" || file_hook_status=$?
    fi
    cat "$OUT/hook_$f.txt"
  fi
}

for f in $FILES; do
  run_file "$f"
  echo "$f exit=$file_status" >> "$OUT/status.txt"
  if [ "$file_status" -ne 0 ]; then
    failed=1
  elif ! grep -q 'All tests passed' "$OUT/$f.txt"; then
    # A file that ran no test must not count as green.
    echo "$f: exit 0 but no 'All tests passed' line" >> "$OUT/status.txt"
    failed=1
  fi
  if [ -n "$file_hook_status" ]; then
    echo "$f hook exit=$file_hook_status" >> "$OUT/status.txt"
    [ "$file_hook_status" = "0" ] || failed=1
  fi
done

# Informational files: the result goes to the summary and never fails the job.
: > "$OUT/informational.txt"
for f in $INFORMATIONAL_FILES; do
  s=0
  flutter test "integration_test/$f" -d "$DEVICE" --reporter expanded > "$OUT/$f.txt" 2>&1 || s=$?
  cat "$OUT/$f.txt"
  if [ "$s" -eq 0 ] && grep -q 'All tests passed' "$OUT/$f.txt"; then
    echo "$f: passed (informational, not gating)" >> "$OUT/informational.txt"
  else
    echo "$f: FAILED exit=$s (informational, not gating)" >> "$OUT/informational.txt"
  fi
done

if [ -n "$stream_pid" ]; then
  kill "$stream_pid" 2>/dev/null || true
  wait "$stream_pid" 2>/dev/null || true
  echo '--- stream server log (requests from the emulator) ---'
  cat "$OUT/stream_server.log"
fi

kill "$sampler_pid" 2>/dev/null || true
sleep 3
kill "$logcat_pid" 2>/dev/null || true
wait "$logcat_pid" 2>/dev/null || true

adb -s "$DEVICE" shell dumpsys package "$PKG" > "$OUT/package_after.txt" 2>&1 || true
grep -h 'POST_NOTIFICATIONS' "$OUT/package_before.txt" "$OUT/package_after.txt" > "$OUT/post_notifications.txt" 2>&1 || true

# A crash or ANR of the app fails the run even when every test passed.
grep -E "FATAL EXCEPTION|ANR in $PKG" "$LOGCAT" > "$OUT/crashes.txt" 2>&1
if [ -s "$OUT/crashes.txt" ]; then
  echo "logcat: crash or ANR found (e2e-out/crashes.txt)" >> "$OUT/status.txt"
  failed=1
fi

# Evidence for the emulator audio option: what the audio stack said about itself.
grep -iE "$AUDIO_GREP" "$LOGCAT" | head -150 > "$OUT/audio_lines.txt" 2>&1 || true
grep -h 'E2E_METRIC' "$OUT"/*_test.dart.txt > "$OUT/metrics.txt" 2>&1 || true

{
  echo '```'
  cat "$OUT/device.txt"
  cat "$OUT/status.txt"
  cat "$OUT/informational.txt"
  cat "$OUT/metrics.txt"
  echo '```'
  if [ -f "$OUT/stream_server.log" ]; then
    echo
    echo "stream server log: $(grep -c 'GET /stream' "$OUT/stream_server.log") GET /stream, $(grep -c 'GET /dead' "$OUT/stream_server.log") GET /dead"
  fi
  echo
  echo "audio_lines.txt: $(wc -l < "$OUT/audio_lines.txt") audio lines in logcat"
  head -20 "$OUT/audio_lines.txt"
  if [ -s "$OUT/summary_extra.md" ]; then
    echo
    cat "$OUT/summary_extra.md"
  fi
} > "$OUT/summary.md"

exit "$failed"
