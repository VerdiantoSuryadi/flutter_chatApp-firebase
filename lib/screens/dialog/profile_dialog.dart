import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_chat/models/chat_user.dart';
import 'package:firebase_chat/screens/chat_screen.dart';
import 'package:firebase_chat/screens/view_image.dart';
import 'package:firebase_chat/screens/view_user_profile.dart';
import 'package:flutter/material.dart';

class ProfileDialog extends StatelessWidget {
  final ChatUser user;
  const ProfileDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 60),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 350,
                child: GestureDetector(
                  onTap: () {
                   Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ViewImage(user: user,)));
                  },
                  child: CachedNetworkImage(
                    imageUrl: user.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.grey.withOpacity(0.8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: Text(
                    user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                ),
              )
            ],
          ),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ViewUserProfile(user: user)));
                    },
                    child: const SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: Icon(
                        Icons.info_rounded,
                        color: Colors.blue,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(
                    color: Colors.grey, thickness: 1, width: 0),
                Flexible(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChatScreen(user: user)));
                    },
                    child: const SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: Icon(
                        Icons.chat_rounded,
                        color: Colors.blue,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
