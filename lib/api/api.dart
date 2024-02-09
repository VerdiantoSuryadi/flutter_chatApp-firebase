import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/models/chat_user.dart';
import 'package:firebase_chat/models/message.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

class Api {
  //authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  //firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  //cloud firestore
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //firebase messaging
  static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  //storing self info
  static late ChatUser mySelf;

  //to return current user
  static User get user => auth.currentUser!;

  //get token firebase messaging
  static Future<void> getToken() async {
    await firebaseMessaging.requestPermission();
    await firebaseMessaging.getToken().then((value) {
      if (value != null) {
        mySelf.pushToken = value;
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }

  //sending push notification
  static Future<void> sendNotification(ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": mySelf.name,
          "body": msg,
          "android_channel_id": "chats",
        },
        "data": {
          "data": "USER ID: ${mySelf.id}",
        },
      };
      var res = await post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAAzqkosd8:APA91bGH9K-_4oKK8Ay0E9zBoPySoyfrlBG7Aus9K0ysE0lbexjGUW780KKIdQvSiv-wO4HDh-4Ojk4C8yH2_IeG93ni15U_q6Vr-7fTvU7yuZsX6lkHT47ChBTZx-oxYhG_3G6nliei'
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationError: $e');
    }
  }

  //checking if user exists
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  //add user
  static Future<bool> addUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    log('Data: ${data.docs}');
    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists
      log('User Exists: ${data.docs.first.data()}');
      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      //user not exists
      return false;
    }
  }

  //getting current user info
  static Future<void> getUserInfo() async {
    return firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        mySelf = ChatUser.fromJson(user.data()!);
        await getToken();
        log("MYSELF token: ${mySelf.pushToken}");

        log('My Data: ${user.data()}');
      } else {
        await createNewUser().then((value) => getUserInfo());
      }
    });
  }

  //create new user
  static Future<void> createNewUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
        createdAt: time,
        image: user.photoURL.toString(),
        name: user.displayName.toString(),
        id: user.uid,
        isOnline: false,
        lastActive: time,
        pushToken: '',
        email: user.email.toString(),
        status: "Hello!");
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  //getting all user from firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> usersId) {
    log('\nUsers Id: $usersId');
    return firestore
        .collection('users')
        .where('id', whereIn: usersId.isEmpty ? [''] : usersId)
        .snapshots();
  }

  //getting id of known users
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserData(String id) {
    return firestore.collection('users').doc(id).snapshots();
  }

  //get spesific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAnyUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  //update online / last active status
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': mySelf.pushToken,
    });
  }

  //add an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

  //update user info
  static Future<void> updateUserInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'name': mySelf.name, 'status': mySelf.status});
  }

  //update profile picture
  static Future<void> updatePicture(File file) async {
    final ext = file.path.split('.').last;
    final ext2 = file.path.split('.');
    log('Ext 2: $ext2');
    log('Extension: $ext');
    final ref = storage.ref().child('pictures/PP_Of_${user.uid}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transfered: ${p0.bytesTransferred / 1000} kb');
    });
    mySelf.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': mySelf.image});
  }

  //Get converstation Id
  static String getConverstationId(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  //Chat Screen Api
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    // print(user.id.hashCode);
    // print(auth.currentUser!.uid.hashCode);
    return firestore
        .collection("chats/${getConverstationId(user.id)}/messages/")
        .orderBy('sent', descending: true)
        .snapshots();
  }

  //send message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    //message sending time
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    //message to send
    final Message message = Message(
        msg: msg,
        read: '',
        from: user.uid,
        to: chatUser.id,
        type: type,
        sent: time);

    final ref = firestore
        .collection('chats/${getConverstationId(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendNotification(chatUser, type == Type.text ? msg : 'image'));
  }

  //Update read status
  static Future<void> updateReadStatus(Message message) async {
    firestore
        .collection('chats/${getConverstationId(message.from)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //Get last message
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMsg(ChatUser user) {
    return firestore
        .collection('chats/${getConverstationId(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send image to chat
  static Future<void> sendImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    final ext2 = file.path.split('.');
    log('Ext 2: $ext2');
    log('Extension: $ext');
    final ref = storage.ref().child(
        'pictures/${getConverstationId(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transfered: ${p0.bytesTransferred / 1000} kb');
    });
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    //chat from uid == sender
    //so converstation id can't be = uid_sender
    //must be => uid_to
    await firestore
        .collection('chats/${getConverstationId(message.to)}/messages/')
        .doc(message.sent)
        .delete();
    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update Message
  static Future<void> updateMessage(
      Message message, String updatedMessage) async {
    await firestore
        .collection('chats/${getConverstationId(message.to)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMessage});
  }
}
