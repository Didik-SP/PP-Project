// models/booking_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  completed('completed'),
  cancelled('cancelled'),
  refunded('refunded');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

enum PaymentStatus {
  pending('pending'),
  paid('paid'),
  failed('failed'),
  refunded('refunded');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class BookingItem {
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String? productImageUrl;

  BookingItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.productImageUrl,
  });

  factory BookingItem.fromMap(Map<String, dynamic> map) {
    return BookingItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: map['unitPrice'] ?? 0,
      totalPrice: map['totalPrice'] ?? 0,
      productImageUrl: map['productImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'productImageUrl': productImageUrl,
    };
  }
}

class CustomerInfo {
  final String name;
  final String phone;
  final String email;
  final String address;

  CustomerInfo({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
  });

  factory CustomerInfo.fromMap(Map<String, dynamic> map) {
    return CustomerInfo(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }
}

class PaymentInfo {
  final PaymentStatus status;
  final String? paymentMethod;
  final String? transactionId;
  final String? snapToken;
  final DateTime? paidAt;
  final int amount;

  PaymentInfo({
    required this.status,
    this.paymentMethod,
    this.transactionId,
    this.snapToken,
    this.paidAt,
    required this.amount,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      status: PaymentStatus.fromString(map['status'] ?? 'pending'),
      paymentMethod: map['paymentMethod'],
      transactionId: map['transactionId'],
      snapToken: map['snapToken'],
      paidAt:
          map['paidAt'] != null ? (map['paidAt'] as Timestamp).toDate() : null,
      amount: map['amount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'snapToken': snapToken,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'amount': amount,
    };
  }
}

// class Booking {
//   final String id;
//   final String userId;
//   final String bookingNumber;
//   final CustomerInfo customerInfo;
//   final String venue;
//   final String? tema;
//   final DateTime eventDate;
//   final List<BookingItem> items;
//   final int totalAmount;
//   final BookingStatus status;
//   final PaymentInfo paymentInfo;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final String? notes;
//   final String? cancellationReason;

//   Booking({
//     required this.id,
//     required this.userId,
//     required this.bookingNumber,
//     required this.customerInfo,
//     required this.venue,
//     this.tema,
//     required this.eventDate,
//     required this.items,
//     required this.totalAmount,
//     required this.status,
//     required this.paymentInfo,
//     required this.createdAt,
//     required this.updatedAt,
//     this.notes,
//     this.cancellationReason,
//   });

//   factory Booking.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;

//     return Booking(
//       id: doc.id,
//       userId: data['userId'] ?? '',
//       bookingNumber: data['bookingNumber'] ?? '',
//       customerInfo: CustomerInfo.fromMap(data['customerInfo'] ?? {}),
//       venue: data['venue'] ?? '',
//       tema: data['tema'], // DITAMBAHKAN: Membaca data tema dari Firestore
//       eventDate: (data['eventDate'] as Timestamp).toDate(),
//       items: (data['items'] as List<dynamic>?)
//               ?.map((item) => BookingItem.fromMap(item as Map<String, dynamic>))
//               .toList() ??
//           [],
//       totalAmount: data['totalAmount'] ?? 0,
//       status: BookingStatus.fromString(data['status'] ?? 'pending'),
//       paymentInfo: PaymentInfo.fromMap(data['paymentInfo'] ?? {}),
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//       updatedAt: (data['updatedAt'] as Timestamp).toDate(),
//       notes: data['notes'],
//       cancellationReason: data['cancellationReason'],
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'userId': userId,
//       'bookingNumber': bookingNumber,
//       'customerInfo': customerInfo.toMap(),
//       'venue': venue,
//       'tema': tema,
//       'eventDate': Timestamp.fromDate(eventDate),
//       'items': items.map((item) => item.toMap()).toList(),
//       'totalAmount': totalAmount,
//       'status': status.value,
//       'paymentInfo': paymentInfo.toMap(),
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': Timestamp.fromDate(updatedAt),
//       'notes': notes,
//       'cancellationReason': cancellationReason,
//     };
//   }

//   // Helper methods
//   int get itemCount => items.length;
//   bool get isPaid => paymentInfo.status == PaymentStatus.paid;
//   bool get canBeCancelled =>
//       status == BookingStatus.pending || status == BookingStatus.confirmed;

//   // Create booking number
//   static String generateBookingNumber() {
//     final now = DateTime.now();
//     final dateStr =
//         '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
//     final random =
//         (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
//     return 'BK-$dateStr-$random';
//   }

//   // Copy with method for updates
//   Booking copyWith({
//     String? id,
//     String? userId,
//     String? bookingNumber,
//     CustomerInfo? customerInfo,
//     String? venue,
//     String? tema, // DITAMBAHKAN
//     DateTime? eventDate,
//     List<BookingItem>? items,
//     int? totalAmount,
//     BookingStatus? status,
//     PaymentInfo? paymentInfo,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     String? notes,
//     String? cancellationReason,
//   }) {
//     return Booking(
//       id: id ?? this.id,
//       userId: userId ?? this.userId,
//       bookingNumber: bookingNumber ?? this.bookingNumber,
//       customerInfo: customerInfo ?? this.customerInfo,
//       venue: venue ?? this.venue,
//       tema: tema ?? this.tema,
//       eventDate: eventDate ?? this.eventDate,
//       items: items ?? this.items,
//       totalAmount: totalAmount ?? this.totalAmount,
//       status: status ?? this.status,
//       paymentInfo: paymentInfo ?? this.paymentInfo,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       notes: notes ?? this.notes,
//       cancellationReason: cancellationReason ?? this.cancellationReason,
//     );
//   }
// }

// Statistics model for dashboard
class BookingStats {
  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int totalRevenue;
  final int pendingPayments;

  BookingStats({
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalRevenue,
    required this.pendingPayments,
  });
}
