"""MCP server for DanReps workout data (read-only)."""

from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo
from mcp.server.fastmcp import FastMCP
import httpx

API_URL = "https://danreps.vercel.app/api/data"

# Detect system local timezone (full IANA name) for correct date display.
# Abbreviated names like "EST" are fixed-offset and don't handle DST.
def _detect_local_tz() -> ZoneInfo:
    import subprocess as _sp
    try:
        _tz_str = _sp.check_output(["readlink", "/etc/localtime"], text=True).strip()
        return ZoneInfo(_tz_str.split("zoneinfo/")[-1])
    except Exception:
        return ZoneInfo("America/New_York")  # fallback

LOCAL_TZ = _detect_local_tz()

mcp = FastMCP("DanReps Workout Data")

# Per-user cache for the session
_cache: dict[str, dict] = {}


async def _fetch_data(user_name: str) -> dict:
    """Fetch and cache ExerSet JSON for a user."""
    if user_name in _cache:
        return _cache[user_name]
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            API_URL,
            params={"userId": user_name},
            headers={"X-API-Key": user_name},
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()
    _cache[user_name] = data
    return data


SWIFT_EPOCH_OFFSET = 978307200  # seconds between 1970-01-01 and 2001-01-01


def _parse_ts(ts) -> datetime:
    """Parse a timestamp from the JSON. Swift's default date encoding uses
    seconds since 2001-01-01 (reference date), not Unix epoch."""
    if isinstance(ts, (int, float)):
        # Swift deferredToDate: seconds since 2001-01-01
        return datetime.fromtimestamp(ts + SWIFT_EPOCH_OFFSET, tz=timezone.utc)
    s = str(ts)
    # Try common ISO formats
    for fmt in ("%Y-%m-%dT%H:%M:%S.%fZ", "%Y-%m-%dT%H:%M:%SZ",
                "%Y-%m-%dT%H:%M:%S.%f%z", "%Y-%m-%dT%H:%M:%S%z",
                "%Y-%m-%dT%H:%M:%S.%f+00:00", "%Y-%m-%dT%H:%M:%S+00:00"):
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    # Fallback: strip fractional seconds
    try:
        base = s.split(".")[0].split("+")[0].rstrip("Z")
        return datetime.strptime(base, "%Y-%m-%dT%H:%M:%S").replace(tzinfo=timezone.utc)
    except Exception:
        return datetime.min.replace(tzinfo=timezone.utc)


def _to_local(dt: datetime) -> datetime:
    """Convert a UTC datetime to the system's local timezone."""
    return dt.astimezone(LOCAL_TZ)


def _date_only(dt: datetime) -> str:
    """Return YYYY-MM-DD string in local timezone."""
    return _to_local(dt).strftime("%Y-%m-%d")


def _is_duration_item(item: dict) -> bool:
    return item.get("Duration") is True


def _is_duration_set(s: dict) -> bool:
    return s.get("Span") is not None


def _total_weight(s: dict) -> int:
    if _is_duration_set(s):
        return 0
    w = s.get("Weight") or 0
    r = s.get("Reps") or 0
    return w * r


def _e1rm(w: int, r: int) -> int:
    return int(w * (1.0 + r / 30.0))


@mcp.tool()
async def get_exercises(user_name: str) -> str:
    """List all exercises with details (name, groups, perSide, duration type, last set info).

    Args:
        user_name: The DanReps username
    """
    data = await _fetch_data(user_name)
    lines = []
    for item in data.get("ExerItems", []):
        name = item["Name"]
        groups = ", ".join(item.get("Groups") or []) or "none"
        per_side = "yes" if item.get("PerSide") else "no"
        dur = "duration" if _is_duration_item(item) else "weight/reps"
        sets = item.get("Sets") or []

        last_info = "no sets"
        if sets:
            last = sets[-1]
            ts = _parse_ts(last["Timestamp"])
            if _is_duration_set(last):
                span = last.get("Span", 0)
                span_str = f"{span:g}" if isinstance(span, float) else str(span)
                units = last.get("Units", "")
                last_info = f"{span_str} {units} on {_date_only(ts)}"
            else:
                w = last.get("Weight", 0)
                r = last.get("Reps", 0)
                last_info = f"{w}lbs x {r} on {_date_only(ts)}"

        lines.append(
            f"- {name}  |  type: {dur}  |  groups: {groups}  |  "
            f"perSide: {per_side}  |  last: {last_info}  |  total sets: {len(sets)}"
        )
    return "\n".join(lines) if lines else "No exercises found."


@mcp.tool()
async def get_workout_history(user_name: str, exercise_name: str) -> str:
    """Get set history for a specific exercise.

    Args:
        user_name: The DanReps username
        exercise_name: Name of the exercise (case-insensitive)
    """
    data = await _fetch_data(user_name)
    item = None
    for ex in data.get("ExerItems", []):
        if ex["Name"].lower() == exercise_name.lower():
            item = ex
            break
    if item is None:
        names = [ex["Name"] for ex in data.get("ExerItems", [])]
        return f"Exercise '{exercise_name}' not found. Available: {', '.join(names)}"

    sets = item.get("Sets") or []
    if not sets:
        return f"No sets recorded for {item['Name']}."

    is_dur = _is_duration_item(item)
    lines = [f"History for {item['Name']} ({len(sets)} sets):"]
    for s in sorted(sets, key=lambda x: _parse_ts(x["Timestamp"])):
        ts = _parse_ts(s["Timestamp"])
        date_str = _to_local(ts).strftime("%Y-%m-%d %H:%M")
        if _is_duration_set(s):
            span = s.get("Span", 0)
            span_str = f"{span:g}" if isinstance(span, float) else str(span)
            units = s.get("Units", "")
            lines.append(f"  {date_str}  {span_str} {units}")
        else:
            w = s.get("Weight", 0)
            r = s.get("Reps", 0)
            lines.append(f"  {date_str}  {w}lbs x {r}")
    return "\n".join(lines)


@mcp.tool()
async def get_day_summary(user_name: str, date: str) -> str:
    """Get workout summary for a specific date.

    Args:
        user_name: The DanReps username
        date: Date in YYYY-MM-DD format
    """
    data = await _fetch_data(user_name)
    target = date  # YYYY-MM-DD

    exercises_done: list[tuple[str, list[dict], bool]] = []
    for item in data.get("ExerItems", []):
        sets = item.get("Sets") or []
        day_sets = [s for s in sets if _date_only(_parse_ts(s["Timestamp"])) == target]
        if day_sets:
            exercises_done.append((item["Name"], day_sets, item.get("PerSide", False)))

    if not exercises_done:
        return f"No workout recorded on {date}."

    lines = [f"Workout on {date}:"]
    total_sets = 0
    total_vol = 0
    for name, day_sets, per_side in exercises_done:
        multiplier = 2 if per_side else 1
        lines.append(f"\n  {name}:")
        for s in sorted(day_sets, key=lambda x: _parse_ts(x["Timestamp"])):
            ts = _parse_ts(s["Timestamp"])
            time_str = _to_local(ts).strftime("%H:%M")
            if _is_duration_set(s):
                span = s.get("Span", 0)
                span_str = f"{span:g}" if isinstance(span, float) else str(span)
                units = s.get("Units", "")
                lines.append(f"    {time_str}  {span_str} {units}")
            else:
                w = s.get("Weight", 0)
                r = s.get("Reps", 0)
                vol = w * r * multiplier
                total_vol += vol
                lines.append(f"    {time_str}  {w}lbs x {r}" + (f" (x2 sides)" if per_side else ""))
            total_sets += 1

    lines.append(f"\nTotal: {total_sets} sets, {total_vol}lbs volume")
    return "\n".join(lines)


@mcp.tool()
async def get_profile_stats(user_name: str) -> str:
    """Get training stats: frequency, volume by group, estimated 1RMs, recent sessions, progression notes.

    Args:
        user_name: The DanReps username
    """
    data = await _fetch_data(user_name)
    now = datetime.now(tz=timezone.utc)
    four_weeks_ago = now - timedelta(days=28)
    lines: list[str] = []

    # Collect all sets from last 4 weeks grouped by date
    date_sets: dict[str, list[tuple[str, dict, bool]]] = {}  # date_str -> [(name, set, perSide)]
    for item in data.get("ExerItems", []):
        for s in item.get("Sets") or []:
            ts = _parse_ts(s["Timestamp"])
            if ts >= four_weeks_ago:
                d = _date_only(ts)
                date_sets.setdefault(d, []).append((item["Name"], s, item.get("PerSide", False)))

    sorted_dates = sorted(date_sets.keys())
    sessions_per_week = len(sorted_dates) / 4.0 if sorted_dates else 0.0
    lines.append(f"TRAINING FREQUENCY: {len(sorted_dates)} sessions in 4 weeks ({sessions_per_week:.1f}/week)")

    # Volume per group per week
    groups: set[str] = set()
    for item in data.get("ExerItems", []):
        for g in item.get("Groups") or []:
            groups.add(g)
    if groups:
        lines.append("\nVOLUME BY GROUP (sets per week, last 4 weeks):")
        for group in sorted(groups):
            group_items = [it for it in data["ExerItems"] if group in (it.get("Groups") or [])]
            weekly_counts = []
            for week_offset in range(3, -1, -1):
                week_start = now - timedelta(days=(week_offset + 1) * 7)
                week_end = now - timedelta(days=week_offset * 7)
                count = 0
                for it in group_items:
                    for s in it.get("Sets") or []:
                        ts = _parse_ts(s["Timestamp"])
                        if week_start <= ts < week_end:
                            count += 1
                weekly_counts.append(str(count))
            lines.append(f"  {group}: {', '.join(weekly_counts)}")

    # Estimated 1RMs
    lines.append("\nESTIMATED 1RMs:")
    for item in data.get("ExerItems", []):
        if _is_duration_item(item):
            continue
        best_e1rm = 0
        best_set = None
        for s in item.get("Sets") or []:
            w = s.get("Weight") or 0
            r = s.get("Reps") or 0
            if w > 0 and r > 0:
                e = _e1rm(w, r)
                if e > best_e1rm:
                    best_e1rm = e
                    best_set = s
        if best_set:
            bw = best_set.get("Weight", 0)
            br = best_set.get("Reps", 0)
            lines.append(f"  {item['Name']}: {best_e1rm}lbs (from {bw}x{br})")

    # Last 4 sessions
    lines.append("\nLAST 4 SESSIONS:")
    for d in sorted_dates[-4:]:
        day_sets = date_sets[d]
        timestamps = [_parse_ts(s["Timestamp"]) for _, s, _ in day_sets]
        min_t = min(timestamps)
        max_t = max(timestamps)
        duration = int((max_t - min_t).total_seconds() / 60)
        total_vol = 0
        for _, s, per_side in day_sets:
            multiplier = 2 if per_side else 1
            total_vol += _total_weight(s) * multiplier
        exercises = sorted(set(name for name, _, _ in day_sets))
        lines.append(f"  {d}: {len(day_sets)} sets, ~{duration}min, {total_vol}lbs vol")
        lines.append(f"    Exercises: {', '.join(exercises)}")

    # Progression notes
    lines.append("\nPROGRESSION NOTES:")
    for item in data.get("ExerItems", []):
        if _is_duration_item(item):
            continue
        sets = item.get("Sets") or []
        if len(sets) < 2:
            continue
        last = sets[-1]
        w = last.get("Weight") or 0
        r = last.get("Reps") or 0
        if w <= 0 or r <= 0:
            continue
        last_e1rm = _e1rm(w, r)
        all_max = 0
        for s in sets:
            sw = s.get("Weight") or 0
            sr = s.get("Reps") or 0
            if sw > 0 and sr > 0:
                all_max = max(all_max, _e1rm(sw, sr))
        if last_e1rm >= all_max and all_max > 0:
            lines.append(f"  {item['Name']}: PR - {w}x{r} (e1RM: {last_e1rm}lbs)")

    return "\n".join(lines)


@mcp.tool()
async def get_coaching(user_name: str, date: str) -> str:
    """Get cached AI coaching notes for a specific date.

    Args:
        user_name: The DanReps username
        date: Date in YYYY-MM-DD format
    """
    data = await _fetch_data(user_name)
    for day_item in data.get("DayItems") or []:
        ts = _parse_ts(day_item["Date"])
        if _date_only(ts) == date:
            return day_item.get("Coaching", "No coaching text found.")
    return f"No coaching notes found for {date}."


if __name__ == "__main__":
    mcp.run()
