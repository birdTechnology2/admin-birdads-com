import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/services.dart';
import '../main_menu.dart';

class ClientsPage extends StatefulWidget {
  @override
  _ClientsPageState createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final CollectionReference clients = FirebaseFirestore.instance.collection('clients');
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

  String formatTimestamp(Timestamp timestamp, DateFormat formatter) {
    var date = timestamp.toDate();
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('العملاء'),
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
                stream: clients.orderBy('created time', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ ما: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('لا توجد بيانات متاحة'));
                  }

                  final data = snapshot.requireData.docs.where((doc) {
                    final clientData = doc.data() as Map<String, dynamic>;
                    final matchesQuery = clientData['firstName'].toString().contains(searchQuery) ||
                        clientData['email'].toString().contains(searchQuery);
                    final matchesDate = selectedDate == null ||
                        (clientData['created time'] as Timestamp).toDate().toString().contains(searchFormat.format(selectedDate!));
                    return matchesQuery && matchesDate;
                  }).toList();

                  final paginatedClients = data.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                  return Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(),
                          columns: [
                            DataColumn(
                              label: Container(
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'رقم العميل',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'UID',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الاسم الأول',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'الاسم الأخير',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'البريد الإلكتروني',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'رقم الهاتف',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'تاريخ إنشاء الحساب',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                color: Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'آخر تسجيل دخول',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                                ),
                              ),
                            ),
                          ],
                          rows: paginatedClients.asMap().entries.map((entry) {
                            final index = entry.key;
                            final client = entry.value;
                            final clientData = client.data() as Map<String, dynamic>;
                            final rowColor = index % 2 == 0 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.background;

                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                  return rowColor;
                                },
                              ),
                              cells: [
                                DataCell(Text('${data.length - (_currentPage * _rowsPerPage + index)}')), // رقم العميل تنازلي
                                DataCell(Text(clientData['uid']?.toString() ?? '')),  // UID
                                DataCell(Text(clientData['firstName']?.toString() ?? '')),
                                DataCell(Text(clientData['lastName']?.toString() ?? '')),
                                DataCell(
                                  Row(
                                    children: [
                                      Text(clientData['email']?.toString() ?? ''),
                                      IconButton(
                                        icon: Icon(Icons.copy),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: clientData['email']?.toString() ?? ''));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('تم نسخ البريد الإلكتروني')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      Text(clientData['phone']?.toString() ?? ''),
                                      IconButton(
                                        icon: Icon(Icons.copy),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: clientData['phone']?.toString() ?? ''));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('تم نسخ رقم الهاتف')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),  // رقم الهاتف
                                DataCell(Text(clientData['created time'] != null ? formatTimestamp(clientData['created time'] as Timestamp, displayFormat) : '')),
                                DataCell(Text(clientData['last seen'] != null ? formatTimestamp(clientData['last seen'] as Timestamp, displayFormat) : '')),
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
                              (data.length / _rowsPerPage).ceil(),
                                  (index) => TextButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: _currentPage == index ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: _currentPage == index ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: (_currentPage + 1) * _rowsPerPage < data.length
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
