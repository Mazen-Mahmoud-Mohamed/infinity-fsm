#!/usr/bin/env node
/**
 * Generates short, user-facing Markdown release notes for INFINITY FSM.
 *
 * Usage:
 *   node scripts/release/generate-release-notes.mjs \
 *     --tag v1.0.12 \
 *     --version 1.0.12 \
 *     --build 13 \
 *     --channel stable \
 *     --output dist/releases/RELEASE_NOTES.md
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

const INFRASTRUCTURE_SCOPES = new Set([
  'release',
  'ci',
  'build',
  'workflow',
  'workflows',
  'github',
  'deps',
  'dep',
  'webhook',
  'scripts',
  'pipeline',
]);

const INFRASTRUCTURE_PATH_PREFIXES = [
  '.github/',
  'scripts/',
  'docs/releases/',
  'installer.',
];

const USER_FACING_PATH_HINTS = [
  'mobile/lib/',
  'backend/src/modules/',
  'mobile/lib/core/localization/',
];

const MAX_BULLETS = 5;

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
      // Accepted for backward compatibility; never included in public notes.
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

export function listCommitFiles(hash, cwd = process.cwd()) {
  if (!hash || hash.length < 7) return [];
  try {
    const raw = runGit(
      ['show', '--name-only', '--pretty=format:', '--no-renames', hash],
      { cwd },
    );
    if (!raw) return [];
    return raw
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean);
  } catch {
    return [];
  }
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

function isInfrastructureScope(scope) {
  if (!scope) return false;
  const parts = scope.toLowerCase().split(/[/,]+/);
  return parts.some((part) => INFRASTRUCTURE_SCOPES.has(part.trim()));
}

export function isInfrastructureOnlyPaths(files) {
  if (!files?.length) return false;
  return files.every((file) => {
    const normalized = file.replace(/\\/g, '/');
    return INFRASTRUCTURE_PATH_PREFIXES.some(
      (prefix) =>
        normalized.startsWith(prefix) ||
        normalized.includes('/scripts/release/') ||
        /\/docs\/releases\//.test(normalized),
    );
  });
}

export function hasUserFacingPaths(files) {
  if (!files?.length) return false;
  return files.some((file) => {
    const normalized = file.replace(/\\/g, '/');
    if (
      normalized.includes('/__tests__/') ||
      normalized.includes('_test.dart') ||
      normalized.endsWith('.test.js') ||
      normalized.endsWith('.test.mjs') ||
      normalized.startsWith('scripts/') ||
      normalized.startsWith('.github/')
    ) {
      return false;
    }
    return USER_FACING_PATH_HINTS.some((hint) => normalized.includes(hint));
  });
}

function cleanSummary(raw) {
  return String(raw || '')
    .replace(/\s+/g, ' ')
    .replace(/\.\s*$/, '')
    .trim();
}

export function toUserFacingSentence(raw) {
  const cleaned = cleanSummary(raw);
  if (!cleaned) return '';
  const sentence = cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
  return /[.!?]$/.test(sentence) ? sentence : `${sentence}.`;
}

/**
 * Expand known product features into short user-facing bullets.
 * Only expands when the commit subject clearly describes that feature.
 */
export function expandUserFacingBullets(type, scope, description) {
  const text = `${scope} ${description}`.toLowerCase();

  if (
    /work[-_]?order/.test(text) &&
    /address/.test(text) &&
    /location/.test(text)
  ) {
    return [
      'Work Order Location is now a normal address field.',
      'An optional location/map link can be added separately.',
      'Technicians only see the Location button when a valid location link exists.',
    ];
  }

  return [toUserFacingSentence(description)];
}

/**
 * Classify a conventional-commit subject into a user-facing release section.
 * Returns null when the commit should be omitted from public notes.
 */
export function classifyCommit(subject, { files = null } = {}) {
  const text = String(subject || '').trim();
  if (!text) return null;

  if (files?.length && isInfrastructureOnlyPaths(files)) {
    return null;
  }

  const match = text.match(
    /^(feat|fix|perf|refactor|docs|test|chore|ci|build|style)(?:\(([^)]+)\))?!?:\s*(.+)$/i,
  );

  if (!match) {
    if (/^(release|bump version|merge )/i.test(text)) return null;
    if (files?.length && !hasUserFacingPaths(files)) return null;
    if (files?.length && hasUserFacingPaths(files)) {
      return {
        section: 'whatsNew',
        bullets: [toUserFacingSentence(text)],
      };
    }
    return null;
  }

  const type = match[1].toLowerCase();
  const scope = (match[2] || '').toLowerCase();
  const description = cleanSummary(match[3]);

  if (!description) return null;
  if (isInfrastructureScope(scope)) return null;

  if (
    type === 'ci' ||
    type === 'test' ||
    type === 'style' ||
    type === 'refactor' ||
    type === 'docs' ||
    type === 'build' ||
    type === 'chore'
  ) {
    return null;
  }

  if (type === 'feat' || type === 'perf') {
    return {
      section: 'whatsNew',
      bullets: expandUserFacingBullets(type, scope, description),
    };
  }

  if (type === 'fix') {
    return {
      section: 'fixes',
      bullets: expandUserFacingBullets(type, scope, description),
    };
  }

  return null;
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

export function groupCommits(commits, { cwd = null, resolveFiles = null } = {}) {
  const groups = {
    whatsNew: [],
    fixes: [],
  };

  for (const commit of commits) {
    let files = commit.files ?? null;
    if (!files && resolveFiles) {
      files = resolveFiles(commit.hash);
    } else if (!files && cwd && commit.hash && /^[0-9a-f]{7,}$/i.test(commit.hash)) {
      files = listCommitFiles(commit.hash, cwd);
    }

    const classified = classifyCommit(commit.subject, { files });
    if (!classified) continue;
    groups[classified.section].push(...classified.bullets);
  }

  return {
    whatsNew: uniqueSummaries(groups.whatsNew).slice(0, MAX_BULLETS),
    fixes: uniqueSummaries(groups.fixes).slice(0, MAX_BULLETS),
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

  const withoutMeta = text
    .replace(/^#?\s*INFINITY FSM v[\d.]+\s*$/gim, '')
    .replace(/^\s*Build:\s*\d+\s*$/gim, '')
    .replace(/^\s*Release channel:\s*\S+\s*$/gim, '')
    .replace(/^##\s+Testing & Verification[\s\S]*?(?=^## |\Z)/gim, '')
    .replace(/^##\s+Release Assets[\s\S]*?(?=^## |\Z)/gim, '')
    .replace(/^##\s+Technical Changes[\s\S]*?(?=^## |\Z)/gim, '')
    .replace(/Automated release assets:?/gi, '')
    .replace(/INFINITY FSM v[\d.]+ automated release\.?/gi, '')
    .replace(/^- .*(Android APK|Windows installer|Release manifest).*$/gim, '')
    .replace(/^##\s+.+$/gm, '')
    .replace(/\n{2,}/g, '\n')
    .trim();

  return withoutMeta.length < 12;
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
  if (
    /^##\s+Testing & Verification\b/im.test(text) ||
    /^##\s+Release Assets\b/im.test(text) ||
    /^##\s+Technical Changes\b/im.test(text)
  ) {
    throw new Error(
      'Public release notes must not include Testing, Release Assets, or Technical Changes sections',
    );
  }
}

export function buildReleaseNotesMarkdown({
  version,
  build,
  channel = 'stable',
  groups,
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
    sections.push(
      `## What's New\n- Maintenance and internal improvements.\n`,
    );
  } else {
    const whatsNew = [...(groups.whatsNew || [])];
    // Fold leftover "improvements" if older callers still pass them.
    if (groups.improvements?.length) {
      whatsNew.push(...groups.improvements);
    }
    sections.push(renderSection("What's New", uniqueSummaries(whatsNew)));
    sections.push(
      renderSection(
        'Fixes',
        uniqueSummaries(groups.fixes || groups.bugFixes || []),
      ),
    );
  }

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

  const groups = groupCommits(commits, {
    cwd: options.commitsFile ? null : cwd,
    resolveFiles: options.resolveFiles || null,
  });
  const hasProductContent = groups.whatsNew.length + groups.fixes.length > 0;

  const markdown = buildReleaseNotesMarkdown({
    version,
    build,
    channel,
    groups,
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
