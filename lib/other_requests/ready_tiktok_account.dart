// lib/other_requests/tiktok_requests.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_menu.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart'; // لاستيراد kIsWeb

class ReadyTiktokAccountPage extends StatefulWidget {
  @override
  _ReadyTiktokAccountPageState createState() => _ReadyTiktokAccountPageState();
}

class _ReadyTiktokAccountPageState extends State<ReadyTiktokAccountPage> {
  final CollectionReference requests = FirebaseFirestore.instance.collection('tiktok_ready_requests');
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
          canEditStatus = (doc.data() as Map<String, dynamic>)['permissions_tiktok_requests_edit'] ?? false;
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

  void updateField(String docId, String fieldName, String newValue) {
    requests.doc(docId).update({fieldName: newValue}).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في التحديث: $error')));
    });
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ النص')));
  }

  void _launchURL(String url) async {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      throw 'لا يمكن فتح الروابط في هذه المنصة';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'جاري العمل على الطلب':
        return Colors.yellow;
      case 'تم التسليم':
        return Colors.lightBlueAccent;
      case 'تم التسليم بعد التعديل':
        return Colors.lightGreenAccent;
      case 'تم الرفض تواصل مع الدعم':
        return Colors.red;
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
        title: Text('طلبات حسابات تيك توك - مرحبًا بك يا $userName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث بالبريد الإلكتروني أو اسم العميل',
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
                Flexible(
                  flex: 1,
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
                stream: requests.orderBy('timestamp', descending: true).snapshots(),
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

                    final matchesQuery = searchQuery.isEmpty ||
                        (requestData['email'] != null && requestData['email'].toString().contains(searchQuery)) ||
                        (requestData['firstName'] != null && requestData['firstName'].toString().contains(searchQuery));

                    final matchesDate = selectedDate == null ||
                        (requestData['timestamp'] as Timestamp).toDate().toLocal().toString().substring(0, 10) == searchFormat.format(selectedDate!);

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
                            final rowColor = getStatusColor(requestData['status'] ?? '');

                            return Container(
                              color: rowColor,
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ExpansionTile(
                                title: Text(
                                  'طلب رقم: $requestIndex - ${requestData['firstName'] ?? 'بدون اسم'}',
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
                                        _buildReadOnlyRow(requestData, 'requestId', 'رقم الطلب ID', textColor),
                                        _buildReadOnlyRow(requestData, 'firstName', 'الاسم الأول', textColor),
                                        _buildReadOnlyRow(requestData, 'lastName', 'الاسم الأخير', textColor),
                                        _buildReadOnlyRow(requestData, 'email', 'البريد الإلكتروني', textColor),
                                        _buildReadOnlyRow(requestData, 'phone', 'الهاتف', textColor),
                                        Row(
                                          children: [
                                            Text('التاريخ: ', style: TextStyle(fontSize: 16, color: textColor)),
                                            Flexible(
                                              child: Text(formatTimestamp(requestData['timestamp']), style: TextStyle(fontSize: 16, color: textColor)),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        _buildReadOnlyRow(requestData, 'tiktokLink', 'رابط تيك توك', textColor),
                                        _buildReadOnlyRow(requestData, 'description', 'تفاصيل الحساب', textColor),
                                        _buildReadOnlyRow(requestData, 'status_editing', 'حالة الاستفسار', textColor),
                                        _buildEditableRowWithDialog(request, requestData, 'responseDetails', 'الرد بالتفاصيل', textColor),
                                        _buildReadOnlyRow(requestData, 'contentDetails_edit', 'استفسار اضافي', textColor),
                                        _buildEditableRowWithDialog(request, requestData, 'responseDetails2', 'الرد بعد الاستفسار', textColor),
                                        _buildEditableRowWithDialog(request, requestData, 'notes', 'الملاحظات', textColor),
                                        _buildReadOnlyRow(requestData, 'accountName', 'اسم الحساب', textColor),
                                        _buildReadOnlyRow(requestData, 'selectedFollowers', 'عدد المتابعين المختارين', textColor),
                                        Row(
                                          children: [
                                            Text('الحالة: ', style: TextStyle(fontSize: 16, color: textColor)),
                                            Flexible(
                                              child: DropdownButton<String>(
                                                value: requestData['status'] ?? 'قيد التنفيذ',
                                                items: [
                                                  'قيد التنفيذ',
                                                  'جاري العمل على الطلب',
                                                  'تم التسليم',
                                                  'تم التسليم بعد التعديل',
                                                  'تم الرفض تواصل مع الدعم',
                                                ].map((status) {
                                                  return DropdownMenuItem<String>(
                                                    value: status,
                                                    child: Text(status, style: TextStyle(fontSize: 14, color: textColor)),
                                                  );
                                                }).toList(),
                                                onChanged: canEditStatus
                                                    ? (newValue) {
                                                  updateField(request.id, 'status', newValue!);
                                                  setState(() {
                                                    requestData['status'] = newValue;
                                                  });
                                                }
                                                    : null,
                                              ),
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

  Widget _buildReadOnlyRow(Map<String, dynamic> requestData, String fieldKey, String label, Color textColor) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontSize: 16, color: textColor)),
        IconButton(
          icon: Icon(Icons.copy, color: textColor),
          onPressed: () => copyToClipboard(requestData[fieldKey]?.toString() ?? ''),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (fieldKey == 'tiktokLink') {
                _launchURL(requestData[fieldKey]?.toString() ?? '');
              }
            },
            child: Text(
              requestData[fieldKey]?.toString() ?? '',
              style: TextStyle(fontSize: 16, color: fieldKey == 'tiktokLink' ? Colors.blue : textColor, decoration: fieldKey == 'tiktokLink' ? TextDecoration.underline : null),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRowWithDialog(DocumentSnapshot request, Map<String, dynamic> requestData, String fieldKey, String label, Color textColor) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontSize: 16, color: textColor)),
        IconButton(
          icon: Icon(Icons.edit, color: Colors.black),
          onPressed: () {
            TextEditingController dialogController = TextEditingController(text: requestData[fieldKey]?.toString() ?? '');
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('تعديل $label'),
                  content: TextField(
                    controller: dialogController,
                    decoration: InputDecoration(hintText: 'أدخل التعديل هنا'),
                    maxLines: 3,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () {
                        updateField(request.id, fieldKey, dialogController.text);
                        setState(() {
                          requestData[fieldKey] = dialogController.text;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text('إرسال'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        Expanded(
          child: Text(requestData[fieldKey]?.toString() ?? '', style: TextStyle(fontSize: 16, color: textColor)),
        ),
      ],
    );
  }
}
