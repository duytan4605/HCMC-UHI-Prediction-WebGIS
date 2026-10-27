import 'package:flutter/material.dart';

import '../api.dart';

class ValidationTab extends StatelessWidget {
  final ValidationMetrics? validationMetrics;
  final XaiData? xaiData;
  final List<StationItem> stations;
  final List<HistoryItem> historyLogs;
  final Function(HistoryItem) onRestoreScenario;
  final Function(int) onDeleteHistoryItem;
  final VoidCallback onClearAllHistory;
  final VoidCallback onExportHistory;

  const ValidationTab({
    super.key,
    required this.validationMetrics,
    required this.xaiData,
    required this.stations,
    required this.historyLogs,
    required this.onRestoreScenario,
    required this.onDeleteHistoryItem,
    required this.onClearAllHistory,
    required this.onExportHistory,
  });

  @override
  Widget build(BuildContext context) {
    final v = validationMetrics;
    final x = xaiData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Kiểm định Mô hình & Trí tuệ Nhân tạo XAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        Text(
          'Kiểm định theo thời gian (Time-split cross-validation): Huấn luyện 2017–2023, kiểm định ngoài mẫu 2024–2026 trên 23.958 điểm.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        // Validation KPI Cards
        if (v != null) ...[
          Row(
            children: [
              _bigKpiCard('RMSE', '${v.rmse}°C', Icons.analytics_outlined, const Color(0xFF1E40AF)),
              const SizedBox(width: 8),
              _bigKpiCard('MAE', '${v.mae}°C', Icons.straighten_outlined, Colors.teal),
              const SizedBox(width: 8),
              _bigKpiCard('R² Score', '${v.r2}', Icons.check_circle_outline, Colors.indigo),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Explainable AI (XAI) Feature Importance
        if (x != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tầm quan trọng của Đặc trưng (XAI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text('Khoảng tin cậy: ${x.confidenceInterval}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final feat in x.features) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(feat.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              Text('${(feat.importance * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                            ],
                          ),
                          const SizedBox(height: 3),
                          LinearProgressIndicator(
                            value: feat.importance,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              feat.code == 'NDBI' ? Colors.redAccent : (feat.code == 'NDVI' ? Colors.green : const Color(0xFF1E40AF)),
                            ),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 2),
                          Text(feat.desc, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Ground truth meteorological stations
        if (stations.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Đối chuẩn với Trạm Khí tượng Thủy văn Mặt đất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 8,
                      columns: const [
                        DataColumn(label: Text('Trạm quan trắc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Thực đo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Vệ tinh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('XGBoost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataColumn(label: Text('Sai số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                      rows: [
                        for (final s in stations)
                          DataRow(
                            cells: [
                              DataCell(Text(s.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                              DataCell(Text('${s.stationTemp}°C', style: const TextStyle(fontSize: 11))),
                              DataCell(Text('${s.satelliteLst}°C', style: const TextStyle(fontSize: 11))),
                              DataCell(Text('${s.predictedLst}°C', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              DataCell(Text('${s.error.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Interactive SQLite History Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nhật ký Kịch bản Mô phỏng (SQLite)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Lưu trữ ngoại tuyến · Nhấp để tái hiện kịch bản', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Xuất CSV',
                  icon: const Icon(Icons.file_download_outlined, color: Color(0xFF1E40AF)),
                  onPressed: onExportHistory,
                ),
                IconButton(
                  tooltip: 'Xóa toàn bộ CSDL',
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                  onPressed: onClearAllHistory,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (historyLogs.isNotEmpty)
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historyLogs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = historyLogs[i];
                return ListTile(
                  dense: true,
                  onTap: () => onRestoreScenario(item),
                  leading: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.restore, size: 16, color: Color(0xFF1E40AF)),
                  ),
                  title: Row(
                    children: [
                      Text('Năm ${item.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.locationsSummary,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${item.ts} · Cây xanh: ${item.dNdvi >= 0 ? "+" : ""}${item.dNdvi.toStringAsFixed(2)} · Bê tông: ${item.dNdbi >= 0 ? "+" : ""}${item.dNdbi.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TB: ${item.mean.toStringAsFixed(1)}°C', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE11D48))),
                          Text('${item.hotPct.toStringAsFixed(0)}% > 36°C', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                        onPressed: () => onDeleteHistoryItem(item.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          const Text('Chưa có nhật ký mô phỏng nào.', style: TextStyle(fontSize: 12, color: Colors.black54)),
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
}

