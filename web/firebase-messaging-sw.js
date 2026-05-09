importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAaKIRybj9Dm2tZYsJDSIKi0rKNjpnwkaA",
  authDomain: "sk-school-master.firebaseapp.com",
  projectId: "sk-school-master",
  storageBucket: "sk-school-master.firebasestorage.app",
  messagingSenderId: "836702428678",
  appId: "1:836702428678:web:0744a0e5276096fd1bad87"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
