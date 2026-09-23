#!/usr/bin/env python3
"""Build and scan a local Grid runtime. Publishes nothing and never contacts Kubernetes."""
import argparse,datetime,hashlib,io,json,os,subprocess,tarfile,tempfile,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TRIVY_URL='https://github.com/aquasecurity/trivy/releases/download/v0.74.0/trivy_0.74.0_Linux-64bit.tar.gz'
TRIVY_SHA='2ae6fe3ee734b7fdf11335663e18c75ea12dccc76062f09f164a3b0f8be4371a'
def sha(b):return hashlib.sha256(b).hexdigest()
def run(args,log,**kwargs):
 with log.open('wb') as f:
  p=subprocess.run(args,stdout=f,stderr=subprocess.STDOUT,check=False,**kwargs)
 return p.returncode
p=argparse.ArgumentParser(description=__doc__);p.add_argument('component',choices=['hub','chromium']);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
a.output.mkdir(parents=True,exist_ok=True);out=a.output.resolve();rev=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
path=ROOT/'images'/f'{a.component}.Dockerfile';assert path.read_bytes()==subprocess.check_output(['git','show',rev+':images/'+a.component+'.Dockerfile'],cwd=ROOT)
tag=f'local-grid-{a.component}:{rev}'
receipt={'schema_version':1,'component':a.component,'source_repository':'https://github.com/imos64/selenium-grid-kubernetes','source_revision':rev,'dockerfile_sha256':sha(path.read_bytes()),'image':tag,'run_id':os.environ.get('GITHUB_RUN_ID'),'run_attempt':os.environ.get('GITHUB_RUN_ATTEMPT'),'event':os.environ.get('GITHUB_EVENT_NAME'),'started_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'passed':False,'published':False}
try:
 assert run(['docker','build','--network','none','--build-arg','SOURCE_REVISION='+rev,'-f',str(path),'-t',tag,str(ROOT)],out/'build.log')==0,'image build failed'
 info=json.loads(subprocess.check_output(['docker','image','inspect',tag]))[0]
 assert info['Config']['User']=='1200:1201' and info['Config']['Labels']['org.opencontainers.image.revision']==rev
 receipt['image_id']=info['Id']
 code='import importlib.util,pathlib,supervisor,requests; assert importlib.util.find_spec("pip") is None; assert not pathlib.Path("/usr/local/bin/rclone").exists(); print("runtime imports pass; unused tooling absent")'
 assert run(['docker','run','--rm','--network','none','--read-only','--cap-drop','ALL','--security-opt','no-new-privileges','--memory','256m','--cpus','0.5','--entrypoint','/home/seluser/venv/bin/python3',tag,'-B','-c',code],out/'restricted-runtime.log')==0,'restricted runtime check failed'
 with tempfile.TemporaryDirectory(prefix='grid-qualification-') as td:
  td=Path(td);raw=urllib.request.urlopen(TRIVY_URL,timeout=90).read();assert sha(raw)==TRIVY_SHA
  with tarfile.open(fileobj=io.BytesIO(raw),mode='r:gz') as tar: (td/'trivy').write_bytes(tar.extractfile('trivy').read())
  (td/'trivy').chmod(0o755);(td/'empty.ignore').write_text('');(td/'empty.yaml').write_text('{}\n')
  assert run(['docker','save','--output',str(td/'image.tar'),tag],out/'export.log')==0
  common=[str(td/'trivy'),'image','--input',str(td/'image.tar'),'--config',str(td/'empty.yaml'),'--ignorefile',str(td/'empty.ignore'),'--secret-config',str(td/'empty.yaml'),'--timeout','15m','--cache-dir',str(ROOT/'.runtime-cache')]
  receipt['scan_exit_code']=run(common+['--scanners','vuln,secret','--severity','HIGH,CRITICAL','--ignore-unfixed=false','--list-all-pkgs','--exit-code','1','--format','json','--output',str(out/'image.json')],out/'scan.log')
  receipt['sbom_exit_code']=run(common+['--format','cyclonedx','--output',str(out/'sbom.json')],out/'sbom.log')
  receipt['scanner']=json.loads(subprocess.check_output([str(td/'trivy'),'--cache-dir',str(ROOT/'.runtime-cache'),'--version','--format','json']))
  assert receipt['scan_exit_code']==receipt['sbom_exit_code']==0,'image scan/SBOM gate failed'
 receipt['passed']=True
finally:
 receipt['finished_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
 receipt['files_sha256']={f.name:sha(f.read_bytes()) for f in sorted(out.iterdir()) if f.is_file() and f.name!='receipt.json'}
 (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
