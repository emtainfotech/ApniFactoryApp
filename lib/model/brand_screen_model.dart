import 'package:apni_factory/model/home_screen_model.dart';

class BrandScreenModel {
  bool? status;
  int? code;
  String? msg;
  Data? data;

  BrandScreenModel({this.status, this.code, this.msg, this.data});

  BrandScreenModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    code = json['code'];
    msg = json['msg'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['code'] = code;
    data['msg'] = msg;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class BrandCompanyInfo {
  int? id;
  String? name;
  String? photo;
  String? city;
  String? state;
  num? minordervalue;

  BrandCompanyInfo({
    this.id,
    this.name,
    this.photo,
    this.city,
    this.state,
    this.minordervalue,
  });

  BrandCompanyInfo.fromJson(Map<String, dynamic> json) {
    id = int.tryParse('${json['id'] ?? ''}');
    name = json['name'];
    photo = json['photo'];
    city = json['city'];
    state = json['state'];
    minordervalue = num.tryParse('${json['minordervalue'] ?? ''}');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photo': photo,
        'city': city,
        'state': state,
        'minordervalue': minordervalue,
      };
}

class BrandCategory {
  int? id;
  String? name;
  String? image;
  int? maincategoryId;

  BrandCategory({this.id, this.name, this.image, this.maincategoryId});

  BrandCategory.fromJson(Map<String, dynamic> json) {
    id = int.tryParse('${json['id'] ?? ''}');
    name = json['name'];
    image = json['image'];
    maincategoryId = int.tryParse('${json['maincategory_id'] ?? ''}');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'maincategory_id': maincategoryId,
      };
}

class Data {
  List<Brand>? brand;
  List<Brand>? allBrands;
  List<BrandCategory>? categories;
  List<HomeProduct>? products;
  BrandCompanyInfo? company;
  int? cmpid;
  String? bannerimage;
  String? companyname;

  Data({
    this.brand,
    this.allBrands,
    this.categories,
    this.products,
    this.company,
    this.cmpid,
    this.bannerimage,
    this.companyname,
  });

  Data.fromJson(Map<String, dynamic> json) {
    if (json['Brand'] != null) {
      brand = <Brand>[];
      for (final v in json['Brand']) {
        brand!.add(Brand.fromJson(v));
      }
    }
    if (json['all_brands'] != null) {
      allBrands = <Brand>[];
      for (final v in json['all_brands']) {
        allBrands!.add(Brand.fromJson(v));
      }
    }
    if (json['categories'] != null) {
      categories = <BrandCategory>[];
      for (final v in json['categories']) {
        categories!.add(BrandCategory.fromJson(v));
      }
    }
    if (json['products'] != null) {
      products = <HomeProduct>[];
      for (final v in json['products']) {
        products!.add(HomeProduct.fromJson(v));
      }
    }
    company = json['company'] != null
        ? BrandCompanyInfo.fromJson(json['company'])
        : null;
    cmpid = int.tryParse('${json['cmpid'] ?? ''}');
    bannerimage = json['bannerimage'];
    companyname = json['companyname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (brand != null) {
      data['Brand'] = brand!.map((v) => v.toJson()).toList();
    }
    if (allBrands != null) {
      data['all_brands'] = allBrands!.map((v) => v.toJson()).toList();
    }
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    if (company != null) {
      data['company'] = company!.toJson();
    }
    data['cmpid'] = cmpid;
    data['bannerimage'] = bannerimage;
    data['companyname'] = companyname;
    return data;
  }
}

class Brand {
  int? id;
  int? companyId;
  String? name;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? userId;
  int? mid;
  int? categoryId;
  String? image;
  String? trademarkno;
  Null? file;
  String? type;
  String? adminresponse;

  Brand(
      {this.id,
      this.companyId,
      this.name,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.userId,
      this.mid,
      this.categoryId,
      this.image,
      this.trademarkno,
      this.file,
      this.type,
      this.adminresponse});

  Brand.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    name = json['name'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    userId = json['user_id'];
    mid = json['mid'];
    categoryId = json['category_id'];
    image = json['image'];
    trademarkno = json['trademarkno'];
    file = json['file'];
    type = json['type'];
    adminresponse = json['adminresponse'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['company_id'] = this.companyId;
    data['name'] = this.name;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['user_id'] = this.userId;
    data['mid'] = this.mid;
    data['category_id'] = this.categoryId;
    data['image'] = this.image;
    data['trademarkno'] = this.trademarkno;
    data['file'] = this.file;
    data['type'] = this.type;
    data['adminresponse'] = this.adminresponse;
    return data;
  }
}