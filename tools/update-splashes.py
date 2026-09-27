#!/usr/bin/env python3
import re
import sys
import urllib.request
from pathlib import Path

REF = sys.argv[1] if len(sys.argv) > 1 else "main"
URL = f"https://raw.githubusercontent.com/hyprwm/Hyprland/{REF}/src/helpers/Splashes.hpp"
LISTS = {"SPLASHES": "splashes.txt", "SPLASHES_CHRISTMAS": "christmas.txt", "SPLASHES_NEWYEAR": "newyear.txt"}
STRING = r'"((?:[^"\\]|\\.)*)"'


def unescape(s):
    return re.sub(r"\\(.)", lambda m: {"n": " ", "t": " "}.get(m.group(1), m.group(1)), s)


def parse(src):
    out = {}
    for name in LISTS:
        body = re.search(rf"\b{name}\s*=\s*\{{(.*?)\n\s*\}};", src, re.S).group(1)
        items = []
        for line in body.splitlines():
            line = line.strip()
            if not line or line.startswith("//"):
                continue
            fmt = re.match(rf"std::format\(\s*{STRING}\s*,(.*)\)\s*,?$", line)
            if fmt:
                args = [a.strip() for a in fmt.group(2).split(",")]
                text = unescape(fmt.group(1))
                for a in args:
                    text = text.replace("{}", "{lastyear}" if a.replace(" ", "") == "newYear-1" else "{year}", 1)
                items.append(text)
                continue
            raw = re.match(r'R"([^(]*)\((.*)\)\1"\s*,?$', line)
            if raw:
                items.append(raw.group(2))
                continue
            parts = re.findall(STRING, line)
            if parts:
                items.append("".join(unescape(p) for p in parts))
        out[name] = items
    return out


def main():
    src = urllib.request.urlopen(URL).read().decode()
    data = Path(__file__).resolve().parent.parent / "data"
    for name, items in parse(src).items():
        (data / LISTS[name]).write_text("\n".join(items) + "\n")
        print(f"{LISTS[name]}: {len(items)}")


main()
