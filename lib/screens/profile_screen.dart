// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/api/api.dart';
import 'package:firebase_chat/helper/dialogs.dart';
import 'package:firebase_chat/models/chat_user.dart';
import 'package:firebase_chat/screens/view_image.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    bool keyboardIsOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text("Profile"),
            actions: [
              IconButton(
                  onPressed: () async {
                    Dialogs.showProgressBar(context);
                    await Api.updateActiveStatus(false);
                    await Api.auth.signOut().then((value) async {
                      await GoogleSignIn().signOut().then((value) {
                        Api.auth = FirebaseAuth.instance;
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false);
                      });
                    });
                  },
                  icon: const Icon(Icons.exit_to_app_rounded))
            ],
          ),
          floatingActionButton: Visibility(
            visible: !keyboardIsOpen,
            child: FloatingActionButton.extended(
              onPressed: () async {
                Dialogs.showProgressBar(context);
                await Api.updateActiveStatus(false);
                await Api.auth.signOut().then((value) async {
                  await GoogleSignIn().signOut().then((value) {
                    //replace home screen to login page
                    Api.auth = FirebaseAuth.instance;
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false);
                  });
                });
              },
              label: const Text("Logout"),
              icon: const Icon(Icons.logout_rounded),
              backgroundColor: Colors.red[800],
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            reverse: true,
            child: Center(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                                                        builder: (_) =>
                                                            ViewImage(
                                                                user: widget
                                                                    .user))),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100),
                                                  child: CachedNetworkImage(
                                                    width: 180,
                                                    height: 180,
                                                    fit: BoxFit.cover,
                                                    imageUrl: widget.user.image,
                                                    placeholder: (context,
                                                            url) =>
                                                        const CircularProgressIndicator(),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const CircleAvatar(
                                                      child: Icon(Icons.person),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        Positioned(
                                          right: -10,
                                          bottom: 0,
                                          child: MaterialButton(
                                            elevation: 1,
                                            onPressed: () {
                                              _showBottomModal();
                                            },
                                            color: Colors.white,
                                            shape: const CircleBorder(),
                                            child: const Icon(
                                              Icons.edit_square,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      data?['name'],
                                      style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      widget.user.email,
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(
                                      height: 5,
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
                      const SizedBox(height: 45),
                      const Padding(
                        padding: EdgeInsets.only(left: 3),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Edit Profile",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600))),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        cursorColor: Colors.deepOrangeAccent,
                        onSaved: (newValue) => Api.mySelf.name = newValue ?? '',
                        validator: (value) => value != null && value.isNotEmpty
                            ? null
                            : 'Name is required',
                        initialValue: widget.user.name,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.tag_faces,
                            color: Colors.deepOrangeAccent,
                          ),
                          hintText: 'eg. Verdianto',
                          label: const Text(
                            'Name',
                            style: TextStyle(color: Colors.deepOrangeAccent),
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.deepOrangeAccent)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors.deepOrangeAccent, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        cursorColor: Colors.deepOrangeAccent,
                        onSaved: (newValue) =>
                            Api.mySelf.status = newValue ?? '',
                        validator: (value) => value != null && value.isNotEmpty
                            ? null
                            : 'Status is required',
                        initialValue: widget.user.status,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.notes,
                              color: Colors.deepOrangeAccent),
                          hintText: 'eg. Busy',
                          label: const Text(
                            'Status',
                            style: TextStyle(color: Colors.deepOrangeAccent),
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.deepOrangeAccent)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.deepOrangeAccent, width: 2)),
                        ),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if ((_formKey.currentState!).validate()) {
                              _formKey.currentState!.save();
                              Api.updateUserInfo().then((value) {
                                Dialogs.showSnackBar(
                                    context,
                                    'Successfully updated!',
                                    Colors.green,
                                    SnackBarBehavior.fixed);
                              });
                              FocusScope.of(context).unfocus();
                            }
                          },
                          icon: const Icon(
                            Icons.save,
                            size: 30,
                          ),
                          label: const Text(
                            "Update",
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 1,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )),
    );
  }

  void _showBottomModal() {
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
              const Text(
                "Choose Image",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 25,
              ),
              //button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  //from gallery
                  Column(
                    children: [
                      Ink.image(
                        image: const AssetImage("assets/gallery.png"),
                        fit: BoxFit.cover,
                        width: 90,
                        height: 90,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          splashColor: Colors.white.withOpacity(0.7),
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            //pick an image
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              log('Image Path: ${image.path} -- MimeType: ${image.mimeType}');
                              //hide bottom modal
                              Navigator.pop(context);
                              setState(() {
                                _image = image.path;
                              });
                              Api.updatePicture(File(_image!));
                            }
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        "Gallery",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  //from camera
                  Column(
                    children: [
                      Ink.image(
                        image: const AssetImage("assets/camera.png"),
                        fit: BoxFit.cover,
                        width: 90,
                        height: 90,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          splashColor: Colors.white.withOpacity(0.7),
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            //pick an image
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.camera);
                            if (image != null) {
                              log('Image Path: ${image.path}');
                              //hide bottom modal
                              Navigator.pop(context);
                              setState(() {
                                _image = image.path;
                              });
                              Api.updatePicture(File(_image!));
                            }
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        "Camera",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                ],
              ),
            ],
          );
        });
  }
}
