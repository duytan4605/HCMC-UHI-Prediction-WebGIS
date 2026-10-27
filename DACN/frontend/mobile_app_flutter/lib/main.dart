import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'constants/app_constants.dart';
import 'widgets/chart_tab.dart';
import 'widgets/floating_layer_control.dart';
import 'widgets/map_panel.dart';
import 'widgets/scenario_tab.dart';
import 'widgets/settings_tab.dart';
import 'widgets/validation_tab.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HcmcUhiApp());
}

class HcmcUhiApp extends StatelessWidget {
  const HcmcUhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HCMC UHI Forecast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          primary: const Color(0xFF1E40AF),
          secondary: const Color(0xFFE11D48),
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: Colors.white,
        ),
      ),
      home: const UhiMainScreen(),
    );
  }
}

class UhiMainScreen extends StatefulWidget {
  const UhiMainScreen({super.key});

  @override
  State<UhiMainScreen> createState() => _UhiMainScreenState();
}

class _UhiMainScreenState extends State<UhiMainScreen> {
  static const String _defaultUrl = 'http://127.0.0.1:8000';

  late UhiApi _api;
  final TextEditingController _urlController = TextEditingController(text: _defaultUrl);
  final MapController _mapController = MapController();

  // Navigation & View
  int _activeTab = 0; // Mobile bottom navigation index (0: Map, 1: Scenario, 2: Chart, 3: Validation, 4: Settings)
  int _desktopTab = 0; // Desktop right pane tab index
  bool _loading = false;
  String? _errorMessage;

  // Role-Based Access Control (RBAC)
  UserRole _currentRole = UserRole.planner;
  final String _userName = 'Nguyễn Duy Tân (1250080265)';
  final String _userOrg = 'Khoa CNTT - ĐH Tài nguyên & Môi trường TP.HCM';

  // Scenario Parameters
  int _forecastYear = 2030;
  double _dNdvi = 0.0;
  double _dNdbi = 0.0;

  // Layer Visibility & Controls
  bool _showHeatmap = true;
  bool _showBoundary = true;
  bool _showMarkers = true;
  double _overlayOpacity = 0.85;

  // Layer Mode
  String _layerMode = 'forecast'; // 'forecast' | 'observation'
  String _obsVariable = 'LST'; // LST, NDVI, NDBI, TVDI
  int _obsYear = 2026;

  // Base Map Tile Index (0: Roadmap, 1: Satellite, 2: Dark)
  int _baseMapIndex = 0;

  // Data Cache
  ForecastMap? _forecastData;
  OverlayBounds? _obsBounds;
  final List<PixelSeries> _selectedPixels = [];
  PixelSeries? _activePopupPoint;
  List<List<LatLng>> _boundaryPolylines = [];
  ValidationMetrics? _validationMetrics;
  XaiData? _xaiData;
  List<StationItem> _stations = [];
  List<HistoryItem> _historyLogs = [];
  String _healthStatus = 'Đang kết nối...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _api = UhiApi(_defaultUrl);
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_base_url') ?? _defaultUrl;
    final savedRole = prefs.getString('user_role') ?? 'Planner';
    _urlController.text = savedUrl;
    _api = UhiApi(savedUrl);

    if (savedRole == 'Viewer') _currentRole = UserRole.viewer;
    if (savedRole == 'Admin') _currentRole = UserRole.admin;

    await _checkHealth();
    await _loadBoundary();
    await _loadValidationAndHistory();
    await _runForecast();
  }

  Future<void> _checkHealth() async {
    try {
      final res = await _api.health();
      if (mounted) {
        setState(() {
          _isConnected = true;
          _healthStatus = 'Kết nối thành công · ${res['n_pixels']} điểm ảnh · Năm mốc: ${res['ymax']}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _healthStatus = 'Chưa kết nối API: $e';
        });
      }
    }
  }

  Future<void> _loadBoundary() async {
    try {
      final rings = await _api.boundary();
      if (mounted) {
        setState(() => _boundaryPolylines = rings);
      }
    } catch (_) {}
  }

  Future<void> _loadValidationAndHistory() async {
    final v = await _api.validation();
    final h = await _api.history(limit: 20);
    final b = await _api.overlayBounds();
    final x = await _api.xai();
    final s = await _api.stations();
    if (mounted) {
      setState(() {
        _validationMetrics = v;
        _historyLogs = h;
        _obsBounds = b;
        _xaiData = x;
        _stations = s;
      });
    }
  }

  Future<void> _saveApiUrl() async {
    final raw = _urlController.text.trim().replaceAll(RegExp(r'/$'), '');
    if (raw.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', raw);
    setState(() {
      _api = UhiApi(raw);
      _loading = true;
      _errorMessage = null;
    });

    await _checkHealth();
    await _loadBoundary();
    await _loadValidationAndHistory();
    await _runForecast();
  }

  Future<void> _runForecast() async {
    if (_currentRole == UserRole.viewer) {
      _showRoleRestrictedDialog('Chạy dự báo kịch bản');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final mapData = await _api.forecastMap(
        year: _forecastYear,
        dNdvi: _dNdvi,
        dNdbi: _dNdbi,
      );

      final updatedPixels = <PixelSeries>[];
      for (final p in _selectedPixels) {
        final up = await _api.pixel(
          lat: p.lat,
          lon: p.lon,
          year: _forecastYear,
          dNdvi: _dNdvi,
          dNdbi: _dNdbi,
        );
        updatedPixels.add(up);
      }

      final h = await _api.history(limit: 20);

      if (mounted) {
        setState(() {
          _forecastData = mapData;
          _selectedPixels
            ..clear()
            ..addAll(updatedPixels);
          if (_selectedPixels.isNotEmpty) {
            _activePopupPoint = _selectedPixels.last;
          }
          _historyLogs = h;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onMapTapped(LatLng point) async {
    setState(() => _loading = true);
    try {
      final pixel = await _api.pixel(
        lat: point.latitude,
        lon: point.longitude,
        year: _forecastYear,
        dNdvi: _dNdvi,
        dNdbi: _dNdbi,
      );

      if (mounted) {
        setState(() {
          _selectedPixels.add(pixel);
          if (_selectedPixels.length > 3) {
            _selectedPixels.removeAt(0);
          }
          _activePopupPoint = pixel;
          _showMarkers = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu điểm ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyPreset(double dn, double db) {
    if (_currentRole == UserRole.viewer) {
      _showRoleRestrictedDialog('Thay đổi kịch bản quy hoạch');
      return;
    }
    setState(() {
      _dNdvi = dn;
      _dNdbi = db;
      _layerMode = 'forecast';
      _showHeatmap = true;
    });
    _runForecast();
  }

  Future<void> _saveCurrentScenario() async {
    if (_forecastData == null) return;
    if (_currentRole == UserRole.viewer) {
      _showRoleRestrictedDialog('Lưu trữ kịch bản vào CSDL');
      return;
    }

    final success = await _api.saveScenario(
      year: _forecastYear,
      dNdvi: _dNdvi,
      dNdbi: _dNdbi,
      mean: _forecastData!.mean,
      max: _forecastData!.max,
      hotPct: _forecastData!.hotPct,
      points: _selectedPixels,
      userName: _userName,
      scenarioName: 'Kịch bản $_forecastYear (${_selectedPixels.length} điểm)',
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Đã lưu kịch bản mô phỏng vào SQLite thành công!'),
            duration: Duration(seconds: 3),
          ),
        );
        _loadValidationAndHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Không thể lưu kịch bản vào CSDL SQLite.'),
          ),
        );
      }
    }
  }

  Future<void> _restoreScenario(HistoryItem item) async {
    setState(() {
      _forecastYear = item.year;
      _dNdvi = item.dNdvi;
      _dNdbi = item.dNdbi;
      _layerMode = 'forecast';
      _showHeatmap = true;
      _loading = true;
    });

    try {
      final m = await _api.forecastMap(year: item.year, dNdvi: item.dNdvi, dNdbi: item.dNdbi);
      final restored = <PixelSeries>[];

      if (item.sampledPoints.isNotEmpty) {
        for (final p in item.sampledPoints) {
          final lat = (p['lat'] as num?)?.toDouble();
          final lon = (p['lng'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            final ps = await _api.pixel(
              lat: lat,
              lon: lon,
              year: item.year,
              dNdvi: item.dNdvi,
              dNdbi: item.dNdbi,
            );
            restored.add(ps);
          }
        }
      }

      if (mounted) {
        setState(() {
          _forecastData = m;
          _selectedPixels
            ..clear()
            ..addAll(restored);
          if (_selectedPixels.isNotEmpty) {
            _activePopupPoint = _selectedPixels.first;
            _mapController.move(
              LatLng(_selectedPixels.first.lat, _selectedPixels.first.lon),
              10.5,
            );
          }
          _desktopTab = 1;
          _activeTab = 2; // Jump to charts tab on mobile
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E40AF),
            content: Text('Đã nạp lại kịch bản Năm ${item.year} và ${restored.length} điểm khảo sát!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi phục hồi kịch bản: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteHistoryItem(int id) async {
    if (_currentRole == UserRole.viewer) {
      _showRoleRestrictedDialog('Xóa dữ liệu CSDL');
      return;
    }
    final ok = await _api.deleteHistory(id);
    if (ok) {
      _loadValidationAndHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bản ghi kịch bản khỏi SQLite.')),
        );
      }
    }
  }

  Future<void> _clearAllHistory() async {
    if (_currentRole != UserRole.admin) {
      _showRoleRestrictedDialog('Dọn sạch CSDL (Yêu cầu quyền Admin)');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận dọn sạch CSDL SQLite'),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ lịch sử các lượt chạy mô phỏng không? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa sạch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _api.clearHistory();
      _loadValidationAndHistory();
    }
  }

  Future<void> _exportHistory() async {
    final csv = await _api.exportHistoryCsv();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xuất Dữ liệu Kịch bản (CSV)'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nội dung dữ liệu CSV đã trích xuất từ SQLite:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv.isEmpty ? 'Không có dữ liệu lịch sử.' : csv,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép nội dung CSV vào bộ nhớ tạm!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Sao chép CSV'),
          ),
        ],
      ),
    );
  }

  void _showRoleRestrictedDialog(String actionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Quyền Hạn Bị Giới Hạn'),
          ],
        ),
        content: Text(
          'Tài khoản hiện tại đang ở vai trò "${_currentRole.title}".\n'
          'Thao tác "$actionName" yêu cầu quyền Chuyên viên Quy hoạch (Planner) hoặc Quản trị viên (Admin).\n\n'
          'Bạn có thể chuyển vai trò trong mục Hồ sơ / Cài đặt để kiểm thử đầy đủ các chức năng.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showRoleSwitcherDialog();
            },
            child: const Text('Chuyển vai trò'),
          ),
        ],
      ),
    );
  }

  void _showRoleSwitcherDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phân Quyền Vai Trò (RBAC)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final role in UserRole.values)
              ListTile(
                leading: Icon(
                  role.icon,
                  color: _currentRole == role ? const Color(0xFF1E40AF) : Colors.grey,
                ),
                title: Text(
                  role.title,
                  style: TextStyle(
                    fontWeight: _currentRole == role ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  role == UserRole.viewer
                      ? 'Chỉ xem bản đồ, chuỗi thời gian, thống kê'
                      : role == UserRole.planner
                          ? 'Can thiệp kịch bản cây xanh, bê tông, lưu SQLite'
                          : 'Toàn quyền cấu hình máy chủ, dọn sạch CSDL',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: _currentRole == role ? const Icon(Icons.check, color: Color(0xFF1E40AF)) : null,
                onTap: () async {
                  setState(() => _currentRole = role);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_role', role.code);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Xong')),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        MapPanel(
          mapController: _mapController,
          baseMapIndex: _baseMapIndex,
          showHeatmap: _showHeatmap,
          showBoundary: _showBoundary,
          showMarkers: _showMarkers,
          overlayOpacity: _overlayOpacity,
          layerMode: _layerMode,
          obsVariable: _obsVariable,
          obsYear: _obsYear,
          forecastData: _forecastData,
          obsBounds: _obsBounds,
          boundaryPolylines: _boundaryPolylines,
          selectedPixels: _selectedPixels,
          activePopupPoint: _activePopupPoint,
          onMapTapped: _onMapTapped,
          onPopupClosed: (p) => setState(() => _activePopupPoint = p),
          apiBaseUrl: _api.baseUrl,
          forecastYear: _forecastYear,
        ),
        FloatingLayerControl(
          baseMapIndex: _baseMapIndex,
          onBaseMapChanged: (idx) => setState(() => _baseMapIndex = idx),
          showBoundary: _showBoundary,
          onBoundaryChanged: (val) => setState(() => _showBoundary = val),
          showHeatmap: _showHeatmap,
          onHeatmapChanged: (val) => setState(() => _showHeatmap = val),
          showMarkers: _showMarkers,
          onMarkersChanged: (val) => setState(() => _showMarkers = val),
          overlayOpacity: _overlayOpacity,
          onOpacityChanged: (val) => setState(() => _overlayOpacity = val),
          layerMode: _layerMode,
          onLayerModeChanged: (val) => setState(() => _layerMode = val),
          obsVariable: _obsVariable,
          onObsVariableChanged: (val) => setState(() => _obsVariable = val),
          obsYear: _obsYear,
          onObsYearChanged: (val) => setState(() => _obsYear = val),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      appBar: _buildAppBar(isDesktop),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HCMC Urban Heat Island (UHI)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Đại học Tài nguyên & Môi trường TP.HCM · Khoa CNTT',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        InkWell(
          onTap: _showRoleSwitcherDialog,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_currentRole.icon, size: 14, color: Colors.amberAccent),
                const SizedBox(width: 6),
                Text(
                  _currentRole.title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _isConnected
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isConnected ? Colors.greenAccent : Colors.redAccent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isConnected ? 'API Sống' : 'Mất kết nối',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Map Section (60%)
        Expanded(
          flex: 6,
          child: _buildMapSection(),
        ),
        // Right: Control & Analytics Tabs (40%)
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF1F5F9),
                  child: Row(
                    children: [
                      _buildDesktopTabButton(0, Icons.tune_rounded, 'Kịch bản'),
                      _buildDesktopTabButton(1, Icons.show_chart_rounded, 'Chuỗi điểm'),
                      _buildDesktopTabButton(2, Icons.verified_outlined, 'Kiểm định'),
                      _buildDesktopTabButton(3, Icons.settings_outlined, 'Cài đặt'),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _desktopTab,
                    children: [
                      ScenarioTab(
                        forecastData: _forecastData,
                        errorMessage: _errorMessage,
                        forecastYear: _forecastYear,
                        onYearChanged: (y) => setState(() => _forecastYear = y),
                        dNdvi: _dNdvi,
                        onNdviChanged: (v) => setState(() => _dNdvi = v),
                        dNdbi: _dNdbi,
                        onNdbiChanged: (v) => setState(() => _dNdbi = v),
                        onRunForecast: _runForecast,
                        onSaveScenario: _saveCurrentScenario,
                        onApplyPreset: _applyPreset,
                        currentRole: _currentRole,
                      ),
                      ChartTab(
                        selectedPixels: _selectedPixels,
                        forecastYear: _forecastYear,
                        onClearPoints: () => setState(() {
                          _selectedPixels.clear();
                          _activePopupPoint = null;
                        }),
                      ),
                      ValidationTab(
                        validationMetrics: _validationMetrics,
                        xaiData: _xaiData,
                        stations: _stations,
                        historyLogs: _historyLogs,
                        onRestoreScenario: _restoreScenario,
                        onDeleteHistoryItem: _deleteHistoryItem,
                        onClearAllHistory: _clearAllHistory,
                        onExportHistory: _exportHistory,
                      ),
                      SettingsTab(
                        userName: _userName,
                        userOrg: _userOrg,
                        currentRole: _currentRole,
                        onShowRoleSwitcher: _showRoleSwitcherDialog,
                        urlController: _urlController,
                        onSaveApiUrl: _saveApiUrl,
                        isConnected: _isConnected,
                        healthStatus: _healthStatus,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTabButton(int index, IconData icon, String label) {
    final isActive = _desktopTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _desktopTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF1E40AF) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? const Color(0xFF1E40AF) : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? const Color(0xFF1E40AF) : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return IndexedStack(
      index: _activeTab,
      children: [
        _buildMapSection(),
        ScenarioTab(
          forecastData: _forecastData,
          errorMessage: _errorMessage,
          forecastYear: _forecastYear,
          onYearChanged: (y) => setState(() => _forecastYear = y),
          dNdvi: _dNdvi,
          onNdviChanged: (v) => setState(() => _dNdvi = v),
          dNdbi: _dNdbi,
          onNdbiChanged: (v) => setState(() => _dNdbi = v),
          onRunForecast: _runForecast,
          onSaveScenario: _saveCurrentScenario,
          onApplyPreset: _applyPreset,
          currentRole: _currentRole,
        ),
        ChartTab(
          selectedPixels: _selectedPixels,
          forecastYear: _forecastYear,
          onClearPoints: () => setState(() {
            _selectedPixels.clear();
            _activePopupPoint = null;
          }),
        ),
        ValidationTab(
          validationMetrics: _validationMetrics,
          xaiData: _xaiData,
          stations: _stations,
          historyLogs: _historyLogs,
          onRestoreScenario: _restoreScenario,
          onDeleteHistoryItem: _deleteHistoryItem,
          onClearAllHistory: _clearAllHistory,
          onExportHistory: _exportHistory,
        ),
        SettingsTab(
          userName: _userName,
          userOrg: _userOrg,
          currentRole: _currentRole,
          onShowRoleSwitcher: _showRoleSwitcherDialog,
          urlController: _urlController,
          onSaveApiUrl: _saveApiUrl,
          isConnected: _isConnected,
          healthStatus: _healthStatus,
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: _activeTab,
      onDestinationSelected: (i) => setState(() => _activeTab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Bản đồ',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
          label: 'Kịch bản',
        ),
        NavigationDestination(
          icon: Icon(Icons.show_chart_outlined),
          selectedIcon: Icon(Icons.show_chart_rounded),
          label: 'Điểm ảnh',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_outlined),
          selectedIcon: Icon(Icons.verified),
          label: 'Kiểm định',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Cài đặt',
        ),
      ],
    );
  }
}
