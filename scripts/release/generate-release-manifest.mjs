#!/usr/bin/env node
/**
 * Generates release-manifest.json for GitHub Releases.
 *
 * Usage:
 *   node scripts/release/generate-release-manifest.mjs \
 *     --version 1.0.2 \
 *     --build 3 \
 *     --channel stable \
 *     --notes-file release-notes.md \
 *     --android mobile/build/app/outputs/flutter-apk/app-release.apk \
 *     --windows dist/releases/INFINITY-Setup-1.0.2.exe \
 *     --output dist/releases/release-manifest.json
 */

import { createHash } from 'node:crypto';
import { readFile, writeFile, stat } from 'node:fs/promises';
import path from 'node:path';

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const key = token.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      args[key] = true;
      continue;
    }
    args[key] = next;
    i += 1;
  }
  return args;
}

async function sha256File(filePath) {
  const buffer = await readFile(filePath);
  return createHash('sha256').update(buffer).digest('hex');
}

async function buildArtifact(filePath) {
  const stats = await stat(filePath);
  return {
    assetName: path.basename(filePath),
    downloadUrl: null,
    sha256: await sha256File(filePath),
    size: stats.size,
    available: true,
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const version = args.version?.toString().trim();
  const build = Number.parseInt(args.build, 10);
  const channel = (args.channel ?? 'stable').toString().trim();
  const output = args.output ?? 'dist/releases/release-manifest.json';
  const releaseDate = args['release-date'] ?? new Date().toISOString();

  if (!version || !Number.isFinite(build) || build < 0) {
    throw new Error('Missing or invalid --version / --build');
  }
  if (!args.android || !args.windows) {
    throw new Error('Both --android and --windows artifact paths are required');
  }

  let releaseNotes = null;
  if (args['notes-file']) {
    releaseNotes = (await readFile(args['notes-file'], 'utf8')).trim();
  } else if (args.notes) {
    releaseNotes = args.notes.toString().trim();
  }

  const manifest = {
    version,
    build,
    channel,
    releaseDate,
    releaseNotes,
    android: await buildArtifact(args.android),
    windows: await buildArtifact(args.windows),
  };

  await writeFile(output, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  console.log(`Wrote ${output}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
