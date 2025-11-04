import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingProduct {
  final String produkId;

  BookingProduct({
    required this.produkId,
  });

  factory BookingProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingProduct(
      produkId: data['produkId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'produkId': produkId,
    };
  }
}

class Booking {
  final String id;
  final String namaPemesan;
  final String tempat;
  final String tema;
  final DateTime tanggal;
  final DateTime createdAt;
  final String status;
  final int totalHarga;
  final List<BookingProduct> products;

  Booking({
    required this.id,
    required this.namaPemesan,
    required this.tempat,
    required this.tema,
    required this.tanggal,
    required this.createdAt,
    this.status = 'pending',
    this.totalHarga = 0,
    this.products = const [],
  });

  factory Booking.fromFirestore(DocumentSnapshot doc,
      {List<BookingProduct> products = const []}) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      namaPemesan: data['namaPemesan'] ?? '',
      tempat: data['tempat'] ?? '',
      tema: data['tema'] ?? '', // DITAMBAHKAN
      tanggal: (data['tanggal'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      totalHarga: data['totalHarga'] ?? 0,
      products: products,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'namaPemesan': namaPemesan,
      'tempat': tempat,
      'tema': tema,
      'tanggal': Timestamp.fromDate(tanggal),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'totalHarga': totalHarga,
    };
  }

  int get totalProducts => products.length;
}

class BookingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Booking> _userBookings = [];
  List<DateTime> _bookedDates = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Booking> get userBookings => _userBookings;
  List<DateTime> get bookedDates => _bookedDates;
  bool get isLoading => _isLoading;
  String get error => _error;

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

  Future<void> loadUserBookings() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setLoading(true);
    setError('');
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .get();
      List<Booking> bookings = [];
      for (final doc in snapshot.docs) {
        final productsSnapshot = await _firestore
            .collection('bookings')
            .doc(doc.id)
            .collection('products')
            .get();
        final products = productsSnapshot.docs
            .map((productDoc) => BookingProduct.fromFirestore(productDoc))
            .toList();
        final booking = Booking.fromFirestore(doc, products: products);
        bookings.add(booking);
      }
      _userBookings = bookings;
      _userBookings.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      _bookedDates = _userBookings
          .map((booking) => DateTime(
                booking.tanggal.year,
                booking.tanggal.month,
                booking.tanggal.day,
              ))
          .toSet()
          .toList();
      setLoading(false);
    } catch (e) {
      setError('Failed to load bookings: $e');
      setLoading(false);
      print('Error loading bookings: $e');
    }
  }

  Future<bool> addBulkBooking({
    required List<String> produkIds,
    required String namaPemesan,
    required String tempat,
    required String tema, // DITAMBAHKAN
    required DateTime tanggal,
    required int totalHarga,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final booking = Booking(
        id: '',
        namaPemesan: namaPemesan,
        tempat: tempat,
        tema: tema,
        tanggal: tanggal,
        createdAt: DateTime.now(),
        totalHarga: totalHarga,
      );
      final docRef = await _firestore.collection('bookings').add({
        ...booking.toFirestore(),
        'userId': user.uid,
      });
      final batch = _firestore.batch();
      for (String produkId in produkIds) {
        final productRef = _firestore
            .collection('bookings')
            .doc(docRef.id)
            .collection('products')
            .doc();
        final bookingProduct = BookingProduct(
          produkId: produkId,
        );
        batch.set(productRef, bookingProduct.toFirestore());
      }
      await batch.commit();
      final localProducts = produkIds
          .map((produkId) => BookingProduct(produkId: produkId))
          .toList();
      final newBooking = Booking(
        id: docRef.id,
        namaPemesan: namaPemesan,
        tempat: tempat,
        tema: tema,
        tanggal: tanggal,
        createdAt: DateTime.now(),
        totalHarga: totalHarga,
        products: localProducts,
      );
      _userBookings.insert(0, newBooking);
      final dateOnly = DateTime(tanggal.year, tanggal.month, tanggal.day);
      if (!_bookedDates.contains(dateOnly)) {
        _bookedDates.add(dateOnly);
      }
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to add bulk booking: $e');
      print('Error adding bulk booking: $e');
      return false;
    }
  }

  Future<bool> addBooking({
    required String produkId,
    required String produkNama,
    required String namaPemesan,
    required String tempat,
    required String tema,
    required DateTime tanggal,
    int totalHarga = 0,
  }) async {
    return await addBulkBooking(
      produkIds: [produkId],
      namaPemesan: namaPemesan,
      tempat: tempat,
      tema: tema,
      tanggal: tanggal,
      totalHarga: totalHarga,
    );
  }

  // Future<bool> addProductToBooking(String bookingId, String produkId) async {
  //   try {
  //     final productRef = _firestore
  //         .collection('bookings')
  //         .doc(bookingId)
  //         .collection('products')
  //         .doc();
  //     final bookingProduct = BookingProduct(
  //       produkId: produkId,
  //     );
  //     await productRef.set(bookingProduct.toFirestore());
  //     final bookingIndex = _userBookings.indexWhere((b) => b.id == bookingId);
  //     if (bookingIndex != -1) {
  //       final updatedProducts =
  //           List<BookingProduct>.from(_userBookings[bookingIndex].products);
  //       updatedProducts.add(bookingProduct);
  //       _userBookings[bookingIndex] = Booking(
  //         id: _userBookings[bookingIndex].id,
  //         namaPemesan: _userBookings[bookingIndex].namaPemesan,
  //         tempat: _userBookings[bookingIndex].tempat,
  //         tanggal: _userBookings[bookingIndex].tanggal,
  //         createdAt: _userBookings[bookingIndex].createdAt,
  //         status: _userBookings[bookingIndex].status,
  //         totalHarga:
  //             _userBookings[bookingIndex].totalHarga,
  //         products: updatedProducts, tema: '',
  //       );
  //     }

  //     notifyListeners();
  //     return true;
  //   } catch (e) {
  //     setError('Failed to add product to booking: $e');
  //     print('Error adding product to booking: $e');
  //     return false;
  //   }
  // }

  // Future<bool> removeProductFromBooking(
  //     String bookingId, String produkId) async {
  //   try {
  //     final productsSnapshot = await _firestore
  //         .collection('bookings')
  //         .doc(bookingId)
  //         .collection('products')
  //         .where('produkId', isEqualTo: produkId)
  //         .limit(1)
  //         .get();
  //     if (productsSnapshot.docs.isNotEmpty) {
  //       await productsSnapshot.docs.first.reference.delete();
  //       final bookingIndex = _userBookings.indexWhere((b) => b.id == bookingId);
  //       if (bookingIndex != -1) {
  //         final updatedProducts = _userBookings[bookingIndex]
  //             .products
  //             .where((p) => p.produkId != produkId)
  //             .toList();
  //         _userBookings[bookingIndex] = Booking(
  //           id: _userBookings[bookingIndex].id,
  //           namaPemesan: _userBookings[bookingIndex].namaPemesan,
  //           tempat: _userBookings[bookingIndex].tempat,
  //           tanggal: _userBookings[bookingIndex].tanggal,
  //           createdAt: _userBookings[bookingIndex].createdAt,
  //           status: _userBookings[bookingIndex].status,
  //           totalHarga:
  //               _userBookings[bookingIndex].totalHarga, // Preserve total price
  //           products: updatedProducts,
  //           tema: '', // test yak
  //         );
  //       }

  //       notifyListeners();
  //     }

  //     return true;
  //   } catch (e) {
  //     setError('Failed to remove product from booking: $e');
  //     print('Error removing product from booking: $e');
  //     return false;
  //   }
  // }

  Future<bool> deleteBooking(String bookingId) async {
    try {
      // Delete all products in subcollection first
      final productsSnapshot = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .collection('products')
          .get();
      final batch = _firestore.batch();
      for (final doc in productsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('bookings').doc(bookingId));
      await batch.commit();
      final booking = _userBookings.firstWhere((b) => b.id == bookingId);
      _userBookings.removeWhere((b) => b.id == bookingId);
      final dateOnly = DateTime(
          booking.tanggal.year, booking.tanggal.month, booking.tanggal.day);
      final hasOtherBookingOnSameDate = _userBookings.any((b) =>
          DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day) == dateOnly);
      if (!hasOtherBookingOnSameDate) {
        _bookedDates.remove(dateOnly);
      }
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to delete booking: $e');
      print('Error deleting booking: $e');
      return false;
    }
  }

  Future<List<BookingProduct>> getBookingProducts(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .collection('products')
          .get();
      return snapshot.docs
          .map((doc) => BookingProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting booking products: $e');
      return [];
    }
  }

  Future<String?> getSnapToken(String orderId, int grossAmount) async {
    final url = Uri.parse('http://YOUR_SERVER_URL:5000/get-snap-token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'order_id': orderId,
        'gross_amount': grossAmount,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['snap_token'];
    } else {
      print('Failed to get snap token: ${response.body}');
      return null;
    }
  }

  bool terBooking(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _bookedDates.contains(dateOnly);
  }

  List<Booking> getTglBooking(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _userBookings.where((booking) {
      final bookingDate = DateTime(
        booking.tanggal.year,
        booking.tanggal.month,
        booking.tanggal.day,
      );
      return bookingDate == dateOnly;
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refresh bookings
  Future<void> refreshBookings() async {
    await loadUserBookings();
  }
}
