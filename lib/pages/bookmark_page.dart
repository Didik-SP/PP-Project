import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
// import 'jadwal_form_page.dart';
import 'bulk_booking_page.dart'; // Import halaman baru
import '../providers/product_provider.dart';
import '../providers/favorite_provider.dart';
import 'detail_produk.dart';
import 'widget/button.dart';
import 'widget/backgroun.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final Map<String, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favoriteProvider =
          Provider.of<FavoriteProvider>(context, listen: false);
      if (!favoriteProvider.isInitialized) {
        favoriteProvider.loadFavorites();
      }
    });
  }

  Uint8List? _decodeBase64(String base64String) {
    if (_imageCache.containsKey(base64String)) {
      return _imageCache[base64String];
    }

    try {
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      final decoded = base64Decode(cleanBase64);
      _imageCache[base64String] = decoded;
      return decoded;
    } catch (e) {
      print('Error decoding base64: $e');
      _imageCache[base64String] = null;
      return null;
    }
  }

  // Widget helper untuk menampilkan gambar base64
  Widget _buildBase64Image(String base64String,
      {double? width, double? height}) {
    if (base64String.isEmpty) {
      return Container(
        width: width ?? 60,
        height: height ?? 60,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 24,
        ),
      );
    }

    final Uint8List? imageBytes = _decodeBase64(base64String);

    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        width: width ?? 60,
        height: height ?? 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width ?? 60,
            height: height ?? 60,
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              color: Colors.grey[400],
              size: 24,
            ),
          );
        },
      );
    } else {
      return Container(
        width: width ?? 60,
        height: height ?? 60,
        color: Colors.grey[200],
        child: Icon(
          Icons.error_outline,
          color: Colors.grey[400],
          size: 24,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Ditandai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _imageCache.clear();
              Provider.of<FavoriteProvider>(context, listen: false)
                  .refreshFavorites();
            },
          ),
        ],
      ),
      body: Consumer2<ProductProvider, FavoriteProvider>(
        builder: (context, productProvider, favoriteProvider, child) {
          // Show loading indicator
          if (favoriteProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat produk ditandai...'),
                ],
              ),
            );
          }

          final favoriteProducts = productProvider.products.where((product) {
            return favoriteProvider.favoriteProductIds.contains(product.id);
          }).toList();

          if (favoriteProducts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada produk ditandai.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tambahkan produk ke ditandai untuk melihatnya di sini.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header dengan jumlah favorit dan tombol pesan semua
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${favoriteProducts.length} produk ditandai',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        // Tombol untuk melihat total harga (opsional)
                        if (favoriteProducts.isNotEmpty)
                          Text(
                            'Total: Rp${NumberFormat('#,###', 'id_ID').format(favoriteProducts.fold<int>(0, (sum, product) => sum + product.harga))}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tombol Pesan Semua Favorit
                    GradientButton(
                      text: 'Pesan Semua Favorit (${favoriteProducts.length})',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BulkBookingPage(
                              favoriteProducts: favoriteProducts,
                            ),
                          ),
                        );
                      },
                    ),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton.icon(
                    //     onPressed: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (context) => BulkBookingPage(
                    //             favoriteProducts: favoriteProducts,
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //     icon: const Icon(Icons.shopping_cart),
                    //     label: Text(
                    //         'Pesan Semua Favorit (${favoriteProducts.length})'),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.green[600],
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(vertical: 12),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              // Divider
              Divider(
                height: 1,
                color: Colors.grey[300],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: favoriteProducts.length,
                  itemBuilder: (context, index) {
                    final product = favoriteProducts[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<List<String>>(
                                future: productProvider
                                    .getProductImages(product.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError ||
                                      !snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  }

                                  // Ambil gambar pertama dari list
                                  final firstImage = snapshot.data!.first;
                                  return _buildBase64Image(firstImage,
                                      width: 60, height: 60);
                                },
                              ),
                            ),
                            title: Text(product.nama),
                            subtitle: Text(
                                'Rp${NumberFormat('#,###', 'id_ID').format(product.harga)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tombol hapus dari favorit
                                IconButton(
                                  icon: const Icon(Icons.bookmark,
                                      color: Colors.red),
                                  onPressed: () {
                                    favoriteProvider.toggleFavorite(product.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${product.nama} dihapus dari favorit'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailProduk(
                                    produkId: product.id,
                                    nama: product.nama,
                                    harga: product.harga,
                                    deskripsi: product.deskripsi,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Tombol individual untuk pesan produk ini saja
                          // Padding(
                          //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          //   child: Row(
                          //     children: [
                          //       // Tombol pesan individual
                          //       Expanded(
                          //         child: OutlinedButton.icon(
                          //           onPressed: () {
                          //             Navigator.push(
                          //               context,
                          //               MaterialPageRoute(
                          //                 builder: (context) =>
                          //                     JadwalFormPage(
                          //                   produkId: product.id,
                          //                 ),
                          //               ),
                          //             );
                          //           },
                          //           icon: const Icon(Icons.calendar_today),
                          //           label: const Text("Pesan"),
                          //           style: OutlinedButton.styleFrom(
                          //             foregroundColor: Colors.blue[600],
                          //             side: BorderSide(
                          //                 color: Colors.blue[600]!),
                          //           ),
                          //         ),
                          //       ),
                          //       const SizedBox(width: 8),
                          //       Expanded(
                          //         child: OutlinedButton.icon(
                          //           onPressed: () {
                          //             favoriteProvider
                          //                 .toggleFavorite(product.id);
                          //             ScaffoldMessenger.of(context)
                          //                 .showSnackBar(
                          //               SnackBar(
                          //                 content: Text(
                          //                     '${product.nama} dihapus dari favorit'),
                          //                 duration:
                          //                     const Duration(seconds: 2),
                          //               ),
                          //             );
                          //           },
                          //           icon: const Icon(
                          //             Icons.bookmark,
                          //           ),
                          //           label: const Text("Batal"),
                          //           style: OutlinedButton.styleFrom(
                          //             foregroundColor: Colors.red[600],
                          //             side:
                          //                 BorderSide(color: Colors.red[600]!),
                          //           ),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
