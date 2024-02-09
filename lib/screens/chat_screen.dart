// ignore_for_file: non_constant_identifier_names

import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_chat/api/api.dart';
import 'package:firebase_chat/helper/my_date_util.dart';
import 'package:firebase_chat/models/chat_user.dart';
import 'package:firebase_chat/models/message.dart';
import 'package:firebase_chat/screens/view_user_profile.dart';
import 'package:firebase_chat/widgets/message_card.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _list = [];
  //handle message text changes
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showEmoji = false;
  bool _is_uploading = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if (_showEmoji) {
              setState(() {
                _showEmoji = !_showEmoji;
                _focusNode.requestFocus();
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 255, 244, 241),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appbar(),
            ),
            body: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder(
                        stream: Api.getAllMessages(widget.user),
                        builder: (context, snapshot) {
                          switch (snapshot.connectionState) {
                            //if data is loading

                            case ConnectionState.waiting:
                            case ConnectionState.none:
                              return const SizedBox();

                            //if some data is loaded
                            case ConnectionState.active:
                            case ConnectionState.done:
                              final data = snapshot.data?.docs;
                              _list = data
                                      ?.map((e) => Message.fromJson(e.data()))
                                      .toList() ??
                                  [];

                              if (_list.isNotEmpty) {
                                return ListView.builder(
                                  reverse: true,
                                  shrinkWrap: true,
                                  itemCount: _list.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return MessageCard(
                                      message: _list[index],
                                    );
                                  },
                                );
                              } else {
                                return const SizedBox();
                              }
                          }
                        }),
                  ),
                  (_is_uploading)
                      ? const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const SizedBox(),

                  //Chat input
                  _chatInput(),

                  //Show Emoji
                  (_showEmoji)
                      ? SizedBox(
                          height: 280,
                          child: EmojiPicker(
                            textEditingController: _textController,
                            onBackspacePressed: () {},
                            config: Config(
                              bgColor: const Color.fromARGB(255, 255, 229, 221),
                              columns: 7,
                              initCategory: Category.SMILEYS,
                              emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                              indicatorColor: Colors.deepOrangeAccent,
                              iconColorSelected: Colors.deepOrangeAccent,
                              verticalSpacing: 0,
                              backspaceColor: Colors.deepOrangeAccent,
                              recentTabBehavior: RecentTabBehavior.RECENT,
                              recentsLimit: 28,
                              noRecents: const Text(
                                'No Recents',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.black26),
                                textAlign: TextAlign.center,
                              ), // Needs to be const Widget
                              loadingIndicator: const SizedBox
                                  .shrink(), // Needs to be const Widget
                              tabIndicatorAnimDuration: kTabScrollDuration,
                              categoryIcons: const CategoryIcons(),
                              buttonMode: ButtonMode.MATERIAL,
                            ),
                          ),
                        )
                      : const SizedBox()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appbar() {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ViewUserProfile(user: widget.user)));
      },
      child: StreamBuilder(
          stream: Api.getAnyUserInfo(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

            return Row(
              children: [
                //back button
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    )),
                //user PP
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: CachedNetworkImage(
                    width: 50,
                    height: 50,
                    imageUrl:
                        list.isNotEmpty ? list[0].image : widget.user.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                  ),
                ),

                //
                const SizedBox(
                  width: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.isNotEmpty ? list[0].name : widget.user.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      list.isNotEmpty
                          ? list[0].isOnline
                              ? 'Online'
                              : MyDateUtil.getLastActiveTime(
                                  context: context,
                                  lastActive: list[0].lastActive)
                          : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: widget.user.lastActive),
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400),
                    )
                  ],
                ),
              ],
            );
          }),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        if (MediaQuery.of(context).viewInsets.bottom != 0) {
                          Future.delayed(
                            const Duration(milliseconds: 200),
                            () {
                              setState(() {
                                _showEmoji = !_showEmoji;
                              });
                            },
                          );
                        } else {
                          setState(() {
                            _showEmoji = !_showEmoji;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.emoji_emotions_rounded,
                        color: Colors.deepOrangeAccent,
                      )),
                  Expanded(
                      child: TextField(
                    focusNode: _focusNode,
                    onTap: () {
                      setState(() {
                        if (_showEmoji) {
                          _showEmoji = !_showEmoji;
                        }
                      });
                    },
                    autocorrect: false,
                    cursorColor: Colors.deepOrangeAccent,
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: const InputDecoration(
                        hintText: "Type here...",
                        hintStyle: TextStyle(color: Colors.deepOrangeAccent),
                        border: InputBorder.none),
                  )),
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        //pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 80);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() => _is_uploading = true);
                          await Api.sendImage(widget.user, File(image.path));
                          setState(() => _is_uploading = false);
                        }
                      },
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.deepOrangeAccent,
                      )),
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        //pick an image
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 80);
                        for (var i in images) {
                          log('Image Path: ${i.path}');
                          setState(() => _is_uploading = true);

                          await Api.sendImage(widget.user, File(i.path));
                          setState(() => _is_uploading = false);
                        }
                        if (images.isNotEmpty) {}
                      },
                      icon: const Icon(
                        Icons.image_rounded,
                        color: Colors.deepOrangeAccent,
                      )),
                ],
              ),
            ),
          ),
          //send message button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  Api.sendFirstMessage(
                      widget.user, _textController.text, Type.text);
                } else {
                  Api.sendMessage(widget.user, _textController.text, Type.text);
                }
                _textController.text = '';
              }
            },
            minWidth: 0,
            padding:
                const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 5),
            shape: const CircleBorder(),
            color: Colors.deepOrangeAccent,
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 25,
            ),
          )
        ],
      ),
    );
  }
}
