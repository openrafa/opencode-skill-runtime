# Python 隔离

> 语言：[English](python-isolation.md) · [中文](python-isolation.zh-CN.md)

为每个 OpenCode skill 使用一个 uv 虚拟环境。

## 原则

1. 一 skill，一 venv。
2. 由 `uv` 负责创建与安装。
3. 生成的 wrapper 隐藏平台相关的库路径。
4. 改写可逆。
5. 生成的 `.venvs/` 是本机状态，不要进 git。

## 命令

```bash
venv-manager.sh create <skill-name> [pkg...]
venv-manager.sh install <skill-name> [pkg...]
venv-manager.sh doctor <skill-name>
venv-manager.sh rewire <skill-name>
venv-manager.sh remove <skill-name>
venv-manager.sh list
```

## 环境变量

| 变量 | 默认 | 用途 |
| --- | --- | --- |
| `VENV_ROOT` | `~/.config/opencode/.venvs` | uv venv 根目录 |
| `SKILL_ROOT` | `~/.opencode/skills` | OpenCode skill 根目录 |
| `UV_BIN` | 自动探测 | uv 可执行文件 |