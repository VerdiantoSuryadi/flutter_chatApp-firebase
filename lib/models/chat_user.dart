class ChatUser {
  ChatUser({
    required this.createdAt,
    required this.image,
    required this.name,
    required this.id,
    required this.isOnline,
    required this.lastActive,
    required this.pushToken,
    required this.email,
    required this.status,
  });
  late  String createdAt;
  late  String image;
  late  String name;
  late  String id;
  late  bool isOnline;
  late  String lastActive;
  late  String pushToken;
  late  String email;
  late  String status;

  ChatUser.fromJson(Map<String, dynamic> json) {
    createdAt = json['createdAt'] ?? '';
    image = json['image'] ?? '';
    name = json['name'] ?? '';
    id = json['id'] ?? '';
    isOnline = json['is_online'] ?? '';
    lastActive = json['last_active'] ?? '';
    pushToken = json['push_token'] ?? '';
    email = json['email'] ?? '';
    status = json['status'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['createdAt'] = createdAt;
    data['image'] = image;
    data['name'] = name;
    data['id'] = id;
    data['is_online'] = isOnline;
    data['last_active'] = lastActive;
    data['push_token'] = pushToken;
    data['email'] = email;
    data['status'] = status;
    return data;
  }
}
