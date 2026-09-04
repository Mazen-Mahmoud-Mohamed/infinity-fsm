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
} from './generate-release-notes.mjs';

describe('classifyCommit', () => {
  it('maps feat to What\'s New', () => {
    assert.deepEqual(classifyCommit('feat(work-orders): add location link'), {
      section: 'whatsNew',
      summary: 'add location link',
    });
  });

  it('maps feat(update/ui/ux) to Improvements', () => {
    assert.equal(
      classifyCommit('feat(update): improve installer UX').section,
      'improvements',
    );
    assert.equal(classifyCommit('feat(ui): polish dialogs').section, 'improvements');
  });

  it('maps fix to Bug Fixes and scoped ci fix to Technical', () => {
    assert.equal(
      classifyCommit('fix(work-orders): restore detail body').section,
      'bugFixes',
    );
    assert.equal(classifyCommit('fix(ci): repair release workflow').section, 'technical');
  });

  it('omits release version bumps and style-only commits', () => {
    assert.equal(classifyCommit('chore(release): bump version to 1.0.12'), null);
    assert.equal(classifyCommit('style: reformat imports'), null);
  });

  it('maps test commits to testing section', () => {
    assert.equal(
      classifyCommit('test(work-orders): cover location fields').section,
      'testing',
    );
  });
});

describe('groupCommits', () => {
  it('groups and deduplicates summaries', () => {
    const groups = groupCommits([
      { hash: 'a', subject: 'feat(wo): add address field' },
      { hash: 'b', subject: 'feat(wo): add address field' },
      { hash: 'c', subject: 'fix(wo): clear stale cache' },
      { hash: 'd', subject: 'chore(release): bump version' },
    ]);
    assert.deepEqual(groups.whatsNew, ['add address field']);
    assert.deepEqual(groups.bugFixes, ['clear stale cache']);
    assert.equal(groups.technical.length, 0);
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
  it('omits empty sections and always includes testing + assets', () => {
    const md = buildReleaseNotesMarkdown({
      version: '1.0.12',
      build: 13,
      channel: 'stable',
      previousTag: 'v1.0.11',
      groups: {
        whatsNew: ['Added location address field'],
        improvements: [],
        bugFixes: ['Fixed blank detail body'],
        technical: [],
        testing: [],
      },
      verificationChecks: [
        'Android release APK built and certificate verified',
        'Windows release installer built',
      ],
    });

    assert.match(md, /# INFINITY FSM v1\.0\.12/);
    assert.match(md, /^Build: 13$/m);
    assert.match(md, /## What's New/);
    assert.match(md, /## Bug Fixes/);
    assert.doesNotMatch(md, /## Improvements/);
    assert.doesNotMatch(md, /## Technical Changes/);
    assert.match(md, /## Testing & Verification/);
    assert.match(md, /Android release APK built/);
    assert.match(md, /## Release Assets/);
  });

  it('uses explicit no-change fallback when requested', () => {
    const md = buildReleaseNotesMarkdown({
      version: '1.0.12',
      build: 13,
      previousTag: 'v1.0.11',
      groups: {
        whatsNew: [],
        improvements: [],
        bugFixes: [],
        technical: [],
        testing: [],
      },
      verificationChecks: ['Release packaging checks completed'],
      noProductChanges: true,
    });
    assert.match(md, /No user-facing product changes were detected between v1\.0\.11 and v1\.0\.12/);
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

  it('accepts meaningful notes with Build line', () => {
    const md = `# INFINITY FSM v1.0.12

Build: 13
Release channel: stable

## What's New
- Added separate Work Order location address

## Testing & Verification
- Android release APK built

## Release Assets
- Android APK
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
});

describe('generateReleaseNotes integration', () => {
  it('builds notes from a commits file and writes JSON-safe markdown', async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'inf-rn-'));
    const commitsPath = path.join(dir, 'commits.txt');
    await writeFile(
      commitsPath,
      [
        '111|feat(work-orders): support address and optional location link|',
        '222|fix(ci): harden release asset upload|',
        '333|test(work-orders): cover location fields|',
        '444|chore(release): bump version to 1.0.12|',
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
        'Android release APK built and certificate verified',
        'Windows release installer built',
        'Release manifest generated with SHA256 checksums',
      ],
      cwd: dir,
    });

    assert.equal(result.source, 'git-history');
    assert.match(result.markdown, /support address and optional location link/i);
    assert.match(result.markdown, /harden release asset upload/i);
    assert.match(result.markdown, /Android release APK built/);
    assert.equal(isGenericOnlyNotes(result.markdown), false);

    const encoded = JSON.stringify({ releaseNotes: result.markdown });
    const decoded = JSON.parse(encoded);
    assert.equal(decoded.releaseNotes, result.markdown);
  });

  it('uses manual override when docs/releases/vX.Y.Z.md exists', async () => {
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
        '## What\'s New',
        '- Manually authored release note for QA',
        '',
        '## Testing & Verification',
        '- Manual override used',
        '',
        '## Release Assets',
        '- Android APK',
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
  });

  it('falls back when no product commits are classified', async () => {
    const dir = await mkdtemp(path.join(tmpdir(), 'inf-rn-empty-'));
    const commitsPath = path.join(dir, 'commits.txt');
    await writeFile(
      commitsPath,
      'aaa|chore(release): bump version to 1.0.12|\n',
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
    assert.match(result.markdown, /No user-facing product changes were detected/);
    assert.doesNotThrow(() => assertMeaningfulReleaseNotes(result.markdown));
  });
});
