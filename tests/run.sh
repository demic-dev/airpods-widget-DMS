#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Use Qt 6. qmltestrunner/qmllint can also be absolute paths supplied by Nix.
runner="${QMLTESTRUNNER:-qmltestrunner}"
lint="${QMLLINT:-qmllint}"

mapfile -t qml < <(find . -name '*.qml' -not -path './.git/*' -not -path './.claude/*' | sort)
"$lint" --ignore-settings --only-explicit-categories --syntax error "${qml[@]}"
bash -n scripts/librepods-bridge.sh

while IFS= read -r file; do
    lines=$(wc -l < "$file")
    if (( lines > 300 )); then
        echo "$file exceeds the 300-line limit ($lines)" >&2
        exit 1
    fi
done < <(find . -type f \( -name '*.qml' -o -name '*.js' -o -name '*.sh' \) -not -path './.git/*' -not -path './.claude/*')

QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    "$runner" -import "$PWD/tests/imports" -input "$PWD/tests"
