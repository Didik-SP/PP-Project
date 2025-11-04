// transaksi - FIXED: image field changed from double to String for base64
import 'package:cloud_firestore/cloud_firestore.dart';

class Transaksi {
  final String id;
  final String bookingId;
  final String userId;
  final String statusPembayaran;
  final double hargaDP;
  final double hargaTotal;
  final String image; // Changed from double to String for base64
  final String tanggalBooking;
  final String tempat;
  final String namaLengkap;
  final DateTime createdAt;

  Transaksi({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.statusPembayaran,
    required this.hargaDP,
    required this.hargaTotal,
    required this.image,
    required this.tanggalBooking,
    required this.tempat,
    required this.namaLengkap,
    required this.createdAt,
  });

  factory Transaksi.fromFirestore(Map<String, dynamic> data, String docId) {
    return Transaksi(
      id: docId,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      statusPembayaran: data['statusPembayaran'] ?? '',
      hargaDP: (data['hargaDP'] ?? 0).toDouble(),
      hargaTotal: (data['hargaTotal'] ?? 0).toDouble(),
      image: data['image'] ?? '', // Now properly handles base64 string
      tanggalBooking: data['tanggalBooking'] ?? '',
      tempat: data['tempat'] ?? '',
      namaLengkap: data['namaLengkap'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'statusPembayaran': statusPembayaran,
      'hargaDP': hargaDP,
      'hargaTotal': hargaTotal,
      'image': image,
      'tanggalBooking': tanggalBooking,
      'tempat': tempat,
      'namaLengkap': namaLengkap,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Transaksi copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? statusPembayaran,
    double? hargaDP,
    double? hargaTotal,
    String? image,
    String? tanggalBooking,
    String? tempat,
    String? namaLengkap,
    DateTime? createdAt,
  }) {
    return Transaksi(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
      hargaDP: hargaDP ?? this.hargaDP,
      hargaTotal: hargaTotal ?? this.hargaTotal,
      image: image ?? this.image,
      tanggalBooking: tanggalBooking ?? this.tanggalBooking,
      tempat: tempat ?? this.tempat,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// BookingProduct model untuk admin
class BookingProduct {
  final String produkId;
  final String? produkNama;

  BookingProduct({
    required this.produkId,
    this.produkNama,
  });

  factory BookingProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingProduct(
      produkId: data['produkId'] ?? '',
      produkNama: data['produkNama'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'produkId': produkId,
      if (produkNama != null) 'produkNama': produkNama,
    };
  }
}
