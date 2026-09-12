"""Original Alpha.4 demo text and provenance assembly; no external image inputs."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEST = ROOT / 'game/assets/drowned_harbor_alpha4'
STAGES = {
    'low_tide': ('The Harbor at Low Tide', 'A town without a place on any chart. Its lamps are lit. Someone expected you.'),
    'bellhouse': ('The Bellhouse Ledger', 'The Council recorded every stolen cargo. The missing column was people.'),
    'council': ('Council Beneath the Light', 'An empty chair is still a chair. Sit carefully. Decide what this light is for.'),
    'high_water': ('The Terror Turn', 'There goes the road. The sea has remembered where it left this town.'),
    'flood': ('High Water', 'Rope, oil, names. Keep what you can carry. Decide who you can bring.'),
    'last_light': ('Last Light', 'A lighthouse promises a destination. Before you turn the lens, choose who should find it.'),
    'ending': ('The Last Bell', 'No more rehearsals. Ring it. Let the Harbor hear what you decided.'),
    'epilogue': ('What Came Home', 'The shore will ask what happened here. You may find yourselves giving different answers.'),
    'complete': ('Until the Next Low Tide', 'That is where your account ends. The sea, of course, keeps its own.'),
}
SPOOKY = {
    'low_tide': 'A town has come out of the sea, and every lamp is waiting for a visitor.',
    'bellhouse': 'These records tell a sad truth. Help the town remember the people it forgot.',
    'council': 'The chairs are empty. The decision is yours: where should the light lead?',
    'high_water': 'The tide is back. Stay together; a new route waits through the channel.',
    'flood': 'Keep your ropes close and your friends closer. There is still time to help.',
    'last_light': 'One last light. Make it a promise you can keep.',
}
DREAD = {
    'low_tide': 'The sea has peeled back its skin. Beneath it: a town, still breathing through its lamps.',
    'high_water': 'The streets fill like opened lungs. The Harbor is drawing its next breath.',
    'flood': 'Cold fingers rise through the floorboards. Some are asking for help. Some remember your name.',
}
ROLES = {
    'lantern_surveyor': ('Lantern Surveyor', 'You map the passages nobody believes are still there. A steady lamp makes a route out of a rumor.'),
    'bellhouse_archivist': ('Bellhouse Archivist', 'You know the difference between an absent name and an erased one. The ledger owes you both.'),
    'lifeboat_keeper': ('Lifeboat Keeper', 'You count places, not promises. A rope in your hands has always meant someone gets another chance.'),
    'fog_listener': ('Fog Listener', 'The fog carries voices before it carries shapes. You have learned when to listen, and when to move.'),
    'wreckers_heir': ("Wrecker’s Heir", 'Your inheritance washed ashore in pieces. You can turn wreckage into shelter, if you can bear what it belonged to.'),
    'tide_chapel_warden': ('Tide Chapel Warden', 'You keep a place for those who cannot cross the water. Even a ghost should have somewhere to stand.'),
}
EVENTS = {
    'search_manifest': 'A relief ship. Food. Medicine. Passengers. The wreck was deliberate.',
    'search_wreck': 'A survivor wrote between the cargo lines. Small handwriting can carry a great accusation.',
    'salvage_oil': 'The lantern takes the oil. The patrol takes an interest.',
    'secure_boat': 'An extra knot. Two more places. Sometimes hope is this practical.',
    'shelter': 'For a moment, even the bell has nothing to add.',
    'aid_resident': 'The rope tightens. Someone on the other end remembers being alive.',
    'follow_names': 'Give a stolen name its place again, and listen to what changes.',
    'follow_light': 'The lens is cracked. Its invitation is perfectly clear.',
    'follow_missing': 'One blank line. One open passage. Absence can be a kind of mercy.',
    'search_archive': 'The pages survived. Your breath may not last as long.',
    'salt_ward': 'Salt draws a boundary the water understands.',
    'harbor_bargain': 'An offer can sound like rescue. Read it twice.',
    'refuse_bargain': 'You keep your own name. The Harbor does not thank you for it.',
    'restless_warn': 'A voice from beneath the water. Still yours. Still useful.',
    'rescue': 'Not every name in the ledger has to stay there.',
    'defeat': 'The tide has taken your breath. It has not taken your turn.',
    'director': 'The Harbor changes its attention. It has learned which streets you favor.',
}


def main() -> None:
    catalog = {'version': 1, 'locale': 'en', 'stages': {}, 'roles': {}, 'events': {}, 'aliases': {}}
    for key, (title, text) in STAGES.items():
        catalog['stages'][key] = {'key': 'dh.stage.' + key, 'title': title, 'text': text,
            'variants': {'spooky': SPOOKY.get(key, text), 'grim': text, 'gore_dread': DREAD.get(key, text)}}
    for key, (title, text) in ROLES.items():
        catalog['roles'][key] = {'key': 'dh.role.' + key, 'title': title, 'text': text,
            'portrait': 'role_' + key + '_portrait.png'}
    for key, text in EVENTS.items():
        catalog['events'][key] = {'key': 'dh.event.' + key, 'text': text}
    (DEST / 'narrative_en.json').write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    lines = []
    for section in ['stages', 'events']:
        for key, row in catalog[section].items():
            lines.append({'id': row['key'], 'text': row['text'], 'speaker': 'The Underteller',
                'delivery': 'Quiet, dry warmth; spare coastal storyteller. No imitation of a real performer.',
                'audience': 'public', 'audio_path': None, 'status': 'generation_ready_not_recorded'})
    (ROOT / 'audio/source/drowned_harbor_alpha4/voice_manifest.json').write_text(
        json.dumps({'version': 1, 'lines': lines}, indent=2) + '\n', encoding='utf-8')
    provenance_path = ROOT / 'art/provenance.json'
    provenance = json.loads(provenance_path.read_text(encoding='utf-8'))
    entries = [e for e in provenance['assets'] if '/drowned_harbor_alpha4/' not in e.get('runtime_path', '')]
    sources = []
    for path in sorted(DEST.glob('*')):
        if path.suffix not in {'.png', '.tres', '.json'}:
            continue
        visual = path.suffix == '.png'
        source = ('art/source/drowned_harbor_alpha4/' + path.name if visual else
            'audio/source/drowned_harbor_alpha4/generate_demo_audio.py' if path.suffix == '.tres' else
            'art/source/drowned_harbor_alpha4/build_narrative.py')
        entry = {'id': 'dh_alpha4_' + path.stem, 'runtime_path': path.relative_to(ROOT).as_posix(),
            'source': source, 'creator': 'OpenAI image_gen via Codex' if visual else 'OpenAI Codex original authored source',
            'license': 'Generated for the Project Owner under OpenAI terms; no third-party inputs' if visual else
                'Project-owned authored source and derived output; no external samples',
            'derivation': 'Unmodified generated PNG copied from retained source master' if visual else 'Deterministic generation from retained source script',
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'status': 'owner_authorized_alpha4_demo_candidate',
            'human_review': 'Pending; no independent human review claimed', 'external_reference_inputs': []}
        entries.append(entry)
        if visual:
            sources.append(entry)
    provenance['assets'] = entries
    provenance_path.write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    (Path(__file__).parent / 'generation_manifest.json').write_text(json.dumps({
        'version': 1, 'generator': 'OpenAI image_gen', 'session': 'Terror Turn Alpha.4 whole-game build',
        'authorization': 'Project Owner pasted request d8c99069-1516-46d6-bf85-01b613745e31',
        'source_kind': 'New text-to-image generation, no referenced images',
        'direction': 'Original modern storybook coastal folk horror; six landmark shared harbor master and six role portraits',
        'prompt_record': 'Direction summary retained; verbatim tool prompts remain in the presentation_assets agent task history.',
        'sources': sources}, indent=2) + '\n', encoding='utf-8')
    print(f'Created {len(STAGES)} stage families, {len(ROLES)} roles, {len(EVENTS)} event lines, {len(entries)} provenance records.')


if __name__ == '__main__':
    main()
