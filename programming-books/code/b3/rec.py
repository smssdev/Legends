"""Helpers for Book 3's examples: start a real server, run real commands against it, and save what the
terminal showed as a transcript (a .sh file the book prints).

  fill(text, words)          replaces {w_name} placeholders, and nothing else (code is full of braces)
  with Server(cmd, cwd, url) as s:   starts the server, waits until url answers, stops it at the end;
                             s.log() is what the server printed so far
  Session(cwd)               s.note("comment"); s.run("curl ...", shown=None) -> output; s.save(path)
"""
import os
import re
import subprocess
import time
from pathlib import Path


# The commands run as on a reader's machine: without this container's proxy settings (curl -v would print them).
# The PHP wrappers in bin/ (PHP runs in Docker) still need the network for Composer: they get the proxy and
# certificates under names that curl and Node ignore.
CLEAN = {k: v for k, v in os.environ.items() if "proxy" not in k.lower()}
CLEAN["PATH"] = str(Path(__file__).parent / "bin") + ":" + CLEAN["PATH"]
if os.environ.get("HTTPS_PROXY"):
    CLEAN["B3_PROXY"] = os.environ["HTTPS_PROXY"]
    CLEAN["B3_CERTS"] = os.environ.get("SSL_CERT_FILE", "")


def fill(text, words):
    return re.sub(r"\{(w_\w+)\}", lambda m: words[m.group(1)], text)


class Server:
    def __init__(self, cmd, cwd, url, env=None):
        """url is only used to check that the server is up; its request is left out of log()."""
        self.cmd, self.cwd, self.url, self.env = cmd, Path(cwd), url, env or CLEAN
        self.out = self.cwd / ".server.log"

    def __enter__(self):
        self.file = open(self.out, "w")
        self.proc = subprocess.Popen(self.cmd, shell=True, cwd=self.cwd, stdout=self.file,
                                     stderr=subprocess.STDOUT, env=self.env, start_new_session=True)
        for _ in range(100):
            if subprocess.run(["curl", "-s", "-o", "/dev/null", self.url], env=CLEAN).returncode == 0:
                time.sleep(0.3)
                self.file.flush()
                text = self.out.read_text()
                # What the server printed when it started (before the check's request), and where the reader's
                # own requests begin.
                head = []
                for line in text.split("\n"):
                    if "Accepted" in line or self.url.rsplit("/", 1)[-1] in line:
                        break
                    head.append(line)
                self.head, self.skip = "\n".join(head).strip("\n"), len(text.encode())
                return self
            time.sleep(0.1)
        raise RuntimeError(f"{self.cmd} did not start:\n{self.log()}")

    def log(self, lines=None):
        """What the server printed, without the start-up check; at most `lines` lines after the first."""
        self.file.flush()
        time.sleep(0.2)
        rest = self.out.read_bytes()[self.skip:].decode().strip("\n").split("\n")
        if lines and len(rest) > lines:
            rest = rest[:lines] + ["..."]
        return "\n".join([self.head] + rest)

    def __exit__(self, *exc):
        import os
        import signal
        os.killpg(self.proc.pid, signal.SIGTERM)
        self.proc.wait()
        self.file.close()
        self.out.unlink()


class Session:
    def __init__(self, cwd):
        self.cwd, self.lines = Path(cwd), []

    def note(self, text):
        self.lines.append(f"# {text}")

    def run(self, cmd, shown=None, check=True):
        """Runs cmd; the transcript shows `shown` (the same command as the reader types it) if given."""
        r = subprocess.run(["bash", "-c", cmd], cwd=self.cwd, capture_output=True, text=True, timeout=60, env=CLEAN)
        out = (r.stdout + r.stderr).replace("\r", "").rstrip("\n")
        if check and r.returncode:
            raise RuntimeError(f"{cmd} failed ({r.returncode}):\n{out}")
        self.lines.append("$ " + (shown or cmd))
        if out:
            self.lines.extend(out.split("\n"))
        return out

    def add(self, text):
        self.lines.extend(text.rstrip("\n").split("\n"))

    def save(self, path):
        Path(path).write_text("\n".join(self.lines) + "\n")
        self.lines = []
