import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYrPr9OnNe72p6DLAx6VBqJcefXLTVSXo',
    appId: '1:973149968770:web:4b42b73c504fc5aaf7d79b',
    messagingSenderId: '973149968770',
    projectId: 'dump-and-drop',
    authDomain: 'dump-and-drop.firebaseapp.com',
    storageBucket: 'dump-and-drop.firebasestorage.app',
    measurementId: 'G-28VG2GZX8Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrvc2i3CE767hzhpjpSs-CfgwUTkFfdSE',
    appId: '1:973149968770:android:06edfa2de0d1a111f7d79b',
    messagingSenderId: '973149968770',
    projectId: 'dump-and-drop',
    storageBucket: 'dump-and-drop.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChkhE6yyCi8ioLONlhBcRUzuzdDOimsH0',
    appId: '1:973149968770:ios:a0b5b6caab7009bcf7d79b',
    messagingSenderId: '973149968770',
    projectId: 'dump-and-drop',
    storageBucket: 'dump-and-drop.firebasestorage.app',
    iosBundleId: 'com.example.dumpAndDrop',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyChkhE6yyCi8ioLONlhBcRUzuzdDOimsH0',
    appId: '1:973149968770:ios:a0b5b6caab7009bcf7d79b',
    messagingSenderId: '973149968770',
    projectId: 'dump-and-drop',
    storageBucket: 'dump-and-drop.firebasestorage.app',
    iosBundleId: 'com.example.dumpAndDrop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBYrPr9OnNe72p6DLAx6VBqJcefXLTVSXo',
    appId: '1:973149968770:web:d2bd854a34e6b1aaf7d79b',
    messagingSenderId: '973149968770',
    projectId: 'dump-and-drop',
    authDomain: 'dump-and-drop.firebaseapp.com',
    storageBucket: 'dump-and-drop.firebasestorage.app',
    measurementId: 'G-C7ZQ6BF2J3',
  );
}
