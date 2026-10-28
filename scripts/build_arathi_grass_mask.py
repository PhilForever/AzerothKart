"""Generate Arathi's conservative 4-unit kart-centre terrain mask.

Uses the project's existing terrain survey and same authored open-fence ranges.
No Warcraft assets are read. A road opening with painted blockers keeps its
existing wall: blockers are rendered from models, not present in the survey.
Usage: python scripts/build_arathi_grass_mask.py [--check]
"""
import argparse, hashlib, math, time
from pathlib import Path
from types import SimpleNamespace
import battleground_layouts as L
from battleground_paint import Survey, even, survey_heights, open_edges
from build_city_tracks import narrow_segments, number
from circuit_boundary import loop_radii

ROOT=Path(__file__).resolve().parents[1]
OUTPUT=ROOT/'addon/AzerothKart/ArathiGrass.lua'
CELL=4; N=512; INSET=18; BUCKET=64

def axis(x,y,a,b):
    ax,ay=a; bx,by=b; dx=bx-ax; dy=by-ay
    den=dx*dx+dy*dy
    t=max(0.,min(1.,((x-ax)*dx+(y-ay)*dy)/den)) if den else 0.
    ex=x-ax-t*dx; ey=y-ay-t*dy
    return math.sqrt(ex*ex+ey*ey),dx*(y-ay)-dy*(x-ax)

def build():
    spec=L.ARATHI
    line=[(float(number(x)),float(number(y))) for x,y in spec['centerline']]
    geo={'centerline':line,'wallRadius':76,'narrows':narrow_segments(spec,line)}
    radii=loop_radii(geo)
    segs=[(line[i-1],line[i]) for i in range(len(line))]
    helper=SimpleNamespace(segs=segs,loop_count=len(segs))
    opened=open_edges(spec,geo,helper)
    narrowed={i for i,r in enumerate(radii) if r<76}
    # Near-course spatial index; nearest beyond 120 cannot form a wall.
    buckets={}
    for i,(a,b) in enumerate(segs):
        for by in range(max(0,int((min(a[1],b[1])-120)//BUCKET)),min(31,int((max(a[1],b[1])+120)//BUCKET))+1):
            for bx in range(max(0,int((min(a[0],b[0])-120)//BUCKET)),min(31,int((max(a[0],b[0])+120)//BUCKET))+1):
                buckets.setdefault((bx,by),[]).append(i)
    survey=Survey(ROOT/'scripts'/spec['survey'])
    assert survey.grid==CELL and survey.cols==N and survey.rows==N
    wet=even(survey.water,N,N,spec['water'].get('smooth',0))
    heights=survey_heights(survey,spec['cliffs'].get('smooth',1))
    # The painter labels cliff-face pixels only once the blend exceeds 50%.
    # Using its low blend onset as a wall blocks nearly invisible gentle slopes.
    lo=(spec['cliffs']['from']+spec['cliffs']['full'])/2; shore=spec['water']['shore']
    hazard=bytearray(N*N)
    for r in range(N):
        for c in range(N):
            i=r*N+c
            gx=(heights[i+1 if c+1<N else i]-heights[i-1 if c else i])/(2*CELL)
            gy=(heights[i-N if r else i]-heights[i+N if r+1<N else i])/(2*CELL)
            if wet[i]>=shore or 3*math.hypot(gx,gy)>=lo:
                hazard[(N-1-r)*N+c]=1
    # Inflate terrain obstacles for the kart's conservative 18-unit inset.
    dilated=bytearray(N*N)
    offsets=[(dx,dy) for dy in range(-5,6) for dx in range(-5,6) if (dx*CELL)**2+(dy*CELL)**2 <= (INSET+CELL*math.sqrt(2))**2]
    for y in range(N):
        for x in range(N):
            if not hazard[y*N+x]: continue
            for dx,dy in offsets:
                nx,ny=x+dx,y+dy
                if 0<=nx<N and 0<=ny<N: dilated[ny*N+nx]=1
    bits=bytearray(N*N//8); road=bytearray(N*N)
    blocked_fence=0; grass=0
    plazas=spec['plazas']; openings=spec['openings']
    for gy in range(N):
        y=(gy+0.5)*CELL
        for gx in range(N):
            x=(gx+0.5)*CELL; idx=gy*N+gx
            # The closest exposed boundary approximates the painted fence.
            best_gap=999.; best_axis=999.; best_k=None; best_side=1
            onroad=False
            for k in buckets.get((int(x//BUCKET),int(y//BUCKET)),()):
                d,cross=axis(x,y,*segs[k]); gap=d-radii[k]
                if gap<=0: onroad=True
                if gap<best_gap: best_gap=gap
                if d<best_axis: best_axis=d; best_k=k; best_side=1 if cross>0 else -1
            plaza_gap=999.
            for p in plazas:
                d,_=axis(x,y,(p['ax'],p['ay']),(p['bx'],p['by']))
                plaza_gap=min(plaza_gap,d-p['radius'])
            if plaza_gap<=0: onroad=True
            if onroad:
                # Road/bridge is an authored raised surface even over survey water.
                road[idx]=1; allowed=True
            else:
                closed=False
                if best_gap<=INSET+CELL and best_k is not None:
                    closed=(best_k in narrowed or best_k not in opened[best_side])
                    # Preserve old boundary at road mouths whose painted objects
                    # are not otherwise exported as physical shapes.
                    for opening in openings:
                        ox,oy=opening['at']; reach=opening['reach']+INSET
                        if (x-ox)**2+(y-oy)**2<=reach*reach: closed=True; break
                if plaza_gap<=INSET+CELL: closed=True
                if closed: blocked_fence+=1
                allowed=not closed and not dilated[idx]
            if x<INSET or x>2048-INSET or y<INSET or y>2048-INSET: allowed=False
            if allowed:
                bits[idx//8] |= 1 << (idx%8)
                if not onroad: grass+=1
    return bytes(bits),road,blocked_fence,grass

def output(data):
    chunks=['"'+''.join('\\%03d'%b for b in data[i:i+128])+'"' for i in range(0,len(data),128)]
    return ('-- Generated by scripts/build_arathi_grass_mask.py; do not edit.\n'
            'local _, ns = ...\nassert(type(ns)=="table" and ns.Battlegrounds and ns.Battlegrounds.arathi_basin)\n'
            'ns.Battlegrounds.arathi_basin.grassMap = {cellSize=4,columns=512,rows=512,data=table.concat({\n'
            + ',\n'.join(chunks) + '})}\n').encode('ascii')

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--check',action='store_true');args=p.parse_args()
    started=time.monotonic(); data,road,fences,grass=build(); rendered=output(data)
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_bytes()!=rendered: raise SystemExit('STALE: '+str(OUTPUT))
        print('CHECK PASS:',OUTPUT)
    else:
        OUTPUT.write_bytes(rendered);print('WROTE:',OUTPUT)
    print('mask bytes=%d sha256=%s road_cells=%d grass_cells=%d fence_cells=%d seconds=%.1f' %
          (len(data),hashlib.sha256(data).hexdigest(),sum(road),grass,fences,time.monotonic()-started))
if __name__=='__main__': main()
