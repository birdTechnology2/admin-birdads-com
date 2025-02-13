import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import '../main_menu.dart';

class CustomerComplaintsPage extends StatefulWidget {
  @override
  _CustomerComplaintsPageState createState() => _CustomerComplaintsPageState();
}

class _CustomerComplaintsPageState extends State<CustomerComplaintsPage> {
  String searchQuery = "";
  DateTime? selectedDate;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  final TextEditingController searchController = TextEditingController();
  final format = DateFormat("yyyy-MM-dd HH:mm");
  final List<String> actions = ['تم التواصل مع العميل', 'تم حل المشكلة', 'جاري العمل عليها'];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color tableHeaderColor = isDarkMode ? Colors.blueGrey : Colors.lightBlue;
    Color tableRowColor(int index) => isDarkMode ? Colors.grey[800]! : (index % 2 == 0 ? Colors.white : Colors.grey[200]!);

    return Scaffold(
      appBar: AppBar(
        title: Text('شكاوى العملاء'),
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
                      labelStyle: TextStyle(color: textColor),
                      suffixIcon: Icon(Icons.search, color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
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
                    format: format,
                    decoration: InputDecoration(
                      labelText: 'اختر التاريخ والوقت',
                      labelStyle: TextStyle(color: textColor),
                      suffixIcon: Icon(Icons.calendar_today, color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                    ),
                    style: TextStyle(color: textColor),
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
                    .collection('complaints')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final complaints = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchesQuery = data['firstName'].toString().contains(searchQuery) ||
                        data['email'].toString().contains(searchQuery);
                    final matchesDate = selectedDate == null ||
                        (data['timestamp'] as Timestamp).toDate().toString().contains(format.format(selectedDate!));
                    return matchesQuery && matchesDate;
                  }).toList();

                  final paginatedComplaints = complaints.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                  return Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(),
                          columns: [
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'رقم الشكوى',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'UID',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الاسم الأول',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الاسم الأخير',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الإيميل',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'رقم الهاتف',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'التوقيت',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الشكوى',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: tableHeaderColor,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الإجراء',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                          rows: paginatedComplaints.asMap().entries.map((entry) {
                            final index = entry.key;
                            final doc = entry.value;
                            final data = doc.data() as Map<String, dynamic>;
                            final rowColor = tableRowColor(index);
                            final currentAction = data['action'] ?? 'اختر';

                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                  return rowColor;
                                },
                              ),
                              cells: [
                                DataCell(Text('${complaints.length - (index + (_currentPage * _rowsPerPage))}', style: TextStyle(color: textColor))),
                                DataCell(Text(doc.id, style: TextStyle(color: textColor))),
                                DataCell(Text(data['firstName'] ?? '', style: TextStyle(color: textColor))),
                                DataCell(Text(data['lastName'] ?? '', style: TextStyle(color: textColor))),
                                DataCell(Text(data['email'] ?? '', style: TextStyle(color: textColor))),
                                DataCell(Text(data['phone'] ?? '', style: TextStyle(color: textColor))),
                                DataCell(Text(format.format((data['timestamp'] as Timestamp).toDate()), style: TextStyle(color: textColor))),
                                DataCell(Text(data['complaint'] ?? '', style: TextStyle(color: textColor))),
                                DataCell(
                                  DropdownButton<String>(
                                    value: actions.contains(currentAction) ? currentAction : 'اختر',
                                    items: ['اختر', ...actions].map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value, style: TextStyle(color: textColor)),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          FirebaseFirestore.instance
                                              .collection('complaints')
                                              .doc(doc.id)
                                              .update({'action': newValue});
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
                          Row(
                            children: List.generate(
                              (complaints.length / _rowsPerPage).ceil(),
                                  (index) => TextButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: _currentPage == index ? Colors.blue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: _currentPage == index ? Colors.white : textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: (_currentPage + 1) * _rowsPerPage < complaints.length
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
      drawer: MainMenu(),
    );
  }
}
