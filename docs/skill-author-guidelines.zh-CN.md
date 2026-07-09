# Skill 作者指南

> 语言：[English](skill-author-guidelines.md) · [中文](skill-author-guidelines.zh-CN.md)

让偏 Python 的 skill 兼容本运行时：

- 把 Python 文件放在 `scripts/` 目录。
- 在 `SKILL.md` 里用 `python3 scripts/name.py` 调用。
- 使用 `#!/usr/bin/env python3` shebang。
- 可选依赖用 fallback 保护。
- 在 skill README 或 `SKILL.md` 顶部写明所需包。
