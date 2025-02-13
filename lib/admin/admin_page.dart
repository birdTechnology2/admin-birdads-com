import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // استيراد مكتبة url_launcher
import '../main_menu.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _instapayController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _supportCallController = TextEditingController();
  final TextEditingController _supportWhatsController = TextEditingController();
  final TextEditingController _supportMessengerController = TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _cashNumber = '';
  String _instapayNumber = '';
  String _linkFb = '';
  String _nameFb = '';
  String _supportCallNumber = '';
  String _supportWhatsLink = '';
  String _supportMessengerLink = '';
  String _supportEmail = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentValues();
  }

  Future<void> _fetchCurrentValues() async {
    try {
      final docRefCash = _firestore.collection('vodaphone cash').doc('bFZ6nQi8DtndIYZKFpqN');
      final docRefFb = _firestore.collection('fb').doc('LDYHr2kvHLOl7slzEfIl');
      final docRefSupport = _firestore.collection('support').doc('7rFk8oFUoxqFi8MOPgj1');

      final docSnapshotCash = await docRefCash.get();
      final docSnapshotFb = await docRefFb.get();
      final docSnapshotSupport = await docRefSupport.get();

      if (docSnapshotCash.exists && docSnapshotFb.exists && docSnapshotSupport.exists) {
        setState(() {
          _cashNumber = docSnapshotCash.get('number cash');
          _instapayNumber = docSnapshotCash.get('instapay number');
          _linkFb = docSnapshotFb.get('link fb');
          _nameFb = docSnapshotFb.get('name fb');
          _supportCallNumber = docSnapshotSupport.get('calls num');
          _supportWhatsLink = docSnapshotSupport.get('whats num');
          _supportMessengerLink = docSnapshotSupport.get('messenger');
          _supportEmail = docSnapshotSupport.get('email supp');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('الوثيقة غير موجودة. تحقق من معرف الوثيقة.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حدث خطأ أثناء جلب البيانات: $e'),
      ));
    }
  }

  Future<void> _updateField(String collection, String field, String newValue) async {
    try {
      final docRef = _firestore.collection(collection).doc(collection == 'vodaphone cash' ? 'bFZ6nQi8DtndIYZKFpqN' : 'LDYHr2kvHLOl7slzEfIl');
      await docRef.update({field: newValue});
      setState(() {
        if (field == 'number cash') {
          _cashNumber = newValue;
          _successMessage = 'تم تغيير رقم الكاش إلى $newValue';
        } else if (field == 'instapay number') {
          _instapayNumber = newValue;
          _successMessage = 'تم تغيير رقم الانستا باي إلى $newValue';
        } else if (field == 'link fb') {
          _linkFb = newValue;
          _successMessage = 'تم تغيير رابط الاكونت إلى $newValue';
        } else if (field == 'name fb') {
          _nameFb = newValue;
          _successMessage = 'تم تغيير اسم الاكونت إلى $newValue';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم تحديث البيانات بنجاح'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حدث خطأ أثناء تحديث البيانات: $e'),
      ));
    }
  }

  Future<void> _updateSupportField(String field, String newValue) async {
    try {
      final docRef = _firestore.collection('support').doc('7rFk8oFUoxqFi8MOPgj1');
      await docRef.update({field: newValue});
      setState(() {
        if (field == 'calls num') {
          _supportCallNumber = newValue;
          _successMessage = 'تم تغيير رقم الاتصال إلى $newValue';
        } else if (field == 'whats num') {
          _supportWhatsLink = newValue;
          _successMessage = 'تم تغيير رابط الواتس اب إلى $newValue';
        } else if (field == 'messenger') {
          _supportMessengerLink = newValue;
          _successMessage = 'تم تغيير رابط الماسنجر إلى $newValue';
        } else if (field == 'email supp') {
          _supportEmail = newValue;
          _successMessage = 'تم تغيير البريد الإلكتروني إلى $newValue';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم تحديث البيانات بنجاح'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حدث خطأ أثناء تحديث البيانات: $e'),
      ));
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('الإدارة'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: MainMenu(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تعديلات من الادارة', style: TextStyle(fontSize: 24, color: textColor)),
              SizedBox(height: 20),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رقم الكاش الحالي هو: $_cashNumber', style: TextStyle(fontSize: 18, color: textColor)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cashController,
                              decoration: InputDecoration(
                                labelText: 'تغيير رقم الكاش',
                                labelStyle: TextStyle(color: textColor),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateField('vodaphone cash', 'number cash', _cashController.text);
                              _cashController.clear();
                            },
                            child: Text('حفظ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رقم الانستا باي الحالي هو: $_instapayNumber', style: TextStyle(fontSize: 18, color: textColor)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _instapayController,
                              decoration: InputDecoration(
                                labelText: 'تغيير رقم الانستا باي',
                                labelStyle: TextStyle(color: textColor),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateField('vodaphone cash', 'instapay number', _instapayController.text);
                              _instapayController.clear();
                            },
                            child: Text('حفظ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رابط الاكونت الحالي هو: '),
                      InkWell(
                        onTap: () => _launchURL(_linkFb),
                        child: Text(
                          _linkFb,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _linkController,
                              decoration: InputDecoration(
                                labelText: 'تغيير رابط الاكونت',
                                labelStyle: TextStyle(color: textColor),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateField('fb', 'link fb', _linkController.text);
                              _linkController.clear();
                            },
                            child: Text('حفظ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اسم الاكونت الحالي هو: $_nameFb', style: TextStyle(fontSize: 18, color: textColor)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'تغيير اسم الاكونت',
                                labelStyle: TextStyle(color: textColor),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateField('fb', 'name fb', _nameController.text);
                              _nameController.clear();
                            },
                            child: Text('حفظ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('الدعم', style: TextStyle(fontSize: 24, color: textColor)),
              SizedBox(height: 20),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رقم الاتصال الحالي هو: $_supportCallNumber', style: TextStyle(fontSize: 18, color: textColor)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _supportCallController,
                              decoration: InputDecoration(
                                labelText: 'تغيير رقم الاتصال',
                                labelStyle: TextStyle(color: textColor),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateSupportField('calls num', _supportCallController.text);
                              _supportCallController.clear();
                            },
                            child: Text('حفظ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رابط الواتس اب الحالي هو: '),
                      InkWell(
                        onTap: () => _launchURL(_supportWhatsLink),
                        child: Text(
                          _supportWhatsLink,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _supportWhatsController,
                              decoration: InputDecoration(
                                labelText: 'تغيير رابط الواتس اب',
                                labelStyle: TextStyle(color: textColor),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateSupportField('whats num', _supportWhatsController.text);
                              _supportWhatsController.clear();
                            },
                            child: Text('حفظ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رابط الماسنجر الحالي هو: '),
                      InkWell(
                        onTap: () => _launchURL(_supportMessengerLink),
                        child: Text(
                          _supportMessengerLink,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _supportMessengerController,
                              decoration: InputDecoration(
                                labelText: 'تغيير رابط الماسنجر',
                                labelStyle: TextStyle(color: textColor),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateSupportField('messenger', _supportMessengerController.text);
                              _supportMessengerController.clear();
                            },
                            child: Text('حفظ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('البريد الإلكتروني الحالي هو: $_supportEmail', style: TextStyle(fontSize: 18, color: textColor)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _supportEmailController,
                              decoration: InputDecoration(
                                labelText: 'تغيير البريد الإلكتروني',
                                labelStyle: TextStyle(color: textColor),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateSupportField('email supp', _supportEmailController.text);
                              _supportEmailController.clear();
                            },
                            child: Text('حفظ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _successMessage.isNotEmpty
                  ? Text(
                _successMessage,
                style: TextStyle(color: Colors.green, fontSize: 16),
              )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
