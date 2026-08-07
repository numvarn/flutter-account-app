import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_app/my_home_page.dart';
import 'package:get_app/profile.dart';
import 'package:get_app/list_and_gridview.dart';
import 'package:get_app/greenpoint/green_point_page.dart';
import 'package:get_app/greenpoint/partner_store_page.dart';
import 'package:get_app/auth/welcome_page.dart';
import 'package:get_app/services/api_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF0D9488),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/me.jpg',
                    fit: BoxFit.cover,
                    width: 64,
                    height: 64,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            accountName: Text(
              'เติ้ล (Tle)',
              style: GoogleFonts.prompt(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            accountEmail: Text(
              'นักศึกษา CSI ปี 3 • รหัส 6712732103',
              style: GoogleFonts.prompt(
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home_rounded,
            title: 'หน้าแรก (Home)',
            color: const Color(0xFF0F172A),
            onTap: () => Get.offAll(() => const MyHomePage()),
          ),
          _buildDrawerItem(
            icon: Icons.person_rounded,
            title: 'ข้อมูลส่วนตัว (Profile)',
            color: const Color(0xFF0F172A),
            onTap: () {
              Get.back();
              Get.to(() => const ProfilePage());
            },
          ),
          _buildDrawerItem(
            icon: Icons.grid_view_rounded,
            title: 'รายการข้อมูล (List & Grid)',
            color: const Color(0xFF0D9488),
            onTap: () {
              Get.back();
              Get.to(() => const ListAndGridViewPage());
            },
          ),
          const Divider(height: 16, thickness: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'งานเสริมที่ส่งคู่กัน (GreenPoint)',
              style: GoogleFonts.prompt(
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.eco_rounded,
            title: 'สะสมคะแนน (GreenPoint)',
            color: const Color(0xFF16A34A),
            onTap: () {
              Get.back();
              Get.to(() => const GreenPointPage());
            },
          ),
          _buildDrawerItem(
            icon: Icons.storefront_rounded,
            title: 'ร้านค้าพันธมิตร (Store)',
            color: const Color(0xFFD97706),
            onTap: () {
              Get.back();
              Get.to(() => const PartnerStorePage());
            },
          ),
          const Divider(height: 16, thickness: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'ระบบบัญชี',
              style: GoogleFonts.prompt(
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            title: 'ออกจากระบบ (Logout)',
            color: const Color(0xFFEF4444),
            onTap: () {
              Get.back();
              Get.defaultDialog(
                title: "ออกจากระบบ",
                titleStyle: GoogleFonts.prompt(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
                content: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    "คุณต้องการออกจากระบบใช่หรือไม่?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(textStyle: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
                  ),
                ),
                textConfirm: "ออกจากระบบ",
                textCancel: "ยกเลิก",
                confirmTextColor: Colors.white,
                cancelTextColor: const Color(0xFF64748B),
                buttonColor: const Color(0xFFEF4444),
                onConfirm: () async {
                  await ApiService.logout();
                  Get.offAll(() => const WelcomePage());
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: GoogleFonts.prompt(
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

