"""Original deterministic synthesis. No samples, voices, third-party audio, or gameplay RNG."""
from __future__ import annotations

import json
import math
import random
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEST = ROOT / "game/assets/drowned_harbor_alpha4"
RATE = 12000
LOOPS = {
    "harbor_wind_loop": (73.42, 4.0, 0.18),
    "bellhouse_memory_loop": (87.31, 4.0, 0.07),
    "lighthouse_memory_loop": (98.0, 4.0, 0.06),
    "high_water_current_loop": (65.41, 4.0, 0.34),
    "last_light_memory_loop": (110.0, 4.0, 0.04),
}
CUES = {
    "bell_strike_cue": (293.66, 2.4),
    "high_water_cue": (55.0, 2.0),
    "rope_rescue_cue": (164.81, 0.7),
    "ledger_page_cue": (740.0, 0.38),
    "ui_confirm_cue": (440.0, 0.18),
    "last_light_cue": (220.0, 1.8),
    "route_warning_cue": (82.41, 0.9),
}


def render(name: str, frequency: float, seconds: float, noise: float, loop: bool) -> None:
    rng = random.Random(name)
    samples: list[int] = []
    smooth = 0.0
    length = round(RATE * seconds)
    # Integer cycles keep loop boundaries continuous, including the slow modulation.
    frequency = round(frequency * seconds) / seconds if loop else frequency
    for index in range(length):
        t = index / RATE
        smooth = 0.97 * smooth + 0.03 * rng.uniform(-1, 1)
        wave = math.sin(math.tau * frequency * t)
        wave += 0.30 * math.sin(math.tau * frequency * 2 * t)
        wave += 0.16 * math.sin(math.tau * frequency * (3 if loop else 2.71) * t)
        envelope = (0.56 + 0.20 * math.sin(math.tau * t / seconds)) if loop else math.exp(-4 * t / seconds)
        envelope *= min(1, t / 0.012)
        envelope *= min(1, (seconds - t) / 0.018)
        value = (wave * (0.07 if loop else 0.17) + smooth * noise) * envelope
        samples.append(round(max(-0.8, min(0.8, value)) * 32767))
    data = struct.pack("<" + "h" * len(samples), *samples)
    text = '[gd_resource type="AudioStreamWAV" format=3]\n\n[resource]\n'
    text += f'format = 1\nmix_rate = {RATE}\nstereo = false\n'
    if loop:
        text += f'loop_mode = 1\nloop_begin = 0\nloop_end = {length}\n'
    text += 'data = PackedByteArray(' + ', '.join(map(str, data)) + ')\n'
    (DEST / (name + '.tres')).write_text(text, encoding='utf-8')


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for name, (frequency, seconds, noise) in LOOPS.items():
        render(name, frequency, seconds, noise, True)
    for name, (frequency, seconds) in CUES.items():
        render(name, frequency, seconds, 0.8 if 'page' in name else 0.1, False)
    manifest = {
        'version': 1, 'creator': 'OpenAI Codex, original procedural synthesis',
        'source': 'audio/source/drowned_harbor_alpha4/generate_demo_audio.py',
        'license': 'Project-owned generated code and synthesized output; no external samples',
        'sample_rate': RATE, 'loops': list(LOOPS), 'cues': list(CUES),
        'voice_status': 'No speech generated. narrative_en.json is the caption and voice-script source.',
    }
    (Path(__file__).parent / 'synthesis_manifest.json').write_text(
        json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Generated {len(LOOPS)} ambience/music loops and {len(CUES)} cues.')


if __name__ == '__main__':
    main()
