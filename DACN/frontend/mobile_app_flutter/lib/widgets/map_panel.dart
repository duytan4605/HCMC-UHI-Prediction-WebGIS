import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api.dart';
import '../constants/app_constants.dart';

class MapPanel extends StatelessWidget {
  final MapController mapController;
  final int baseMapIndex;
  final bool showHeatmap;
  final bool showBoundary;
  final bool showMarkers;
  final double overlayOpacity;
  final String layerMode;
  final String obsVariable;
  final int obsYear;
  final ForecastMap? forecastData;
  final OverlayBounds? obsBounds;
  final List<List<LatLng>> boundaryPolylines;
  final List<PixelSeries> selectedPixels;
  final PixelSeries? activePopupPoint;
  final ValueChanged<LatLng> onMapTapped;
  final ValueChanged<PixelSeries?> onPopupClosed;
  final String apiBaseUrl;
  final int forecastYear;

  const MapPanel({
    super.key,
    required this.mapController,
    required this.baseMapIndex,
    required this.showHeatmap,
    required this.showBoundary,
    required this.showMarkers,
    required this.overlayOpacity,
    required this.layerMode,
    required this.obsVariable,
    required this.obsYear,
    required this.forecastData,
    required this.obsBounds,
    required this.boundaryPolylines,
    required this.selectedPixels,
    required this.activePopupPoint,
    required this.onMapTapped,
    required this.onPopupClosed,
    required this.apiBaseUrl,
    required this.forecastYear,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // FlutterMap
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: const LatLng(10.78, 106.75),
            initialZoom: 9.6,
            onTap: (tapPosition, point) => onMapTapped(point),
          ),
          children: [
            // Base Map Tile Layer with auto-flush ValueKey
            TileLayer(
              key: ValueKey('basemap_tile_layer_$baseMapIndex'),
              urlTemplate: getBaseMapUrl(baseMapIndex),
              userAgentPackageName: 'vn.edu.hcmunre.uhi',
            ),

            // Forecast Heatmap Overlay
            if (showHeatmap && layerMode == 'forecast' && forecastData != null)
              OverlayImageLayer(
                overlayImages: [
                  OverlayImage(
                    bounds: LatLngBounds(
                      LatLng(forecastData!.south, forecastData!.west),
                      LatLng(forecastData!.north, forecastData!.east),
                    ),
                    imageProvider: MemoryImage(forecastData!.bytes),
                    opacity: overlayOpacity,
                  ),
                ],
              ),

            // Historical Observation Overlay
            if (showHeatmap && layerMode == 'observation' && obsBounds != null)
              OverlayImageLayer(
                overlayImages: [
                  OverlayImage(
                    bounds: LatLngBounds(
                      LatLng(obsBounds!.south, obsBounds!.west),
                      LatLng(obsBounds!.north, obsBounds!.east),
                    ),
                    imageProvider: NetworkImage(
                      '$apiBaseUrl/overlays/${obsVariable}_$obsYear.png',
                    ),
                    opacity: overlayOpacity,
                  ),
                ],
              ),

            // Administrative boundary outline
            if (showBoundary && boundaryPolylines.isNotEmpty)
              PolylineLayer(
                polylines: boundaryPolylines.map((ring) {
                  return Polyline(
                    points: ring,
                    strokeWidth: 2.2,
                    color: Colors.redAccent.withValues(alpha: 0.9),
                  );
                }).toList(),
              ),

            // Markers for selected pixels (up to 3)
            if (showMarkers)
              MarkerLayer(
                markers: [
                  for (int i = 0; i < selectedPixels.length; i++)
                    Marker(
                      point: LatLng(selectedPixels[i].lat, selectedPixels[i].lon),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => onPopupClosed(selectedPixels[i]),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kPointColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),

        // Color Legend Bar in Top-Right
        _buildMapLegend(),

        // Marker Callout / Popup in Bottom-Left
        if (activePopupPoint != null) _buildMarkerCalloutPopup(),
      ],
    );
  }

  Widget _buildMapLegend() {
    String title = 'LST (°C)';
    List<Color> colors = [
      const Color(0xFF0000FF),
      const Color(0xFF00FFFF),
      const Color(0xFF00AA00),
      const Color(0xFFFFFF00),
      const Color(0xFFFF0000),
    ];
    String minVal = '25';
    String midVal = '35';
    String maxVal = '45';

    if (layerMode == 'observation') {
      if (obsVariable == 'NDVI') {
        title = 'NDVI (Thực vật)';
        colors = [Colors.red, Colors.yellow, Colors.lightGreen, Colors.green, const Color(0xFF004D00)];
        minVal = '-0.2';
        midVal = '0.3';
        maxVal = '0.8';
      } else if (obsVariable == 'NDBI') {
        title = 'NDBI (Xây dựng)';
        colors = [Colors.green, Colors.yellow, Colors.red];
        minVal = '-0.5';
        midVal = '0.0';
        maxVal = '0.5';
      } else if (obsVariable == 'TVDI') {
        title = 'TVDI (Hạn hán)';
        colors = [Colors.green, Colors.yellow, Colors.orange, Colors.red];
        minVal = '0.0';
        midVal = '0.5';
        maxVal = '1.0';
      }
    }

    return Positioned(
      top: 12,
      right: 12,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(colors: colors),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(minVal, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  Text(midVal, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  Text(maxVal, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerCalloutPopup() {
    final p = activePopupPoint!;
    final index = selectedPixels.indexOf(p);
    final idxDisplay = index >= 0 ? index + 1 : 1;
    final color = index >= 0 ? kPointColors[index] : const Color(0xFF1E40AF);
    final cur = p.latestObserved ?? 0.0;
    final target = p.targetForecast ?? 0.0;
    final delta = p.delta ?? 0.0;

    return Positioned(
      bottom: 24,
      left: 12,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color, width: 1.5),
        ),
        elevation: 6,
        child: Container(
          width: 310,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                        child: Text('Điểm $idxDisplay', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 190,
                        child: Text(
                          p.locationName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => onPopupClosed(null),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tọa độ: ${p.lat.toStringAsFixed(4)}°B, ${p.lon.toStringAsFixed(4)}°Đ',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _calloutItem('LST 2026', '${cur.toStringAsFixed(1)}°C', Colors.black87),
                  _calloutItem('Dự báo $forecastYear', '${target.toStringAsFixed(1)}°C', color),
                  _calloutItem(
                    'Chênh lệch',
                    '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)}°C',
                    delta > 0 ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calloutItem(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valColor)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}

