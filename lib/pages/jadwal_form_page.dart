// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../models/produk.dart';
// import '../providers/booking_provider.dart';
// import '../providers/product_provider.dart';

// class JadwalFormPage extends StatefulWidget {
//   final String produkId;

//   JadwalFormPage({required this.produkId});

//   @override
//   _JadwalFormPageState createState() => _JadwalFormPageState();
// }

// class _JadwalFormPageState extends State<JadwalFormPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _namaController = TextEditingController();
//   final TextEditingController _tempatController = TextEditingController();
//   DateTime? _tanggalDipilih;
//   bool _isLoading = false;
//   String? _produkNama;

//   @override
//   void initState() {
//     super.initState();
//     _loadProductName();
//   }

//   void _loadProductName() {
//     final productProvider =
//         Provider.of<ProductProvider>(context, listen: false);
//     final product = productProvider.products.firstWhere(
//       (p) => p.id == widget.produkId,
//       orElse: () => Product(
//           id: '',
//           nama: 'Produk Tidak Ditemukan',
//           harga: 0,
//           deskripsi: '',
//           firstImageUrl: ''),
//     );
//     setState(() {
//       _produkNama = product.nama;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bookingProvider = Provider.of<BookingProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Form Pemesanan"),
//         backgroundColor: Colors.blue[600],
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (_produkNama != null) ...[
//                 Card(
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Row(
//                       children: [
//                         Icon(Icons.shopping_bag, color: Colors.blue[600]),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Produk yang Dipesan:',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               Text(
//                                 _produkNama!,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue[700],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//               ],
//               TextFormField(
//                 controller: _namaController,
//                 decoration: InputDecoration(
//                   labelText: "Nama Lengkap Pemesan",
//                   prefixIcon: Icon(Icons.person),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Masukkan nama lengkap';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//               InkWell(
//                 onTap: () => _selectDate(context),
//                 child: InputDecorator(
//                   decoration: InputDecoration(
//                     labelText: "Tanggal Dijadwalkan",
//                     prefixIcon: Icon(Icons.calendar_today),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     suffixIcon: _tanggalDipilih != null &&
//                             bookingProvider.isDateBooked(_tanggalDipilih!)
//                         ? Tooltip(
//                             message:
//                                 'Anda sudah memiliki jadwal pada tanggal ini',
//                             child: Icon(Icons.warning, color: Colors.orange),
//                           )
//                         : null,
//                   ),
//                   child: Text(
//                     _tanggalDipilih != null
//                         ? DateFormat('dd MMM yyyy').format(_tanggalDipilih!)
//                         : 'Pilih Tanggal',
//                     style: TextStyle(
//                       color: _tanggalDipilih != null
//                           ? Colors.black
//                           : Colors.grey[600],
//                     ),
//                   ),
//                 ),
//               ),
//               if (_tanggalDipilih != null &&
//                   bookingProvider.isDateBooked(_tanggalDipilih!))
//                 Padding(
//                   padding: EdgeInsets.only(top: 8),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info, size: 16, color: Colors.orange),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'Anda sudah memiliki jadwal pada tanggal ini. Anda tetap bisa menambah jadwal baru.',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.orange[700],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: _tempatController,
//                 decoration: InputDecoration(
//                   labelText: "Tempat yang Diinginkan",
//                   prefixIcon: Icon(Icons.location_on),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Masukkan tempat';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _submitForm,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[600],
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor:
//                                     AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             ),
//                             SizedBox(width: 12),
//                             Text("Menyimpan..."),
//                           ],
//                         )
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.send),
//                             SizedBox(width: 8),
//                             Text("Kirim Jadwal"),
//                           ],
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(Duration(days: 1)),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(Duration(days: 365)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.blue[600]!,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() {
//         _tanggalDipilih = picked;
//       });
//     }
//   }

//   void _submitForm() async {
//     if (_formKey.currentState!.validate() &&
//         _tanggalDipilih != null &&
//         _produkNama != null) {
//       setState(() {
//         _isLoading = true;
//       });

//       final bookingProvider =
//           Provider.of<BookingProvider>(context, listen: false);

//       final success = await bookingProvider.addBooking(
//         produkId: widget.produkId,
//         produkNama: _produkNama!,
//         namaPemesan: _namaController.text,
//         tempat: _tempatController.text,
//         tanggal: _tanggalDipilih!,
//       );

//       setState(() {
//         _isLoading = false;
//       });

//       if (success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.white),
//                 SizedBox(width: 8),
//                 Text('Pemesanan berhasil dikirim'),
//               ],
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.error, color: Colors.white),
//                 SizedBox(width: 8),
//                 Text('Gagal menyimpan pemesanan. Coba lagi.'),
//               ],
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } else if (_tanggalDipilih == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               Icon(Icons.warning, color: Colors.white),
//               SizedBox(width: 8),
//               Text('Pilih tanggal terlebih dahulu'),
//             ],
//           ),
//           backgroundColor: Colors.orange,
//         ),
//       );
//     }
//   }
// }
