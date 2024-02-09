import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat/api/api.dart';
import 'package:firebase_chat/helper/my_date_util.dart';
import 'package:firebase_chat/models/chat_user.dart';
import 'package:firebase_chat/screens/view_image.dart';
import 'package:flutter/material.dart';

class ViewUserProfile extends StatefulWidget {
  final ChatUser user;
  const ViewUserProfile({super.key, required this.user});

  @override
  State<ViewUserProfile> createState() => _ViewUserProfileState();
}

class _ViewUserProfileState extends State<ViewUserProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.user.name),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Joined on ",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black),
            ),
            Text(
              MyDateUtil.getLastMessageTime(
                  context: context,
                  time: widget.user.createdAt,
                  showYear: true),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.black54),
            )
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: Api.getUserData(widget.user.id),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const Center(
                              child: CircularProgressIndicator());
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.data();
                          return Column(
                            children: [
                              Stack(
                                children: [
                                  data?['image'] == ''
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          child: Image.asset(
                                            "assets/noimage.png",
                                            width: 180,
                                            height: 180,
                                            fit: BoxFit.cover,
                                          ))
                                      : GestureDetector(
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => ViewImage(
                                                      user: widget.user))),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            child: CachedNetworkImage(
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              imageUrl: widget.user.image,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const CircleAvatar(
                                                child: Icon(Icons.person),
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                widget.user.email,
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey.shade600),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                data?['status'],
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                      }
                    }),
              ],
            ),
          ),
        ));
  }
}
