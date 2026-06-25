# Devbox

这是一个面向个人使用的远程 AI 开发工作台。

它不是多人平台，也不是每个项目一个 sandbox。它的目标是：在远程服务器上长期运行一个 Docker devbox 容器，本地继续使用 JetBrains IDE，通过 Mutagen 双向同步代码，让 AI agent、Python/Node/TypeScript 工具链、测试和构建都运行在远程容器里。

## 工作流定位

```text
Mac / 本地机器
  ├── JetBrains IDE
  ├── iTerm2 / Termius
  ├── dsync
  └── 本地项目目录

        ⇅ Mutagen 双向同步

远程服务器
  └── devbox Docker 容器
       ├── /workspace/projects/<project-a>
       ├── /workspace/projects/<project-b>
       ├── Python / Node / TypeScript / shell tools
       ├── tmux
       ├── AI coding agents
       └── 持久化 home/cache/config
```

核心思路：

- 本地仍然用 JetBrains 打开本地项目目录。
- 远程 devbox 负责运行环境、AI agent、测试、构建和长期任务。
- 本地改代码，远程 agent 能看到。
- 远程 agent 改代码，本地 IDE 能看到。
- 状态保存在 tmux 里，iTerm2 和 Termius 只是 SSH 入口。
- 默认一个全局 devbox 承载多个项目，而不是一个项目一个容器。

## Quick Start

在远程服务器上准备 SSH 目录（整个 `./ssh/` 将直接挂载为容器的 `/root/.ssh`）：

```bash
mkdir -p ssh
# 方式一：只放 authorized_keys（最小方式）
cp ~/.ssh/id_ed25519.pub ssh/authorized_keys

# 方式二：复制完整的 SSH 配置（推荐）
cp ~/.ssh/id_ed25519 ssh/
cp ~/.ssh/id_ed25519.pub ssh/
cp ~/.ssh/authorized_keys ssh/
cp ~/.ssh/known_hosts ssh/
cp ~/.ssh/config ssh/
chmod 700 ssh
chmod 600 ssh/*
```

构建并启动 devbox：

```bash
cp .env.example .env
docker build -t devbox:latest .
docker compose up -d
```

本地 Mac 的 `~/.ssh/config` 配置固定 Host：

```sshconfig
Host devbox
  HostName <remote-server-host>
  User root
  Port 2222
  ServerAliveInterval 30
  ServerAliveCountMax 3
```

连接 devbox：

```bash
ssh devbox
```

如需个人 shell/editor 配置，建议从自己的 dotfiles 仓库运行时安装：

```bash
export DEVBOX_DOTFILES_REPO=git@github.com:<user>/<dotfiles-repo>.git
devbox-bootstrap-dotfiles
```

在本地项目目录启动同步：

```bash
dsync up
```

进入远程项目并启动 tmux：

```bash
ssh devbox
cd /workspace/projects/<project>
tmux new -A -s <project>
```

## 仓库内容

```text
.
├── Dockerfile              # devbox 镜像定义
├── docker-compose.yml      # 长期 devbox 容器配置
├── bin/                    # 容器启动和 dotfiles bootstrap 脚本
├── ssh/                    # SSH authorized_keys 示例和本地挂载目录
├── dsync                   # Mutagen 同步命令封装
├── .dsyncignore            # 默认同步忽略规则
├── .env.example            # compose 本地覆盖示例
├── CONTRIBUTING.md         # 贡献说明
├── SECURITY.md             # 安全边界和披露说明
└── LICENSE                 # 开源许可证
```

## Devbox 镜像

当前 `Dockerfile` 基于 `debian:bookworm-slim`，定位是可重建的基础镜像，而不是个人环境快照。它包含：

- 中文 locale：`zh_CN.UTF-8`
- SSH server/client
- `zsh`、`tmux`
- `git`、`vim` / `nano`、`ripgrep`、`fd`、`fzf`、`jq`、`rsync`、`unzip`
- Python 3、`pip`、`venv`、`pipx`、`uv`
- Node.js 22、npm、Corepack、pnpm
- JDK 17
- Docker CLI 和 Compose plugin（连接宿主机 Docker socket）
- `build-essential`
- `sshfs` / FUSE 相关能力
- `tini` 作为 init 进程

当前默认使用 `root` 作为 devbox 用户。这是为了个人开发和 AI agent 操作方便，是有意选择的高信任工作台模式，不是安全 sandbox。

`/root` 是持久 volume，因此镜像不会把 Oh My Zsh、agent 登录态或个人配置烘进最终 home。个人 shell/editor 偏好应通过运行时 dotfiles bootstrap 安装。

## 启动 devbox

在远程服务器上构建镜像：

```bash
cp .env.example .env
docker build -t devbox:latest .
```

启动容器：

```bash
docker compose up -d
```

查看容器：

```bash
docker ps
```

当前 compose 默认会把容器 SSH 暴露到宿主机 `2222` 端口，可通过 `.env` 覆盖：

```dotenv
DEVBOX_IMAGE=devbox:latest
DEVBOX_CONTAINER_NAME=devbox
DEVBOX_SSH_PORT=2222
```

## SSH 连接

建议在本地 Mac 的 `~/.ssh/config` 中配置一个固定 Host：

```sshconfig
Host devbox
  HostName <remote-server-host>
  User root
  Port 2222
  ServerAliveInterval 30
  ServerAliveCountMax 3
```

之后可以直接：

```bash
ssh devbox
```

`dsync` 默认也使用这个 Host：

```bash
DSYNC_REMOTE_HOST=devbox
```

### SSH key

SSH 公钥通过运行时挂载提供，避免把 key 写进镜像构建层：

```bash
mkdir -p ssh
cp ~/.ssh/id_ed25519.pub ssh/authorized_keys
docker compose up -d
```

仓库只保留 `ssh/authorized_keys.example`，真实 `ssh/authorized_keys` 会被 `.gitignore` 忽略。

`docker-compose.yml` 默认把 `./ssh/` 只读挂载到 `/run/devbox/ssh`，entrypoint 启动时把所有 SSH 文件复制到 `/root/.ssh/` 并修正权限（复制后 owner 为 root，满足 sshd 的权限要求）。这样 `./ssh/` 里的私钥、公钥、authorized_keys、known_hosts 和 config 都会在容器内可用。

## dsync

`dsync` 是基于 Mutagen 的同步封装，用于把当前本地项目目录同步到远程 devbox。

默认规则：

```text
local:   当前目录
remote:  devbox:/workspace/projects/<当前目录名>
session: dsync-<remote-project-name>-<本地路径 hash>
mode:    two-way-resolved
```

例如在本地项目 `foo` 目录中执行：

```bash
dsync up
```

会启动一个后台同步 session，并同步到：

```text
devbox:/workspace/projects/foo
```

如果想前台观察同步状态，使用：

```bash
dsync monitor
```

### 前置依赖

本地需要安装 Mutagen：

```bash
brew install mutagen-io/mutagen/mutagen
```

也可以先运行诊断：

```bash
dsync doctor
```

### 命令

```bash
dsync up       # 启动当前项目同步并退出
dsync down     # 停止当前项目同步
dsync status   # 查看当前项目同步状态
dsync flush    # 强制 flush 同步
dsync reset    # 重建同步 session
dsync pause    # 暂停同步
dsync resume   # 恢复同步
dsync monitor  # 前台观察同步状态
dsync doctor   # 检查 Mutagen、SSH、远程项目根目录和当前配置
```

`dsync up` 遇到已有同名 session 时不会自动重建；如需重建，显式执行 `dsync reset`。

### 配置

可以通过环境变量覆盖默认配置：

```bash
DSYNC_REMOTE_HOST=devbox
DSYNC_REMOTE_BASE_DIR=/workspace/projects
DSYNC_REMOTE_NAME=<当前目录名>
DSYNC_SYNC_MODE=two-way-resolved
```

`DSYNC_REMOTE_NAME` 是远程项目目录名，只允许字母、数字、点、下划线和连字符。`DSYNC_REMOTE_BASE_DIR` 必须是绝对路径，且不能是 `/`。

也可以在项目目录下创建 `.dsyncrc`：

```bash
DSYNC_REMOTE_HOST=devbox
DSYNC_REMOTE_BASE_DIR=/workspace/projects
DSYNC_REMOTE_NAME=foo-api
DSYNC_SYNC_MODE=two-way-resolved
```

`.dsyncrc` 会作为 shell 文件加载，只应在受信任的本地项目中使用。

### 忽略规则

`dsync` 会加载：

1. 全局 `~/.dsyncignore`
2. 当前项目 `.dsyncignore`

本仓库提供了一份 `.dsyncignore` 示例，主要忽略：

- Python 虚拟环境和缓存
- `node_modules`
- Java/Gradle/Maven 缓存
- Rust `target`
- 构建产物
- IDE 和系统临时文件

当前没有默认读取项目 `.gitignore`，因为 `.gitignore` 不一定等同于“不同步规则”。

## tmux 使用方式

平时可以 SSH 进入 devbox，然后进入项目目录和 tmux 会话：

```bash
ssh devbox
cd /workspace/projects/<project>
tmux new -A -s <project>
```

推荐按项目组织 tmux：

```text
session: <project>
  window: agent
  window: shell
  window: server
  window: test
  window: logs
```

对于特别长期或独立的 AI 任务，也可以单独开 session：

```text
<project>
<project>-agent-login
<project>-agent-refactor
<project>-logs
```

建议把长期运行的 AI agent、测试 watcher、开发服务器都放在 tmux 里，而不是依赖本地终端窗口。

## JetBrains + AI agent 协作

典型流程：

1. 本地 JetBrains 打开项目目录。
2. 在项目目录执行 `dsync up`。
3. SSH 进入 devbox。
4. 进入 `/workspace/projects/<project>`。
5. 在 tmux 中启动 AI coding agent。
6. AI agent 修改远程文件。
7. Mutagen 同步回本地。
8. 本地 JetBrains 实时查看、编辑、审查改动。

这个流程的核心价值是：

- 保留本地 JetBrains 体验。
- AI agent 在远程稳定运行。
- 人和 agent 围绕同一份代码实时协作。
- 不需要为了让远程看到代码而频繁 push/pull。

## 关于 `.git` 同步

当前方案倾向同步 `.git`，因为这样可以做到：

- 本地切分支后，远程 devbox 立即看到同样代码状态。
- 本地未 push 的分支和提交也能被远程 agent 使用。
- 不需要污染团队远端仓库。

但这也有风险：

- `git worktree` metadata 可能包含本地/远程机器相关路径。
- 多 agent 并行改多个 worktree 时，Mutagen 和 Git metadata 可能冲突。
- 本地和远程同时做复杂 Git 操作时，需要更谨慎。

当前建议：

- 单工作区日常开发可以继续同步 `.git`。
- 多 worktree / 多 agent 并行先不要作为默认流程。
- 如果要支持并行任务，后续应在 `dsync` 中显式建模 worktree/session，而不是让 agent 随意创建远程 worktree。

## 安全说明

当前 `docker-compose.yml` 使用了较高权限配置：

- `privileged: true`
- `/dev/fuse`
- `SYS_ADMIN`
- 挂载 `/var/run/docker.sock`

这些配置适合个人高信任 devbox，但不适合不可信代码或多人共享环境。

特别注意：挂载 Docker socket 后，容器内进程基本具备控制宿主机 Docker 的能力。AI agent 如果能访问 Docker socket，也应视为拥有很高权限。

## 持久缓存

`docker-compose.yml` 使用 devbox 自己的 named volumes 保存常见依赖缓存，而不是挂载宿主机用户目录：

- `devbox_gradle` → `/root/.gradle`
- `devbox_m2` → `/root/.m2`
- `devbox_npm` → `/root/.npm`
- `devbox_pnpm` → `/root/.local/share/pnpm`
- `devbox_uv` → `/root/.local/share/uv`

这样镜像可以重建，依赖缓存也能跨容器保留，并且不依赖宿主机 `$HOME` 的路径和状态。

## 私人 dotfiles

基础镜像不预装 Oh My Zsh、主题、插件、`.zshrc`、`.vimrc` 或其他个人配置。需要个性化环境时，在容器内手动从自己的 dotfiles 仓库安装：

```bash
export DEVBOX_DOTFILES_REPO=git@github.com:<user>/<dotfiles-repo>.git
devbox-bootstrap-dotfiles
```

默认会 clone 或 fast-forward 更新到 `/root/.dotfiles`。如果仓库里有可执行的 `./install` 或 `./bootstrap`，命令会自动执行；也可以显式指定应用命令：

```bash
devbox-bootstrap-dotfiles -- ./bootstrap
```

## 可恢复性

这个 devbox 是长期工作台，不追求完全不可变，但应尽量做到可恢复。

建议原则：

- 高频基础工具写进 `Dockerfile`。
- `/root`、`/workspace`、缓存和配置用 volume 持久化。
- 个人 shell/editor 偏好放到私人 dotfiles，不写进基础镜像。
- AI agent 或手动安装的新工具定期记录。
- 容器坏了时，至少能根据 Dockerfile、volume 和环境快照恢复主要状态。

后续可以增加命令：

```bash
devbox snapshot  # 记录当前环境包和工具版本
devbox diff      # 比较环境快照差异
devbox audit     # 从 shell history 中找安装命令
```

可记录内容包括：

```bash
dpkg --get-selections
npm list -g --depth=0
pnpm list -g --depth=0
uv tool list
pipx list
python3 --version
node --version
npm --version
```

也可以要求 AI agent 如果安装系统或全局工具，记录到：

```text
~/.devbox/install-log.md
```

建议规则：

```text
If you install system or global tools, record the command and reason in ~/.devbox/install-log.md.
Prefer project-local dependencies over global installs.
Ask before installing large system packages.
```

## 未来计划

可能的增强方向：

- 给 `dsync` 增加 `shell` 命令，直接进入远程项目目录。
- 给 `dsync` 增加 `tmux` / `agent` 命令，直接 attach 当前项目会话。
- 给 `dsync` 增加 `doctor`，检查 SSH、Mutagen、远程目录和权限。
- 给 `dsync` 增加更清晰的 session 命名，例如 `dsync-<project>-<hash>`。
- 设计多 agent / worktree 并行模式。

## 开源发布检查

发布前建议确认：

```bash
bash -n dsync bin/devbox-entrypoint bin/devbox-bootstrap-dotfiles
docker compose config >/dev/null
```

如修改了镜像内容，再执行：

```bash
docker build -t devbox:latest .
```

仓库按 MIT License 发布，贡献说明见 `CONTRIBUTING.md`，安全边界见 `SECURITY.md`。

## 当前适用边界

适合：

- 个人远程开发环境
- Mac + JetBrains 用户
- 长期运行 AI coding agent
- 多项目共享一个远程工具链
- 希望本地和远程实时双向看代码

不适合：

- 多人隔离环境
- 不可信代码执行平台
- 强安全边界 sandbox
- 每个项目都要求完全独立系统依赖
- 需要严格可复现的生产构建环境

## 社区

本项目认可并支持 LINUX DO 社区：<https://linux.do/>
