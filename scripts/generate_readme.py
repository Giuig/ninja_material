#!/usr/bin/env python3
"""
Generate README.md for all ninja apps from per-app readme_config.yml files.

Usage:
    cd ninja_material/scripts
    python generate_readme.py

Requires: PyYAML  (pip install pyyaml)
"""

import sys
import os

try:
    import yaml
except ImportError:
    print("PyYAML not found. Install it with: pip install pyyaml")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_PATH = os.path.join(SCRIPT_DIR, "readme_template.md")
REPOS_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))

# All apps in the family — used to build the cross-linking table
FAMILY = [
    {
        "slug": "tvninja",
        "github": "https://github.com/Giuig/tvninja",
        "description": "IPTV / M3U8 player",
    },
    {
        "slug": "auraninja",
        "github": "https://github.com/Giuig/auraninja",
        "description": "Ambient sound mixer and focus app",
    },
    {
        "slug": "decisioninja",
        "github": "https://github.com/Giuig/decisioninja",
        "description": "Decision maker with dice, pointer, and binary choices",
    },
    {
        "slug": "ninja_material",
        "github": "https://github.com/Giuig/ninja_material",
        "description": "Shared Flutter library powering all ninja apps",
    },
]


def load_config(repo_dir: str) -> dict:
    config_path = os.path.join(repo_dir, "readme_config.yml")
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_template() -> str:
    with open(TEMPLATE_PATH, "r", encoding="utf-8") as f:
        return f.read()


def build_features(features: list) -> str:
    return "\n".join(f"- {item}" for item in features)


def build_web_section(config: dict) -> str:
    url = config.get("web_url")
    if not url:
        return ""
    name = config["name"]
    note = config.get("web_note", "")
    note_block = f"\n> {note}\n" if note else ""
    return f"\n## Try it Online\n\n**[Launch {name}]({url})**\n{note_block}"


def build_download_section(config: dict) -> str:
    if config.get("is_library"):
        return ""
    slug = config["slug"]
    github = config["github"]
    return (
        f"\n## Download\n\n"
        f"Get the latest APK from the [Releases page]({github}/releases/latest).\n\n"
        f"| APK | Notes |\n"
        f"|---|---|\n"
        f"| `{slug}-X.X.X.apk` | Universal — works on any device |\n"
        f"| `{slug}-X.X.X-arm64-v8a.apk` | Most modern Android phones |\n"
        f"| `{slug}-X.X.X-armeabi-v7a.apk` | Older 32-bit devices |\n"
        f"| `{slug}-X.X.X-x86_64.apk` | Emulators |\n\n"
        f"### Install via Obtainium\n\n"
        f"Add `{github}` in [Obtainium](https://github.com/ImranR98/Obtainium) to receive automatic updates. "
        f"Use the APK filter `{slug}-\\d` to select the universal build.\n"
    )


def build_family_rows(current_slug: str) -> str:
    rows = []
    for app in FAMILY:
        if app["slug"] == current_slug:
            continue
        rows.append(f"| [{app['slug']}]({app['github']}) | {app['description']} |")
    return "\n".join(rows)


def build_extra_sections(config: dict) -> str:
    sections = config.get("extra_sections", [])
    if not sections:
        return ""
    parts = []
    for section in sections:
        parts.append(f"\n## {section['title']}\n\n{section['content']}")
    return "\n".join(parts) + "\n"


def build_kofi_section(config: dict) -> str:
    url = config.get("kofi_url")
    description = config.get("kofi_description")
    if not url:
        return ""
    
    desc = description or "Support my open-source work!"
    return (
        f"\n## Support\n\n"
        f"{desc} ☕\n\n"
        f"[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)]({url})\n"
    )


def build_izzyondroid_section(config: dict) -> str:
    if not config.get("izzyondroid"):
        return ""
    slug = config["slug"]
    # auraninja uses io.github.giuig.auraninja, others use different package naming
    package = config.get("izzyondroid_package", f"io.github.giuig.{slug}")
    return (
        f"\n### Install via IzzyOnDroid\n\n"
        f"[<img src=\"https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroid.png\" alt=\"Get it on IzzyOnDroid\" height=\"80\">](https://apt.izzysoft.de/fdroid/index/apk/{package})\n"
    )


def generate(config: dict, template: str) -> str:
    return template.format(
        name=config["name"],
        description=config["description"],
        features=build_features(config["features"]),
        web_section=build_web_section(config),
        download_section=build_download_section(config),
        kofi_section=build_kofi_section(config),
        izzyondroid_section=build_izzyondroid_section(config),
        build_commands=config["build_commands"].strip(),
        extra_sections=build_extra_sections(config),
        family_rows=build_family_rows(config["slug"]),
    )


def write_readme(repo_dir: str, content: str):
    path = os.path.join(repo_dir, "README.md")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)
    print(f"  Written: {path}")


def main():
    template = load_template()
    repos = [d for d in os.listdir(REPOS_DIR)
             if os.path.isdir(os.path.join(REPOS_DIR, d))
             and os.path.exists(os.path.join(REPOS_DIR, d, "readme_config.yml"))]
    repos.sort()

    if not repos:
        print("No readme_config.yml found in any sibling repo.")
        sys.exit(1)

    for repo in repos:
        repo_dir = os.path.join(REPOS_DIR, repo)
        print(f"Generating README for {repo}...")
        config = load_config(repo_dir)
        content = generate(config, template)
        write_readme(repo_dir, content)

    print("\nDone.")


if __name__ == "__main__":
    main()
