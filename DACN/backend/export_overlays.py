# Nội suy điểm mẫu CSV thành PNG quan trắc (LST/NDVI/NDBI/TVDI) theo năm.
import json
from pathlib import Path
import numpy as np
import pandas as pd
from PIL import Image
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'data' / 'overlays'
OUT.mkdir(parents=True, exist_ok=True)
df = pd.read_csv(ROOT / 'data' / 'HCMC_UHI_10Years_2017_2026.csv').dropna()
P = df[['longitude', 'latitude']].values
x0, x1 = float(P[:, 0].min()), float(P[:, 0].max())
y0, y1 = float(P[:, 1].min()), float(P[:, 1].max())
step = 0.004
gx, gy = np.meshgrid(np.arange(x0, x1, step), np.arange(y1, y0, -step))
dist = cKDTree(P).query(np.c_[gx.ravel(), gy.ravel()])[0].reshape(gx.shape)
inside = dist <= 0.02
(OUT / 'bounds.json').write_text(json.dumps({
    'west': x0, 'east': float(gx.max()), 'south': float(gy.min()), 'north': y1
}), encoding='utf-8')

PAL = {
    'LST':  ([(0, 0, 255), (0, 255, 255), (0, 170, 0), (255, 255, 0), (255, 0, 0)], 25, 45),
    'NDVI': ([(255, 0, 0), (255, 255, 0), (144, 238, 144), (0, 170, 0), (0, 100, 0)], -0.2, 0.8),
    'NDBI': ([(0, 170, 0), (255, 255, 0), (255, 0, 0)], -0.5, 0.5),
    'TVDI': ([(0, 100, 0), (0, 170, 0), (255, 255, 0), (255, 165, 0), (255, 0, 0)], 0.0, 1.0),
}

def colorize(v, pal, vmin, vmax):
    t = np.clip((v - vmin) / (vmax - vmin), 0, 1)
    xs = np.linspace(0, 1, len(pal))
    return np.stack([np.interp(t, xs, [p[i] for p in pal]) for i in range(3)], -1).astype(np.uint8)

years = sorted(df['Year'].astype(int).unique())
cols = [c for c in ('LST', 'NDVI', 'NDBI', 'TVDI') if c in df.columns]
for year in years:
    d = df[df['Year'] == year]
    pts = d[['longitude', 'latitude']].values
    for col in cols:
        grid = griddata(pts, d[col].values, (gx, gy), method='linear')
        grid = np.where(np.isnan(grid), griddata(pts, d[col].values, (gx, gy), method='nearest'), grid)
        pal, vmin, vmax = PAL[col]
        rgba = np.dstack([colorize(grid, pal, vmin, vmax), np.where(inside, 230, 0).astype(np.uint8)])
        Image.fromarray(rgba, 'RGBA').save(OUT / f'{col}_{year}.png')
        print('wrote', col, year)
print('xong', OUT)
