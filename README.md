# Quality-of-Life Scripts

This repository contains a collection of habdy scripts designed to improve quality of life in the terminal.

## Scripts

| Script                | Description                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `cdg.sh`              | Selects a directory via `fzf` and changes the current directory to it.                                      |
| `cg.sh`               | Selects a file via `fzf` and displays its contents.                                                         |
| `video_compress.sh`   | Compresses a video file to a target size using `ffmpeg`.                                                    |
| `dl.sh`               | Downloads a video from a given URL using `yt-dlp` through `proxychains`.                                    |
| `findtext.sh`         | Searches for files in the current directory and subdirectories that contain a given text.                   |
| `git-clean-branch.sh` | Interactively cleans up local and remote git branches, keeping only `main` or `master`.                       |
| `locatefile.sh`       | Locates files in the current directory and subdirectories whose names match a given pattern.                  |
| `ls-cols.sh`          | Displays a two-column directory listing with directories on the left and files on the right, sorted by modification time. |
| `newPW.sh`            | Generates five random passwords and displays them in a sorted list.                                         |
| `secure.c`            | A C program that provides secure file encryption and decryption using modern cryptographic libraries.         |
| `upload_file_0x0.sh`  | Uploads a file to `0x0.st` and copies the resulting URL to the clipboard.                                   |
| `upload_url_0x0.sh`   | Uploads a URL to `0x0.st` to shorten it and copies the resulting URL to the clipboard.                      |
| `yt.sh`               | Downloads a YouTube video, replacing spaces in the filename with underscores.                               |

## Usage

To use these scripts, you can either run them directly from the `Quality-of-life` directory, or you can add the `Quality-of-life` directory to your `PATH` to make them accessible from anywhere in your terminal.

For example, to use the `cg.sh` script, you could run:

```bash
./Quality-of-life/cg.sh
```

If you add the directory to your `PATH`, you can simply run:

```bash
cg.sh
```
