# Contributing

Thanks for taking the time to improve Devbox.

## Scope

Devbox is intentionally a personal, high-trust remote development workspace. Please keep changes aligned with that scope:

- Optimize for one developer using one long-lived devbox across multiple projects.
- Do not turn the project into a multi-user platform or a security sandbox.
- Keep the base image rebuildable and avoid baking personal state into it.
- Prefer explicit documentation for high-privilege behavior.

## Development

Useful local checks before opening a pull request:

```bash
bash -n dsync bin/devbox-entrypoint bin/devbox-bootstrap-dotfiles
docker compose config >/dev/null
docker build -t devbox:latest .
```

If your change affects the image, also verify a container can start and accept SSH key based login.

## Documentation

- Update `README.md` when commands, environment variables, volumes, ports, or workflows change.
- Update `CONTEXT.md` when terminology changes.
- Keep examples generic. Do not include real hosts, private repository URLs, tokens, or SSH keys.

## Pull Requests

Please include:

- What changed and why.
- Any security implications, especially around Docker socket access, `privileged`, FUSE, SSH, or root usage.
- The checks you ran.
