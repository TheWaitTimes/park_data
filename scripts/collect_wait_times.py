"""
Pulls live wait time data for the four Walt Disney World theme parks from
themeparks.wiki and appends it to per-park CSV files under data/.

Designed to be run on a schedule (e.g. every 30 minutes) by a GitHub Action,
which then commits the updated CSVs back to the repo.

Each run:
  1. Looks up the WDW parks' entity IDs from themeparks.wiki (no hardcoded
     IDs, so this keeps working even if themeparks.wiki reshuffles them).
  2. For each park, checks today's operating hours and skips it if it's
     currently closed.
  3. Pulls live wait times for every attraction in parks that are open and
     appends a row per attraction to that park's CSV file.
"""

import csv
import os
import sys
from datetime import datetime, timezone

import requests

THEMEPARKS_BASE = "https://api.themeparks.wiki/v1"
DATA_DIR = "data"

# Display name -> substring to match against themeparks.wiki park names.
PARK_NAME_KEYWORDS = {
    "Magic Kingdom": "magic kingdom",
    "EPCOT": "epcot",
    "Disney's Hollywood Studios": "hollywood studios",
    "Disney's Animal Kingdom": "animal kingdom",
}

# Display name -> filename slug. The actual file written each run is
# "data/<slug>_<year>.csv" (e.g. data/magic_kingdom_2026.csv), so a new
# file starts automatically every January 1st (UTC) instead of one file
# growing forever.
PARK_SLUGS = {
    "Magic Kingdom": "magic_kingdom",
    "EPCOT": "epcot",
    "Disney's Hollywood Studios": "hollywood_studios",
    "Disney's Animal Kingdom": "animal_kingdom",
}

FIELDNAMES = [
    "recorded_at",
    "park_id",
    "park_name",
    "attraction_id",
    "attraction_name",
    "status",
    "wait_time_minutes",
    "last_updated",
]


def tp_get(path):
    resp = requests.get(f"{THEMEPARKS_BASE}{path}", timeout=30)
    resp.raise_for_status()
    return resp.json()


def find_wdw_parks():
    """Resolve the four WDW park entity IDs by name, dynamically."""
    destinations = tp_get("/destinations")["destinations"]
    wdw = next(
        d for d in destinations if "walt disney world" in d["name"].lower()
    )
    children = tp_get(f"/entity/{wdw['id']}/children")["children"]
    parks = [c for c in children if c.get("entityType") == "PARK"]

    resolved = {}
    for display_name, keyword in PARK_NAME_KEYWORDS.items():
        match = next((p for p in parks if keyword in p["name"].lower()), None)
        if match:
            resolved[display_name] = match["id"]
        else:
            print(f"WARNING: could not find a park matching '{keyword}'", file=sys.stderr)
    return resolved


def is_open_now(park_id, now):
    """True if `now` (tz-aware UTC) falls within any of today's schedule entries."""
    schedule = tp_get(f"/entity/{park_id}/schedule").get("schedule", [])
    for entry in schedule:
        opening, closing = entry.get("openingTime"), entry.get("closingTime")
        if not opening or not closing:
            continue
        open_dt = datetime.fromisoformat(opening)
        close_dt = datetime.fromisoformat(closing)
        if open_dt <= now <= close_dt:
            return True
    return False


def collect_park_rows(park_name, park_id, now_iso):
    live = tp_get(f"/entity/{park_id}/live").get("liveData", [])
    rows = []
    for item in live:
        if item.get("entityType") != "ATTRACTION":
            continue
        wait = None
        standby = (item.get("queue") or {}).get("STANDBY") or {}
        if isinstance(standby.get("waitTime"), int):
            wait = standby["waitTime"]
        rows.append({
            "recorded_at": now_iso,
            "park_id": park_id,
            "park_name": park_name,
            "attraction_id": item["id"],
            "attraction_name": item.get("name", ""),
            "status": item.get("status"),
            "wait_time_minutes": wait,
            "last_updated": item.get("lastUpdated"),
        })
    return rows


def append_rows(filename, rows):
    if not rows:
        return
    os.makedirs(DATA_DIR, exist_ok=True)
    path = os.path.join(DATA_DIR, filename)
    file_exists = os.path.isfile(path)
    with open(path, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDNAMES)
        if not file_exists:
            writer.writeheader()
        writer.writerows(rows)


def main():
    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()

    parks = find_wdw_parks()
    if not parks:
        print("ERROR: no WDW parks resolved, aborting.", file=sys.stderr)
        sys.exit(1)

    total = 0
    for park_name, park_id in parks.items():
        filename = f"{PARK_SLUGS[park_name]}_{now.year}.csv"
        try:
            if not is_open_now(park_id, now):
                print(f"{park_name}: closed right now, skipping")
                continue
            rows = collect_park_rows(park_name, park_id, now_iso)
            append_rows(filename, rows)
            total += len(rows)
            print(f"{park_name}: appended {len(rows)} rows to data/{filename}")
        except requests.HTTPError as e:
            print(f"ERROR fetching {park_name}: {e}", file=sys.stderr)

    print(f"Done. Appended {total} total rows at {now_iso}")


if __name__ == "__main__":
    main()
