# API dự báo UHI: xu hướng NDVI/NDBI theo năm cho từng điểm ảnh -> XGBoost dự báo LST -> nội suy không gian thành heatmap.
import sqlite3, base64, io, json, time
from pathlib import Path
import numpy as np, pandas as pd, joblib
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from PIL import Image, ImageDraw
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

ROOT = Path(__file__).resolve().parent.parent
app = FastAPI(title='HCMC UHI API')
model = joblib.load(ROOT / 'models' / 'ultimate_uhi_model_10yrs.joblib')
con = sqlite3.connect(ROOT / 'data' / 'uhi.db', check_same_thread=False)
obs = pd.read_sql('SELECT * FROM observation', con)
pix = pd.read_sql('SELECT * FROM pixel', con)
con.execute('CREATE TABLE IF NOT EXISTS run_log(id INTEGER PRIMARY KEY, ts TEXT, year INT, d_ndvi REAL, d_ndbi REAL, mean REAL, max REAL, hot_pct REAL)'); con.commit()
YMAX = int(obs['year'].max())

def trend(col):  # hồi quy tuyến tính theo năm cho từng điểm ảnh
    g = obs.groupby('pid'); mx = g['year'].transform('mean'); my = g[col].transform('mean')
    sxy = ((obs['year'] - mx) * (obs[col] - my)).groupby(obs['pid']).sum()
    sxx = ((obs['year'] - mx) ** 2).groupby(obs['pid']).sum()
    b = (sxy / sxx.replace(0, np.nan)).fillna(0)
    return g[col].mean() - b * g['year'].mean(), b

T = pix.set_index('pid'); T['n'] = obs.groupby('pid').size()
for c in ('NDVI', 'NDBI'):
    T['a_' + c], T['b_' + c] = trend(c)
T = T[T['n'] >= 4].reset_index()
if T.empty:
    raise RuntimeError('Không có điểm ảnh nào quan trắc >= 4 năm. Xem bảng thống kê khi chạy load_db.py.')

def predict(t, year, dn=0.0, db=0.0):
    # Year đưa vào mô hình bị kẹp ở năm cuối dữ liệu (XGBoost không ngoại suy); xu hướng thời gian đến từ NDVI/NDBI.
    X = pd.DataFrame({'NDVI': np.clip(t['a_NDVI'] + t['b_NDVI'] * year + dn, -1, 1),
                      'NDBI': np.clip(t['a_NDBI'] + t['b_NDBI'] * year + db, -1, 1),
                      'Year': min(year, YMAX), 'latitude': t['latitude'], 'longitude': t['longitude']})
    return model.predict(X)

PAL = [(0, 0, 255), (0, 255, 255), (0, 170, 0), (255, 255, 0), (255, 0, 0)]  # 25 -> 45 °C
def colorize(v, vmin=25, vmax=45):
    t = np.clip((v - vmin) / (vmax - vmin), 0, 1); xs = np.linspace(0, 1, len(PAL))
    return np.stack([np.interp(t, xs, [p[i] for p in PAL]) for i in range(3)], -1).astype(np.uint8)

def inside_mask(gx, gy, step, P):
    """Cắt heatmap đúng theo ranh giới (vẽ polygon lên ảnh mặt nạ); nếu thiếu file ranh giới thì dùng khoảng cách tới điểm mẫu."""
    f = ROOT / 'data' / 'hcm_boundary.geojson'
    if not f.exists():
        return cKDTree(P).query(np.c_[gx.ravel(), gy.ravel()])[0].reshape(gx.shape) <= 0.02
    g = json.loads(f.read_text(encoding='utf-8')); g = g.get('geometry', g)
    polys = [g['coordinates']] if g['type'] == 'Polygon' else g['coordinates']
    im = Image.new('L', (gx.shape[1], gx.shape[0]), 0); d = ImageDraw.Draw(im)
    for poly in polys:
        for k, ring in enumerate(poly):  # vành 0 = ngoài, các vành sau = lỗ
            d.polygon([((x - gx[0, 0]) / step, (gy[0, 0] - y) / step) for x, y in ring], fill=1 if k == 0 else 0)
    return np.array(im, dtype=bool)

@app.get('/api/forecast_map')
def forecast_map(year: int = 2030, d_ndvi: float = 0, d_ndbi: float = 0, step: float = 0.004):
    v = predict(T, year, d_ndvi, d_ndbi)
    P = T[['longitude', 'latitude']].values
    x0, x1, y0, y1 = P[:, 0].min(), P[:, 0].max(), P[:, 1].min(), P[:, 1].max()
    gx, gy = np.meshgrid(np.arange(x0, x1, step), np.arange(y1, y0, -step))
    g = griddata(P, v, (gx, gy), method='linear')
    g = np.where(np.isnan(g), griddata(P, v, (gx, gy), method='nearest'), g)
    inside = inside_mask(gx, gy, step, P)
    rgba = np.dstack([colorize(g), np.where(inside, 230, 0).astype(np.uint8)])
    buf = io.BytesIO(); Image.fromarray(rgba, 'RGBA').save(buf, 'PNG')
    res = {'image': 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode(),
            'bounds': [[float(gy.min()), float(x0)], [float(y1), float(gx.max())]],
            'mean': float(v.mean()), 'max': float(v.max()), 'hot_pct': float((v > 36).mean() * 100)}
    con.execute('INSERT INTO run_log(ts,year,d_ndvi,d_ndbi,mean,max,hot_pct) VALUES(?,?,?,?,?,?,?)', (time.strftime('%Y-%m-%d %H:%M:%S'), year, d_ndvi, d_ndbi, res['mean'], res['max'], res['hot_pct'])); con.commit()
    return res

@app.get('/api/pixel')
def pixel(lat: float, lon: float, year: int = 2035, d_ndvi: float = 0, d_ndbi: float = 0):
    i = int(np.argmin((T['latitude'] - lat) ** 2 + (T['longitude'] - lon) ** 2)); t = T.iloc[[i]]
    o = obs[obs['pid'] == t['pid'].iloc[0]].sort_values('year')
    return {'lat': float(t['latitude'].iloc[0]), 'lon': float(t['longitude'].iloc[0]),
            'observed': [{'year': int(r.year), 'lst': round(float(r.LST), 2)} for r in o.itertuples()],
            'forecast': [{'year': y, 'lst': round(float(predict(t, y, d_ndvi, d_ndbi)[0]), 2)}
                         for y in range(YMAX + 1, max(year, YMAX + 1) + 1)]}

@app.get('/api/boundary')
def boundary():
    return FileResponse(ROOT / 'data' / 'hcm_boundary.geojson')

@app.get('/api/history')
def history(limit: int = 8):
    return pd.read_sql('SELECT ts,year,d_ndvi,d_ndbi,round(mean,2) mean,round(max,2) max,round(hot_pct,1) hot_pct FROM run_log ORDER BY id DESC LIMIT ?', con, params=(limit,)).to_dict('records')

@app.get('/api/validation')
def validation():
    f = ROOT / 'data' / 'validation.json'
    return json.loads(f.read_text()) if f.exists() else {}

if (ROOT / 'data' / 'overlays').exists():
    app.mount('/overlays', StaticFiles(directory=ROOT / 'data' / 'overlays'), name='overlays')
app.mount('/', StaticFiles(directory=ROOT / 'frontend', html=True), name='frontend')
