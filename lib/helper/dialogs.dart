import 'package:flutter/material.dart';

class Dialogs {
  static void showSnackBar(BuildContext context, String msg, Color color,
      SnackBarBehavior behavior) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      behavior: behavior,
      duration: const Duration(seconds: 2),
    ));
  }

  static void showProgressBar(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => const Center(
              child: CircularProgressIndicator(),
            ));
  }


}
