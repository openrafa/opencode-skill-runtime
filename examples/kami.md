# Example: Python-Heavy Skill

A Python-heavy skill can document its dependencies like this:

```bash
venv-manager.sh create <skill-name> weasyprint pypdf pymupdf python-pptx pygments
```

This repository does not bundle upstream skills. Install upstream skills from
their own source, then use this runtime when they need isolated Python packages.
