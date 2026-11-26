from pathlib import Path
import math, struct
out=Path(__file__).resolve().parents[1]/'Media'
size=128
samples=4
for name in ('crosshair','circle','bullseye'):
    pixels=bytearray()
    for py in range(size):
        for px in range(size):
            hits=0
            for sy in range(samples):
                for sx in range(samples):
                    x=(px+(sx+.5)/samples)/size-.5
                    y=(py+(sy+.5)/samples)/size-.5
                    r=math.hypot(x,y)
                    if name=='circle': ink=abs(r-.4)<=.045
                    elif name=='bullseye': ink=abs(r-.42)<=.035 or abs(r-.23)<=.035 or r<=.055
                    else:
                        ink=abs(r-.28)<=.04 or (abs(y)<=.04 and .13<=abs(x)<=.48) or (abs(x)<=.04 and .13<=abs(y)<=.48)
                    hits+=bool(ink)
            pixels.extend((255,255,255,round(255*hits/(samples*samples))))
    # Uncompressed 32-bit BGRA TGA, top-left origin with 8 alpha bits.
    header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,size,size,32,0x28)
    (out/(name+'.tga')).write_bytes(header+pixels)
print('Generated three 128px antialiased geometric icon textures.')
