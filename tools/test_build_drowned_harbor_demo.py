"""Exercise clean demo staging and exact bundle membership without running Godot."""
from __future__ import annotations

import unittest
import zipfile
from pathlib import Path

from build_drowned_harbor_demo import (
    PACKAGE_METADATA,
    ROOT,
    copy_game_inputs,
    fresh_build_directory,
    publish_bundle,
)


class DemoBuildTests(unittest.TestCase):
    def test_new_stage_cannot_inherit_or_overlay_old_source(self) -> None:
        with fresh_build_directory(ROOT / 'builds/alpha4/test-runs') as work:
            source = work / 'game'
            for name in ('src', 'assets', 'data'):
                (source / name).mkdir(parents=True)
            (source / 'src/current.gd').write_text('current', encoding='utf-8')
            (source / 'assets/current.png.import').write_text('old cache', encoding='utf-8')
            legacy = work / 'project'
            (legacy / 'src').mkdir(parents=True)
            (legacy / 'src/deleted_private_fixture.gd').write_text('stale', encoding='utf-8')
            with fresh_build_directory(work) as fresh:
                stage = fresh / 'project'
                copy_game_inputs(source, stage)
                self.assertEqual((stage / 'src/current.gd').read_text(encoding='utf-8'), 'current')
                self.assertFalse((stage / 'src/deleted_private_fixture.gd').exists())
                self.assertFalse((stage / 'assets/current.png.import').exists())
                with self.assertRaises(FileExistsError):
                    copy_game_inputs(source, stage)
                stage_parent = fresh
            self.assertFalse(stage_parent.exists())
            self.assertTrue((legacy / 'src/deleted_private_fixture.gd').is_file())

    def test_bundle_excludes_stale_and_unexpected_files(self) -> None:
        with fresh_build_directory(ROOT / 'builds/alpha4/test-runs') as work:
            source, output = work / 'fresh', work / 'windows'
            source.mkdir()
            output.mkdir()
            executable = 'drowned_harbor_demo.exe'
            for name in (executable, *PACKAGE_METADATA):
                (source / name).write_bytes(b'new ' + name.encode())
                (output / name).write_bytes(b'old')
            (source / 'unexpected.log').write_text('new diagnostic', encoding='utf-8')
            (output / 'private_old_save.json').write_text('local data', encoding='utf-8')
            (output / 'retired_binary.exe').write_bytes(b'old binary')
            archive = work / 'demo.zip'
            publish_bundle(source, output, archive, executable)
            with zipfile.ZipFile(archive) as bundle:
                self.assertEqual(set(bundle.namelist()), {executable, *PACKAGE_METADATA})
                self.assertEqual(bundle.read(executable), b'new ' + executable.encode())
            self.assertEqual((output / executable).read_bytes(), b'new ' + executable.encode())
            self.assertTrue((output / 'private_old_save.json').is_file())
            self.assertTrue((output / 'retired_binary.exe').is_file())

    def test_incomplete_export_preserves_prior_artifacts(self) -> None:
        with fresh_build_directory(ROOT / 'builds/alpha4/test-runs') as work:
            source, output = work / 'fresh', work / 'windows'
            source.mkdir()
            output.mkdir()
            executable = 'drowned_harbor_demo.exe'
            (source / executable).write_bytes(b'incomplete export')
            (output / executable).write_bytes(b'last good build')
            archive = work / 'demo.zip'
            archive.write_bytes(b'last good archive')
            with self.assertRaisesRegex(ValueError, 'Incomplete demo output'):
                publish_bundle(source, output, archive, executable)
            self.assertEqual((output / executable).read_bytes(), b'last good build')
            self.assertEqual(archive.read_bytes(), b'last good archive')


if __name__ == '__main__':
    unittest.main()
