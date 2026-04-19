import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static Object? _initializationError;

  static bool get isInitialized => Firebase.apps.isNotEmpty;
  static Object? get initializationError => _initializationError;

  static Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    _initializationError = null;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (error) {
      _initializationError = error;
      rethrow;
    }
  }
}
