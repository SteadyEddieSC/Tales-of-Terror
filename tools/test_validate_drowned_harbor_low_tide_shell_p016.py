#!/usr/bin/env python3
"""Run P0.15 Low Tide regressions against P0.16 manifest progression."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Callable

import test_validate_drowned_harbor_low_tide_shell as inherited_tests
from validate_drowned_harbor_low_tide_shell_p016 import validate


def rewrite_json(
    root: Path,
    relative: Path,
    mutate: Callable[[dict], None],
) -> None:
    """Preserve inherited mutations and convert its former future-set no-op."""
    before = inherited_tests.read_json(root / relative)
    inherited_tests_original_rewrite(root, relative, mutate)
    after = inherited_tests.read_json(root / relative)
    if relative == inherited_tests.MANIFEST_PATH and after == before:
        after["future_work_issues"] = [85, 86]
        (root / relative).write_text(
            json.dumps(after, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )


inherited_tests_original_rewrite = inherited_tests.rewrite_json


def main() -> int:
    original_validate = inherited_tests.validate
    original_rewrite = inherited_tests.rewrite_json
    inherited_tests.validate = validate
    inherited_tests.rewrite_json = rewrite_json
    try:
        return inherited_tests.main()
    finally:
        inherited_tests.validate = original_validate
        inherited_tests.rewrite_json = original_rewrite


if __name__ == "__main__":
    raise SystemExit(main())
