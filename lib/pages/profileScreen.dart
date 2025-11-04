import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'widget/backgroun.dart';

class ProfilPage extends StatefulWidget {
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final AuthService _authService = AuthService();
  final String whatsappLink = "https://wa.link/whos7w";
  Map<String, dynamic>? userData;
  bool isLoading = true;
  User? currentUser;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        userData = await _authService.getUserData();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentUsername: userData?['username'] ?? '',
        ),
      ),
    );

    // Jika result adalah true, berarti ada pembaruan, muat ulang data pengguna
    if (result == true) {
      _loadUserData();
    }
  }

  // Fungsi untuk membuka WhatsApp menggunakan wa.link
  Future<void> _openWhatsApp() async {
    try {
      final Uri uri = Uri.parse(whatsappLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      _showWhatsAppErrorDialog();
    }
  }

  // Dialog error untuk WhatsApp
  void _showWhatsAppErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 12),
            Text('Tidak dapat membuka WhatsApp'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gagal membuka WhatsApp otomatis.'),
            SizedBox(height: 12),
            Text(
              'Silakan buka link berikut secara manual:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            SelectableText(
              whatsappLink,
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(whatsappLink);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Salin Link',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menyalin link ke clipboard
  void _copyToClipboard(String text) {
    final data = ClipboardData(text: text);
    Clipboard.setData(data);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link berhasil disalin ke clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Fungsi untuk menampilkan dialog error
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red.shade600,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signout(context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildHeader(),
                      SizedBox(height: 30),
                      _buildProfileCard(),
                      SizedBox(height: 24),
                      _buildMenuSection(),
                      SizedBox(height: 30),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'Profil Saya',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kelola informasi akun Anda',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFF8B4513).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFF8B4513).withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 50,
              color: Color(0xFF8B4513),
            ),
          ),
          SizedBox(height: 20),

          // User Info
          _buildInfoRow(
            Icons.person_outline_rounded,
            'Username',
            userData?['username'] ?? 'Tidak tersedia',
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            currentUser?.email ?? 'Tidak tersedia',
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            'WhatsApp',
            userData?['wa'] ?? 'Tidak tersedia',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? statusColor}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF8B4513).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Color(0xFF8B4513),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuCard(
          'Pengaturan & Bantuan',
          [
            _buildMenuItem(
              Icons.edit_outlined,
              'Edit Profil',
              'Ubah informasi profil Anda',
              () {
                _navigateToEditProfile();
              },
            ),
            _buildMenuItem(
              Icons.contact_support_outlined,
              'Hubungi Kami',
              'Butuh bantuan? Hubungi customer service',
              () {
                _openWhatsApp(); // Mengganti _showComingSoon dengan _openWhatsApp
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF8B4513).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: Color(0xFF8B4513),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 12),
            Text(
              'Keluar dari Akun',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEmailVerification() async {
    if (currentUser?.emailVerified == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email Anda sudah terverifikasi'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    try {
      await currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email verifikasi telah dikirim'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim email verifikasi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.construction_rounded,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 12),
            Text('Coming Soon'),
          ],
        ),
        content: Text('Fitur $feature sedang dalam pengembangan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF8B4513),
              size: 28,
            ),
            SizedBox(width: 12),
            Text('Tentang Aplikasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dina Griya Rias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            SizedBox(height: 8),
            Text('Versi: 1.0.0'),
            SizedBox(height: 4),
            Text('Platform layanan pernikahan terpercaya'),
            SizedBox(height: 12),
            Text(
              'Hubungi Kami:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('Email: info@dinagriyarias.com'),
            Text('WhatsApp: +62 xxx-xxxx-xxxx'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
