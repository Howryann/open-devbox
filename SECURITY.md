# Security Policy

## Supported Use

Devbox is designed for a single developer's trusted remote workspace. It is not a sandbox, not a multi-tenant service, and not suitable for running untrusted workloads.

## Important Risks

The default `docker-compose.yml` intentionally enables high-privilege capabilities:

- `privileged: true`
- `/dev/fuse`
- `SYS_ADMIN`
- `/var/run/docker.sock` mounted into the container
- root SSH login with public-key authentication

Anyone who can execute code inside the container should be treated as highly privileged on the host, especially because access to the Docker socket can lead to host-level control.

## Secret Handling

Do not commit secrets to this repository. In particular, avoid committing:

- private SSH keys
- real `authorized_keys` files
- API tokens
- `.env` files with credentials
- private dotfiles with credentials or service logins

Use runtime mounts and local ignored files for secrets.

## Reporting Issues

If you find a security issue, please avoid publishing exploit details in a public issue. Contact the repository maintainer privately when possible, or open a minimal public issue requesting a private disclosure channel.
