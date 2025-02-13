import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_menu.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bulkMessageController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _rowsPerPage = 10;

  Future<void> _sendNotification(String message, String email) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': message,
        'email': email,
        'sender': 'الادارة',
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال الإشعار بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال الإشعار'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendBulkNotification(String message) async {
    final clients = await FirebaseFirestore.instance.collection('clients').get();
    for (var doc in clients.docs) {
      final data = doc.data();
      await _sendNotification(message, data['email']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // حقل البحث
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث عن العميل بالاسم أو البريد الإلكتروني',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _searchQuery = _searchController.text.trim();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    });
                  },
                  child: Text('إلغاء البحث'),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('clients').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final clients = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final firstName = data['firstName']?.toString().toLowerCase() ?? '';
                    final lastName = data['lastName']?.toString().toLowerCase() ?? '';
                    final email = data['email']?.toString().toLowerCase() ?? '';
                    final query = _searchQuery.toLowerCase();
                    return firstName.contains(query) || lastName.contains(query) || email.contains(query);
                  }).toList();

                  final paginatedClients = clients.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                  return Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(),
                          columns: [
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
                                  'البريد الإلكتروني',
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
                                  'إرسال إشعار',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: paginatedClients.asMap().entries.map((entry) {
                            final index = entry.key;
                            final doc = entry.value;
                            final data = doc.data() as Map<String, dynamic>;
                            final messageController = TextEditingController();
                            final rowColor = isDarkMode ? Colors.black : (index % 2 == 0 ? Colors.white : Colors.grey[200]);
                            final textColor = isDarkMode ? Colors.white : Colors.black;

                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                  return rowColor;
                                },
                              ),
                              cells: [
                                DataCell(Text(data['firstName'] ?? '', style: TextStyle(color: textColor))),
                                DataCell(Text(data['lastName'] ?? '', style: TextStyle(color: textColor))),
                                DataCell(Text(data['email'] ?? '', style: TextStyle(color: textColor))),
                                DataCell(
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: 200,
                                          child: TextField(
                                            controller: messageController,
                                            decoration: InputDecoration(
                                              labelText: 'رسالة',
                                              labelStyle: TextStyle(color: textColor),
                                            ),
                                            style: TextStyle(color: textColor),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.send, color: textColor),
                                        onPressed: () {
                                          final message = messageController.text;
                                          if (message.isNotEmpty) {
                                            _sendNotification(message, data['email']);
                                            messageController.clear();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildPageNumbers(context, clients.length),
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
                            onPressed: (_currentPage + 1) * _rowsPerPage < clients.length
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
            // حقل إرسال إشعار لجميع العملاء
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _bulkMessageController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'إرسال إشعار لجميع العملاء',
                      labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    maxLines: 3,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final message = _bulkMessageController.text;
                      if (message.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('تأكيد إرسال الإشعار', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                            content: Text('هل أنت متأكد من أنك تريد إرسال "$message" إلى جميع العملاء؟', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                            backgroundColor: isDarkMode ? Colors.black : Colors.white,
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('إلغاء', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                              ),
                              TextButton(
                                onPressed: () {
                                  _sendBulkNotification(message);
                                  Navigator.of(context).pop();
                                  _bulkMessageController.clear();
                                },
                                child: Text('نعم', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Text('إرسال الإشعار للجميع'),
                  ),
                ],
              ),
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
