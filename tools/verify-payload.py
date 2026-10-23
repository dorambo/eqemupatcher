"""Reject map expansion creep and manifest hashes that differ from served Git bytes."""
from pathlib import Path
import hashlib, json, re, subprocess, sys

repo=Path(__file__).resolve().parents[1]
allowed=set(json.loads((repo/'tools/rof2-map-zones.json').read_text())['zones'])
maps=list((repo/'rof/maps').rglob('*.txt'))
for path in maps:
    zone=re.sub(r'_\d+$','',path.stem).lower()
    if zone not in allowed: raise SystemExit('Not a supported RoF2 map: '+str(path))

# Windows checkout must not normalize bytes that raw.githubusercontent.com serves.
tracked=subprocess.check_output(['git','-C',str(repo),'ls-files','-z','--','rof/']).decode().split('\0')
git=subprocess.Popen(['git','-C',str(repo),'cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
hashes={}
try:
    for name in filter(None,tracked):
        git.stdin.write((':'+name+'\n').encode());git.stdin.flush()
        header=git.stdout.readline().split()
        if len(header)!=3 or header[1]!=b'blob': raise RuntimeError('Missing index blob: '+name)
        data=git.stdout.read(int(header[2]));assert git.stdout.read(1)==b'\n'
        if len(sys.argv)==1 and (repo/name).read_bytes()!=data:
            raise RuntimeError('Checkout bytes differ from Git: '+name)
        hashes[name[4:]]=hashlib.md5(data).hexdigest().lower()
finally:
    git.stdin.close();git.wait()

if len(sys.argv)>1:
    text=Path(sys.argv[1]).read_text(encoding='utf-8-sig')
    entries=re.split(r'(?m)^- name: ',text.split('\ndownloads:\n',1)[1])[1:]
    checked=set()
    for chunk in entries:
        name=chunk.splitlines()[0]
        if name.startswith('"'): name=json.loads(name)
        elif name.startswith("'"): name=name[1:-1].replace("''", "'")
        name=name.replace('\\','/')
        if name not in hashes: raise RuntimeError('Untracked download in manifest: '+name)
        md5=re.search(r'^  md5: "?([0-9a-fA-F]{32})"?$',chunk,re.M)
        if not md5 or md5[1].lower()!=hashes[name]: raise RuntimeError('Manifest hash differs from served Git bytes: '+name)
        checked.add(name)
    for path in maps:
        name=path.relative_to(repo/'rof').as_posix()
        if name not in checked: raise RuntimeError('Map missing from manifest: '+name)
    print('Verified',len(checked),'manifest download hashes against Git bytes')
print('Verified',len(maps),'RoF2 map files and exact payload checkout bytes')
