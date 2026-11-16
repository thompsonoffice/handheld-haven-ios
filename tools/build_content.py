#!/usr/bin/env python3
"""Parse content/Handheld-Haven plain text into bundled JSON.

The parser copies strings from the source files. It does not add devices,
prices, or specifications. Chapter order, entry order, labels, and wording
stay as written.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content" / "Handheld-Haven"
OUT = ROOT / "HandheldHaven" / "Resources" / "haven-data.json"

DEVICE_FILES = [
    "10-gpd-win-series.txt",
    "11-gpd-pocket-micropc-duo.txt",
    "12-asus-rog-ally.txt",
    "13-lenovo-legion.txt",
    "14-msi-claw.txt",
    "15-ayaneo.txt",
    "16-onexplayer.txt",
    "17-other-handhelds-and-steam-deck.txt",
    "18-microsoft-surface.txt",
    "19-dell-venue-and-small-windows-tablets.txt",
    "20-umpcs-and-origami.txt",
]

GUIDE_FILES = [
    ("readme", "00-README.txt"),
    ("index", "01-INDEX.txt"),
    ("history", "02-history-and-eras.txt"),
    ("buyers-guide", "03-blind-buyers-guide.txt"),
    ("screen-reader", "04-screen-reader-setup.txt"),
]

STANDARD_SECTIONS = [
    "WHAT IT CAN DO",
    "HARDWARE",
    "CONTROLS AND BUTTON LAYOUT",
    "HOW IT FEELS",
    "BLIND USABILITY",
    "GAME COMPATIBILITY",
    "UNCERTAIN",
    "SOURCES",
]

HEADER_LABELS = ("Also known as", "Maker", "Released", "Launch price")


def read_text(name: str) -> str:
    path = CONTENT / name
    data = path.read_bytes()
    if b"\x00" in data:
        raise SystemExit(f"{name} is not plain text")
    return data.decode("utf-8")


def is_rule(line: str) -> bool:
    s = line.strip()
    return len(s) >= 5 and set(s) <= {"-"}


def is_end_marker(line: str) -> bool:
    return line.strip().upper().startswith("END OF ")


def letters(line: str) -> str:
    return "".join(ch for ch in line if ch.isalpha())


def is_heading(line: str) -> bool:
    s = line.strip()
    if not s or s.startswith("http://") or s.startswith("https://"):
        return False
    if s.startswith("ENTRY:") or s.startswith("THIN ENTRY"):
        return False
    found = letters(s)
    if len(found) < 3:
        return False
    return found.isupper()


def slug(text: str) -> str:
    lowered = text.lower()
    lowered = lowered.replace("&", " and ")
    cleaned = re.sub(r"[^a-z0-9]+", "-", lowered).strip("-")
    return cleaned or "entry"


def unique_slug(text: str, used: set[str]) -> str:
    base = slug(text)
    candidate = base
    n = 2
    while candidate in used:
        candidate = f"{base}-{n}"
        n += 1
    used.add(candidate)
    return candidate


def split_label(line: str) -> tuple[str, str] | None:
    if ":" not in line:
        return None
    label, value = line.split(":", 1)
    label = label.strip()
    value = value.strip()
    if not label:
        return None
    return label, value


def parse_guide(guide_id: str, filename: str) -> dict:
    raw = read_text(filename)
    lines = raw.splitlines()
    # Drop a trailing end marker if one is ever added; guides do not use ENTRY.
    body_lines = [ln.rstrip() for ln in lines if not is_end_marker(ln)]
    if not body_lines or not body_lines[0].strip():
        raise SystemExit(f"{filename} has no title")
    title = body_lines[0].strip()
    rest = body_lines[1:]
    intro_lines: list[str] = []
    sections: list[dict] = []
    current_heading: str | None = None
    current_body: list[str] = []

    def flush() -> None:
        nonlocal current_heading, current_body
        if current_heading is None:
            return
        body = "\n".join(current_body).strip()
        sections.append({"heading": current_heading, "body": body})
        current_heading = None
        current_body = []

    for line in rest:
        if is_rule(line):
            continue
        if is_heading(line):
            flush()
            current_heading = line.strip()
            continue
        if current_heading is None:
            intro_lines.append(line)
        else:
            current_body.append(line)
    flush()
    return {
        "id": guide_id,
        "title": title,
        "fileName": filename,
        "intro": "\n".join(intro_lines).strip(),
        "sections": sections,
    }


def parse_glossary(filename: str = "05-glossary.txt") -> dict:
    raw = read_text(filename)
    lines = [ln.rstrip() for ln in raw.splitlines()]
    if not lines or lines[0].strip() != "GLOSSARY":
        raise SystemExit("glossary file does not start with GLOSSARY")
    intro: list[str] = []
    terms = []
    used: set[str] = set()
    started = False
    for line in lines[1:]:
        if not line.strip():
            if not started:
                intro.append(line)
            continue
        stripped = line.strip()
        parts = split_label(stripped)
        is_term = parts is not None and re.match(r"^[^:]{1,80}:\s+\S", stripped) is not None
        if not is_term:
            if started:
                raise SystemExit(f"glossary line is not a term: {line!r}")
            intro.append(line)
            continue
        started = True
        term, definition = parts
        terms.append(
            {
                "id": unique_slug(term, used),
                "term": term,
                "definition": definition,
            }
        )
    return {"intro": "\n".join(intro).strip(), "terms": terms}


def parse_sources(filename: str = "06-sources.txt") -> dict:
    raw = read_text(filename)
    lines = [ln.rstrip() for ln in raw.splitlines()]
    if not lines or lines[0].strip() != "SOURCES":
        raise SystemExit("sources file does not start with SOURCES")
    intro: list[str] = []
    groups: list[dict] = []
    current_title: str | None = None
    current_urls: list[str] = []

    def flush() -> None:
        nonlocal current_title, current_urls
        if current_title is None:
            return
        groups.append(
            {
                "id": slug(current_title),
                "title": current_title,
                "urls": current_urls,
            }
        )
        current_title = None
        current_urls = []

    for line in lines[1:]:
        if not line.strip() or is_rule(line):
            if current_title is None:
                intro.append(line)
            continue
        if is_heading(line) and not line.strip().startswith("http"):
            flush()
            current_title = line.strip()
            continue
        text = line.strip()
        if current_title is None:
            intro.append(line)
            continue
        if not (text.startswith("http://") or text.startswith("https://")):
            raise SystemExit(f"source line is not a URL: {text!r}")
        current_urls.append(text)
    flush()
    return {"intro": "\n".join(intro).strip(), "groups": groups}


def parse_device_block(block: str, chapter_id: str, filename: str, used_ids: set[str]) -> dict:
    lines = [ln.rstrip() for ln in block.splitlines() if not is_rule(ln)]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    if not lines or not lines[0].startswith("ENTRY:"):
        raise SystemExit(f"device block in {filename} does not start with ENTRY:")
    name = lines[0].split(":", 1)[1].strip()
    if not name:
        raise SystemExit(f"empty ENTRY name in {filename}")

    header: dict[str, str] = {}
    extra_header: list[dict[str, str]] = []
    idx = 1
    while idx < len(lines) and not is_heading(lines[idx]):
        line = lines[idx].strip()
        idx += 1
        if not line:
            continue
        parts = split_label(line)
        if parts is None:
            raise SystemExit(f"{filename} {name}: header line has no label: {line!r}")
        label, value = parts
        if label in HEADER_LABELS and label not in header:
            header[label] = value
        elif label in header:
            header[label] = header[label] + "\n" + value
        else:
            extra_header.append({"label": label, "value": value})

    sections: dict[str, list[str]] = {}
    order: list[str] = []
    current: str | None = None
    for line in lines[idx:]:
        if is_end_marker(line):
            continue
        if is_heading(line):
            current = line.strip()
            if current not in sections:
                sections[current] = []
                order.append(current)
            continue
        if current is None:
            if line.strip():
                raise SystemExit(f"{filename} {name}: text before any section: {line!r}")
            continue
        sections[current].append(line)

    def section_text(title: str) -> str:
        return "\n".join(sections.get(title, [])).strip()

    missing = [title for title in STANDARD_SECTIONS if title not in sections]
    if missing:
        raise SystemExit(f"{filename} {name}: missing sections {missing}")

    hardware: list[dict[str, str]] = []
    pending: dict[str, str] | None = None
    for raw_line in sections["HARDWARE"]:
        line = raw_line.strip()
        if not line:
            continue
        parts = split_label(line)
        if parts is None:
            if pending is None:
                hardware.append({"label": "", "value": line})
            else:
                pending["value"] = (pending["value"] + " " + line).strip()
            continue
        pending = {"label": parts[0], "value": parts[1]}
        hardware.append(pending)

    source_lines = []
    for raw_line in sections["SOURCES"]:
        line = raw_line.strip()
        if not line:
            continue
        if not (line.startswith("http://") or line.startswith("https://")):
            raise SystemExit(f"{filename} {name}: source is not a URL: {line!r}")
        source_lines.append(line)

    extra_sections = []
    for title in order:
        if title in STANDARD_SECTIONS:
            continue
        extra_sections.append({"heading": title, "body": section_text(title)})
    if extra_sections:
        raise SystemExit(f"{filename} {name}: unexpected sections {[s['heading'] for s in extra_sections]}")

    full_text = "\n".join(lines)
    uncertain = section_text("UNCERTAIN")
    if "THIN ENTRY" in full_text and "THIN ENTRY" not in uncertain:
        raise SystemExit(f"{filename} {name}: THIN ENTRY was separated from UNCERTAIN")
    return {
        "id": unique_slug(name, used_ids),
        "name": name,
        "chapterID": chapter_id,
        "fileName": filename,
        "alsoKnownAs": header.get("Also known as", ""),
        "maker": header.get("Maker", ""),
        "released": header.get("Released", ""),
        "launchPrice": header.get("Launch price", ""),
        "extraHeader": extra_header,
        "thin": "THIN ENTRY" in full_text,
        "overview": section_text("WHAT IT CAN DO"),
        "hardware": hardware,
        "controls": section_text("CONTROLS AND BUTTON LAYOUT"),
        "howItFeels": section_text("HOW IT FEELS"),
        "blindUsability": section_text("BLIND USABILITY"),
        "gameCompatibility": section_text("GAME COMPATIBILITY"),
        "uncertain": uncertain,
        "sources": source_lines,
        "extraSections": extra_sections,
    }


def parse_chapter(filename: str, used_ids: set[str]) -> tuple[dict, list[dict]]:
    raw = read_text(filename)
    lines = raw.splitlines()
    if not lines or not lines[0].strip():
        raise SystemExit(f"{filename} has no title")
    title = lines[0].strip()
    chapter_id = slug(filename.split("-", 1)[1].rsplit(".", 1)[0] if filename[0].isdigit() else title)
    text = "\n".join(lines)
    parts = re.split(r"(?=^ENTRY:)", text, flags=re.M)
    intro = parts[0]
    intro_lines = [ln.rstrip() for ln in intro.splitlines() if not is_end_marker(ln) and not is_rule(ln)]
    # First line is the title; keep the rest as the chapter introduction.
    intro_body = "\n".join(intro_lines[1:]).strip()
    devices = []
    for part in parts[1:]:
        if not part.strip():
            continue
        # Stop if the file ends with a marker glued on after the last entry.
        devices.append(parse_device_block(part, chapter_id, filename, used_ids))
    match = re.search(r"This file has (\d+) entries:", intro_body)
    if not match:
        raise SystemExit(f"{filename} does not say how many entries it has")
    expected = int(match.group(1))
    if expected != len(devices):
        raise SystemExit(f"{filename} says {expected} entries but parsed {len(devices)}")
    chapter = {
        "id": chapter_id,
        "title": title,
        "fileName": filename,
        "intro": intro_body,
        "deviceIDs": [device["id"] for device in devices],
    }
    return chapter, devices


def entry_names(filename: str) -> list[str]:
    names = []
    for line in read_text(filename).splitlines():
        if line.startswith("ENTRY:"):
            names.append(line.split(":", 1)[1].strip())
    return names


def build() -> dict:
    used: set[str] = set()
    chapters = []
    devices = []
    for filename in DEVICE_FILES:
        chapter, found = parse_chapter(filename, used)
        chapters.append(chapter)
        devices.extend(found)

    complete_names = entry_names("Handheld-Haven-complete.txt")
    parsed_names = [device["name"] for device in devices]
    if complete_names != parsed_names:
        raise SystemExit("complete file ENTRY list does not match the chapter files")

    guides = [parse_guide(guide_id, filename) for guide_id, filename in GUIDE_FILES]
    glossary_doc = parse_glossary()
    glossary = glossary_doc["terms"]
    by_term = {item["term"].casefold(): item["id"] for item in glossary}
    for item in glossary:
        definition = item["definition"]
        match = re.fullmatch(r"See ([^.]+)\.", definition)
        item["seeAlso"] = by_term.get(match.group(1).casefold(), "") if match else ""
        if match and not item["seeAlso"]:
            raise SystemExit(f"glossary see-also missing target: {item['term']} -> {match.group(1)}")

    sources = parse_sources()
    url_count = sum(len(group["urls"]) for group in sources["groups"])
    claimed = re.search(r"(\d+) in total", sources["intro"])
    if not claimed or int(claimed.group(1)) != url_count:
        raise SystemExit(f"sources intro count does not match URL lines ({url_count})")

    for device in devices:
        if not device["maker"] or not device["released"] or not device["launchPrice"]:
            raise SystemExit(f"{device['name']} is missing maker, released, or launch price")
        blob = read_text(device["fileName"])
        for fact in device["hardware"]:
            rendered = f"{fact['label']}: {fact['value']}" if fact["label"] else fact["value"]
            if rendered not in blob and fact["value"] not in blob:
                raise SystemExit(f"hardware fact not found in source: {rendered!r}")
        for field in ("overview", "controls", "howItFeels", "blindUsability", "gameCompatibility", "uncertain"):
            text = device[field]
            if text and text not in blob:
                raise SystemExit(f"{device['name']} {field} was not copied from the source")

    return {
        "version": 1,
        "title": "Handheld Haven",
        "deviceCount": len(devices),
        "chapters": chapters,
        "devices": devices,
        "guides": guides,
        "glossaryIntro": glossary_doc["intro"],
        "glossary": glossary,
        "sourcesIntro": sources["intro"],
        "sourceGroups": sources["groups"],
    }


def main() -> None:
    data = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    OUT.write_text(encoded, encoding="utf-8")
    print(
        f"wrote {OUT.relative_to(ROOT)} "
        f"devices={data['deviceCount']} chapters={len(data['chapters'])} "
        f"guides={len(data['guides'])} glossary={len(data['glossary'])} "
        f"source_urls={sum(len(g['urls']) for g in data['sourceGroups'])}"
    )


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
