"""Writes the examples of Book 4, chapter "Cloud and Infrastructure as Code", in English and Arabic.
Run: python3 make.py   (downloads OpenTofu 1.10.6 and its Docker provider the first time; needs Docker)

Bit Booking's infrastructure, described in OpenTofu (the open-source fork of Terraform): a private network,
a PostgreSQL database with its volume, and two copies of the application, here as Docker containers on this
machine so that every command really runs; in the cloud the same files would use the cloud's provider and
describe virtual machines, a managed database and a load balancer. Recorded: plan, apply, a plan with
nothing to do, a change of version, drift made by hand and found, and destroy. Transcripts are *.sh.
"""
import os
import re
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Session, fill  # noqa: E402

TOFU = "1.10.6"
CACHE = Path.home() / ".cache" / "b4-tofu"

T = {
    "en": dict(
        w_c_provider="which provider turns these blocks into real things, at an exact version",
        w_c_net="a private network: only the app copies can reach the database",
        w_c_db="the database keeps its data in a named volume, which outlives the container",
        w_c_secret="never a password in the code: it arrives as a variable, from the pipeline's secret store",
        w_c_app="count: two identical copies, as Chapter 6 showed stateless copies should be",
        w_c_version="which release runs: the pipeline sets it to the image's commit",
        w_c_out="what other tools need to know after an apply",
        w_s_init="Download the provider", w_s_plan="What would change?", w_s_apply="Make it so",
        w_s_check="The two copies answer", w_s_again="Plan again: nothing to do",
        w_s_v2="Release v2: the plan shows exactly what will be replaced",
        w_s_drift="Someone removes a container by hand; the next plan finds it",
        w_s_destroy="Remove everything",
    ),
    "ar": dict(
        w_c_provider="أي مزوّد يحوّل هذه الكتل إلى أشياء حقيقية، بإصدار محدد",
        w_c_net="شبكة خاصة: لا تصل إلى قاعدة البيانات إلا نسخ التطبيق",
        w_c_db="تحفظ قاعدة البيانات بياناتها في وحدة تخزين مسماة، تعيش أطول من الحاوية",
        w_c_secret="لا كلمة مرور في الكود أبداً: تصل متغيراً، من مخزن أسرار الخط",
        w_c_app="count: نسختان متطابقتان، كما أظهر الفصل 6 أن النسخ بلا حالة يجب أن تكون",
        w_c_version="أي إصدار يعمل: يضبطه الخط على commit الصورة",
        w_c_out="ما تحتاج الأدوات الأخرى معرفته بعد التطبيق",
        w_s_init="نزّل المزوّد", w_s_plan="ما الذي سيتغير؟", w_s_apply="نفّذ",
        w_s_check="النسختان تجيبان", w_s_again="خطّط من جديد: لا شيء يُعمل",
        w_s_v2="أطلق v2: تُظهر الخطة بالضبط ما سيُستبدل",
        w_s_drift="أحدهم يحذف حاوية باليد؛ والخطة التالية تجد ذلك",
        w_s_destroy="احذف كل شيء",
    ),
}

FILES = {
    "versions.tf": '''terraform {
  required_version = ">= 1.10"
  # {w_c_provider}
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.5.0"
    }
  }
}

provider "docker" {}
''',
    "variables.tf": '''variable "app_version" {
  # {w_c_version}
  type    = string
  default = "v1"
}

variable "app_copies" {
  type    = number
  default = 2
}

variable "db_password" {
  # {w_c_secret}
  type      = string
  sensitive = true
}
''',
    "main.tf": '''# {w_c_net}
resource "docker_network" "private" {
  name = "bit-private"
}

resource "docker_image" "postgres" {
  name         = "postgres:18"
  keep_locally = true
}

resource "docker_image" "node" {
  name         = "node:22-slim"
  keep_locally = true
}

# {w_c_db}
resource "docker_volume" "db_data" {
  name = "bit-db-data"
}

resource "docker_container" "db" {
  name  = "bit-db"
  image = docker_image.postgres.image_id
  env   = ["POSTGRES_PASSWORD=${var.db_password}", "POSTGRES_DB=booking"]
  networks_advanced {
    name = docker_network.private.id
  }
  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql"
  }
}

# {w_c_app}
resource "docker_container" "app" {
  count   = var.app_copies
  name    = "bit-app-${count.index + 1}"
  image   = docker_image.node.image_id
  command = ["node", "-e", "require('http').createServer((q, s) => s.end(process.env.VERSION + ' from ' + require('os').hostname())).listen(3000)"]
  env     = ["VERSION=${var.app_version}", "DATABASE_HOST=${docker_container.db.name}"]
  networks_advanced {
    name = docker_network.private.id
  }
  ports {
    internal = 3000
    external = 8081 + count.index
  }
}
''',
    "outputs.tf": '''# {w_c_out}
output "app_urls" {
  value = [for c in docker_container.app : "http://localhost:${c.ports[0].external}"]
}
''',
}


def tofu_binary():
    target = CACHE / TOFU / "tofu"
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        archive = target.parent / "tofu.zip"
        url = f"https://github.com/opentofu/opentofu/releases/download/v{TOFU}/tofu_{TOFU}_linux_amd64.zip"
        urllib.request.urlretrieve(url, archive)
        with zipfile.ZipFile(archive) as z:
            z.extract("tofu", target.parent)
        target.chmod(0o755)
        archive.unlink()
    return target


def clean(text):
    """Tofu's output without colours, without the blank lines, and with container ids shortened."""
    text = re.sub(r"\x1b\[[0-9;]*m", "", text)
    text = re.sub(r"\b[0-9a-f]{64}\b", lambda m: m.group(0)[:12], text)
    text = re.sub(r"\[id=sha256:[0-9a-f]+[^\]]*\]", "[id=sha256:…]", text)
    text = re.sub(r"(after|Creation complete after|Destruction complete after) [0-9.]+s", r"\1 …s", text)
    return "\n".join(line.rstrip() for line in text.split("\n") if line.strip())


def record(folder, t):
    tofu = tofu_binary()
    bin_dir = folder / ".bin"
    bin_dir.mkdir()
    (bin_dir / "tofu").symlink_to(tofu)
    env = dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}", TF_IN_AUTOMATION="1",
               TF_VAR_db_password="a-secret-from-the-pipeline", TF_PLUGIN_CACHE_DIR=str(CACHE / "plugins"))
    (CACHE / "plugins").mkdir(parents=True, exist_ok=True)

    def run(cmd, keep=None):
        r = subprocess.run(cmd, shell=True, cwd=folder, env=env, capture_output=True, text=True, timeout=300)
        out = clean(r.stdout + r.stderr)
        if r.returncode:
            raise RuntimeError(f"{cmd}:\n{out}")
        lines = out.split("\n")
        return [line for line in lines if keep(line)] if keep else lines

    for name in ("bit-db", "bit-app-1", "bit-app-2"):
        subprocess.run(["docker", "rm", "-f", name], capture_output=True)
    subprocess.run(["docker", "network", "rm", "bit-private"], capture_output=True)
    subprocess.run(["docker", "volume", "rm", "bit-db-data"], capture_output=True)

    lines = [f"# {t['w_s_init']}", "$ tofu init"]
    lines += run("tofu init -no-color", keep=lambda l: "Installing" in l or "Installed" in l or "initialized" in l)
    lines += [f"# {t['w_s_plan']}", "$ tofu plan"]
    lines += run("tofu plan -no-color", keep=lambda l: re.match(r"^  # |^Plan:", l))
    (folder / "plan.sh").write_text("\n".join(lines) + "\n")

    lines = [f"# {t['w_s_apply']}", "$ tofu apply -auto-approve"]
    lines += run("tofu apply -no-color -auto-approve",
                 keep=lambda l: "Creation complete" in l or l.startswith("Apply complete"))
    lines += ["$ tofu output app_urls"] + run("tofu output -no-color app_urls")
    lines += [f"# {t['w_s_check']}", "$ curl -s localhost:8081; echo; curl -s localhost:8082; echo"]
    import time
    for port in (8081, 8082):
        for _ in range(50):
            answer = subprocess.run(["curl", "-s", "-m", "2", f"localhost:{port}"], capture_output=True,
                                    text=True, env=CLEAN).stdout
            if answer:
                break
            time.sleep(0.2)
        lines.append(answer)
    lines += [f"# {t['w_s_again']}", "$ tofu plan"]
    lines += run("tofu plan -no-color", keep=lambda l: l.startswith("No changes"))
    (folder / "apply.sh").write_text("\n".join(lines) + "\n")

    lines = [f"# {t['w_s_v2']}", "$ tofu plan -var app_version=v2"]
    lines += run("tofu plan -no-color -var app_version=v2",
                 keep=lambda l: re.match(r"^  # |^Plan:|^      ~ env", l) or "forces replacement" in l)
    (folder / "change.sh").write_text("\n".join(lines) + "\n")

    subprocess.run(["docker", "rm", "-f", "bit-app-2"], capture_output=True)
    lines = [f"# {t['w_s_drift']}", "$ docker rm -f bit-app-2", "bit-app-2", "$ tofu plan"]
    lines += run("tofu plan -no-color", keep=lambda l: re.match(r"^  # |^Plan:", l))
    (folder / "drift.sh").write_text("\n".join(lines) + "\n")

    lines = [f"# {t['w_s_destroy']}", "$ tofu destroy -auto-approve"]
    lines += run("tofu destroy -no-color -auto-approve", keep=lambda l: l.startswith("Destroy complete"))
    (folder / "destroy.sh").write_text("\n".join(lines) + "\n")

    for name in (".bin", ".terraform"):
        shutil.rmtree(folder / name, ignore_errors=True)
    for name in ("terraform.tfstate", "terraform.tfstate.backup"):
        (folder / name).unlink(missing_ok=True)


for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    record(folder, t)
    print("wrote", lang)
