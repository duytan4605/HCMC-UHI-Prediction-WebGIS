# HCMC Urban Heat Island (UHI) — Hệ thống Dự báo Đảo nhiệt Đô thị TP.HCM

**Đồ án chuyên ngành Tin học Tài nguyên và Môi trường**  
**Đề tài:** Ứng dụng Google Earth Engine và Machine Learning phân tích, dự báo đảo nhiệt đô thị tại TP. Hồ Chí Minh.  
**GVHD:** TS. Dương Thị Thúy Nga  
**Sinh viên thực hiện:** Nguyễn Duy Tân (MSSV: 1250080265) — Lớp: 12_ĐH_THMT  
**Đơn vị:** Khoa Công nghệ Thông tin, Trường Đại học Tài nguyên và Môi trường TP. Hồ Chí Minh.

---

## 1. Tổng quan Kiến trúc Hệ thống

Toàn bộ hệ thống được xây dựng theo mô hình Client-Server hiện đại:
- **Backend FastAPI**: Nguồn dữ liệu tập trung duy nhất, chịu trách nhiệm xử lý thuật toán học máy XGBoost, trích xuất xu hướng chuỗi thời gian NDVI/NDBI từ 10 năm dữ liệu Landsat 8/9, nội suy không gian phủ toàn TP.HCM, và quản trị cơ sở dữ liệu SQLite (`uhi.db`).
- **Frontend Flutter (Đa nền tảng - Desktop Windows & Mobile & Web)**: Ứng dụng chính cho người dùng và trình chiếu báo cáo trước Hội đồng. Ứng dụng Flutter được thiết kế theo chuẩn Material 3, giao diện thích ứng (Responsive Layout): hiển thị dạng Dashboard chuyên nghiệp trên màn hình máy tính/máy chiếu (Windows Desktop) và dạng Tab trực quan trên thiết bị di động (Android / iOS / Web).
- **WebGIS PWA**: Giao diện phụ trợ chạy trên trình duyệt hỗ trợ truy cập nhanh qua mạng nội bộ.

```text
┌────────────────────────────────────────────────────────┐
│             Ứng dụng Flutter Đa Nền Tảng               │
│   • Windows Desktop App (.exe native cho Hội đồng)     │
│   • Mobile App (Android / iOS)                        │
└───────────────────────────┬────────────────────────────┘
                            │ (Gọi REST API HTTP/JSON)
                            ▼
┌────────────────────────────────────────────────────────┐
│                   Backend FastAPI                      │
│   • /api/forecast_map  : Heatmap nội suy theo kịch bản │
│   • /api/pixel         : Chuỗi quan trắc + dự báo điểm │
│   • /api/boundary      : Ranh giới hành chính TP.HCM   │
│   • /api/validation    : Chỉ số kiểm định mô hình      │
│   • /api/history       : Nhật ký các lượt mô phỏng     │
│   • /overlays          : Ảnh vệ tinh quan trắc 10 năm  │
└───────────────┬──────────────────────────┬─────────────┘
                ▼                          ▼
     CSDL SQLite (uhi.db)       Mô hình XGBoost (.joblib)
   (8.000+ điểm ảnh, log chạy)   (NDVI, NDBI, tọa độ, năm)
```

---

## 2. Các Tính năng Nổi bật của Ứng dụng Flutter

1. **Dự báo Đảo nhiệt theo Kịch bản Quy hoạch (2027 – 2035)**:
   - Người dùng linh hoạt điều chỉnh: Năm dự báo, mức tăng giảm thảm phủ thực vật ($\Delta\text{NDVI}$) và mật độ xây dựng ($\Delta\text{NDBI}$).
   - Nút chọn nhanh 3 kịch bản: **Hiện trạng gốc**, **Kịch bản phủ xanh đô thị**, và **Kịch bản bê tông hóa**.
   - Thẻ chỉ số tổng hợp thời gian thực: Nhiệt độ bề mặt (LST) trung bình toàn thành phố, LST cực đại, tỷ lệ diện tích có nguy cơ nhiệt cao (> 36 °C).
2. **Quan trắc Lịch sử Viễn thám (2017 – 2026)**:
   - Chuyển đổi lớp bản đồ quan sát 4 chỉ số môi trường: **LST**, **NDVI**, **NDBI**, **TVDI** từ vệ tinh Landsat 8/9 qua 10 năm.
   - Thước đo màu động (Dynamic Legend) phản ánh chính xác khoảng giá trị của từng chỉ số.
3. **Phân tích Tương tác Chuỗi Thời gian Đa Điểm ảnh**:
   - Chạm trực tiếp vào bất kỳ vị trí nào trên bản đồ TP.HCM để trích xuất điểm ảnh gần nhất (tối đa 3 điểm so sánh cùng lúc).
   - Biểu đồ đường tương tác (`fl_chart`): Nét liền biểu diễn chuỗi quan trắc 10 năm (2017–2026), nét đứt biểu diễn xu hướng dự báo kịch bản (2027–2035).
   - Bảng tổng hợp so sánh mức tăng nhiệt ($\Delta T$) và phân loại mức độ rủi ro đảo nhiệt (Thấp, Trung bình, Cao, Rất cao).
4. **Kiểm định Khoa học Mô hình (Model Validation)**:
   - Kiểm định theo phương pháp chia cắt thời gian độc lập (**Time-split Cross-Validation**): Huấn luyện trên chuỗi 2017–2023, kiểm định ngoài mẫu trên giai đoạn 2024–2026 với hơn 23.900 điểm ảnh.
   - Trình bày đầy đủ các chỉ số: $RMSE = 3.20\text{ }^\circ\text{C}$, $MAE = 2.47\text{ }^\circ\text{C}$, $R^2 = 0.39$, so sánh với Baseline Persistence Model ($2.85\text{ }^\circ\text{C}$).
5. **Nhật ký Mô phỏng & Quản trị CSDL**:
   - Tự động ghi lại lịch sử các lần chạy kịch bản vào bảng `run_log` trong CSDL SQLite.
6. **Lớp Bản đồ Đa dạng & Ranh giới TP.HCM**:
   - Hỗ trợ chuyển đổi giữa bản đồ đường phố (OpenStreetMap), bản đồ ảnh vệ tinh (Google/Esri Satellite), và bản đồ nền tối (CartoDB Dark).
   - Vẽ ranh giới địa giới hành chính TP. Hồ Chí Minh sắc nét.

---

## 3. Hướng dẫn Cài đặt & Khởi chạy

### Bước 1: Khởi động Backend FastAPI
Mở terminal tại thư mục gốc của đồ án:
```powershell
# Kích hoạt môi trường ảo Python
.venv\Scripts\activate

# Cài đặt thư viện nếu chưa cài (đã loại bỏ hoàn toàn streamlit)
pip install -r requirements.txt

# Di chuyển vào thư mục backend và chạy server
cd DACN
uvicorn backend.main:app --host 0.0.0.0 --port 8000
```
> Server sẽ lắng nghe tại: `http://127.0.0.1:8000`. Hãy giữ cửa sổ này hoạt động khi demo.

### Bước 2: Chạy Ứng dụng Flutter

#### A. Chạy trên Windows Desktop (Khuyến nghị cho Hội đồng & Trình chiếu):
Mở một terminal mới:
```powershell
cd DACN\frontend\mobile_app_flutter
flutter run -d windows
```
Hoặc mở trực tiếp file chạy Release đã được build sẵn:
```
DACN\frontend\mobile_app_flutter\build\windows\x64\runner\Release\flutter_application_1.exe
```

#### B. Chạy trên Thiết bị Di động (Android / iOS):
- **Trên máy ảo Android Emulator**: Chạy `flutter run` (ứng dụng tự động nhận diện `http://10.0.2.2:8000`).
- **Trên điện thoại thật**: Kết nối chung mạng Wi-Fi với máy tính, mở tab **Cài đặt** trong ứng dụng và nhập IP máy tính (ví dụ `http://192.168.1.15:8000`).

#### C. Chạy trên Web (Chrome / Edge):
```powershell
cd DACN\frontend\mobile_app_flutter
flutter run -d chrome
```

---

## 4. Cấu trúc Mã nguồn

```text
DACN/
├── backend/
│   ├── main.py              # FastAPI Server (XGBoost + SQLite + Heatmap)
│   ├── load_db.py           # Nạp CSV vào CSDL SQLite (uhi.db)
│   ├── validate_time.py     # Kiểm định mô hình theo thời gian (2017-2023 / 2024-2026)
│   └── export_overlays.py   # Xuất ảnh quan trắc LST/NDVI/NDBI/TVDI 10 năm
├── frontend/
│   ├── mobile_app_flutter/  # Ứng dụng Flutter chính (Windows Desktop + Mobile)
│   │   ├── lib/
│   │   │   ├── api.dart     # REST API Client & Data Models
│   │   │   └── main.dart    # Giao diện chính Material 3 Responsive
│   │   ├── pubspec.yaml     # Cấu hình thư viện Flutter
│   │   └── build/windows/   # Bản build Windows native executable
│   └── index.html           # WebGIS PWA
├── data/                    # SQLite uhi.db, GeoJSON, overlays vệ tinh
└── models/                  # ultimate_uhi_model_10yrs.joblib
```

---

## 5. Quy chuẩn Báo cáo Khoa CNTT - HCMUNRE

- Đồ án được chuẩn bị theo đúng thể thức Hướng dẫn trình bày Đồ án chuyên ngành Đại học của Khoa Công nghệ Thông tin - Trường ĐH Tài nguyên và Môi trường TP.HCM:
  - Khổ giấy A4, font Times New Roman, size 13, giãn dòng 1.5 lines.
  - Cấu trúc đầy đủ các trang bìa, lời cảm ơn, lời cam đoan, nhận xét của GVHD & GVPB, lịch làm việc, tóm tắt, mục lục, danh mục sơ đồ hình ảnh, danh mục bảng.
  - Nội dung 3 chương chuẩn mực: Chương 1 Tổng quan tài liệu, Chương 2 Phương pháp thực hiện (thiết kế hệ thống, thuật toán, kiến trúc 1 FastAPI - Flutter Client), Chương 3 Cài đặt thử nghiệm, kết quả và đánh giá.
  - Danh mục tài liệu tham khảo chuẩn IEEE với trên 10 tài liệu khoa học uy tín.
