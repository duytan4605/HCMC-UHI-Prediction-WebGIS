import json
import streamlit as st
import pandas as pd
import numpy as np
import joblib
import folium
import branca.colormap as cm
import requests
from folium.plugins import HeatMap
from streamlit_folium import st_folium
from pathlib import Path
from scipy.interpolate import griddata
from scipy.spatial import cKDTree

# 1. Cấu hình giao diện Dashboard rộng
st.set_page_config(
    page_title="HCMC UHI Monitoring & AI Forecasting WebGIS", 
    page_icon="🌡️", 
    layout="wide"
)

# 2. CSS trang trí cao cấp
st.markdown("""
    <style>
    .main {
        background-color: #f8fafc;
    }
    .block-container {
        padding-top: 2rem;
        padding-bottom: 2rem;
    }
    .header-card {
        background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
        padding: 24px;
        border-radius: 16px;
        color: white;
        margin-bottom: 25px;
        box-shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.2);
    }
    .custom-container {
        background-color: #ffffff;
        padding: 22px;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02);
        margin-bottom: 20px;
    }
    .stButton>button {
        background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
        color: white;
        border-radius: 12px;
        font-weight: 700;
        border: none;
        padding: 12px 20px;
        box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
        transition: all 0.3s ease;
    }
    .stButton>button:hover {
        background: linear-gradient(135deg, #1d4ed8 0%, #1e40af 100%);
        box-shadow: 0 6px 16px rgba(37, 99, 235, 0.4);
    }
    .metric-card {
        background: linear-gradient(135deg, #ffffff 0%, #fff1f2 100%);
        padding: 24px;
        border-radius: 16px;
        box-shadow: 0 10px 25px -5px rgba(220, 38, 38, 0.1);
        text-align: center;
        border: 1px solid #fecdd3;
        border-left: 6px solid #e11d48;
        margin-top: 15px;
    }
    </style>
""", unsafe_allow_html=True)

# 3. Tiêu đề hệ thống
st.markdown("""
    <div class="header-card">
        <h1 style='margin: 0; font-size: 26px; font-weight: 800; color: #ffffff;'>🌍 HCMC Urban Heat Island (UHI) Monitoring & AI Forecasting WebGIS</h1>
        <p style='margin: 8px 0 0 0; font-size: 14px; color: #94a3b8;'>Hệ thống giám sát không gian và dự báo Đảo nhiệt đô thị tích hợp mô hình Machine Learning (XGBoost)</p>
    </div>
""", unsafe_allow_html=True)

# 4. Tự động tải tài nguyên (Mô hình, CSV và Ranh giới)
@st.cache_resource
def load_resources():
    current_dir = Path(__file__).resolve().parent
    model = None
    for folder_name in ['models', 'model']:
        model_path = current_dir / folder_name / 'ultimate_uhi_model_10yrs.joblib'
        if model_path.exists():
            model = joblib.load(model_path)
            break
            
    df_sample = None
    for folder_name in ['data', '.']:
        csv_path = current_dir / folder_name / 'HCMC_UHI_10Years_2017_2026.csv'
        if csv_path.exists():
            # Đọc đủ toàn bộ điểm mẫu (~20.000 dòng, rất nhẹ)
            df_sample = pd.read_csv(csv_path) 
            break
            
    return model, df_sample

@st.cache_data
def get_hcm_boundary():
    f = Path(__file__).resolve().parent / 'data' / 'hcm_boundary.geojson'
    if f.exists():
        return json.loads(f.read_text(encoding='utf-8'))
    try:
        url = "https://nominatim.openstreetmap.org/search.php?q=Ho+Chi+Minh+City+Vietnam&polygon_geojson=1&format=jsonv2"
        for item in requests.get(url, headers={'User-Agent': 'WebGIS_Thesis'}, timeout=10).json():
            if item.get('geojson', {}).get('type') in ('Polygon', 'MultiPolygon'):
                return item['geojson']
    except Exception:
        pass
    return None

def csv_to_raster(df, col, year, colormap, step=0.0025):
    """Dự phòng khi chưa có ảnh raster xuất từ GEE: nội suy các điểm mẫu của 1 năm thành lưới ảnh."""
    d = df[df['Year'] == year]
    allp = df[['longitude', 'latitude']].values
    x0, x1, y0, y1 = allp[:, 0].min(), allp[:, 0].max(), allp[:, 1].min(), allp[:, 1].max()
    gx, gy = np.meshgrid(np.arange(x0, x1, step), np.arange(y0, y1, step))
    pts, v = d[['longitude', 'latitude']].values, d[col].values
    grid = griddata(pts, v, (gx, gy), method='linear')
    grid = np.where(np.isnan(grid), griddata(pts, v, (gx, gy), method='nearest'), grid)
    dist, _ = cKDTree(allp).query(np.c_[gx.ravel(), gy.ravel()])
    inside = dist.reshape(gx.shape) <= 0.012
    lut = np.array([colormap.rgba_floats_tuple(t) for t in np.linspace(colormap.vmin, colormap.vmax, 256)])
    idx = np.clip(((grid - colormap.vmin) / (colormap.vmax - colormap.vmin) * 255).astype(int), 0, 255)
    rgba = lut[idx]
    rgba[..., 3] = np.where(inside, 1.0, 0.0)
    return rgba, [[float(y0), float(x0)], [float(gy.max()), float(gx.max())]]

model, df_sample = load_resources()
hcm_geojson = get_hcm_boundary()
if hcm_geojson is None:
    st.warning('Không tải được ranh giới TP.HCM. Hãy đặt file data/hcm_boundary.geojson (xuất từ notebook).')

# 5. Phân chia bố cục 2 cột
col_map, col_control = st.columns([7, 5], gap="large")

with col_map:
    st.markdown("""
        <div class="custom-container" style="padding-bottom: 5px;">
            <h3 style='margin-top: 0; color: #1e293b; font-size: 18px;'>🗺️ Không gian phân tích chuyên sâu (2017-2026)</h3>
        </div>
    """, unsafe_allow_html=True)
    
    # TRẢ VỀ NDBI GỐC
    data_layer = st.radio(
        "📊 Chọn lớp dữ liệu hiển thị không gian:", 
        ["🌡️ Nhiệt độ bề mặt (LST)", "🌿 Chỉ số thực vật (NDVI)", "🏗️ Mật độ xây dựng (NDBI)", "💧 Khô hạn (TVDI)"], 
        horizontal=True
    )
    
    view_year = st.select_slider('📅 Năm hiển thị bản đồ:', options=list(range(2017, 2027)), value=2024)

    m = folium.Map(location=[10.9, 106.9], zoom_start=9, tiles=None)

    folium.TileLayer(
        tiles='https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
        attr='Google',
        name='🗺️ Bản đồ hành chính (Google Maps)',
        overlay=False,
        control=True
    ).add_to(m)

    folium.TileLayer(
        tiles='https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
        attr='Google',
        name='🛰️ Vệ tinh (Google Satellite)',
        overlay=False,
        control=True
    ).add_to(m)

    # ĐỒNG BỘ COLORMAP VỀ NDBI
    if "LST" in data_layer:
        colormap = cm.LinearColormap(colors=['blue', 'cyan', 'green', 'yellow', 'red'], vmin=25, vmax=45, caption='LST (°C)')
        val_col = 'LST'
    elif "NDVI" in data_layer:
        colormap = cm.LinearColormap(colors=['red', 'yellow', 'lightgreen', 'green', 'darkgreen'], vmin=-0.2, vmax=0.8, caption='NDVI')
        val_col = 'NDVI'
    elif "TVDI" in data_layer:
        colormap = cm.LinearColormap(colors=['darkgreen', 'green', 'yellow', 'orange', 'red'], vmin=0, vmax=1, caption='TVDI')
        val_col = 'TVDI'
    else:
        colormap = cm.LinearColormap(colors=['green', 'yellow', 'red'], vmin=-0.5, vmax=0.5, caption='NDBI')
        val_col = 'NDBI'
    
    colormap.add_to(m)
    
    overlay_dir = Path(__file__).resolve().parent / 'data' / 'overlays'
    png, meta = overlay_dir / f'{val_col}_{view_year}.png', overlay_dir / 'bounds.json'
    if png.exists() and meta.exists():
        bd = json.loads(meta.read_text())
        folium.raster_layers.ImageOverlay(image=str(png), bounds=[[bd['south'], bd['west']], [bd['north'], bd['east']]],
                                          opacity=0.9, name=f'🛰️ Raster {val_col} {view_year} (Landsat 8/9)').add_to(m)
    elif df_sample is not None:
        img, bounds = csv_to_raster(df_sample, val_col, view_year, colormap)
        folium.raster_layers.ImageOverlay(image=img, bounds=bounds, origin='lower', opacity=0.9,
                                          name=f'📊 {val_col} {view_year} (nội suy từ điểm mẫu)').add_to(m)
        st.caption('Đang dùng lớp nội suy từ ~2.000 điểm mẫu/năm. Chạy export_overlays_cell.py để có raster 30 m sắc nét như bản demo.')

    if hcm_geojson:
        folium.GeoJson(
            hcm_geojson,
            name="Ranh giới Hành chính TP.HCM",
            style_function=lambda x: {'color': 'red', 'weight': 2.5, 'fillOpacity': 0}
        ).add_to(m)
        
    folium.LayerControl(collapsed=False).add_to(m)

    st_folium(m, width=None, height=550, use_container_width=True, returned_objects=[])

with col_control:
    st.markdown("""
        <div class="custom-container">
            <h3 style='margin-top: 0; color: #1e293b; font-size: 18px;'>⚙️ Bảng điều khiển Kịch bản (What-if)</h3>
    """, unsafe_allow_html=True)
    
    scenario = st.selectbox(
        "🎯 Chọn Kịch bản mô phỏng môi trường:",
        [
            "Tùy chỉnh thủ công",
            "🌱 Kịch bản Xanh (Tăng cây xanh 20%)",
            "🏗️ Kịch bản Bê tông hóa cực đoan"
        ]
    )

    if scenario == "🌱 Kịch bản Xanh (Tăng cây xanh 20%)":
        default_ndvi = 0.50
        default_ndbi = -0.10
        st.success("💡 Đã kích hoạt kịch bản tăng cường sinh thái mảng xanh.")
    elif scenario == "🏗️ Kịch bản Bê tông hóa cực đoan":
        default_ndvi = 0.05
        default_ndbi = 0.60
        st.warning("⚠️ Đã kích hoạt kịch bản mở rộng hạ tầng bê tông.")
    else:
        default_ndvi = 0.25
        default_ndbi = 0.15

    # KHÔI PHỤC SLIDER NDBI
    ndvi = st.slider("🌿 Chỉ số thực vật (NDVI):", -1.0, 1.0, default_ndvi)
    ndbi = st.slider("🏢 Mật độ xây dựng (NDBI):", -1.0, 1.0, default_ndbi)
    target_year = st.slider("📅 Năm dự báo tương lai:", 2026, 2035, 2030)

    lat, lon = 10.7766, 106.6951
    st.markdown("<br>", unsafe_allow_html=True)

    if st.button("🚀 CHẠY MÔ PHỎNG & DỰ BÁO LST", use_container_width=True):
        if model is not None:
            with st.spinner("Đang tính toán ma trận không gian XGBoost..."):
                # ĐẦU VÀO AI CHUẨN XÁC NDBI
                input_data = pd.DataFrame([[ndvi, ndbi, target_year, lat, lon]], 
                                      columns=['NDVI', 'NDBI', 'Year', 'latitude', 'longitude'])
                pred_lst = model.predict(input_data)[0]
            
            st.markdown(
                f"""
                <div class="metric-card">
                    <h4 style="margin: 0; color: #64748b; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px;">Nhiệt độ bề mặt đất (LST) năm {target_year}</h4>
                    <h1 style="margin: 10px 0 0 0; color: #e11d48; font-size: 40px; font-weight: 800;">{pred_lst:.2f} °C</h1>
                    <p style="margin: 6px 0 0 0; color: #64748b; font-size: 11px;">Kết xuất trực tiếp từ mô hình học máy không gian</p>
                </div>
                """, 
                unsafe_allow_html=True
            )
            
            if pred_lst > 36.0:
                st.error("🚨 Cảnh báo sinh thái: Khu vực có nguy cơ hình thành đảo nhiệt mức độ cao!")
            else:
                st.info("ℹ️ Đánh giá: Biên nhiệt độ nằm trong tầm kiểm soát.")
        else:
            st.error("Không tìm thấy mô hình AI để dự báo!")
            
    st.markdown("</div>", unsafe_allow_html=True)

