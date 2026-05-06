# Watermarkr

**A tiny helper that auto-watermarks every screenshot you take on your Mac.**

Have you ever shared a screenshot and wished it had your name on it — like a little signature in the corner? That's what this tool does, automatically. You take a screenshot the way you always do, and a tiny invisible helper adds your watermark to it. You don't have to remember anything, click anything, or open any app.

## What's a watermark?

A watermark is a small label — usually your name or logo — that sits in the corner of a picture. It tells people who made it. Photographers and designers use them all the time.

This tool puts something like `© Your Name` in the bottom-right corner of every screenshot you take.

```
Before:  [your screenshot]
After:   [your screenshot] ............................. © Your Name
```

The original screenshot is replaced with the watermarked one. There's no extra file to clean up.

## How it works (in plain English)

Your Mac has a folder where every screenshot you take is saved (usually your Desktop). This tool sets up a tiny background helper that:

1. **Watches that folder.** Like a friendly assistant who only does one thing — keep an eye on the folder and wait.
2. **Notices when a new picture appears.** The moment you take a screenshot, the helper sees it.
3. **Adds your watermark.** It writes your name in the corner of the picture, in nice clean text.
4. **Done.** The picture is now watermarked. You didn't have to lift a finger.

The helper starts automatically every time you turn on your Mac. You can forget it exists — it just works.

## Before you start: install two free tools

This tool needs two helpers to do its job. They're free, safe, and used by millions of people. To install them, you'll use a program called **Homebrew**, which is the standard way Mac users install command-line tools.

### Step 1: Install Homebrew (if you don't have it)

Open the **Terminal** app (press `Cmd + Space`, type "Terminal", press Enter). Then copy and paste this line into the Terminal and press Enter:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

It might ask for your Mac password — that's normal. Wait until it finishes (a few minutes).

> Already have Homebrew? Skip this step.

### Step 2: Install the two helpers

In the same Terminal window, run:

```bash
brew install fswatch imagemagick
```

That installs:
- **fswatch** — the bit that watches your folder for new files
- **imagemagick** — the bit that draws the watermark on the picture

Wait for it to finish. You'll see the prompt come back when it's done.

## Step by step: get the watermark running

### 1. Download this folder

[**Download the latest release here**](https://github.com/aleao-sl/watermarkr/releases/latest) — on that page, scroll down to the **Assets** section and click **Source code (zip)**.

Once it downloads, unzip it and put the folder somewhere stable on your Mac (your home folder is a good spot) — somewhere you won't accidentally move or delete it.

> ⚠️ Don't move the folder after setup. The helper remembers where you put it. If you do move it, just run the setup again from the new location.

### 2. Open Terminal in that folder

In Finder, find the folder you just downloaded. Right-click it and choose **"New Terminal at Folder"**. (If you don't see that option, open Terminal and type `cd ` followed by dragging the folder into the Terminal window, then press Enter.)

### 3. Run the setup

Type this and press Enter:

```bash
./setup.sh
```

The setup will ask you a few simple questions. Each one shows a suggested answer in `[brackets]`. **If the suggestion looks fine, just press Enter.** If you want to change it, type something different and press Enter.

The questions are:

- **Watermark text** — what you want written on the screenshot. For example: `© Maria Silva`
- **Watch directory** — the folder where your screenshots get saved. The setup figures this out for you automatically. Press Enter to accept.
- **Log file path** — where the helper writes its diary (so you can check what it did). Press Enter to accept.
- **Font file path** — what kind of letters to use. Press Enter to accept.

That's it. Setup will turn the helper on and tell you "Loaded LaunchAgent..." when it's running.

### 4. Try it out

Take a screenshot the way you always do — `Cmd + Shift + 4` and drag a box, or `Cmd + Shift + 3` for the whole screen. Open the screenshot. You should see your watermark in the bottom-right corner.

🎉 You're done. From now on, every screenshot you take gets watermarked automatically.

## Changing your settings later

Want to update your watermark text, or change which folder it watches? Just open Terminal in the folder again and run:

```bash
./setup.sh
```

It will show your current settings as the suggestions. Type new answers for the things you want to change, press Enter for the rest. The helper restarts itself with the new settings.

## Turning it on and off

If you want to **pause** the watermark helper temporarily, open Terminal and run:

```bash
launchctl unload ~/Library/LaunchAgents/com.<your-username>.watermarkr.plist
```

Replace `<your-username>` with your Mac username. (Not sure? Type `whoami` in Terminal — it'll tell you.)

To **turn it back on**:

```bash
launchctl load ~/Library/LaunchAgents/com.<your-username>.watermarkr.plist
```

## Removing it completely

If you ever want to uninstall:

```bash
launchctl unload ~/Library/LaunchAgents/com.<your-username>.watermarkr.plist
rm ~/Library/LaunchAgents/com.<your-username>.watermarkr.plist
```

Then drag the project folder to the Trash. Done.

## Is this safe? What does it actually do to my Mac?

Short answer: yes. This tool does **not** modify any system files, does **not** install kernel extensions, and does **not** change anything in macOS itself. It runs entirely inside your own user account and never asks for an admin password.

Here's exactly what gets added to your Mac, and where:

### The two helpers (installed by Homebrew)

- **fswatch** — a small open-source tool that watches folders for changes. Lives at `/opt/homebrew/bin/fswatch`. Source: [github.com/emcrisostomo/fswatch](https://github.com/emcrisostomo/fswatch)
- **imagemagick** — a well-known open-source image toolkit, around since 1987 and used widely by photographers, websites, and developers. Source: [imagemagick.org](https://imagemagick.org)

Both are installed by Homebrew into `/opt/homebrew/` (or `/usr/local/` on Intel Macs). They are general-purpose tools, not specific to this project — you might already have them for other reasons. You can uninstall them anytime with `brew uninstall fswatch imagemagick`.

### The background helper (the LaunchAgent)

A **LaunchAgent** is the standard, Apple-supported way for any Mac program to run quietly in the background. It's the same mechanism that Dropbox, 1Password, Slack and most Mac apps use. It's documented and supported by Apple — it is not a hack or a workaround.

This tool installs **one** LaunchAgent file at:

```
~/Library/LaunchAgents/com.<your-username>.watermarkr.plist
```

That file lives in **your user folder** — not in any system directory. It simply tells macOS: "when this user logs in, run `watermarkr.sh`, and restart it if it crashes." That's the entire job.

### What this tool does NOT do

- It does not modify any system files (nothing in `/System` or any other system directory)
- It does not require an admin password (no `sudo` is used or needed)
- It does not connect to the internet
- It does not collect or send any data anywhere
- It does not access any files outside the folder you tell it to watch
- It does not run as root or with elevated privileges

### Removing everything

To remove the LaunchAgent, see "Removing it completely" above. To also remove the dependencies, run `brew uninstall fswatch imagemagick` — your Mac will be exactly how it was before.

## If something doesn't work

Don't worry — most problems are easy to fix.

**"Missing dependencies"** when running setup
You skipped or missed the Homebrew step. Run:
```bash
brew install fswatch imagemagick
```
…and try `./setup.sh` again.

**Watermark not appearing on screenshots**
Open the log file (the path you set during setup, usually `watermarkr.log` in the project folder) and look at the last few lines. It usually says exactly what went wrong — for example, that it couldn't find your screenshots folder.

You can read the log live by running this in Terminal:
```bash
tail -f /path/to/watermarkr/watermarkr.log
```
(Replace `/path/to/watermarkr/` with where you put the folder.)

**"setup has not been run yet"**
Run `./setup.sh` from the project folder.

**You changed something and nothing happened**
Run `./setup.sh` again — it tells the helper to reload with the new settings.

## What the watermark looks like

- **Position:** bottom-right corner
- **Style:** semi-transparent white text with a thin dark outline (so it's readable on any background — light, dark, or busy)
- **Size:** 27pt — visible but not in your face
- **Font:** Mona Sans (a modern, friendly font), or any TTF font you choose

## Which kinds of pictures it works on

It watermarks all the common image types your Mac can produce:

`.png` `.jpg` `.jpeg` `.gif` `.bmp` `.tiff` `.tif` `.webp` `.heic`

Other files (PDFs, videos, documents) are left alone.

## Files in this project

| File | What it's for |
|------|---------------|
| `setup.sh` | The setup wizard you run once |
| `watermarkr.sh` | The actual helper that watches your folder |
| `watermarkr.conf` | Your saved settings (gets created during setup) |
| `MonaSans-Regular.ttf` | The font for the watermark text |
| `watermarkr.log` | The diary of what the helper has done (gets created automatically) |
| `watermarkr.conf.example` | A reference showing what a config file looks like |
| `LICENSE` | Project license (MIT) |
| `MonaSans-LICENSE.txt` | License for the bundled Mona Sans font (SIL OFL 1.1) |

You don't need to open or edit any of these by hand — `setup.sh` does everything for you.

## Disclaimer

This software is provided **"as is"**, without warranty of any kind, express or implied. Use of this tool is **at your own risk** and your **own responsibility**. The author is not liable for any data loss, file corruption, lost screenshots, or any other damages that may arise from using this software, however caused.

A few things to keep in mind:

- The tool modifies image files **in place** — the original screenshot is overwritten with the watermarked version. There is no automatic backup. If your screenshots are important to you, back them up separately.
- The tool watches the folder you point it at and will watermark any image that appears there. If you store other people's images in that folder, they will also be watermarked.
- The full source code is in this folder and is short enough to read in a few minutes. You are encouraged to review `setup.sh` and `watermarkr.sh` yourself before running them.

By using this software, you agree to the terms of the [MIT License](LICENSE).
