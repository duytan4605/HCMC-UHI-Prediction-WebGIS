import 'package:flutter/material.dart';

class FloatingLayerControl extends StatelessWidget {
  final int baseMapIndex;
  final ValueChanged<int> onBaseMapChanged;
  final bool showBoundary;
  final ValueChanged<bool> onBoundaryChanged;
  final bool showHeatmap;
  final ValueChanged<bool> onHeatmapChanged;
  final bool showMarkers;
  final ValueChanged<bool> onMarkersChanged;
  final double overlayOpacity;
  final ValueChanged<double> onOpacityChanged;
  final String layerMode;
  final ValueChanged<String> onLayerModeChanged;
  final String obsVariable;
  final ValueChanged<String> onObsVariableChanged;
  final int obsYear;
  final ValueChanged<int> onObsYearChanged;

  const FloatingLayerControl({
    super.key,
    required this.baseMapIndex,
    required this.onBaseMapChanged,
    required this.showBoundary,
    required this.onBoundaryChanged,
    required this.showHeatmap,
    required this.onHeatmapChanged,
    required this.showMarkers,
    required this.onMarkersChanged,
    required this.overlayOpacity,
    required this.onOpacityChanged,
    required this.layerMode,
    required this.onLayerModeChanged,
    required this.obsVariable,
    required this.onObsVariableChanged,
    required this.obsYear,
    required this.onObsYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Panel Title
              const Row(
                children: [
                  Icon(Icons.layers_outlined, size: 18, color: Color(0xFF1E40AF)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Quản lý Lớp Bản đồ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 12),

              // Base Map Selector
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _chip('Đường phố', baseMapIndex == 0, () => onBaseMapChanged(0)),
                  _chip('Vệ tinh', baseMapIndex == 1, () => onBaseMapChanged(1)),
                  _chip('Tối', baseMapIndex == 2, () => onBaseMapChanged(2)),
                ],
              ),
              const SizedBox(height: 6),

              // 2 Main Checkboxes directly visible
              _checkboxRow(
                'Lớp nhiệt LST',
                showHeatmap,
                onHeatmapChanged,
                'Tắt/bật lớp màu nhiệt để soi ảnh vệ tinh',
              ),
              _checkboxRow(
                'Ranh giới hành chính',
                showBoundary,
                onBoundaryChanged,
                'Đường viền đỏ bao quanh TP.HCM',
              ),

              // Opacity Slider (when heatmap is enabled)
              if (showHeatmap) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('Độ mờ: ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Slider(
                        value: overlayOpacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        onChanged: onOpacityChanged,
                      ),
                    ),
                    Text(
                      '${(overlayOpacity * 100).round()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],

              const Divider(height: 10),

              // Mode Selector: Forecast vs Historical Observation
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _chip(
                    'Dự báo kịch bản',
                    layerMode == 'forecast',
                    () => onLayerModeChanged('forecast'),
                  ),
                  _chip(
                    'Quan trắc quá khứ',
                    layerMode == 'observation',
                    () => onLayerModeChanged('observation'),
                  ),
                ],
              ),

              // Observation Controls (when in historical mode)
              if (layerMode == 'observation') ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: obsVariable,
                      isDense: true,
                      underline: const SizedBox(),
                      items: ['LST', 'NDVI', 'NDBI', 'TVDI']
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v, style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) onObsVariableChanged(val);
                      },
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: obsYear,
                      isDense: true,
                      underline: const SizedBox(),
                      items: List.generate(10, (i) => 2017 + i)
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y', style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) onObsYearChanged(val);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkboxRow(String label, bool value, ValueChanged<bool> onChanged, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E40AF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}
