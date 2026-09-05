# Manual release notes overrides

Automated GitHub Releases generate short, user-facing notes from commits between the previous `vX.Y.Z` tag and the current tag.

To override the generated notes for a specific version, add a Markdown file named after that version:

```text
docs/releases/v1.0.12.md
```

When that file exists at release time, it is used as the authoritative release body (and as `releaseNotes` in `release-manifest.json`).

Guidelines:

- Include a `Build: N` line (required for Update Center fallback parsing when synthesizing from the GitHub release body).
- Keep notes short and user-facing. Prefer:

```markdown
## What's New

- Concise product change.

## Fixes

- Concise bug fix.
```

- Do not include Testing & Verification, Release Assets, CI details, or technical implementation notes.
- Do not invent changes that are not in the release.
- Overrides are optional; omit the file to keep automatic generation.
