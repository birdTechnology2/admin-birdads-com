// ملف customer_requests_page.dart مع التعديل

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_menu.dart';

class CustomerRequestsPage extends StatefulWidget {
  @override
  _CustomerRequestsPageState createState() => _CustomerRequestsPageState();
}

class _CustomerRequestsPageState extends State<CustomerRequestsPage> {
  final CollectionReference requests = FirebaseFirestore.instance.collection('customer requests');
  String searchQuery = "";
  DateTime? selectedDate;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  final TextEditingController searchController = TextEditingController();
  final searchFormat = DateFormat("yyyy-MM-dd");
  final displayFormat = DateFormat("yyyy-MM-dd HH:mm");
  int? _expandedIndex;
  String userName = "";
  bool canEditStatus = false;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserPermissions();
  }

  Future<void> _fetchUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('saved_username');
    if (savedUsername != null) {
      FirebaseFirestore.instance
          .collection('admin users')
          .where('user_name', isEqualTo: savedUsername)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            userName = querySnapshot.docs.first['name'];
          });
        }
      });
    }
  }

  Future<void> _checkUserPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('saved_username');

    if (savedUsername != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('admin users')
          .where('user_name', isEqualTo: savedUsername)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        setState(() {
          canEditStatus = (doc.data() as Map<String, dynamic>)['permissions_customer_requests_edit'] ?? false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    return displayFormat.format(date);
  }

  void updateAction(String docId, String newAction) {
    if (newAction == null || newAction.isEmpty) {
      newAction = 'طلب جديد';
    }
    requests.doc(docId).update({'action': newAction}).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update action: $error')));
    });
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ النص')));
  }

  Color getActionColor(String action) {
    switch (action) {
      case 'تم الرفض':
        return Colors.red;
      case 'تم تعديل استهداف الإعلان':
      case 'تم تعديل المطلوب في الإعلان':
      case 'تم استرجاع الاموال للعميل':
      case 'تم تزويد الإعلان':
        return Colors.green;
      case 'تم إيقاف الإعلان':
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('طلبات العملاء - مرحبًا بك يا $userName'),
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
                      labelText: 'بحث بالبريد الإلكتروني، ID العميل، أو ID الإعلان',
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
                stream: requests.orderBy('createdTime', descending: true).snapshots(),
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
                    final requestData = doc.data() as Map<String, dynamic>;

                    final matchesQuery = (requestData['email'] != null && requestData['email'].toString().contains(searchQuery)) ||
                        (requestData['customerID'] != null && requestData['customerID'].toString().contains(searchQuery)) ||
                        (requestData['adID'] != null && requestData['adID'].toString().contains(searchQuery));

                    final matchesDate = selectedDate == null ||
                        (requestData['createdTime'] as Timestamp).toDate().toLocal().toString().substring(0, 10) == searchFormat.format(selectedDate!);

                    return matchesQuery && matchesDate;
                  }).toList();

                  final paginatedRequests = data.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedRequests.length,
                          itemBuilder: (context, index) {
                            final request = paginatedRequests[index];
                            final requestData = request.data() as Map<String, dynamic>;
                            final requestIndex = data.length - (_currentPage * _rowsPerPage + index);
                            final rowColor = getActionColor(requestData['action'] ?? '');

                            return Container(
                              color: rowColor,
                              margin: const EdgeInsets.symmetric(vertical: 4.0), // إضافة فراغ بين الطلبات
                              child: ExpansionTile(
                                title: Text(
                                  'طلب رقم: $requestIndex - ${requestData['ad name'] ?? 'بدون اسم'}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                initiallyExpanded: _expandedIndex == index,
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    _expandedIndex = expanded ? index : null;
                                  });
                                },
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (requestData['email'] != null)
                                          Row(
                                            children: [
                                              Text('البريد الإلكتروني: ', style: TextStyle(fontSize: 16, color: textColor)),
                                              IconButton(
                                                icon: Icon(Icons.copy, color: textColor),
                                                onPressed: () => copyToClipboard(requestData['email']),
                                              ),
                                              Expanded(
                                                child: Text(requestData['email'], style: TextStyle(fontSize: 16, color: textColor)),
                                              ),
                                            ],
                                          ),
                                        if (requestData['customerID'] != null)
                                          Row(
                                            children: [
                                              Text('ID العميل: ', style: TextStyle(fontSize: 16, color: textColor)),
                                              IconButton(
                                                icon: Icon(Icons.copy, color: textColor),
                                                onPressed: () => copyToClipboard(requestData['customerID']),
                                              ),
                                              Expanded(
                                                child: Text(requestData['customerID'], style: TextStyle(fontSize: 16, color: textColor)),
                                              ),
                                            ],
                                          ),
                                        if (requestData['adID'] != null)
                                          Row(
                                            children: [
                                              Text('ID الإعلان: ', style: TextStyle(fontSize: 16, color: textColor)),
                                              IconButton(
                                                icon: Icon(Icons.copy, color: textColor),
                                                onPressed: () => copyToClipboard(requestData['adID']),
                                              ),
                                              Expanded(
                                                child: Text(requestData['adID'], style: TextStyle(fontSize: 16, color: textColor)),
                                              ),
                                            ],
                                          ),
                                        if (requestData['note'] != null)
                                          Row(
                                            children: [
                                              Text('الملاحظات: ', style: TextStyle(fontSize: 16, color: textColor)),
                                              IconButton(
                                                icon: Icon(Icons.copy, color: textColor),
                                                onPressed: () => copyToClipboard(requestData['note']),
                                              ),
                                              Expanded(
                                                child: Text(requestData['note'], style: TextStyle(fontSize: 16, color: textColor)),
                                              ),
                                            ],
                                          ),
                                        Row(
                                          children: [
                                            Text('التوقيت: ', style: TextStyle(fontSize: 16, color: textColor)),
                                            Expanded(
                                              child: Text(formatTimestamp(requestData['createdTime']), style: TextStyle(fontSize: 16, color: textColor)),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text('الإجراء: ', style: TextStyle(fontSize: 16, color: textColor)),
                                            DropdownButton<String>(
                                              value: requestData['action'] != null &&
                                                  [
                                                    'طلب جديد',
                                                    'تم تزويد الإعلان',
                                                    'تم إيقاف الإعلان',
                                                    'تم تعديل استهداف الإعلان',
                                                    'تم استرجاع الاموال للعميل',
                                                    'تم تعديل المطلوب في الإعلان',
                                                    'تم الرفض',
                                                  ].contains(requestData['action'])
                                                  ? requestData['action']
                                                  : 'طلب جديد',
                                              items: [
                                                'طلب جديد',
                                                'تم تزويد الإعلان',
                                                'تم إيقاف الإعلان',
                                                'تم تعديل استهداف الإعلان',
                                                'تم استرجاع الاموال للعميل',
                                                'تم تعديل المطلوب في الإعلان',
                                                'تم الرفض',
                                              ].map((status) {
                                                return DropdownMenuItem<String>(
                                                  value: status,
                                                  child: Text(status, style: TextStyle(color: textColor)),
                                                );
                                              }).toList(),
                                              onChanged: canEditStatus ? (newValue) {
                                                updateAction(request.id, newValue!);
                                                setState(() {
                                                  requestData['action'] = newValue;
                                                });
                                              } : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          (data.length / _rowsPerPage).ceil(),
                              (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text('${index + 1}'),
                              selected: _currentPage == index,
                              onSelected: (selected) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              selectedColor: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _currentPage > 0
                                ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                                : null,
                            child: Text('السابق'),
                          ),
                          TextButton(
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
