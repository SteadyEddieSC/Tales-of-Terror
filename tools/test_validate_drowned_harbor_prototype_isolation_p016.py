#!/usr/bin/env python3
"""Run inherited isolation regressions with P0.16 compatibility validation."""

from __future__ import annotations

import test_validate_drowned_harbor_prototype_isolation as inherited_tests
from validate_drowned_harbor_prototype_isolation_p016 import validate


def main() -> int:
    original = inherited_tests.validate
    inherited_tests.validate = validate
    try:
        return inherited_tests.main()
    finally:
        inherited_tests.validate = original


if __name__ == "__main__":
    raise SystemExit(main())
