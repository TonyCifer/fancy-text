# TTFToRoblox

A tool to convert TrueType Font (TTF) files into bitmap atlases for use with the FancyText module.

## What It Does

TTFToRoblox converts TTF font files into two files that FancyText can use:

1. **PNG Atlas** - A 2048x2048 image containing all rendered characters
2. **Lua Module** - Character metadata (positions, sizes, offsets, advance values)

## Using the Executable (Easiest)

1. Drag and drop your .ttf file onto the .exe
2. Two files will be generated:
   - `yourfont.png` - Upload this to Roblox as an image
   - `yourfont.lua` - Place this in FancyText/Fonts/

## Manual Method (Python Script)

### Requirements

- Windows OS (uses BMFont.exe)
- TTF font file
- Python 3.x with fontTools (for ProcessFont.py script)

If you prefer to use the Python script directly:

```bash
python ProcessFont.py yourfont.ttf
```
