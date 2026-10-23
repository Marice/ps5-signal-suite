#!/usr/bin/env bash
# ps5-signal-suite - Writes payloads.json from the latest release of each suite payload.
# SPDX-License-Identifier: GPL-3.0-or-later
#
# usage: tools/update.sh
#
# Needs gh (logged in) and python3. For each payload it reads the latest GitHub
# release, takes the ELF's SHA-256 from the release's SHA256SUMS, and writes the
# entry pldmgr reads (its CUSTOM_REPOSITORIES.md format). Run it after every
# release of ps5-exporter, ps5-homeassistant or ps5-signal, then commit and push.

set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# repo | file | name | description (in suite order: the exporter first, the others read it)
payloads=(
    "ps5-exporter|ps5-exporter.elf|ps5-exporter|The console's temperatures, power, fan, clocks, CPU load, frame rate and running game as Prometheus metrics on port 9100. ps5-homeassistant reads them."
    "ps5-homeassistant|ps5-homeassistant.elf|ps5-homeassistant|The PS5 as a device in Home Assistant over MQTT: its values from ps5-exporter, live events (trophies, games started and stopped, ShadowMountPlus copies), the status of your payloads, starting a game, a notification on the TV, the light and beeper through ps5-signal, rest mode and power off."
    "ps5-signal|ps5-signal.elf|ps5-signal|Beeps and the console's light for you and for homebrew: a startup tune, colours, patterns, over a small HTTP API on the console."
)

for line in "${payloads[@]}"; do
    IFS='|' read -r repo file name description <<<"$line"
    gh release view -R "Marice/$repo" --json tagName,publishedAt >"$work/$repo.release.json"
    tag=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tagName"])' "$work/$repo.release.json")
    gh release download "$tag" -R "Marice/$repo" -p SHA256SUMS -O "$work/$repo.sums" --clobber
    sum=$(awk -v f="$file" '$2 == f {print $1}' "$work/$repo.sums")
    [[ ${#sum} == 64 ]] || { echo "update.sh: no SHA-256 for $file in $repo $tag" >&2; exit 1; }
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$repo" "$file" "$name" "$tag" "$sum" "$description" >>"$work/rows.tsv"
    printf '%s\n' "$work/$repo.release.json" >>"$work/releases.txt"
done

python3 - "$work/rows.tsv" "$root/payloads.json" <<'PY'
import json, sys
rows = [line.rstrip("\n").split("\t") for line in open(sys.argv[1], encoding="utf-8")]
releases = {}
payloads = []
for repo, file, name, tag, checksum, description in rows:
    published = json.load(open(sys.argv[1].rsplit("/", 1)[0] + f"/{repo}.release.json"))["publishedAt"][:10]
    payloads.append({
        "id": repo,
        "name": name,
        "filename": file,
        "url": f"https://github.com/Marice/{repo}/releases/download/{tag}/{file}",
        "version": tag,
        "last_update": published,
        "description": description,
        "category": "Signal suite",
        "checksum": checksum,
        "author": "Marice",
        "details_url": f"https://raw.githubusercontent.com/Marice/{repo}/main/README.md",
        "source": f"https://github.com/Marice/{repo}",
    })
catalog = {"name": "Signal suite", "payloads": payloads}
with open(sys.argv[2], "w", encoding="utf-8") as out:
    json.dump(catalog, out, indent=2, ensure_ascii=False)
    out.write("\n")
print(f"wrote {sys.argv[2]}: " + ", ".join(p["id"] + " " + p["version"] for p in payloads))
PY
