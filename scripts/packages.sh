#!/usr/bin/env bash
#
# Keeps all Package.resolved files of the repository in sync.
#
# The root Package.resolved is the single source of truth. The workspace and
# the example projects (built by Xcode Cloud) get the same pins.
#
#   scripts/packages.sh update   Update the root pins and propagate them
#   scripts/packages.sh sync     Propagate the current root pins without updating
#   scripts/packages.sh check    Fail if any Package.resolved differs from the root
#
set -euo pipefail

cd "$(dirname "$0")/.."

ROOT_RESOLVED="Package.resolved"
PYTHON="${PYTHON:-/usr/bin/python3}"

# container type, container path, scheme, Package.resolved path
CONTAINERS=(
    "workspace|Snabble.xcworkspace|SwiftySnabble|Snabble.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    "project|Example/SnabbleSampleApp.xcodeproj|SwiftySnabble|Example/SnabbleSampleApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    "project|Example/MinimalScanAndGo.xcodeproj|MinimalScanAndGo|Example/MinimalScanAndGo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
)

# Replaces the pins of $2 with the pins of $1, keeping the rest of $2.
copy_pins() {
    "$PYTHON" -I - "$1" "$2" <<'PY'
import json, sys
source, target = sys.argv[1], sys.argv[2]
with open(source) as f:
    pins = json.load(f)["pins"]
try:
    with open(target) as f:
        resolved = json.load(f)
except FileNotFoundError:
    resolved = {"pins": [], "version": 3}
resolved["pins"] = pins
with open(target, "w") as f:
    json.dump(resolved, f, indent=2, separators=(",", " : "))
    f.write("\n")
PY
}

sync() {
    for entry in "${CONTAINERS[@]}"; do
        IFS='|' read -r type container scheme resolved <<< "$entry"
        echo "==> $container"
        mkdir -p "$(dirname "$resolved")"
        copy_pins "$ROOT_RESOLVED" "$resolved"
        # Lets Xcode confirm the pins and recompute the originHash.
        xcodebuild -resolvePackageDependencies -"$type" "$container" -scheme "$scheme" -quiet
    done
}

check() {
    local files=("$ROOT_RESOLVED")
    for entry in "${CONTAINERS[@]}"; do
        IFS='|' read -r _ _ _ resolved <<< "$entry"
        files+=("$resolved")
    done

    "$PYTHON" -I - "${files[@]}" <<'PY'
import json, sys

def load(path):
    with open(path) as f:
        return {p["identity"]: p["state"] for p in json.load(f)["pins"]}

root_path, *others = sys.argv[1:]
root = load(root_path)
failed = False
for path in others:
    pins = load(path)
    for identity in sorted(root.keys() | pins.keys()):
        expected, actual = root.get(identity), pins.get(identity)
        if expected is None:
            print(f"{path}: unexpected pin '{identity}'")
        elif actual is None:
            print(f"{path}: missing pin '{identity}'")
        elif expected.get("revision") != actual.get("revision"):
            print(f"{path}: '{identity}' is {actual.get('version')}, expected {expected.get('version')}")
        else:
            continue
        failed = True

if failed:
    print("\nPackage.resolved files are out of sync. Run: make packages-sync")
    sys.exit(1)
print(f"All {len(others) + 1} Package.resolved files match ({len(root)} pins).")
PY
}

case "${1:-}" in
    update)
        swift package update
        sync
        check
        ;;
    sync)
        sync
        check
        ;;
    check)
        check
        ;;
    *)
        echo "Usage: $0 update|sync|check" >&2
        exit 64
        ;;
esac
