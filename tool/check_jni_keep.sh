#!/usr/bin/env bash
# Verifies that a release APK still contains every class, method and field
# that JNI-based Dart packages look up by name. R8 can't see those lookups;
# a missing one crashes the app at runtime (see android/app/proguard-rules.pro).
#
#   tool/check_jni_keep.sh [path/to/app-release.apk]
#
# Needs: python3, and dexdump from the Android SDK build-tools.
set -euo pipefail
cd "$(dirname "$0")/.."
APK=${1:-build/app/outputs/flutter-apk/app-release.apk}
DEXDUMP=$(ls "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/*/dexdump 2>/dev/null | tail -1)
[[ -x "$DEXDUMP" ]] || { echo "dexdump not found (set ANDROID_HOME)"; exit 2; }
python3 - "$APK" "$DEXDUMP" <<'PY'
import json, re, subprocess, sys, tempfile, zipfile, pathlib
apk, dexdump = sys.argv[1], sys.argv[2]

# Dart packages that bind Java/Kotlin via package:jni.
cfg = json.load(open('.dart_tool/package_config.json'))
roots = {}
for p in cfg['packages']:
    root = pathlib.Path(p['rootUri'].replace('file://', ''))
    if not root.is_absolute():
        root = (pathlib.Path('.dart_tool') / root).resolve()
    pub = root / 'pubspec.yaml'
    if p['name'] == 'jni' or (pub.exists() and re.search(r'^\s+jni:', pub.read_text(), re.M)):
        roots[p['name']] = root / 'lib'

S = r"r?'([^']*)'|r?\"([^\"]*)\""
cls_re = re.compile(r"(\w+)\s*=\s*(?:jni\$_\.)?JClass\.forName\(\s*(?:" + S + r")\s*,?\s*\)")
mem_re = re.compile(r"(\w+)\.(instanceMethodId|staticMethodId|instanceFieldId|staticFieldId|constructorId)\(\s*(?:" + S + r")(?:\s*,\s*(?:" + S + r"))?\s*,?\s*\)")
APP = re.compile(r'^(kotlin|kotlinx|io/flutter|com/github|androidx)/')

wanted = set()  # (class, kind, name, sig)
for pkg, lib in roots.items():
    for f in lib.rglob('*.dart'):
        src = f.read_text()
        classes = {}
        for m in cls_re.finditer(src):
            classes[m.group(1)] = m.group(2) or m.group(3)
        # Generated bindings refer to the class as `_class` per Dart class;
        # attribute each member to the nearest preceding forName.
        positions = sorted((m.start(), m.group(2) or m.group(3), m.group(1)) for m in cls_re.finditer(src))
        for m in mem_re.finditer(src):
            var, kind = m.group(1), m.group(2)
            a = m.group(3) or m.group(4); b = m.group(5) or m.group(6)
            if kind == 'constructorId':
                name, sig = '<init>', a
            else:
                name, sig = a, b
            cls = classes.get(var) if var != '_class' else None
            if cls is None:
                prev = [c for (pos, c, v) in positions if pos < m.start() and v == var]
                cls = prev[-1] if prev else None
            if cls and APP.match(cls):
                wanted.add((cls, 'field' if 'Field' in kind else 'method', name, sig))
        for c in classes.values():
            if APP.match(c):
                wanted.add((c, 'class', '', ''))

# What the APK contains.
have_cls, have_mem, supers = set(), set(), {}
with tempfile.TemporaryDirectory() as tmp:
    with zipfile.ZipFile(apk) as z:
        dexes = [n for n in z.namelist() if re.match(r'classes\d*\.dex$', n)]
        z.extractall(tmp, dexes)
    for d in dexes:
        out = subprocess.run([dexdump, f'{tmp}/{d}'], capture_output=True, text=True, errors='replace').stdout
        cur = None; section = None; name = None
        for line in out.splitlines():
            m = re.match(r"\s*Class descriptor\s*:\s*'L(.+);'", line)
            if m: cur = m.group(1); have_cls.add(cur); continue
            m = re.match(r"\s*Superclass\s*:\s*'L(.+);'", line)
            if m and cur: supers[cur] = m.group(1); continue
            if re.match(r'\s*(Direct|Virtual) methods', line): section = 'method'; continue
            if re.match(r'\s*(Static|Instance) fields', line): section = 'field'; continue
            m = re.match(r"\s*name\s*:\s*'(.+)'", line)
            if m: name = m.group(1); continue
            m = re.match(r"\s*type\s*:\s*'(.+)'", line)
            if m and cur and section and name is not None:
                have_mem.add((cur, section, name, m.group(1))); name = None

def has_member(c, kind, name, sig):
    # JNI resolves inherited members too (e.g. Kotlin multifile facades).
    while c:
        if (c, kind, name, sig) in have_mem:
            return True
        c = supers.get(c)
    return False

missing = []
for (c, kind, name, sig) in sorted(wanted):
    if kind == 'class':
        if c not in have_cls: missing.append(f'class  {c}')
    elif c in have_cls and not has_member(c, kind, name, sig):
        missing.append(f'{kind:6} {c}.{name}{sig if kind=="method" else " : "+sig}')
    elif c not in have_cls:
        pass  # reported as a missing class
print(f'Checked {len(wanted)} JNI lookups from: {", ".join(sorted(roots))}')
if missing:
    print('MISSING from APK:'); print('\n'.join('  ' + m for m in missing)); sys.exit(1)
print('All present.')
PY
