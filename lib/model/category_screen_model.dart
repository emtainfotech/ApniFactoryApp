class CategoryScreenModel {
  bool? status;
  int? code;
  String? msg;
  Data? data;

  CategoryScreenModel({this.status, this.code, this.msg, this.data});

  CategoryScreenModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    code = json['code'];
    msg = json['msg'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['code'] = this.code;
    data['msg'] = this.msg;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  List<String>? advertisement;
  List<Company>? company;
  List<Category>? category;
  List<CategoryScreenSubcategory>? subcategory;
  List<String>? slider;

  Data({this.advertisement, this.company, this.category, this.subcategory, this.slider});

  Data.fromJson(Map<String, dynamic> json) {
    advertisement = json['advertisement'] != null ? json['advertisement'].cast<String>() : [];
    if (json['company'] != null) {
      company = <Company>[];
      json['company'].forEach((v) {
        company!.add(new Company.fromJson(v));
      });
    }
    if (json['category'] != null) {
      category = <Category>[];
      json['category'].forEach((v) {
        category!.add(new Category.fromJson(v));
      });
    }
    if (json['subcategory'] != null) {
      subcategory = <CategoryScreenSubcategory>[];
      json['subcategory'].forEach((v) {
        subcategory!.add(CategoryScreenSubcategory.fromJson(v));
      });
    }
    slider = json['slider'] != null ? json['slider'].cast<String>() : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['advertisement'] = this.advertisement;
    if (this.company != null) {
      data['company'] = this.company!.map((v) => v.toJson()).toList();
    }
    if (this.category != null) {
      data['category'] = this.category!.map((v) => v.toJson()).toList();
    }
    if (this.subcategory != null) {
      data['subcategory'] = this.subcategory!.map((v) => v.toJson()).toList();
    }
    data['slider'] = this.slider;
    return data;
  }
}

class CategoryScreenSubcategory {
  String? name;
  String? image;
  int? cid;
  int? scid;
  int? mid;

  CategoryScreenSubcategory({this.name, this.image, this.cid, this.scid, this.mid});

  CategoryScreenSubcategory.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    image = json['image'];
    cid = json['cid'];
    scid = json['scid'];
    mid = json['mid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['image'] = image;
    data['cid'] = cid;
    data['scid'] = scid;
    data['mid'] = mid;
    return data;
  }
}

class Company {
  String? name;
  String? image;
  int? cmpid;
  int? count;
  String? city;

  Company({this.name, this.image, this.cmpid, this.count, this.city});

  Company.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    image = json['image'];
    cmpid = json['cmpid'];
    count = json['count'];
    city = json['city'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['image'] = this.image;
    data['cmpid'] = this.cmpid;
    data['count'] = this.count;
    data['city'] = this.city;
    return data;
  }
}

class Category {
  String? name;
  String? image;
  int? cid;

  Category({this.name, this.image, this.cid});

  Category.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    image = json['image'];
    cid = json['cid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['image'] = this.image;
    data['cid'] = this.cid;
    return data;
  }
}