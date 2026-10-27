# TÀI LIỆU ĐẶC TẢ BỔ SUNG NGHIỆP VỤ & KIẾN TRÚC HỆ THỐNG
**Đề tài:** Ứng dụng GEE và Machine Learning phân tích, dự báo đảo nhiệt đô thị (UHI) tại TP. Hồ Chí Minh  
**Học viên/Sinh viên thực hiện:** Nguyễn Duy Tân (MSSV: 1250080265) - Lớp: 12_ĐH_THMT  
**Giảng viên hướng dẫn:** TS. Dương Thị Thúy Nga  
**Đơn vị:** Khoa Công nghệ Thông tin - Trường Đại học Tài nguyên & Môi trường TP.HCM  
**Công nghệ nền tảng:** Flutter Native (Desktop & Mobile) · FastAPI (Python AI Core) · SQLite CSDL Cục bộ · Mô hình XGBoost  

---

## MỤC LỤC TỔNG HỢP
1. [Đánh giá hiện trạng ứng dụng Flutter & Chỉ ra các khiếm khuyết từ thực tế kiểm thử](#1-đánh-giá-hiện-trạng-ứng-dụng-flutter--chỉ-ra-các-khiếm-khuyết-từ-thực-tế-kiểm-thử)
2. [Đề xuất giải pháp khắc phục chi tiết trên giao diện UI/UX và Bản đồ GIS](#2-đề-xuất-giải-pháp-khắc-phục-chi-tiết-trên-giao-diện-uiux-và-bản-đồ-gis)
3. [Kế hoạch tái cấu trúc mã nguồn (Refactoring Architecture) chuẩn Flutter](#3-kế-hoạch-tái-cấu-trúc-mã-nguồn-refactoring-architecture-chuẩn-flutter)
4. [Đặc tả 08 nghiệp vụ Quản lý Tài khoản & Phân quyền (Authentication & Authorization)](#4-đặc-tả-08-nghiệp-vụ-quản-lý-tài-khoản--phân-quyền-authentication--authorization)
5. [Đặc tả 08 nghiệp vụ Quản trị Cơ sở dữ liệu SQLite & Quản lý Dữ liệu cục bộ](#5-đặc-tả-08-nghiệp-vụ-quản-trị-cơ-sở-dữ-liệu-sqlite--quản-lý-dữ-liệu-cục-bộ)
6. [Danh mục các nghiệp vụ chuyên sâu cho Hệ thống AI dự đoán (XGBoost, Landsat, XAI, Kiểm định)](#6-danh-mục-các-nghiệp-vụ-chuyên-sâu-cho-hệ-thống-ai-dự-đoán-xgboost-landsat-xai-kiểm-định)
7. [Đặc tả Schema Cơ sở dữ liệu SQLite & Sơ đồ luồng dữ liệu](#7-đặc-tả-schema-cơ-sở-dữ-liệu-sqlite--sơ-đồ-luồng-dữ-liệu)

---

## 1. ĐÁNH GIÁ HIỆN TRẠNG ỨNG DỤNG FLUTTER & CHỈ RA CÁC KHIẾM KHUYẾT TỪ THỰC TẾ KIỂM THỬ

Dựa trên quá trình vận hành thử nghiệm trên bản dựng Desktop (Windows) và dữ liệu hình ảnh trích xuất từ giao diện ứng dụng, hệ thống đã hoàn thiện được khung sườn cơ bản kết nối giữa FastAPI và Flutter UI. Tuy nhiên, ứng dụng bộc lộ **4 nhóm hạn chế kỹ thuật và trải nghiệm người dùng nghiêm trọng**:

### 1.1. Chấm 3 điểm khảo sát nhưng không hiển thị tên địa phương / ngữ cảnh địa lý
* **Vấn đề quan sát được:** Trên bản đồ, hệ thống cho phép người dùng nhấp chọn 3 điểm quan sát (được đánh số tròn 1, 2, 3 với màu sắc phân biệt Xanh dương - Đỏ - Xanh lá). Tuy nhiên:
  * Bản đồ không hiện nhãn tên phường, xã, quận, huyện hoặc tên địa danh gắn liền với điểm đó.
  * Trong bảng *"So sánh & Đánh giá Nguy cơ Đảo nhiệt"* ở Tab 2, danh sách chỉ hiển thị tọa độ thô dạng số thập phân (ví dụ: `11.124, 106.639`, `10.911, 106.653`, `10.734, 106.715`).
* **Hậu quả nghiệp vụ:** Người sử dụng không chuyên về GIS (như cán bộ quản lý môi trường, nhà quy hoạch đô thị) không thể hình dung ngay điểm số 1 nằm ở khu vực nào (Quận 12, Hóc Môn hay Củ Chi) nếu không tự tra cứu tọa độ bên ngoài. Điều này làm giảm tính trực quan và khả năng ứng dụng thực tế của đồ án.

### 1.2. Nhật ký kịch bản (Tab Kiểm định - SQLite) thiếu thông tin ngữ cảnh khảo sát
* **Vấn đề quan sát được:** Danh sách lịch sử lưu trữ cục bộ ghi nhận hàng loạt dòng kịch bản với cấu trúc đơn điệu:
  > *"Năm 2030 · Cây xanh: +0.00 · Bê tông: +0.00 | TB: 36.9°C (58% > 36°C)"*
* **Hậu quả nghiệp vụ:**
  * Toàn bộ các lượt chạy kịch bản đều hiển thị giống nhau mà không ghi nhận 3 điểm mẫu đã được khảo sát tại vị trí nào trong lượt chạy đó.
  * Khi người dùng nhấp vào một dòng nhật ký trong danh sách, hệ thống không có phản hồi tương tác (không khôi phục lại vị trí 3 điểm lên bản đồ, không vẽ lại biểu đồ đường lịch sử LST). Nhật ký hiện tại mới chỉ dừng lại ở mức "bảng ghi chết" (static logs).

### 1.3. Thiếu công cụ Quản lý lớp bản đồ (Layer Switcher) và điều khiển độ mờ (Opacity)
* **Vấn đề quan sát được:** 
  * Lớp phủ nhiệt độ bề mặt đất (LST Heatmap Raster) cùng ranh giới sáp nhập TP.HCM (vùng đỏ, xanh) luôn luôn đè cố định lên lớp bản đồ nền.
  * Người dùng bấm chuyển qua chế độ bản đồ *"Vệ tinh"* hoặc *"Đường phố"* nhưng không có cách nào tạm tắt lớp màu LST hoặc ẩn ranh giới đỏ để quan sát hiện trạng địa vật, công trình, mạng lưới giao thông thực tế bên dưới.
  * Thanh trượt *"Độ mờ bản đồ Heatmap"* hiện đang bị đặt sâu trong Tab 1 (*Kịch bản & Thống kê*), gây bất tiện khi người dùng chuyển sang các tab khác mà muốn điều chỉnh độ trong suốt của bản đồ.

### 1.4. Tình trạng quá tải mã nguồn trong `main.dart` (Monolithic Code Anti-Pattern)
* **Vấn đề kỹ thuật:** Toàn bộ mã nguồn giao diện (Scaffold, AppBar, Sidebar, TabBar), logic bản đồ (Flutter Map / Leaflet controller, tile layer, markers), logic gọi HTTP client sang FastAPI, và truy vấn đọc ghi SQLite đang bị dồn chung vào một file `main.dart` duy nhất (vượt quá 1.500 - 2.000 dòng lệnh).
* **Rủi ro:** Mã nguồn khó bảo trì, dễ phát sinh lỗi xung đột State khi mở rộng, không thể viết Unit Test riêng cho thuật toán và vi phạm nghiêm trọng nguyên lý trách nhiệm đơn lẻ (Single Responsibility Principle - SRP) trong công nghệ phần mềm.

---

## 2. ĐỀ XUẤT GIẢI PHÁP KHẮC PHỤC CHI TIẾT TRÊN GIAO DIỆN UI/UX VÀ BẢN ĐỒ GIS

### 2.1. Nâng cấp bộ tương tác điểm chấm (Interactive Point Markers & Reverse Geocoding)
* **Tích hợp API Phân giải địa danh:** Khi người dùng click chọn tọa độ trên bản đồ, ứng dụng tự động thực hiện truy vấn Reverse Geocoding (thông qua dịch vụ miễn phí OpenStreetMap Nominatim hoặc nạp sẵn một Shapefile/GeoJSON ranh giới cấp Phường/Xã nội bộ của TP.HCM bằng Turf.js / GEOS library) để lấy tên đơn vị hành chính.
* **Gắn nhãn Tooltip / Callout trực tiếp:**
  * Khi nhấp vào Marker số 1: Hiển thị Popup nổi trên bản đồ gồm: `Điểm 1: P. Tân Chánh Hiệp, Quận 12` | `LST Hiện trạng: 38.9°C` | `Dự báo 2030: 41.1°C`.
  * Cập nhật lại cột *"Điểm"* trong Bảng so sánh Tab 2: Thay vì chỉ ghi số `1`, hiển thị thành `1 - P. Tân Chánh Hiệp (Q.12)`.

### 2.2. Xây dựng Bảng điều khiển Lớp bản đồ chuyên nghiệp (Floating Layer Control)
Thiết kế một widget nổi (Floating Card) trong suốt ở góc trên bên phải hoặc bên trái bản đồ (bên dưới thanh chọn map style Đường phố / Vệ tinh / Tối), cung cấp các công tắc bật/tắt độc lập:
* **Công tắc 1: Lớp Heatmap LST:** Cho phép ẩn/hiện hoàn toàn lớp màu dự báo nhiệt độ.
* **Thanh trượt Độ trong suốt (Layer Opacity Slider):** Cho phép kéo trượt từ $0\%$ (trong suốt hoàn toàn, thấy rõ ảnh vệ tinh) đến $100\%$ (màu nhiệt LST đặc trưng).
* **Công tắc 2: Ranh giới Đô thị sáp nhập:** Bật/tắt đường bao viền đỏ của các khu vực hành chính (TP.HCM, Bà Rịa - Vũng Tàu, Đồng Nai, Bình Dương...).
* **Công tắc 3: Hiển thị Marker khảo sát:** Bật/tắt 3 điểm ghim để xem tổng thể không gian mà không bị che khuất điểm ảnh.

### 2.3. Cải tiến trải nghiệm tương tác với Nhật ký SQLite (Interactive Scenario History)
* Thiết kế lại mỗi thẻ nhật ký trong danh sách:
  * Dòng 1: Thời gian lưu (`2026-10-27 12:10`) & Năm kịch bản (`2030`).
  * Dòng 2: Danh sách địa bàn khảo sát: `Q.12` $\rightarrow$ `Bình Tân` $\rightarrow$ `Cần Giờ`.
  * Dòng 3: Tác động quy hoạch: `ΔNDVI: +0.15` (Phủ xanh), `ΔNDBI: -0.10` (Giảm bê tông).
  * Dòng 4: Chỉ số kết quả: `LST TB: 35.8°C` (Màu xanh dịu mát nếu nhiệt độ giảm, màu đỏ cam nếu nhiệt độ tăng cảnh báo).
* **Tính năng nạp lại kịch bản (Click-to-Restore):** Khi bấm vào thẻ nhật ký, hệ thống sẽ:
  1. Di chuyển camera bản đồ bao quát 3 điểm tương ứng của bản ghi đó.
  2. Tự động set lại các thanh Slider tham số cây xanh / bê tông về đúng cấu hình đã lưu.
  3. Vẽ lại biểu đồ đường chuỗi thời gian ở Tab 2.

---

## 3. KẾ HOẠCH TÁI CẤU TRÚC MÃ NGUỒN (REFACTORING ARCHITECTURE) CHUẨN FLUTTER

Áp dụng mô hình phân lớp chuẩn (Layered Architecture) nhằm tách toàn bộ logic khỏi `main.dart`, chia hệ thống thành các module độc lập theo cây thư mục sau:

```text
lib/
│
├── main.dart                          # Điểm khởi chạy ứng dụng (main, setup Provider/Bloc, MaterialApp)
│
├── core/                              # Cấu hình dùng chung toàn ứng dụng
│   ├── constants/
│   │   ├── app_colors.dart            # Định nghĩa bảng màu nhiệt độ LST, Primary, Dark Theme
│   │   ├── app_constants.dart         # Tọa độ mặc định TP.HCM, URL FastAPI, ngưỡng nhiệt độ
│   │   └── api_endpoints.dart         # Các URL path kết nối backend
│   ├── theme/
│   │   └── app_theme.dart             # Cấu hình giao diện Dark/Light mode
│   └── utils/
│       ├── geo_utils.dart             # Xử lý tính toán tọa độ, chuyển đổi GeoJSON
│       └── formatters.dart            # Format ngày tháng, số thập phân nhiệt độ (°C)
│
├── models/                            # Định nghĩa các lớp đối tượng dữ liệu (Data Entities)
│   ├── point_sample_model.dart        # Model điểm chấm khảo sát (id, lat, lng, name, district, lstHistory)
│   ├── scenario_model.dart            # Model kịch bản chạy (id, timestamp, year, ndvi, ndbi, results)
│   ├── uhi_stat_model.dart            # Thống kê tổng hợp (lst_mean, lst_max, area_percentage)
│   └── user_model.dart                # Model tài khoản người dùng, phân quyền (RBAC)
│
├── services/                          # Tầng xử lý logic nghiệp vụ, mạng và lưu trữ (Data Layer)
│   ├── api_service.dart               # Quản lý toàn bộ HTTP Request đến FastAPI backend
│   ├── sqlite_service.dart            # Quản lý Database Helper: Mở CSDL, CRUD kịch bản và điểm chấm
│   ├── geocoding_service.dart         # Phân giải tọa độ ra tên Phường/Quận
│   └── export_service.dart            # Xử lý xuất báo cáo ra file Excel, CSV, PDF
│
├── state/ hoặc providers/             # Quản lý trạng thái ứng dụng (State Management)
│   ├── map_provider.dart              # Quản lý trạng thái lớp bản đồ, danh sách marker, mode xem
│   ├── scenario_provider.dart         # Quản lý slider tham số, trạng thái chạy model XGBoost
│   └── auth_provider.dart             # Quản lý trạng thái đăng nhập, token, quyền hạn
│
├── screens/                           # Các màn hình chính của ứng dụng
│   ├── splash_screen.dart             # Màn hình chờ kiểm tra kết nối API FastAPI
│   ├── login_screen.dart              # Màn hình đăng nhập, phân quyền người dùng
│   └── home_screen.dart               # Màn hình chính phân chia 2 cột: Map bên trái, Tabs bên phải
│
└── widgets/                           # Các thành phần giao diện con tái sử dụng
    ├── map/
    │   ├── map_gis_view.dart          # Widget FlutterMap chứa TileLayer, Raster LST Layer
    │   ├── map_layer_controller.dart  # Bảng điều khiển bật/tắt lớp và slider Opacity
    │   └── map_marker_popup.dart      # Hộp thoại thông tin khi click vào điểm chấm 1, 2, 3
    ├── panels/
    │   ├── tab_scenario_panel.dart    # Tab 1: Kịch bản quy hoạch, 3 card thống kê, nút chạy AI
    │   ├── tab_timeseries_panel.dart  # Tab 2: Biểu đồ đường LST theo năm & bảng so sánh
    │   ├── tab_validation_panel.dart  # Tab 3: Nhật ký chạy kịch bản SQLite & kiểm định sai số
    │   └── tab_settings_panel.dart    # Tab 4: Cài đặt URL server & thông tin sinh viên đồ án
    └── common/
        ├── metric_card.dart           # Card hiển thị chỉ số nhiệt độ TB, Cực đại, Tỉ lệ > 36°C
        └── custom_slider.dart         # Thanh trượt tùy chỉnh cho NDVI, NDBI, Opacity
```

---

## 4. ĐẶC TẢ 08 NGHIỆP VỤ QUẢN LÝ TÀI KHOẢN & PHÂN QUYỀN (AUTHENTICATION & AUTHORIZATION)

Để đưa đồ án từ một bài tập code giao diện đơn thuần trở thành một ứng dụng chuyển giao công nghệ hoàn chỉnh cho cơ quan quản lý đô thị/môi trường, hệ thống cần được trang bị các nghiệp vụ phân quyền và quản lý tài khoản người dùng sau:

| STT | Tên nghiệp vụ | Mô tả chức năng chi tiết | Vai trò áp dụng |
| :--- | :--- | :--- | :--- |
| **NV-TK01** | **Xác thực Đăng nhập & Đăng ký đa kênh** | Hỗ trợ đăng nhập bằng tài khoản nội bộ (Username/Password) mã hóa mật khẩu theo chuẩn BCrypt/Argon2. Tích hợp tùy chọn đăng nhập bằng tài khoản Google Edu / SSO phục vụ nghiên cứu học thuật. | Tất cả người dùng |
| **NV-TK02** | **Phân quyền theo vai trò (Role-Based Access Control - RBAC)** | Phân chia hệ thống làm 3 cấp bậc quyền hạn rõ rệt:<br>• **Khách/Sinh viên (Viewer):** Chỉ được xem hiện trạng bản đồ nhiệt, xem biểu đồ lịch sử 2017-2026, xem thống kê.<br>• **Chuyên viên Quy hoạch (Planner):** Được can thiệp thanh trượt $\Delta\text{NDVI}$, $\Delta\text{NDBI}$, chạy mô phỏng dự báo XGBoost đến 2035, lưu kịch bản vào CSDL cá nhân.<br>• **Quản trị viên Hệ thống (System Admin):** Cấu hình URL máy chủ FastAPI, xem log hệ thống, dọn dẹp CSDL SQLite, quản lý danh sách tài khoản. | Toàn hệ thống |
| **NV-TK03** | **Quản lý Hồ sơ cá nhân (User Profile)** | Cho phép người dùng cập nhật thông tin cá nhân: Họ tên, Chức vụ, Cơ quan công tác (Sở TN&MT, Viện Quy hoạch...), thay đổi mật khẩu và cập nhật ảnh đại diện. | Toàn bộ tài khoản |
| **NV-TK04** | **Lưu trữ Không gian làm việc cá nhân (Saved Workspaces)** | Người dùng có thể lưu lại "phiên làm việc" gồm: 3 điểm khảo sát quan tâm, góc nhìn camera bản đồ (Zoom, Center Lat/Lng), chế độ bản đồ nền để tải lại ngay khi mở ứng dụng ở các lần sau mà không cần thiết lập lại từ đầu. | Chuyên viên, Admin |
| **NV-TK05** | **Kiểm soát Tần suất gọi API (Rate Limiting & GPU Protection)** | Hệ thống backend và app giới hạn tần suất ấn nút *"Chạy dự báo XGBoost"*. Tài khoản thông thường chỉ được chạy tối đa 15 kịch bản/phút nhằm chống hiện tượng spam gây treo tiến trình tính toán ma trận của FastAPI. | Hệ thống kiểm soát |
| **NV-TK06** | **Ghi nhận Nhật ký Thao tác (User Audit Trail)** | Ghi nhận chi tiết vào CSDL: Tài khoản nào, lúc mấy giờ đã chạy kịch bản dự báo gì, đã thay đổi tham số cây xanh bao nhiêu %, và đã xuất những báo cáo nào để bảo đảm tính minh bạch khi chuyển giao dữ liệu. | Quản trị viên theo dõi |
| **NV-TK07** | **Đồng bộ Kịch bản lên Cloud (Cloud Data Syncing)** | Cho phép Chuyên viên xuất bản kịch bản mô phỏng từ SQLite nội bộ của máy cá nhân lên kho lưu trữ kịch bản chung của dự án trên Server đám mây để các thành viên khác trong hội đồng nghiên cứu cùng xem xét. | Chuyên viên, Admin |
| **NV-TK08** | **Cơ chế Khóa phiên an toàn & Đổi mật khẩu định kỳ** | Tự động đăng xuất hoặc khóa màn hình thao tác nếu người dùng không có tương tác sau 30 phút nhằm bảo đảm an toàn dữ liệu chuyên ngành. Hỗ trợ gửi mã token xác nhận qua Email để cấp lại mật khẩu. | Tất cả người dùng |

---

## 5. ĐẶC TẢ 08 NGHIỆP VỤ QUẢN TRỊ CƠ SỞ DỮ LIỆU SQLITE & QUẢN LÝ DỮ LIỆU CỤC BỘ

Ứng dụng Flutter Desktop vận hành cơ sở dữ liệu SQLite cục bộ (thông qua package `sqflite` hoặc `sqlite3`) nhằm lưu trữ lịch sử kịch bản, tham số và kết quả phục vụ nghiên cứu ngoại tuyến (Offline-First). Các tác vụ bắt buộc phải có gồm:

| STT | Tên nghiệp vụ | Luồng xử lý kỹ thuật & Mô tả chi tiết |
| :--- | :--- | :--- |
| **NV-SQL01** | **Khởi tạo và Di chuyển cấu trúc CSDL (Database Migration)** | Khi ứng dụng khởi động lần đầu, `SqliteService` tự động kiểm tra và tạo mới tệp cơ sở dữ liệu (ví dụ: `uhi_analytics.db`) cùng các bảng, khóa ngoại và chỉ mục (Index) hỗ trợ truy vấn nhanh. Quản lý phiên bản Schema qua `onUpgrade`. |
| **NV-SQL02** | **Lưu trữ Kịch bản Toàn diện (Create Scenario Record)** | Ghi nhận toàn bộ thông số của một lần chạy mô phỏng: Thời gian tạo, Năm dự báo (2030, 2035), Tỉ lệ $\Delta\text{NDVI}$, $\Delta\text{NDBI}$, Nhiệt độ TB, Nhiệt độ cực đại, Tỉ lệ diện tích $> 36^\circ\text{C}$, và mảng JSON lưu trữ thông tin chi tiết của 3 điểm chấm (tọa độ, tên địa bàn, LST dự báo). |
| **NV-SQL03** | **Truy vấn, Lọc và Tìm kiếm Lịch sử (Filter & Search Queries)** | Cung cấp giao diện lọc nhanh danh sách kịch bản: Lọc theo khoảng thời gian thực hiện, lọc theo năm đích (ví dụ chỉ xem kịch bản năm 2035), hoặc lọc các kịch bản có giải pháp "Phủ xanh" ($\Delta\text{NDVI} > 0$). |
| **NV-SQL04** | **Nạp và Tái hiện Trạng thái (Restore Scenario State)** | Khi người dùng click chọn 1 dòng nhật ký trong danh sách SQLite, hệ thống truy vấn lại bản ghi, giải mã chuỗi JSON và tự động điền lại các giá trị lên Sliders, vẽ lại 3 Marker lên bản đồ và hiển thị lại biểu đồ nhiệt độ tương ứng mà không cần gọi lại API backend. |
| **NV-SQL05** | **Xóa đơn lẻ & Xóa hàng loạt (Delete & Batch Purge)** | Người dùng có thể xóa từng kịch bản thử nghiệm không đạt yêu cầu bằng nút thùng rác, hoặc chọn chức năng "Dọn dẹp toàn bộ dữ liệu kiểm định" để đưa bảng nhật ký về trạng thái ban đầu kèm hộp thoại xác nhận an toàn (Dialog confirmation). |
| **NV-SQL06** | **Xuất dữ liệu ra Excel / CSV (Data Export Engine)** | Cho phép trích xuất toàn bộ bảng lịch sử kịch bản và dữ liệu chuỗi thời gian của các điểm khảo sát ra tệp định dạng `.xlsx` hoặc `.csv` phục vụ cho việc đính kèm vào phụ lục báo cáo đồ án hoặc vẽ đồ thị chuyên sâu trên Origin / SPSS. |
| **NV-SQL07** | **Ghi nhận & Cập nhật Dữ liệu Đo đạc Thực tế (Ground Truth Recording)** | Cung cấp chức năng cho phép chuyên viên nhập nhiệt độ quan trắc thực tế từ các trạm khí tượng thủy văn mặt đất (ví dụ trạm Tân Sơn Hòa, trạm Lê Minh Xuân) vào bản ghi SQLite để hệ thống tự tính toán sai số thực nghiệm ($RMSE$, $MAE$) trực tiếp trên giao diện. |
| **NV-SQL08** | **Sao lưu và Phục hồi CSDL (Database Backup & Restore)** | Hỗ trợ tính năng: Export toàn bộ tệp CSDL SQLite (`.db`) ra một thư mục do người dùng chọn trên máy tính (phòng trường hợp cài lại máy hoặc mang sang máy hội đồng chấm đồ án). Cho phép chọn một tệp `.db` có sẵn từ ngoài vào để phục hồi toàn bộ dữ liệu nghiên cứu cũ. |

---

## 6. DANH MỤC CÁC NGHIỆP VỤ CHUYÊN SÂU CHO HỆ THỐNG AI DỰ ĐOÁN (XGBOOST, LANDSAT, XAI, KIỂM ĐỊNH)

Đối với một đồ án chuyên ngành Tin học Môi trường ứng dụng Trí tuệ Nhân tạo, phần xử lý AI không thể là một "hộp đen" (Black-box) đơn giản. Cần bổ sung các nghiệp vụ kỹ thuật sau:

### 6.1. Nghiệp vụ Quản lý Quy trình Dự báo XGBoost theo Kịch bản
* **Đầu vào đa chiều (Multi-feature Inputs):** Mô hình Machine Learning (XGBoost Regressor) chạy trên FastAPI không chỉ nhận năm dự báo mà nhận tập đặc trưng gồm:
  * Chỉ số thực vật hiện trạng ($\text{NDVI}$).
  * Chỉ số xây dựng/bê tông hóa hiện trạng ($\text{NDBI}$).
  * Chỉ số nước mặt ($\text{NDWI}$).
  * Tọa độ không gian (Vĩ độ, Kinh độ để học hiệu ứng phụ thuộc không gian).
* **Mô phỏng động (Dynamic Simulation):** Khi người dùng kéo Slider *"Độ phủ cây xanh (+NDVI)"* lên $+0.15$ và *"Mật độ xây dựng (NDBI)"* xuống $-0.10$, mô hình sẽ tái tính toán ma trận nhiệt độ mới cho toàn bộ $7.986$ điểm ảnh lưới đại diện cho TP.HCM và trả về mảng kết quả phân bố nhiệt mới.

### 6.2. Nghiệp vụ Xử lý & Khai phá Chuỗi thời gian Vệ tinh Landsat (Time-Series Engine)
* **Khai thác dữ liệu Landsat 8/9 Thermal Band (TIRS):** Tích hợp dữ liệu chuỗi thời gian lịch sử từ năm 2017 đến năm 2026.
* **Nghiệp vụ nội suy và xử lý ảnh mây:** Hiển thị rõ trên giao diện phương pháp đã áp dụng trên Google Earth Engine (GEE) để loại trừ mây (QA Cloud Masking) trước khi trích xuất giá trị nhiệt độ bề mặt đất LST ($^\circ\text{C}$) theo từng năm.
* **Trực quan hóa đa điểm (Multi-point Comparison):** Cho phép so sánh đồng thời chuỗi biến thiên nhiệt độ của 3 khu vực có đặc tính mặt đệm đối lập (ví dụ: Điểm 1 - Đô thị hóa nén cao; Điểm 2 - Vùng ven đang chuyển dịch đất đai; Điểm 3 - Rừng ngập mặn/khu sinh thái Cần Giờ).

### 6.3. Nghiệp vụ Giải thích Trí tuệ Nhân tạo (Explainable AI - XAI)
* **Đánh giá mức độ quan trọng của đặc trưng (Feature Importance):** Cung cấp biểu đồ cột thể hiện mức độ đóng góp của từng chỉ số vào kết quả dự báo nhiệt độ LST:
  * Tác động của $\text{NDBI}$ (Mức độ xây dựng): Thường đóng góp $> 45\%$ vào việc làm tăng nhiệt độ cực đoan.
  * Tác động của $\text{NDVI}$ (Mặt đệm cây xanh): Đóng góp làm mát, giảm nhiệt độ từ $2 - 4^\circ\text{C}$.
* **Khoảng tin cậy dự báo (Prediction Interval & Confidence):** Đi kèm với con số dự báo $41.1^\circ\text{C}$ của Năm 2030, hệ thống hiển thị khoảng dao động tin cậy $95\%$ (ví dụ: $[40.2^\circ\text{C} - 42.0^\circ\text{C}]$) dựa trên độ lệch chuẩn của mô hình rừng cây quyết định trong XGBoost.

### 6.4. Nghiệp vụ Đánh giá Độ chính xác & Kiểm định Mô hình (Model Validation)
* **Tự động tính toán các chỉ số thống kê sai số:**
  * **Hệ số xác định ($R^2$ Score):** Thể hiện mức độ tương thích giữa giá trị LST dự báo và giá trị LST thực tế quan sát qua vệ tinh ($R^2 \ge 0.85$ là mô hình đạt chuẩn nghiên cứu môi trường).
  * **Sai số tuyệt đối trung bình (MAE - Mean Absolute Error):**
    $$\text{MAE} = \frac{1}{n}\sum_{i=1}^{n}|y_i - \hat{y}_i|$$
  * **Căn bậc hai sai số bình phương trung bình (RMSE - Root Mean Squared Error):**
    $$\text{RMSE} = \sqrt{\frac{1}{n}\sum_{i=1}^{n}(y_i - \hat{y}_i)^2}$$
* **Bảng ma trận kiểm định theo năm:** Hiển thị sai số dự báo thử nghiệm trên tập dữ liệu kiểm tra độc lập (Test Set) của các năm đã có dữ liệu vệ tinh thực tế (như năm 2024, 2025, 2026).

---

## 7. ĐẶC TẢ SCHEMA CƠ SỞ DỮ LIỆU SQLITE & SƠ ĐỒ LUỒNG DỮ LIỆU

### 7.1. Cấu trúc Bảng Cơ sở dữ liệu SQLite (`uhi_analytics.db`)

Dưới đây là các câu lệnh SQL DDL chuẩn hóa để tạo các bảng lưu trữ trong file `sqlite_service.dart`:

```sql
-- 1. BẢNG QUẢN LÝ TÀI KHOẢN NGƯỜI DÙNG (USERS)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT CHECK(role IN ('Viewer', 'Planner', 'Admin')) DEFAULT 'Viewer',
    organization TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. BẢNG LƯU TRỮ NHẬT KÝ KỊCH BẢN MÔ PHỎNG (SCENARIO_LOGS)
CREATE TABLE IF NOT EXISTS scenario_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    scenario_name TEXT,
    target_year INTEGER NOT NULL,               -- Năm dự báo: 2030, 2035...
    delta_ndvi REAL DEFAULT 0.0,                -- Tỉ lệ thay đổi cây xanh (-0.50 đến +0.50)
    delta_ndbi REAL DEFAULT 0.0,                -- Tỉ lệ thay đổi bê tông (-0.50 đến +0.50)
    avg_lst REAL NOT NULL,                      -- Nhiệt độ LST trung bình toàn thành phố (°C)
    max_lst REAL NOT NULL,                      -- Nhiệt độ LST cực đại (°C)
    ratio_above_36 REAL NOT NULL,               -- Phần trăm diện tích > 36°C (%)
    sampled_points_json TEXT NOT NULL,          -- Chuỗi JSON lưu chi tiết tọa độ và LST của 3 điểm khảo sát
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 3. BẢNG LƯU TRỮ ĐIỂM CHẤM KHẢO SÁT CHI TIẾT (SAMPLED_POINTS_DETAIL)
CREATE TABLE IF NOT EXISTS sampled_points_detail (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scenario_id INTEGER NOT NULL,
    point_order INTEGER NOT NULL,               -- Thứ tự điểm: 1, 2, 3
    latitude REAL NOT NULL,                     -- Vĩ độ
    longitude REAL NOT NULL,                    -- Kinh độ
    district_name TEXT,                         -- Tên Phường, Quận (sau geocoding)
    baseline_lst REAL,                          -- Nhiệt độ LST hiện trạng năm mốc (°C)
    predicted_lst REAL,                         -- Nhiệt độ LST sau khi mô phỏng kịch bản (°C)
    risk_level TEXT,                            -- Mức độ nguy cơ: "Bình thường", "Cao", "Rất cao"
    FOREIGN KEY(scenario_id) REFERENCES scenario_logs(id) ON DELETE CASCADE
);

-- 4. BẢNG LƯU DỮ LIỆU KIỂM CHỨNG THỰC TẾ TRẠM MẶT ĐẤT (GROUND_TRUTH_VALIDATION)
CREATE TABLE IF NOT EXISTS ground_truth_validation (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    station_name TEXT NOT NULL,                 -- Tên trạm khí tượng thủy văn
    record_date DATE NOT NULL,
    measured_temp REAL NOT NULL,                -- Nhiệt độ quan trắc thực tế tại trạm (°C)
    satellite_lst REAL NOT NULL,                -- Nhiệt độ LST vệ tinh đo được (°C)
    predicted_lst REAL NOT NULL,                -- Nhiệt độ LST do XGBoost dự báo (°C)
    absolute_error REAL GENERATED ALWAYS AS (abs(measured_temp - predicted_lst)) STORED
);

-- TẠO CHỈ MỤC ĐỂ TỐI ƯU HÓA TRUY VẤN
CREATE INDEX IF NOT EXISTS idx_scenario_created ON scenario_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_points_scenario ON sampled_points_detail(scenario_id);
```

### 7.2. Cấu trúc dữ liệu JSON mẫu lưu trong trường `sampled_points_json`

Nhằm giúp việc nạp lại dữ liệu kịch bản diễn ra tức thì trên ứng dụng Flutter mà không cần JOIN phức tạp, mỗi bản ghi kịch bản sẽ serialize mảng 3 điểm thành JSON như sau:

```json
[
  {
    "order": 1,
    "lat": 11.124,
    "lng": 106.639,
    "location_name": "Phường Tân Chánh Hiệp, Quận 12",
    "lst_2026": 38.9,
    "lst_predict": 41.1,
    "difference": 2.2,
    "risk_level": "Rất cao"
  },
  {
    "order": 2,
    "lat": 10.911,
    "lng": 106.653,
    "location_name": "Phường Bình Trị Đông, Quận Bình Tân",
    "lst_2026": 35.0,
    "lst_predict": 38.3,
    "difference": 3.3,
    "risk_level": "Rất cao"
  },
  {
    "order": 3,
    "lat": 10.734,
    "lng": 106.715,
    "location_name": "Xã Long Hòa, Huyện Cần Giờ",
    "lst_2026": 37.4,
    "lst_predict": 37.8,
    "difference": 0.4,
    "risk_level": "Cao"
  }
]
```

### 7.3. Sơ đồ Luồng Dữ liệu giữa Flutter Native - SQLite - FastAPI

```text
[ Người Dùng Thao Tác ]
       │
       ├──> (1) Nhấp chọn 3 Điểm trên Bản đồ GIS ────> Geocoding Service (Phân giải Tên Quận/Huyện)
       │                                                         │
       │                                                         ▼
       │                                            Hiển thị Callout/Popup Địa danh
       │
       ├──> (2) Kéo Sliders (ΔNDVI, ΔNDBI, Năm 2030)
       │         và Nhấn "Chạy dự báo XGBoost"
       │                     │
       │                     ▼
       │             [ Tầng Mạng: ApiService ]
       │                     │ (Gửi HTTP POST kèm Tọa độ 3 điểm & Tham số)
       │                     ▼
       │             [ FastAPI Backend Engine ]
       │                     │
       │                     ├──> Tải Trọng số Model XGBoost (.joblib / .onnx)
       │                     ├──> Tính toán Nhiệt độ bề mặt LST mới
       │                     └──> Trả về JSON: LST Trung bình, Max, Tỉ lệ >36°C, LST 3 điểm
       │                                     │
       │       ┌─────────────────────────────┘
       ▼       ▼
[ Cập nhật Giao diện Flutter ]
       │
       ├──> Cập nhật 3 Card Thống kê & Vẽ lại Heatmap với Opacity tùy chỉnh
       ├──> Tab 2: Vẽ Biểu đồ đường (LineChart) chuỗi thời gian & Bảng so sánh có tên địa phương
       │
       └──> (3) Tự động Lưu trữ [ SqliteService ]
                     │
                     ▼
             Ghi vào Bảng `scenario_logs` & `sampled_points_detail`
                     │
                     ▼
             Tab 3: Hiển thị ngay lên danh sách Nhật ký SQLite
             (Cho phép Click để Restore lại Bản đồ hoặc Xuất Excel)
```

---

## LỜI KẾT & HƯỚNG TRIỂN KHAI TIẾP THEO

Tài liệu đặc tả bổ sung này đã bao quát toàn diện các khía cạnh cần thiết để nâng cấp đồ án: từ khắc phục các khiếm khuyết hiển thị cụ thể trên giao diện thực tế (nhật ký, ranh giới, định danh điểm), tái cấu trúc mã nguồn theo chuẩn công nghệ phần mềm, đến việc hoàn thiện các nghiệp vụ cơ sở dữ liệu và bảo mật. Khi đưa nội dung này vào báo cáo Word, đề tài sẽ thể hiện được tính chuyên nghiệp, tính ứng dụng thực tiễn cao và đáp ứng trọn vẹn các tiêu chí đánh giá của Hội đồng chấm đồ án tốt nghiệp.