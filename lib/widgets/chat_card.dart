import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_chat/api/api.dart';
import 'package:firebase_chat/helper/my_date_util.dart';
import 'package:firebase_chat/models/chat_user.dart';
import 'package:firebase_chat/models/message.dart';
import 'package:firebase_chat/screens/chat_screen.dart';
import 'package:firebase_chat/screens/dialog/profile_dialog.dart';
import 'package:flutter/material.dart';

class ChatCard extends StatefulWidget {
  final ChatUser user;
  const ChatCard({super.key, required this.user});

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  Message? _message;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
        child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatScreen(
                            user: widget.user,
                          )));
            },
            child: StreamBuilder(
              stream: Api.getLastMsg(widget.user),
              builder: (context, snapshot) {
                final data = snapshot.data?.docs;
                final list =
                    data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
                if (list.isNotEmpty) {
                  _message = list[0];
                }
                return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                    title: Text(widget.user.name),
                    subtitle: Text(
                      _message != null
                          ? _message!.type == Type.image
                              ? 'Image'
                              : _message!.msg
                          : widget.user.status,
                      maxLines: 1,
                    ),
                    leading: InkWell(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) =>  ProfileDialog(user: widget.user,));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: CachedNetworkImage(
                          width: 55,
                          height: 55,
                          imageUrl: widget.user.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                        ),
                      ),
                    ),
                    trailing: _message == null
                        ? null
                        : _message!.read.isEmpty &&
                                _message!.from != Api.user.uid
                            ? Container(
                                width: 15,
                                height: 15,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(10)),
                              )
                            : Text(
                                MyDateUtil.getLastMessageTime(
                                    context: context, time: _message!.sent),
                                style: const TextStyle(color: Colors.black54),
                              ));
              },
            )),
      ),
    );
  }
}
