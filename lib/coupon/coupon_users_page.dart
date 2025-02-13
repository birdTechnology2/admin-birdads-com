import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import '../main_menu.dart';

class CouponUsersPage extends StatefulWidget {
  @override
  _CouponUsersPageState createState() => _CouponUsersPageState();
}

class _CouponUsersPageState extends State<CouponUsersPage> {
  String searchQuery = "";
  DateTime? selectedDate;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  final TextEditingController searchController = TextEditingController();
  final searchFormat = DateFormat("yyyy-MM-dd");
  final displayFormat = DateFormat("yyyy-MM-dd HH:mm");

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getCouponDetails(String couponId) async {
    final couponDoc = await FirebaseFirestore.instance
        .collection('create coupon')
        .doc(couponId)
        .get();
    if (couponDoc.exists) {
      return couponDoc.data()!;
    } else {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getClientDetails(String email) async {
    final clientQuery = await FirebaseFirestore.instance
        .collection('clients')
        .where('email', isEqualTo: email)
        .get();
    if (clientQuery.docs.isNotEmpty) {
      return clientQuery.docs.first.data();
    } else {
      return {'firstName': '', 'lastName': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('مستخدمين الكوبونات'),
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
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث بالاميل',
                      suffixIcon: Icon(Icons.search, color: textColor),
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    style: TextStyle(color: textColor),
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
                    format: searchFormat,
                    decoration: InputDecoration(
                      labelText: 'اختر التاريخ',
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
                      return date;
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
                    .collection('used_coupons')
                    .orderBy('timestamp', descending: true) // إضافة الترتيب حسب التوقيت
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final couponUsers = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchesQuery = data['email'].toString().contains(searchQuery);
                    final matchesDate = selectedDate == null ||
                        (data['timestamp'] as Timestamp).toDate().toString().contains(searchFormat.format(selectedDate!));
                    return matchesQuery && matchesDate;
                  }).toList();

                  final paginatedCouponUsers = couponUsers.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: Future.wait(paginatedCouponUsers.map((doc) async {
                      final data = doc.data() as Map<String, dynamic>;
                      final couponDetails = await _getCouponDetails(data['coupon_id']);
                      final clientDetails = await _getClientDetails(data['email']);
                      return {
                        ...data,
                        'coupon_name': couponDetails['coupon name'],
                        'coupon_cost': couponDetails['cost'],
                        'firstName': clientDetails['firstName'],
                        'lastName': clientDetails['lastName'],
                      };
                    }).toList()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('حدث خطأ أثناء جلب بيانات الكوبونات'));
                      }

                      final couponUserDetails = snapshot.data!;

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
                                      'رقم المستخدم',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Container(
                                    color: Colors.lightBlue,
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'الاسم الأول',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Container(
                                    color: Colors.lightBlue,
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'الاسم الأخير',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Container(
                                    color: Colors.lightBlue,
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'البريد الإلكتروني',
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
                                      'مبلغ الكوبون',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Container(
                                    color: Colors.lightBlue,
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'تاريخ الاستخدام',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                              rows: couponUserDetails.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                final rowColor = index % 2 == 0 ? cardColor : (isDarkMode ? Colors.grey[800] : Colors.grey[200]);
                                final DateTime usedDate = (data['timestamp'] as Timestamp).toDate();
                                final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

                                return DataRow(
                                  color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                    return rowColor;
                                  }),
                                  cells: [
                                    DataCell(Text('${couponUsers.length - (index + (_currentPage * _rowsPerPage))}', style: TextStyle(color: textColor))),
                                    DataCell(Text(data['firstName'] ?? '', style: TextStyle(color: textColor))),
                                    DataCell(Text(data['lastName'] ?? '', style: TextStyle(color: textColor))),
                                    DataCell(Text(data['email'] ?? '', style: TextStyle(color: textColor))),
                                    DataCell(Text(data['coupon_name'] ?? '', style: TextStyle(color: textColor))),
                                    DataCell(Text(data['coupon_cost']?.toString() ?? '', style: TextStyle(color: textColor))),
                                    DataCell(Text(dateFormat.format(usedDate), style: TextStyle(color: textColor))),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildPageNumbers(context, couponUsers.length),
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
                                onPressed: (_currentPage + 1) * _rowsPerPage < couponUsers.length
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
}
