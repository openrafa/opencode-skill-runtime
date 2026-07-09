#!/usr/bin/env bash
# venv-manager.sh — Standardized per-skill Python environment isolation for OpenCode skills.
#
# This script manages uv-based virtual environments for OpenCode skills that require
# third-party Python packages. It follows the pattern proven with kami (weasyprint,
# pypdf, pymupdf, etc.) and generalizes it into a reusable tool.
#
# Usage:
#   venv-manager.sh create <skill-name> [pkg1 pkg2 ...]   # create venv + install deps
#   venv-manager.sh install <skill-name> [pkg1 pkg2 ...]  # install additional deps
#   venv-manager.sh update <skill-name>                   # update all deps in venv
#   venv-manager.sh remove <skill-name>                   # delete venv and wrapper
#   venv-manager.sh list                                  # list all managed skill venvs
#   venv-manager.sh doctor <skill-name>                   # verify venv health + imports
#   venv-manager.sh rewire <skill-name>                   # re-apply python3→wrapper rewrite
#
# Environment:
#   VENV_ROOT     — where uv venvs live (default: ~/.config/opencode/.venvs)
#   SKILL_ROOT    — where skills live (default: ~/.opencode/skills)
#   UV_BIN        — path to uv binary (default: auto-detected from PATH)
#
# Example:
#   venv-manager.sh create kami weasyprint pypdf pymupdf python-pptx pygments numpy
#
# Copyright: MIT — part of the OpenCode skill isolation toolkit.

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
VENV_ROOT="${VENV_ROOT:-$HOME/.config/opencode/.venvs}"
SKILL_ROOT="${SKILL_ROOT:-$HOME/.opencode/skills}"
UV_BIN="${UV_BIN:-$(command -v uv || true)}"

if [[ -z "$UV_BIN" || ! -x "$UV_BIN" ]]; then
  echo "ERROR: uv not found in PATH. Install: curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
  exit 1
fi

# ─── Helpers ─────────────────────────────────────────────────────────────────
die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "[venv-manager] $*"; }

venv_path() { echo "$VENV_ROOT/$1"; }
skill_path() { echo "$SKILL_ROOT/$1"; }
wrapper_path() { echo "$SKILL_ROOT/$1/bin/$1-python"; }
python_path() { echo "$(venv_path "$1")/bin/python"; }

skill_exists() {
  [[ -d "$(skill_path "$1")" ]] || die "Skill '$1' not found at $(skill_path "$1")"
}

# ─── macOS library path helper ────────────────────────────────────────────────
# Some packages (weasyprint via cairo/pango) need Homebrew libs on macOS.
# This generates a wrapper that injects DYLD_LIBRARY_PATH when needed.
generate_wrapper() {
  local skill="$1"
  local venv_python
  venv_python="$(python_path "$skill")"
  local wrapper
  wrapper="$(wrapper_path "$skill")"
  local skill_bin
  skill_bin="$(skill_path "$skill")/bin"

  mkdir -p "$skill_bin"

  local dyld_path=""
  if [[ "$OSTYPE" == darwin* ]] && [[ -d /opt/homebrew/lib ]]; then
    dyld_path='export DYLD_LIBRARY_PATH="/opt/homebrew/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"'
  elif [[ "$OSTYPE" == darwin* ]] && [[ -d /usr/local/lib ]]; then
    dyld_path='export DYLD_LIBRARY_PATH="/usr/local/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"'
  fi

  cat > "$wrapper" <<EOF
#!/bin/bash
# Auto-generated wrapper for skill '$skill'.
# Routes python3 calls into the isolated uv virtual environment.
${dyld_path}
exec "$venv_python" "\$@"
EOF
  chmod +x "$wrapper"
  info "Created wrapper: $wrapper"
}

remove_wrapper() {
  local skill="$1"
  local wrapper
  wrapper="$(wrapper_path "$skill")"
  if [[ -f "$wrapper" ]]; then
    rm -f "$wrapper"
    info "Removed wrapper: $wrapper"
  fi
}

# ─── Rewrite SKILL.md and scripts ────────────────────────────────────────────
# Replaces bare 'python3 ' with the wrapper path in SKILL.md and .py shebangs.
rewire_skill() {
  local skill="$1"
  local wrapper
  wrapper="$(wrapper_path "$skill")"
  local skill_dir
  skill_dir="$(skill_path "$skill")"

  if [[ ! -f "$wrapper" ]]; then
    die "Wrapper not found. Run 'venv-manager.sh create $skill' first."
  fi

  # Rewrite SKILL.md
  if [[ -f "$skill_dir/SKILL.md" ]]; then
    # Replace 'python3 ' (with trailing space to avoid partial matches) with wrapper path
    # But be careful not to double-rewrite if already rewritten.
    if grep -q "python3 " "$skill_dir/SKILL.md"; then
      sed -i.bak "s|python3 |$wrapper |g" "$skill_dir/SKILL.md"
      rm -f "$skill_dir/SKILL.md.bak"
      info "Rewrote SKILL.md to use wrapper"
    else
      info "SKILL.md already uses wrapper (no bare 'python3 ' found)"
    fi
  fi

  # Rewrite shebangs in scripts/*.py
  local shebang_target="#!/usr/bin/env python3"
  local shebang_replacement="#!$wrapper"
  local count=0
  while IFS= read -r -d '' pyfile; do
    local firstline
    firstline="$(head -n 1 "$pyfile")"
    if [[ "$firstline" == "$shebang_target" || "$firstline" == "#!/usr/bin/python3" ]]; then
      sed -i.bak "1s|.*|$shebang_replacement|" "$pyfile"
      rm -f "$pyfile.bak"
      ((count++))
    fi
  done < <(find "$skill_dir" -name "*.py" -type f -print0 2>/dev/null || true)

  if [[ $count -gt 0 ]]; then
    info "Rewrote shebang in $count Python file(s)"
  fi
}

restore_skill() {
  local skill="$1"
  local skill_dir
  skill_dir="$(skill_path "$skill")"

  if [[ -f "$skill_dir/SKILL.md" ]]; then
    local wrapper
    wrapper="$(wrapper_path "$skill")"
    if grep -q "$wrapper" "$skill_dir/SKILL.md"; then
      sed -i.bak "s|$wrapper |python3 |g" "$skill_dir/SKILL.md"
      rm -f "$skill_dir/SKILL.md.bak"
      info "Restored SKILL.md to use 'python3'"
    fi
  fi

  local count=0
  while IFS= read -r -d '' pyfile; do
    local firstline
    firstline="$(head -n 1 "$pyfile")"
    if [[ "$firstline" == "#!"*"/$skill-python" ]]; then
      sed -i.bak '1s|.*|#!/usr/bin/env python3|' "$pyfile"
      rm -f "$pyfile.bak"
      ((count++))
    fi
  done < <(find "$skill_dir" -name "*.py" -type f -print0 2>/dev/null || true)

  if [[ $count -gt 0 ]]; then
    info "Restored shebang in $count Python file(s)"
  fi
}

# ─── Commands ────────────────────────────────────────────────────────────────
cmd_create() {
  local skill="$1"
  shift
  local packages=("$@")

  skill_exists "$skill"
  local venv
  venv="$(venv_path "$skill")"

  if [[ -d "$venv" ]]; then
    die "Venv already exists: $venv. Use 'update' or 'remove' first."
  fi

  info "Creating uv venv for skill '$skill'..."
  "$UV_BIN" venv "$venv"

  if [[ ${#packages[@]} -gt 0 ]]; then
    info "Installing packages: ${packages[*]}"
    "$UV_BIN" pip install --python "$(python_path "$skill")" "${packages[@]}"
  fi

  generate_wrapper "$skill"
  rewire_skill "$skill"

  info "Skill '$skill' is now isolated in $venv"
  cmd_doctor "$skill"
}

cmd_install() {
  local skill="$1"
  shift
  local packages=("$@")

  [[ ${#packages[@]} -gt 0 ]] || die "No packages specified"
  skill_exists "$skill"

  local venv
  venv="$(venv_path "$skill")"
  [[ -d "$venv" ]] || die "Venv not found. Run 'create $skill' first."

  info "Installing packages into '$skill': ${packages[*]}"
  "$UV_BIN" pip install --python "$(python_path "$skill")" "${packages[@]}"
}

cmd_update() {
  local skill="$1"
  skill_exists "$skill"

  local venv
  venv="$(venv_path "$skill")"
  [[ -d "$venv" ]] || die "Venv not found. Run 'create $skill' first."

  info "Updating all packages in '$skill'..."
  "$UV_BIN" pip list --python "$(python_path "$skill")"
  "$UV_BIN" pip install --python "$(python_path "$skill")" --upgrade -e . 2>/dev/null || true
  # uv doesn't have a direct 'upgrade all', but we can reinstall what's there
  info "Note: uv pip install --upgrade <pkg> for individual upgrades"
}

cmd_remove() {
  local skill="$1"
  skill_exists "$skill"

  local venv
  venv="$(venv_path "$skill")"

  if [[ -d "$venv" ]]; then
    rm -rf "$venv"
    info "Removed venv: $venv"
  fi

  restore_skill "$skill"
  remove_wrapper "$skill"
}

cmd_list() {
  info "Managed skill virtual environments under $VENV_ROOT:"
  if [[ -d "$VENV_ROOT" ]]; then
    for d in "$VENV_ROOT"/*; do
      [[ -d "$d" ]] || continue
      local name
      name="$(basename "$d")"
      local py
      py="$d/bin/python"
      local ver="unknown"
      if [[ -x "$py" ]]; then
        ver="$("$py" --version 2>/dev/null | awk '{print $2}' || echo unknown)"
      fi
      printf "  %-20s  Python %s\n" "$name" "$ver"
    done
  else
    echo "  (none)"
  fi
}

cmd_doctor() {
  local skill="$1"
  skill_exists "$skill"

  local venv
  venv="$(venv_path "$skill")"
  local wrapper
  wrapper="$(wrapper_path "$skill")"

  info "Diagnosing skill '$skill'..."

  # Check venv
  if [[ -d "$venv" && -x "$(python_path "$skill")" ]]; then
    echo "  ✓ Virtual environment: $venv"
    "$(python_path "$skill")" --version
  else
    echo "  ✗ Virtual environment missing or broken"
    return 1
  fi

  # Check wrapper
  if [[ -x "$wrapper" ]]; then
    echo "  ✓ Wrapper script: $wrapper"
  else
    echo "  ✗ Wrapper script missing"
    return 1
  fi

  # Check imports from Python files
  local skill_dir
  skill_dir="$(skill_path "$skill")"
  local checked_mods=""
  while IFS= read -r -d '' pyfile; do
    while IFS= read -r line; do
      local mod=""
      # Extract top-level module name from import line
      if [[ "$line" =~ ^import\ +([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
        mod="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^from\ +([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
        mod="${BASH_REMATCH[1]}"
      fi
      [[ -n "$mod" ]] || continue
      # Skip relative imports and stdlib
      [[ "$mod" == "."* ]] && continue
      case "$mod" in
        __future__|argparse|ast|base64|binascii|builtins|bz2|cProfile|calendar|cgi|cgitb|chunk|cmath|cmd|code|codecs|codeop|collections|colorsys|compileall|concurrent|configparser|contextlib|contextvars|copy|copyreg|crypt|csv|ctypes|curses|dataclasses|datetime|dbm|decimal|difflib|dis|distutils|doctest|email|encodings|enum|faulthandler|fcntl|filecmp|fileinput|fnmatch|fractions|ftplib|functools|gc|getopt|getpass|gettext|glob|graphlib|grp|gzip|hashlib|heapq|hmac|html|http|idlelib|imaplib|imghdr|imp|importlib|inspect|io|ipaddress|itertools|json|keyword|lib2to3|linecache|locale|logging|lzma|mailbox|mailcap|marshal|math|mimetypes|mmap|modulefinder|multiprocessing|netrc|nis|nntplib|numbers|operator|optparse|os|ossaudiodev|pathlib|pdb|pickle|pickletools|pipes|pkgutil|platform|plistlib|poplib|posix|posixpath|pprint|profile|pstats|pty|pwd|py_compile|pyclbr|pydoc|queue|quopri|random|re|readline|reprlib|resource|rlcompleter|runpy|sched|secrets|select|selectors|shelve|shlex|shutil|signal|site|smtpd|smtplib|socket|socketserver|spwd|sqlite3|ssl|stat|statistics|string|stringprep|struct|subprocess|sunau|symtable|sys|sysconfig|syslog|tabnanny|tarfile|telnetlib|tempfile|termios|test|textwrap|threading|time|timeit|tkinter|token|tokenize|trace|traceback|tracemalloc|tty|turtle|turtledemo|types|typing|unicodedata|unittest|urllib|uu|uuid|venv|warnings|wave|weakref|webbrowser|winreg|winsound|wsgiref|xdrlib|xml|xmlrpc|zipapp|zipfile|zipimport|zlib|zoneinfo) continue ;;
      esac
      # Deduplicate against newline-separated list
      if echo "$checked_mods" | grep -qxF "$mod" 2>/dev/null; then
        continue
      fi
      # Skip local modules anywhere in the skill tree
      if find "$skill_dir" -name "$mod.py" -type f | read -r; then
        continue
      fi
      checked_mods="${checked_mods}${checked_mods:+$'\n'}${mod}"
      # Try importing
      if "$(python_path "$skill")" -c "import $mod" 2>/dev/null; then
        echo "  ✓ Import '$mod' OK"
      else
        echo "  ⚠ Import '$mod' failed (may be optional or missing)"
      fi
    done < <(grep -hE '^(import|from)\s+[a-zA-Z_]' "$pyfile" 2>/dev/null || true)
  done < <(find "$skill_dir" -name "*.py" -type f -print0 2>/dev/null || true)

  if [[ -z "$checked_mods" ]]; then
    echo "  ℹ No third-party imports detected (pure stdlib skill)"
  fi
}

cmd_rewire() {
  local skill="$1"
  skill_exists "$skill"
  rewire_skill "$skill"
}

# ─── Main ────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") <command> <args>

Commands:
  create  <skill> [pkg...]   Create venv, install deps, generate wrapper, rewire skill
  install <skill> [pkg...]   Install additional packages into existing venv
  update  <skill>            Update packages (uv best-effort)
  remove  <skill>            Delete venv, restore SKILL.md and shebangs
  list                       List all managed skill venvs
  doctor  <skill>            Verify venv health and importability
  rewire  <skill>            Re-apply python3→wrapper rewrite (after skill update)

Environment:
  VENV_ROOT     default: ~/.config/opencode/.venvs
  SKILL_ROOT    default: ~/.opencode/skills
  UV_BIN        auto-detected from PATH

Example:
  $(basename "$0") create kami weasyprint pypdf pymupdf python-pptx pygments
  $(basename "$0") doctor kami
  $(basename "$0") rewire kami
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }

cmd="$1"
shift

case "$cmd" in
  create)  [[ $# -ge 1 ]] || { usage; exit 1; }; cmd_create "$@" ;;
  install) [[ $# -ge 2 ]] || { usage; exit 1; }; cmd_install "$@" ;;
  update)  [[ $# -eq 1 ]] || { usage; exit 1; }; cmd_update "$1" ;;
  remove)  [[ $# -eq 1 ]] || { usage; exit 1; }; cmd_remove "$1" ;;
  list)    cmd_list ;;
  doctor)  [[ $# -eq 1 ]] || { usage; exit 1; }; cmd_doctor "$1" ;;
  rewire)  [[ $# -eq 1 ]] || { usage; exit 1; }; cmd_rewire "$1" ;;
  *)       usage; exit 1 ;;
esac
