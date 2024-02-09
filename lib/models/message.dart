class Message {
  Message({
    required this.msg,
    required this.read,
    required this.from,
    required this.to,
    required this.type,
    required this.sent,
  });
  late final String msg;
  late final String read;
  late final String from;
  late final String to;
  late final String sent;
  late final Type type;

  Message.fromJson(Map<String, dynamic> json) {
    msg = json['msg'].toString();
    read = json['read'].toString();
    from = json['from'].toString();
    to = json['to'].toString();
    type = json['type'].toString() == Type.image.name ? Type.image : Type.text;
    sent = json['sent'].toString();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['msg'] = msg;
    data['read'] = read;
    data['from'] = from;
    data['to'] = to;
    data['type'] = type.name;
    data['sent'] = sent;
    return data;
  }
}

enum Type { text, image }
