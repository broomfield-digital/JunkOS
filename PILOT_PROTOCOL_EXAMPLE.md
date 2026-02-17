# Workspace Bootstrap Protocol

## Goal

Ensure a workspace directory is fully provisioned and verified.
Operate in a sense-act-verify cycle until all checks pass or
an unrecoverable error is encountered.

## Command Interface

Standard shell commands. No special binaries required.

## Workspace Specification

Target directory: `/tmp/discordia-pilot-test`

Required structure:

```
/tmp/discordia-pilot-test/
  identity.txt    — contains: hostname, kernel, architecture (one per line)
  network.txt     — contains: output of `ip -brief addr` or `ifconfig -a`
  uptime.txt      — contains: output of `uptime`
  manifest.sha256 — SHA-256 checksums of the three files above
```

## Operating Policy

1. Query before acting: check what already exists before creating or overwriting.
2. One file at a time: create, then verify, before moving to the next.
3. Manifest last: only generate manifest.sha256 after all three content files
   are created and individually verified.
4. Verify the manifest: after writing it, re-hash the files and compare.
   If mismatch, regenerate and re-verify (max 2 retries).

## Cycle

Each iteration:

1. Check if target directory exists. Create if missing.
2. For each required file (identity, network, uptime):
   - If missing: create it with the specified content.
   - If present: verify it is non-empty and content looks reasonable.
   - If corrupt or empty: recreate it.
3. Once all three files exist and are verified:
   - Generate `manifest.sha256` using `shasum -a 256` or `sha256sum`.
   - Verify manifest by re-running the checksum and comparing.
4. Report final status: list all files, their sizes, and whether the
   manifest verification passed.

## Safety Guardrails

- Only operate within `/tmp/discordia-pilot-test`. Do not create files elsewhere.
- Do not delete files outside the target directory.
- If the manifest fails verification after 2 retries, stop and report the error.
- Do not install packages or modify system configuration.

## Success Criteria

All of the following must be true:

1. `/tmp/discordia-pilot-test/` exists.
2. All three content files exist and are non-empty.
3. `manifest.sha256` exists and passes verification.

Report "PILOT COMPLETE: all checks passed" on success, or
"PILOT FAILED: <reason>" on unrecoverable error.
