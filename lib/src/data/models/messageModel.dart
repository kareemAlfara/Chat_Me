class Messagemodel {
  final String message;
  final String image_url;
  final String Sender_id;
  final String reciver_id;
  final String chat_between;
  final int id;

  factory Messagemodel.fromJson(json) {
    return Messagemodel(
      id: json['id'],
      message: json['message'].toString(),
      image_url: json['image_url'].toString(),
      Sender_id: json["Sender_Id"].toString(),
      reciver_id: json['reciver_Id'],
      chat_between: json["chat_between"],
    );
  }

  Messagemodel({
    required this.message,
    required this.id,
    required this.image_url,
    required this.Sender_id,
    required this.reciver_id,
    required this.chat_between,
  });
}
