// الكود بالكامل بعد إضافة التعديل

// lib/users_permissions/create_user_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_menu.dart';

class CreateUserPage extends StatefulWidget {
  @override
  _CreateUserPageState createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final nameController = TextEditingController();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();

  Map<String, Map<String, bool>> permissions = {
    'العملاء': {'مشاهدة': false, 'تعديل': false},
    'التحويلات': {'مشاهدة': false, 'تعديل': false},
    'إرسال إشعار للعملاء': {'مشاهدة': false, 'تعديل': false},
    'قائمة الإشعارات': {'مشاهدة': false, 'تعديل': false},
    'شكاوى العملاء': {'مشاهدة': false, 'تعديل': false},
    'الإعلانات': {'مشاهدة': false, 'تعديل': false},
    'طلبات العملاء': {'مشاهدة': false, 'تعديل': false},
    'إنشاء كوبون': {'مشاهدة': false, 'تعديل': false},
    'مستخدمين الكوبونات': {'مشاهدة': false, 'تعديل': false},
    'كشف حساب العملاء': {'مشاهدة': false, 'تعديل': false},
    'الإدارة': {'مشاهدة': false, 'تعديل': false},
    'المستخدمين والصلاحيات': {'مشاهدة': false, 'تعديل': false},
  };

  @override
  void dispose() {
    nameController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إنشاء مستخدم جديد'),
      ),
      drawer: MainMenu(),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: userNameController,
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'الباصورد',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              CheckboxListTile(
                title: Text('صلاحيات كاملة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                value: permissions.values.every((perm) => perm['مشاهدة']! && perm['تعديل']!),
                onChanged: (bool? value) {
                  setState(() {
                    permissions.forEach((key, perm) {
                      perm['مشاهدة'] = value ?? false;
                      perm['تعديل'] = value ?? false;
                    });
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Divider(thickness: 1.5),
              ...permissions.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: permissions[key]!['مشاهدة'],
                            onChanged: (bool? value) {
                              setState(() {
                                permissions[key]!['مشاهدة'] = value ?? false;
                              });
                            },
                          ),
                          Text('مشاهدة', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 20),
                          Checkbox(
                            value: permissions[key]!['تعديل'],
                            onChanged: (bool? value) {
                              setState(() {
                                permissions[key]!['تعديل'] = value ?? false;
                              });
                            },
                          ),
                          Text('تعديل', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 32.0),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty || userNameController.text.isEmpty || passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('من فضلك املأ جميع الحقول')));
                      return;
                    }
                    try {
                      final newUserDoc = FirebaseFirestore.instance.collection('admin users').doc();
                      await newUserDoc.set({
                        'uid': newUserDoc.id,
                        'name': nameController.text,
                        'user_name': userNameController.text,
                        'password': passwordController.text,
                        // التعديل: تغيير طريقة تخزين الصلاحيات لتكون في حقول منفصلة
                        'permissions_clients_view': true,
                        'permissions_clients_edit': true,
                        'permissions_transfers_view': true,
                        'permissions_transfers_edit': true,
                        'permissions_send_notification_view': true,
                        'permissions_send_notification_edit': true,
                        'permissions_notifications_list_view': true,
                        'permissions_notifications_list_edit': true,
                        'permissions_customer_complaints_view': true,
                        'permissions_customer_complaints_edit': true,
                        'permissions_ads_view': true,
                        'permissions_ads_edit': true,
                        'permissions_customer_requests_view': true,
                        'permissions_customer_requests_edit': true,
                        'permissions_create_coupon_view': true,
                        'permissions_create_coupon_edit': true,
                        'permissions_coupon_users_view': true,
                        'permissions_coupon_users_edit': true,
                        'permissions_customer_statement_view': true,
                        'permissions_customer_statement_edit': true,
                        'permissions_management_view': true,
                        'permissions_management_edit': true,
                        'permissions_users_permissions_view': true,
                        'permissions_users_permissions_edit': true,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء الحساب بنجاح')));
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إنشاء الحساب: $e')));
                    }
                  },
                  child: Text('إنشاء حساب', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

