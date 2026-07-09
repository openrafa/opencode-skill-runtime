# Troubleshooting

> Language: [English](troubleshooting.md) · [中文](troubleshooting.zh-CN.md)

## `uv` is missing

Install uv and confirm it is on `PATH`.

## macOS library loading fails

Some packages, such as HTML/PDF renderers, need Homebrew libraries. The generated
wrapper adds common Homebrew library paths on macOS.

## A skill update restored `python3`

Run:

```bash
venv-manager.sh rewire <skill-name>
```

## A venv is broken

Remove and recreate the skill environment.
