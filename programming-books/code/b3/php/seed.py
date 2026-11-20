"""Puts a package's download in Composer's cache, made with git from the same commit.

Only needed on machines that can clone from GitHub but cannot download GitHub's zip files (some build
servers). Usage:
  python3 seed.py phpstan/phpstan:2.3.7 [more packages]
  python3 seed.py --lock path/to/composer.lock      every package in a lock file, in parallel

Composer keeps each download as cache/files/<package>/<sha1 of its URL>.zip, and uses it instead of
downloading again. The cache is the one bin/composer mounts (~/.cache/b3-composer).
"""
import hashlib
import re
import subprocess
import sys
import tempfile
from pathlib import Path

CACHE = Path.home() / ".cache" / "b3-composer" / "cache" / "files"


def seed(package, version):
    info = subprocess.run(["composer", "show", "-a", package, version], capture_output=True, text=True).stdout
    url = re.search(r"^dist\s*:\s*\[zip\]\s*(\S+)\s+(\S+)", info, re.M)
    if not url:
        raise SystemExit(f"{package} {version}: no zip download found")
    return seed_url(package, *url.groups())


def seed_latest(package):
    """The newest stable version of a package (what `composer require package` would choose)."""
    info = subprocess.run(["composer", "show", "-a", package], capture_output=True, text=True).stdout
    versions = re.search(r"^versions\s*:\s*(.+)$", info, re.M).group(1).split(", ")
    version = next(v.lstrip("v") for v in versions if re.fullmatch(r"v?\d+\.\d+\.\d+", v.strip("* ")))
    return seed(package, version)


def seed_url(package, url, ref):
    target = CACHE / package / f"{hashlib.sha1(url.encode()).hexdigest()}.zip"
    if target.exists():
        return target
    owner_repo = re.search(r"repos/([^/]+/[^/]+)/zipball", url).group(1)
    with tempfile.TemporaryDirectory() as tmp:
        git = ["git", "-C", tmp]
        subprocess.run(["git", "init", "-q", tmp], check=True)
        subprocess.run(git + ["fetch", "-q", "--depth", "1", f"https://github.com/{owner_repo}.git", ref], check=True)
        target.parent.mkdir(parents=True, exist_ok=True)
        prefix = owner_repo.replace("/", "-") + "-" + ref[:7] + "/"
        subprocess.run(git + ["archive", "--format=zip", f"--prefix={prefix}", "-o", str(target), "FETCH_HEAD"],
                       check=True)
    return target


def seed_lock(lock):
    import json
    from concurrent.futures import ThreadPoolExecutor
    data = json.loads(Path(lock).read_text())
    jobs = [(p["name"], p["dist"]["url"], p["dist"]["reference"])
            for p in data.get("packages", []) + data.get("packages-dev", [])
            if p.get("dist", {}).get("url", "").startswith("https://api.github.com/")]
    with ThreadPoolExecutor(8) as pool:
        return list(pool.map(lambda job: seed_url(*job), jobs))


if __name__ == "__main__":
    if sys.argv[1:2] == ["--lock"]:
        print(len(seed_lock(sys.argv[2])), "packages in the cache")
        raise SystemExit
    for spec in sys.argv[1:]:
        name, version = spec.split(":")
        print(seed(name, version))
