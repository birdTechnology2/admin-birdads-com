import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_user_page.dart';
import 'edit_user_page.dart';

class UsersPermissionsPage extends StatefulWidget {
  @override
  _UsersPermissionsPageState createState() => _UsersPermissionsPageState();
}

class _UsersPermissionsPageState extends State<UsersPermissionsPage> {
  List<DocumentSnapshot> _userDocuments = [];
  int _expandedIndex = -1;

  Map<String, String> permissionTranslations = {
    'permissions_ads_edit': 'صلاحية تعديل الإعلانات',
    'permissions_ads_view': 'صلاحية عرض الإعلانات',
    'permissions_clients_edit': 'صلاحية تعديل العملاء',
    'permissions_clients_view': 'صلاحية عرض العملاء',
    'permissions_coupon_users_edit': 'صلاحية تعديل مستخدمي الكوبونات',
    'permissions_coupon_users_view': 'صلاحية عرض مستخدمي الكوبونات',
    'permissions_create_coupon_edit': 'صلاحية تعديل الكوبونات',
    'permissions_create_coupon_view': 'صلاحية عرض الكوبونات',
    'permissions_customer_complaints_edit': 'صلاحية تعديل شكاوى العملاء',
    'permissions_customer_complaints_view': 'صلاحية عرض شكاوى العملاء',
    'permissions_customer_requests_edit': 'صلاحية تعديل طلبات العملاء',
    'permissions_customer_requests_view': 'صلاحية عرض طلبات العملاء',
    'permissions_management_edit': 'صلاحية تعديل الإدارة',
    'permissions_management_view': 'صلاحية عرض الإدارة',
    'permissions_notifications_list_view': 'صلاحية عرض قائمة الإشعارات',
    'permissions_notifications_list_edit': 'صلاحية تعديل قائمة الإشعارات',
    'permissions_send_notification_edit': 'صلاحية إرسال إشعار',
    'permissions_transfers_edit': 'صلاحية تعديل التحويلات',
    'permissions_transfers_view': 'صلاحية عرض التحويلات',
    'permissions_users_permissions_edit': 'صلاحية تعديل المستخدمين والصلاحيات',
    'permissions_users_permissions_view': 'صلاحية عرض المستخدمين والصلاحيات',
    'permissions_send_notification_view': 'صلاحية عرض الإشعار',
    'permissions_customer_statement_view': 'صلاحية عرض كشف حساب العملاء',
    'permissions_customer_statement_edit': 'صلاحية تعديل كشف حساب العملاء',
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('admin users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('المستخدمين والصلاحيات'),
            ),
            body: Center(child: Text('حدث خطأ أثناء استرجاع البيانات')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('المستخدمين والصلاحيات'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _userDocuments = snapshot.data!.docs;

        return Scaffold(
          appBar: AppBar(
            title: Text('المستخدمين والصلاحيات'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateUserPage()),
                    );
                  },
                  child: Text('إنشاء حساب', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          drawer: MainMenu(),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: _userDocuments.length,
              itemBuilder: (context, index) {
                Color tileColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                final data = _userDocuments[index].data() as Map<String, dynamic>;
                return Container(
                  color: tileColor,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ExpansionTile(
                    title: Text(
                      data['name'] ?? 'بدون اسم',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: _expandedIndex == index,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedIndex = expanded ? index : -1;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('الاسم: ', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8.0),
                                Text(data['name'] ?? '', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Text('اسم المستخدم: ', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8.0),
                                Text(data['user_name'] ?? '', style: TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: data['user_name'] ?? ''));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم نسخ اسم المستخدم')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Text('كلمة السر: ', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8.0),
                                Text(data['password'] ?? '', style: TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: data['password'] ?? ''));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم نسخ كلمة السر')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Text('UID: ', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 8.0),
                                Text(data['uid'] ?? '', style: TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: data['uid'] ?? ''));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم نسخ UID')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Text('الصلاحيات المتاحة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: data.keys
                                  .where((key) => key.startsWith('permissions_'))
                                  .map((key) {
                                String permissionName = permissionTranslations[key] ?? key;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: data[key] ?? false,
                                        onChanged: null,
                                        activeColor: Colors.grey,
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        permissionName,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 16.0),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => EditUserPage(userDocument: _userDocuments[index])),
                                    );
                                  },
                                  child: Text('تعديل', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('حذف المستخدم'),
                                        content: Text('هل ترغب في حذف المستخدم؟'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('لا', style: TextStyle(color: Colors.white)),
                                            style: TextButton.styleFrom(backgroundColor: Colors.grey),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('admin users')
                                                  .doc(_userDocuments[index].id)
                                                  .delete()
                                                  .then((_) => Navigator.of(context).pop());
                                            },
                                            child: Text('نعم', style: TextStyle(color: Colors.white)),
                                            style: TextButton.styleFrom(backgroundColor: Colors.red),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Text('حذف', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
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
        );
      },
    );
  }
}
