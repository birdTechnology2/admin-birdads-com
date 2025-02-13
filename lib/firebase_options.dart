// ملف: lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' // إضافة الفاصلة المنقوطة هنا
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// اتبع الدليل لتهيئة Firebase لفلاتر:
// https://firebase.flutter.dev/docs/overview#initializing-flutterfire
const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyACWEwXvznddfmxSfgPiwUGU1X8XUPCEmk',
  authDomain: 'birdy-d8157.firebaseapp.com',
  projectId: 'birdy-d8157',
  storageBucket: 'birdy-d8157.appspot.com',
  messagingSenderId: '843123500831',
  appId: '1:843123500831:web:70d372c601d7059cdf322a',
  measurementId: 'G-82GCLGJS0N',
);
