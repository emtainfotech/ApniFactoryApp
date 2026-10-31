class HomescreenModel {
  bool? status;
  int? code;
  String? msg;
  Data? data;

  HomescreenModel({this.status, this.code, this.msg, this.data});

  HomescreenModel.fromJson(Map<String, dynamic> json) {
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
  List<String>? slider;
  List<Maincategory>? maincategory;
  List<String>? advertisement;
  int? notification;
  List<HomeProduct>? randomProducts;
  List<HomeBrand>? brands;
  List<HomeProduct>? moreProducts;

  Data(
      {this.slider,
      this.maincategory,
      this.advertisement,
      this.notification,
      this.randomProducts,
      this.brands,
      this.moreProducts});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['slider'] != null) {
      slider = json['slider'].cast<String>();
    }
    if (json['maincategory'] != null) {
      maincategory = <Maincategory>[];
      json['maincategory'].forEach((v) {
        maincategory!.add(new Maincategory.fromJson(v));
      });
    }
    if (json['advertisement'] != null) {
      advertisement = json['advertisement'].cast<String>();
    }
    notification = json['notification'];

    if (json['random_products'] != null) {
      randomProducts = <HomeProduct>[];
      json['random_products'].forEach((v) {
        randomProducts!.add(new HomeProduct.fromJson(v));
      });
    }

    if (json['brands'] != null) {
      brands = <HomeBrand>[];
      json['brands'].forEach((v) {
        brands!.add(new HomeBrand.fromJson(v));
      });
    }

    if (json['more_products'] != null) {
      moreProducts = <HomeProduct>[];
      json['more_products'].forEach((v) {
        moreProducts!.add(new HomeProduct.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['slider'] = this.slider;
    if (this.maincategory != null) {
      data['maincategory'] = this.maincategory!.map((v) => v.toJson()).toList();
    }
    data['advertisement'] = this.advertisement;
    data['notification'] = this.notification;
    if (this.randomProducts != null) {
      data['random_products'] =
          this.randomProducts!.map((v) => v.toJson()).toList();
    }
    if (this.brands != null) {
      data['brands'] = this.brands!.map((v) => v.toJson()).toList();
    }
    if (this.moreProducts != null) {
      data['more_products'] =
          this.moreProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HomeProduct {
  int? id;
  String? name;
  String? image;
  int? categoryId;
  String? categoryName;
  int? brandId;
  String? brandName;
  num? price;
  num? oldprice;
  String? colorId;

  HomeProduct({
    this.id,
    this.name,
    this.image,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    this.price,
    this.oldprice,
    this.colorId,
  });

  HomeProduct.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    categoryId = json['category_id'];
    categoryName = json['category_name'];
    brandId = json['brand_id'];
    brandName = json['brand_name'];
    price = json['price'];
    oldprice = json['oldprice'];
    colorId = json['color_id']?.toString() ?? '0';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['brand_id'] = brandId;
    data['brand_name'] = brandName;
    data['price'] = price;
    data['oldprice'] = oldprice;
    data['color_id'] = colorId;
    return data;
  }
}

class HomeBrand {
  int? id;
  String? name;
  String? image;
  int? companyId;
  int? categoryId;

  HomeBrand({
    this.id,
    this.name,
    this.image,
    this.companyId,
    this.categoryId,
  });

  HomeBrand.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    companyId = json['company_id'];
    categoryId = json['category_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['company_id'] = companyId;
    data['category_id'] = categoryId;
    return data;
  }
}

class Maincategory {
  int? id;
  String? name;
  String? title;
  String? image;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? sequence;

  Maincategory(
      {this.id,
      this.name,
      this.title,
      this.image,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.sequence});

  Maincategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    title = json['title'];
    image = json['image'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    sequence = json['sequence'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['title'] = this.title;
    data['image'] = this.image;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['sequence'] = this.sequence;
    return data;
  }
}