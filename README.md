# photos-net

A peer-to-peer family photo network. No server, no cloud, no gatekeeper —
every member's computer keeps a full copy of everyone's photos and browses
them in a local gallery.

- **Sync:** [Syncthing](https://syncthing.net) — BitTorrent-style block
  exchange over encrypted direct connections, with NAT traversal.
- **Gallery:** [PiGallery2](https://github.com/bpatrik/pigallery2) —
  renders the synced photo folders in a browser.
- **Trust model:** pure mesh. There is no central authority; membership is
  pairwise device acceptance, arranged in the group chat.

## How it works

```
your machine                          every other member's machine
+------------------+                  +------------------+
| PiGallery2       |  browse          | PiGallery2       |
|   reads ~/photos |                  |   reads ~/photos |
|                  |                  |                  |
| ~/photos/you/    |  you write here  | ~/photos/them/   |
| ~/photos/them/   |  receive-only    | ~/photos/you/    |  receive-only
| ~/photos/network |  the roster      | ~/photos/network |
|       ^                             |       ^
|   Syncthing <====BEP====> Syncthing <====BEP====> ...
+------------------+                  +------------------+
```

Each member owns one folder — `photos-<name>` — that only they can write to.
Everyone else holds it *receive-only*: your originals can't be altered or
deleted by anyone else. Every gallery shows the union of all members'
folders. There is no server copy; the library exists on the members'
machines.

## Joining (new member)

**Non-technical members:** see `docs/join-guide.md` — send it plus this
folder in the group chat. They double-click one file.

Quick version for technical members:

1. Run the installer:

   **Linux / macOS**
   ```bash
   bash bin/photos-setup.sh --name <your-name>
   ```

   **Windows (PowerShell)**
   ```powershell
   .\bin\photos-setup.ps1 -Name <your-name>
   ```

   Or double-click `photos-setup.cmd` (Windows) / `photos-setup.command`
   (macOS) — the family-friendly launchers.

2. The script prints your **device ID**. Post it in the group chat, or
   paste one existing member's ID when asked.

3. Each existing member runs `photos-accept` (or clicks the prompt in the
   Syncthing GUI) — one click each.

4. Their photo folders arrive under `~/photos/<name>/` as receive-only;
   your gallery at `http://localhost:8089` shows everything.

5. Put your photos in `~/photos/<your-name>/`. They replicate to everyone.

## If you're already a member

- **Someone new posts an ID?** Run `bin/photos-accept` — accepts them and
  shares all folders in one step. (`--watch` accepts automatically, but
  the click is the membership gate — use judgement.)
- **Check your own ID?** `bin/photos-myid` (shows a QR code too, if
  `qrencode` is installed).

## Layout

```
bin/photos-setup.sh    Linux/macOS installer
bin/photos-setup.ps1   Windows installer (SyncTrayzor + npm gallery)
bin/photos-join        join via one bootstrap peer ID + roster import
bin/photos-accept      accept pending devices + share all folders
bin/photos-myid        show your device ID / QR
seed/seed-config.json  canonical conventions (folder names, types, versions)
seed/members.txt       roster seed — lives inside the synced 'network' folder
docs/spike-notes.md    verification log from the two-node proof
```

## Honest limitations

- **Joining is permanent for the data:** a removed member keeps everything
  synced while they were in. Removal only stops future sync.
- **Every member stores the full library** — each machine needs enough free
  disk for everyone's photos.
- **Someone must be online to bootstrap:** a new member needs at least one
  existing member reachable to receive the roster and folders. Any member
  can serve; no machine is special.
- **The gallery is local-first:** photos are browsable away from home only
  if your machine is reachable (an optional WireGuard ingress tier exists
  in the design notes for members who want that).
