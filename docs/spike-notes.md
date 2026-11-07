# Spike notes — verification log

Date: 2026-11-07. Host: Fedora 44 workstation (31 GB RAM, podman 5.8.9).
Verify-and-declare: all checks were run locally (phase 1 — no remote hosts).

## App spike (Phase A)

Two candidates run side-by-side against `$HOME/photos` (41 test images):

| | Containers | RSS during scan | Image size | Setup steps |
|---|---|---|---|---|
| PiGallery2 3.5.2 | 1 | ~100 MB | 940 MB | one `podman run` |
| Immich v3.3.5 | 4 (server+ML+pg+valkey) | ~2.7 GB | ~3.4 GB | compose + admin signup + library creation via API |

- PiGallery2 rendered the folder tree immediately, zero config.
- Immich needed onboarding + external-library setup; its default exclusion
  patterns already cover `.stfolder`/`.stversions` (Syncthing-aware).
- **Decision: PiGallery2** — weight and one-container install suit
  "browse the family folder on any hardware." Note: image defaults
  `authenticationRequired: true` with seeded `admin`/`admin` — the
  installer must set a real password or disable auth.

## Two-node + roster join proof (Phase B)

Three Syncthing instances on one host (A=node-a :8384/22000, B=node-b
:8385/43843, C=node-c :8386/40135), driven entirely via the REST API —
the same calls the helper scripts make.

Verified:

- `photos-node-a` (sendreceive on A) -> A shares to B; B accepts **receive-only**.
  All 41 files arrived on B.
- `photos-node-b` (sendreceive on B) -> A accepts receive-only; node-b's new
  photo synced to A in seconds.
- **Delete protection:** deleting `img_01.jpg` on B's receive-only copy
  did NOT propagate; A's original untouched. B shows
  `receiveOnlyChanged: 1` (the "Revert Local Changes" state).
- **Roster bootstrap:** `network` folder (sendreceive, all members)
  carries `members.txt`. Carol joined knowing ONLY A's device ID:
  C adds A -> A accepts + shares `network`/`photos-node-a` -> members.txt
  syncs -> helper adds B's ID automatically -> B accepts + shares all
  folders -> C ends with the full library, connected to BOTH peers
  (swarm: files pull from whichever members are online).

## Install-path notes

- Fedora: `dnf install syncthing` (2.1.6), `systemctl --user` unit ships
  with the package; `loginctl enable-linger` for boot persistence.
- Syncthing picks a free TCP port if 22000 is taken — no config needed.
- Windows path uses SyncTrayzor (winget `SyncTrayzor.SyncTrayzor`) +
  npm-installed PiGallery2 (avoids Docker Desktop).
- Gallery bind mounts must be `:ro` — apps never write the library.

## Not yet verified

- `photos-setup.sh` / `.ps1` on a clean machine (they were written from
  these notes, not run end-to-end).
- `photos-join` / `photos-accept` as packaged scripts (their API sequence
  was executed manually — see above).
- macOS install path (`brew install syncthing`, `brew services`).
- Conflict behaviour when two members edit `members.txt` simultaneously.
