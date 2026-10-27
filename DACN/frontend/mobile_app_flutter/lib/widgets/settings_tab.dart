import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SettingsTab extends StatelessWidget {
  final String userName;
  final String userOrg;
  final UserRole currentRole;
  final VoidCallback onShowRoleSwitcher;
  final TextEditingController urlController;
  final VoidCallback onSaveApiUrl;
  final bool isConnected;
  final String healthStatus;

  const SettingsTab({
    super.key,
    required this.userName,
    required this.userOrg,
    required this.currentRole,
    required this.onShowRoleSwitcher,
    required this.urlController,
    required this.onSaveApiUrl,
    required this.isConnected,
    required this.healthStatus,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Profile & RBAC Section
        const Text(
          'Hồ sơ Người dùng & Phân quyền (RBAC)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF1E40AF),
                      child: Text(
                        userName.isNotEmpty ? userName[0] : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            userOrg,
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      avatar: Icon(currentRole.icon, size: 14, color: const Color(0xFF1E40AF)),
                      label: Text(
                        currentRole.title,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onShowRoleSwitcher,
                  icon: const Icon(Icons.switch_account_outlined, size: 16),
                  label: const Text('Chuyển đổi vai trò kiểm thử (Viewer / Planner / Admin)'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        // FastAPI Connection Settings
        const Text(
          'Cấu hình Kết nối Máy chủ FastAPI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: urlController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'API Base URL',
            hintText: 'http://127.0.0.1:8000',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Localhost (127.0.0.1:8000)'),
              onPressed: () {
                urlController.text = 'http://127.0.0.1:8000';
                onSaveApiUrl();
              },
            ),
            ActionChip(
              label: const Text('Android Emulator (10.0.2.2:8000)'),
              onPressed: () {
                urlController.text = 'http://10.0.2.2:8000';
                onSaveApiUrl();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E40AF)),
          onPressed: onSaveApiUrl,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Lưu & Kết nối lại'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isConnected ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Text(
            healthStatus,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isConnected ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),

        const Text(
          'Thông tin Đồ án Chuyên ngành',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Trường:', 'Đại học Tài nguyên và Môi trường TP.HCM'),
                _buildInfoRow('Khoa:', 'Công nghệ Thông tin'),
                _buildInfoRow('Chuyên ngành:', 'Tin học Tài nguyên và Môi trường'),
                _buildInfoRow(
                  'Đề tài:',
                  'Ứng dụng GEE và Machine Learning phân tích, dự báo đảo nhiệt đô thị (UHI) tại TP. Hồ Chí Minh',
                ),
                _buildInfoRow('Giảng viên HD:', 'TS. Dương Thị Thúy Nga'),
                _buildInfoRow('Sinh viên:', 'Nguyễn Duy Tân (MSSV: 1250080265)'),
                _buildInfoRow('Lớp:', '12_ĐH_THMT · Khóa: 2022 – 2026'),
                _buildInfoRow(
                  'Công nghệ nền:',
                  'FastAPI · SQLite · XGBoost · Flutter Native (Windows Desktop & Mobile)',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

