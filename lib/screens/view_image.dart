import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_chat/models/chat_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ViewImage extends StatelessWidget {
  final ChatUser user;
  const ViewImage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarDividerColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light),
        centerTitle: false,
        title: Text(
          user.name,
          style: const TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: InteractiveViewer(
            panAxis: PanAxis.free,
            panEnabled: true,
            minScale: 1,
            maxScale: 5,
            child: CachedNetworkImage(
              imageUrl: user.image,
             
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ),
    );
  }
}
