import sys
import os
import subprocess
import shutil
from fontTools.ttLib import TTFont

TEMPLATE_BMFC = """fileVersion=1
# font settings
fontName=
fontFile=
charSet=0
fontSize=64
aa=1
scaleH=100
useSmoothing=1
isBold=0
isItalic=0
useUnicode=1
disableBoxChars=1
outputInvalidCharGlyph=0
dontIncludeKerningPairs=1
useHinting=1
renderFromOutline=0
useClearType=1
autoFitNumPages=0
autoFitFontSizeMin=0
autoFitFontSizeMax=0
# character alignment
paddingDown=2
paddingUp=2
paddingRight=2
paddingLeft=2
spacingHoriz=1
spacingVert=1
useFixedHeight=0
forceZero=0
widthPaddingFactor=0.00
# output file
outWidth=1024
outHeight=1024
outBitDepth=32
fontDescFormat=0
fourChnlPacked=0
textureFormat=png
textureCompression=0
alphaChnl=1
redChnl=0
greenChnl=0
blueChnl=0
invA=0
invR=0
invG=0
invB=0
# outline
outlineThickness=0
# selected chars
chars=32-126
# imported icon images
"""

def get_font_name(ttf_path):
    try:
        font = TTFont(ttf_path)
        name_table = font['name']
        
        for record in name_table.names:
            if record.nameID == 1:
                if b'\x00' in record.string:
                    return record.string.decode('utf-16-be')
                else:
                    try:
                        return record.string.decode('utf-8')
                    except:
                        return record.string.decode('latin-1')
        
        return os.path.splitext(os.path.basename(ttf_path))[0]
    except:
        return os.path.splitext(os.path.basename(ttf_path))[0]

def parse_fnt(path, font_size=64):
    chars = {}

    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("char id="):
                data = {}
                for kv in line.split():
                    if "=" in kv:
                        k, v = kv.split("=", 1)
                        data[k] = v
                char_id = int(data["id"])

                chars[char_id] = {
                    "x": int(data["x"]),
                    "y": int(data["y"]),
                    "width": int(data["width"]),
                    "height": int(data["height"]),
                    "xoffset": int(data["xoffset"]),
                    "yoffset": int(data["yoffset"]),
                    "xadvance": int(data["xadvance"]),
                }
    return chars

def write_lua(path, atlas_id, original_size, chars):
    with open(path, "w", encoding="utf-8") as f:
        f.write("return {\n")
        f.write(f'\tAtlas = "{atlas_id}",\n')
        f.write(f"\tOriginalSize = {original_size},\n")
        f.write("\tCharacters = {\n")
        for cid, c in sorted(chars.items()):
            f.write(
                f"\t\t[{cid}] = {{ x = {c['x']}, y = {c['y']}, width = {c['width']}, height = {c['height']}, "
                f"xoffset = {c['xoffset']}, yoffset = {c['yoffset']}, xadvance = {c['xadvance']} }},\n"
            )
        f.write("\t},\n")
        f.write("}\n")

def get_bmfont_path():
    if getattr(sys, 'frozen', False):
        bundle_dir = sys._MEIPASS
        bmfont_bundled = os.path.join(bundle_dir, "bmfont.exe")
        if os.path.exists(bmfont_bundled):
            return bmfont_bundled
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bmfont_script = os.path.join(script_dir, "bmfont.exe")
    if os.path.exists(bmfont_script):
        return bmfont_script
    
    return "bmfont.exe"

def build_font(ttf_path):
    name = os.path.splitext(os.path.basename(ttf_path))[0]
    font_name = get_font_name(ttf_path)
    abs_ttf_path = os.path.abspath(ttf_path)
    
    lines = TEMPLATE_BMFC.split('\n')
    
    new_lines = []
    for line in lines:
        if line.startswith("fontFile="):
            new_lines.append(f"fontFile={abs_ttf_path}")
        elif line.startswith("fontName="):
            new_lines.append(f"fontName={font_name}")
        else:
            new_lines.append(line)
    
    cfg_path = os.path.join(os.getcwd(), f"{name}_temp.bmfc")
    with open(cfg_path, "w", encoding="utf-8") as f:
        f.write('\n'.join(new_lines))
        f.flush()
        os.fsync(f.fileno())
    
    bmfont_exe = get_bmfont_path()
    
    subprocess.run([
        bmfont_exe,
        "-c", cfg_path,
        "-o", name
    ], 
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    creationflags=subprocess.CREATE_NO_WINDOW)
    
    fnt_file = f"{name}.fnt"
    png_file = f"{name}_0.png"
    
    if not os.path.exists(fnt_file) or not os.path.exists(png_file):
        raise FileNotFoundError(f"BMFont did not generate expected files")
    
    chars = parse_fnt(fnt_file)
    
    out_png = f"{name}.png"
    shutil.move(png_file, out_png)
    
    out_lua = f"{name}.lua"
    write_lua(out_lua, "rbxassetid://0", 64, chars)
    
    os.remove(cfg_path)
    os.remove(fnt_file)

if __name__ == "__main__":
    if len(sys.argv) >= 2:
        try:
            build_font(sys.argv[1])
        except:
            pass
