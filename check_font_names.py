#!/usr/bin/env python3
from fontTools.ttLib import TTFont
import sys

font_files = [
    "LedScroller/Fonts/MatrixSans-Regular.ttf",
    "LedScroller/Fonts/MatrixSansSC-Regular.ttf",
    "LedScroller/Fonts/MatrixSansRaster-Regular.ttf",
    "LedScroller/Fonts/MatrixSansRasterSC-Regular.ttf",
    "LedScroller/Fonts/MatrixSansSmooth-Regular.ttf",
    "LedScroller/Fonts/MatrixSansSmoothSC-Regular.ttf",
    "LedScroller/Fonts/MatrixSansVideo-Regular.ttf",
    "LedScroller/Fonts/MatrixSansVideoSC-Regular.ttf"
]

for font_path in font_files:
    try:
        font = TTFont(font_path)
        name_table = font['name']
        
        # PostScript name (nameID 6)
        postscript_name = None
        for record in name_table.names:
            if record.nameID == 6:
                postscript_name = record.toUnicode()
                break
        
        print(f"{font_path.split('/')[-1]}: {postscript_name}")
    except Exception as e:
        print(f"{font_path}: Error - {e}")
