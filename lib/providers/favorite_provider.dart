import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _favoriteProductIds = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<String> get favoriteProductIds => _favoriteProductIds;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  FavoriteProvider() {
    _initializeFavorites();
  }

  int getTotalFavoritePrice(List<dynamic> products) {
    int total = 0;
    for (var product in products) {
      if (_favoriteProductIds.contains(product.id)) {
        total += product.harga as int;
      }
    }
    return total;
  }

  // Method untuk mendapatkan jumlah produk favorit
  int get favoriteCount => _favoriteProductIds.length;

  // Method untuk cek apakah ada produk favorit
  bool get hasFavorites => _favoriteProductIds.isNotEmpty;

  // Method untuk inisialisasi awal
  Future<void> _initializeFavorites() async {
    final user = _auth.currentUser;
    if (user != null) {
      await loadFavorites();
    }
    // Listen untuk perubahan auth state
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadFavorites();
      } else {
        // Bersihkan favorites jika user logout
        _favoriteProductIds.clear();
        _isInitialized = false;
        notifyListeners();
      }
    });
  }

  Future<void> loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) {
      _favoriteProductIds.clear();
      _isInitialized = true;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();
      _favoriteProductIds = snapshot.docs.map((doc) => doc.id).toList();
      _isInitialized = true;
      debugPrint("Loaded ${_favoriteProductIds.length} favorites");
    } catch (e) {
      debugPrint("Failed to load favorites: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String produkId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final favRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(produkId);
    try {
      if (_favoriteProductIds.contains(produkId)) {
        await favRef.delete();
        _favoriteProductIds.remove(produkId);
        debugPrint("Removed from favorites: $produkId");
      } else {
        await favRef.set({'timestamp': FieldValue.serverTimestamp()});
        _favoriteProductIds.add(produkId);
        debugPrint("Added to favorites: $produkId");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to toggle favorite: $e");
    }
  }

  // Method untuk menambah multiple favorites sekaligus
  Future<bool> addMultipleFavorites(List<String> produkIds) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final batch = _firestore.batch();
      for (String produkId in produkIds) {
        if (!_favoriteProductIds.contains(produkId)) {
          final favRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc(produkId);

          batch.set(favRef, {'timestamp': FieldValue.serverTimestamp()});
          _favoriteProductIds.add(produkId);
        }
      }
      await batch.commit();
      notifyListeners();
      debugPrint("Added ${produkIds.length} items to favorites");
      return true;
    } catch (e) {
      debugPrint("Failed to add multiple favorites: $e");
      return false;
    }
  }

  // Method untuk menghapus multiple favorites sekaligus
  Future<bool> removeMultipleFavorites(List<String> produkIds) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final batch = _firestore.batch();
      for (String produkId in produkIds) {
        if (_favoriteProductIds.contains(produkId)) {
          final favRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc(produkId);
          batch.delete(favRef);
          _favoriteProductIds.remove(produkId);
        }
      }
      await batch.commit();
      notifyListeners();
      debugPrint("Removed ${produkIds.length} items from favorites");
      return true;
    } catch (e) {
      debugPrint("Failed to remove multiple favorites: $e");
      return false;
    }
  }

  // Method untuk clear semua favorites
  Future<bool> clearAllFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _favoriteProductIds.clear();
      notifyListeners();
      debugPrint("Cleared all favorites");
      return true;
    } catch (e) {
      debugPrint("Failed to clear favorites: $e");
      return false;
    }
  }

  bool isFavorite(String produkId) {
    return _favoriteProductIds.contains(produkId);
  }

  // Method untuk refresh data secara manual
  Future<void> refreshFavorites() async {
    await loadFavorites();
  }

  // Method untuk mendapatkan favorites dengan detail produk
  List<T> getFavoriteProducts<T>(
      List<T> allProducts, String Function(T) getId) {
    return allProducts.where((product) {
      return _favoriteProductIds.contains(getId(product));
    }).toList();
  }
}
