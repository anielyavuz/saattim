import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<Map> anonymSignIn() async {
    Map returnCode = {};
    try {
      var user = await _auth.signInAnonymously();

      await _firestore.collection("Users").doc(user.user!.uid).set({
        "userName": "Guest",
        "email": "",
        "photoUrl": "",
        "registerType": "Anonym",
        "id": user.user!.uid,
        "userAuth": "Prod",
        "userSubscription": "Free",
        "createTime":
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()).toString(),
      });
    } on FirebaseAuthException catch (e) {
      returnCode['status'] = false;
      returnCode['value'] = e.code;
      print('Failed with error code: ${e.code}');
      print(e.message);
    }
    return returnCode;
  }

  Future appleLoginFromMainPage() async {
    // 1. perform the sign-in request
    final result = await TheAppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);
    print(result.error);
    // 2. check the result
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = result.credential!;
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          accessToken:
              String.fromCharCodes(appleIdCredential.authorizationCode!),
        );

        final newUser = await _auth.signInWithCredential(credential);
        final firebaseUser = newUser.user!;
        print("AAAAAAAAAAAAA11");
        // print(newUser.user!.uid);
        print(newUser.user);

        await _firestore.collection("Users").doc(newUser.user!.uid).set({
          "userName": newUser.user!.displayName != null
              ? newUser.user!.displayName
              : "KiWi User",
          "email": newUser.user!.email != null ? newUser.user!.email : "",
          "photoUrl": newUser.user!.photoURL != null
              ? newUser.user!.photoURL
              : "https://firebasestorage.googleapis.com/v0/b/kiwihabitapp-5f514.appspot.com/o/kiwiLogo.png?alt=media&token=90320926-0ff1-4fc8-a3eb-62c9d85e0ef0",
          "registerType": "Apple",
          "id": newUser.user!.uid,
          "userAuth": "Prod",
          "userSubscription": "Free",
        }).then((value) async {
          //silemedik çünkü user log out oldu ve yetkisi gitti...
          // var k = await FirebaseFirestore.instance
          //     .collection("Users")
          //     .doc(anonymData['id'])
          //     .delete();
        });
      // if (!doesGoogleUserExist(newUser.user!.uid)) {
      //   await _firestore.collection("Users").doc(newUser.user!.uid).set(anonymData);
      // }
      case AuthorizationStatus.cancelled:
      // TODO: Handle this case.
      case AuthorizationStatus.error:
      // TODO: Handle this case.
    }
  }

  signOut() async {
    return await _auth.signOut();
  }
}
