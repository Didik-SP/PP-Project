// transaksi.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';

class TransaksiPage extends StatefulWidget {
  @override
  _TransaksiPageState createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _transaksiList = [];
  bool _isLoading = false;
  String? _selectedTransactionId;
  File? _selectedImage;
  String? _compressedImageBase64;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 1. Ambil semua data transaksi milik user
      final querySnapshot = await _firestore
          .collection('transaksi')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<Map<String, dynamic>> loadedTransaksi = [];

      // 2. Untuk setiap transaksi, ambil detail booking (termasuk item produk)
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final bookingId = data['bookingId'] as String?;

        List<BookingItem> bookingItems = [];

        // Jika ada bookingId, cari dokumen booking yang sesuai
        if (bookingId != null && bookingId.isNotEmpty) {
          final bookingDoc =
              await _firestore.collection('bookings').doc(bookingId).get();

          if (bookingDoc.exists) {
            final bookingData = bookingDoc.data();
            if (bookingData != null && bookingData['items'] != null) {
              // Ubah list dynamic menjadi List<BookingItem>
              bookingItems = (bookingData['items'] as List<dynamic>)
                  .map((itemData) => BookingItem.fromMap(itemData))
                  .toList();
            }
          }
        }

        // 3. Gabungkan data transaksi dengan data item produk
        loadedTransaksi.add({
          'id': doc.id,
          ...data,
          'products': bookingItems, // Simpan daftar produk
        });
      }

      // 4. Urutkan transaksi berdasarkan tanggal pembuatan (terbaru dulu)
      loadedTransaksi.sort((a, b) {
        final aCreated = a['createdAt'] as Timestamp?;
        final bCreated = b['createdAt'] as Timestamp?;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        return bCreated.compareTo(aCreated);
      });

      setState(() {
        _transaksiList = loadedTransaksi;
      });
    } catch (e) {
      _showErrorDialog('Gagal memuat data transaksi: $e');
      print('Error loading transaksi: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sisa dari kode (helper methods, dialogs, dll) tetap sama
  // ... (SALIN SEMUA METHOD HELPER DARI FILE ASLI ANDA KE SINI)
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        await _compressImage(File(image.path));
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar: $e');
    }
  }

  Future<void> _compressImage(File imageFile) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 800,
        minHeight: 600,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (compressedImage != null) {
        final base64String = base64Encode(compressedImage);
        setState(() {
          _compressedImageBase64 = base64String;
        });
      }
    } catch (e) {
      _showErrorDialog('Gagal mengkompress gambar: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadBuktiBayar(String transactionId) async {
    if (_compressedImageBase64 == null) {
      _showErrorDialog('Silakan pilih foto bukti pembayaran terlebih dahulu');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _firestore.collection('transaksi').doc(transactionId).update({
        'image': _compressedImageBase64,
        'statusPembayaran': 'diproses',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      setState(() {
        _selectedImage = null;
        _compressedImageBase64 = null;
        _selectedTransactionId = null;
      });

      await _loadTransaksi();
      _showSuccessDialog(
          'Bukti pembayaran berhasil dikirim dan status diperbarui');
    } catch (e) {
      _showErrorDialog('Gagal mengirim bukti pembayaran: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showUploadDialog(Map<String, dynamic> transaksi) {
    setState(() {
      _selectedTransactionId = transaksi['id'];
      _selectedImage = null;
      _compressedImageBase64 = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Upload Bukti Pembayaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Transaksi:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Tema: ${transaksi['tema']}'),
                          Text('Booking: ${transaksi['tempat']}'),
                          Text('Tanggal: ${transaksi['tanggalBooking']}'),
                          Text(
                              'DP: Rp ${_formatCurrency(transaksi['hargaDP'])}'),
                          Text(
                              'Total: Rp ${_formatCurrency(transaksi['hargaTotal'])}'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Belum ada foto dipilih'),
                              ],
                            ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading
                            ? null
                            : () async {
                                await _pickImage();
                                setDialogState(() {});
                              },
                        icon: Icon(Icons.photo_library),
                        label: Text('Pilih Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (_isUploading)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Memproses gambar...'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isUploading
                      ? null
                      : () {
                          setState(() {
                            _selectedImage = null;
                            _compressedImageBase64 = null;
                            _selectedTransactionId = null;
                          });
                          Navigator.pop(context);
                        },
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: (_compressedImageBase64 != null && !_isUploading)
                      ? () {
                          Navigator.pop(context);
                          _uploadBuktiBayar(_selectedTransactionId!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final number = amount is int ? amount : (amount as double).toInt();
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'belum dp':
      case 'pending':
        return Colors.orange;
      case 'diproses':
        return Colors.blue;
      case 'selesai':
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'dibatalkan':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Berhasil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8DDD4),
      appBar: AppBar(
        title: Text('Transaksi'),
        backgroundColor: Color(0xFF8B4513).withOpacity(0.3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransaksi,
              child: _transaksiList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _transaksiList.length,
                      itemBuilder: (context, index) {
                        final transaksi = _transaksiList[index];
                        final status = transaksi['statusPembayaran'] ?? '';
                        final canUpload = status.toLowerCase() == 'belum dp' ||
                            status.toLowerCase() == 'pending';

                        // Ambil daftar produk dari data yang sudah digabungkan
                        final List<BookingItem> products =
                            transaksi['products'] ?? [];

                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        transaksi['tema'] ??
                                            'Lokasi Acara', // TEMPAT PEMESANAN
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(transaksi['tanggalBooking'] ??
                                        'Tidak ada tanggal'), // TANGGAL PEMESANAN
                                  ],
                                ),
                                Divider(height: 24),

                                // Info Pembayaran
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('DP (30%):'),
                                          Text(
                                            'Rp ${_formatCurrency(transaksi['hargaDP'])}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Total:'),
                                          Text(
                                            'Rp ${_formatCurrency(transaksi['hargaTotal'])}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Tombol Upload
                                if (canUpload) ...[
                                  SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showUploadDialog(transaksi),
                                      icon: Icon(Icons.cloud_upload),
                                      label: Text('Upload Bukti Pembayaran'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
