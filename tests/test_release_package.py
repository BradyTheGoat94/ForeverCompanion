#!/usr/bin/env python3
"""Regression tests for the CurseForge packaging safety checks."""
import importlib.util
import hashlib
import json
import zipfile
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("release_builder", ROOT / "tools" / "build_curseforge_beta.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.old = (builder.ROOT, builder.ADDON, builder.TOC)
        self.addCleanup(self.restore)
        builder.ROOT = Path(self.temp.name)
        builder.ADDON = builder.ROOT / "ForeverCompanion"
        builder.ADDON.mkdir()
        builder.TOC = builder.ADDON / "ForeverCompanion.toc"
        (builder.ADDON / "Core.lua").write_text("local ok = true\n", encoding="utf-8")

    def restore(self):
        builder.ROOT, builder.ADDON, builder.TOC = self.old

    def manifest(self, extra=""):
        builder.TOC.write_text(
            "## Interface: 16001\n## Title: Brady's Forever Companion\n"
            "## Version: 3.18.0-beta\n" + extra + "Core.lua\n",
            encoding="utf-8",
        )

    def test_valid_minimal_package(self):
        self.manifest()
        files, meta = builder.validate()
        self.assertEqual(2, len(files))
        self.assertEqual("16001", meta["Interface"])

    def test_archive_integrity_and_reproducibility(self):
        self.manifest()
        first = builder.build(builder.ROOT / "dist-first")
        second = builder.build(builder.ROOT / "dist-second")
        first_bytes, second_bytes = first.read_bytes(), second.read_bytes()
        self.assertEqual(hashlib.sha256(first_bytes).digest(), hashlib.sha256(second_bytes).digest())
        with zipfile.ZipFile(first) as archive:
            self.assertIsNone(archive.testzip())
            self.assertEqual(
                {"ForeverCompanion/ForeverCompanion.toc", "ForeverCompanion/Core.lua"},
                set(archive.namelist()),
            )
        report = json.loads((first.parent / "release-audit.json").read_text(encoding="utf-8"))
        self.assertEqual(hashlib.sha256(first_bytes).hexdigest(), report["sha256"])
        self.assertFalse(report["client_verified"])

    def test_missing_manifest_file(self):
        self.manifest("Missing.lua\n")
        with self.assertRaisesRegex(ValueError, "Missing manifest dependency"):
            builder.validate()

    def test_duplicate_manifest_file(self):
        self.manifest("Core.lua\n")
        with self.assertRaisesRegex(ValueError, "Duplicate manifest"):
            builder.validate()

    def test_unsafe_parent_path(self):
        self.manifest("..\\secret.lua\n")
        with self.assertRaisesRegex(ValueError, "Unsafe manifest path"):
            builder.validate()

    def test_drive_qualified_path(self):
        self.manifest("C:\\Windows\\evil.lua\n")
        with self.assertRaisesRegex(ValueError, "Unsafe manifest path"):
            builder.validate()

    def test_unreferenced_lua_is_rejected(self):
        self.manifest()
        (builder.ADDON / "Hidden.lua").write_text("return true\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Unreferenced module"):
            builder.validate()

    def test_case_insensitive_collision(self):
        if (builder.ADDON / "core.lua").exists():
            self.skipTest("Requires a case-sensitive filesystem to create two colliding files")
        self.manifest()
        (builder.ADDON / "core.lua").write_text("return true\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Case-insensitive filename collision"):
            builder.validate()

    def test_empty_lua_rejected(self):
        self.manifest()
        (builder.ADDON / "Core.lua").write_text("", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Empty addon file"):
            builder.validate()


if __name__ == "__main__":
    unittest.main()
