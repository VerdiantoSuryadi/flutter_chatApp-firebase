// ignore_for_file: avoid_unnecessary_containers

import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_chat/api/api.dart';
import 'package:firebase_chat/helper/dialogs.dart';
import 'package:firebase_chat/helper/my_date_util.dart';
import 'package:firebase_chat/main.dart';
import 'package:firebase_chat/models/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';

class MessageCard extends StatefulWidget {
  final Message message;
  const MessageCard({super.key, required this.message});

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    bool isSender = Api.user.uid == widget.message.from;
    return InkWell(
      onLongPress: () {
        _showBottomModal(isSender);
      },
      child: isSender ? _orangeMessage() : _blueMessage(),
    );
  }

  //sender message
  Widget _blueMessage() {
    //update last read message  if sender and receiver are different
    if (widget.message.read.isEmpty) {
      Api.updateReadStatus(widget.message);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: widget.message.type == Type.text
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            margin: const EdgeInsets.only(bottom: 5),
            width: widget.message.type == Type.image ? mq.width * 0.7 : null,
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 157, 211, 255),
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20))),
            child: widget.message.type == Type.text
                ? Text(
                    widget.message.msg,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w300),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const CircleAvatar(
                        child: Icon(
                          Icons.image,
                          size: 70,
                        ),
                      ),
                    ),
                  ),
          ),
          Text(
            MyDateUtil.getFormattedTime(
                context: context, time: widget.message.sent),
            style: const TextStyle(color: Colors.black45, fontSize: 10),
          ),
          const SizedBox(
            height: 5,
          ),
        ],
      ),
    );
  }

  //our message
  Widget _orangeMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: widget.message.type == Type.text
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            margin: const EdgeInsets.only(bottom: 5),
            width: widget.message.type == Type.image ? mq.width * 0.7 : null,
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 168, 142),
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20))),
            child: widget.message.type == Type.text
                ? Text(
                    widget.message.msg,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w300),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const CircleAvatar(
                        child: Icon(
                          Icons.image,
                          size: 70,
                        ),
                      ),
                    ),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                MyDateUtil.getFormattedTime(
                    context: context, time: widget.message.sent),
                style: const TextStyle(color: Colors.black45, fontSize: 10),
              ),
              const SizedBox(
                width: 3,
              ),
              widget.message.read.isNotEmpty
                  ? const Icon(
                      Icons.done_all_rounded,
                      color: Colors.deepOrange,
                    )
                  : const Icon(
                      Icons.done,
                      color: Colors.deepOrange,
                    )
            ],
          ),
          const SizedBox(
            height: 5,
          )
        ],
      ),
    );
  }

  void _showBottomModal(bool isSender) {
    showModalBottomSheet(
        backgroundColor: Colors.white,
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              Container(
                height: 5,
                margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.4,
                    vertical: 10),
                decoration: const BoxDecoration(color: Colors.grey),
              ),
              if (widget.message.type == Type.image && !isSender)
                //copy text
                _ItemOption(
                    icon: const Icon(
                      Icons.save_rounded,
                      color: Colors.deepOrangeAccent,
                    ),
                    name: 'Save Image',
                    onTap: () async {
                      try {
                        log('Image URL: ${widget.message.msg}');
                        await GallerySaver.saveImage(widget.message.msg,
                                albumName: 'ChatApp')
                            .then((success) {
                          Navigator.pop(context);
                          if (success != null && success) {
                            Dialogs.showSnackBar(
                                context,
                                'Image Saved',
                                Colors.deepOrangeAccent.withOpacity(0.8),
                                SnackBarBehavior.fixed);
                          }
                        });
                      } catch (e) {
                        log("Error: $e");
                        Dialogs.showSnackBar(context, 'Error: $e', Colors.red,
                            SnackBarBehavior.fixed);
                      }
                    }),
              if (widget.message.type == Type.text)
                //copy text
                _ItemOption(
                    icon: const Icon(
                      Icons.copy_all_rounded,
                      color: Colors.deepOrangeAccent,
                    ),
                    name: 'Copy Text',
                    onTap: () async {
                      await Clipboard.setData(
                              ClipboardData(text: widget.message.msg))
                          .then((value) {
                        Navigator.pop(context);
                        Dialogs.showSnackBar(
                            context,
                            'Text Copied!',
                            Colors.deepOrangeAccent.withOpacity(0.8),
                            SnackBarBehavior.fixed);
                      });
                    }),
              if (widget.message.type == Type.text && isSender)
                //edit option
                _ItemOption(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.deepOrangeAccent,
                    ),
                    name: 'Edit Message',
                    onTap: () {
                      Navigator.pop(context);
                      _showMessageModal();
                    }),
              if (isSender)
                //delete option
                _ItemOption(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.deepOrangeAccent,
                    ),
                    name: 'Delete Message',
                    onTap: () async {
                      await Api.deleteMessage(widget.message).then((value) {
                        Navigator.pop(context);
                        Dialogs.showSnackBar(
                            context,
                            'Delete success',
                            Colors.deepOrangeAccent.withOpacity(0.8),
                            SnackBarBehavior.fixed);
                      });
                    }),
            ],
          );
        });
  }

  void _showMessageModal() {
    String message = widget.message.msg;
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Edit Message",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            onChanged: (value) => message = value,
                            validator: (value) =>
                                value != null && value.isNotEmpty
                                    ? null
                                    : 'Field is required!',
                            initialValue: message,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10)),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if ((_formKey.currentState!).validate()) {
                                  _formKey.currentState!.save();
                                  Navigator.pop(context);
                                  Api.updateMessage(widget.message, message)
                                      .then((value) => Dialogs.showSnackBar(
                                          context,
                                          'Message updated',
                                          Colors.deepOrangeAccent
                                              .withOpacity(0.8),
                                          SnackBarBehavior.fixed));
                                  FocusScope.of(context).unfocus();
                                }
                              },
                              icon: const Icon(
                                Icons.save,
                                size: 20,
                              ),
                              label: const Text(
                                "Update",
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                  elevation: 1,
                                  backgroundColor: Colors.deepOrangeAccent),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => Navigator.pop(context),
                      child: const CircleAvatar(
                          backgroundColor: Colors.deepOrangeAccent,
                          child: Icon(
                            Icons.clear,
                            color: Colors.white,
                          )),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItemOption extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;
  const _ItemOption(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            icon,
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                name,
                style: const TextStyle(
                    fontSize: 16, color: Colors.black54, letterSpacing: 0.5),
              ),
            )
          ],
        ),
      ),
    );
  }
}
