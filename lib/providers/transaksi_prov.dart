import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/transaksiMod.dart';

class TransaksiProv with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Transaksi> _listTransaksi = [];
  bool _isLoading = false;
  String _error = '';

  List<Transaksi> get listTransaksi => _listTransaksi;
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

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Create new transaksi
  Future<bool> createTransaksi({
    required String bookingId,
    required String userId,
    required double hargaDP,
    required double hargaTotal,
    required String tanggalBooking,
    required String tempat,
    required String namaLengkap,
    String statusPembayaran = 'pending',
  }) async {
    try {
      setLoading(true);
      clearError();

      print('Creating transaksi with data:');
      print('BookingId: $bookingId');
      print('UserId: $userId');
      print('HargaDP: $hargaDP');
      print('HargaTotal: $hargaTotal');

      // Data transaksi yang akan disimpan
      final transaksiData = {
        'bookingId': bookingId,
        'userId': userId,
        'statusPembayaran': statusPembayaran,
        'hargaDP': hargaDP,
        'hargaTotal': hargaTotal,
        'tanggalBooking': tanggalBooking,
        'tempat': tempat,
        'namaLengkap': namaLengkap,
        'createdAt': FieldValue.serverTimestamp(),
      };
      print('Saving transaksi data: $transaksiData');
      final docRef =
          await _firestore.collection('transaksi').add(transaksiData);
      print('Transaksi saved successfully with ID: ${docRef.id}');
      await Future.delayed(Duration(milliseconds: 500));
      await getAllTransaksi();
      setLoading(false);
      return true;
    } catch (e) {
      setError('Gagal menyimpan transaksi: $e');
      setLoading(false);
      print('Error creating transaksi: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<void> getAllTransaksi() async {
    try {
      setLoading(true);
      clearError();
      print('Fetching transaksi from Firestore...');
      final querySnapshot = await _firestore
          .collection('transaksi')
          .orderBy('createdAt', descending: true)
          .get();
      print('Found ${querySnapshot.docs.length} transaksi documents');
      final List<Transaksi> loadedTransaksi = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('Processing transaksi doc ${doc.id}: $data');
          if (data.containsKey('bookingId') &&
              data.containsKey('userId') &&
              data.containsKey('namaLengkap')) {
            final transaksi = Transaksi.fromFirestore(data, doc.id);
            loadedTransaksi.add(transaksi);
            print('Successfully created Transaksi object for ${doc.id}');
          } else {
            print(
                'Skipping invalid transaksi document ${doc.id}: missing required fields');
          }
        } catch (e) {
          print('Error processing transaksi document ${doc.id}: $e');
          continue;
        }
      }
      _listTransaksi = loadedTransaksi;
      print('Loaded ${_listTransaksi.length} transaksi successfully');
      setLoading(false);
      notifyListeners();
    } catch (e) {
      setError('Gagal memuat data transaksi: $e');
      setLoading(false);
      print('Error fetching transaksi: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Update status pembayaran - untuk mendukung status 'selesai'
  Future<bool> updateStatusPembayaran(
      String transaksiId, String newStatus) async {
    try {
      setLoading(true);
      clearError();
      print('Updating status pembayaran for $transaksiId to $newStatus');
      final allowedStatuses = ['pending', 'diproses', 'selesai', 'dibatalkan'];
      if (!allowedStatuses.contains(newStatus)) {
        setError('Status tidak valid: $newStatus');
        setLoading(false);
        return false;
      }
      await _firestore.collection('transaksi').doc(transaksiId).update({
        'statusPembayaran': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'selesai') 'completedAt': FieldValue.serverTimestamp(),
      });
      print('Status pembayaran updated successfully to $newStatus');
      final index = _listTransaksi.indexWhere((t) => t.id == transaksiId);
      if (index != -1) {
        final updatedTransaksi = Transaksi(
          id: _listTransaksi[index].id,
          bookingId: _listTransaksi[index].bookingId,
          userId: _listTransaksi[index].userId,
          statusPembayaran: newStatus,
          hargaDP: _listTransaksi[index].hargaDP,
          hargaTotal: _listTransaksi[index].hargaTotal,
          image: _listTransaksi[index].image,
          tanggalBooking: _listTransaksi[index].tanggalBooking,
          tempat: _listTransaksi[index].tempat,
          namaLengkap: _listTransaksi[index].namaLengkap,
          createdAt: _listTransaksi[index].createdAt,
        );
        _listTransaksi[index] = updatedTransaksi;
        notifyListeners();
      }
      setLoading(false);
      return true;
    } catch (e) {
      setError('Gagal mengupdate status pembayaran: $e');
      setLoading(false);
      print('Error updating status pembayaran: $e');
      return false;
    }
  }

  // Method khusus untuk menyelesaikan transaksi
  Future<bool> markTransaksiSelesai(String transaksiId) async {
    try {
      setLoading(true);
      clearError();
      print('Marking transaksi $transaksiId as selesai');
      await _firestore.collection('transaksi').doc(transaksiId).update({
        'statusPembayaran': 'selesai',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final index = _listTransaksi.indexWhere((t) => t.id == transaksiId);
      if (index != -1) {
        final updatedTransaksi = Transaksi(
          id: _listTransaksi[index].id,
          bookingId: _listTransaksi[index].bookingId,
          userId: _listTransaksi[index].userId,
          statusPembayaran: 'selesai',
          hargaDP: _listTransaksi[index].hargaDP,
          hargaTotal: _listTransaksi[index].hargaTotal,
          image: _listTransaksi[index].image,
          tanggalBooking: _listTransaksi[index].tanggalBooking,
          tempat: _listTransaksi[index].tempat,
          namaLengkap: _listTransaksi[index].namaLengkap,
          createdAt: _listTransaksi[index].createdAt,
        );
        _listTransaksi[index] = updatedTransaksi;
        notifyListeners();
      }
      setLoading(false);
      print('Transaksi marked as selesai successfully');
      return true;
    } catch (e) {
      setError('Gagal menyelesaikan transaksi: $e');
      setLoading(false);
      print('Error marking transaksi as selesai: $e');
      return false;
    }
  }

  // Method untuk test koneksi Firestore
  Future<bool> testFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');
      final testDoc = await _firestore.collection('test').add({
        'message': 'Test connection',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Test document created with ID: ${testDoc.id}');
      await testDoc.delete();
      print('Test document deleted');
      return true;
    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  // Get transaksi by booking ID
  Transaksi? getTransaksiByBookingId(String bookingId) {
    try {
      return _listTransaksi.firstWhere((t) => t.bookingId == bookingId);
    } catch (e) {
      print('No transaksi found for booking ID: $bookingId');
      return null;
    }
  }

  // Get transaksi by user ID
  List<Transaksi> getTransaksiByUserId(String userId) {
    return _listTransaksi.where((t) => t.userId == userId).toList();
  }

  // Get transaksi by status
  List<Transaksi> getTransaksiByStatus(String status) {
    return _listTransaksi.where((t) => t.statusPembayaran == status).toList();
  }

  // Delete transaksi
  Future<bool> deleteTransaksi(String transaksiId) async {
    try {
      setLoading(true);
      clearError();
      await _firestore.collection('transaksi').doc(transaksiId).delete();
      // Remove from local list
      _listTransaksi.removeWhere((t) => t.id == transaksiId);
      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      setError('Gagal menghapus transaksi: $e');
      setLoading(false);
      print('Error deleting transaksi: $e');
      return false;
    }
  }

  // Update transaksi data
  Future<bool> updateTransaksi({
    required String transaksiId,
    String? statusPembayaran,
    double? hargaDP,
    double? hargaTotal,
    String? tanggalBooking,
    String? tempat,
    String? namaLengkap,
  }) async {
    try {
      setLoading(true);
      clearError();
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (statusPembayaran != null) {
        updateData['statusPembayaran'] = statusPembayaran;
        // Tambahkan completedAt jika status menjadi selesai
        if (statusPembayaran == 'selesai') {
          updateData['completedAt'] = FieldValue.serverTimestamp();
        }
      }
      if (hargaDP != null) updateData['hargaDP'] = hargaDP;
      if (hargaTotal != null) updateData['hargaTotal'] = hargaTotal;
      if (tanggalBooking != null) updateData['tanggalBooking'] = tanggalBooking;
      if (tempat != null) updateData['tempat'] = tempat;
      if (namaLengkap != null) updateData['namaLengkap'] = namaLengkap;
      await _firestore
          .collection('transaksi')
          .doc(transaksiId)
          .update(updateData);
      await getAllTransaksi();
      setLoading(false);
      return true;
    } catch (e) {
      setError('Gagal mengupdate transaksi: $e');
      setLoading(false);
      print('Error updating transaksi: $e');
      return false;
    }
  }

  // Get total revenue - Updated untuk include status 'selesai'
  double getTotalRevenue() {
    return _listTransaksi
        .where((t) =>
            t.statusPembayaran == 'selesai' ||
            t.statusPembayaran == 'paid' ||
            t.statusPembayaran == 'completed')
        .fold(0.0, (sum, t) => sum + t.hargaTotal);
  }

  // Get total DP received
  double getTotalDP() {
    return _listTransaksi
        .where((t) => t.statusPembayaran != 'dibatalkan')
        .fold(0.0, (sum, t) => sum + t.hargaDP);
  }

  // Get pending transactions count
  int getPendingTransactionsCount() {
    return _listTransaksi.where((t) => t.statusPembayaran == 'pending').length;
  }

  // Get completed transactions count
  int getCompletedTransactionsCount() {
    return _listTransaksi.where((t) => t.statusPembayaran == 'selesai').length;
  }

  // Get transactions in progress count
  int getInProgressTransactionsCount() {
    return _listTransaksi.where((t) => t.statusPembayaran == 'diproses').length;
  }

  // Get cancelled transactions count
  int getCancelledTransactionsCount() {
    return _listTransaksi
        .where((t) => t.statusPembayaran == 'dibatalkan')
        .length;
  }

  // List<Transaksi> searchTransaksi(String query) {
  //   if (query.isEmpty) return _listTransaksi;

  //   final lowerQuery = query.toLowerCase();
  //   return _listTransaksi.where((transaksi) {
  //     return transaksi.namaLengkap.toLowerCase().contains(lowerQuery) ||
  //         transaksi.tempat.toLowerCase().contains(lowerQuery) ||
  //         transaksi.statusPembayaran.toLowerCase().contains(lowerQuery) ||
  //         transaksi.bookingId.toLowerCase().contains(lowerQuery);
  //   }).toList();
  // }

  // Get status summary
  Map<String, int> getStatusSummary() {
    final summary = <String, int>{
      'pending': 0,
      'diproses': 0,
      'selesai': 0,
      'dibatalkan': 0,
    };
    for (var transaksi in _listTransaksi) {
      summary[transaksi.statusPembayaran] =
          (summary[transaksi.statusPembayaran] ?? 0) + 1;
    }
    return summary;
  }

  // Refresh data
  Future<void> refreshTransaksi() async {
    await getAllTransaksi();
  }

  // Listen to real-time updates
  Stream<List<Transaksi>> getTransaksiStream() {
    return _firestore
        .collection('transaksi')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Transaksi.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Check if transaksi can be completed
  bool canCompleteTransaksi(Transaksi transaksi) {
    return transaksi.statusPembayaran != 'selesai' &&
        transaksi.statusPembayaran != 'dibatalkan';
  }

  // Get remaining payment amount
  double getRemainingPayment(Transaksi transaksi) {
    return transaksi.hargaTotal - transaksi.hargaDP;
  }

  // Bulk update status (untuk keperluan admin)
  Future<bool> bulkUpdateStatus(
      List<String> transaksiIds, String newStatus) async {
    try {
      setLoading(true);
      clearError();
      final batch = _firestore.batch();
      for (String id in transaksiIds) {
        final docRef = _firestore.collection('transaksi').doc(id);
        final updateData = {
          'statusPembayaran': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (newStatus == 'selesai') {
          updateData['completedAt'] = FieldValue.serverTimestamp();
        }
        batch.update(docRef, updateData);
      }
      await batch.commit();
      await getAllTransaksi();
      setLoading(false);
      return true;
    } catch (e) {
      setError('Gagal melakukan bulk update: $e');
      setLoading(false);
      print('Error in bulk update: $e');
      return false;
    }
  }
}
