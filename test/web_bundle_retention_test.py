"""Real disposable Git histories exercise publication chronology and safe fallback."""
import subprocess
import tempfile
import unittest
from pathlib import Path

HELPER = Path(__file__).resolve().parents[1] / 'tools/select_web_bundle_pruning.py'


class Retention(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='youjia-retention-test.')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Retention Test')
        self.git('config', 'user.email', 'retention-test@example.invalid')
        for name in ['f', 'e', 'a', 'b']:
            self.publish(name)
        (self.root / 'game-c.pck').write_text('current staged build')

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.root, text=True)

    def publish(self, name, content='pck'):
        (self.root / f'game-{name}.pck').write_text(content)
        self.git('add', '-A')
        self.git('commit', '-qm', f'Publish {name}')

    def select(self, current='game-c', keep=4):
        return subprocess.run(['python3', str(HELPER), current, str(keep)],
                              cwd=self.root, text=True, capture_output=True)

    def test_inverse_hash_order_removes_oldest(self):
        r = self.select()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.splitlines(), ['game-f'])
        # Existing lexicographic pruning wrongly removes a, a newer publication.
        self.assertEqual(sorted(p.stem for p in self.root.glob('game-*.pck'))[0], 'game-a')

    def test_current_always_retained_and_count_exact(self):
        r = self.select(keep=1)
        self.assertEqual(set(r.stdout.splitlines()), {'game-f', 'game-e', 'game-a', 'game-b'})
        self.assertNotIn('game-c', r.stdout)

    def test_zero_disables_pruning(self):
        self.assertEqual(self.select(keep=0).stdout, '')

    def test_large_count_does_not_prune(self):
        self.assertEqual(self.select(keep=10).stdout, '')

    def test_republished_old_hash_is_recent(self):
        self.publish('f', 'republished')
        self.assertEqual(self.select().stdout.splitlines(), ['game-e'])

    def test_deleted_and_readded_publication(self):
        self.git('rm', 'game-f.pck')
        self.git('commit', '-qm', 'Retire f')
        self.publish('f', 'new f')
        self.assertEqual(self.select().stdout.splitlines(), ['game-e'])

    def test_unknown_history_preserves_all(self):
        (self.root / 'game-d.pck').write_text('unranked')
        r = self.select()
        self.assertEqual(r.returncode, 0)
        self.assertEqual(r.stdout, '')
        self.assertIn('incomplete bundle history', r.stderr)

    def test_actual_publisher_pruning_block_keeps_recent_resources(self):
        for name in ['f', 'e', 'a', 'b', 'c']:
            (self.root / f'game-{name}.js').write_text(name)
            (self.root / f'game-{name}.wasm').write_text(name)
        (self.root / 'index.pck').write_text('alias')
        source = (HELPER.parent / 'publish_gh_pages.sh').read_text()
        start = source.index('if [[ "${KEEP_BUNDLES}" -gt 0 ]]; then')
        end = source.index('\ncd "$GH_PAGES_DIR"\ngit add -A', start)
        import os
        env = dict(os.environ, REPO_ROOT=str(HELPER.parent.parent),
                   ENTRY='game-c', KEEP_BUNDLES='4')
        subprocess.run(['bash', '-euo', 'pipefail', '-c', source[start:end]],
                       cwd=self.root, env=env, check=True, capture_output=True)
        self.assertEqual({p.stem for p in self.root.glob('game-*.pck')},
                         {'game-e', 'game-a', 'game-b', 'game-c'})
        self.assertFalse((self.root / 'game-f.js').exists())
        self.assertFalse((self.root / 'game-f.wasm').exists())
        self.assertEqual((self.root / 'game-a.js').read_text(), 'a')
        self.assertEqual((self.root / 'index.pck').read_text(), 'alias')

    def test_real_shallow_clone_preserves_all_bundles(self):
        clone = self.root / 'shallow-clone'
        subprocess.run(['git', 'clone', '-q', '--depth=1', self.root.as_uri(), str(clone)],
                       check=True, capture_output=True)
        (clone / 'game-c.pck').write_text('current staged build')
        r = subprocess.run(['python3', str(HELPER), 'game-c', '4'], cwd=clone,
                           text=True, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout, '')
        self.assertIn('shallow bundle history', r.stderr)
        source = (HELPER.parent / 'publish_gh_pages.sh').read_text()
        start = source.index('if [[ "${KEEP_BUNDLES}" -gt 0 ]]; then')
        end = source.index('\ncd "$GH_PAGES_DIR"\ngit add -A', start)
        import os
        env = dict(os.environ, REPO_ROOT=str(HELPER.parent.parent),
                   ENTRY='game-c', KEEP_BUNDLES='4')
        subprocess.run(['bash', '-euo', 'pipefail', '-c', source[start:end]],
                       cwd=clone, env=env, check=True, capture_output=True)
        self.assertEqual(len(list(clone.glob('game-*.pck'))), 5)

    def test_missing_current_fails_before_deletion(self):
        r = self.select(current='game-dead')
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(r.stdout, '')
        self.assertEqual(len(list(self.root.glob('game-*.pck'))), 5)


if __name__ == '__main__':
    unittest.main(verbosity=2)
