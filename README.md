# 🌍 HCMC Urban Heat Island (UHI) Prediction & Analysis WebGIS

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![Google Earth Engine](https://img.shields.io/badge/Google%20Earth%20Engine-API-green.svg)](https://earthengine.google.com/)
[![Machine Learning](https://img.shields.io/badge/Machine%20Learning-XGBoost%20%7C%20Random%20Forest-orange.svg)](https://xgboost.readthedocs.io/)
[![Framework](https://img.shields.io/badge/Framework-Streamlit-FF4B4B.svg)](https://streamlit.io/)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

> **Đồ án chuyên ngành Tin học Môi trường**  
> **Đề tài:** Ứng dụng Google Earth Engine và Machine Learning trong phân tích và dự báo hiện tượng Đảo nhiệt đô thị (Urban Heat Island - UHI) tại TP. Hồ Chí Minh.  
> **Giảng viên hướng dẫn:** TS. Dương Thị Thúy Nga  
> **Sinh viên thực hiện:** Nguyễn Duy Tân (MSSV: 1250080265) - Lớp 12_ĐH_THMT  
> **Đơn vị:** Khoa Công nghệ Thông tin, Trường Đại học Tài nguyên và Môi trường TP. Hồ Chí Minh.

---

## 📌 Giới thiệu tổng quan

Thành phố Hồ Chí Minh đang trải qua tốc độ đô thị hóa và bê tông hóa nhanh chóng, dẫn đến sự suy giảm diện tích mảng xanh và gia tăng cường độ hiện tượng **Đảo nhiệt đô thị (Urban Heat Island - UHI)**.

Hệ thống **HCMC-UHI-Prediction-WebGIS** cung cấp giải pháp toàn diện từ khâu thu thập dữ liệu viễn thám không gian lớn, trích xuất chỉ số sinh thái, huấn luyện mô hình dự báo học máy (Machine Learning) cho đến giao diện trực quan hóa tương tác WebGIS/Dashboard.

### ✨ Các tính năng chính
- **Thu thập & Tiền xử lý tự động (GEE):** Truy vấn chuỗi ảnh vệ tinh Landsat 8/9 và Sentinel-2 (giai đoạn 2017 – 2026), tự động lọc mây (Cloud Masking) và hiệu chỉnh khí quyển trên nền tảng đám mây Google Earth Engine.
- **Trích xuất chỉ số sinh thái đa chiều:** Tự động tính toán Nhiệt độ bề mặt đất ($LST$), Chỉ số thực vật ($NDVI$), Chỉ số mật độ xây dựng ($NDBI$) và Chỉ số khô hạn thực vật - nhiệt độ ($TVDI$).
- **Mô hình hóa dự báo AI:** Triển khai, đối chiếu và tối ưu hóa siêu tham số (GridSearchCV) trên hai thuật toán học máy dạng cây là **Random Forest** và **XGBoost**.
- **Tương tác WebGIS & Dashboard:** Hiển thị lớp bản đồ nhiệt động, tra cứu giá trị theo tọa độ/khu vực, vẽ biểu đồ chuỗi thời gian và giả định kịch bản biến động mảng xanh (What-if analysis).

---

## 🏗 Kiến trúc hệ thống (System Architecture)

Hệ thống được thiết kế theo mô hình 3 tầng độc lập:

1. **Tầng Dữ liệu (Data Layer):** Google Earth Engine API (Kho ảnh viễn thám Big Data) & MongoDB Atlas (Lưu trữ GeoJSON và chuỗi lịch sử/dự báo).
2. **Tầng Xử lý & Mô hình hóa (Application & ML Layer):** Lập trình Python, thư viện `geemap`, `scikit-learn`, `xgboost` thực thi trích xuất chỉ số và suy luận dự báo.
3. **Tầng Hiển thị (Presentation Layer):** Khung ứng dụng Streamlit tích hợp bản đồ tương tác Folium/Leaflet.

---

## 📊 Kết quả thực nghiệm mô hình (Model Performance)

Đánh giá trên tập dữ liệu kiểm thử (Test set) gồm hơn 19.000 điểm mẫu không gian - thời gian tại TP.HCM:

| Mô hình | RMSE (°C) | MAE (°C) | Hệ số xác định ($R^2$) |
| :--- | :---: | :---: | :---: |
| **Random Forest** | 1.15 | 0.82 | 0.88 |
| **XGBoost (Gốc)** | 1.12 | 0.79 | 0.89 |
| **XGBoost (Đã tinh chỉnh - Best Model)** | **1.08** | **0.74** | **0.90** |

*Mô hình XGBoost sau khi tinh chỉnh đạt độ chính xác vượt trội, đáp ứng tốt các chỉ tiêu kỹ thuật đề ra.*

---

## 🛠 Công nghệ & Thư viện sử dụng

- **Ngôn ngữ:** Python 3.10+, JavaScript (GEE Code Editor)
- **Geospatial & Remote Sensing:** `earthengine-api`, `geemap`, `folium`, `geopandas`, `rasterio`
- **Machine Learning & Data Science:** `scikit-learn`, `xgboost`, `pandas`, `numpy`, `joblib`
- **Database:** MongoDB Atlas (NoSQL / GeoJSON)
- **Web Framework:** `streamlit`, `streamlit-option-menu`, `plotly`

---

## 🚀 Hướng dẫn cài đặt & Chạy ứng dụng

### 1. Yêu cầu tiền đề
- Đã cài đặt **Python 3.10** trở lên.
- Có tài khoản **Google Earth Engine** đã được xác thực API key.

### 2. Cài đặt môi trường

```bash
# 1. Clone repository về máy cá nhân
git clone [https://github.com/duytan4605/HCMC-UHI-Prediction-WebGIS.git](https://github.com/duytan4605/HCMC-UHI-Prediction-WebGIS.git)
cd HCMC-UHI-Prediction-WebGIS

# 2. Tạo và kích hoạt môi trường ảo (Virtual Environment)
python -m venv venv
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# 3. Cài đặt các thư viện phụ thuộc
pip install -r requirements.txt

```

### 3. Cấu hình Authenticate Google Earth Engine

Lần đầu chạy, bạn cần xác thực tài khoản GEE:

```python
import ee
ee.Authenticate()
ee.Initialize(project='tên-project-gee-của-bạn')

```

### 4. Khởi chạy ứng dụng WebGIS

```bash
streamlit run app.py

```

Truy cập giao diện tại địa chỉ cục bộ: `http://localhost:8501`

---

## 📁 Cấu trúc thư mục dự án

```text
HCMC-UHI-Prediction-WebGIS/
├── data/                   # Tệp dữ liệu CSV mẫu, GeoJSON ranh giới TP.HCM
├── models/                 # Chứa các file mô hình đã huấn luyện (.joblib, .pkl)
│   ├── best_uhi_model.joblib
│   └── ultimate_uhi_model_10yrs.joblib
├── notebooks/              # Jupyter Notebooks xử lý GEE, Train ML & GridSearch
│   └── final_uhi_model_joblib.ipynb
├── src/                    # Mã nguồn xử lý chính
│   ├── gee_processing.py   # Lọc mây, tính LST, NDVI, TVDI
│   ├── ml_pipeline.py      # Huấn luyện & suy luận mô hình ML
│   └── db_connector.py     # Kết nối MongoDB Atlas
├── app.py                  # Mã nguồn chính giao diện Streamlit WebGIS
├── requirements.txt        # Danh sách thư viện Python
├── LICENSE                 # Giấy phép mã nguồn mở
└── README.md               # Tài liệu hướng dẫn dự án

```

---

## 📝 Đóng góp & Bản quyền

Dự án thuộc quyền sở hữu trí tuệ của **Nguyễn Duy Tân** phục vụ cho Đồ án chuyên ngành Tin học Môi trường tại Trường Đại học Tài nguyên và Môi trường TP. Hồ Chí Minh.

Mọi ý kiến đóng góp hoặc thắc mắc xin vui lòng liên hệ qua Email: `1250080265@sv.hcmunre.edu.vn`.

```

```