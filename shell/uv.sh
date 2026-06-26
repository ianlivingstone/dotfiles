#!/usr/bin/env zsh
# uv (Python package and project manager) setup and configuration
# SOURCED MODULE: Uses graceful error handling, never use set -e
#
# uv is managed by Homebrew (see Brewfile), so its binary is already on PATH via
# `brew shellenv` — no curl-installer `env` script or ~/.local/bin handling needed.
# This module only validates the uv version and wires up uv-managed Python, both of
# which are independent of how uv itself was installed (Pythons live under
# ~/.local/share/uv/python regardless).

# Load utility functions
source "$(cd "$(dirname "${(%):-%N}")" && pwd)/utils.sh"

# Get the directory containing this script
MODULE_DIR="$(get_shell_dir)"

# Get UV_VERSION from versions.config or use fallback
UV_VERSION=$(get_version_requirement "uv" || echo "0.5.0")

# Get PYTHON_VERSION from versions.config or use fallback
PYTHON_VERSION=$(get_version_requirement "python" || echo "3.11")

if command -v uv &>/dev/null; then
    # Check uv version matches configured version
    local installed_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
    if [[ "$installed_version" != "unknown" && "$installed_version" < "$UV_VERSION" ]]; then
        show_warning "uv version $installed_version is older than required $UV_VERSION (update with: brew upgrade uv)"
    fi

    # Find and prioritize uv-managed Python in PATH
    # This ensures uv-managed Python takes precedence over system Python
    local uv_python_dir="$HOME/.local/share/uv/python"
    if [[ -d "$uv_python_dir" ]]; then
        # Find the installed Python version matching our requirement
        local installed_python_path=$(uv python find "$PYTHON_VERSION" 2>/dev/null || echo "")

        if [[ -n "$installed_python_path" && -x "$installed_python_path" ]]; then
            # Get the bin directory from the python executable path
            local python_bin_dir=$(dirname "$installed_python_path")

            # Prepend to PATH to ensure it takes priority over system Python
            # Remove any existing entries first to avoid duplicates
            export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^$python_bin_dir$" | tr '\n' ':' | sed 's/:$//')
            export PATH="$python_bin_dir:$PATH"

            # Verify we're using a uv-managed Python that meets requirements
            local active_python_version=$(python3 --version 2>/dev/null | awk '{print $2}')
            local active_path=$(which python3 2>/dev/null)

            # Check if active Python is from uv-managed directory and meets version requirement
            if [[ "$active_path" == *"/.local/share/uv/python/"* ]]; then
                # Using uv-managed Python, check if version meets requirement
                local major_version=${active_python_version%%.*}
                local minor_version=${active_python_version#*.}
                minor_version=${minor_version%%.*}
                local required_minor=${PYTHON_VERSION#*.}
                required_minor=${required_minor%%.*}

                if [[ $major_version -eq 3 && $minor_version -ge $required_minor ]]; then
                    # Successfully using uv-managed Python that meets requirements
                    :  # Silent success
                else
                    show_warning "Using uv-managed Python $active_python_version, but $PYTHON_VERSION+ required"
                fi
            else
                show_warning "uv-managed Python found but system Python is active (using: $active_python_version at $active_path)"
            fi
        else
            # uv-managed Python not found, check system Python
            if command -v python3 &>/dev/null; then
                local python_version=$(python3 --version 2>/dev/null | awk '{print $2}')
                if [[ -n "$python_version" ]]; then
                    local major_version=${python_version%%.*}
                    local minor_version=${python_version#*.}
                    minor_version=${minor_version%%.*}
                    local required_minor=${PYTHON_VERSION#*.}
                    required_minor=${required_minor%%.*}

                    if [[ $major_version -lt 3 ]] || [[ $major_version -eq 3 && $minor_version -lt $required_minor ]]; then
                        show_warning "Python version $python_version is older than required $PYTHON_VERSION"
                        echo "💡 Install Python $PYTHON_VERSION with: uv python install $PYTHON_VERSION"
                    fi
                fi
            else
                # Python not found - suggest installation via uv
                echo "⚠️  Python 3 not found"
                echo "💡 Install Python $PYTHON_VERSION with: uv python install $PYTHON_VERSION"
            fi
        fi
    fi

    # During update mode, ensure Python is installed via uv
    if [[ "${DOTFILES_UPDATE_MODE:-0}" == "1" ]]; then
        local uv_python_list=$(uv python list 2>/dev/null | grep -E "cpython-$PYTHON_VERSION" || echo "")
        if [[ -z "$uv_python_list" ]]; then
            echo "📦 Installing Python $PYTHON_VERSION via uv..."
            uv python install "$PYTHON_VERSION" 2>/dev/null || echo "⚠️  Failed to install Python via uv"
        fi
    fi
else
    # uv not installed - it is managed by Homebrew
    show_warning "uv not found. Install with: brew install uv  (or: ./dotfiles.sh update)"
fi
