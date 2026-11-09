"""Release-policy exceptions must not silently admit new timer sites/assets."""
import importlib.util
from pathlib import Path
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('submission_audit',ROOT/'tools/audit_curseforge_submission.py')
submission=importlib.util.module_from_spec(spec)
spec.loader.exec_module(submission)

class ReleasePolicies(unittest.TestCase):
    def root_audit(self,change):
        with TemporaryDirectory() as directory:
            candidate=Path(directory)
            shutil.copytree(ROOT/'ForeverCompanion',candidate/'ForeverCompanion')
            shutil.copy(ROOT/'ARTWORK_PROVENANCE.md',candidate)
            change(candidate/'ForeverCompanion')
            return subprocess.run([sys.executable,'-X','utf8',str(ROOT/'release_audit.py')],cwd=candidate,capture_output=True,text=True)

    def test_new_timer_site_still_requires_review(self):
        def change(addon):
            with (addon/'Core.lua').open('a',encoding='utf-8') as stream:
                stream.write('\nC_Timer.After(.1,function() end)\n')
        result=self.root_audit(change)
        self.assertNotEqual(result.returncode,0)
        self.assertIn('Timer call sites changed',result.stdout)

    def test_new_artwork_is_not_silently_allowed(self):
        result=self.root_audit(lambda addon:(addon/'Media/unreviewed.png').write_bytes(b'unreviewed'))
        self.assertNotEqual(result.returncode,0)
        self.assertIn('Unexpected packaged asset',result.stdout)

    def test_submission_uses_candidate_version_instead_of_fixed_release(self):
        with TemporaryDirectory() as directory:
            toc=Path(directory)/'addon.toc';handoff=Path(directory)/'handoff.md'
            version='99.2.3-beta'
            text=(ROOT/'ForeverCompanion/ForeverCompanion.toc').read_text(encoding='utf-8')
            import re
            text=re.sub(r'^## Version: .+$','## Version: '+version,text,flags=re.M)
            toc.write_text(text,encoding='utf-8')
            content=submission.HANDOFF.read_text(encoding='utf-8')
            content=re.sub(r'\*\*Version:\*\* .+','**Version:** '+version,content,count=1)
            handoff.write_text(content,encoding='utf-8')
            with patch.object(submission,'TOC',toc),patch.object(submission,'HANDOFF',handoff):
                self.assertEqual(submission.audit(),[])
                handoff.write_text(content.replace('**Version:** '+version,'**Version:** 1.0.0-beta'),encoding='utf-8')
                self.assertTrue(any('candidate version' in error for error in submission.audit()))

if __name__=='__main__': unittest.main()
