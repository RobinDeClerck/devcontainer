# devbase

> _"It works on my machine."_ — Famous last words, before dev containers.

A shared Alpine-based dev container image with a friendly terminal banner, [Starship](https://starship.rs) prompt, and language presets that auto-install dependencies on attach.

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

## License

MIT — © Robin De Clerck
