// lib/main_menu.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:admin/router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';



class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/logo.png'),
                    ),
                    SizedBox(width: 15),
                    Text(
                      'القائمة الرئيسية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                FutureBuilder<DocumentSnapshot?> (
                  future: _getUserDocument(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(color: Colors.white);
                    } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                      print('Error or document does not exist: \${snapshot.error}');
                      return Text('خطأ في التحميل', style: TextStyle(color: Colors.white));
                    } else {
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      String userName = data['user_name'] ?? 'مستخدم';
                      return Center(
                        child: Text(
                          userName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.home,
            title: 'الصفحة الرئيسية',
            route: '/',
          ),
          FutureBuilder<DocumentSnapshot?>(
            future: _getUserDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Waiting for Firestore document...');
                return CircularProgressIndicator();
              } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                print('Error or document does not exist: \${snapshot.error}');
                return SizedBox();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                print('Data retrieved from Firestore: \$data');
                bool canViewClients = data['permissions_clients_view'] ?? false;
                print('Permission to view clients: \$canViewClients');
                return canViewClients
                    ? _buildMenuItem(
                  context,
                  icon: Icons.person,
                  title: 'العملاء',
                  route: '/clients',
                )
                    : SizedBox();
              }
            },
          ),
          FutureBuilder<DocumentSnapshot?>(
            future: _getUserDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Waiting for Firestore document...');
                return CircularProgressIndicator();
              } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                print('Error or document does not exist: \${snapshot.error}');
                return SizedBox();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                print('Data retrieved from Firestore: \$data');
                bool canViewTransfers = data['permissions_transfers_view'] ?? false;
                print('Permission to view transfers: \$canViewTransfers');
                return canViewTransfers
                    ? _buildMenuItem(
                  context,
                  icon: Icons.transfer_within_a_station,
                  title: 'التحويلات',
                  route: '/transfers',
                )
                    : SizedBox();
              }
            },
          ),
          _buildExpandableMenuItem(
            context,
            icon: Icons.notifications,
            title: 'الإشعارات',
            children: [
              FutureBuilder<DocumentSnapshot?> (
                future: _getUserDocument(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('Waiting for Firestore document...');
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                    print('Error or document does not exist: \${snapshot.error}');
                    return SizedBox();
                  } else {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    print('Data retrieved from Firestore: \$data');
                    bool canSendNotification = data['permissions_send_notification_view'] ?? false;
                    print('Permission to send notifications: \$canSendNotification');
                    return canSendNotification
                        ? _buildMenuItem(
                      context,
                      icon: Icons.send,
                      title: 'إرسال إشعار للعملاء',
                      route: '/notifications',
                    )
                        : SizedBox();
                  }
                },
              ),
              FutureBuilder<DocumentSnapshot?> (
                future: _getUserDocument(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('Waiting for Firestore document...');
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                    print('Error or document does not exist: \${snapshot.error}');
                    return SizedBox();
                  } else {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    print('Data retrieved from Firestore: \$data');
                    bool canViewNotificationsList = data['permissions_notifications_list_view'] ?? false;
                    print('Permission to view notifications list: \$canViewNotificationsList');
                    return canViewNotificationsList
                        ? _buildMenuItem(
                      context,
                      icon: Icons.list,
                      title: 'قائمة الإشعارات',
                      route: '/notification_log',
                    )
                        : SizedBox();
                  }
                },
              ),
            ],
          ),
          FutureBuilder<DocumentSnapshot?> (
            future: _getUserDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Waiting for Firestore document...');
                return CircularProgressIndicator();
              } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                print('Error or document does not exist: \${snapshot.error}');
                return SizedBox();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                print('Data retrieved from Firestore: \$data');
                bool canViewCustomerComplaints = data['permissions_customer_complaints_view'] ?? false;
                print('Permission to view customer complaints: \$canViewCustomerComplaints');
                return canViewCustomerComplaints
                    ? _buildMenuItem(
                  context,
                  icon: Icons.report_problem,
                  title: 'شكاوى العملاء',
                  route: '/customer_complaints',
                )
                    : SizedBox();
              }
            },
          ),
          FutureBuilder<DocumentSnapshot?> (
            future: _getUserDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Waiting for Firestore document...');
                return CircularProgressIndicator();
              } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                print('Error or document does not exist: \${snapshot.error}');
                return SizedBox();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                print('Data retrieved from Firestore: \$data');
                bool canViewAds = data['permissions_ads_view'] ?? false;
                print('Permission to view ads: \$canViewAds');
                return canViewAds
                    ? _buildMenuItem(
                  context,
                  icon: Icons.ad_units,
                  title: 'الإعلانات',
                  route: '/ads',
                )
                    : SizedBox();
              }
            },
          ),
          FutureBuilder<DocumentSnapshot?> (
            future: _getUserDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Waiting for Firestore document...');
                return CircularProgressIndicator();
              } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                print('Error or document does not exist: \${snapshot.error}');
                return SizedBox();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                print('Data retrieved from Firestore: \$data');
                bool canViewCustomerRequests = data['permissions_customer_requests_view'] ?? false;
                print('Permission to view customer requests: \$canViewCustomerRequests');
                return canViewCustomerRequests
                    ? _buildMenuItem(
                  context,
                  icon: Icons.request_page,
                  title: 'طلبات العملاء',
                  route: '/customer_requests',
                )
                    : SizedBox();
              }
            },
          ),
          _buildExpandableMenuItem(
            context,
            icon: Icons.card_giftcard,
            title: 'الكوبونات',
            children: [
              FutureBuilder<DocumentSnapshot?> (
                future: _getUserDocument(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('Waiting for Firestore document...');
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                    print('Error or document does not exist: \${snapshot.error}');
                    return SizedBox();
                  } else {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    print('Data retrieved from Firestore: \$data');
                    bool canCreateCoupon = data['permissions_create_coupon_view'] ?? false;
                    print('Permission to create coupon: \$canCreateCoupon');
                    return canCreateCoupon
                        ? _buildMenuItem(
                      context,
                      icon: Icons.add,
                      title: 'إنشاء كوبون',
                      route: '/create_coupon',
                    )
                        : SizedBox();
                  }
                },
              ),
              FutureBuilder<DocumentSnapshot?> (
                future: _getUserDocument(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('Waiting for Firestore document...');
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                    print('Error or document does not exist: \${snapshot.error}');
                    return SizedBox();
                  } else {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    print('Data retrieved from Firestore: \$data');
                    bool canViewCouponUsers = data['permissions_coupon_users_view'] ?? false;
                    print('Permission to view coupon users: \$canViewCouponUsers');
                    return canViewCouponUsers
                        ? _buildMenuItem(
                      context,
                      icon: Icons.list,
                      title: 'مستخدمين الكوبونات',
                      route: '/coupon_users',
                    )
                        : SizedBox();
                  }
                },
              ),
            ],
          ),
          _buildExpandableMenuItem(
            context,
            icon: Icons.more_horiz,
            title: 'طلبات أخرى',
            children: [
              _buildMenuItem(
                context,
                icon: Icons.people,
                title: 'تزويد متابعين تيك توك',
                route: '/tiktok_followers',
              ),
              _buildMenuItem(
                context,
                icon: Icons.people,
                title: 'تزويد متابعين فيس بوك',
                route: '/facebook_followers',
              ),
              _buildMenuItem(
                context,
                icon: Icons.content_paste,
                title: 'طلبات المحتوى',
                route: '/content_requests',
              ),
              _buildMenuItem(
                context,
                icon: Icons.design_services,
                title: 'طلبات التصميمات',
                route: '/design_requests',
              ),
              _buildMenuItem(
                context,
                icon: Icons.videocam,
                title: 'طلبات الفيديوهات',
                route: '/video_requests',
              ),
              _buildMenuItem(
                context,
                icon: Icons.pageview,
                title: 'صفحات فيس جاهزة',
                route: '/ready_facebook_pages',
              ),
              _buildMenuItem(
                context,
                icon: Icons.account_box,
                title: 'أكونت تيك توك جاهز',
                route: '/ready_tiktok_account',
              ),
            ],
          ),
          FutureBuilder<DocumentSnapshot?> (
            future: _getUserDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Waiting for Firestore document...');
                return CircularProgressIndicator();
              } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                print('Error or document does not exist: \${snapshot.error}');
                return SizedBox();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                print('Data retrieved from Firestore: \$data');
                bool canViewCustomerStatement = data['permissions_customer_statement_view'] ?? false;
                print('Permission to view customer statement: \$canViewCustomerStatement');
                return canViewCustomerStatement
                    ? _buildMenuItem(
                  context,
                  icon: Icons.account_balance,
                  title: 'كشف حساب العملاء',
                  route: '/customer_account_statement',
                )
                    : SizedBox();
              }
            },
          ),
          FutureBuilder<DocumentSnapshot?> (
            future: _getUserDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Waiting for Firestore document...');
                return CircularProgressIndicator();
              } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                print('Error or document does not exist: \${snapshot.error}');
                return SizedBox();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                print('Data retrieved from Firestore: \$data');
                bool canViewManagement = data['permissions_management_view'] ?? false;
                print('Permission to view management: \$canViewManagement');
                return canViewManagement
                    ? _buildMenuItem(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'الإدارة',
                  route: '/admin',
                )
                    : SizedBox();
              }
            },
          ),
          FutureBuilder<DocumentSnapshot?> (
            future: _getUserDocument(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('Waiting for Firestore document...');
                return CircularProgressIndicator();
              } else if (snapshot.hasError || snapshot.data == null || !snapshot.data!.exists) {
                print('Error or document does not exist: \${snapshot.error}');
                return SizedBox();
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                print('Data retrieved from Firestore: \$data');
                bool canViewUsersPermissions = data['permissions_users_permissions_view'] ?? false;
                print('Permission to view users permissions: \$canViewUsersPermissions');
                return canViewUsersPermissions
                    ? _buildMenuItem(
                  context,
                  icon: Icons.group,
                  title: 'المستخدمين والصلاحيات',
                  route: '/users_permissions',
                )
                    : SizedBox();
              }
            },
          ),
          Divider(),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Future<DocumentSnapshot?> _getUserDocument() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('saved_username');

    if (savedUsername != null) {
      // Get user document from Firestore based on the saved username
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('admin users')
          .where('user_name', isEqualTo: savedUsername)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        print('Document data from Firestore: \${doc.data()}');
        return doc;
      } else {
        print('No document found for the logged-in user');
        return null;
      }
    } else {
      print('No username found in SharedPreferences');
      return null;
    }
  }


  Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String title, required String route}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        print('Navigating to route: \$route');
        context.go(route);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildExpandableMenuItem(BuildContext context,
      {required IconData icon, required String title, required List<Widget> children}) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      children: children,
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.red),
      title: Text(
        'تسجيل الخروج',
        style: TextStyle(color: Colors.red),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('تأكيد تسجيل الخروج'),
              content: Text('هل ترغب بتسجيل الخروج؟'),
              actions: [
                TextButton(
                  child: Text('لا', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('نعم', style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await setLoggedInStatus(false);
                    context.go('/login');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
