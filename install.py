"""Download and verify CreatorCut. Does not execute downloaded application code.

The native AI host reads the installed setup instructions and performs setup.
No GitHub account, Git or third-party Python packages required.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import tempfile
import time
import urllib.request
import zipfile

REPOSITORY = 'nategoldai/creatorcut-updates'
MAX_ZIP = 100 * 1024 * 1024
MAX_EXPANDED = 512 * 1024 * 1024

def safe_name(name):
    p = PurePosixPath(name)
    if not name or p.is_absolute() or '\\' in name or ':' in name or any(x in ('', '.', '..') for x in name.split('/')):
        raise ValueError('Unsafe package path')
    return p

def fetch(url, limit, expected=None, accept=None):
    headers={'User-Agent': 'CreatorCut-Installer', 'Cache-Control': 'no-cache'}
    if accept:
        headers['Accept']=accept
    request = urllib.request.Request(url, headers=headers)
    started = time.monotonic()
    with urllib.request.urlopen(request, timeout=30) as response:
        from urllib.parse import urlsplit
        original, final = urlsplit(url), urlsplit(response.geturl())
        if final.scheme != 'https' or final.hostname != original.hostname:
            raise ValueError('Unexpected download destination')
        chunks, total = [], 0
        while True:
            chunk = response.read(256 * 1024)
            if not chunk:
                break
            total += len(chunk)
            if total > limit or time.monotonic() - started > 600:
                raise ValueError('Download exceeded its limit; retry installation')
            chunks.append(chunk)
    if expected is not None and total != expected:
        raise ValueError('Incomplete package download; retry installation')
    return b''.join(chunks)

def download():
    url = 'https://api.github.com/repos/' + REPOSITORY + '/contents/CreatorCut-OS.zip'
    info = json.loads(fetch(url, 2 * 1024 * 1024))
    size, blob = info.get('size'), info.get('sha', '')
    raw = info.get('download_url', '')
    if info.get('type') != 'file' or info.get('path') != 'CreatorCut-OS.zip' or type(size) is not int or not 0 < size <= MAX_ZIP or not re.fullmatch('[a-f0-9]{40}', blob):
        raise ValueError('Invalid publisher package metadata')
    if not raw.startswith('https://raw.githubusercontent.com/' + REPOSITORY + '/'):
        raise ValueError('Unexpected publisher address')
    # Pin the Git object: branch/CDN propagation cannot mix old bytes with new metadata.
    payload = fetch('https://api.github.com/repos/' + REPOSITORY + '/git/blobs/' + blob,
                    MAX_ZIP, size, accept='application/vnd.github.raw+json')
    if hashlib.sha1(('blob ' + str(len(payload)) + '\0').encode() + payload).hexdigest() != blob:
        raise ValueError('Publisher package changed during download; retry installation')
    return payload

def unpack(package, destination):
    destination = Path(destination).expanduser().absolute()
    # Repeated installation must never overwrite projects or an existing app.
    if destination.exists() or destination.is_symlink():
        raise ValueError('This folder already exists. Open its Studio and use Install update; nothing was overwritten: ' + str(destination))
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(package) as archive:
        entries = archive.infolist()
        names = [x.filename for x in entries]
        if len(names) > 10000 or len(names) != len(set(names)) or sum(x.file_size for x in entries) > MAX_EXPANDED:
            raise ValueError('Invalid or oversized package')
        for item in entries:
            safe_name(item.filename.rstrip('/'))
            if (item.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError('Symbolic links are not allowed')
        roots = [n[:-len('edit.py')] for n in names if n.endswith('/CreatorCut OS/edit.py')]
        if len(roots) != 1:
            raise ValueError('Expected exactly one CreatorCut application')
        root = roots[0]
        manifest_name = root + 'kit/SHA256-MANIFEST.json'
        if archive.getinfo(manifest_name).file_size > 2 * 1024 * 1024:
            raise ValueError('Oversized verification manifest')
        hashes = json.loads(archive.read(manifest_name))
        if not isinstance(hashes, dict):
            raise ValueError('Invalid verification manifest')
        app_files = {n[len(root):] for n in names if n.startswith(root) and not n.endswith('/')}
        if app_files != set(hashes) | {'kit/SHA256-MANIFEST.json'}:
            raise ValueError('Package contains unverified application files')
        for rel, expected in hashes.items():
            safe_name(rel)
            if not isinstance(expected, str) or not re.fullmatch('[a-f0-9]{64}', expected) or hashlib.sha256(archive.read(root + rel)).hexdigest() != expected:
                raise ValueError('Package file verification failed')
        version = archive.read(root + 'kit/VERSION').decode().strip()
        if not re.fullmatch(r'\d+\.\d+\.\d+', version):
            raise ValueError('Invalid application version')
        stage = Path(tempfile.mkdtemp(prefix='.creatorcut-install-', dir=destination.parent))
        try:
            for rel in sorted(app_files):
                target = stage.joinpath(*safe_name(rel).parts)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(root + rel))
                if rel.endswith(('.py', '.sh')):
                    target.chmod(0o755)
            # Exclusive reservation prevents racing installers overwriting each other.
            destination.mkdir()
            try:
                for child in stage.iterdir():
                    os.replace(child, destination / child.name)
            except BaseException:
                # Leave recoverable files; do not delete an existing customer folder.
                raise
        finally:
            shutil.rmtree(stage, ignore_errors=True)
    return {'version': version, 'directory': str(destination), 'next': 'Read AGENTS.md and kit/skills-src/setup/SKILL.md in this directory and follow setup in the native host. Open Studio inside the host preview.'}

def main():
    parser = argparse.ArgumentParser(description='Download verified CreatorCut files; native host completes setup.')
    parser.add_argument('--directory', default=str(Path.home() / 'CreatorCut OS'))
    parser.add_argument('--package', help=argparse.SUPPRESS)
    args = parser.parse_args()
    try:
        if args.package:
            result = unpack(Path(args.package), args.directory)
        else:
            import io
            result = unpack(io.BytesIO(download()), args.directory)
        print(json.dumps(result, indent=2))
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        parser.exit(1, 'CreatorCut installation did not complete: ' + str(error) + '\n')

if __name__ == '__main__':
    main()
