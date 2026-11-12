class SearchModel {
  bool? status;
  int? code;
  String? msg;
  List<Data>? data;

  SearchModel({this.status, this.code, this.msg, this.data});

  SearchModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    code = json['code'];
    msg = json['msg'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['code'] = this.code;
    data['msg'] = this.msg;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  String? name;
  String? image;
  int? relatedid;
  int? companyId;
  String? companyName;
  String? screen;

  Data({
    this.id,
    this.name,
    this.image,
    this.relatedid,
    this.companyId,
    this.companyName,
    this.screen,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = int.tryParse('${json['id'] ?? ''}');
    name = json['name'];
    image = json['image'];
    relatedid = int.tryParse('${json['relatedid'] ?? ''}');
    companyId = int.tryParse('${json['company_id'] ?? ''}');
    companyName = json['company_name']?.toString();
    screen = json['screen'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['relatedid'] = relatedid;
    data['company_id'] = companyId;
    data['company_name'] = companyName;
    data['screen'] = screen;
    return data;
  }
}