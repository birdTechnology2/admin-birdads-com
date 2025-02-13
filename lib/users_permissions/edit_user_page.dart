// lib/users_permissions/edit_user_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserPage extends StatefulWidget {
  final DocumentSnapshot userDocument;

  EditUserPage({required this.userDocument});

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController nameController;
  late TextEditingController userNameController;
  late TextEditingController passwordController;

  Map<String, bool> permissions = {
    'permissions_clients_view': false,
    'permissions_clients_edit': false,
    'permissions_transfers_view': false,
    'permissions_transfers_edit': false,
    'permissions_send_notification_view': false,
    'permissions_send_notification_edit': false,
    'permissions_notifications_list_view': false,
    'permissions_customer_complaints_view': false,
    'permissions_customer_complaints_edit': false,
    'permissions_ads_view': false,
    'permissions_ads_edit': false,
    'permissions_customer_requests_view': false,
    'permissions_customer_requests_edit': false,
    'permissions_create_coupon_view': false,
    'permissions_create_coupon_edit': false,
    'permissions_coupon_users_view': false,
    'permissions_coupon_users_edit': false,
    'permissions_customer_statement_view': false,
    'permissions_customer_statement_edit': false,
    'permissions_management_view': false,
    'permissions_management_edit': false,
    'permissions_users_permissions_view': false,
    'permissions_users_permissions_edit': false,
  };

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.userDocument['name']);
    userNameController = TextEditingController(text: widget.userDocument['user_name']);
    passwordController = TextEditingController(text: widget.userDocument['password']);

    permissions.forEach((key, value) {
      if (widget.userDocument.data()!.toString().contains(key)) {
        permissions[key] = widget.userDocument.get(key) ?? false;
      }
    });
  }

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
        title: Text('تعديل المستخدم'),
      ),
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
                value: permissions.values.every((perm) => perm),
                onChanged: (bool? value) {
                  setState(() {
                    permissions.updateAll((key, _) => value ?? false);
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Divider(thickness: 1.5),
              ...permissions.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: permissions[key],
                        onChanged: (bool? value) {
                          setState(() {
                            permissions[key] = value ?? false;
                          });
                        },
                      ),
                      SizedBox(width: 16),
                      Text(
                        _getPermissionName(key),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
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
                      await FirebaseFirestore.instance.collection('admin users').doc(widget.userDocument.id).update({
                        'name': nameController.text,
                        'user_name': userNameController.text,
                        'password': passwordController.text,
                        ...permissions,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ التعديلات بنجاح')));
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء حفظ التعديلات: $e')));
                    }
                  },
                  child: Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPermissionName(String key) {
    Map<String, String> permissionTranslations = {
      'permissions_clients_view': 'صلاحية عرض العملاء',
      'permissions_clients_edit': 'صلاحية تعديل العملاء',
      'permissions_transfers_view': 'صلاحية عرض التحويلات',
      'permissions_transfers_edit': 'صلاحية تعديل التحويلات',
      'permissions_send_notification_view': 'صلاحية عرض الإشعار',
      'permissions_send_notification_edit': 'صلاحية إرسال إشعار',
      'permissions_notifications_list_view': 'صلاحية عرض قائمة الإشعارات',
      'permissions_customer_complaints_view': 'صلاحية عرض شكاوى العملاء',
      'permissions_customer_complaints_edit': 'صلاحية تعديل شكاوى العملاء',
      'permissions_ads_view': 'صلاحية عرض الإعلانات',
      'permissions_ads_edit': 'صلاحية تعديل الإعلانات',
      'permissions_customer_requests_view': 'صلاحية عرض طلبات العملاء',
      'permissions_customer_requests_edit': 'صلاحية تعديل طلبات العملاء',
      'permissions_create_coupon_view': 'صلاحية عرض الكوبونات',
      'permissions_create_coupon_edit': 'صلاحية تعديل الكوبونات',
      'permissions_coupon_users_view': 'صلاحية عرض مستخدمي الكوبونات',
      'permissions_coupon_users_edit': 'صلاحية تعديل مستخدمي الكوبونات',
      'permissions_customer_statement_view': 'صلاحية عرض كشف حساب العملاء',
      'permissions_customer_statement_edit': 'صلاحية تعديل كشف حساب العملاء',
      'permissions_management_view': 'صلاحية عرض الإدارة',
      'permissions_management_edit': 'صلاحية تعديل الإدارة',
      'permissions_users_permissions_view': 'صلاحية عرض المستخدمين والصلاحيات',
      'permissions_users_permissions_edit': 'صلاحية تعديل المستخدمين والصلاحيات',
    };
    return permissionTranslations[key] ?? key;
  }
}
