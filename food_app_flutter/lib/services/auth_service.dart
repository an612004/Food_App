// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
  try {
    // Đảm bảo đăng xuất Google & Firebase trước khi đăng nhập lại
    await _googleSignIn.signOut();
    await _auth.signOut();

    // Bước 1: Mở hộp thoại chọn tài khoản Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    // Bước 2: Lấy thông tin xác thực
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Bước 3: Tạo credential cho Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Bước 4: Đăng nhập Firebase bằng credential
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  } catch (e) {
    print('Lỗi đăng nhập Google: $e');
    return null;
  }
}


  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
