#!/usr/bin/env python3
"""Regenerates docs/PAIR_TRACKER.md from GitHub (merged PRs) and git (co-author trailers on main).
Usage: python3 scripts/pair-tracker.py   (needs the gh CLI logged in as poncema4)"""
import json, subprocess

CO = "Co-authored-by: poncema4 <144962839+poncema4@users.noreply.github.com>"
prs = json.loads(subprocess.check_output(["gh", "pr", "list", "--state", "merged", "--limit", "200", "--json", "number,title,mergedAt,url"]))
prs.sort(key=lambda p: p["number"])
log = subprocess.check_output(["git", "log", "origin/main", "--format=%H%x1f%an%x1f%b%x1e"]).decode().split("\x1e")
commits = [c.strip("\n").split("\x1f") for c in log if c.strip()]
total = sum(1 for c in commits if len(c) >= 3 and CO in c[2])
doc = [
    "# Pair Extraordinaire tracker", "",
    "Goal: raise the Pair Extraordinaire badge on the personal account `poncema4`.", "",
    "**How it is earned**: commits that carry a `Co-authored-by:` trailer, included in a pull request that is merged. Every PR here is rebase-merged so the trailer survives on `main`. The author is `Claude <noreply@anthropic.com>`; the co-author is `poncema4 <144962839+poncema4@users.noreply.github.com>` (the verified GitHub no-reply address).", "",
    "**Tiers are community-reported, not an official GitHub page**: 1 (default), 10 (Bronze), 24 (Silver), 48 (Gold) co-authored commits on merged PRs. Whether the badge has advanced can only be seen on the profile at github.com/poncema4.", "",
    f"**Verified count on `main`**: {total} commits carry the poncema4 co-author trailer; {len(prs)} merged PRs (`python3 scripts/pair-tracker.py` regenerates this file).", "",
    "## Merged PRs", "", "| PR | Title | Merged |", "|---|---|---|",
]
for p in prs:
    doc.append(f"| [#{p['number']}]({p['url']}) | {p['title']} | {p['mergedAt'][:10]} |")
doc += ["", "One PR counts once however many commits it has; the count above is commits, which is what the tiers are described in.", "",
        "Rules we follow: real changes only (no padding), never a made-up co-author, branch deleted after each merge."]
open("docs/PAIR_TRACKER.md", "w").write("\n".join(doc) + "\n")
print(total, len(prs))
