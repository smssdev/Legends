import os
import re
"""Book 7's examples are JavaScript (Node 22) that talk to a free, open model running on the reader's own
computer, through the node-llama-cpp package. This kit writes a chapter's files in each language, runs them
as a reader would, in a project outside the repository, and records each terminal session.

The model is downloaded once (2.5 GB) into ~/.node-llama-cpp/models, where node-llama-cpp keeps models by
default. Answers are generated with temperature 0 unless a chapter says otherwise, so a run gives the same
text again on the same machine; another machine may differ in small ways, which the book says where it shows.
"""
import shutil
import subprocess
from pathlib import Path

import importlib.util

_spec = importlib.util.spec_from_file_location("b5kit", Path(__file__).parent.parent / "b5" / "kit.py")
b5kit = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(b5kit)
HOME, Session, fill, write = b5kit.HOME, b5kit.Session, b5kit.fill, b5kit.write

WORK = HOME / "b7-work"
LLAMA = "node-llama-cpp@3.22.3"
_env = b5kit.env


def env():
    e = _env()
    e["PATH"] = "/opt/node22/bin:" + e["PATH"]
    return e


b5kit.env = env  # every command of the kit finds Node

# A model answers at a few tokens a second on a plain processor: allow an hour per command.
_sh = b5kit.sh
b5kit.sh = lambda cmd, cwd, timeout=3600: _sh(cmd, cwd, timeout)

MODEL_NOTE = {
    "en": """// The book's model: Qwen3 4B Instruct (2507), an open model under the
// Apache 2.0 license, quantized to 4 bits by Unsloth (2.5 GB). It is
// downloaded once, the first time an example runs, into
// ~/.node-llama-cpp/models; then everything runs on your computer, offline.
""",
    "ar": """// نموذج الكتاب: Qwen3 4B Instruct (2507)، نموذج مفتوح برخصة Apache 2.0،
// ضغطته Unsloth إلى 4 بتات (2.5 GB). يُنزَّل مرة، أول مرة يعمل فيها مثال،
// في ~/.node-llama-cpp/models؛ ثم يعمل كل شيء على حاسوبك، دون اتصال.
""",
}

MODEL_JS = """import {getLlama, LlamaLogLevel, resolveModelFile} from "node-llama-cpp";

export const MODEL = "hf:unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M";

export async function loadModel() {
  const llama = await getLlama({gpu: false, logLevel: LlamaLogLevel.error});
  return llama.loadModel({modelPath: await resolveModelFile(MODEL)});
}
"""


def deps():
    """node-llama-cpp, installed once for every chapter's project."""
    base = WORK / "_deps"
    if not (base / "node_modules" / "node-llama-cpp").exists():
        base.mkdir(parents=True, exist_ok=True)
        write(base, {"package.json": '{"type": "module", "private": true}\n'})
        subprocess.run(["chown", "-R", "reader:reader", str(WORK)], check=False)
        out, code = b5kit.sh(f"npm install --silent {LLAMA}", base, timeout=1800)
        if code:
            raise RuntimeError(out)
    return base / "node_modules"


WIDTH = 74


def wrap_comments(text):
    """A comment line longer than the printed page is folded into several, so the book never wraps code."""
    out = []
    for line in text.split("\n"):
        m = re.match(r"^(\s*// )(.*)$", line)
        if not m or len(line) <= WIDTH:
            out.append(line)
            continue
        prefix, rest = m.groups()
        current = ""
        for word in rest.split(" "):
            if current and len(prefix) + len(current) + 1 + len(word) > WIDTH:
                out.append(prefix + current)
                current = word
            else:
                current = f"{current} {word}" if current else word
        out.append(prefix + current)
    return "\n".join(out)


def chapter(here, words_by_lang, files, runs, made=()):
    """files: {path: text} with {w_...} words; runs: [(transcript, command[, keep])], keep(lines) -> lines;
    made: files the examples write (code from the model), copied to the book's folder after the runs."""
    modules = deps()
    only = os.environ.get("B7_LANG")  # B7_LANG=ar runs one edition
    for lang, words in words_by_lang.items():
        if only and lang != only:
            continue
        out = here / lang
        shutil.rmtree(out, ignore_errors=True)
        base = WORK / here.name / lang
        shutil.rmtree(base, ignore_errors=True)
        base.mkdir(parents=True)
        (base / "node_modules").symlink_to(modules)
        texts = {"package.json": '{"type": "module", "private": true}\n', "lib/model.mjs": MODEL_NOTE.get(lang, MODEL_NOTE["en"]) + MODEL_JS}
        texts.update({name: wrap_comments(fill(text, words)) for name, text in files.items()})
        write(base, texts)
        write(out, texts)
        subprocess.run(["chown", "-R", "reader:reader", str(base)], check=False)
        for transcript, command, *keep in runs:
            s = Session(base)
            s.run(fill(command, words), keep=keep[0] if keep else None)
            s.save(out / transcript)
        for name in made:
            if (base / name).exists():
                (out / name).parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(base / name, out / name)
        print("wrote", out)
