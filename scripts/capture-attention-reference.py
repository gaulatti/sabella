#!/usr/bin/env python3
"""Capture the pinned producer through a separate, temporary Chrome profile."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import subprocess
import tempfile

REVISION = "cb891040bb40fa5668a7ccb851681396620b4d11"
SOURCE = "src/utils/attention-color.ts"
parser = argparse.ArgumentParser()
parser.add_argument("--bleecker-repository", required=True, type=Path)
parser.add_argument("--chrome-binary", required=True, type=Path)
parser.add_argument("--output", required=True, type=Path)
args = parser.parse_args()
source = subprocess.check_output(
    ["git", "show", f"{REVISION}:{SOURCE}"], cwd=args.bleecker_repository, text=True
)
script = source[source.index("function clamp"):]
for before, after in [
    ("function clamp(value: number, min: number, max: number): number", "function clamp(value, min, max)"),
    ("export function createAttentionColor({ hue, intensity: rawIntensity }: AttentionColorOptions): AttentionColorResult",
     "function createAttentionColor({ hue, intensity: rawIntensity })"),
]:
    if script.count(before) != 1:
        raise ValueError("The pinned producer signature changed")
    script = script.replace(before, after)
cases = [{"hue": hue, "intensity": intensity}
         for hue in [0, 15, 60, 105, 210, 285, 359] for intensity in [0, 2.25, 5, 10]]
cases += [{"hue": -0.5, "intensity": -1}, {"hue": 720.6, "intensity": 11}]
script += "\nconst cases=" + json.dumps(cases) + ";\n" + r"""
const canvas=document.createElement('canvas');canvas.width=canvas.height=1;
const ctx=canvas.getContext('2d',{willReadFrequently:true});
const probe=document.createElement('span');document.body.appendChild(probe);
function rgb(color){
  probe.style.color='color(from '+color+' srgb r g b / alpha)';
  const value=getComputedStyle(probe).color;
  if(!value.startsWith('color(srgb '))throw Error('Missing relative sRGB conversion: '+value);
  const parts=value.slice(11,-1).trim().split(/\s*\/\s*|\s+/).map(Number);
  return parts.length===3?[...parts,1]:parts;
}
function stops(background){
  const body=background.slice(background.indexOf('(')+1,-1);let depth=0,start=0;const parts=[];
  for(let i=0;i<body.length;i++){
    if(body[i]==='(')depth++;else if(body[i]===')')depth--;
    else if(body[i]===','&&depth===0){parts.push(body.slice(start,i).trim());start=i+1;}
  }
  parts.push(body.slice(start).trim());
  return parts.slice(1).map(part=>{
    const match=/^(.*)\s+([\d.]+)%$/.exec(part);if(!match)throw Error('Missing stop');
    return {color:rgb(match[1]),location:Number(match[2])/100};
  });
}
const rows=cases.map(input=>{
  const output=createAttentionColor(input);ctx.clearRect(0,0,1,1);
  ctx.fillStyle=output.accent;ctx.fillRect(0,0,1,1);
  return {input,...output,accentRgba:Array.from(ctx.getImageData(0,0,1,1).data),
    backgroundStops:stops(output.style.background),borderSrgb:rgb(output.style.borderColor)};
});
document.getElementById('results').textContent=JSON.stringify(rows);
"""


class Results(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.result = ""

    def handle_starttag(self, tag, attrs):
        if tag == "pre" and ("id", "results") in attrs:
            self.active = True

    def handle_endtag(self, tag):
        if tag == "pre":
            self.active = False

    def handle_data(self, data):
        if self.active:
            self.result += data


with tempfile.TemporaryDirectory(prefix="sabella-attention-reference-") as folder:
    root = Path(folder)
    html = root / "reference.html"
    html.write_text('<!doctype html><meta charset="utf-8"><pre id="results"></pre><script>' + script + "</script>")
    result = subprocess.run([
        str(args.chrome_binary), "--headless=new", "--disable-background-networking", "--disable-extensions",
        "--no-first-run", "--no-default-browser-check", "--user-data-dir=" + str(root / "profile"),
        "--dump-dom", html.as_uri(),
    ], capture_output=True, text=True, timeout=45, check=True)
    parsed = Results()
    parsed.feed(result.stdout)
    rows = json.loads(parsed.result)
    if len(rows) != len(cases):
        raise ValueError("Incomplete browser fixture")
    component_path = "src/components/attention-surface.tsx"
    component = subprocess.check_output(["git", "show", f"{REVISION}:{component_path}"], cwd=args.bleecker_repository, text=True)
    for contract in ["rounded-[11px] border text-left shadow-[0_16px_38px_-30px_rgba(0,0,0,0.92)]", "px-4 py-4", "px-5 py-5"]:
        if contract not in component:
            raise ValueError("The pinned component appearance changed")
    rasters = []
    for name, width, height, hue, intensity in [("landscape", 320, 160, 210, 5), ("portrait", 160, 320, 105, 5)]:
        sample = next(row for row in rows if row["input"] == {"hue": hue, "intensity": intensity})
        fixture_name = "attention-" + name + "-cb89104.png"
        output = args.output.parent / fixture_name
        raster_html = root / (name + ".html")
        raster_html.write_text("<!doctype html><style>*{box-sizing:border-box}html,body{margin:0;background:white}article{position:absolute;left:80px;top:80px;width:" + str(width) + "px;height:" + str(height) + "px;border:1px solid " + sample["style"]["borderColor"] + ";border-radius:11px;background:" + sample["style"]["background"] + ";box-shadow:0 16px 38px -30px rgba(0,0,0,.92)}</style><article></article>")
        subprocess.run([str(args.chrome_binary), "--headless=new", "--disable-background-networking", "--disable-extensions", "--no-first-run", "--no-default-browser-check", "--hide-scrollbars", "--force-device-scale-factor=1", "--window-size=" + str(width + 160) + "," + str(height + 160), "--user-data-dir=" + str(root / "profile"), "--screenshot=" + str(output), raster_html.as_uri()], capture_output=True, text=True, timeout=45, check=True)
        rasters.append({"file": fixture_name, "sha256": hashlib.sha256(output.read_bytes()).hexdigest(), "width": width, "height": height, "hue": hue, "intensity": intensity})
    version = subprocess.check_output([str(args.chrome_binary), "--version"], text=True).strip()
    args.output.write_text(json.dumps({"producer": {
        "repository": "gaulatti/bleecker", "revision": REVISION, "path": SOURCE,
        "source_sha256": hashlib.sha256(source.encode()).hexdigest(), "browser_version": version,
        "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "component_path": component_path, "component_sha256": hashlib.sha256(component.encode()).hexdigest(),
        "rasters": rasters,
        "meaning": "Actual pinned producer; only TypeScript signature annotations removed. Numeric CSS colors and isolated component paint rasters; no device interaction acceptance.",
    }, "cases": rows}, indent=2) + "\n")
    print(f"Captured {len(rows)} producer cases at {REVISION}")
