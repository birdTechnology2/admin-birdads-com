// ملف create_coupon_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import '../main_menu.dart';

class CreateCouponPage extends StatefulWidget {
  @override
  _CreateCouponPageState createState() => _CreateCouponPageState();
}

class _CreateCouponPageState extends State<CreateCouponPage> {
  String searchQuery = "";
  DateTime? selectedDate;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController _couponNameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _validController = TextEditingController();
  final format = DateFormat("yyyy-MM-dd HH:mm");
  final List<Map<String, dynamic>> _coupons = [];

  @override
  void dispose() {
    searchController.dispose();
    _couponNameController.dispose();
    _costController.dispose();
    _validController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final rowBackgroundColor = isDarkMode ? Colors.black : Colors.white;
    final alternateRowBackgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[200];

    return Scaffold(
      appBar: AppBar(
        title: Text('إنشاء كوبون'),
      ),
      drawer: MainMenu(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponNameController,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'اسم الكوبون',
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _validController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'الصلاحية (بالأيام)',
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _createCoupon,
                  child: Text('إنشاء كوبون'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث بالاسم',
                      suffixIcon: Icon(Icons.search),
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                      labelText: 'بحث بالتاريخ',
                      suffixIcon: Icon(Icons.calendar_today),
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('create coupon')
                    .orderBy('validTo', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final coupons = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchesQuery = data['coupon name'].toString().contains(searchQuery);
                    final matchesDate = selectedDate == null ||
                        (data['validFrom'] as Timestamp).toDate().toString().contains(format.format(selectedDate!));
                    return matchesQuery && matchesDate;
                  }).toList();

                  final paginatedCoupons = coupons.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                  return Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(),
                          columns: [
                            DataColumn(
                              label: Container(
                                color: Colors.lightBlue,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'رقم الكوبون',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Colors.lightBlue,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'اسم الكوبون',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Colors.lightBlue,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'المبلغ',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Colors.lightBlue,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الصلاحية (بالأيام)',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Colors.lightBlue,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الصلاحية تبدأ من',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Colors.lightBlue,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الصلاحية تنتهي في',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                          rows: paginatedCoupons.asMap().entries.map((entry) {
                            final index = entry.key;
                            final doc = entry.value;
                            final data = doc.data() as Map<String, dynamic>;
                            final rowColor = index % 2 == 0 ? rowBackgroundColor : alternateRowBackgroundColor;
                            final DateTime validFrom = (data['validFrom'] as Timestamp).toDate();
                            final DateTime validTo = (data['validTo'] as Timestamp).toDate();
                            final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                  return rowColor;
                                },
                              ),
                              cells: [
                                DataCell(Text('${coupons.length - (index + (_currentPage * _rowsPerPage))}')),
                                DataCell(Text(data['coupon name'] ?? '')),
                                DataCell(Text(data['cost'].toString())),
                                DataCell(Text(data['validDays'].toString())),
                                DataCell(Text(dateFormat.format(validFrom))),
                                DataCell(Text(dateFormat.format(validTo))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildPageNumbers(context, coupons.length),
                      ),
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
                          ElevatedButton(
                            onPressed: (_currentPage + 1) * _rowsPerPage < coupons.length
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _createCoupon() async {
    final String couponName = _couponNameController.text;
    final int cost = int.parse(_costController.text);
    final int validDays = int.parse(_validController.text);
    final DateTime now = DateTime.now();
    final DateTime validFrom = now;
    final DateTime validTo = now.add(Duration(days: validDays));

    await FirebaseFirestore.instance.collection('create coupon').add({
      'coupon name': couponName,
      'cost': cost,
      'validFrom': validFrom,
      'validTo': validTo,
      'validDays': validDays,
    });

    setState(() {
      _coupons.add({
        'coupon name': couponName,
        'cost': cost,
        'validFrom': validFrom,
        'validTo': validTo,
        'validDays': validDays,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إنشاء الكوبون بنجاح')),
    );

    _couponNameController.clear();
    _costController.clear();
    _validController.clear();
  }
}
