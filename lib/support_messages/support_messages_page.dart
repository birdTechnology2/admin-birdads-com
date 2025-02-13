import 'package:flutter/material.dart';
import '../main_menu.dart'; // تأكد من استيراد MainMenu

class SupportMessagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('رسائل الدعم'),
      ),
      body: Center(
        child: Text('صفحة رسائل الدعم'),
      ),
      drawer: MainMenu(), // إضافة القائمة الرئيسية كـ Drawer
    );
  }
}
