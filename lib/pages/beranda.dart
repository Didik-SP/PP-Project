// beranda.dart - Updated with Filter Categories
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'detail_produk.dart';
import '../providers/product_provider.dart';

class BerandaContent extends StatefulWidget {
  @override
  _BerandaContentState createState() => _BerandaContentState();
}

class _BerandaContentState extends State<BerandaContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua'; // Default selected category

  // Daftar kategori filter
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': '🏷️'},
    {'name': 'Perlengkapan', 'icon': '🌸'},
    {'name': 'Jasa', 'icon': '💄'},
  ];

  @override
  void initState() {
    super.initState();

    // Load products when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });

    // Add listener to search controller
    _searchController.addListener(() {
      context.read<ProductProvider>().updateSearchText(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method untuk handle filter kategori
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    // TODO: Implement actual filtering logic in ProductProvider
    // context.read<ProductProvider>().filterByCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchBar(),
                const SizedBox(height: 16),
                // _filterCategories(), // Kategori filter baru
                // const SizedBox(height: 24),
                // _kategoriBar(),
                // const SizedBox(height: 24),
                _semuaProdukBar(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari layanan pernikahan',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFF8B4513),
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  // Widget baru untuk kategori filter
  Widget _filterCategories() {
    return Container(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];

          return Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category['name']),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF8B4513) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color:
                        isSelected ? Color(0xFF8B4513) : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['icon'],
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 6),
                    Text(
                      category['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _kategoriBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kategori Layanan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all categories
              },
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _buildCategoryItem(
              '🌸',
              'Perlengkapan',
              Color(0xFF8B4513).withOpacity(0.1),
              Color(0xFF8B4513),
            ),
            SizedBox(width: 12),
            _buildCategoryItem(
              '💄',
              'Jasa',
              Colors.pink.shade50,
              Colors.pink.shade700,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
      String icon, String title, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: textColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 32),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk menampilkan gambar base64
  Widget _buildProductImage(String base64String, ProductProvider provider) {
    if (base64String.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            size: 32,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    try {
      final Uint8List? imageBytes = provider.getImageBytes(base64String);

      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gambar tidak\ndapat dimuat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  size: 32,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 4),
                Text(
                  'Format gambar\ntidak valid',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
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
                size: 32,
                color: Colors.grey[400],
              ),
              SizedBox(height: 4),
              Text(
                'Error memuat\ngambar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _semuaProdukBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produk Layanan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) {
              return Container(
                height: 200,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                  ),
                ),
              );
            }

            if (productProvider.error.isNotEmpty) {
              return Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Terjadi Kesalahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      productProvider.error,
                      style: TextStyle(
                        color: Colors.red.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (productProvider.filteredProducts.isEmpty) {
              return Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      color: Colors.grey.shade400,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Tidak ada layanan ditemukan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Coba kata kunci yang berbeda',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: productProvider.filteredProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final product = productProvider.filteredProducts[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            DetailProduk(
                          nama: product.nama,
                          harga: product.harga,
                          deskripsi: product.deskripsi,
                          produkId: product.id,
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: animation.drive(
                              Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                                  .chain(CurveTween(curve: Curves.easeInOut)),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image - Updated untuk base64
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: _buildProductImage(
                              product.firstImageUrl,
                              productProvider,
                            ),
                          ),
                        ),
                        // Product Info
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.nama,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF8B4513).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_offer_rounded,
                                        size: 12,
                                        color: Color(0xFF8B4513),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Rp${NumberFormat('#,###', 'id_ID').format(product.harga)}',
                                        style: TextStyle(
                                          fontSize: 12,
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
