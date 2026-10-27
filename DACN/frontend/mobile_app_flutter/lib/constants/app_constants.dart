import 'package:flutter/material.dart';

const List<Color> kPointColors = [
  Color(0xFF2563EB), // Blue
  Color(0xFFE11D48), // Rose/Red
  Color(0xFF16A34A), // Green
];

enum UserRole {
  viewer('Viewer', 'Khách / Sinh viên', Icons.visibility_outlined),
  planner('Planner', 'Chuyên viên Quy hoạch', Icons.architecture_outlined),
  admin('Admin', 'Quản trị viên Hệ thống', Icons.admin_panel_settings_outlined);

  final String code;
  final String title;
  final IconData icon;
  const UserRole(this.code, this.title, this.icon);
}

String getBaseMapUrl(int index) {
  switch (index) {
    case 1:
      // Google Satellite
      return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
    case 2:
      // CartoDB Dark Matter
      return 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png';
    default:
      // Google Roadmap (Đường phố Việt Nam sắc nét, không bị lỗi mạng)
      return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  }
}

