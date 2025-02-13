import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_menu.dart';
import 'client_details_page.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

class CustomerAccountStatementPage extends StatefulWidget {
  @override
  _CustomerAccountStatementPageState createState() => _CustomerAccountStatementPageState();
}

class _CustomerAccountStatementPageState extends State<CustomerAccountStatementPage> {
  final CollectionReference clients = FirebaseFirestore.instance.collection('clients');
  final CollectionReference statements = FirebaseFirestore.instance.collection('statement');
  String searchQuery = "";
  DateTime? selectedDate;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController minBalanceController = TextEditingController();
  final TextEditingController maxBalanceController = TextEditingController();
  final format = DateFormat("yyyy-MM-dd HH:mm");
  String? successMessage;
  bool isCredit = true;
  int amount = 0;
  String userName = "";
  bool canEditBalance = false;

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

  void _fetchUserName() async {
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
          canEditBalance = (doc.data() as Map<String, dynamic>)['permissions_customer_statement_edit'] ?? false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    minBalanceController.dispose();
    maxBalanceController.dispose();
    super.dispose();
  }

  String formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    return format.format(date);
  }

  String maskString(String input) {
    if (input.length <= 3) return input;
    return input.substring(0, 3) + '...';
  }

  Future<void> updateStatement(String email, int additionAmount, int deductionAmount) async {
    final transactionName = additionAmount > 0 ? 'تم إضافة رصيد' : 'تم خصم رصيد';
    final newTransaction = {
      'email': email,
      'addition_amount': additionAmount,
      'deduction_amount': deductionAmount,
      'timestamp': Timestamp.now(),
      'transaction_name': transactionName,
    };
    await statements.add(newTransaction);

    QuerySnapshot clientSnapshot = await clients.where('email', isEqualTo: email).limit(1).get();
    if (clientSnapshot.docs.isNotEmpty) {
      DocumentSnapshot clientDoc = clientSnapshot.docs.first;
      int currentBalance = clientDoc['total_balance'] ?? 0;
      int newBalance = currentBalance + additionAmount - deductionAmount;
      await clients.doc(clientDoc.id).update({'total_balance': newBalance});

      setState(() {
        successMessage = additionAmount > 0
            ? 'تم إضافة رصيد إلى ${email} بقيمة ${additionAmount}'
            : 'تم خصم رصيد من ${email} بقيمة ${deductionAmount}';
        isCredit = additionAmount > 0;
        amount = additionAmount > 0 ? additionAmount : deductionAmount;
      });
    } else {
      throw Exception('Client not found');
    }
  }

  Future<int> fetchClientBalance(String clientId) async {
    try {
      DocumentSnapshot clientDoc = await clients.doc(clientId).get();
      if (clientDoc.exists) {
        return clientDoc['total_balance'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
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
        title: Text('كشف حساب العملاء - مرحبًا بك يا $userName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (successMessage != null)
              Container(
                color: isCredit ? Colors.green[100] : Colors.red[100],
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        successMessage!,
                        style: TextStyle(
                          color: isCredit ? Colors.green : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      amount.toString(),
                      style: TextStyle(
                        color: isCredit ? Colors.green : Colors.red,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 10),
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      minBalanceController.clear();
                      maxBalanceController.clear();
                      searchQuery = "";
                      selectedDate = null;
                    });
                  },
                  child: Text('إلغاء البحث'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minBalanceController,
                    decoration: InputDecoration(
                      labelText: 'الحد الأدنى للرصيد',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: maxBalanceController,
                    decoration: InputDecoration(
                      labelText: 'الحد الأقصى للرصيد',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // This triggers the filtering of data based on balance range
                    });
                  },
                  child: Text('فلتر بالرصيد'),
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

                  final minBalance = int.tryParse(minBalanceController.text) ?? 0;
                  final maxBalance = int.tryParse(maxBalanceController.text) ?? double.maxFinite.toInt();

                  final data = snapshot.requireData.docs.where((doc) {
                    final clientData = doc.data() as Map<String, dynamic>;
                    final matchesQuery = clientData['firstName'].toString().contains(searchQuery) ||
                        clientData['email'].toString().contains(searchQuery);
                    final balance = clientData['total_balance'] ?? 0;
                    final matchesBalance = balance >= minBalance && balance <= maxBalance;
                    return matchesQuery && matchesBalance;
                  }).toList();

                  final paginatedClients = data.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border: TableBorder.all(),
                            columns: [
                              DataColumn(
                                label: Container(
                                  color: tableHeaderColor,
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'رقم',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  color: tableHeaderColor,
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'ID العميل',
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
                                    'البريد الإلكتروني',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  color: tableHeaderColor,
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'اخر تحديث',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  color: tableHeaderColor,
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'الرصيد',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              if (canEditBalance) ...[
                                DataColumn(
                                  label: Container(
                                    color: tableHeaderColor,
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'اضافة رصيد',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Container(
                                    color: tableHeaderColor,
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'خصم رصيد',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                              DataColumn(
                                label: Container(
                                  color: tableHeaderColor,
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'التفاصيل',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                            rows: paginatedClients.asMap().entries.map((entry) {
                              final index = entry.key;
                              final client = entry.value;
                              final clientData = client.data() as Map<String, dynamic>;
                              final rowColor = tableRowColor(index);
                              final TextEditingController additionController = TextEditingController();
                              final TextEditingController deductionController = TextEditingController();
                              final clientEmail = clientData['email'];

                              return DataRow(
                                color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                  return rowColor;
                                }),
                                cells: [
                                  DataCell(Text('${data.length - (_currentPage * _rowsPerPage + index)}', style: TextStyle(color: textColor))), // رقم العميل تنازلي
                                  DataCell(
                                    Row(
                                      children: [
                                        Expanded(child: Text(maskString(clientData['uid']?.toString() ?? ''), style: TextStyle(color: textColor))),
                                        SizedBox(width: 5),
                                        IconButton(
                                          icon: Icon(Icons.copy, color: textColor),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: clientData['uid']?.toString() ?? ''));
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ ID العميل')));
                                          },
                                        ),
                                      ],
                                    ),
                                  ), // ID العميل
                                  DataCell(Text(clientData['firstName']?.toString() ?? '', style: TextStyle(color: textColor))),
                                  DataCell(Text(clientData['lastName']?.toString() ?? '', style: TextStyle(color: textColor))),
                                  DataCell(
                                    Row(
                                      children: [
                                        Expanded(child: Text(maskString(clientData['email']?.toString() ?? ''), style: TextStyle(color: textColor))),
                                        SizedBox(width: 5),
                                        IconButton(
                                          icon: Icon(Icons.copy, color: textColor),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: clientData['email']?.toString() ?? ''));
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ البريد الإلكتروني')));
                                          },
                                        ),
                                      ],
                                    ),
                                  ), // البريد الإلكتروني
                                  DataCell(
                                    StreamBuilder<QuerySnapshot>(
                                      stream: statements
                                          .where('email', isEqualTo: clientData['email'])
                                          .orderBy('timestamp', descending: true)
                                          .limit(1)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                          return Text('', style: TextStyle(color: textColor));
                                        }
                                        final lastTransaction = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                                        final lastTimestamp = lastTransaction['timestamp'] as Timestamp;
                                        return Text(formatTimestamp(lastTimestamp), style: TextStyle(color: textColor));
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    FutureBuilder<int>(
                                      future: fetchClientBalance(client.id),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        }
                                        if (snapshot.hasError) {
                                          return Text('خطأ', style: TextStyle(color: textColor));
                                        }
                                        return Text(snapshot.data?.toString() ?? '0', style: TextStyle(color: textColor));
                                      },
                                    ),
                                  ), // الرصيد
                                  if (canEditBalance) ...[
                                    DataCell(
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: additionController,
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                labelText: '',
                                                labelStyle: TextStyle(color: textColor),
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: textColor),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: textColor),
                                                ),
                                              ),
                                              style: TextStyle(color: textColor),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add_circle, color: Colors.green),
                                            onPressed: () async {
                                              final amount = int.tryParse(additionController.text);
                                              if (amount != null) {
                                                await updateStatement(clientData['email'], amount, 0);
                                                additionController.clear();
                                                setState(() {}); // إعادة بناء الواجهة لتحديث الرسالة
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: deductionController,
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                labelText: '',
                                                labelStyle: TextStyle(color: textColor),
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: textColor),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: textColor),
                                                ),
                                              ),
                                              style: TextStyle(color: textColor),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () async {
                                              final amount = int.tryParse(deductionController.text);
                                              if (amount != null) {
                                                await updateStatement(clientData['email'], 0, amount);
                                                deductionController.clear();
                                                setState(() {}); // إعادة بناء الواجهة لتحديث الرسالة
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ClientDetailsPage(
                                              email: clientEmail,
                                              firstName: clientData['firstName'],
                                              lastName: clientData['lastName'],
                                              clientId: clientData['uid'].toString(),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text('إظهار'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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
