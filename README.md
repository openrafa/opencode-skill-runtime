# OpenCode Skill Runtime

[English](README.md) · [中文](README.zh-CN.md)

Runtime helpers for OpenCode skills, RAFA-original internals. The core tool is `venv-manager.sh`: one [uv](https://github.com/astral-sh/uv)-managed virtualenv per skill.

**Attribution:** this repository is not a fork. It exists so Python-heavy skills under `~/.opencode/skills/` do not share a fragile global interpreter.

**Suite hub:** [opencode-methodology](https://github.com/openrafa/opencode-methodology) → [Install from scratch](https://github.com/openrafa/opencode-methodology/blob/main/docs/install-from-scratch.md).

## Getting started

1. Install OpenCode and [`uv`](https://github.com/astral-sh/uv) (`UV_BIN` optional).
2. Clone and install the helper into the OpenCode config tree:

```bash
git clone https://github.com/openrafa/opencode-skill-runtime.git
mkdir -p ~/.config/opencode/.scripts
cp opencode-skill-runtime/bin/venv-manager.sh \
  ~/.config/opencode/.scripts/venv-manager.sh
```

3. Create / check / rewire a skill venv:

```bash
bash ~/.config/opencode/.scripts/venv-manager.sh create <skill-name> <package>...
bash ~/.config/opencode/.scripts/venv-manager.sh doctor <skill-name>
bash ~/.config/opencode/.scripts/venv-manager.sh rewire <skill-name>
```

4. Use the skill in OpenCode as usual. Re-run `doctor` if imports fail.

### What lands on disk

```text
~/.config/opencode/
├── .scripts/
│   └── venv-manager.sh
└── .venvs/                 # generated local state, gitignored by you
    └── <skill-name>/
```

Defaults: `VENV_ROOT=~/.config/opencode/.venvs`, `SKILL_ROOT=~/.opencode/skills`. See [`docs/python-isolation.md`](docs/python-isolation.md) ([中文](docs/python-isolation.zh-CN.md)).

## Why

Global site-packages make skills conflict and failures hard to diagnose. One venv per skill + a generated wrapper keeps isolation reversible.

## Docs

| Topic | English | 中文 |
| --- | --- | --- |
| Python isolation | [python-isolation.md](docs/python-isolation.md) | [python-isolation.zh-CN.md](docs/python-isolation.zh-CN.md) |
| Author guidelines | [skill-author-guidelines.md](docs/skill-author-guidelines.md) | [skill-author-guidelines.zh-CN.md](docs/skill-author-guidelines.zh-CN.md) |
| Troubleshooting | [troubleshooting.md](docs/troubleshooting.md) | [troubleshooting.zh-CN.md](docs/troubleshooting.zh-CN.md) |

## Related

- Example of a Python-heavy skill name, not bundled: [`examples/kami.md`](examples/kami.md)
- Wiki skills that may need isolation: [opencode-obsidian-wiki](https://github.com/openrafa/opencode-obsidian-wiki)

## License & credit

MIT — Copyright (c) 2026 [Cyame](https://github.com/Cyame). See [`LICENSE`](LICENSE).
This runtime helper is written for this suite.
