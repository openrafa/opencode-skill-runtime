# 排障

> 语言：[English](troubleshooting.md) · [中文](troubleshooting.zh-CN.md)

## 缺少 `uv`

安装 uv，并确认它在 `PATH` 中。

## macOS 动态库加载失败

某些包（如 HTML/PDF 渲染）需要 Homebrew 库。生成的 wrapper 会在 macOS 上加入常见 Homebrew 库路径。

## skill 更新后又变回 `python3`

执行：

```bash
venv-manager.sh rewire <skill-name>
```

## venv 坏了

删除并重建该 skill 的环境。