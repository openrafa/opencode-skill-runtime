# OpenCode Skill Runtime

[English](README.md) · [中文](README.zh-CN.md)

面向 OpenCode skills 的可移植运行时辅助工具。核心是 `venv-manager.sh`：每个 skill
一个由 [uv](https://github.com/astral-sh/uv) 管理的虚拟环境。

**归属：** 本仓库为 **RAFA 原创**（不是 fork）。目的是让 `~/.opencode/skills/`
下依赖 Python 的 skill 不再挤在同一个脆弱的全局解释器里。

**套件入口：** [opencode-methodology](https://github.com/openrafa/opencode-methodology)
→ [从零安装](https://github.com/openrafa/opencode-methodology/blob/main/docs/install-from-scratch.zh-CN.md)。

## 快速开始（从零）

1. 安装 OpenCode 与 [`uv`](https://github.com/astral-sh/uv)（可选 `UV_BIN`）。
2. 克隆并把 helper 装进 OpenCode 配置树：

```bash
git clone https://github.com/openrafa/opencode-skill-runtime.git
mkdir -p ~/.config/opencode/.scripts
cp opencode-skill-runtime/bin/venv-manager.sh \
  ~/.config/opencode/.scripts/venv-manager.sh
```

3. 创建 / 检查 / rewire skill venv：

```bash
bash ~/.config/opencode/.scripts/venv-manager.sh create <skill-name> <package>...
bash ~/.config/opencode/.scripts/venv-manager.sh doctor <skill-name>
bash ~/.config/opencode/.scripts/venv-manager.sh rewire <skill-name>
```

4. 在 OpenCode 中照常使用该 skill。若 import 失败，再跑 `doctor`。

### 会落到磁盘的内容

```text
~/.config/opencode/
├── .scripts/
│   └── venv-manager.sh
└── .venvs/                 # 生成本机状态（请自行 gitignore）
    └── <skill-name>/
```

默认：`VENV_ROOT=~/.config/opencode/.venvs`，
`SKILL_ROOT=~/.opencode/skills`。见 [`docs/python-isolation.zh-CN.md`](docs/python-isolation.zh-CN.md)。

## 为什么需要

全局 site-packages 容易让 skill 互相冲突、故障难查。一 skill 一 venv + 可逆 wrapper 更稳。

## 文档

| 主题 | English | 中文 |
| --- | --- | --- |
| Python 隔离 | [python-isolation.md](docs/python-isolation.md) | [python-isolation.zh-CN.md](docs/python-isolation.zh-CN.md) |
| 作者指南 | [skill-author-guidelines.md](docs/skill-author-guidelines.md) | [skill-author-guidelines.zh-CN.md](docs/skill-author-guidelines.zh-CN.md) |
| 排障 | [troubleshooting.md](docs/troubleshooting.md) | [troubleshooting.zh-CN.md](docs/troubleshooting.zh-CN.md) |

## 相关

- Python 重型 skill 命名示例（不随仓库附带）：[`examples/kami.md`](examples/kami.md)
- 可能需要隔离的 wiki skills：[opencode-obsidian-wiki](https://github.com/openrafa/opencode-obsidian-wiki)

## 许可与署名

MIT — Copyright (c) 2026 [Cyame](https://github.com/Cyame)。见 [`LICENSE`](LICENSE)。
本运行时辅助工具为本套件原创。
