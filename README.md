# Quality-of-life.sh

Small terminal commands with fzf pickers, previews and gum prompts, packaged with Nix.
Type `qol` to list them and pick one.

## Commands

| Command | Does |
|---|---|
| `cdg` | Jump to a folder with fzf and a tree preview (zsh function) |
| `cg` | Pick a file with a highlighted preview, then read it |
| `compress` | Shrink a video to a target size or resolution, picked with a thumbnail preview |
| `dl` | Download a video or its audio with yt-dlp |
| `ff` | Find files by name with fd and a preview; prints the picked paths |
| `ft` | Search text live with ripgrep; Enter opens the match in your editor |
| `lc` | List folders and files side by side, newest first |
| `pw` | Generate passwords, pick one, copy it to the clipboard |
| `qol` | List these commands; pick one to run it |
| `up` | Upload a file to Litterbox or shorten a URL with TinyURL, and copy the link |
| `vault` | Encrypt or decrypt a file or folder with a passphrase (age) |

## Try one

```bash
nix run github:VenTheZone/Quality-of-life.sh            # qol: the list
nix run github:VenTheZone/Quality-of-life.sh#compress   # any command by name
```

## Install

With Home Manager (installs every command, the `cdg` zsh function and the `QOL` alias):

```nix
# flake.nix
inputs.qol = {
  url = "github:VenTheZone/Quality-of-life.sh";
  inputs.nixpkgs.follows = "nixpkgs";
};

# your Home Manager user
imports = [ inputs.qol.homeModules.default ];
```

Without Home Manager, `nix profile install github:VenTheZone/Quality-of-life.sh` installs the commands
(not `cdg`, which has to be a shell function to change your shell's folder).

## Notes

- Pickers, prompts and `pw`, `up`, `vault`, `dl`, `compress` need a terminal. `qol` prints the plain
  list when its output is piped or you pass `--list`.
- `compress` writes `<name>.compressed.mp4` next to the video (`.compressed-1.mp4` and so on when
  that name is taken) and never overwrites. Size targets (10, 25, 50 MB or your own) use two-pass
  x264 aimed at the size, and a video already under the target is left alone. 1080p, 720p and 480p
  use CRF 23 and never upscale. It refuses a video whose duration it cannot read. The picker shows
  a thumbnail (kitty graphics in kitty, chafa elsewhere).
- `up` asks before anything goes public, and its default answer is no. Litterbox files stay online
  for 1, 12, 24 or 72 hours (1 GB at most). Anyone with a link can
  open it. The link is copied to the clipboard under Wayland and shown otherwise.
- `vault` uses age with a passphrase: `vault notes/` makes `notes.tar.age`, `vault notes.tar.age`
  restores it without overwriting existing files. After encrypting it asks for the passphrase
  again to compare the archive with the original, and only then offers to delete the original
  (default no).
- `pw` takes a length from 8 to 128 (default 20), offers six passwords and shows the one you pick.
  It copies that one to the clipboard under Wayland.
- `dl` asks for a quality for video (Best, 1080p, 720p, 480p, 360p; a video with nothing that
  small gets its best) and shows one status line that redraws in place: a bar, speed, time left
  and the height, then a ✓ line per finished file. yt-dlp's warnings and errors print above it.
- `dl` saves in the current folder. To send some sites elsewhere, list them in
  `~/.config/qol/dl-routes`, one `<domain> <folder>` per line (`#` starts a comment, `~` is your
  home). A link to that domain or any subdomain of it saves in that folder; the first match wins.
- `ft` opens a match as `$EDITOR +LINE -- FILE` (nvim when `$EDITOR` is unset).

## Adding a command

1. Add `bin/<name>`: line 1 `#!/usr/bin/env bash`, line 2 `# qol: <one-line description>`, then
   `# shellcheck source=/dev/null` and `. "$QOL_LIB"` for the shared helpers in `lib/ui.sh`.
2. Add its tools to `deps` in `flake.nix`.
3. Add a row to the table above and, for any logic, `tests/<name>.test.sh`.
4. `git add` the new files, then run `nix flake check`, which shellchecks every command and runs
   the tests. Flakes only see git-tracked files, so an untracked `bin/<name>` is skipped and the
   check passes without covering it.

## License

MIT, see [LICENSE](LICENSE).
