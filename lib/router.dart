// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'clients/clients_page.dart';
import 'customer_complaints/customer_complaints_page.dart';
import 'notifications/NotificationLogPage.dart';
import 'notifications/notifications_page.dart';
import 'transfers/transfers_page.dart';
import 'home_page.dart';
import 'ads_page/ads_page.dart';
import 'coupon/create_coupon_page.dart';
import 'coupon/coupon_users_page.dart';
import 'customer_account_statement.dart';
import 'admin/admin_page.dart';
import 'customer_requests/customer_requests_page.dart';
import 'users_permissions/users_permissions_page.dart';
import 'login_page.dart';
import 'other_requests/content_requests.dart';
import 'other_requests/design_requests.dart';
import 'other_requests/video_requests.dart';
import 'other_requests/ready_facebook_pages.dart';
import 'other_requests/ready_tiktok_account.dart';
import 'other_requests/tiktok_followers.dart';
import 'other_requests/facebook_followers.dart';

// Add this function to check login status
Future<bool> isLoggedIn() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_logged_in') ?? false;
}

Future<void> setLoggedInStatus(bool status) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_logged_in', status);
}

final GoRouter router = GoRouter(
  initialLocation: '/login', // Start with login page if not logged in
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomePage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) => ClientsPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/transfers',
      builder: (context, state) => TransfersPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationsPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/notification_log',
      builder: (context, state) => NotificationLogPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/ads',
      builder: (context, state) => AdsPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/create_coupon',
      builder: (context, state) => CreateCouponPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/coupon_users',
      builder: (context, state) => CouponUsersPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/customer_account_statement',
      builder: (context, state) => CustomerAccountStatementPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => AdminPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/customer_requests',
      builder: (context, state) => CustomerRequestsPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/users_permissions',
      builder: (context, state) => UsersPermissionsPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/customer_complaints',
      builder: (context, state) => CustomerComplaintsPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/tiktok_followers',
      builder: (context, state) => TikTokFollowersPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/facebook_followers',
      builder: (context, state) => FacebookFollowersPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/content_requests',
      builder: (context, state) => ContentRequestsPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/design_requests',
      builder: (context, state) => DesignRequestsPage(), // لو الصفحة في lib/other_requests/design_requests.dart
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),

    GoRoute(
      path: '/video_requests',
      builder: (context, state) => VideoRequestsPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/ready_facebook_pages',
      builder: (context, state) => ReadyFacebookPagesPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/ready_tiktok_account',
      builder: (context, state) => ReadyTiktokAccountPage(),
      redirect: (context, state) async {
        if (!await isLoggedIn()) {
          return '/login';
        }
        return null;
      },
    ),
    // Add similar redirects for all other routes except '/login'
    GoRoute(
      path: '/login',
      builder: (context, state) {
        print('Navigating to LoginPage...');
        return LoginPage();
      },
      redirect: (context, state) async {
        if (await isLoggedIn()) {
          print('User is already logged in, redirecting to home...');
          return '/';
        }
        return null;
      },
    ),
  ],
);

// Function to handle logout
dynamic logout(BuildContext context) async {
  await setLoggedInStatus(false);
  await Future.delayed(Duration(milliseconds: 100));
  bool isLoggedOut = !await isLoggedIn();
  print('User status set to logged out: \$isLoggedOut');
  print('User status set to logged out');
  router.go('/login');
}

