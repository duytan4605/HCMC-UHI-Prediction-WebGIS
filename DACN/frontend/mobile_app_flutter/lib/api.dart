import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PixelPoint {
  final int year;
  final double lst;
  PixelPoint({required this.year, required this.lst});
}

class PixelSeries {
  final double lat;
  final double lon;
  final String locationName;
  final List<PixelPoint> observed;
  final List<PixelPoint> forecast;

  PixelSeries({
    required this.lat,
    required this.lon,
    required this.locationName,
    required this.observed,
    required this.forecast,
  });

  double? get latestObserved =>
      observed.isNotEmpty ? observed.last.lst : null;

  double? get targetForecast =>
      forecast.isNotEmpty ? forecast.last.lst : null;

  double? get delta =>
      (latestObserved != null && targetForecast != null)
          ? (targetForecast! - latestObserved!)
          : null;

  String get riskLevel {
    final f = targetForecast ?? 0.0;
    if (f > 38) return 'Rất cao';
    if (f > 35) return 'Cao';
    if (f > 32) return 'Trung bình';
    return 'Thấp';
  }

  Map<String, dynamic> toJson(int order) {
    return {
      'order': order,
      'lat': lat,
      'lng': lon,
      'location_name': locationName,
      'lst_2026': latestObserved ?? 0.0,
      'lst_predict': targetForecast ?? 0.0,
      'difference': delta ?? 0.0,
      'risk_level': riskLevel,
    };
  }
}

class ForecastMap {
  final Uint8List bytes;
  final double south;
  final double west;
  final double north;
  final double east;
  final double mean;
  final double max;
  final double hotPct;

  ForecastMap({
    required this.bytes,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.mean,
    required this.max,
    required this.hotPct,
  });
}

class OverlayBounds {
  final double south;
  final double west;
  final double north;
  final double east;

  OverlayBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });
}

class ValidationMetrics {
  final double rmse;
  final double mae;
  final double r2;
  final double baselineRmse;
  final int nTest;

  ValidationMetrics({
    required this.rmse,
    required this.mae,
    required this.r2,
    required this.baselineRmse,
    required this.nTest,
  });

  factory ValidationMetrics.fromJson(Map<String, dynamic> json) {
    return ValidationMetrics(
      rmse: (json['rmse'] as num?)?.toDouble() ?? 0.0,
      mae: (json['mae'] as num?)?.toDouble() ?? 0.0,
      r2: (json['r2'] as num?)?.toDouble() ?? 0.0,
      baselineRmse: (json['baseline_rmse'] as num?)?.toDouble() ?? 0.0,
      nTest: (json['n_test'] as num?)?.toInt() ?? 0,
    );
  }
}

class HistoryItem {
  final int id;
  final String ts;
  final int year;
  final double dNdvi;
  final double dNdbi;
  final double mean;
  final double max;
  final double hotPct;
  final String sampledPointsJson;
  final String userName;
  final String scenarioName;
  final List<dynamic> sampledPoints;

  HistoryItem({
    required this.id,
    required this.ts,
    required this.year,
    required this.dNdvi,
    required this.dNdbi,
    required this.mean,
    required this.max,
    required this.hotPct,
    required this.sampledPointsJson,
    required this.userName,
    required this.scenarioName,
    required this.sampledPoints,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final rawPts = json['sampled_points_json'] as String? ?? '[]';
    List<dynamic> pts = [];
    try {
      pts = jsonDecode(rawPts) as List<dynamic>;
    } catch (_) {}

    return HistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ts: json['ts'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      dNdvi: (json['d_ndvi'] as num?)?.toDouble() ?? 0.0,
      dNdbi: (json['d_ndbi'] as num?)?.toDouble() ?? 0.0,
      mean: (json['mean'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      hotPct: (json['hot_pct'] as num?)?.toDouble() ?? 0.0,
      sampledPointsJson: rawPts,
      userName: json['user_name'] as String? ?? 'Chuyên viên Quy hoạch',
      scenarioName: json['scenario_name'] as String? ?? 'Kịch bản tùy chọn',
      sampledPoints: pts,
    );
  }

  String get locationsSummary {
    if (sampledPoints.isEmpty) return 'Toàn thành phố';
    final names = sampledPoints
        .map((p) {
          final loc = p['location_name'] as String? ?? '';
          final parts = loc.split(',');
          return parts.isNotEmpty ? parts.last.trim() : loc;
        })
        .where((n) => n.isNotEmpty)
        .toList();
    return names.isNotEmpty ? names.join(' → ') : 'Toàn thành phố';
  }
}

class StationItem {
  final String name;
  final double lat;
  final double lon;
  final double stationTemp;
  final double satelliteLst;
  final double predictedLst;

  StationItem({
    required this.name,
    required this.lat,
    required this.lon,
    required this.stationTemp,
    required this.satelliteLst,
    required this.predictedLst,
  });

  double get error => (stationTemp - predictedLst).abs();

  factory StationItem.fromJson(Map<String, dynamic> json) {
    return StationItem(
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      stationTemp: (json['station_temp'] as num?)?.toDouble() ?? 0.0,
      satelliteLst: (json['satellite_lst'] as num?)?.toDouble() ?? 0.0,
      predictedLst: (json['predicted_lst'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class XaiFeature {
  final String name;
  final String code;
  final double importance;
  final String desc;

  XaiFeature({
    required this.name,
    required this.code,
    required this.importance,
    required this.desc,
  });

  factory XaiFeature.fromJson(Map<String, dynamic> json) {
    return XaiFeature(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      importance: (json['importance'] as num?)?.toDouble() ?? 0.0,
      desc: json['desc'] as String? ?? '',
    );
  }
}

class XaiData {
  final List<XaiFeature> features;
  final String confidenceInterval;
  final double r2Score;
  final double rmse;
  final double mae;

  XaiData({
    required this.features,
    required this.confidenceInterval,
    required this.r2Score,
    required this.rmse,
    required this.mae,
  });

  factory XaiData.fromJson(Map<String, dynamic> json) {
    final feats = ((json['features'] as List?) ?? [])
        .map((f) => XaiFeature.fromJson(f as Map<String, dynamic>))
        .toList();
    return XaiData(
      features: feats,
      confidenceInterval: json['confidence_interval_95'] as String? ?? '±0.8 °C',
      r2Score: (json['r2_score'] as num?)?.toDouble() ?? 0.39,
      rmse: (json['rmse'] as num?)?.toDouble() ?? 3.20,
      mae: (json['mae'] as num?)?.toDouble() ?? 2.47,
    );
  }
}

class UhiApi {
  String base;
  String get baseUrl => base;

  UhiApi(this.base);

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$base$path').replace(queryParameters: q);

  Future<Map<String, dynamic>> health() async {
    final r = await http
        .get(_u('/api/health'))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) {
      throw Exception('API status code: ${r.statusCode}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<ForecastMap> forecastMap({
    required int year,
    required double dNdvi,
    required double dNdbi,
  }) async {
    final r = await http
        .get(_u('/api/forecast_map', {
          'year': '$year',
          'd_ndvi': '$dNdvi',
          'd_ndbi': '$dNdbi',
        }))
        .timeout(const Duration(seconds: 60));
    if (r.statusCode != 200) {
      throw Exception('Lỗi API forecast_map: ${r.statusCode}');
    }
    final d = jsonDecode(r.body) as Map<String, dynamic>;
    final img = d['image'] as String;
    final b64 = img.contains(',') ? img.split(',').last : img;
    final bounds = d['bounds'] as List<dynamic>;
    final sw = bounds[0] as List<dynamic>;
    final ne = bounds[1] as List<dynamic>;
    return ForecastMap(
      bytes: base64Decode(b64),
      south: (sw[0] as num).toDouble(),
      west: (sw[1] as num).toDouble(),
      north: (ne[0] as num).toDouble(),
      east: (ne[1] as num).toDouble(),
      mean: (d['mean'] as num).toDouble(),
      max: (d['max'] as num).toDouble(),
      hotPct: (d['hot_pct'] as num).toDouble(),
    );
  }

  Future<PixelSeries> pixel({
    required double lat,
    required double lon,
    required int year,
    required double dNdvi,
    required double dNdbi,
  }) async {
    final r = await http
        .get(_u('/api/pixel', {
          'lat': '$lat',
          'lon': '$lon',
          'year': '$year',
          'd_ndvi': '$dNdvi',
          'd_ndbi': '$dNdbi',
        }))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('Lỗi API pixel: ${r.statusCode}');
    }
    final d = jsonDecode(r.body) as Map<String, dynamic>;
    List<PixelPoint> parsePoints(String key) =>
        ((d[key] as List?) ?? [])
            .map((e) => PixelPoint(
                  year: (e['year'] as num).toInt(),
                  lst: (e['lst'] as num).toDouble(),
                ))
            .toList();

    return PixelSeries(
      lat: (d['lat'] as num).toDouble(),
      lon: (d['lon'] as num).toDouble(),
      locationName: d['location_name'] as String? ?? 'TP. Hồ Chí Minh',
      observed: parsePoints('observed'),
      forecast: parsePoints('forecast'),
    );
  }

  Future<List<List<LatLng>>> boundary() async {
    final r = await http
        .get(_u('/api/boundary'))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('Lỗi API boundary: ${r.statusCode}');
    }
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final geom = data.containsKey('geometry') ? data['geometry'] : data;
    final type = geom['type'] as String? ?? 'Polygon';
    final coords = geom['coordinates'] as List<dynamic>;

    final List<List<LatLng>> rings = [];
    if (type == 'Polygon') {
      for (final ring in coords) {
        final ringList = (ring as List<dynamic>)
            .map((pt) => LatLng(
                  (pt[1] as num).toDouble(),
                  (pt[0] as num).toDouble(),
                ))
            .toList();
        rings.add(ringList);
      }
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        for (final ring in poly as List<dynamic>) {
          final ringList = (ring as List<dynamic>)
              .map((pt) => LatLng(
                    (pt[1] as num).toDouble(),
                    (pt[0] as num).toDouble(),
                  ))
              .toList();
          rings.add(ringList);
        }
      }
    }
    return rings;
  }

  Future<OverlayBounds?> overlayBounds() async {
    try {
      final r = await http
          .get(_u('/overlays/bounds.json'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        return OverlayBounds(
          south: (d['south'] as num).toDouble(),
          west: (d['west'] as num).toDouble(),
          north: (d['north'] as num).toDouble(),
          east: (d['east'] as num).toDouble(),
        );
      }
    } catch (_) {}
    return null;
  }

  String overlayUrl(String variable, int year) {
    final cleanBase = base.replaceAll(RegExp(r'/$'), '');
    return '$cleanBase/overlays/${variable}_$year.png';
  }

  Future<ValidationMetrics?> validation() async {
    try {
      final r = await http
          .get(_u('/api/validation'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        return ValidationMetrics.fromJson(d);
      }
    } catch (_) {}
    return null;
  }

  Future<List<HistoryItem>> history({int limit = 15}) async {
    try {
      final r = await http
          .get(_u('/api/history', {'limit': '$limit'}))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List<dynamic>;
        return list
            .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> saveScenario({
    required int year,
    required double dNdvi,
    required double dNdbi,
    required double mean,
    required double max,
    required double hotPct,
    required List<PixelSeries> points,
    required String userName,
    required String scenarioName,
  }) async {
    try {
      final payload = {
        'year': year,
        'd_ndvi': dNdvi,
        'd_ndbi': dNdbi,
        'mean': mean,
        'max': max,
        'hot_pct': hotPct,
        'sampled_points': [
          for (int i = 0; i < points.length; i++) points[i].toJson(i + 1),
        ],
        'user_name': userName,
        'scenario_name': scenarioName,
      };

      final r = await http.post(
        _u('/api/scenario/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteHistory(int logId) async {
    try {
      final r = await http.delete(_u('/api/history/$logId'));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearHistory() async {
    try {
      final r = await http.post(_u('/api/history/clear'));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> exportHistoryCsv() async {
    try {
      final r = await http.get(_u('/api/history/export'));
      if (r.statusCode == 200) {
        return r.body;
      }
    } catch (_) {}
    return '';
  }

  Future<List<StationItem>> stations() async {
    try {
      final r = await http.get(_u('/api/stations'));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List<dynamic>;
        return list
            .map((e) => StationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<XaiData?> xai() async {
    try {
      final r = await http.get(_u('/api/xai'));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        return XaiData.fromJson(d);
      }
    } catch (_) {}
    return null;
  }
}
