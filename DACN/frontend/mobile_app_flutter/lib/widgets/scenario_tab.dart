import 'package:flutter/material.dart';
import '../api.dart';
import '../constants/app_constants.dart';

class ScenarioTab extends StatelessWidget {
  final ForecastMap? forecastData;
  final String? errorMessage;
  final int forecastYear;
  final ValueChanged<int> onYearChanged;
  final double dNdvi;
  final ValueChanged<double> onNdviChanged;
  final double dNdbi;
  final ValueChanged<double> onNdbiChanged;
  final VoidCallback onRunForecast;
  final VoidCallback onSaveScenario;
  final Function(double, double) onApplyPreset;
  final UserRole currentRole;

  const ScenarioTab({
    super.key,
    required this.forecastData,
    required this.errorMessage,
    required this.forecastYear,
    required this.onYearChanged,
    required this.dNdvi,
    required this.onNdviChanged,
    required this.dNdbi,
    required this.onNdbiChanged,
    required this.onRunForecast,
    required this.onSaveScenario,
    required this.onApplyPreset,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    final m = forecastData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
          ),

        // 3 KPI Statistical Cards
        if (m != null) ...[
          const Text('Thống kê Đảo nhiệt Đô thị TP.HCM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              _bigKpiCard('LST Trung bình', '${m.mean.toStringAsFixed(1)}°C', Icons.thermostat_outlined, Colors.blue),
              const SizedBox(width: 8),
              _bigKpiCard('LST Cực đại', '${m.max.toStringAsFixed(1)}°C', Icons.local_fire_department_outlined, Colors.red),
              const SizedBox(width: 8),
              _bigKpiCard('Diện tích > 36°C', '${m.hotPct.toStringAsFixed(1)}%', Icons.pie_chart_outline, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Planning Presets
        const Text('Kịch bản Quy hoạch Môi trường', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.forest, size: 16, color: Colors.green),
              label: const Text('Phủ xanh đô thị (+Cây xanh, -Bê tông)'),
              onPressed: () => onApplyPreset(0.15, -0.10),
            ),
            ActionChip(
              avatar: const Icon(Icons.apartment, size: 16, color: Colors.brown),
              label: const Text('Bê tông hóa (-Cây xanh, +Bê tông)'),
              onPressed: () => onApplyPreset(-0.15, 0.15),
            ),
            ActionChip(
              avatar: const Icon(Icons.restore, size: 16, color: Colors.grey),
              label: const Text('Hiện trạng gốc (Giữ nguyên)'),
              onPressed: () => onApplyPreset(0.0, 0.0),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Parameter Sliders Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tùy chỉnh Tham số Mô hình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                _slider(
                  label: 'Năm dự báo',
                  valueDisplay: '$forecastYear',
                  value: forecastYear.toDouble(),
                  min: 2027,
                  max: 2035,
                  step: 1,
                  onChanged: (v) => onYearChanged(v.round()),
                  onChangeEnd: (_) => onRunForecast(),
                ),
                _slider(
                  label: 'Độ phủ cây xanh (NDVI)',
                  valueDisplay: '${dNdvi >= 0 ? "+" : ""}${dNdvi.toStringAsFixed(2)}',
                  value: dNdvi,
                  min: -0.30,
                  max: 0.30,
                  step: 0.05,
                  onChanged: (v) => onNdviChanged((v * 20).round() / 20),
                  onChangeEnd: (_) => onRunForecast(),
                ),
                _slider(
                  label: 'Mật độ xây dựng (NDBI)',
                  valueDisplay: '${dNdbi >= 0 ? "+" : ""}${dNdbi.toStringAsFixed(2)}',
                  value: dNdbi,
                  min: -0.30,
                  max: 0.30,
                  step: 0.05,
                  onChanged: (v) => onNdbiChanged((v * 20).round() / 20),
                  onChangeEnd: (_) => onRunForecast(),
                ),
                const SizedBox(height: 12),

                // Action Buttons: Run & Save to SQLite
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF1E40AF),
                        ),
                        onPressed: onRunForecast,
                        icon: const Icon(Icons.bolt),
                        label: const Text('CHẠY DỰ BÁO', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: onSaveScenario,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Lưu SQLite', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 Cơ chế AI & Viễn thám:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E40AF)),
              ),
              SizedBox(height: 4),
              Text(
                '• Huấn luyện trên chuỗi 10 năm Landsat 8/9 trích xuất từ Google Earth Engine.\n'
                '• Tự động phân giải tên Quận/Huyện cho từng điểm ảnh khi người dùng chạm bản đồ.\n'
                '• Hỗ trợ lưu trữ và phục hồi kịch bản ngoại tuyến với cơ sở dữ liệu SQLite.',
                style: TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bigKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
              const SizedBox(height: 2),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required String valueDisplay,
    required double value,
    required double min,
    required double max,
    required double step,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(valueDisplay, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}

