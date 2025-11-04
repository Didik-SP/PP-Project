import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/produk.dart';
import '../providers/booking_provider.dart';
import '../providers/product_provider.dart';
import 'booking_confirmation_dialog.dart';

class BulkBookingPage extends StatefulWidget {
  final List<Product> favoriteProducts;

  const BulkBookingPage({
    super.key,
    required this.favoriteProducts,
  });

  @override
  State<BulkBookingPage> createState() => _BulkBookingPageState();
}

class _BulkBookingPageState extends State<BulkBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tempatController = TextEditingController();
  final TextEditingController _temaController =
      TextEditingController(); // DITAMBAHKAN
  DateTime? _tanggalDipilih;
  bool _isLoading = false;
  bool _isLoadingUserData = true;
  List<Product> _selectedProducts = [];
  String _namaPemesan = '';

  // Cache untuk gambar produk untuk menghindari rebuild berulang
  final Map<String, String> _imageCache = {};

  @override
  void initState() {
    super.initState();
    // Pilih semua produk secara default
    _selectedProducts = List.from(widget.favoriteProducts);

    // Load user data dan preload images
    _loadUserData();
    _preloadImages();
  }

  // Load data user dari Firestore
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _namaPemesan = userData['username'] ?? '';
            _isLoadingUserData = false;
          });
        } else {
          // Jika data user tidak ditemukan, gunakan email sebagai fallback
          setState(() {
            _namaPemesan = user.email ?? '';
            _isLoadingUserData = false;
          });
        }
      } else {
        // User tidak login
        setState(() {
          _namaPemesan = '';
          _isLoadingUserData = false;
        });

        if (mounted) {
          _showErrorSnackBar('User tidak terautentikasi');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
        _showErrorSnackBar('Gagal memuat data user');
      }
    }
  }

  // Preload gambar untuk mengurangi rebuild yang berlebihan
  void _preloadImages() async {
    final productProvider = context.read<ProductProvider>();
    for (final product in widget.favoriteProducts) {
      try {
        final imageUrl = await productProvider.getFirstProductImage(product.id);
        if (mounted) {
          _imageCache[product.id] = imageUrl;
        }
      } catch (e) {
        debugPrint('Error preloading image for ${product.id}: $e');
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Helper function to decode base64 string to Uint8List
  Uint8List? _decodeBase64(String base64String) {
    try {
      if (base64String.isEmpty) return null;

      // Remove data:image/jpeg;base64, prefix if exists
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      return base64Decode(cleanBase64);
    } catch (e) {
      debugPrint('Error decoding base64: $e');
      return null;
    }
  }

  // Widget helper untuk menampilkan gambar base64 dengan optimasi
  Widget _buildBase64Image(String base64String,
      {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    // Return placeholder jika string kosong
    if (base64String.isEmpty) {
      return _buildImagePlaceholder(width, height, Icons.image_not_supported);
    }

    try {
      final Uint8List? imageBytes = _decodeBase64(base64String);

      if (imageBytes != null && imageBytes.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            width: width,
            height: height,
            fit: fit,
            // Gunakan cacheWidth dan cacheHeight untuk optimasi memori
            cacheWidth: width?.toInt(),
            cacheHeight: height?.toInt(),
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error displaying image: $error');
              return _buildImagePlaceholder(width, height, Icons.broken_image);
            },
          ),
        );
      } else {
        return _buildImagePlaceholder(width, height, Icons.error_outline);
      }
    } catch (e) {
      debugPrint('Exception in _buildBase64Image: $e');
      return _buildImagePlaceholder(width, height, Icons.error_outline);
    }
  }

  // Helper untuk placeholder gambar
  Widget _buildImagePlaceholder(double? width, double? height, IconData icon) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 24,
        color: Colors.grey[400],
      ),
    );
  }

  // Widget untuk menampilkan item produk dengan optimasi
  Widget _buildProductListItem(Product product, bool isSelected) {
    // Gunakan cache jika tersedia
    final cachedImage = _imageCache[product.id];

    if (cachedImage != null) {
      return _buildProductTile(product, isSelected, cachedImage);
    }

    // Jika tidak ada cache, gunakan FutureBuilder dengan key unik
    return FutureBuilder<String>(
      key: ValueKey('product_${product.id}'),
      future: context.read<ProductProvider>().getFirstProductImage(product.id),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data ?? '';

        // Cache hasil untuk menghindari rebuild
        if (snapshot.hasData && imageUrl.isNotEmpty) {
          _imageCache[product.id] = imageUrl;
        }

        return _buildProductTile(product, isSelected, imageUrl);
      },
    );
  }

  // Widget tile produk yang terpisah
  Widget _buildProductTile(Product product, bool isSelected, String imageUrl) {
    return CheckboxListTile(
      key: ValueKey('tile_${product.id}'),
      value: isSelected,
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            if (!_selectedProducts.contains(product)) {
              _selectedProducts.add(product);
            }
          } else {
            _selectedProducts.remove(product);
          }
        });
      },
      title: Text(
        product.nama,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Rp${NumberFormat('#,###', 'id_ID').format(product.harga)}',
        style: TextStyle(
          color: Color(0xFF8B4513),
          fontWeight: FontWeight.w500,
        ),
      ),
      secondary: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: imageUrl.isNotEmpty
            ? _buildBase64Image(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : Icon(
                Icons.image_not_supported,
                size: 24,
                color: Colors.grey[400],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final totalHarga = _selectedProducts.fold<int>(
      0,
      (sum, product) => sum + product.harga,
    );

    // Tampilkan loading jika masih memuat data user
    if (_isLoadingUserData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Pesan Produk"),
          backgroundColor: Color(0xFF8B4513),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data user...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesan Produk"),
        backgroundColor: Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Produk (${_selectedProducts.length}/${widget.favoriteProducts.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedProducts =
                                        List.from(widget.favoriteProducts);
                                  });
                                },
                                child: const Text('Pilih Semua'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Gunakan ListView.separated untuk performa yang lebih baik
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.favoriteProducts.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final product = widget.favoriteProducts[index];
                        final isSelected =
                            _selectedProducts.any((p) => p.id == product.id);

                        return _buildProductListItem(product, isSelected);
                      },
                    ),

                    if (_selectedProducts.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Estimasi:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp${NumberFormat('#,###', 'id_ID').format(totalHarga)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B4513),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Display Nama Pemesan (Read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama Pemesan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _namaPemesan.isNotEmpty
                              ? _namaPemesan
                              : 'Tidak diketahui',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _temaController,
                decoration: InputDecoration(
                  labelText: "Tema Acara",
                  prefixIcon: const Icon(Icons.style),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan tema pemesanan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isLoading ? null : () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Tanggal Dijadwalkan",
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _tanggalDipilih != null &&
                            bookingProvider.terBooking(_tanggalDipilih!)
                        ? const Tooltip(
                            message:
                                'Anda sudah memiliki jadwal pada tanggal ini',
                            child: Icon(Icons.warning, color: Colors.orange),
                          )
                        : null,
                  ),
                  child: Text(
                    _tanggalDipilih != null
                        ? DateFormat('dd MMM yyyy').format(_tanggalDipilih!)
                        : 'Pilih Tanggal',
                    style: TextStyle(
                      color: _tanggalDipilih != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),

              if (_tanggalDipilih != null &&
                  bookingProvider.terBooking(_tanggalDipilih!))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anda sudah memiliki jadwal pada tanggal ini. Booking baru akan ditambahkan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              TextFormField(
                controller: _tempatController,
                decoration: InputDecoration(
                  labelText: "Tempat yang Diinginkan",
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan tempat';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ||
                          _selectedProducts.isEmpty ||
                          _namaPemesan.isEmpty
                      ? null
                      : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text("Memproses..."),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send),
                            const SizedBox(width: 8),
                            Text("Pesan ${_selectedProducts.length} Produk"),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Method untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _tanggalDipilih ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF8B4513)!,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != _tanggalDipilih && mounted) {
        setState(() {
          _tanggalDipilih = picked;
        });
      }
    } catch (e) {
      debugPrint('Error selecting date: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka pemilih tanggal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method untuk submit form dengan error handling yang lebih baik
  Future<void> _submitForm() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalDipilih == null) {
      _showErrorSnackBar('Pilih tanggal terlebih dahulu');
      return;
    }

    if (_selectedProducts.isEmpty) {
      _showErrorSnackBar('Pilih minimal satu produk');
      return;
    }

    if (_namaPemesan.isEmpty) {
      _showErrorSnackBar('Data nama pemesan tidak tersedia');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Hitung total harga untuk produk yang dipilih
      final totalHarga = _selectedProducts.fold<int>(
        0,
        (sum, product) => sum + product.harga,
      );

      // Tampilkan dialog konfirmasi terlebih dahulu
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => BookingConfirmationDialog(
          products: _selectedProducts,
          namaPemesan: _namaPemesan, // Gunakan nama dari Firestore
          tema: _temaController.text, // Gunakan nama dari Firestore
          tempat: _tempatController.text.trim(),
          tanggal: _tanggalDipilih!,
          totalHarga: totalHarga, // Pass total harga ke dialog
        ),
      );

      if (!mounted) return;

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Proses booking
      final bookingProvider = context.read<BookingProvider>();

      final success = await bookingProvider.addBulkBooking(
        produkIds: _selectedProducts.map((p) => p.id).toList(),
        namaPemesan: _namaPemesan, // Gunakan nama dari Firestore
        tempat: _tempatController.text.trim(),
        tanggal: _tanggalDipilih!,
        totalHarga: totalHarga, // Pass total harga ke provider
        tema: _temaController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessSnackBar(
            'Berhasil memesan ${_selectedProducts.length} produk favorit!');
        Navigator.of(context).pop(true);
      } else {
        final errorMessage = bookingProvider.error.isNotEmpty
            ? bookingProvider.error
            : 'Gagal melakukan pemesanan';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      debugPrint('Error in _submitForm: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  // Helper methods untuk menampilkan snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _tempatController.dispose();
    _temaController.dispose(); // DITAMBAHKAN

    super.dispose();
  }
}
