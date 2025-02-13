import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;

class ClientDetailsPage extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;
  final String clientId;
  ClientDetailsPage({required this.email, required this.firstName, required this.lastName, required this.clientId});

  @override
  _ClientDetailsPageState createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage> {
  final CollectionReference statements = FirebaseFirestore.instance.collection('statement');
  final CollectionReference clients = FirebaseFirestore.instance.collection('clients');
  List<Map<String, dynamic>> clientStatements = [];
  int balance = 0;
  bool isLoading = true;
  String? successMessage;
  bool canEditBalance = false;

  @override
  void initState() {
    super.initState();
    _fetchUserPermissions();
    fetchClientStatements(widget.email);
  }

  Future<void> _fetchUserPermissions() async {
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

  String formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    var formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(date);
  }

  String translateTransactionName(String transactionName) {
    if (transactionName == 'تم اضافة رصيد') {
      return 'تم إضافة الرصيد تلقائياً';
    } else if (transactionName == 'تم خصم رصيد') {
      return 'تم خصم رصيد';
    } else {
      return transactionName;
    }
  }

  Future<void> fetchClientStatements(String email) async {
    try {
      print("Fetching statements for email $email");
      final snapshot = await statements
          .where('email', isEqualTo: email)
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        clientStatements = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        balance = clientStatements.fold(0, (int sum, item) => sum + (item['addition_amount'] as int) - (item['deduction_amount'] as int));
        isLoading = false;
      });
      // Update total balance in Firestore
      await clients.doc(widget.clientId).update({'total_balance': balance});
      print("Fetched ${clientStatements.length} statements for email $email");
    } catch (e) {
      print("Error fetching statements for email $email: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteStatement(String statementId, int additionAmount, int deductionAmount) async {
    try {
      await statements.doc(statementId).delete();
      await fetchClientStatements(widget.email); // Refresh statements
      setState(() {
        successMessage = 'تم حذف المعاملة بقيمة ${additionAmount > 0 ? additionAmount : deductionAmount}';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage!)));
    } catch (e) {
      print("Error deleting statement: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في حذف المعاملة')));
    }
  }

  Future<void> downloadPDF() async {
    try {
      print("Starting PDF generation...");
      final pdf = pw.Document();
      final headers = ["Added Amount", "Deducted Amount", "Transaction Name", "Transaction Time"];
      final rows = clientStatements.map((statement) {
        return [
          statement['addition_amount'].toString(),
          statement['deduction_amount'].toString(),
          translateTransactionName(statement['transaction_name'] ?? ''),
          formatTimestamp(statement['timestamp']),
        ];
      }).toList();

      // تحميل خط Amiri من الأصول
      final ttf = await loadFontFromAsset('assets/fonts/Amiri-Regular.ttf');

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Client Details", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Email: ${widget.email}", style: pw.TextStyle(fontSize: 18)),
              pw.Text("Client ID: ${widget.clientId}", style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: headers,
                data: rows.map((row) {
                  return [
                    pw.Text(row[0], style: pw.TextStyle(color: PdfColors.green)),
                    pw.Text(row[1], style: pw.TextStyle(color: PdfColors.red)),
                    pw.Text(row[2], style: pw.TextStyle(font: ttf)),
                    pw.Text(row[3]),
                  ];
                }).toList(),
                cellAlignment: pw.Alignment.center,
                cellStyle: pw.TextStyle(fontSize: 14),
                headerStyle: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey,
                    width: 0.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Balance: ${balance.toString()}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );

      print("PDF generation completed. Starting download...");
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      print("PDF download completed.");
    } catch (e) {
      print("Error generating PDF: $e");
    }
  }

  Future<pw.Font> loadFontFromAsset(String path) async {
    try {
      final fontData = await rootBundle.load(path);
      return pw.Font.ttf(fontData);
    } catch (e) {
      print("Error loading font from asset: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final headerBackgroundColor = isDarkMode ? Colors.black : Colors.grey[200];

    return Scaffold(
      appBar: AppBar(
        title: Text('Client Details'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, // Align content to the right
            children: [
              if (successMessage != null)
                Container(
                  color: Colors.green[100],
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          successMessage!,
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 10),
              Text(
                "Client Transactions",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "First Name: ${widget.firstName}",
                style: TextStyle(fontSize: 18),
              ),
              Text(
                "Last Name: ${widget.lastName}",
                style: TextStyle(fontSize: 18),
              ),
              Text(
                "Email: ${widget.email}",
                style: TextStyle(fontSize: 18),
              ),
              Text(
                "Client ID: ${widget.clientId}",
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: TableBorder.all(),
                  columns: [
                    DataColumn(
                      label: Container(
                        color: headerBackgroundColor,
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Transaction Time',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        color: headerBackgroundColor,
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Transaction Name',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        color: headerBackgroundColor,
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Deducted Amount',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        color: headerBackgroundColor,
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Added Amount',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ),
                    if (canEditBalance)
                      DataColumn(
                        label: Container(
                          color: headerBackgroundColor,
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Actions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                      ),
                  ],
                  rows: clientStatements.map((statement) {
                    return DataRow(
                      cells: [
                        DataCell(Text(formatTimestamp(statement['timestamp']), style: TextStyle(color: textColor))),
                        DataCell(Text(translateTransactionName(statement['transaction_name'] ?? ''), style: TextStyle(color: textColor))),
                        DataCell(Text(statement['deduction_amount'].toString(), style: TextStyle(color: Colors.red))),
                        DataCell(Text(statement['addition_amount'].toString(), style: TextStyle(color: Colors.green))),
                        if (canEditBalance)
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteStatement(statement['id'], statement['addition_amount'], statement['deduction_amount']);
                              },
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width < 600 ? double.infinity : 600,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: textColor),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  "Balance: ${balance.toString()}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: downloadPDF,
                child: Text('Download All Transactions PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
