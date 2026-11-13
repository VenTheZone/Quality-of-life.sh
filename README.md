# Quality-of-Life Scripts

This repository contains a collection of handy scripts designed to improve quality of life in the terminal.

## Scripts

### File Management & Navigation
| Script                | Description                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `cdg.sh`              | Selects a directory via `fzf` and changes the current directory to it.                                      |
| `cg.sh`               | Selects a file via `fzf` and displays its contents.                                                         |
| `nav.sh`              | Advanced directory navigator with enhanced browsing capabilities.                                          |
| `locatefile.sh`       | Locates files in the current directory and subdirectories whose names match a given pattern.                  |
| `findtext.sh`         | Searches for files in the current directory and subdirectories that contain a given text.                   |
| `ls-cols.sh`          | Displays a two-column directory listing with directories on the left and files on the right, sorted by modification time. |

### Video & Media Processing
| Script                | Description                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `video_compress.sh`   | Compresses a video file to a target size using `ffmpeg`.                                                    |
| `Video_Quality.sh`    | Converts video resolution with quality presets.                                                            |
| `dl.sh`               | Downloads a video from a given URL using `yt-dlp` through `proxychains`.                                    |
| `yt.sh`               | Downloads a YouTube video, replacing spaces in the filename with underscores.                               |

### Development & Git
| Script                | Description                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `git-clean-branch.sh` | Interactively cleans up local and remote git branches, keeping only `main` or `master`.                       |

### Security & Utilities
| Script                | Description                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `secure.c`            | A C program that provides secure file encryption and decryption using modern cryptographic libraries.         |
| `newPW.sh`            | Generates five random passwords and displays them in a sorted list.                                         |
| `microfetch.c`        | Ultra-lightweight system information tool designed for embedded systems.                                    |

### Network & Cloud Services
| Script                | Description                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `upload_file_0x0.sh`  | Uploads a file to `0x0.st` and copies the resulting URL to the clipboard.                                   |
| `upload_url_0x0.sh`   | Uploads a URL to `0x0.st` to shorten it and copies the resulting URL to the clipboard.                      |
| `sync_notes.sh`       | Synchronizes Obsidian vault with remote storage.                                                            |

### Docker & Container Management
| Script                | Description                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `open-webui.sh`       | Launches Open WebUI Docker container for AI model management.                                              |

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

## Microfetch
 Download and compile
```gcc -Os -static -s microfetch.c -o microfetch```


 (Optional) Install system-wide
```sudo cp microfetch /usr/local/bin/```

 For ARM embedded systems
```arm-linux-gnueabi-gcc -Os -static -s microfetch.c -o microfetch-arm ```

## Video Processing Options

This collection includes two different approaches to video processing:

- **Size-based compression** (`video_compress.sh`): Compresses videos to a target file size while maintaining quality
- **Resolution-based conversion** (`Video_Quality.sh`): Changes video resolution with quality presets

Choose the appropriate script based on whether you need to control file size or resolution.

## Security & Encryption

The `secure.c` program provides comprehensive file encryption and decryption capabilities. Compile it with:

```bash
gcc secure.c -o secure -lssl -lcrypto
```

## Docker Integration

The `open-webui.sh` script manages Open WebUI containers for local AI model management, requiring Docker to be installed and running.
