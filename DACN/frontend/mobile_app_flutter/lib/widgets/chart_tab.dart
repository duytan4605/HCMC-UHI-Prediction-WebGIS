import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../constants/app_constants.dart';

class ChartTab extends StatelessWidget {
  final List<PixelSeries> selectedPixels;
  final int forecastYear;
  final VoidCallback onClearPoints;

  const ChartTab({
    super.key,
    required this.selectedPixels,
    required this.forecastYear,
    required this.onClearPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPixels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Chưa có điểm ảnh nào được chọn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'Chạm trực tiếp lên bản đồ TP.HCM để phân tích chuỗi thời gian nhiệt độ kèm tên Phường/Quận tương ứng.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chuỗi Thời gian Nhiệt độ Bề mặt (LST)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  'Nét liền: Quan trắc 2017–2026 · Nét đứt: Dự báo kịch bản năm $forecastYear',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onClearPoints,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Xóa điểm'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Line Chart Container
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
            child: SizedBox(height: 270, child: LineChart(_buildLineChartData())),
          ),
        ),
        const SizedBox(height: 16),

        // Selected Points Detail Cards & Comparison Table
        const Text('Bảng So sánh & Đánh giá Nguy cơ Đảo nhiệt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),

        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('Điểm khảo sát & Địa danh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Tọa độ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Dự báo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Chênh lệch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('Mức độ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              ],
              rows: [
                for (int i = 0; i < selectedPixels.length; i++)
                  _buildDataRow(i, selectedPixels[i]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(int index, PixelSeries p) {
    final cur = p.latestObserved ?? 0.0;
    final f = p.targetForecast ?? 0.0;
    final d = p.delta ?? 0.0;

    String risk;
    Color riskColor;
    if (f > 38) {
      risk = 'Rất cao';
      riskColor = Colors.red;
    } else if (f > 35) {
      risk = 'Cao';
      riskColor = Colors.orange;
    } else if (f > 32) {
      risk = 'Trung bình';
      riskColor = Colors.amber.shade700;
    } else {
      risk = 'Thấp';
      riskColor = Colors.green;
    }

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: kPointColors[index], shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Điểm ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text(p.locationName, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text('${p.lat.toStringAsFixed(3)}, ${p.lon.toStringAsFixed(3)}', style: const TextStyle(fontSize: 10))),
        DataCell(Text('${cur.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 11))),
        DataCell(Text('${f.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        DataCell(Text(
          '${d >= 0 ? "+" : ""}${d.toStringAsFixed(1)}°C',
          style: TextStyle(fontSize: 11, color: d > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: riskColor, width: 0.8),
            ),
            child: Text(risk, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor)),
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData() {
    double minY = 20;
    double maxY = 50;

    for (final p in selectedPixels) {
      for (final pt in p.observed) {
        if (pt.lst < minY) minY = (pt.lst - 2).floorToDouble();
        if (pt.lst > maxY) maxY = (pt.lst + 2).ceilToDouble();
      }
      for (final pt in p.forecast) {
        if (pt.lst < minY) minY = (pt.lst - 2).floorToDouble();
        if (pt.lst > maxY) maxY = (pt.lst + 2).ceilToDouble();
      }
    }

    return LineChartData(
      minX: 2017,
      maxX: 2035,
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,
        verticalInterval: 2,
        getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        getDrawingVerticalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text('LST (°C)', style: TextStyle(fontSize: 10)),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            reservedSize: 32,
            getTitlesWidget: (val, meta) => Text(
              '${val.toInt()}°',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.x.toInt()}: ${spot.y.toStringAsFixed(1)} °C',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        for (int i = 0; i < selectedPixels.length; i++) ...[
          LineChartBarData(
            spots: [
              for (final pt in selectedPixels[i].observed)
                FlSpot(pt.year.toDouble(), pt.lst),
            ],
            color: kPointColors[i],
            barWidth: 2.5,
            isCurved: true,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: [
              if (selectedPixels[i].observed.isNotEmpty)
                FlSpot(
                  selectedPixels[i].observed.last.year.toDouble(),
                  selectedPixels[i].observed.last.lst,
                ),
              for (final pt in selectedPixels[i].forecast)
                FlSpot(pt.year.toDouble(), pt.lst),
            ],
            color: kPointColors[i],
            barWidth: 2.2,
            dashArray: [6, 4],
            isCurved: true,
            dotData: const FlDotData(show: true),
          ),
        ],
      ],
    );
  }
}

