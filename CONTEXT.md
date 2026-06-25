# Devbox

Devbox is a personal remote development workspace for running coding tools, AI agents, tests, builds, and long-lived terminal sessions while the developer keeps editing locally.

## Language

**Devbox**:
A personal remote development workspace owned by one developer and shared across that developer's projects.
_Avoid_: Sandbox, project container, multi-user platform

**Local Project Directory**:
The project copy opened by the developer's local editor and kept in sync with the remote workspace.
_Avoid_: Source of truth, local sandbox

**Remote Project Workspace**:
The project copy inside the Devbox where agents, tools, tests, builds, and long-running processes operate.
_Avoid_: Deployment environment, production runtime

**Remote Project Name**:
The directory name used to identify a Remote Project Workspace within the Devbox's project collection.
_Avoid_: Workspace name, session name, project ID

**Synchronization Session**:
A live bidirectional relationship between a Local Project Directory and its corresponding Remote Project Workspace.
_Avoid_: Backup job, deploy, one-way upload

**Base Image**:
A rebuildable image that provides the shared operating system, language runtimes, and durable startup behavior for a Devbox without owning personal workspace state.
_Avoid_: Golden image, environment snapshot, project image

**Personal Dotfiles**:
A developer-owned set of shell, editor, Git, and tool preferences used to personalize a Devbox without changing its shared base capabilities.
_Avoid_: Base image contents, project configuration, environment snapshot

**Dotfiles Bootstrap**:
A developer-triggered setup step that applies Personal Dotfiles to a Devbox after the Base Image has provided the required tooling.
_Avoid_: Container startup, image build step, automatic sync

**Trusted Root Workspace**:
A Devbox operating model where the developer intentionally uses root inside a personal, high-trust environment for low-friction tooling and agent operation.
_Avoid_: Security sandbox, least-privilege platform, shared host

**Shared Toolchain**:
The cross-project language runtimes, package managers, and diagnostic tools provided by the Base Image for general development work.
_Avoid_: Project dependencies, personal tool state, agent login state

**Dependency Cache Volume**:
A persistent Devbox-owned cache for package managers and build tools that survives container rebuilds without binding to the host user's home directory.
_Avoid_: Host cache mount, project dependency, image layer
