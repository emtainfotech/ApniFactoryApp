class NotificationModel {
  bool? status;
  int? code;
  String? msg;
  List<Data>? data;

  NotificationModel({this.status, this.code, this.msg, this.data});

  NotificationModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    code = json['code'];
    msg = json['msg'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['code'] = code;
    data['msg'] = msg;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  int? customerId;
  int? msgread;
  String? createdAt;
  String? updatedAt;
  String? title;
  String? body;
  String? image;
  String? deepLink;
  String? screen;
  String? screenid;
  String? type;
  String? timeAgo;

  Data({
    this.id,
    this.customerId,
    this.msgread,
    this.createdAt,
    this.updatedAt,
    this.title,
    this.body,
    this.image,
    this.deepLink,
    this.screen,
    this.screenid,
    this.type,
    this.timeAgo,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id'];
    msgread = json['msgread'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    title = json['title'];
    body = json['body'] ?? json['msg'];
    image = json['image'];
    deepLink = json['deep_link'];
    screen = json['screen'];
    screenid = json['screenid']?.toString();
    type = json['type'];
    timeAgo = json['time_ago'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['customer_id'] = customerId;
    data['msgread'] = msgread;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['title'] = title;
    data['body'] = body;
    data['image'] = image;
    data['deep_link'] = deepLink;
    data['screen'] = screen;
    data['screenid'] = screenid;
    data['type'] = type;
    data['time_ago'] = timeAgo;
    return data;
  }
}
