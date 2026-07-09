# Python Isolation

> Language: [English](python-isolation.md) · [中文](python-isolation.zh-CN.md)

Use one uv virtual environment per OpenCode skill.

## Principles

1. One skill, one venv.
2. `uv` manages creation and installation.
3. A generated wrapper hides platform-specific library paths.
4. Rewrites are reversible.
5. Generated `.venvs/` are local state and stay out of git.

## Commands

```bash
venv-manager.sh create <skill-name> [pkg...]
venv-manager.sh install <skill-name> [pkg...]
venv-manager.sh doctor <skill-name>
venv-manager.sh rewire <skill-name>
venv-manager.sh remove <skill-name>
venv-manager.sh list
```

## Environment Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `VENV_ROOT` | `~/.config/opencode/.venvs` | uv venv root |
| `SKILL_ROOT` | `~/.opencode/skills` | OpenCode skill root |
| `UV_BIN` | auto-detected | uv executable |
