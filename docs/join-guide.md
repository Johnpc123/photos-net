# Join the family photo network

*Written for non-technical family members. Just send them the repo
link — everything they need is inside.*

---

## What you're getting

A shared family photo library. Everyone's photos appear in a folder on
your computer and in a gallery you open in your web browser. When you
add photos, everyone else gets them automatically. There's no company
in the middle — the photos live on the family's own computers.

You need: a computer that stays on reasonably often, and enough free
disk space for everyone's photos (we'll tell you the current size).

## Step 1 — get the files

1. Open **github.com/Johnpc123/photos-net** in your browser.
2. Click the green **<> Code** button → **Download ZIP**.
3. Unzip it somewhere you can find it (Desktop or Downloads is fine)
   and open the `photos-net` folder inside.

## Step 2 — run the installer

**Windows:** open the folder and **double-click `photos-setup.cmd`**.
If Windows shows a blue "protected your PC" warning, click
**More info → Run anyway** (it's our own script, not a download from
the internet).

**Mac:** open the folder and **double-click `photos-setup.command`**.
If macOS says it can't be opened, right-click the file and choose
**Open**, then **Open** again. (Or: System Settings → Privacy &
Security → "Open Anyway".)

**Linux:** open a terminal in the folder and run `bash bin/photos-setup.sh`.

## Step 3 — wait and watch

A window opens and installs things for a few minutes. It's normal to be
asked for your computer's password (that's the installer getting
permission to install software). When it finishes it will show a long
code that looks like:

    ABCDEF1-2345678-ABCDEF1-2345678-ABCDEF1-2345678-ABCDEF1-2345678

**Copy that whole code and paste it in the group chat.** That's your
computer's name on the network — it's safe to share with family.

## Step 4 — one of us accepts you

Each existing member gets a notification and clicks "accept". Photos
then start appearing in the `photos` folder in your home directory —
this can take a while the first time (it's copying everyone's photos).

## Step 5 — browse and add photos

- **See everyone's photos:** open `http://localhost:8089` in your
  browser. Bookmark it.
- **Add your photos:** put them in `photos → <your-name>` inside your
  home folder (the installer created it). They'll appear for everyone
  once they copy across.
- Everyone else's folders appear too — you can look, but you can't
  change or delete their photos. Only you control yours.

## Everyday use

- Everything starts automatically when your computer turns on — there's
  nothing to run.
- New photos people add just show up. Adding to your folder = sharing
  with the family.
- The gallery button only works on *your* computer at home — ask John
  if you want to see photos when you're away (that's a separate add-on).

## If something goes wrong

- **Nothing happens when I double-click (Mac):** right-click → Open.
- **Red text about "execution policy" (Windows):** you double-clicked
  the `.ps1` file instead of `photos-setup.cmd` — use the `.cmd` one.
- **"Command not found":** re-run the installer — it picks up where it
  left off.
- **Photos stopped appearing:** is the other computer on? The network
  only needs *one* member online, but nobody's computer = nobody's
  photos until someone comes back.
- **Anything else:** screenshot it and put it in the group chat.

## The honest fine print

- Everyone gets a full copy — your computer needs the disk space.
- Once photos have copied to a member's machine, removing that member
  stops *new* sharing but can't take back what they already have —
  like handing someone prints.
- You can leave anytime: uninstall Syncthing and delete your `photos`
  folder. Your shared photos stay with the family.
