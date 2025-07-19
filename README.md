# Dev Container Setup Script

> “It works on my machine” - Every developer, before using dev containers.

`setup.sh` is a shell script designed to streamline the setup of development containers by running initialization scripts from remote presets and local sources.

## Features

- Runs remote initialization scripts from a GitHub repository preset (under this repo /scripts).
- Runs local initialization scripts from your project's `.devcontainer/scripts` folder.

## Usage

```bash
./setup.sh [-p preset] [--preset=preset] [-l] [--list-presets] [-h] [--help]
````

### Options

| Option                         | Description                                                                                       |
| ------------------------------ | ------------------------------------------------------------------------------------------------- |
| `-p PRESET`, `--preset=PRESET` | Select a remote preset to run (e.g. `node`, `python`). Remote scripts from this preset run first. |
| `-l`, `--list-presets`         | List available remote presets and exit.                                                           |
| `-h`, `--help`                 | Show help message and exit.                                                                       |

---

## How to Use in `devcontainer.json`

Add a post-create or initialization command like this:

```json
"postCreateCommand": "sh -c \"curl -sSL https://raw.githubusercontent.com/RobinDeClerck/devcontainer/main/setup.sh | sh -s -- -p node\""
```

This will download and run the setup script with the `node` preset.

## Requirements

* Your project must contain a `.devcontainer/scripts/` folder.

* Add shell scripts inside `.devcontainer/scripts/` with names prefixed for ordering, e.g.:

  ```
  001-install.sh
  002-configure.sh
  003-finish.sh
  ```

* Ensure these scripts are executable and idempotent if possible.

## How It Works

1. **Remote Presets**
   If a preset is specified, the script fetches initialization scripts from the remote GitHub repo:
   `https://github.com/RobinDeClerck/devcontainer/tree/main/scripts/<preset>/`

2. **Local Scripts**
   Then, the script runs all shell scripts found in `.devcontainer/scripts` in alphabetical order.
   E.g.:
   ```
   001-install.sh
   002-configure.sh
   003-finish.sh
   ```

## Dependencies
   The script requires the following tools to be installed in the environment.
   It's recommended to add these to you dev container Dockerfile.

   * `curl`
   * `jq`
   * `lolcat`
   * `figlet`

   ```
   RUN apk add --no-cache npm -X http://dl-cdn.alpinelinux.org/alpine/edge/testing lolcat figlet
   ```
