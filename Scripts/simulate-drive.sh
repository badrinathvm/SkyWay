#!/bin/zsh
# Drives the Bitrig iPhone simulator's location along a route, so Skyway's CarPlay
# Trips tab measures real location updates without leaving your desk.
#
#   Scripts/simulate-drive.sh            drive through Cupertino at 30 mph
#   Scripts/simulate-drive.sh 70         ...at 70 mph
#   Scripts/simulate-drive.sh freeway    Apple's Freeway Drive scenario, on a loop
#   Scripts/simulate-drive.sh stop       stop moving and clear the simulated location
#
# Start a trip in CarPlay first, then run this. Allow location on the iPhone if asked.

set -euo pipefail

device_set="$HOME/Library/Bitrig/Simulators"
device=$(xcrun simctl --set "$device_set" list devices booted \
  | grep -E '^\s+iPhone' | head -1 | grep -oE '[0-9A-F-]{36}' || true)

if [[ -z "$device" ]]; then
  echo "No booted Bitrig iPhone simulator. Open the project's preview in Bitrig first." >&2
  exit 1
fi

location() {
  xcrun simctl --set "$device_set" location "$device" "$@"
}

case "${1:-30}" in
  stop)
    location clear
    echo "Stopped. The simulator no longer has a simulated location."
    ;;
  freeway)
    location run "Freeway Drive"
    echo "Running Freeway Drive. Stop it with: $0 stop"
    ;;
  <->)
    mph=$1
    meters_per_second=$(( mph * 1609.344 / 3600 ))
    # About 7.5 miles from Apple Park through Cupertino and Sunnyvale to Mountain View.
    location start --speed="$meters_per_second" --interval=1 \
      37.3349,-122.0090 37.3230,-122.0322 37.3230,-122.0600 \
      37.3550,-122.0600 37.3860,-122.0830 37.4000,-122.1100
    echo "Driving about 7.5 miles at $mph mph. Stop it with: $0 stop"
    ;;
  *)
    echo "Usage: $0 [mph | freeway | stop]" >&2
    exit 64
    ;;
esac
