#!/usr/bin/env python3
"""
sanitize_wiki_articles.py - Remove internal/proprietary references from wiki markdown files.

Scans markdown files in a directory and removes or redacts:
  - Internal wiki links (wiki.int.liquidweb.com)
  - Internal tool URLs (layer3.liquidweb.com)
  - Internal script references (files.sysres.liquidweb.com, sysres-toolbox)
  - Billing/subaccount workflow procedures (company-specific)
  - Embedded private keys (RSA, DSA, EC, etc.)

Preserves general technical content (Linux, sysadmin knowledge) while stripping
company-proprietary procedures and internal infrastructure references.

Usage:
    python3 sanitize_wiki_articles.py /path/to/wiki_articles/
    python3 sanitize_wiki_articles.py /path/to/wiki_articles/ --dry-run
    python3 sanitize_wiki_articles.py /path/to/wiki_articles/ --verbose
"""

import os
import re
import sys
import argparse
from pathlib import Path


# Patterns that indicate a line should be removed entirely
LINE_REMOVE_PATTERNS = [
    re.compile(r'https?://wiki\.int\.liquidweb\.com\S*', re.IGNORECASE),
    re.compile(r'https?://layer3\.liquidweb\.com\S*', re.IGNORECASE),
    re.compile(r'https?://files\.sysres\.liquidweb\.com\S*', re.IGNORECASE),
    re.compile(r'sysres-toolbox', re.IGNORECASE),
    re.compile(r'billing_ssh_key', re.IGNORECASE),
]

# Patterns that indicate a line references internal billing/subaccount workflows
BILLING_PATTERNS = [
    re.compile(r'\bsubaccount\b', re.IGNORECASE),
    re.compile(r'\bsub-account\b', re.IGNORECASE),
    re.compile(r'\bAuth tab\b.*\b(billing|subaccount)\b', re.IGNORECASE),
    re.compile(r'\b(billing|sub-?account)\b.*\b(page|settings|tab)\b', re.IGNORECASE),
    re.compile(r'\bsub-?account\s+page\b', re.IGNORECASE),
    re.compile(r'Modify the sub-account', re.IGNORECASE),
    re.compile(r'auth settings.*billing', re.IGNORECASE),
    re.compile(r'billing.*auth settings', re.IGNORECASE),
    re.compile(r'internal google doc', re.IGNORECASE),
    re.compile(r'internal pastebin', re.IGNORECASE),
    re.compile(r'our internal systems', re.IGNORECASE),
    re.compile(r'our ticketing system', re.IGNORECASE),
    re.compile(r'account note containing', re.IGNORECASE),
    re.compile(r'sticky note on their account', re.IGNORECASE),
    re.compile(r'note.*to the account', re.IGNORECASE),
    re.compile(r'copy-pasteable login', re.IGNORECASE),
    re.compile(r'other techs know', re.IGNORECASE),
    re.compile(r'save you and your co-?workers', re.IGNORECASE),
]

# Private key block pattern (multiline)
PRIVATE_KEY_PATTERN = re.compile(
    r'-{3,}BEGIN\s+(RSA\s+|DSA\s+|EC\s+|OPENSSH\s+|ENCRYPTED\s+)?PRIVATE\s+KEY-{3,}'
    r'.*?'
    r'-{3,}END\s+(RSA\s+|DSA\s+|EC\s+|OPENSSH\s+|ENCRYPTED\s+)?PRIVATE\s+KEY-{3,}',
    re.DOTALL
)

# Section header patterns that indicate an internal-only section
INTERNAL_SECTION_HEADERS = [
    re.compile(r'^#{1,4}\s+.*Generate a Key for billing', re.IGNORECASE),
    re.compile(r'^#{1,4}\s+.*internal\s+(wiki|doc|tool|resource)', re.IGNORECASE),
]


def should_remove_line(line):
    """Check if a line contains internal references that should be removed."""
    stripped = line.strip()
    if not stripped:
        return False

    for pat in LINE_REMOVE_PATTERNS:
        if pat.search(stripped):
            return True

    return False


def is_billing_procedure_line(line):
    """Check if a line is part of a billing/subaccount procedure."""
    for pat in BILLING_PATTERNS:
        if pat.search(line):
            return True
    return False


def is_internal_section_header(line):
    """Check if a line is a header for an internal-only section."""
    for pat in INTERNAL_SECTION_HEADERS:
        if pat.search(line.strip()):
            return True
    return False


def get_header_level(line):
    """Return the markdown header level (1-6) or 0 if not a header."""
    match = re.match(r'^(#{1,6})\s', line)
    return len(match.group(1)) if match else 0


def sanitize_content(content, filename="", verbose=False):
    """Sanitize a markdown file's content. Returns (new_content, changes_list)."""
    changes = []

    # Step 1: Remove private key blocks
    key_matches = list(PRIVATE_KEY_PATTERN.finditer(content))
    if key_matches:
        content = PRIVATE_KEY_PATTERN.sub('[PRIVATE KEY REMOVED]', content)
        changes.append(f"  Removed {len(key_matches)} private key block(s)")

    # Step 2: Process line by line
    lines = content.split('\n')
    output_lines = []
    skip_until_header_level = 0
    i = 0

    while i < len(lines):
        line = lines[i]
        header_level = get_header_level(line)

        # If we're skipping an internal section, check if we've hit a same/higher level header
        if skip_until_header_level > 0:
            if header_level > 0 and header_level <= skip_until_header_level:
                skip_until_header_level = 0
                # Don't skip this line - it's the start of a new section
            else:
                changes.append(f"  Removed line {i+1} (internal section): {line.strip()[:80]}")
                i += 1
                continue

        # Check if this is an internal section header
        if is_internal_section_header(line):
            skip_until_header_level = header_level if header_level > 0 else 999
            changes.append(f"  Removed internal section starting at line {i+1}: {line.strip()[:80]}")
            i += 1
            continue

        # Check if line should be removed (internal URLs, tools)
        if should_remove_line(line):
            changes.append(f"  Removed line {i+1}: {line.strip()[:80]}")
            i += 1
            continue

        # Check if line is a billing/subaccount procedure
        if is_billing_procedure_line(line):
            changes.append(f"  Removed line {i+1} (billing/internal): {line.strip()[:80]}")
            i += 1
            continue

        output_lines.append(line)
        i += 1

    new_content = '\n'.join(output_lines)

    # Step 3: Clean up excessive blank lines (3+ consecutive -> 2)
    new_content = re.sub(r'\n{4,}', '\n\n\n', new_content)

    return new_content, changes


def sanitize_directory(wiki_dir, dry_run=False, verbose=False):
    """Scan and sanitize all markdown files in a directory."""
    wiki_path = Path(wiki_dir)
    if not wiki_path.is_dir():
        print(f"Error: {wiki_dir} is not a directory")
        sys.exit(1)

    md_files = sorted(wiki_path.glob("*.md"))
    total_files = len(md_files)
    modified_files = 0
    total_changes = 0

    print(f"Scanning {total_files} markdown files in {wiki_dir}")
    print(f"Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print("=" * 60)

    for md_file in md_files:
        with open(md_file, 'r', encoding='utf-8', errors='replace') as f:
            original = f.read()

        sanitized, changes = sanitize_content(original, md_file.name, verbose)

        if changes:
            modified_files += 1
            total_changes += len(changes)
            print(f"\n{md_file.name}: {len(changes)} change(s)")
            if verbose:
                for c in changes:
                    print(c)

            if not dry_run:
                with open(md_file, 'w', encoding='utf-8') as f:
                    f.write(sanitized)

    print("\n" + "=" * 60)
    print(f"Files scanned:  {total_files}")
    print(f"Files modified: {modified_files}")
    print(f"Total changes:  {total_changes}")
    if dry_run:
        print("(Dry run — no files were modified)")


def main():
    parser = argparse.ArgumentParser(
        description="Remove internal/proprietary references from wiki markdown files.")
    parser.add_argument("directory", help="Path to wiki_articles directory")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be changed without modifying files")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Show each individual change")
    args = parser.parse_args()

    sanitize_directory(args.directory, dry_run=args.dry_run, verbose=args.verbose)


if __name__ == "__main__":
    main()
