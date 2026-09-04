#!/usr/bin/env node
/**
 * Generates Markdown release notes for INFINITY FSM GitHub Releases.
 *
 * Usage:
 *   node scripts/release/generate-release-notes.mjs \
 *     --tag v1.0.12 \
 *     --version 1.0.12 \
 *     --build 13 \
 *     --channel stable \
 *     --output dist/releases/RELEASE_NOTES.md \
 *     --check "Android release APK built and certificate verified" \
 *     --check "Windows release installer built"
 *
 * Optional:
 *   --previous-tag v1.0.11
 *   --override-file docs/releases/v1.0.12.md
 *   --commits-file /tmp/commits.txt   (for tests; one "hash|subject|body" per line)
 */

import { execFileSync } from 'node:child_process';
import { access, readFile, writeFile, mkdir } from 'node:fs/promises';
import { constants as fsConstants } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function parseArgs(argv) {
  const args = {
    check: [],
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const key = token.slice(2);
    const next = argv[i + 1];
    if (key === 'check') {
      if (!next || next.startsWith('--')) {
        throw new Error('--check requires a value');
      }
      args.check.push(next);
      i += 1;
      continue;
    }
    if (!next || next.startsWith('--')) {
      args[key] = true;
      continue;
    }
    args[key] = next;
    i += 1;
  }
  return args;
}

function runGit(args, { cwd = process.cwd() } = {}) {
  return execFileSync('git', args, {
    cwd,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  }).trim();
}

export function listVersionTags(cwd = process.cwd()) {
  const raw = runGit(['tag', '-l', 'v*.*.*', '--sort=-version:refname'], {
    cwd,
  });
  if (!raw) return [];
  return raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => /^v\d+\.\d+\.\d+$/i.test(line));
}

export function resolvePreviousTag(currentTag, tags) {
  const normalized = String(currentTag || '').trim();
  const index = tags.findIndex(
    (tag) => tag.toLowerCase() === normalized.toLowerCase(),
  );
  if (index === -1) {
    const older = tags.filter((tag) => compareSemverTag(tag, normalized) < 0);
    return older[0] ?? null;
  }
  return tags[index + 1] ?? null;
}

function compareSemverTag(left, right) {
  const leftParts = parseSemverParts(left);
  const rightParts = parseSemverParts(right);
  for (let i = 0; i < 3; i += 1) {
    if (leftParts[i] < rightParts[i]) return -1;
    if (leftParts[i] > rightParts[i]) return 1;
  }
  return 0;
}

function parseSemverParts(tag) {
  const version = String(tag || '')
    .trim()
    .replace(/^v/i, '');
  return version.split('.').map((part) => {
    const value = Number.parseInt(part, 10);
    return Number.isFinite(value) ? value : 0;
  });
}

export function readCommitsBetween(previousTag, currentTag, cwd = process.cwd()) {
  const range = previousTag ? `${previousTag}..${currentTag}` : currentTag;
  let raw = '';
  try {
    raw = runGit(['log', range, '--pretty=format:%H%x1f%s%x1f%b%x1e'], {
      cwd,
    });
  } catch {
    raw = runGit(
      ['log', currentTag, '-n', '50', '--pretty=format:%H%x1f%s%x1f%b%x1e'],
      { cwd },
    );
  }

  if (!raw) return [];

  return raw
    .split('\x1e')
    .map((chunk) => chunk.trim())
    .filter(Boolean)
    .map((chunk) => {
      const [hash, subject = '', body = ''] = chunk.split('\x1f');
      return {
        hash: (hash || '').trim(),
        subject: (subject || '').trim(),
        body: (body || '').trim(),
      };
    })
    .filter((item) => item.hash && item.subject);
}

export function parseCommitsFile(raw) {
  return String(raw || '')
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const [hash, subject, body = ''] = line.split('|');
      return {
        hash: (hash || '').trim(),
        subject: (subject || '').trim(),
        body: (body || '').trim(),
      };
    })
    .filter((item) => item.hash && item.subject);
}

/**
 * Classify a conventional-commit subject into a release section.
 * Returns null when the commit should be omitted from user-facing notes.
 */
export function classifyCommit(subject) {
  const text = String(subject || '').trim();
  if (!text) return null;

  const match = text.match(
    /^(feat|fix|perf|refactor|docs|test|chore|ci|build|style)(?:\(([^)]+)\))?!?:\s*(.+)$/i,
  );

  if (!match) {
    if (/^(release|bump version|merge )/i.test(text)) return null;
    return { section: 'technical', summary: cleanSummary(text) };
  }

  const type = match[1].toLowerCase();
  const scope = (match[2] || '').toLowerCase();
  const description = cleanSummary(match[3]);

  if (!description) return null;

  if (
    type === 'chore' &&
    (scope === 'release' || /^bump version/i.test(description))
  ) {
    return null;
  }

  if (type === 'feat') {
    if (
      scope.includes('update') ||
      scope.includes('ux') ||
      scope.includes('ui')
    ) {
      return { section: 'improvements', summary: description };
    }
    return { section: 'whatsNew', summary: description };
  }

  if (type === 'fix') {
    if (scope === 'ci' || scope === 'release' || scope === 'webhook') {
      return { section: 'technical', summary: description };
    }
    return { section: 'bugFixes', summary: description };
  }

  if (type === 'perf') {
    return { section: 'improvements', summary: description };
  }

  if (type === 'refactor') {
    return { section: 'technical', summary: description };
  }

  if (type === 'docs') {
    if (
      scope.includes('readme') ||
      scope.includes('release') ||
      scope.includes('update')
    ) {
      return { section: 'technical', summary: description };
    }
    return null;
  }

  if (type === 'test') {
    return { section: 'testing', summary: description };
  }

  if (type === 'ci' || type === 'build') {
    return { section: 'technical', summary: description };
  }

  if (type === 'chore') {
    if (
      scope === 'ci' ||
      scope === 'deps' ||
      scope === 'release' ||
      scope === 'webhook'
    ) {
      return { section: 'technical', summary: description };
    }
    return null;
  }

  if (type === 'style') {
    return null;
  }

  return { section: 'technical', summary: description };
}

function cleanSummary(raw) {
  return String(raw || '')
    .replace(/\s+/g, ' ')
    .replace(/\.\s*$/, '')
    .trim();
}

function uniqueSummaries(items) {
  const seen = new Set();
  const result = [];
  for (const item of items) {
    const key = item.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(item);
  }
  return result;
}

export function groupCommits(commits) {
  const groups = {
    whatsNew: [],
    improvements: [],
    bugFixes: [],
    technical: [],
    testing: [],
  };

  for (const commit of commits) {
    const classified = classifyCommit(commit.subject);
    if (!classified) continue;
    groups[classified.section].push(classified.summary);
  }

  return {
    whatsNew: uniqueSummaries(groups.whatsNew),
    improvements: uniqueSummaries(groups.improvements),
    bugFixes: uniqueSummaries(groups.bugFixes),
    technical: uniqueSummaries(groups.technical),
    testing: uniqueSummaries(groups.testing),
  };
}

function renderSection(title, bullets) {
  if (!bullets.length) return '';
  const lines = bullets.map((item) => `- ${item}`);
  return `## ${title}\n${lines.join('\n')}\n`;
}

export function isGenericOnlyNotes(markdown) {
  const text = String(markdown || '').trim();
  if (!text) return true;

  const withoutHeader = text
    .replace(/^#\s+INFINITY FSM v[\d.]+\s*$/gim, '')
    .replace(/^\s*Build:\s*\d+\s*$/gim, '')
    .replace(/^\s*Release channel:\s*\S+\s*$/gim, '')
    .replace(/^##\s+Release Assets[\s\S]*$/gim, '')
    .replace(/Automated release assets:?/gi, '')
    .replace(/^- .*$/gm, (line) => {
      if (/Android APK|Windows installer|Release manifest/i.test(line)) {
        return '';
      }
      return line;
    })
    .replace(/\n{2,}/g, '\n')
    .trim();

  if (!withoutHeader) return true;

  const stripped = withoutHeader
    .replace(/INFINITY FSM v[\d.]+ automated release\.?/gi, '')
    .replace(/Build:\s*\d+/gi, '')
    .trim();

  return stripped.length < 24;
}

export function assertMeaningfulReleaseNotes(markdown) {
  const text = String(markdown || '').trim();
  if (!text) {
    throw new Error('Release notes are empty');
  }
  if (isGenericOnlyNotes(text)) {
    throw new Error(
      'Release notes are effectively empty (only Build/channel/assets boilerplate)',
    );
  }
  if (!/^\s*Build:\s*\d+\s*$/im.test(text)) {
    throw new Error(
      'Release notes must include a "Build: N" line for Update Center fallback parsing',
    );
  }
}

export function buildReleaseNotesMarkdown({
  version,
  build,
  channel = 'stable',
  previousTag = null,
  groups,
  verificationChecks = [],
  noProductChanges = false,
}) {
  const header = [
    `# INFINITY FSM v${version}`,
    '',
    `Build: ${build}`,
    `Release channel: ${channel}`,
    '',
  ];

  const sections = [];

  if (noProductChanges) {
    const range = previousTag
      ? `between ${previousTag} and v${version}`
      : `for v${version} (first release tag in history)`;
    sections.push(
      `## What's New\n- No user-facing product changes were detected ${range}; this release packages the current build for distribution.\n`,
    );
  } else {
    sections.push(renderSection("What's New", groups.whatsNew));
    sections.push(renderSection('Improvements', groups.improvements));
    sections.push(renderSection('Bug Fixes', groups.bugFixes));
    sections.push(renderSection('Technical Changes', groups.technical));
  }

  const testingBullets = [
    ...verificationChecks,
    ...groups.testing.map((item) => `Related verification commit: ${item}`),
  ];
  if (!testingBullets.length) {
    testingBullets.push(
      'Release packaging checks completed in CI for this tag (see workflow job results).',
    );
  }
  sections.push(
    renderSection('Testing & Verification', uniqueSummaries(testingBullets)),
  );

  sections.push(
    [
      '## Release Assets',
      `- Android APK (\`app-release.apk\`)`,
      `- Windows installer (\`INFINITY-Setup-${version}.exe\`)`,
      '- Release manifest (`release-manifest.json`)',
      '',
    ].join('\n'),
  );

  return `${header.join('\n')}\n${sections.filter(Boolean).join('\n')}`.trim() + '\n';
}

async function fileExists(filePath) {
  try {
    await access(filePath, fsConstants.R_OK);
    return true;
  } catch {
    return false;
  }
}

export async function resolveOverridePath(
  version,
  explicitPath,
  cwd = process.cwd(),
) {
  if (explicitPath) {
    return path.resolve(cwd, explicitPath);
  }
  return path.resolve(cwd, 'docs', 'releases', `v${version}.md`);
}

export async function generateReleaseNotes(options) {
  const version = options.version?.toString().trim();
  const build = Number.parseInt(options.build, 10);
  const tag = (options.tag || `v${version}`).toString().trim();
  const channel = (options.channel || 'stable').toString().trim();
  const cwd = options.cwd || process.cwd();

  if (!version || !Number.isFinite(build) || build < 0) {
    throw new Error('Missing or invalid version/build');
  }

  const overridePath = await resolveOverridePath(
    version,
    options.overrideFile,
    cwd,
  );
  if (await fileExists(overridePath)) {
    const manual = (await readFile(overridePath, 'utf8')).trim();
    let body = manual;
    if (!/^\s*Build:\s*\d+\s*$/im.test(body)) {
      body = `# INFINITY FSM v${version}\n\nBuild: ${build}\nRelease channel: ${channel}\n\n${manual}`;
    }
    if (!body.startsWith('#')) {
      body = `# INFINITY FSM v${version}\n\nBuild: ${build}\nRelease channel: ${channel}\n\n${body}`;
    }
    assertMeaningfulReleaseNotes(body);
    return {
      markdown: body.endsWith('\n') ? body : `${body}\n`,
      previousTag: options.previousTag ?? null,
      usedManualOverride: true,
      source: 'manual-override',
    };
  }

  let previousTag = options.previousTag?.toString().trim() || null;
  if (!previousTag) {
    const tags = listVersionTags(cwd);
    previousTag = resolvePreviousTag(tag, tags);
  }

  let commits = [];
  if (options.commitsFile) {
    const raw = await readFile(path.resolve(cwd, options.commitsFile), 'utf8');
    commits = parseCommitsFile(raw);
  } else {
    commits = readCommitsBetween(previousTag, tag, cwd);
  }

  const groups = groupCommits(commits);
  const hasProductContent =
    groups.whatsNew.length +
      groups.improvements.length +
      groups.bugFixes.length +
      groups.technical.length >
    0;

  const markdown = buildReleaseNotesMarkdown({
    version,
    build,
    channel,
    previousTag,
    groups,
    verificationChecks: options.checks || [],
    noProductChanges: !hasProductContent,
  });

  assertMeaningfulReleaseNotes(markdown);

  return {
    markdown,
    previousTag,
    usedManualOverride: false,
    source: hasProductContent ? 'git-history' : 'no-change-fallback',
    groups,
    commitCount: commits.length,
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const version = args.version?.toString().trim();
  const build = args.build;
  const tag = args.tag?.toString().trim() || (version ? `v${version}` : '');
  const output = args.output || 'dist/releases/RELEASE_NOTES.md';

  const result = await generateReleaseNotes({
    version,
    build,
    tag,
    channel: args.channel || 'stable',
    previousTag: args['previous-tag'],
    overrideFile: args['override-file'],
    commitsFile: args['commits-file'],
    checks: args.check || [],
    cwd: process.cwd(),
  });

  const outPath = path.resolve(process.cwd(), output);
  await mkdir(path.dirname(outPath), { recursive: true });
  await writeFile(outPath, result.markdown, 'utf8');

  process.stdout.write(
    `${JSON.stringify(
      {
        output: outPath,
        previousTag: result.previousTag,
        source: result.source,
        usedManualOverride: result.usedManualOverride,
        commitCount: result.commitCount ?? null,
      },
      null,
      2,
    )}\n`,
  );
}

const isDirectRun =
  Boolean(process.argv[1]) &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isDirectRun) {
  main().catch((error) => {
    console.error(error.message);
    process.exit(1);
  });
}
