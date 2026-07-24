#!/usr/bin/env python3
"""Generate deterministic nonproduction pseudolocalized narrative data."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable

VOICE_DIR = Path("docs/tales/drowned_harbor/voice")
VOICE_PATTERN = "drowned_harbor_voice_*_families_v1.json"
PLACEHOLDER_PATTERN = re.compile(r"\{[a-z][a-z0-9_]*\}")
WORD_PATTERN = re.compile(r"\S+")
ACCENT_TABLE = str.maketrans(
    {
        "A": "Å",
        "B": "Ɓ",
        "C": "Ç",
        "D": "Ð",
        "E": "Ë",
        "F": "Ƒ",
        "G": "Ĝ",
        "H": "Ħ",
        "I": "Ï",
        "J": "Ĵ",
        "K": "Ķ",
        "L": "Ŀ",
        "M": "M",
        "N": "Ñ",
        "O": "Ø",
        "P": "Þ",
        "Q": "Q",
        "R": "Ŕ",
        "S": "Š",
        "T": "Ŧ",
        "U": "Ü",
        "V": "V",
        "W": "Ŵ",
        "X": "X",
        "Y": "Ÿ",
        "Z": "Ž",
        "a": "å",
        "b": "ƀ",
        "c": "ç",
        "d": "ð",
        "e": "ë",
        "f": "ƒ",
        "g": "ĝ",
        "h": "ħ",
        "i": "ï",
        "j": "ĵ",
        "k": "ķ",
        "l": "ŀ",
        "m": "m",
        "n": "ñ",
        "o": "ø",
        "p": "þ",
        "q": "q",
        "r": "ŕ",
        "s": "š",
        "t": "ŧ",
        "u": "ü",
        "v": "v",
        "w": "ŵ",
        "x": "x",
        "y": "ÿ",
        "z": "ž",
    }
)


class PseudolocalizationError(ValueError):
    """Raised when source narrative data cannot be pseudolocalized safely."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PseudolocalizationError(message)


def split_placeholders(source: str) -> list[tuple[bool, str]]:
    parts: list[tuple[bool, str]] = []
    position = 0
    for match in PLACEHOLDER_PATTERN.finditer(source):
        if match.start() > position:
            parts.append((False, source[position : match.start()]))
        parts.append((True, match.group(0)))
        position = match.end()
    if position < len(source):
        parts.append((False, source[position:]))
    return parts


def expand_words(source: str, expansion_ratio: float) -> str:
    """Add visible expansion markers after words without changing placeholders."""

    require(0.0 <= expansion_ratio <= 1.0, "expansion ratio must be between 0 and 1")
    if not source or expansion_ratio == 0:
        return source

    target_extra = max(1, round(len(source) * expansion_ratio))
    words = list(WORD_PATTERN.finditer(source))
    if not words:
        return source + ("~" * target_extra)

    per_word = target_extra // len(words)
    remainder = target_extra % len(words)
    output: list[str] = []
    position = 0
    for index, match in enumerate(words):
        output.append(source[position : match.end()])
        extra = per_word + (1 if index < remainder else 0)
        if extra:
            output.append("~" * extra)
        position = match.end()
    output.append(source[position:])
    return "".join(output)


def pseudolocalize_text(source: str, expansion_ratio: float = 0.35) -> str:
    require(isinstance(source, str) and bool(source.strip()), "source text must be non-empty")
    output: list[str] = ["[!! "]
    for is_placeholder, segment in split_placeholders(source):
        if is_placeholder:
            output.append(segment)
        else:
            accented = segment.translate(ACCENT_TABLE)
            output.append(expand_words(accented, expansion_ratio))
    output.append(" !!]")
    result = "".join(output)
    require(
        set(PLACEHOLDER_PATTERN.findall(result))
        == set(PLACEHOLDER_PATTERN.findall(source)),
        "placeholder preservation failed",
    )
    return result


def discover_voice_manifests() -> tuple[Path, ...]:
    paths = tuple(sorted(VOICE_DIR.glob(VOICE_PATTERN)))
    require(bool(paths), "no governed voice manifests found")
    return paths


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise PseudolocalizationError(f"file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise PseudolocalizationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(data, dict), f"root must be an object: {path}")
    return data


def generate_package(paths: Iterable[Path], expansion_ratio: float = 0.35) -> dict[str, Any]:
    families: list[dict[str, Any]] = []
    seen: set[str] = set()
    for path in paths:
        data = load_json(path)
        require(
            data.get("manifest_kind") == "voice_line_families_preproduction",
            f"unexpected source manifest kind: {path}",
        )
        entries = data.get("entries")
        require(isinstance(entries, list), f"entries must be a list: {path}")
        for entry in entries:
            require(isinstance(entry, dict), f"voice entry must be an object: {path}")
            family_id = entry.get("family_id")
            require(isinstance(family_id, str) and family_id, f"family_id missing: {path}")
            require(family_id not in seen, f"duplicate family_id: {family_id}")
            seen.add(family_id)
            scripts = entry.get("draft_script")
            require(isinstance(scripts, dict), f"draft_script missing: {family_id}")
            expected = {"spooky", "grim", "gore_and_dread", "plain_system"}
            require(set(scripts) == expected, f"profile set incomplete: {family_id}")
            localized = {
                profile: pseudolocalize_text(text, expansion_ratio)
                for profile, text in scripts.items()
            }
            families.append(
                {
                    "family_id": family_id,
                    "mechanical_equivalence_key": entry.get(
                        "mechanical_equivalence_key"
                    ),
                    "strings": localized,
                }
            )

    return {
        "locale": "qps-ploc",
        "display_name": "Pseudo (Expanded, Nonproduction)",
        "status": "generated_test_only",
        "source_locale": "en-US",
        "expansion_ratio": expansion_ratio,
        "warning": (
            "This is deterministic pseudolocalization for layout and placeholder "
            "testing. It is not a real translation or supported player locale."
        ),
        "family_count": len(families),
        "string_count": len(families) * 4,
        "families": families,
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Output JSON path. Generated output should remain untracked.",
    )
    parser.add_argument(
        "--expansion-ratio",
        type=float,
        default=0.35,
        help="Additional visible character ratio between 0 and 1.",
    )
    parser.add_argument("manifests", nargs="*", type=Path)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    paths = tuple(args.manifests) if args.manifests else discover_voice_manifests()
    try:
        package = generate_package(paths, args.expansion_ratio)
    except PseudolocalizationError as exc:
        print(f"Pseudolocalization failed: {exc}", file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(package, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"Generated {package['string_count']} pseudolocalized strings across "
        f"{package['family_count']} families at {args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
