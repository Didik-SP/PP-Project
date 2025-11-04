// detail_produk.dart - Updated for Base64 Images with Image.memory
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'fullviewimage.dart';
import '../providers/favorite_provider.dart';
import '../providers/product_provider.dart';
import 'widget/backgroun.dart';

class DetailProduk extends StatefulWidget {
  final String nama;
  final int harga;
  final String deskripsi;
  final String produkId;

  const DetailProduk({
    Key? key,
    required this.nama,
    required this.harga,
    required this.deskripsi,
    required this.produkId,
  }) : super(key: key);

  @override
  State<DetailProduk> createState() => _DetailProdukState();
}

class _DetailProdukState extends State<DetailProduk> {
  int currentImageIndex = 0;
  List<String>? _cachedImages; // Cache gambar untuk menghindari rebuild
  bool _isLoadingImages = true;
  bool _hasImageError = false;
  final String whatsappLink = "https://wa.link/whos7w";

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

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
    }
  }

  // Load images sekali saja saat initState
  Future<void> _loadImages() async {
    try {
      final productProvider = context.read<ProductProvider>();
      final images = await productProvider.getProductImages(widget.produkId);

      if (mounted) {
        setState(() {
          _cachedImages = images;
          _isLoadingImages = false;
          _hasImageError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
          _hasImageError = true;
        });
      }
    }
  }

  // Helper function to decode base64 string to Uint8List
  Uint8List? _decodeBase64(String base64String) {
    try {
      // Remove data:image/jpeg;base64, prefix if exists
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      return base64Decode(cleanBase64);
    } catch (e) {
      print('Error decoding base64: $e');
      return null;
    }
  }

  // Widget helper untuk menampilkan gambar base64
  Widget _buildBase64Image(String base64String, {BoxFit fit = BoxFit.cover}) {
    if (base64String.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada gambar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final Uint8List? imageBytes = _decodeBase64(base64String);

      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gambar tidak dapat dimuat',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Format gambar tidak valid',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Error memuat gambar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar dengan efek parallax
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(),
            ),
          ),

          // Content Area
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Product Name
                    Text(
                      widget.nama,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price with highlight
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF8B4513).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF8B4513).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer_rounded,
                            color: Color(0xFF8B4513),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(widget.harga)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description_rounded,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Deskripsi Layanan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.deskripsi,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Consumer<FavoriteProvider>(
                            builder: (context, favProvider, child) {
                              final isFav =
                                  favProvider.isFavorite(widget.produkId);
                              return ElevatedButton(
                                onPressed: () {
                                  favProvider.toggleFavorite(widget.produkId);

                                  // Haptic feedback
                                  HapticFeedback.lightImpact();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isFav
                                            ? 'Dihapus dari favorit'
                                            : 'Ditambahkan ke favorit',
                                      ),
                                      backgroundColor:
                                          isFav ? Colors.red : Colors.green,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFav
                                      ? Colors.red.shade50
                                      : Color(0xFF8B4513).withOpacity(0.1),
                                  foregroundColor: isFav
                                      ? Colors.red.shade700
                                      : Color(0xFF8B4513),
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isFav
                                          ? Colors.red.shade200
                                          : Color(0xFF8B4513).withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isFav
                                          ? Icons.bookmark
                                          : Icons.bookmark_rounded,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isFav ? 'Favorit' : 'Suka',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () {
                              _openWhatsApp();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF8B4513),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.message_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Hubungi Kami',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    // Gunakan cached images, bukan FutureBuilder yang rebuild terus
    if (_isLoadingImages) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
          ),
        ),
      );
    }

    if (_hasImageError) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat gambar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingImages = true;
                    _hasImageError = false;
                  });
                  _loadImages();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final gambarList = _cachedImages ?? [];

    if (gambarList.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada gambar tersedia',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // PageView untuk swipe gambar base64
        PageView.builder(
          itemCount: gambarList.length,
          onPageChanged: (index) {
            // Haptic feedback saat swipe
            HapticFeedback.selectionClick();

            // Hanya update currentImageIndex, tidak rebuild seluruh widget
            setState(() {
              currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // Haptic feedback saat tap
                HapticFeedback.mediumImpact();

                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FullScreenGalleryPage(
                      imageDataList: gambarList,
                      initialIndex: index,
                      isBase64: true, // Menandakan ini adalah base64
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Hero(
                tag: 'product_image_${widget.produkId}_$index',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  child: _buildBase64Image(
                    gambarList[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),

        // Image indicators (dots)
        if (gambarList.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: gambarList.asMap().entries.map((entry) {
                final isActive = currentImageIndex == entry.key;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: isActive ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // Image counter
        if (gambarList.length > 1)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${currentImageIndex + 1}/${gambarList.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
