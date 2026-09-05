#!/usr/bin/env node
/**
 * Unit tests for generate-release-notes.mjs
 * Run: node --test scripts/release/generate-release-notes.test.mjs
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import {
  classifyCommit,
  groupCommits,
  resolvePreviousTag,
  parseCommitsFile,
  buildReleaseNotesMarkdown,
  isGenericOnlyNotes,
  assertMeaningfulReleaseNotes,
  generateReleaseNotes,
  expandUserFacingBullets,
} from './generate-release-notes.mjs';

describe('classifyCommit', () => {
  it('maps user-facing feat commits to What\'s New', () => {
    const result = classifyCommit('feat(work-orders): add optional map pin');
    assert.equal(result.section, 'whatsNew');
    assert.ok(result.bullets[0].startsWith('Add optional map pin'));
  });

  it('expands Work Order address/location features into short product bullets', () => {
    const result = classifyCommit(
      'feat(work-orders): support address and optional location link',
    );
    assert.equal(result.section, 'whatsNew');
    assert.deepEqual(result.bullets, [
      'Work Order Location is now a normal address field.',
      'An optional location/map link can be added separately.',
      'Technicians only see the Location button when a valid location link exists.',
    ]);
  });

  it('maps fix commits to Fixes', () => {
    assert.equal(
      classifyCommit('fix(work-orders): restore detail body').section,
      'fixes',
    );
  });

  it('omits release infrastructure, CI, tests, style, and version bumps', () => {
    assert.equal(
      classifyCommit('feat(release): automate meaningful release notes'),
      null,
    );
    assert.equal(classifyCommit('fix(ci): repair release workflow'), null);
    assert.equal(classifyCommit('test(work-orders): cover location fields'), null);
    assert.equal(classifyCommit('ci: tweak workflow'), null);
    assert.equal(classifyCommit('chore(release): bump version to 1.0.12'), null);
    assert.equal(classifyCommit('style: reformat imports'), null);
    assert.equal(classifyCommit('refactor(api): rename helper'), null);
    assert.equal(classifyCommit('docs(readme): update release docs'), null);
  });

  it('omits commits that only touch infrastructure paths', () => {
    assert.equal(
      classifyCommit('feat(mobile): something', {
        files: [
          'scripts/release/generate-release-notes.mjs',
          '.github/workflows/release.yml',
        ],
      }),
      null,
    );
  });
});

describe('expandUserFacingBullets', () => {
  it('returns a single concise sentence for ordinary changes', () => {
    assert.deepEqual(expandUserFacingBullets('feat', 'attendance', 'show overtime tip'), [
      'Show overtime tip.',
    ]);
  });
});

describe('groupCommits', () => {
  it('keeps only user-facing bullets and ignores infrastructure commits', () => {
    const groups = groupCommits([
      {
        hash: 'a',
        subject: 'feat(work-orders): support address and optional location link',
      },
      {
        hash: 'b',
        subject: 'feat(release): automate meaningful release notes',
      },
      { hash: 'c', subject: 'fix(ci): harden release asset upload' },
      { hash: 'd', subject: 'test(work-orders): cover location fields' },
      { hash: 'e', subject: 'chore(release): bump version to 1.0.12' },
      { hash: 'f', subject: 'fix(notifications): clear stale badge count' },
    ]);

    assert.deepEqual(groups.whatsNew, [
      'Work Order Location is now a normal address field.',
      'An optional location/map link can be added separately.',
      'Technicians only see the Location button when a valid location link exists.',
    ]);
    assert.deepEqual(groups.fixes, ['Clear stale badge count.']);
  });
});

describe('resolvePreviousTag', () => {
  it('returns the next older tag from a sorted list', () => {
    const tags = ['v1.0.12', 'v1.0.11', 'v1.0.10', 'v1.0.2'];
    assert.equal(resolvePreviousTag('v1.0.12', tags), 'v1.0.11');
    assert.equal(resolvePreviousTag('v1.0.10', tags), 'v1.0.2');
    assert.equal(resolvePreviousTag('v1.0.2', tags), null);
  });

  it('handles current tag not yet listed', () => {
    const tags = ['v1.0.11', 'v1.0.10'];
    assert.equal(resolvePreviousTag('v1.0.12', tags), 'v1.0.11');
  });
});

describe('parseCommitsFile', () => {
  it('parses hash|subject|body lines', () => {
    const commits = parseCommitsFile(
      'abc|feat(x): one|body\ndef|fix(y): two|\n',
    );
    assert.equal(commits.length, 2);
    assert.equal(commits[0].subject, 'feat(x): one');
  });
});

describe('buildReleaseNotesMarkdown', () => {
  it('generates short What\'s New / Fixes notes without CI or asset sections', () => {
    const md = buildReleaseNotesMarkdown({
      version: '1.0.12',
      build: 13,
      channel: 'stable',
      groups: {
        whatsNew: [
          'Work Order Location is now a normal address field.',
          'An optional location/map link can be added separately.',
        ],
        fixes: ['Fixed blank detail body.'],
      },
    });

    assert.match(md, /# INFINITY FSM v1\.0\.12/);
    assert.match(md, /^Build: 13$/m);
    assert.match(md, /## What's New/);
    assert.match(md, /## Fixes/);
    assert.doesNotMatch(md, /## Testing & Verification/);
    assert.doesNotMatch(md, /## Release Assets/);
    assert.doesNotMatch(md, /## Technical Changes/);
    assert.doesNotMatch(md, /Android signing secrets/);
    assert.doesNotMatch(md, /release-manifest\.json/);
  });

  it('uses the short maintenance fallback when there are no product changes', () => {
    const md = buildReleaseNotesMarkdown({
      version: '1.0.12',
      build: 13,
      groups: { whatsNew: [], fixes: [] },
      noProductChanges: true,
    });
    assert.match(md, /## What's New/);
    assert.match(md, /Maintenance and internal improvements\./);
    assert.doesNotMatch(md, /Testing & Verification/);
    assert.doesNotMatch(md, /Release Assets/);
  });
});

describe('empty notes protection', () => {
  it('detects generic boilerplate-only notes', () => {
    assert.equal(
      isGenericOnlyNotes(`INFINITY FSM v1.0.11

Build: 12
Release channel: stable

Automated release assets:
- Android APK
- Windows installer
- Release manifest`),
      true,
    );
  });

  it('accepts short meaningful notes with Build line', () => {
    const md = `# INFINITY FSM v1.0.12

Build: 13
Release channel: stable

## What's New
- Work Order Location is now a normal address field.
`;
    assert.equal(isGenericOnlyNotes(md), false);
    assert.doesNotThrow(() => assertMeaningfulReleaseNotes(md));
  });

  it('rejects notes missing Build line', () => {
    assert.throws(
      () =>
        assertMeaningfulReleaseNotes(`# INFINITY FSM v1.0.12

## What's New
- Something meaningful enough to pass length checks here
`),
      /Build: N/,
    );
  });

  it('rejects notes that still include CI/asset sections', () => {
    assert.throws(
      () =>
        assertMeaningfulReleaseNotes(`# INFINITY FSM v1.0.12

Build: 13
Release channel: stable

## What's New
- A real product change.

## Testing & Verification
- Android release APK built
`),
      /must not include Testing/,
    );
  });
});

describe('generateReleaseNotes integration', () => {
  it('A/B/C/D/E/F: user-facing notes only; ignores release/CI/test commits', async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'inf-rn-'));
    const commitsPath = path.join(dir, 'commits.txt');
    await writeFile(
      commitsPath,
      [
        '111|feat(work-orders): support address and optional location link|',
        '222|feat(release): automate meaningful release notes|',
        '333|fix(ci): harden release asset upload|',
        '444|test(work-orders): cover location fields|',
        '555|chore(release): bump version to 1.0.12|',
      ].join('\n'),
      'utf8',
    );

    const result = await generateReleaseNotes({
      version: '1.0.12',
      build: 13,
      tag: 'v1.0.12',
      previousTag: 'v1.0.11',
      commitsFile: commitsPath,
      checks: [
        'Android signing secrets validated',
        'Firebase Android client configuration verified',
        'Android release APK built',
      ],
      cwd: dir,
    });

    assert.equal(result.source, 'git-history');
    assert.match(result.markdown, /Work Order Location is now a normal address field/);
    assert.match(result.markdown, /optional location\/map link/i);
    assert.doesNotMatch(result.markdown, /automate meaningful release notes/i);
    assert.doesNotMatch(result.markdown, /harden release asset upload/i);
    assert.doesNotMatch(result.markdown, /cover location fields/i);
    assert.doesNotMatch(result.markdown, /## Testing & Verification/);
    assert.doesNotMatch(result.markdown, /## Release Assets/);
    assert.doesNotMatch(result.markdown, /## Technical Changes/);
    assert.doesNotMatch(result.markdown, /Android signing secrets/);
    assert.doesNotMatch(result.markdown, /Firebase Android client/);

    const encoded = JSON.stringify({ releaseNotes: result.markdown });
    const decoded = JSON.parse(encoded);
    assert.equal(decoded.releaseNotes, result.markdown);
  });

  it('H: manual override remains authoritative and is not appended with CI sections', async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'inf-rn-ov-'));
    const overrideDir = path.join(dir, 'docs', 'releases');
    await mkdir(overrideDir, { recursive: true });
    await writeFile(
      path.join(overrideDir, 'v1.0.12.md'),
      [
        '# INFINITY FSM v1.0.12',
        '',
        'Build: 13',
        'Release channel: stable',
        '',
        "## What's New",
        '- Manually authored release note for QA',
      ].join('\n'),
      'utf8',
    );

    const result = await generateReleaseNotes({
      version: '1.0.12',
      build: 13,
      tag: 'v1.0.12',
      cwd: dir,
    });

    assert.equal(result.usedManualOverride, true);
    assert.match(result.markdown, /Manually authored release note for QA/);
    assert.doesNotMatch(result.markdown, /## Testing & Verification/);
    assert.doesNotMatch(result.markdown, /## Release Assets/);
  });

  it('G: empty/no-user-facing-change release gets the short maintenance fallback', async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'inf-rn-empty-'));
    const commitsPath = path.join(dir, 'commits.txt');
    await writeFile(
      commitsPath,
      [
        'aaa|chore(release): bump version to 1.0.12|',
        'bbb|feat(release): automate meaningful release notes|',
        'ccc|ci: tweak packaging|',
      ].join('\n'),
      'utf8',
    );

    const result = await generateReleaseNotes({
      version: '1.0.12',
      build: 13,
      tag: 'v1.0.12',
      previousTag: 'v1.0.11',
      commitsFile: commitsPath,
      checks: ['Windows release installer built'],
      cwd: dir,
    });

    assert.equal(result.source, 'no-change-fallback');
    assert.match(result.markdown, /Maintenance and internal improvements\./);
    assert.doesNotMatch(result.markdown, /Windows release installer/);
    assert.doesNotThrow(() => assertMeaningfulReleaseNotes(result.markdown));
  });

  it('I: release-manifest.json receives the exact same short notes', async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'inf-rn-manifest-'));
    const commitsPath = path.join(dir, 'commits.txt');
    const notesPath = path.join(dir, 'RELEASE_NOTES.md');
    const manifestPath = path.join(dir, 'release-manifest.json');
    const androidStub = path.join(dir, 'app-release.apk');
    const windowsStub = path.join(dir, 'INFINITY-Setup-1.0.12.exe');

    await writeFile(
      commitsPath,
      '111|feat(work-orders): support address and optional location link|\n',
      'utf8',
    );
    await writeFile(androidStub, 'apk');
    await writeFile(windowsStub, 'exe');

    const result = await generateReleaseNotes({
      version: '1.0.12',
      build: 13,
      tag: 'v1.0.12',
      previousTag: 'v1.0.11',
      commitsFile: commitsPath,
      cwd: dir,
    });
    await writeFile(notesPath, result.markdown, 'utf8');

    const { spawnSync } = await import('node:child_process');
    const manifestScript = path.resolve(
      'scripts/release/generate-release-manifest.mjs',
    );
    const run = spawnSync(
      process.execPath,
      [
        manifestScript,
        '--version',
        '1.0.12',
        '--build',
        '13',
        '--channel',
        'stable',
        '--notes-file',
        notesPath,
        '--android',
        androidStub,
        '--windows',
        windowsStub,
        '--output',
        manifestPath,
      ],
      { encoding: 'utf8' },
    );
    assert.equal(run.status, 0, run.stderr || run.stdout);

    const { readFile } = await import('node:fs/promises');
    const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
    assert.equal(manifest.releaseNotes, result.markdown.trim());
    assert.doesNotMatch(manifest.releaseNotes, /## Testing & Verification/);
    assert.doesNotMatch(manifest.releaseNotes, /## Release Assets/);
  });
});
