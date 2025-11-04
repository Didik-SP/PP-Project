import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/produk.dart';

class BookingConfirmationDialog extends StatelessWidget {
  final List<Product> products;
  final String namaPemesan;
  final String tema;
  final String tempat;
  final DateTime tanggal;
  final int totalHarga;

  const BookingConfirmationDialog({
    super.key,
    required this.products,
    required this.namaPemesan,
    required this.tema,
    required this.tempat,
    required this.tanggal,
    required this.totalHarga,
  });

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

  // Widget helper untuk menampilkan gambar base64
  Widget _buildBase64Image(String base64String,
      {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (base64String.isEmpty) {
      return _buildImagePlaceholder(width, height, Icons.image_not_supported);
    }

    try {
      final Uint8List? imageBytes = _decodeBase64(base64String);

      if (imageBytes != null && imageBytes.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            imageBytes,
            width: width,
            height: height,
            fit: fit,
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 18,
        color: Colors.grey[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Konfirmasi Pemesanan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Periksa kembali detail pemesanan Anda',
                        style: TextStyle(
                          color: Colors.blue[100],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Detail pemesanan
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detail Pemesanan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.person,
                                'Nama Pemesan',
                                namaPemesan,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.style,
                                'Tema',
                                tema,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.location_on,
                                'Tempat',
                                tempat,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Tanggal',
                                DateFormat('dd MMMM yyyy').format(tanggal),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Daftar produk
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Produk yang Dipesan (${products.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Daftar produk
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Product image
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: product.firstImageUrl.isNotEmpty
                                          ? _buildBase64Image(
                                              product.firstImageUrl,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              Icons.image_not_supported_rounded,
                                              size: 18,
                                              color: Colors.grey[400],
                                            ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Product info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.nama,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Rp${NumberFormat('#,###').format(product.harga)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Total harga
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Estimasi:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Rp${NumberFormat('#,###').format(totalHarga)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Warning message
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.orange[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pastikan semua informasi sudah benar sebelum melanjutkan. Pemesanan tidak dapat dibatalkan.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Konfirmasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper widget untuk info row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
