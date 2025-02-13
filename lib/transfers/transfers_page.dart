import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_menu.dart';

class TransfersPage extends StatefulWidget {
  @override
  _TransfersPageState createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  final Map<String, TextEditingController> _controllers = {};
  String _searchQuery = '';
  DateTime? selectedDate;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  final TextEditingController searchController = TextEditingController();
  final format = DateFormat("HH:mm, dd-MM-yyyy");

  String? successMessage;
  bool isCredit = true;
  int amount = 0;
  String firstName = '';
  String lastName = '';
  String? transactionId;
  String _dropdownValue = 'تحويل جديد';

  late Color rowBackgroundColor;
  late Color alternateRowBackgroundColor;
  bool canEditStatus = false;
  String userName = "";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    rowBackgroundColor = isDarkMode ? Colors.black : Colors.white;
    alternateRowBackgroundColor = isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;

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
          canEditStatus = (doc.data() as Map<String, dynamic>)['permissions_transfers_edit'] ?? false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    searchController.dispose();
    super.dispose();
  }

  Future<void> _updateClientBalanceAndLogTransaction(
      String email,
      int amount,
      bool isCredit,
      String firstName,
      String lastName,
      String transactionId, {
        bool isAutomatic = false,
      }) async {
    final CollectionReference clients = FirebaseFirestore.instance.collection('clients');
    final CollectionReference statements = FirebaseFirestore.instance.collection('statement');

    try {
      QuerySnapshot clientSnapshot = await clients.where('email', isEqualTo: email).limit(1).get();
      if (clientSnapshot.docs.isNotEmpty) {
        DocumentSnapshot clientDoc = clientSnapshot.docs.first;
        String clientId = clientDoc.id;
        Map<String, dynamic> clientData = clientDoc.data() as Map<String, dynamic>;

        int currentBalance = clientData['total_balance'] ?? 0;
        int newBalance = isCredit ? currentBalance + amount : currentBalance - amount;
        await clients.doc(clientId).update({'total_balance': newBalance});

        final newTransaction = {
          'ID client': clientId,
          'first name': clientData['firstName'],
          'last name': clientData['lastName'],
          'email': email,
          'addition_amount': isCredit ? amount : 0,
          'deduction_amount': isCredit ? 0 : amount,
          'timestamp': Timestamp.now(),
          'transaction_name': isCredit
              ? (isAutomatic ? 'تم إضافة الرصيد تلقائياً' : 'تم إضافة رصيد')
              : 'تم خصم رصيد',
          'related_transaction': transactionId,
        };
        await statements.add(newTransaction);

        setState(() {
          successMessage = isCredit
              ? 'تم إضافة رصيد إلى ${firstName} ${lastName} بقيمة ${amount}'
              : 'تم خصم رصيد من ${firstName} ${lastName} بقيمة ${amount}';
          this.isCredit = isCredit;
          this.amount = amount;
          this.firstName = firstName;
          this.lastName = lastName;
          this.transactionId = transactionId;
        });
      } else {
        throw Exception('Client not found');
      }
    } catch (e) {
      print("Error updating client balance and logging transaction: $e");
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التحويلات - مرحبًا بك يا $userName'),
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
                      labelText: 'بحث بالاسم أو البريد الإلكتروني أو المبلغ',
                      suffixIcon: Icon(Icons.search),
                      labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DateTimeField(
                    format: DateFormat("yyyy-MM-dd"),
                    decoration: InputDecoration(
                      labelText: 'اختر التاريخ',
                      suffixIcon: Icon(Icons.calendar_today),
                      labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
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
                      _searchQuery = "";
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
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('حدث خطأ ما!'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('لا توجد تحويلات'));
                    }

                    List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

                    if (_searchQuery.isNotEmpty || selectedDate != null) {
                      docs = docs.where((doc) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        bool matchesQuery = _searchQuery.isEmpty ||
                            data['firstName'].toString().contains(_searchQuery) ||
                            data['lastName'].toString().contains(_searchQuery) ||
                            data['email'].toString().contains(_searchQuery) ||
                            data['amount'].toString().contains(_searchQuery) ||
                            DateFormat('yyyy-MM-dd').format((data['timestamp'] as Timestamp).toDate()).contains(_searchQuery);

                        bool matchesDate = selectedDate == null ||
                            DateFormat('yyyy-MM-dd').format((data['timestamp'] as Timestamp).toDate()) ==
                                DateFormat('yyyy-MM-dd').format(selectedDate!);

                        return matchesQuery && matchesDate;
                      }).toList();
                    }

                    docs.sort((a, b) {
                      Timestamp timestampA = a['timestamp'] as Timestamp;
                      Timestamp timestampB = b['timestamp'] as Timestamp;
                      return timestampB.compareTo(timestampA);
                    });

                    final totalDocs = docs.length;
                    final paginatedDocs = docs.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                    return Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: _buildColumns(),
                            rows: _buildRows(paginatedDocs, totalDocs),
                            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.lightBlue),
                            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            dataRowColor: MaterialStateColor.resolveWith((states) => rowBackgroundColor),
                            dataTextStyle: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                            dividerThickness: 1.0,
                            border: TableBorder.all(color: Colors.grey, style: BorderStyle.solid),
                            columnSpacing: 10.0,
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
                                (docs.length / _rowsPerPage).ceil(),
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
                                        color: _currentPage == index
                                            ? Colors.white
                                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: (_currentPage + 1) * _rowsPerPage < docs.length
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
            ),
          ],
        ),
      ),
      drawer: MainMenu(),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'رقم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'الاسم الأول',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'الاسم الأخير',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'البريد الإلكتروني',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'المبلغ بالنسبة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'الرصيد المطلوب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'الملاحظات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'إيصال التحويل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'التوقيت',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      DataColumn(
        label: Container(
          color: Colors.lightBlue,
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    ];
  }

  List<DataRow> _buildRows(List<QueryDocumentSnapshot> docs, int totalDocs) {
    return docs.asMap().entries.map((entry) {
      int index = entry.key;
      DocumentSnapshot document = entry.value;
      Map<String, dynamic> data = document.data() as Map<String, dynamic>;

      if (!_controllers.containsKey(document.id)) {
        _controllers[document.id] = TextEditingController();
      }

      DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
      String formattedDate = DateFormat('HH:mm, dd-MM-yyyy').format(timestamp);

      String statusValue = data['status'] ?? 'تحويل جديد';

      return DataRow(
        color: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          return index % 2 == 0 ? alternateRowBackgroundColor : rowBackgroundColor;
        }),
        cells: [
          DataCell(Center(child: Text('${totalDocs - (index + (_currentPage * _rowsPerPage))}'))),
          DataCell(Center(child: Text(data['firstName'] ?? ''))),
          DataCell(Center(child: Text(data['lastName'] ?? ''))),
          DataCell(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Center(child: Text(data['email'] ?? ''))),
                IconButton(
                  icon: Icon(Icons.copy, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: data['email']));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ البريد الإلكتروني')));
                  },
                ),
              ],
            ),
          ),
          DataCell(Center(child: Text(data['amount'].toString()))),
          DataCell(Center(child: Text(data['amount_required']?.toString() ?? ''))),
          DataCell(Center(child: Text(data['note'] ?? ''))),
          DataCell(
            Center(
              child: data['screenshotUrl'] != null
                  ? InkWell(
                child: Text(
                  'عرض الإيصال',
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
                onTap: () => _launchURL(data['screenshotUrl']),
              )
                  : Text('لا يوجد'),
            ),
          ),
          DataCell(Center(child: Text(formattedDate))),
          DataCell(
            canEditStatus
                ? DropdownButton<String>(
              value: statusValue,
              onChanged: (String? newValue) async {
                if (newValue == 'تم التحقق وتم اضافة الرصيد' && data['status'] != 'تم التحقق وتم اضافة الرصيد') {
                  int requiredAmount = int.parse(data['amount_required']);
                  await _updateClientBalanceAndLogTransaction(data['email'], requiredAmount, true, data['firstName'], data['lastName'], document.id, isAutomatic: true);
                }
                await FirebaseFirestore.instance.collection('transactions').doc(document.id).update({'status': newValue});
                setState(() {
                  statusValue = newValue!;
                  data['status'] = newValue;
                });
              },
              items: <String>[
                'تم التحقق وتم اضافة الرصيد',
                'تحويل جديد',
                'رسالة مكررة بالخطأ',
                'تم التحقق ولم يتم التحويل',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            )
                : Center(
              child: Text(
                statusValue,
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}
