import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firestore 直読み前に `request.auth != null` を満たす。
Future<void> ensureSignedInForFirestore(FirebaseApp app) async {
  final auth = FirebaseAuth.instanceFor(app: app);
  if (auth.currentUser != null) {
    return;
  }
  await auth.signInAnonymously();
}
