// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/api/api.dart';
import 'package:firebase_chat/helper/dialogs.dart';
import 'package:firebase_chat/main.dart';
import 'package:firebase_chat/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..forward();
  late final Animation<double> _animation =
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _handleGoogleBtn() {
    //showing progress bar
    Dialogs.showProgressBar(context);

    _signInWithGoogle().then((user) async {
      //hide progress bar
      Navigator.pop(context);

      if (user != null) {
        log('\nUser: ${user.user}');
        log('\nUserAditionalInfo: ${user.additionalUserInfo}');
        if (await Api.userExists()) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          await Api.createNewUser().then((value) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      //triger authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      //obtain the auth detail from request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      //create new credential
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);

      return await Api.auth.signInWithCredential(credential);
    } catch (e) {
      log('\n_signInWithGoogle: $e');
      Dialogs.showSnackBar(context, 'Something went wrong, check your internet',
          Colors.red.withOpacity(0.8), SnackBarBehavior.floating);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Welcome"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ScaleTransition(
                scale: _animation,
                child: SizedBox(
                  width: 350,
                  height: 350,
                  child: Image.asset(
                    "assets/logo.png",
                  ),
                ),
              ),
              SizedBox(
                width: mq.width * .8,
                height: mq.height * .07,
                child: ElevatedButton(
                  onPressed: () {
                    _handleGoogleBtn();
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 1,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const BeveledRectangleBorder(
                          side: BorderSide(color: Colors.grey))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Image.asset("assets/google.png")),
                      ),
                      const Text(
                        "Sign In with Google",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
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
