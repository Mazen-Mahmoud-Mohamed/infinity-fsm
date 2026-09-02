#!/usr/bin/env node
/**
 * Reads pubspec.yaml and validates it against a release tag version.
 *
 * Usage:
 *   node scripts/release/resolve-release-version.mjs --tag v1.0.2
 */

import { readFile } from 'node:fs/promises';

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

function parsePubspecVersion(raw) {
  const match = raw.match(/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+(\d+)\s*$/m);
  if (!match) {
    throw new Error('pubspec.yaml must contain version: X.Y.Z+N');
  }
  return {
    version: match[1],
    build: Number.parseInt(match[2], 10),
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const tag = args.tag?.toString().trim();
  if (!tag) {
    throw new Error('Missing --tag (example: v1.0.2)');
  }

  const tagVersion = tag.replace(/^v/i, '');
  const pubspec = await readFile('mobile/pubspec.yaml', 'utf8');
  const resolved = parsePubspecVersion(pubspec);

  if (resolved.version !== tagVersion) {
    throw new Error(
      `Tag version ${tagVersion} does not match pubspec version ${resolved.version}. ` +
        'Update mobile/pubspec.yaml before creating the release tag.',
    );
  }

  process.stdout.write(
    `${JSON.stringify({
      version: resolved.version,
      build: resolved.build,
      tag,
    })}\n`,
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
