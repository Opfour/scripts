#!/usr/bin/env python3
"""
test_rss_feeds.py - Test a list of RSS feed URLs for availability and freshness.

Reads feed URLs from a list, checks HTTP status, validates RSS/Atom XML,
and reports the last publish date to identify stale feeds.

Usage:
    python3 test_rss_feeds.py                    # Uses built-in feed list
    python3 test_rss_feeds.py feeds.txt          # One URL per line
    python3 test_rss_feeds.py --json             # JSON output
"""

import urllib.request
import urllib.error
import ssl
import sys
import json
import re
from datetime import datetime


def test_feed(name, url, timeout=10):
    """Test a single RSS feed URL. Returns dict with status info."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    result = {"name": name, "url": url, "status": 0, "is_feed": False,
              "last_pub": None, "error": None}
    try:
        req = urllib.request.Request(
            url, headers={"User-Agent": "Mozilla/5.0 (compatible; FeedChecker/1.0)"})
        resp = urllib.request.urlopen(req, timeout=timeout, context=ctx)
        result["status"] = resp.getcode()
        content = resp.read(5000).decode("utf-8", errors="replace")
        feed_tags = ["<rss", "<feed", "<rdf", "<channel", "<item", "<entry"]
        result["is_feed"] = any(tag in content.lower() for tag in feed_tags)

        # Try to extract last publish date
        date_patterns = [
            r"<pubDate>([^<]+)</pubDate>",
            r"<updated>([^<]+)</updated>",
            r"<dc:date>([^<]+)</dc:date>",
            r"<published>([^<]+)</published>",
        ]
        for pat in date_patterns:
            match = re.search(pat, content)
            if match:
                result["last_pub"] = match.group(1).strip()
                break
    except Exception as e:
        result["error"] = str(e)[:120]

    return result


def main():
    # Default feed list (thelinuxreport.com original feeds)
    feeds = [
        ("g33kinfo", "http://feeds.feedburner.com/g33kinfo/GHZm"),
        ("WebUpd8", "http://feeds2.feedburner.com/webupd8"),
        ("HowToForge", "http://www.howtoforge.com/feed.rss"),
        ("NixCraft", "http://feeds.cyberciti.biz/Nixcraft-LinuxFreebsdSolarisTipsTricks"),
        ("Tux Machines", "http://www.tuxmachines.org/node/feed"),
        ("The Geek Stuff", "http://feeds.feedburner.com/TheGeekStuff"),
        ("Ben Cane", "http://feeds.feedburner.com/bencane/SAUo"),
        ("TuxRadar", "http://www.tuxradar.com/rss"),
        ("LWN.net", "http://lwn.net/headlines/newrss"),
        ("HowToGeek News", "http://www.howtogeek.com/t/news/feed/"),
        ("HowToGeek Linux", "http://www.howtogeek.com/tag/linux/feed/"),
        ("One Thing Well", "http://onethingwell.org/rss"),
        ("Command-line-fu", "http://feeds2.feedburner.com/Command-line-fu"),
        ("Bash Shell", "http://feeds.feedburner.com/bash-shell"),
        ("Ubuntu Geek", "http://feeds.feedburner.com/UbuntuGeek"),
        ("Phoronix", "http://feeds.feedburner.com/Phoronix"),
        ("Hacker News", "http://news.ycombinator.com/rss"),
        ("LXer", "http://lxer.com/module/newswire/headlines.rss"),
        ("SourceForge Blog", "http://sourceforge.net/blog/feed/"),
        ("Freshmeat", "http://freshmeat.net/?format=atom"),
        ("Icewalkers", "http://www.icewalkers.com/backend/icewalkers.xml"),
        ("FOSSWire", "http://feeds.feedburner.com/fosswire"),
        ("Slashdot", "http://rss.slashdot.org/Slashdot/slashdot"),
        ("DistroWatch", "http://distrowatch.com/news/dw.xml"),
        ("LinuxSecurity", "http://linuxsecurity.com/static-content/linuxsecurity_articles.rss"),
        ("Blackonsole", "http://blackonsole.org/feed/"),
        ("cPanel Admin", "http://www.thecpaneladmin.com/feed/"),
        ("LanMaster53", "http://lanmaster53.com/feed/"),
        ("Konsole Minded", "http://kmandla.wordpress.com/feed/"),
        ("Linux.org", "http://www.linux.org/feeds/rss"),
        ("Linux Foundation", "http://www.linuxfoundation.org/news-media/news/rss.xml"),
        ("Linux Magazine", "http://www.linux-magazine.com/rss/feed/lmi_full"),
        ("Linux Journal", "http://feeds.feedburner.com/linuxjournalcom"),
        ("Linux Insider", "http://www.linuxinsider.com/perl/syndication/rssfull.pl"),
        ("SysAd", "http://feeds.feedburner.com/sysad"),
        ("TechRepublic", "http://www.techrepublic.com/rssfeeds/blogs/"),
        ("Planet Fedora", "http://planet.fedoraproject.org/rss20.xml"),
        ("Arch Linux News", "https://www.archlinux.org/feeds/news/"),
        ("Tech News World", "http://www.technewsworld.com/perl/syndication/rssfull.pl"),
        ("LinuxBSDos", "http://linuxbsdos.com/feed/"),
        ("Digitizor", "http://feeds.feedburner.com/digitizor"),
        ("Linuxaria", "http://feeds.feedburner.com/Linuxaria_En"),
    ]

    # If a file argument is provided, read feeds from it (one URL per line)
    if len(sys.argv) > 1 and sys.argv[1] != "--json":
        feeds = []
        with open(sys.argv[1]) as f:
            for line in f:
                url = line.strip()
                if url and not url.startswith("#"):
                    name = url.split("/")[2] if "/" in url else url
                    feeds.append((name, url))

    json_mode = "--json" in sys.argv

    results = []
    for name, url in feeds:
        r = test_feed(name, url)
        results.append(r)
        if not json_mode:
            status = "ALIVE+FEED" if r["is_feed"] else f"HTTP {r['status']}" if r["status"] else "DEAD"
            if r["error"]:
                status += f" ({r['error'][:50]})"
            pub = r["last_pub"][:30] if r["last_pub"] else "unknown"
            print(f"{status:20s} | {name:25s} | {pub:30s} | {url}")

    if json_mode:
        print(json.dumps(results, indent=2))
    else:
        alive = [r for r in results if r["is_feed"]]
        dead = [r for r in results if not r["is_feed"]]
        print(f"\n--- SUMMARY ---")
        print(f"Working feeds: {len(alive)}")
        print(f"Dead/broken:   {len(dead)}")


if __name__ == "__main__":
    main()
