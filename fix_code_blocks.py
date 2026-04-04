#!/usr/bin/env python3
"""
fix_code_blocks.py - Fix code formatting in WordPress blog posts.

Detects paragraphs that contain commands, code output, config snippets,
or technical content that should be wrapped in <pre><code> blocks instead
of plain <p> tags. Designed for wiki-sourced technical articles about
Linux system administration, DNS, Apache, MySQL, etc.

Usage:
    python3 fix_code_blocks.py [--dry-run] [--post-id ID]

    --dry-run   Show what would change without updating posts
    --post-id   Fix a single post by ID (for testing)
"""

import re
import subprocess
import sys
import json

# Patterns that indicate a line is code/command/output rather than prose
CODE_PATTERNS = [
    # Shell commands
    r'^\s*(sudo |yum |dnf |apt |apt-get |systemctl |service |chmod |chown |chgrp |mkdir |cp |mv |rm |ls |cat |grep |awk |sed |find |tar |wget |curl |ssh |scp |rsync |git |docker |pip |npm |make |cd |echo |export |source |nano |vi |vim |head |tail |less |more |wc |sort |uniq |cut |tr |diff |patch |mount |umount |fdisk |df |du |ps |top |kill |pkill |nohup |crontab |at |useradd |userdel |usermod |groupadd |passwd |su |id |whoami |hostname |ifconfig |ip |ping |traceroute |netstat |ss |dig |nslookup |host |whois |iptables |firewall-cmd |ufw |rpm |dpkg )',
    # Commands with common prefixes
    r'^\s*(#|root@|\$|%|>>>)\s',
    # File paths that look like commands
    r'^\s*(/usr/|/etc/|/var/|/opt/|/home/|/root/|/tmp/|/bin/|/sbin/)\S+',
    # DNS dig output
    r'^;;\s*(QUESTION|ANSWER|AUTHORITY|ADDITIONAL)\s+SECTION:',
    r'^;\S+\.\s+IN\s+(A|AAAA|MX|NS|TXT|SOA|SRV|CNAME|PTR)',
    r'^\S+\.\s+\d+\s+IN\s+(A|AAAA|MX|NS|TXT|SOA|SRV|CNAME|PTR)\s',
    # Config file lines
    r'^\s*(<VirtualHost|<Directory|<Location|<IfModule|</|ServerName|ServerAlias|DocumentRoot|ErrorLog|CustomLog|Options|AllowOverride|Require|Listen|LoadModule|Include)',
    # Apache/nginx config
    r'^\s*(server\s*\{|location\s|proxy_pass|root\s|index\s|error_page)',
    # INI-style config
    r'^\s*\[[\w\s\.-]+\]\s*$',
    # Key=value config lines
    r'^\s*\w[\w\._-]*\s*=\s*\S',
    # MySQL/SQL
    r'^\s*(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|GRANT|REVOKE|USE|SHOW|DESCRIBE|EXPLAIN|SET|FLUSH|mysql>|MariaDB)',
    # PHP code
    r'^\s*(<\?php|\$\w+\s*=|function\s+\w+|class\s+\w+|require|include|echo\s)',
    # Output with common patterns
    r'^\s*\d+\.\d+\.\d+\.\d+',  # IP addresses at start
    r'^\s*-rw|^\s*drw|^\s*lrw',  # ls -l output
    r'^\s*total\s+\d+',  # ls total line
    # Zone file records
    r'^\s*\S+\s+\d+\s+IN\s+',
    # Common output markers
    r'^\s*(output:|result:|example:|---+|===+|\*\*\*+)',
    # Indented code (4+ spaces or tab)
    r'^\s{4,}\S',
    r'^\t+\S',
    # Usage lines
    r'^\s*usage:\s',
    # Shebang lines
    r'^#!/',
    # Package manager output
    r'^\s*(Loaded|Active|CGroup|Main PID|installed|Resolving|Setting up|Unpacking|Processing)',
    # Log lines
    r'^\[?(Mon|Tue|Wed|Thu|Fri|Sat|Sun|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
    # Cron format
    r'^\s*[\d\*]+\s+[\d\*]+\s+[\d\*]+\s+[\d\*]+\s+[\d\*]+\s+',
    # Variable assignments
    r'^\s*(export\s+)?\w+=',
    # Pipe chains
    r'.*\|\s*(grep|awk|sed|sort|uniq|wc|head|tail|cut|tr|xargs)',
]

# Patterns that indicate a line is definitely prose (not code)
PROSE_PATTERNS = [
    r'^(The|This|That|These|Those|A|An|In|On|At|For|To|From|With|By|As|If|When|Where|How|What|Why|Which|It|You|We|They|He|She|Is|Are|Was|Were|Has|Have|Had|Can|Could|Would|Should|May|Might|Must|Will|Shall|Do|Does|Did|Not|But|And|Or|So|Yet|Both|Either|Neither|Each|Every|All|Some|Any|No|Most|More|Many|Few|Much|Such|Very|Also|Just|Only|Even|Still|Already|Always|Never|Often|Usually|Sometimes|Here|There|Now|Then|Note|NOTE|Below|Above|Example)\b',
    r'\.\s*$',  # Ends with a period (sentences)
    r'^[A-Z][a-z]+\s+[a-z]+\s+[a-z]+',  # Natural language sentence pattern
]

# Compile patterns
code_regexes = [re.compile(p, re.IGNORECASE if 'QUESTION' in p or 'SELECT' in p else 0) for p in CODE_PATTERNS]
prose_regexes = [re.compile(p) for p in PROSE_PATTERNS]


def is_code_line(text):
    """Determine if a stripped text line looks like code."""
    text = text.strip()
    if not text:
        return False

    # Skip lines that are just URLs (references, not commands)
    if re.match(r'^https?://\S+$', text):
        return False

    # Skip lines containing HTML tags (bold, links, etc.) — likely prose with formatting
    if re.search(r'<(strong|em|a |b>|i>)', text):
        return False

    # Skip lines that are clearly prose sentences (start with common words, end with period)
    if re.match(r'^(The|This|That|These|Those|A|An|In|On|At|For|To|From|With|By|As|If|When|Where|How|What|Why|Which|It|You|We|They|He|She|Is|Are|Was|Were|Has|Have|Had|Can|Could|Would|Should|May|Might|Must|Will|Shall|Do|Does|Did|Not|But|And|Or|So|Yet|Both|Either|Neither|Each|Every|All|Some|Any|No|Most|More|Many|Few|Much|Such|Very|Also|Just|Only|Even|Still|Already|Always|Never|Often|Usually|Sometimes|Here|There|Now|Then|Note|NOTE|Below|Above|Once|However|Instead|After|Before)\b', text) and len(text) > 60:
        return False

    # Check code patterns first
    for regex in code_regexes:
        if regex.search(text):
            return True

    # Usage/help output patterns (word followed by spaces and dash description)
    if re.match(r'^\w+\s{2,}-\s+\w', text):
        return True

    # Short lines without sentence structure are likely code
    if len(text) < 80 and not any(r.search(text) for r in prose_regexes):
        # Contains special chars common in code
        code_chars = sum(1 for c in text if c in '{}[]()<>|&;$@#=/\\`~^')
        if code_chars >= 2:
            return True

    return False


def is_consecutive_code_block(paragraphs, start_idx):
    """Check if a series of consecutive paragraphs form a code block."""
    code_lines = []
    i = start_idx
    while i < len(paragraphs):
        text = re.sub(r'</?p>', '', paragraphs[i]).strip()
        if not text:
            i += 1
            continue
        if is_code_line(text):
            code_lines.append((i, text))
            i += 1
        else:
            break
    return code_lines


def fix_post_content(html):
    """Fix code formatting in post HTML content."""
    if not html or not html.strip():
        return html, False

    # Split into lines for processing
    lines = html.split('\n')
    result = []
    i = 0
    changed = False
    in_pre = False

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Skip if already in pre/code blocks
        if '<pre>' in stripped or '<pre ' in stripped:
            in_pre = True
            result.append(line)
            i += 1
            continue
        if '</pre>' in stripped:
            in_pre = False
            result.append(line)
            i += 1
            continue
        if in_pre:
            result.append(line)
            i += 1
            continue

        # Check if this is a <p> tag containing code
        p_match = re.match(r'^<p>(.*)</p>$', stripped)
        if p_match:
            content = p_match.group(1).strip()

            if is_code_line(content):
                # Look ahead for consecutive code paragraphs
                # Use relaxed matching for continuation lines
                code_contents = [content]
                j = i + 1
                while j < len(lines):
                    next_stripped = lines[j].strip()
                    if not next_stripped:
                        j += 1
                        continue
                    next_match = re.match(r'^<p>(.*)</p>$', next_stripped)
                    if not next_match:
                        break
                    next_content = next_match.group(1).strip()
                    if not next_content:
                        j += 1
                        continue
                    # Direct code match
                    if is_code_line(next_content):
                        code_contents.append(next_content)
                        j += 1
                        continue
                    # Continuation heuristic: short line, no HTML,
                    # doesn't start a new prose sentence
                    if (len(next_content) < 80
                            and not re.search(r'<(strong|em|a |b>|i>)', next_content)
                            and not re.match(r'^(The|This|That|These|Those|A|An|In|On|At|For|To|From|With|By|As|If|When|Where|How|What|Why|Which|It|You|We|They|He|She|Is|Are|Was|Were|Has|Have|Had|Can|Could|Would|Should|May|Might|Must|Will|Shall|Do|Does|Did|Not|But|And|Or|So|Yet|Both|Either|Neither|Each|Every|All|Some|Any|No|Most|More|Many|Few|Much|Such|Very|Also|Just|Only|Even|Still|Already|Always|Never|Often|Usually|Sometimes|Here|There|Now|Then|Note|NOTE|Below|Above|Once|However|Instead|After|Before)\b.*\.\s*$', next_content)):
                        code_contents.append(next_content)
                        j += 1
                        continue
                    break

                # Write as pre/code block
                result.append('<pre><code>' + '\n'.join(code_contents) + '</code></pre>')
                result.append('')
                changed = True
                i = j
                continue

        result.append(line)
        i += 1

    return '\n'.join(result), changed


def get_post_content(post_id):
    """Get post content from WordPress."""
    cmd = f'ssh root@host.aatrcatering.com "cd /home/davidrs/public_html && wp post get {post_id} --field=post_content --allow-root 2>/dev/null"'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout


def update_post_content(post_id, content):
    """Update post content in WordPress."""
    # Write content to temp file on VPS
    local_path = f'/tmp/post_{post_id}_fixed.html'
    with open(local_path, 'w') as f:
        f.write(content)

    # Upload and update
    subprocess.run(f'scp {local_path} root@host.aatrcatering.com:/tmp/post_{post_id}_fixed.html',
                   shell=True, capture_output=True)
    result = subprocess.run(
        f'ssh root@host.aatrcatering.com "cd /home/davidrs/public_html && wp post update {post_id} --post_content=\\"\\$(cat /tmp/post_{post_id}_fixed.html)\\" --allow-root 2>/dev/null"',
        shell=True, capture_output=True, text=True
    )
    # Cleanup
    subprocess.run(f'rm -f {local_path}', shell=True)
    subprocess.run(f'ssh root@host.aatrcatering.com "rm -f /tmp/post_{post_id}_fixed.html"',
                   shell=True, capture_output=True)
    return 'Success' in result.stdout


def main():
    dry_run = '--dry-run' in sys.argv
    single_id = None

    for i, arg in enumerate(sys.argv):
        if arg == '--post-id' and i + 1 < len(sys.argv):
            single_id = int(sys.argv[i + 1])

    if single_id:
        post_ids = [single_id]
    else:
        # Get all blog post IDs (published + future)
        cmd = 'ssh root@host.aatrcatering.com "cd /home/davidrs/public_html && wp post list --post_type=post --post_status=publish,future --fields=ID --format=csv --allow-root 2>/dev/null"'
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        post_ids = [int(line.strip()) for line in result.stdout.strip().split('\n')[1:] if line.strip().isdigit()]

    print(f"Processing {len(post_ids)} posts...")
    fixed_count = 0
    skipped_count = 0

    for pid in post_ids:
        content = get_post_content(pid)
        if not content.strip():
            print(f"  Post {pid}: empty content, skipping")
            skipped_count += 1
            continue

        fixed_content, was_changed = fix_post_content(content)

        if was_changed:
            if dry_run:
                print(f"  Post {pid}: WOULD FIX code blocks")
                fixed_count += 1
            else:
                if update_post_content(pid, fixed_content):
                    print(f"  Post {pid}: Fixed code blocks")
                    fixed_count += 1
                else:
                    print(f"  Post {pid}: FAILED to update")
        else:
            skipped_count += 1

    print(f"\nDone. Fixed: {fixed_count}, Unchanged: {skipped_count}")


if __name__ == '__main__':
    main()
