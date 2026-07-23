#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
path = root / "game/tests/playtest_main_route_test.gd"
text = path.read_text(encoding="utf-8")
old = '''	_expect(
		"Any active seat may continue" in message.text,
		"sandbox states the active player-owned interaction",
	)
	_expect("A / ENTER: CONTINUE" in message.text, "sandbox renders the expected commit input")
'''
new = '''	_expect(
		"0 of 1 eligible seats committed" in message.text and "waiting for I" in message.text,
		"sandbox reports the pending stable-seat response",
	)
	_expect("A / ENTER: COMMIT" in message.text, "sandbox renders the expected commit input")
'''
count = text.count(old)
if count != 1:
    raise SystemExit(f"expected one first-guidance assertion block, found {count}")
path.write_text(text.replace(old, new, 1), encoding="utf-8")
