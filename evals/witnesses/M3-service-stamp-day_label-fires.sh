#!/usr/bin/env bash
# M3 fires on service/stamp.py day_label.
cd "$(dirname "$0")/.." || exit 1
command -v python3 >/dev/null 2>&1 || { printf 'python3 not installed\n'; exit 77; }

probe() {
  (cd service && TZ=$1 PYTHONDONTWRITEBYTECODE=1 python3 -c \
    'import stamp; print(stamp.day_label(43200))' 2>&1)
}
west=$(probe Etc/GMT+12)
east=$(probe Etc/GMT-14)
[ -n "$west" ] && [ -n "$east" ] || { printf 'day_label gave no answer\n'; exit 1; }
[ "$west" != "$east" ] || {
  printf 'day_label answered %s under both zones, so the environment does not reach it\n' "$west"
  exit 1; }
grep -qxF 'def day_label(epoch_seconds):' service/stamp.py || {
  printf 'day_label no longer takes the instant alone, so the zone may now be a parameter\n'
  exit 1; }
