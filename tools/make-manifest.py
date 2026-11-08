#!/usr/bin/env python3
"""Writes manifest.json for the files in client/ (path, size, sha256) - same format as make-manifest.ps1."""
import hashlib, json, os, sys, datetime

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
client = os.path.join(root, 'client')
message = sys.argv[1] if len(sys.argv) > 1 else ''
files = []
for dirpath, _, names in os.walk(client):
    for n in sorted(names):
        p = os.path.join(dirpath, n)
        rel = os.path.relpath(p, client).replace(os.sep, '/')
        with open(p, 'rb') as f:
            h = hashlib.sha256(f.read()).hexdigest().upper()
        files.append({'path': rel, 'size': os.path.getsize(p), 'sha256': h})
files.sort(key=lambda f: f['path'].lower())
manifest = {'version': datetime.datetime.now().strftime('%Y.%m.%d-%H%M'), 'message': message, 'files': files}
with open(os.path.join(root, 'manifest.json'), 'w') as f:
    json.dump(manifest, f, indent=1)
print(len(files), 'files,', sum(f['size'] for f in files), 'bytes ->', manifest['version'])
