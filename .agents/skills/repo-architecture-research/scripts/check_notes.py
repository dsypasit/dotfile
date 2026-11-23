#!/usr/bin/env python3
"""Static checks for architecture notes before you claim they are done.

Dependency-free. Catches the failure classes that actually break these docs:

  * frontmatter missing or malformed
  * unbalanced ``` fences (a diagram that swallows the rest of the note)
  * mermaid-hostile characters and unquoted flowchart labels
  * wikilinks whose target is missing, or whose name collides with another note/folder
  * duplicate note basenames across the scan root (ambiguous [[links]])

Usage:
    python3 check_notes.py <docs-root> [--quiet]

Exit code 1 when any ERROR is reported, 0 otherwise (warnings alone do not fail).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

MERMAID_FENCE = re.compile(r"```mermaid\n(.*?)```", re.S)
FENCE = re.compile(r"^\s*```", re.M)
LINK = re.compile(r"\[\[([^\]\|#]+)(?:[#\|][^\]]*)?\]\]")
# node definition: ID[ ... / ID{ ... / ID([ ...  with an unquoted first char
NODE = re.compile(r'(?<![\w"])([A-Za-z0-9_]+)(\[\[|\(\[|\{\{|\[|\(|\{)([^"\s\[\(\{])')


def check_frontmatter(path: Path, text: str, errors: list[str], warnings: list[str]) -> None:
    if not text.startswith("---"):
        warnings.append(f"{path}: no frontmatter block")
        return
    parts = text.split("---", 2)
    if len(parts) < 3:
        errors.append(f"{path}: unterminated frontmatter")
        return
    for line in parts[1].splitlines():
        s = line.rstrip()
        if not s or s.lstrip().startswith("#"):
            continue
        if s.startswith((" ", "\t", "-")):  # nested value / list item
            continue
        if ":" not in s:
            errors.append(f"{path}: frontmatter line without ':': {s!r}")


def check_fences(path: Path, text: str, errors: list[str]) -> int:
    fences = len(FENCE.findall(text))
    if fences % 2:
        errors.append(f"{path}: unbalanced code fences ({fences})")
    return len(MERMAID_FENCE.findall(text))


def check_mermaid(path: Path, text: str, errors: list[str], warnings: list[str]) -> None:
    for block_index, block in enumerate(MERMAID_FENCE.findall(text), 1):
        lines = block.splitlines()
        kind = lines[0].strip() if lines else ""
        for lineno, line in enumerate(lines, 1):
            s = line.strip()
            if not s or s.startswith("%%"):
                continue
            for ch, why in ((";", "statement separator"), ("\\", "escape")):
                if ch in s:
                    errors.append(
                        f"{path} mermaid#{block_index} L{lineno}: {ch!r} ({why}) -> {s}"
                    )
            if s.startswith("#"):
                warnings.append(f"{path} mermaid#{block_index} L{lineno}: '#' at line start")
            if kind.startswith(("flowchart", "graph")):
                for m in NODE.finditer(s):
                    tail = s[m.end() - 1 :]
                    if tail.startswith("|") or '"' in s[m.start() :].split("-->")[0]:
                        continue
                    errors.append(
                        f"{path} mermaid#{block_index} L{lineno}: unquoted node label -> {s}"
                    )
                    break


def find_index_root(scan_root: Path) -> Path:
    """Wikilinks resolve from the vault root, not from the scanned subfolder."""
    for parent in [scan_root, *scan_root.parents]:
        if (parent / ".obsidian").is_dir():
            return parent
    return scan_root


def build_target_index(root: Path) -> tuple[dict[str, list[Path]], dict[str, list[Path]]]:
    files: dict[str, list[Path]] = {}
    folders: dict[str, list[Path]] = {}
    for p in root.rglob("*.md"):
        if ".git" in p.parts:
            continue
        files.setdefault(p.stem, []).append(p)
    for p in root.rglob("*"):
        if p.is_dir() and ".git" not in p.parts:
            folders.setdefault(p.name, []).append(p)
    return files, folders


def check_links(
    index_root: Path, path: Path, text: str, index, errors: list[str], warnings: list[str]
) -> None:
    files, folders = index
    for raw in sorted(set(LINK.findall(text))):
        target = raw.strip()
        if not target:
            continue
        if "/" in target:  # path-qualified: resolved from the index (vault) root
            candidate = index_root / (target if target.endswith(".md") else target + ".md")
            if not candidate.exists() and not (index_root / target).is_dir():
                errors.append(f"{path}: broken path link [[{target}]] (from {index_root})")
            continue
        hits = files.get(target, [])
        folder_hits = folders.get(target, [])
        if len(hits) > 1:
            warnings.append(
                f"{path}: ambiguous [[{target}]] (notes: "
                + ", ".join(str(h.relative_to(index_root)) for h in hits)
                + ")"
            )
        elif not hits and not folder_hits:
            errors.append(f"{path}: unresolved link [[{target}]]")
        elif hits and folder_hits:
            warnings.append(
                f"{path}: [[{target}]] matches a note and a folder name -> qualify it"
            )


def check_duplicate_basenames(root: Path, index, warnings: list[str]) -> None:
    files, _ = index
    for stem, hits in sorted(files.items()):
        if len(hits) > 1:
            warnings.append(
                f"duplicate note name '{stem}' ("
                + ", ".join(str(h.relative_to(root)) for h in hits)
                + ") -> bare wikilinks are ambiguous"
            )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("root", type=Path)
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"not a directory: {root}", file=sys.stderr)
        return 2

    index_root = find_index_root(root)
    errors: list[str] = []
    warnings: list[str] = []
    index = build_target_index(index_root)
    check_duplicate_basenames(index_root, index, warnings)

    total_notes = 0
    total_diagrams = 0
    for path in sorted(root.rglob("*.md")):
        if ".git" in path.parts:
            continue
        total_notes += 1
        text = path.read_text(encoding="utf-8", errors="replace")
        rel = path.relative_to(root)
        check_frontmatter(rel, text, errors, warnings)
        total_diagrams += check_fences(rel, text, errors)
        check_mermaid(rel, text, errors, warnings)
        check_links(index_root, rel, text, index, errors, warnings)

    for w in warnings if not args.quiet else []:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    print(f"\n{total_notes} notes, {total_diagrams} mermaid blocks, "
          f"{len(errors)} errors, {len(warnings)} warnings "
          f"(links resolved from {index_root})")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
