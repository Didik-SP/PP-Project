// providers/product_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../models/produk.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _error = '';
  String _searchText = '';

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchText => _searchText;

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Update search text and filter products
  void updateSearchText(String searchText) {
    _searchText = searchText.toLowerCase();
    _filterProducts();
    notifyListeners();
  }

  // Filter products based on search text
  void _filterProducts() {
    if (_searchText.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products.where((product) {
        return product.nama.toLowerCase().contains(_searchText);
      }).toList();
    }
  }

  // Helper function to decode base64 string to Uint8List
  Uint8List? _decodeBase64(String base64String) {
    try {
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

  // Helper function to check if string is base64
  bool _isBase64(String value) {
    if (value.isEmpty) return false;
    if (value.startsWith('data:image/') && value.contains('base64,')) {
      return true;
    }
    try {
      String cleanValue = value;
      if (value.contains(',')) {
        cleanValue = value.split(',').last;
      }
      base64Decode(cleanValue);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Load products from Firestore with base64 images
  void loadProducts() async {
    setLoading(true);
    setError('');
    try {
      _firestore.collection('produk').snapshots().listen(
        (snapshot) async {
          List<Product> loadedProducts = [];
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final nama = data['nama'] ?? 'Tanpa Nama';
            final harga = data['harga'] is int ? data['harga'] as int : 0;
            final deskripsi = data['deskripsi'] ?? '-';
            String firstImageUrl = '';
            try {
              final imageSnapshot = await _firestore
                  .collection('produk')
                  .doc(doc.id)
                  .collection('gambar')
                  .limit(1)
                  .get();
              if (imageSnapshot.docs.isNotEmpty) {
                final imageData = imageSnapshot.docs.first.data();
                for (var value in imageData.values) {
                  if (value is String && _isBase64(value)) {
                    firstImageUrl = value;
                    break;
                  }
                }
              }
            } catch (e) {
              print('Error getting image for ${doc.id}: $e');
            }
            loadedProducts.add(Product(
              id: doc.id,
              nama: nama,
              harga: harga,
              deskripsi: deskripsi,
              firstImageUrl: firstImageUrl,
            ));
          }
          _products = loadedProducts;
          _filterProducts();
          setLoading(false);
        },
        onError: (error) {
          setError('Error: $error');
          setLoading(false);
        },
      );
    } catch (e) {
      setError('Error: $e');
      setLoading(false);
    }
  }

  // Get product images (base64)
  Future<List<String>> getProductImages(String produkId) async {
    try {
      final snapshot = await _firestore
          .collection('produk')
          .doc(produkId)
          .collection('gambar')
          .get();
      List<String> gambarList = [];
      for (var doc in snapshot.docs) {
        doc.data().forEach((key, value) {
          if (value is String && _isBase64(value)) {
            gambarList.add(value);
          }
        });
      }
      return gambarList;
    } catch (e) {
      throw Exception('Failed to load images: $e');
    }
  }

  // Get first image of a product
  Future<String> getFirstProductImage(String produkId) async {
    try {
      final images = await getProductImages(produkId);
      return images.isNotEmpty ? images.first : '';
    } catch (e) {
      return '';
    }
  }

  // Convert base64 string to Uint8List for Image.memory
  Uint8List? getImageBytes(String base64String) {
    return _decodeBase64(base64String);
  }
}
