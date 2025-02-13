import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/services.dart'; // تم إضافة هذه المكتبة
import '../main_menu.dart';

class NotificationLogPage extends StatefulWidget {
  @override
  _NotificationLogPageState createState() => _NotificationLogPageState();
}

class _NotificationLogPageState extends State<NotificationLogPage> {
  String searchQuery = "";
  DateTime? selectedDate;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  final TextEditingController searchController = TextEditingController();

  final format = DateFormat("yyyy-MM-dd HH:mm");

  List<QueryDocumentSnapshot<Object?>> notifications = [];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل الإشعارات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث بالاسم أو البريد الإلكتروني',
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DateTimeField(
                    format: format,
                    decoration: InputDecoration(
                      labelText: 'اختر التاريخ والوقت',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onChanged: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                    onShowPicker: (context, currentValue) async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        initialDate: currentValue ?? DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
                        );
                        return DateTimeField.combine(date, time);
                      } else {
                        return currentValue;
                      }
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = "";
                      selectedDate = null;
                    });
                  },
                  child: Text('إلغاء البحث'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('حدث خطأ'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    notifications = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final matchesQuery = data['firstName'].toString().contains(searchQuery) ||
                          data['email'].toString().contains(searchQuery);
                      final matchesDate = selectedDate == null ||
                          (data['timestamp'] as Timestamp).toDate().toString().contains(format.format(selectedDate!));
                      return matchesQuery && matchesDate;
                    }).toList();

                    final paginatedNotifications = notifications.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        border: TableBorder.all(),
                        columns: [
                          DataColumn(
                            label: Container(
                              color: isDarkMode ? Colors.black : Colors.lightBlue,
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'UID',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              color: isDarkMode ? Colors.black : Colors.lightBlue,
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'الاسم الأول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              color: isDarkMode ? Colors.black : Colors.lightBlue,
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'الاسم الأخير',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              color: isDarkMode ? Colors.black : Colors.lightBlue,
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'الإيميل',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              color: isDarkMode ? Colors.black : Colors.lightBlue,
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'التوقيت',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              color: isDarkMode ? Colors.black : Colors.lightBlue,
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'المرسل',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              color: isDarkMode ? Colors.black : Colors.lightBlue,
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'الرسالة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: paginatedNotifications.asMap().entries.map((entry) {
                          final index = entry.key;
                          final doc = entry.value;
                          final data = doc.data() as Map<String, dynamic>;
                          final rowColor = isDarkMode ? Colors.black : (index % 2 == 0 ? Colors.white : Colors.grey[200]);
                          final textColor = isDarkMode ? Colors.white : Colors.black;

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                return rowColor;
                              },
                            ),
                            cells: [
                              DataCell(Text(doc.id, style: TextStyle(color: textColor))),
                              DataCell(Text(data['firstName'] ?? '', style: TextStyle(color: textColor))),
                              DataCell(Text(data['lastName'] ?? '', style: TextStyle(color: textColor))),
                              DataCell(Text(data['email'] ?? '', style: TextStyle(color: textColor))),
                              DataCell(Text(format.format((data['timestamp'] as Timestamp).toDate()), style: TextStyle(color: textColor))),
                              DataCell(Text(data['sender'] ?? '', style: TextStyle(color: textColor))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.copy, color: Colors.blue),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: data['message']));
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ الرسالة')));
                                      },
                                    ),
                                    Expanded(child: Text(data['message'] ?? '', style: TextStyle(color: textColor))),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0
                      ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                      : null,
                  child: Text('السابق'),
                ),
                Expanded(
                  child: Center( // تعديل هنا لتوسيط الأرقام
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildPageNumbers(context, notifications.length),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (_currentPage + 1) * _rowsPerPage < notifications.length
                      ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                      : null,
                  child: Text('التالي'),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: MainMenu(),
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context, int totalItems) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalPages = (totalItems / _rowsPerPage).ceil();
    final currentPage = (_currentPage + 1);
    final List<Widget> pageNumbers = [];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pageNumbers.add(
          _buildPageNumber(context, i, isDarkMode),
        );
      }
    } else {
      if (currentPage <= 3) {
        for (int i = 1; i <= 5; i++) {
          pageNumbers.add(
            _buildPageNumber(context, i, isDarkMode),
          );
        }
        pageNumbers.add(Text('...', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
        pageNumbers.add(
          _buildPageNumber(context, totalPages, isDarkMode),
        );
      } else if (currentPage > 3 && currentPage < totalPages - 2) {
        pageNumbers.add(
          _buildPageNumber(context, 1, isDarkMode),
        );
        pageNumbers.add(Text('...', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
        for (int i = currentPage - 2; i <= currentPage + 2; i++) {
          pageNumbers.add(
            _buildPageNumber(context, i, isDarkMode),
          );
        }
        pageNumbers.add(Text('...', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
        pageNumbers.add(
          _buildPageNumber(context, totalPages, isDarkMode),
        );
      } else {
        pageNumbers.add(
          _buildPageNumber(context, 1, isDarkMode),
        );
        pageNumbers.add(Text('...', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
        for (int i = totalPages - 4; i <= totalPages; i++) {
          pageNumbers.add(
            _buildPageNumber(context, i, isDarkMode),
          );
        }
      }
    }

    return pageNumbers;
  }

  Widget _buildPageNumber(BuildContext context, int pageNumber, bool isDarkMode) {
    return TextButton(
      onPressed: () {
        setState(() {
          _currentPage = pageNumber - 1;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: _currentPage == pageNumber - 1 ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            color: _currentPage == pageNumber - 1 ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}
