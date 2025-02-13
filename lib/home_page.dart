// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html; // استخدام HTML Audio API للتعامل مع تشغيل الصوت
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'main.dart';
import 'main_menu.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  int lastNewTransfersCount = 0;
  int lastAdsInReviewCount = 0;
  int lastCustomerRequestsCount = 0;
  bool notificationsEnabled = true;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    requestNotificationPermission();
    setupFirebaseMessaging();
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

  void requestNotificationPermission() {
    html.Notification.requestPermission().then((permission) {
      if (permission == 'granted') {
        print("Notification permission granted");
      } else {
        print("Notification permission denied");
      }
    });
  }

  void setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (notificationsEnabled) {
        showNotification(message.notification?.title ?? 'Notification', message.notification?.body ?? '');
        playNotificationSound();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tapped logic here.
    });

    // طلب التوكن وحفظه في قاعدة البيانات
    messaging.getToken().then((String? token) {
      if (token != null) {
        print('Token retrieved successfully: $token');
        saveTokenToFirestore(token);
      } else {
        print('Failed to retrieve token');
      }
    }).catchError((error) {
      print('Error retrieving token: $error');
    });
  }

  // دالة لحفظ التوكن في Firestore
  void saveTokenToFirestore(String token) {
    if (userName.isNotEmpty) {
      FirebaseFirestore.instance.collection('user_tokens').doc(userName).set({
        'token': token,
      }).then((_) {
        print('Token saved successfully');
      }).catchError((error) {
        print('Error saving token to Firestore: $error');
      });
    } else {
      print('Username is empty, cannot save token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصفحة الرئيسية'),
        actions: [
          IconButton(
            icon: Icon(App.themeNotifier.value == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: () {
              App.themeNotifier.value =
              App.themeNotifier.value == ThemeMode.light
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),
          IconButton(
            icon: Icon(notificationsEnabled ? Icons.notifications : Icons.notifications_off),
            onPressed: () {
              setState(() {
                notificationsEnabled = !notificationsEnabled;
              });
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: App.themeNotifier.value == ThemeMode.light
                ? [Colors.teal[200]!, Colors.teal[700]!]
                : [Colors.grey[850]!, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName.isNotEmpty
                      ? 'مرحبًا بك في تطبيق بيرد ادز ادمن  يا ا/$userName'
                      : 'مرحبًا بك في التطبيق الخاص بك!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: App.themeNotifier.value == ThemeMode.light
                        ? Colors.teal[900]
                        : Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                buildCard(
                  context,
                  icon: Icons.transform,
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('status', isEqualTo: 'تحويل جديد')
                      .snapshots(),
                  title: 'عدد التحويلات الجديدة: ',
                  lastCount: lastNewTransfersCount,
                  onUpdate: (newCount) {
                    if (notificationsEnabled && newCount > lastNewTransfersCount) {
                      showNotification('طلب تحويل جديد!', 'هناك طلب تحويل جديد في النظام');
                      playNotificationSound();
                    }
                    lastNewTransfersCount = newCount;
                  },
                ),
                buildCard(
                  context,
                  icon: Icons.ad_units,
                  stream: FirebaseFirestore.instance
                      .collection('created ads')
                      .where('status', isEqualTo: 'في المراجعة من الادارة')
                      .snapshots(),
                  title: 'عدد الإعلانات في مرحلة المراجعة: ',
                  lastCount: lastAdsInReviewCount,
                  onUpdate: (newCount) {
                    if (notificationsEnabled && newCount > lastAdsInReviewCount) {
                      showNotification('إعلان جديد في المراجعة!', 'هناك إعلان جديد ينتظر المراجعة');
                      playNotificationSound();
                    }
                    lastAdsInReviewCount = newCount;
                  },
                ),
                buildCard(
                  context,
                  icon: Icons.request_page,
                  stream: FirebaseFirestore.instance
                      .collection('customer requests')
                      .where('action', whereIn: [
                    'طلب جديد',
                    'تعديل اخر',
                    'طلب إيقاف الإعلان',
                    'طلب تعديل علي الاستهداف لتحسين النتائج',
                    'تزويد الإعلان',
                    'تشغيل الإعلان',
                    'استكمال الإعلان',
                  ])
                      .snapshots(),
                  title: 'عدد طلبات العملاء الجديدة: ',
                  lastCount: lastCustomerRequestsCount,
                  onUpdate: (newCount) {
                    if (notificationsEnabled && newCount > lastCustomerRequestsCount) {
                      showNotification('طلب عميل جديد!', 'هناك طلب جديد من أحد العملاء');
                      playNotificationSound();
                    }
                    lastCustomerRequestsCount = newCount;
                  },
                ),
                buildTotalBalanceCard(
                  context,
                  icon: Icons.account_balance,
                  stream: FirebaseFirestore.instance.collection('clients').snapshots(),
                  title: 'إجمالي الأرصدة: ',
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: MainMenu(),
    );
  }

  Widget buildCard(BuildContext context,
      {required IconData icon,
        required Stream<QuerySnapshot> stream,
        required String title,
        required int lastCount,
        required Function(int) onUpdate}) {
    return Card(
      elevation: 10,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('حدث خطأ ما!');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            int count = snapshot.data?.docs.length ?? 0;
            onUpdate(count);

            return Row(
              children: [
                Icon(icon, color: Colors.teal[900]),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$title $count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: App.themeNotifier.value == ThemeMode.light
                          ? Colors.teal[900]
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildTotalBalanceCard(BuildContext context,
      {required IconData icon,
        required Stream<QuerySnapshot> stream,
        required String title}) {
    return Card(
      elevation: 10,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('حدث خطأ ما!');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            num totalBalance = 0;
            snapshot.data?.docs.forEach((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('total_balance')) {
                totalBalance += (data['total_balance'] ?? 0) as num;
              }
            });

            return Row(
              children: [
                Icon(icon, color: Colors.teal[900]),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$title ${totalBalance.toInt()}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: App.themeNotifier.value == ThemeMode.light
                          ? Colors.teal[900]
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void playNotificationSound() {
    if (notificationsEnabled) {
      final audio = html.AudioElement('assets/notification.mp3');
      audio.play();
    }
  }

  void showNotification(String title, String body) {
    if (notificationsEnabled) {
      html.Notification.requestPermission().then((permission) {
        if (permission == 'granted') {
          html.Notification(title, body: body);
        } else {
          print("Notification permission not granted");
        }
      });
    }
  }
}