import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add this function to manage login status
Future<void> setLoggedInStatus(bool status) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_logged_in', status);
  bool currentStatus = prefs.getBool('is_logged_in') ?? false;
  print('Logged in status set to: \$status, Current status in SharedPreferences: \$currentStatus');
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('saved_username');
    String? savedPassword = prefs.getString('saved_password');
    bool? rememberMe = prefs.getBool('remember_me');

    if (rememberMe == true) {
      setState(() {
        _usernameController.text = savedUsername ?? '';
        _passwordController.text = savedPassword ?? '';
        _rememberMe = rememberMe ?? false;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    // Check Firebase Firestore collection 'admin_users'
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('admin users')
          .where('user_name', isEqualTo: username)
          .get();

      if (query.docs.isNotEmpty) {
        var userData = query.docs.first;
        print('User found: \${userData.data()}'); // Debugging statement
        if (userData['password'] == password) {
          if (_rememberMe) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('saved_username', username);
            await prefs.setString('saved_password', password);
            await prefs.setBool('remember_me', true);
          } else {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_username');
            await prefs.remove('saved_password');
            await prefs.setBool('remember_me', false);
          }

          // Update login status
          await setLoggedInStatus(true);

          // Navigate to Home Page if user is found
          context.go('/');
        } else {
          // Show error message if password is incorrect
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('كلمة المرور غير صحيحة')),
          );
        }
      } else {
        // Show error message if user is not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('اسم المستخدم غير صحيح')),
        );
      }
    } catch (e) {
      print('Error: $e'); // Debugging statement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 50),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'اسم المستخدم',
                  prefixIcon: Icon(Icons.person, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock, color: Colors.blue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blue,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                obscureText: _obscurePassword,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  Text(
                    'تذكرني',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _login,
                child: Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
