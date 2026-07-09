# Skill Author Guidelines

> Language: [English](skill-author-guidelines.md) · [中文](skill-author-guidelines.zh-CN.md)

To make a Python-heavy skill compatible with this runtime:

- Put Python files under a `scripts/` directory.
- Call them from `SKILL.md` with `python3 scripts/name.py`.
- Use `#!/usr/bin/env python3` shebangs.
- Keep optional dependencies guarded with fallbacks.
- Document required packages near the top of the skill README or `SKILL.md`.