# Devcontainer - devbase

> _"It works on my machine."_ — Famous last words, before dev containers.

A shared Alpine-based dev container image with a friendly terminal banner, [Starship](https://starship.rs) prompt, and language presets that auto-install dependencies on attach.

![devbase terminal](docs/terminal.png)

## Use it

In any project's `.devcontainer/devcontainer.json`:

```jsonc
{
  "image": "ghcr.io/robindeclerck/devbase:latest",
  "containerEnv": { "DEVBASE_PRESETS": "python" },
  "postAttachCommand": "bash -lc terminal"
}
```

Need extra tools? Extend it with a project-local Dockerfile:

```dockerfile
FROM ghcr.io/robindeclerck/devbase:latest
RUN apk add --no-cache python3 py3-pip && \
    rm -f /usr/lib/python*/EXTERNALLY-MANAGED
```

## Presets

`DEVBASE_PRESETS` is comma-separated. Each preset runs on attach.

| Preset   | What it does                                                                 |
| -------- | ---------------------------------------------------------------------------- |
| `python` | Installs `requirements-dev.txt` if present, else `requirements.txt`.         |
| `node`   | Runs `npm ci` if `package-lock.json` exists, else `npm install`.             |

If a preset's runtime is missing, you get a friendly hint pointing at the Dockerfile line you need.

## What's in the image

- `bash`, `gum`, `starship`, `figlet`, `lolcat`
- `openssh-client`, `ca-certificates`
- `terminal` — banner + system info + git info + daily tip on shell start

## Command-line

Scaffold a new project's `.devcontainer/` interactively:

```bash
bash -c "$(curl -fsSL "https://raw.githubusercontent.com/RobinDeClerck/devcontainer/main/templates/init.sh?$(date +%s)")"
```

Walks you through name, slug, and preset, then drops `.devcontainer/devcontainer.json`, `Dockerfile`, `docker-compose.override.yml`, and `docker-compose.yml` into the current directory.

Requires [`gum`](https://github.com/charmbracelet/gum) — the script will offer to install it via Homebrew if missing.

## Develop

```bash
git clone git@github.com:RobinDeClerck/devcontainer.git
# Open in VS Code → Reopen in Container
```

Tag a release to publish a new image to GHCR:

```bash
git tag v0.2.0
git push origin v0.2.0
```

To see existing tags:

```bash
git tag --sort=-creatordate -l --format='%(creatordate:short) %(refname:short)'
```

To republish an existing tag:

```bash
git tag -d v0.2.0                  # delete local
git push origin :refs/tags/v0.2.0  # delete remote
git tag v0.2.0                     # recreate
git push origin v0.2.0             # push again
```

> Note: anyone who already pulled `v0.2.0` won't get the update automatically — bump the version instead if that matters.

## License

MIT — © Robin De Clerck
