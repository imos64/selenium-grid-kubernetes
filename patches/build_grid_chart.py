#!/usr/bin/env python3
"""Reproduce the narrow Grid chart patch from the SHA-locked upstream archive."""
import argparse
import difflib
import gzip
import hashlib
import io
import tarfile
from pathlib import Path

UPSTREAM_SHA = 'df90a9300ed27e220ccde25beacf90f9b5d7b145595000ca195162315174ad78'
VERSION = '0.59.1-techixora.1'
REPLACEMENTS = {
    'selenium-grid/Chart.yaml': [
        ('version: 0.59.1\n', 'version: ' + VERSION + '\n'),
    ],
    'selenium-grid/templates/_helpers.tpl': [
        ('  spec:\n    shareProcessNamespace:',
         '  spec:\n    {{- with $.Values.global.seleniumGrid.podSecurityContext }}\n'
         '    securityContext: {{- toYaml . | nindent 6 }}\n    {{- end }}\n    shareProcessNamespace:'),
    ],
    'selenium-grid/templates/hub-deployment.yaml': [
        ('    spec:\n      serviceAccountName:',
         '    spec:\n      {{- with .Values.global.seleniumGrid.podSecurityContext }}\n'
         '      securityContext: {{- toYaml . | nindent 8 }}\n      {{- end }}\n      serviceAccountName:'),
        ('      containers:\n',
         '      {{- with .Values.hub.initContainers }}\n'
         '      initContainers: {{- toYaml . | nindent 8 }}\n      {{- end }}\n      containers:\n'),
    ],
}


def build(upstream):
    if hashlib.sha256(upstream).hexdigest() != UPSTREAM_SHA:
        raise ValueError('wrong upstream archive')
    result, diff, changed = io.BytesIO(), [], set()
    with tarfile.open(fileobj=io.BytesIO(upstream), mode='r:gz') as src:
        with gzip.GzipFile(fileobj=result, mode='wb', filename='', mtime=0) as gz:
            with tarfile.open(fileobj=gz, mode='w', format=tarfile.PAX_FORMAT) as dst:
                for member in src.getmembers():
                    if not member.isfile():
                        raise ValueError('unexpected archive member')
                    data = src.extractfile(member).read()
                    if member.name in REPLACEMENTS:
                        before = data.decode()
                        after = before
                        for old, new in REPLACEMENTS[member.name]:
                            if after.count(old) != 1:
                                raise ValueError('patch context changed: ' + member.name)
                            after = after.replace(old, new)
                        diff.extend(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                                                       'a/' + member.name, 'b/' + member.name))
                        data = after.encode();changed.add(member.name)
                    member.size = len(data)
                    dst.addfile(member, io.BytesIO(data))
    if changed != set(REPLACEMENTS):
        raise ValueError('missing patch targets')
    return result.getvalue(), ''.join(diff)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('upstream', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--check', action='store_true', help='compare committed bytes without writing')
    args = parser.parse_args()
    archive, patch = build(args.upstream.read_bytes())
    patch_path = Path(__file__).with_name('selenium-grid.patch')
    if args.check:
        if args.output.read_bytes() != archive or patch_path.read_text() != patch:
            raise ValueError('committed archive or patch is not reproducible')
    else:
        args.output.write_bytes(archive)
        patch_path.write_text(patch)
    print(hashlib.sha256(archive).hexdigest())
