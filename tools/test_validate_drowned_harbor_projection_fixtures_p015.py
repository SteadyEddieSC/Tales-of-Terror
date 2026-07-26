#!/usr/bin/env python3
"""Run inherited projection regressions with the P0.15 manifest validator."""

from __future__ import annotations

import test_validate_drowned_harbor_projection_fixtures as inherited_tests
from validate_drowned_harbor_projection_fixtures_p015 import validate


def main() -> int:
    original = inherited_tests.validate
    inherited_tests.validate = validate
    try:
        return inherited_tests.main()
    finally:
        inherited_tests.validate = original


if __name__ == "__main__":
    raise SystemExit(main())
