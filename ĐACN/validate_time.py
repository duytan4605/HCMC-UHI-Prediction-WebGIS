# Kiểm định theo thời gian: học trên 2017-2023, thử trên 2024-2026 (khác chia ngẫu nhiên 80/20). Chạy 1 lần, ghi data/validation.json.
import sqlite3, json, numpy as np, pandas as pd
from pathlib import Path
from xgboost import XGBRegressor
D = Path(__file__).resolve().parent / 'data'
o = pd.read_sql('SELECT o.*, p.latitude, p.longitude FROM observation o JOIN pixel p USING(pid)', sqlite3.connect(D / 'uhi.db'))
tr, te = o[o.year <= 2023], o[o.year >= 2024]
F = ['NDVI', 'NDBI', 'year', 'latitude', 'longitude']
m = XGBRegressor(n_estimators=300, max_depth=6, learning_rate=0.05, random_state=42).fit(tr[F], tr['LST'])
g = tr.groupby('pid'); ok = g.size()[lambda s: s >= 4].index
P = pd.DataFrame(index=ok)
for c in ('NDVI', 'NDBI'):
    mx, my = g['year'].transform('mean'), g[c].transform('mean')
    b = (((tr.year - mx) * (tr[c] - my)).groupby(tr.pid).sum() / ((tr.year - mx) ** 2).groupby(tr.pid).sum().replace(0, np.nan)).fillna(0)
    P['a_' + c], P['b_' + c] = (g[c].mean() - b * g['year'].mean()).loc[ok], b.loc[ok]
P['last'] = tr.sort_values('year').groupby('pid')['LST'].last().loc[ok]
t = te.join(P, on='pid', how='inner')
X = pd.DataFrame({'NDVI': np.clip(t.a_NDVI + t.b_NDVI * t.year, -1, 1), 'NDBI': np.clip(t.a_NDBI + t.b_NDBI * t.year, -1, 1),
                  'year': 2023, 'latitude': t.latitude, 'longitude': t.longitude})
e, e0 = t.LST - m.predict(X), t.LST - t['last']
r = {'rmse': round(float(np.sqrt((e ** 2).mean())), 2), 'mae': round(float(e.abs().mean()), 2),
     'r2': round(float(1 - (e ** 2).sum() / ((t.LST - t.LST.mean()) ** 2).sum()), 2),
     'baseline_rmse': round(float(np.sqrt((e0 ** 2).mean())), 2), 'n_test': int(len(t))}
(D / 'validation.json').write_text(json.dumps(r)); print(r)
