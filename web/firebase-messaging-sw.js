importScripts('https://www.gstatic.com/firebasejs/9.17.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.17.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyACWEwXvznddfmxSfgPiwUGU1X8XUPCEmk',
  authDomain: 'birdy-d8157.firebaseapp.com',
  projectId: 'birdy-d8157',
  storageBucket: 'birdy-d8157.appspot.com',
  messagingSenderId: '843123500831',
  appId: '1:843123500831:web:70d372c601d7059cdf322a',
  measurementId: 'G-82GCLGJS0N',
});

const messaging = firebase.messaging();

// Handling background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message: ', payload);
  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body || 'You have received a new message.',
    icon: payload.notification?.icon || '/assets/icon.png', // استخدم آيكون مناسب
  };

  // Show notification
  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', function(event) {
  console.log('Notification click Received: ', event);
  event.notification.close();
  event.waitUntil(
    clients.openWindow('https://alkawasir.online')
  );
});
