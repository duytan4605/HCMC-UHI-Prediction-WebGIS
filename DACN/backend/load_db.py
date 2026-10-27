# Nạp CSV vào CSDL SQLite: data/uhi.db (bảng pixel, observation). Chạy 1 lần.
import sqlite3, pandas as pd
from pathlib import Path
D = Path(__file__).resolve().parent.parent / 'data'
df = pd.read_csv(D / 'HCMC_UHI_10Years_2017_2026.csv').dropna()
df['year'] = df['Year'].astype(int)
df['pid'] = df['latitude'].round(6).astype(str) + '_' + df['longitude'].round(6).astype(str)
con = sqlite3.connect(D / 'uhi.db')
df.drop_duplicates('pid')[['pid', 'latitude', 'longitude']].to_sql('pixel', con, if_exists='replace', index=False)
df.drop_duplicates(['pid', 'year'])[['pid', 'year', 'LST', 'NDVI', 'NDBI'] + [c for c in ('TVDI', 'QC') if c in df.columns]].to_sql('observation', con, if_exists='replace', index=False)
con.execute('CREATE INDEX IF NOT EXISTS ix_obs ON observation(pid, year)'); con.commit()
print(len(df), 'dòng. Số điểm ảnh theo số năm quan trắc (n = số năm):')
print(pd.read_sql('SELECT n, COUNT(*) AS so_diem FROM (SELECT COUNT(*) n FROM observation GROUP BY pid) GROUP BY n', con).to_string(index=False))
