import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/transaksiMod.dart';
import '../providers/booking_provider.dart';
import '../providers/transaksi_prov.dart';
import 'widget/backgroun.dart';

class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key});

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  late final ValueNotifier<List<dynamic>>
      _selectedEvents; // Changed to dynamic untuk booking dan transaksi
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getAcaraKalender(DateTime.now()));

    // Load bookings dan transaksi when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadUserBookings();
      Provider.of<TransaksiProv>(context, listen: false).getAllTransaksi();
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<dynamic> _getAcaraKalender(DateTime day) {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final transaksiProvider =
        Provider.of<TransaksiProv>(context, listen: false);

    List<dynamic> events = [];

    // Tambahkan booking user
    events.addAll(bookingProvider.getTglBooking(day));

    // Tambahkan transaksi dengan status 'selesai' dari semua user
    final completedTransaksi =
        transaksiProvider.getTransaksiByStatus('selesai');
    for (var transaksi in completedTransaksi) {
      try {
        // Parse tanggal booking dari transaksi (format: "13/06/2025")
        final dateParts = transaksi.tanggalBooking.split('/');
        if (dateParts.length == 3) {
          final day_part = int.parse(dateParts[0]);
          final month_part = int.parse(dateParts[1]);
          final year_part = int.parse(dateParts[2]);
          final transaksiDate = DateTime(year_part, month_part, day_part);

          if (isSameDay(day, transaksiDate)) {
            events.add(transaksi);
          }
        }
      } catch (e) {
        // Handle error parsing date
        print(
            'Error parsing date for transaksi ${transaksi.id}: ${transaksi.tanggalBooking} - $e');
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Jadwal'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<BookingProvider>(context, listen: false)
                  .loadUserBookings();
              Provider.of<TransaksiProv>(context, listen: false)
                  .getAllTransaksi();
              if (_selectedDay != null) {
                _selectedEvents.value = _getAcaraKalender(_selectedDay!);
              }
            },
          ),
        ],
      ),
      body: Consumer2<BookingProvider, TransaksiProv>(
        builder: (context, bookingProvider, transaksiProvider, child) {
          if (bookingProvider.isLoading || transaksiProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingProvider.error.isNotEmpty ||
              transaksiProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${bookingProvider.error.isNotEmpty ? bookingProvider.error : transaksiProvider.error}',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      bookingProvider.loadUserBookings();
                      transaksiProvider.getAllTransaksi();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Calendar Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TableCalendar<dynamic>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    eventLoader: _getAcaraKalender,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: Colors.red[400]),
                      holidayTextStyle: TextStyle(color: Colors.red[400]),
                      markerDecoration: BoxDecoration(
                        color: Colors.blue[600],
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      canMarkersOverflow: true,
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue[700],
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.blue[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Colors.blue[600],
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Colors.blue[600],
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _selectedEvents.value = _getAcaraKalender(selectedDay);
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),

                // Events Section
                ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _selectedEvents,
                  builder: (context, events, _) {
                    return Container(
                      margin: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Text(
                            _selectedDay != null
                                ? 'Jadwal untuk ${DateFormat('dd MMMM yyyy').format(_selectedDay!)}'
                                : 'Pilih tanggal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 8),

                          // Statistics Section
                          if (events.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${events.where((e) => e is Transaksi).length} Terbooking',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${events.where((e) => e is Booking).length} Permintaan Anda',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],

                          // Events List Section
                          events.isEmpty
                              ? Container(
                                  height:
                                      200, // Memberikan tinggi tetap untuk area kosong
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Tidak ada jadwal pada tanggal ini',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: events.map((event) {
                                    if (event is Booking) {
                                      return _buildBookingCard(event);
                                    } else if (event is Transaksi) {
                                      return _buildTransaksiCard(event);
                                    }
                                    return SizedBox.shrink();
                                  }).toList(),
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person,
            color: Colors.blue[600],
          ),
        ),
        title: Text(
          'Permintaan Anda',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pemesan: ${booking.namaPemesan}'),
            Text('Acara: ${booking.tema}'),
            Text('Status: ${booking.status}'),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(context, booking);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Batal'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaksiCard(Transaksi transaksi) {
    final isCompleted = transaksi.statusPembayaran == 'selesai';
    final isPending = transaksi.statusPembayaran == 'belum dp';

    Color cardColor = isCompleted ? Colors.green[100]! : Colors.orange[100]!;
    Color iconColor = isCompleted ? Colors.green[600]! : Colors.orange[600]!;
    Color textColor = isCompleted ? Colors.green[700]! : Colors.orange[700]!;
    Color borderColor = isCompleted ? Colors.green[300]! : Colors.orange[300]!;
    IconData iconData = isCompleted ? Icons.event_available : Icons.schedule;
    String titleText = isCompleted ? 'Terbooking' : 'Menunggu DP';

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              iconData,
              color: iconColor,
            ),
          ),
          title: Text(
            titleText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Klien: ${transaksi.namaLengkap}'),
              Text('Tempat: ${transaksi.tempat}'),
              Text('Total: ${NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(transaksi.hargaTotal)}'),
              Container(
                margin: EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaksi.statusPembayaran.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.info_outline,
            color: iconColor,
          ),
          onTap: () {
            _showTransaksiDetail(context, transaksi);
          },
        ),
      ),
    );
  }

  void _showTransaksiDetail(BuildContext context, Transaksi transaksi) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.event_available, color: Colors.green[600]),
              SizedBox(width: 8),
              Text('Detail Booking'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildDetailRow('Booking ID', transaksi.bookingId),
              _buildDetailRow('Klien', transaksi.namaLengkap),
              _buildDetailRow('Tempat', transaksi.tempat),
              _buildDetailRow('Tanggal', transaksi.tanggalBooking),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              ':$value',
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Jadwal'),
          content: Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final bookingProvider =
                    Provider.of<BookingProvider>(context, listen: false);
                final success = await bookingProvider.deleteBooking(booking.id);

                Navigator.of(context).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Jadwal berhasil dihapus')),
                  );
                  // Update selected events
                  if (_selectedDay != null) {
                    _selectedEvents.value = _getAcaraKalender(_selectedDay!);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus jadwal')),
                  );
                }
              },
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
