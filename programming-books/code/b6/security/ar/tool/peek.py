"""What anyone who can read this browser's storage can read: the secure storage keeps its key beside its values."""
import base64
import json
import sys

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

kept = json.load(open(sys.argv[1]))
print("shared_preferences, as stored:      ", kept["token"])
key = base64.b64decode(kept["FlutterSecureStorage"])
for name, value in kept.items():
    if name.startswith("FlutterSecureStorage."):
        iv, data = (base64.b64decode(part) for part in value.split("."))
        print(f"{name}, as stored:   {value[:32]}...")
        print(f"{name}, decrypted:   {AESGCM(key).decrypt(iv, data, None).decode()}")
