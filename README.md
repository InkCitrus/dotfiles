# dotfiles

[![Verify dotfiles](https://github.com/InkCitrus/dotfiles/actions/workflows/verify.yml/badge.svg)](https://github.com/InkCitrus/dotfiles/actions/workflows/verify.yml)

[English](#english) · [中文](#中文) · [日本語](#日本語)

## English

Portable terminal configuration for macOS, Linux, WSL, and Windows PowerShell 7.
Includes Starship, Atuin history search, fzf integration for zsh, zsh autosuggestions,
and syntax highlighting. Optional tools are loaded only when available.

### Platforms

| Platform | Shell | Deployment |
| --- | --- | --- |
| macOS, Apple Silicon or Intel | zsh | Symbolic links with `install.sh` |
| Linux / WSL | zsh | The same installer; Homebrew is optional |
| Native Windows | PowerShell 7+ | File copies with `install.ps1`; no symlink privileges required |

Installers preview changes by default and back up existing files before applying them.
They do not install packages or change your default shell.
Only the listed configuration files are managed; history databases, login credentials,
SSH keys, and fonts are not included.

### Install

Clone the repository into a location you intend to keep:

```sh
git clone https://github.com/InkCitrus/dotfiles.git
cd dotfiles
```

On macOS, Linux, or WSL:

```sh
bash install.sh --dry-run
bash install.sh --install
```

Open a new terminal. If your current shell is Bash, run `zsh` to try the configuration;
`.bashrc` is not changed. If you move the repository, rerun the installer from its new location.

On Windows, run these commands in **PowerShell 7+**:

```powershell
./install.ps1 -DryRun
./install.ps1 -Install
```

Open a new terminal in the same host application. The profile target is
`$PROFILE.CurrentUserCurrentHost`; hosts such as VS Code can use a different profile.
Install separately in each host you use. If execution policy blocks the script, allow
local scripts for the current session with `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`.
Windows and WSL have separate home directories and should be configured separately.

### Dependencies and behavior

The Unix installer requires Bash 3.2+; the shell configuration requires zsh.
The Windows installer and profile require PowerShell 7+.
Install optional tools separately. On macOS or Linux with Homebrew:

```sh
brew bundle --file=packages/Brewfile
```

Linux distribution packages are also supported. zsh plugins are searched for in common
system and Homebrew locations. For custom locations, set `ZSH_AUTOSUGGESTIONS_FILE` and
`ZSH_SYNTAX_HIGHLIGHTING_FILE` before starting zsh, or in `.zprofile.local` for login shells.

On Windows:

```powershell
winget install -e --id Microsoft.PowerShell
winget install -e --id Git.Git
winget install -e --id Starship.Starship
winget install -e --id Atuinsh.Atuin
```

- zsh: Ctrl-R opens Atuin when available; otherwise fzf or zsh retains the binding.
  Up/Down search history by prefix. fzf provides Ctrl-T, Alt-C, and fuzzy completion.
- PowerShell: Starship and Atuin are initialized when available; PSReadLine provides
  Up/Down history search. zsh-specific fzf key bindings are not installed.
- Starship keeps its default appearance. Atuin keeps its compact search UI and asks you
  to review the selected command before running it. Sync requires an explicit login.
- Git sets `init.defaultBranch = main`, enables fetch pruning, and includes
  `~/.gitconfig.local`. Existing `~/.gitconfig` is retained and can override these settings.

Official setup references: [Starship](https://starship.rs/guide/),
[Atuin](https://docs.atuin.sh/main/guide/installation/),
[fzf](https://github.com/junegunn/fzf#setting-up-shell-integration), and
[WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/install).

### Paths and machine-specific settings

`XDG_CONFIG_HOME` defaults to `~/.config`; `XDG_STATE_HOME` defaults to `~/.local/state`.
`ZDOTDIR` defaults to the home directory. Keep these variables consistent between
installation and subsequent shell sessions. The installer does not modify `.zshenv`.

| Path | Purpose |
| --- | --- |
| `$ZDOTDIR/.zshrc`, `$ZDOTDIR/.zprofile` | Managed zsh entry points |
| `$XDG_CONFIG_HOME/dotfiles/env.zsh` | Shared zsh environment |
| `$XDG_CONFIG_HOME/atuin/config.toml` | Atuin preferences |
| `$XDG_CONFIG_HOME/git/config` | Shared Git defaults |
| `$ZDOTDIR/.zshrc.local`, `$ZDOTDIR/.zprofile.local` | Machine-specific zsh overrides |
| `~/.gitconfig.local` | Local Git identity, signing, proxy settings, etc. |
| `$XDG_CONFIG_HOME/powershell/profile.local.ps1` | Machine-specific PowerShell overrides |

Examples are provided in `.zshrc.local.example` and `.gitconfig.local.example`.
The PowerShell profile sets `ATUIN_CONFIG_DIR` to the shared Atuin directory unless you
have already set it. Atuin history and authentication remain local to each machine.
For a custom prompt, configure your own `starship.toml` or set `STARSHIP_CONFIG`;
see [Starship configuration](https://starship.rs/config/).

### Edit and sync

On macOS/Linux/WSL, managed files are symbolic links into this repository. Editing
`~/.zshrc`, for example, edits the repository's `config/zsh/.zshrc` directly.
On Windows, installed files are copies: edit the repository, then rerun
`./install.ps1 -Install`. If you edit an installed copy, copy your changes back to the
repository before reinstalling. Neither installer automatically commits or pushes changes.

Review changes with `git diff`, then commit and push them. On another machine, pull
updates with `git pull`; rerun the Windows installer to refresh its copies. Reopen your
shell to load changes. Keep machine-specific secrets outside the repository, even when
using local override files.

### Restore

Each installation prints its backup directory and an exact restore command.
Backups are stored under `$XDG_STATE_HOME/dotfiles/backups`.

```sh
bash install.sh --restore /absolute/path/to/backup
```

```powershell
./install.ps1 -Restore 'C:/absolute/path/to/backup'
```

Restore removes newly installed files and restores the originals, including original
symlinks. Restore multiple installations from newest to oldest. If an installed
symlink has been replaced, or a Windows copy has been edited, restoration stops so you
can preserve those changes first. Editing a Unix source file in the repository does
not prevent restoring the previous configuration. Empty directories, installed
software, and runtime data are retained.

### Verification

```sh
bash tests/test-install.sh
```

```powershell
./tests/test-install.ps1
```

Tests use temporary directories to check preview, installation, repeated execution,
conflict protection, restoration, and paths containing spaces. Unix tests also check
zsh syntax and startup without optional enhancements; PowerShell tests check script syntax.
The [GitHub Actions workflow](https://github.com/InkCitrus/dotfiles/actions/workflows/verify.yml)
runs on macOS, Ubuntu, and Windows; see the badge above for the latest result.

---

## 中文

适用于 macOS、Linux、WSL 和 Windows PowerShell 7 的终端配置。
包含 Starship、Atuin 历史搜索、zsh 的 fzf 集成、自动建议和语法高亮。
可选工具仅在已安装时加载。

### 支持平台

| 平台 | Shell | 部署方式 |
| --- | --- | --- |
| macOS，Apple Silicon 或 Intel | zsh | `install.sh` 创建符号链接 |
| Linux / WSL | zsh | 使用同一安装器，Homebrew 可选 |
| Windows 原生 | PowerShell 7+ | `install.ps1` 复制文件，无需符号链接权限 |

安装器默认只预览，实际安装前会备份已有文件，不安装软件包，也不更换默认 Shell。
仅管理明确列出的配置，不包含历史数据库、登录凭据、SSH 密钥或字体。

### 安装

将仓库克隆到准备长期保留的位置：

```sh
git clone https://github.com/InkCitrus/dotfiles.git
cd dotfiles
```

macOS、Linux 或 WSL：

```sh
bash install.sh --dry-run
bash install.sh --install
```

重新打开终端。如果当前使用 Bash，可先运行 `zsh` 体验；安装器不会修改 `.bashrc`。
移动仓库后，需要在新位置重新运行安装器。

Windows 请在 **PowerShell 7+** 中运行：

```powershell
./install.ps1 -DryRun
./install.ps1 -Install
```

重新打开同一宿主中的终端。安装目标为 `$PROFILE.CurrentUserCurrentHost`；
VS Code 等宿主可能使用不同的 profile，需要分别安装。
如果执行策略阻止脚本，可仅在当前会话运行
`Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`。
Windows 和 WSL 的用户目录独立，应分别配置。

### 依赖与使用行为

Unix 安装器要求 Bash 3.2+，Shell 配置要求 zsh；Windows 安装器及 profile 要求 PowerShell 7+。
其他工具单独安装。macOS 或已安装 Homebrew 的 Linux 可以运行：

```sh
brew bundle --file=packages/Brewfile
```

Linux 也支持发行版的软件包。zsh 插件会从常见系统目录和 Homebrew 目录查找。
非标准位置可通过 `ZSH_AUTOSUGGESTIONS_FILE`、`ZSH_SYNTAX_HIGHLIGHTING_FILE` 指定，
在启动 zsh 前设置，或为登录 Shell 写入 `.zprofile.local`。

Windows：

```powershell
winget install -e --id Microsoft.PowerShell
winget install -e --id Git.Git
winget install -e --id Starship.Starship
winget install -e --id Atuinsh.Atuin
```

- zsh：已安装 Atuin 时，Ctrl-R 打开 Atuin；否则保留 fzf 或 zsh 的绑定。
  上下方向键按前缀搜索历史，fzf 提供 Ctrl-T、Alt-C 和模糊补全。
- PowerShell：加载已安装的 Starship 和 Atuin；PSReadLine 提供方向键历史搜索。
  不安装 zsh 专属的 fzf 快捷键。
- Starship 保留默认外观。Atuin 使用紧凑界面，选中命令后回到提示符供确认；同步需要主动登录。
- Git 设置新仓库默认分支为 `main`，fetch 时清理失效的远程分支，并加载 `~/.gitconfig.local`。
  已有 `~/.gitconfig` 会保留，它可以覆盖共享设置。

官方安装说明：[Starship](https://starship.rs/guide/)、
[Atuin](https://docs.atuin.sh/main/guide/installation/)、
[fzf](https://github.com/junegunn/fzf#setting-up-shell-integration)、
[WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/install)。

### 路径与本机设置

`XDG_CONFIG_HOME` 默认为 `~/.config`，`XDG_STATE_HOME` 默认为 `~/.local/state`，
`ZDOTDIR` 默认为用户主目录。安装时和之后的 Shell 会话应使用一致的变量设置。
安装器不会修改 `.zshenv`。

| 路径 | 用途 |
| --- | --- |
| `$ZDOTDIR/.zshrc`、`$ZDOTDIR/.zprofile` | 受管理的 zsh 入口 |
| `$XDG_CONFIG_HOME/dotfiles/env.zsh` | zsh 共享环境 |
| `$XDG_CONFIG_HOME/atuin/config.toml` | Atuin 偏好设置 |
| `$XDG_CONFIG_HOME/git/config` | Git 共享默认值 |
| `$ZDOTDIR/.zshrc.local`、`$ZDOTDIR/.zprofile.local` | 本机 zsh 覆盖设置 |
| `~/.gitconfig.local` | Git 身份、签名、代理等本机设置 |
| `$XDG_CONFIG_HOME/powershell/profile.local.ps1` | 本机 PowerShell 覆盖设置 |

示例见 `.zshrc.local.example` 和 `.gitconfig.local.example`。
PowerShell 会将 `ATUIN_CONFIG_DIR` 指向共享配置目录；如果已设置此变量，则保留原值。
Atuin 的历史和登录信息仍保存在各机器本地。
需要自定义提示符时，可自行管理 `starship.toml` 或设置 `STARSHIP_CONFIG`，
参见 [Starship 配置](https://starship.rs/config/)。

### 修改与同步

macOS/Linux/WSL 使用符号链接。例如编辑 `~/.zshrc`，就是修改仓库中的
`config/zsh/.zshrc`，无需改两遍。
Windows 安装的是副本：编辑仓库后，重新运行 `./install.ps1 -Install`。
如果直接编辑了已安装的副本，需要先将修改同步回仓库，再重新安装。
安装器不会自动提交或推送 Git 修改。

使用 `git diff` 检查修改，再提交并推送。其他机器运行 `git pull` 获取更新；
Windows 还需重新运行安装器以更新副本。重新打开 Shell 后加载新配置。
本机机密信息应保留在仓库之外，即使使用 `.local` 覆盖文件也不应提交它们。

### 恢复

每次安装都会打印备份目录和对应恢复命令。
备份位于 `$XDG_STATE_HOME/dotfiles/backups`。

```sh
bash install.sh --restore /absolute/path/to/backup
```

```powershell
./install.ps1 -Restore 'C:/absolute/path/to/backup'
```

恢复会移除新安装的文件并还原原文件，包括原符号链接。
多次安装应按从新到旧的顺序恢复。
如果安装后的符号链接被替换，或 Windows 副本被修改，恢复会停止，便于先保留这些修改。
直接编辑 Unix 仓库内的源文件不会妨碍恢复原配置。
恢复不删除空目录、已安装软件或运行数据。

### 验证

```sh
bash tests/test-install.sh
```

```powershell
./tests/test-install.ps1
```

测试在临时目录中检查预览、安装、重复执行、冲突保护、恢复以及含空格的路径。
Unix 测试还检查 zsh 语法和缺少可选增强工具时的启动；PowerShell 测试检查脚本语法。
[GitHub Actions](https://github.com/InkCitrus/dotfiles/actions/workflows/verify.yml)
在 macOS、Ubuntu 和 Windows 上运行，最新结果见顶部徽章。

---

## 日本語

macOS、Linux、WSL、Windows PowerShell 7 向けのターミナル設定です。
Starship、Atuin の履歴検索、zsh 用の fzf 連携、入力候補の表示、シンタックスハイライトを含みます。
オプションのツールは、インストールされている場合にのみ読み込みます。

### 対応プラットフォーム

| プラットフォーム | シェル | 配置方法 |
| --- | --- | --- |
| macOS（Apple Silicon / Intel） | zsh | `install.sh` でシンボリックリンクを作成 |
| Linux / WSL | zsh | 同じインストーラーを使用。Homebrew は任意 |
| Windows ネイティブ | PowerShell 7+ | `install.ps1` でファイルをコピー。リンク作成権限は不要 |

インストーラーは既定で変更内容の表示のみを行い、適用前に既存ファイルをバックアップします。
パッケージのインストールや既定のシェルの変更は行いません。
管理対象は指定した設定ファイルのみで、履歴データベース、認証情報、SSH 鍵、フォントは含みません。

### インストール

リポジトリを継続して使用する場所にクローンします。

```sh
git clone https://github.com/InkCitrus/dotfiles.git
cd dotfiles
```

macOS、Linux、WSL：

```sh
bash install.sh --dry-run
bash install.sh --install
```

新しいターミナルを開くと設定が読み込まれます。Bash を使っている場合は、`zsh` を実行して試せます。
`.bashrc` は変更しません。リポジトリを移動した場合は、新しい場所でインストーラーを再実行してください。

Windows では **PowerShell 7+** で実行します。

```powershell
./install.ps1 -DryRun
./install.ps1 -Install
```

同じホストアプリケーションで新しいターミナルを開いてください。
配置先は `$PROFILE.CurrentUserCurrentHost` です。VS Code などでは別のプロファイルを使う場合があるため、
使用するホストごとにインストールします。
実行ポリシーでスクリプトがブロックされる場合は、現在のセッションに限って
`Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned` を実行できます。
Windows と WSL のホームディレクトリは別々なので、それぞれ設定してください。

### 依存ツールと動作

Unix のインストーラーには Bash 3.2+、シェル設定には zsh が必要です。
Windows のインストーラーとプロファイルには PowerShell 7+ が必要です。
追加ツールは個別にインストールします。macOS、または Homebrew を使用する Linux：

```sh
brew bundle --file=packages/Brewfile
```

Linux ディストリビューションのパッケージも利用できます。
zsh プラグインは一般的なシステムディレクトリと Homebrew の配置先から検索します。
独自の配置先を使う場合は、zsh の起動前に `ZSH_AUTOSUGGESTIONS_FILE` と
`ZSH_SYNTAX_HIGHLIGHTING_FILE` を設定するか、ログインシェル用の `.zprofile.local` に記述してください。

Windows：

```powershell
winget install -e --id Microsoft.PowerShell
winget install -e --id Git.Git
winget install -e --id Starship.Starship
winget install -e --id Atuinsh.Atuin
```

- zsh：Atuin が利用可能なら Ctrl-R で Atuin を開き、それ以外では fzf または zsh の割り当てを維持します。
  上下キーは入力済みの文字列に一致する履歴を検索します。fzf は Ctrl-T、Alt-C、あいまい補完を提供します。
- PowerShell：利用可能な Starship と Atuin を初期化し、PSReadLine で上下キーによる履歴検索を設定します。
  zsh 専用の fzf キーバインドは設定しません。
- Starship は既定の表示を使います。Atuin はコンパクトな画面を使い、選んだコマンドを実行前に確認できます。
  同期には明示的なログインが必要です。
- Git は新規リポジトリの既定ブランチを `main` にし、fetch 時の prune を有効にして、
  `~/.gitconfig.local` を読み込みます。既存の `~/.gitconfig` は保持され、共有設定を上書きできます。

公式の導入ガイド：[Starship](https://starship.rs/guide/)、
[Atuin](https://docs.atuin.sh/main/guide/installation/)、
[fzf](https://github.com/junegunn/fzf#setting-up-shell-integration)、
[WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/install)。

### 配置先とマシン固有の設定

`XDG_CONFIG_HOME` の既定値は `~/.config`、`XDG_STATE_HOME` は `~/.local/state`、
`ZDOTDIR` はホームディレクトリです。インストール時と以後のシェルで同じ値を使ってください。
インストーラーは `.zshenv` を変更しません。

| パス | 用途 |
| --- | --- |
| `$ZDOTDIR/.zshrc`、`$ZDOTDIR/.zprofile` | 管理対象の zsh 起動設定 |
| `$XDG_CONFIG_HOME/dotfiles/env.zsh` | zsh の共通環境設定 |
| `$XDG_CONFIG_HOME/atuin/config.toml` | Atuin の設定 |
| `$XDG_CONFIG_HOME/git/config` | Git の共通設定 |
| `$ZDOTDIR/.zshrc.local`、`$ZDOTDIR/.zprofile.local` | マシン固有の zsh 設定 |
| `~/.gitconfig.local` | Git のユーザー情報、署名、プロキシなど |
| `$XDG_CONFIG_HOME/powershell/profile.local.ps1` | マシン固有の PowerShell 設定 |

サンプルは `.zshrc.local.example` と `.gitconfig.local.example` にあります。
PowerShell のプロファイルは `ATUIN_CONFIG_DIR` を共通設定のディレクトリに設定しますが、
すでに値がある場合はその値を保持します。Atuin の履歴と認証情報は各マシンに保存されます。
プロンプトを変更する場合は、自分で `starship.toml` を管理するか `STARSHIP_CONFIG` を設定してください。
詳細は [Starship の設定](https://starship.rs/config/)を参照してください。

### 編集と同期

macOS/Linux/WSL では、管理対象のファイルはリポジトリへのシンボリックリンクです。
たとえば `~/.zshrc` を編集すると、リポジトリの `config/zsh/.zshrc` が直接変更されます。
Windows ではコピーを配置するため、リポジトリを編集してから `./install.ps1 -Install` を再実行してください。
配置済みのコピーを直接編集した場合は、再インストール前に変更をリポジトリへ戻してください。
インストーラーは Git のコミットや push を自動では行いません。

`git diff` で変更を確認してからコミットし、push します。
別のマシンでは `git pull` で更新し、Windows ではインストーラーも再実行します。
設定を読み込むにはシェルを開き直してください。
機密情報はリポジトリの外で管理し、`.local` の設定ファイルに書く場合もコミットしないでください。

### 復元

インストール時にバックアップ先と復元コマンドが表示されます。
バックアップは `$XDG_STATE_HOME/dotfiles/backups` に保存されます。

```sh
bash install.sh --restore /absolute/path/to/backup
```

```powershell
./install.ps1 -Restore 'C:/absolute/path/to/backup'
```

復元すると、新しく配置したファイルを取り除き、元のファイルやシンボリックリンクを戻します。
複数回インストールした場合は、新しいものから順に復元してください。
配置後のリンクが置き換えられたり、Windows のコピーが編集されたりした場合は、変更を保護するため復元を停止します。
Unix でリポジトリ内の元ファイルを編集しても、以前の設定への復元は妨げません。
空のディレクトリ、インストール済みソフトウェア、実行時のデータは残ります。

### 検証

```sh
bash tests/test-install.sh
```

```powershell
./tests/test-install.ps1
```

一時ディレクトリを使い、プレビュー、インストール、再実行、競合時の保護、復元、空白を含むパスを検証します。
Unix では zsh の構文と追加機能なしでの起動、PowerShell ではスクリプトの構文も確認します。
[GitHub Actions](https://github.com/InkCitrus/dotfiles/actions/workflows/verify.yml)
で macOS、Ubuntu、Windows のテストを実行します。最新の結果は冒頭のバッジから確認できます。
