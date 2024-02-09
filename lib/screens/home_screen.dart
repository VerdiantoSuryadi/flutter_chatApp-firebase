import 'dart:developer';

import 'package:firebase_chat/api/api.dart';
import 'package:firebase_chat/helper/dialogs.dart';
import 'package:firebase_chat/screens/profile_screen.dart';
import 'package:firebase_chat/widgets/chat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  List<ChatUser> _list = [];
  //storing searched item
  final List<ChatUser> _searchList = [];
  //storing search status
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    Api.getUserInfo().then((value) => Api.updateActiveStatus(true));

    SystemChannels.lifecycle.setMessageHandler((message) {
      log("Message : $message");
      if (Api.auth.currentUser != null) {
        if (message.toString().contains("paused")) {
          Api.updateActiveStatus(false);
        }
        if (message.toString().contains("resumed")) {
          Api.updateActiveStatus(true);
        }
        if (message.toString().contains("inactive")) {
          Api.updateActiveStatus(false);
        }
        if (message.toString().contains("detached")) {
          Api.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool keyboardIsOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          //when _isSearching true , set value false to disable back button and just change value of _isSearching
          //when _isSearching false , set back button value to true
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
            appBar: AppBar(
              leading: const SizedBox(),
              title: _isSearching
                  ? TextField(
                      cursorColor: Colors.white,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                          fontSize: 17, letterSpacing: 1, color: Colors.white),
                      decoration: const InputDecoration(
                          isDense: true,
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1)),
                          hintText: "Search..",
                          hintStyle: TextStyle(color: Colors.white)),
                      onChanged: (value) {
                        //search logic

                        _searchList.clear();

                        for (var i in _list) {
                          if (i.name
                              .toLowerCase()
                              .contains(value.toLowerCase())) {
                            _searchList.add(i);
                            if (value.isEmpty) {
                              _searchList.clear();
                            }
                          }
                          setState(() {
                            _searchList;
                          });
                        }
                      },
                    )
                  : const Text(
                      "Chat App",
                      style: TextStyle(color: Colors.white),
                    ),
              actions: [
                IconButton(
                    color: Colors.white,
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        _searchList.clear();
                      });
                    },
                    icon: Icon(_isSearching ? Icons.clear : Icons.search)),
                IconButton(
                    color: Colors.white,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProfileScreen(
                                    user: Api.mySelf,
                                  )));
                    },
                    icon: const Icon(Icons.person_rounded))
              ],
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Visibility(
                visible: !keyboardIsOpen,
                child: FloatingActionButton(
                  backgroundColor: Colors.deepOrangeAccent,
                  onPressed: () async {
                    showAddUser();
                  },
                  child: const Icon(Icons.comment_rounded),
                ),
              ),
            ),
            body: StreamBuilder(
              stream: Api.getMyUsersId(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  //if data is loading

                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );

                  //if some data is loaded
                  case ConnectionState.active:
                  case ConnectionState.done:
                    return StreamBuilder(
                        stream: Api.getAllUsers(
                            snapshot.data?.docs.map((e) => e.id).toList() ??
                                []),
                        builder: (context, snapshot) {
                          switch (snapshot.connectionState) {
                            //if data is loading

                            case ConnectionState.waiting:
                            case ConnectionState.none:
                              return const Center(
                                child: CircularProgressIndicator(),
                              );

                            //if some data is loaded
                            case ConnectionState.active:
                            case ConnectionState.done:
                              final data = snapshot.data?.docs;
                              _list = data
                                      ?.map((e) => ChatUser.fromJson(e.data()))
                                      .toList() ??
                                  [];

                              if (_list.isNotEmpty) {
                                return ListView.builder(
                                  itemCount: _isSearching
                                      ? _searchList.length
                                      : _list.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return ChatCard(
                                        user: _isSearching
                                            ? _searchList[index]
                                            : _list[index]);
                                  },
                                );
                              } else {
                                return const Center(
                                    child: Text(
                                  "You don't have a chat",
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20),
                                ));
                              }
                          }
                        });
                }
              },
            )),
      ),
    );
  }

  void showAddUser() {
    String email = '';
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
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
                        "Add User",
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
                          onChanged: (value) => email = value,
                          validator: (value) =>
                              value != null && value.isNotEmpty
                                  ? null
                                  : 'Field is required!',
                          decoration: const InputDecoration(
                              hintText: "Email",
                              prefixIcon: Icon(
                                Icons.email,
                                color: Colors.deepOrange,
                              ),
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
                            onPressed: () async {
                              if ((_formKey.currentState!).validate()) {
                                _formKey.currentState!.save();
                                Navigator.pop(context);
                                if (email.isNotEmpty) {
                                  await Api.addUser(email).then((value) {
                                    if (!value) {
                                      Dialogs.showSnackBar(
                                          context,
                                          "User doesn't exists",
                                          Colors.red,
                                          SnackBarBehavior.fixed);
                                    } else {
                                      Dialogs.showSnackBar(
                                          context,
                                          "Successfully added",
                                          Colors.green,
                                          SnackBarBehavior.fixed);
                                    }
                                  });
                                }
                                // ignore: use_build_context_synchronously
                                FocusScope.of(context).unfocus();
                              }
                            },
                            icon: const Icon(
                              Icons.person_add,
                              size: 20,
                            ),
                            label: const Text(
                              "Add",
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
        );
      },
    );
  }
}
