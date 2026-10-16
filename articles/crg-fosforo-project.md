---
title: "fosforo: データを収集しない macOS・iPadOS・iOS 向けターミナルエミュレータ"
emoji: "🔥"
type: "tech"
topics: ["swift", "c", "ios", "macos", "terminal"]
published: true
---

fosforo is a terminal emulator for macOS, iPadOS and iOS, written in C and Swift and drawn with Metal.

On the Mac it is a fast terminal made for developers: your login shell on a pty, with the system's ssh and git, several sessions per window, search, copy mode and shell integration.

On the iPad and iPhone the shell is [rocchetto](https://github.com/crgimenes/rocchetto), built into the app: pipes, redirects, functions, history, and sixty-odd commands written in [Filo](https://github.com/crgimenes/filo). The `ssh` and `mosh` commands are the app's own clients, and private keys can be kept encrypted by a key in the device's Secure Enclave, opened with Face ID, Touch ID or the passcode.

Configuration and themes are Filo scripts. The default font is IBM 3270; box drawing, blocks, braille and Powerline glyphs are drawn from geometry, so ANSI art has no seams.

The Mac app is signed and notarized, for Apple silicon and Intel (`brew install --cask crgimenes/tap/fosforo`). The iPad and iPhone app is on its way to the App Store. MIT licensed.

## Privacy

fosforo collects no data. It has no analytics, no crash reporting, no advertising and no accounts; nothing is sent to its author or to any partner.

- The app connects only to the machines you name, or that a program you run asks for: what an SSH or Mosh session carries goes to that server, encrypted.
- Files you put in the app's iCloud Drive folder (`~/iCloud`) are stored by Apple in your own iCloud account; the rest of the home, `~/.ssh` and `~/.config` included, stays on the device.
- SSH keys live in `~/.ssh` inside the app, readable only by it (mode 0600, the strictest file protection iOS offers) and left out of device backups, so they do not travel to a new device. A key is a plain file until you run `key protect`: then it is sealed by this device's Secure Enclave and each use asks for Face ID, Touch ID or the passcode; the app never sees biometric data. On a device with no passcode the seal still works, but nothing is asked; the app says so.
- Removing the app removes everything it stored on the device; files in your iCloud Drive folder stay there until you delete them.

Questions about privacy: [open an issue](https://github.com/crgimenes/fosforo/issues).
