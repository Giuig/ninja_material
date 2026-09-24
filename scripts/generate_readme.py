#!/usr/bin/env python3
"""
Generate README.md for all ninja apps from per-app readme_config.yml files.

Usage:
    python generate_readme.py                            # write every repo found
    python generate_readme.py --repo auraninja           # write just that one
    python generate_readme.py --repo auraninja --check    # verify only, never write

`--repo` exists so CI can run this with only ninja_material and the one app
checked out, instead of needing all four side by side. That is safe because the
family table comes from the FAMILY list below, not from whichever directories
happen to be present — see build_family_rows.

`--check` is what runs on a pull request. It regenerates in memory and diffs
against the committed README, so a hand-edit to README.md fails the build now
rather than being silently reverted by the next write run — which is how four
configs quietly drifted between 2026-04 and 2026-09.

Requires: PyYAML  (pip install pyyaml)
"""

import argparse
import difflib
import sys
import os
from urllib.parse import quote

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


def build_badges(config: dict) -> str:
    # Opt-in per app via `badges:` in readme_config.yml, because the same row is
    # not right everywhere: a `stars` badge only helps once the count is worth
    # showing, and `izzyondroid` needs an actual listing. The GPLv3 badge is not
    # here — it already lives in the License section and should not be doubled.
    kinds = config.get("badges", [])
    if not kinds:
        return ""

    slug = config["slug"]
    github = config["github"]
    repo_path = github.replace("https://github.com/", "")

    badges = []
    for kind in kinds:
        if kind == "release":
            badges.append(
                f"[![Release](https://img.shields.io/github/v/release/{repo_path})]"
                f"({github}/releases/latest)"
            )
        elif kind == "izzyondroid":
            package = config.get("izzyondroid_package", f"io.github.giuig.{slug}")
            endpoint = quote(
                f"https://apt.izzysoft.de/fdroid/api/v1/shield/{package}", safe=""
            )
            badges.append(
                f"[![IzzyOnDroid](https://img.shields.io/endpoint?url={endpoint})]"
                f"(https://apt.izzysoft.de/fdroid/index/apk/{package})"
            )
        elif kind == "stars":
            badges.append(
                f"[![Stars](https://img.shields.io/github/stars/{repo_path})]"
                f"({github}/stargazers)"
            )
        else:
            raise ValueError(f"Unknown badge {kind!r} in {slug}/readme_config.yml")

    return "\n" + "\n".join(badges) + "\n"


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
    # Built from FAMILY, not from the sibling directories on disk. This is what
    # makes `--repo` sound: a single-repo run still emits the complete family
    # table, so CI only needs ninja_material plus the one app checked out. If
    # this ever starts discovering repos instead, `--repo` runs would silently
    # start dropping rows from every other app's table.
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
        badges=build_badges(config),
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


def readme_path(repo_dir: str) -> str:
    return os.path.join(repo_dir, "README.md")


def write_readme(repo_dir: str, content: str):
    path = readme_path(repo_dir)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)
    print(f"  Written: {path}")


def check_readme(repo_dir: str, expected: str) -> bool:
    """Diff the generated README against the committed one. Never writes."""
    slug = os.path.basename(repo_dir.rstrip(os.sep))
    path = readme_path(repo_dir)

    if not os.path.exists(path):
        print(f"  FAILED: {path} does not exist.")
        print(f"  Create it with: python generate_readme.py --repo {slug}")
        return False

    # newline="" keeps the file's own line endings instead of normalising them,
    # so a CRLF checkout is named as such below rather than showing up as a
    # whole-file diff in which every line looks identical.
    with open(path, "r", encoding="utf-8", newline="") as f:
        actual = f.read()

    if actual == expected:
        print(f"  OK: README.md matches readme_config.yml.")
        return True

    if actual.replace("\r\n", "\n") == expected:
        print(f"  FAILED: {path} has CRLF line endings; the generator writes LF.")
        print("  The content itself is in sync — fix the checkout, not the file.")
        print("  .gitattributes marks *.md as `text eol=lf` for exactly this.")
        return False

    print(f"  FAILED: README.md does not match what readme_config.yml generates.")
    for line in difflib.unified_diff(
        actual.splitlines(),
        expected.splitlines(),
        fromfile=f"{slug}/README.md (committed)",
        tofile=f"{slug}/README.md (generated)",
        lineterm="",
    ):
        print(f"  {line}")

    # Say which file to edit. Without this the failure reads as a mystery: the
    # diff points at README.md, which is the one file that must NOT be edited.
    print()
    print("  README.md is GENERATED — do not edit it directly, the next write")
    print("  run will revert you. Edit one of:")
    print(f"    {slug}/readme_config.yml                      (this app's content)")
    print("    ninja_material/scripts/readme_template.md    (shared layout)")
    print(f"  then run: python generate_readme.py --repo {slug}")
    print("  or trigger the README sync workflow in this repo (workflow_dispatch).")
    return False


def resolve_repos(requested: str) -> list:
    """One repo when --repo was given, otherwise every sibling with a config."""
    if requested:
        repo_dir = os.path.join(REPOS_DIR, requested)
        if not os.path.isdir(repo_dir):
            print(f"No such directory: {repo_dir}")
            print("--repo takes a directory name sitting next to ninja_material,")
            print("e.g. --repo auraninja")
            sys.exit(1)
        if not os.path.exists(os.path.join(repo_dir, "readme_config.yml")):
            print(f"No readme_config.yml in {repo_dir}")
            sys.exit(1)
        return [requested]

    repos = sorted(
        d for d in os.listdir(REPOS_DIR)
        if os.path.isdir(os.path.join(REPOS_DIR, d))
        and os.path.exists(os.path.join(REPOS_DIR, d, "readme_config.yml"))
    )
    if not repos:
        print("No readme_config.yml found in any sibling repo.")
        sys.exit(1)
    return repos


def main():
    parser = argparse.ArgumentParser(
        description="Generate ninja app READMEs from per-app readme_config.yml.",
    )
    parser.add_argument(
        "--repo",
        metavar="SLUG",
        help="Only handle this repo, named by its directory next to "
             "ninja_material. Default: every sibling that has a "
             "readme_config.yml, which needs all four checked out.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify only. Generates in memory, prints a diff against the "
             "committed README and exits non-zero if they differ. Writes nothing.",
    )
    args = parser.parse_args()

    repos = resolve_repos(args.repo)
    template = load_template()
    out_of_sync = []

    for repo in repos:
        repo_dir = os.path.join(REPOS_DIR, repo)
        print(f"{'Checking' if args.check else 'Generating'} README for {repo}...")
        config = load_config(repo_dir)
        content = generate(config, template)
        if args.check:
            if not check_readme(repo_dir, content):
                out_of_sync.append(repo)
        else:
            write_readme(repo_dir, content)

    if out_of_sync:
        print(f"\nOut of sync: {', '.join(out_of_sync)}")
        sys.exit(1)

    print("\nDone.")


if __name__ == "__main__":
    main()
