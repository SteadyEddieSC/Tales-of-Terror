#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
path = root / "game/tests/playtest_main_route_test.gd"
text = path.read_text(encoding="utf-8")
old = '''	_expect(
		PlaytestReport.release_id() in title.text, "sandbox uses the single v0.1.6 release source"
	)
	_expect("HELP: X / H" in message.text, "sandbox renders X as Help")
	_expect("DIAGNOSTICS: T" in message.text, "sandbox renders T-only diagnostics")
	_expect(not "DIAGNOSTICS: X" in message.text, "sandbox never renders X as diagnostics")
'''
new = '''	_expect(
		"LANTERN HOUSE" in title.text and "STAGE 1" in title.text,
		"sandbox identifies the current Tale and stage",
	)
	_expect(
		"Any active seat may continue" in message.text,
		"sandbox states the active player-owned interaction",
	)
	_expect("A / ENTER: CONTINUE" in message.text, "sandbox renders the expected commit input")
	_expect("X / H: HELP" in message.text, "interaction guidance preserves Help")
	_expect(not "DIAGNOSTICS: X" in message.text, "sandbox never renders X as diagnostics")
'''
count = text.count(old)
if count != 1:
    raise SystemExit(f"expected one legacy sandbox guidance assertion block, found {count}")
path.write_text(text.replace(old, new, 1), encoding="utf-8")
