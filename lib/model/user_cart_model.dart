class UserCartModel {
  final bool status;
  final int code;
  final String msg;
  num? grandTotal; 
  num? netamount; 
  int counter;
  num cgst;
  num sgst;
  num igst;
  num? couponbyadmin;
  String combinecoupon;
  int? companyId;
  String? companyName;
  String? companyPhoto;
  String? companyCity;
  List<SellerGroupModel>? sellerGroups;
  bool? allSellersCanCheckout;

  final Map<String, List<List<ProductCategory>>> data;

  UserCartModel({
    required this.status,
    required this.code,
    required this.msg,
    required this.grandTotal,
    required this.netamount,
    required this.counter,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.couponbyadmin,
    required this.combinecoupon,
    this.companyId,
    this.companyName,
    this.companyPhoto,
    this.companyCity,
    this.sellerGroups,
    this.allSellersCanCheckout,
    required this.data,
  });

  int get activeCompanyId {
    if (companyId != null && companyId! > 0) return companyId!;
    if (sellerGroups != null && sellerGroups!.isNotEmpty) {
      return sellerGroups!.first.companyId;
    }
    return 0;
  }

  String get activeCompanyName {
    if (companyName != null && companyName!.trim().isNotEmpty) {
      return companyName!.trim();
    }
    if (sellerGroups != null && sellerGroups!.isNotEmpty) {
      return sellerGroups!.first.companyName;
    }
    return '';
  }

  // Factory method to parse JSON into UserCartModel
  factory UserCartModel.fromJson(Map<String, dynamic> json) {
    return UserCartModel(
      status: json['status'],
      code: json['code'],
      msg: json['msg'],
      grandTotal: json['grandtotal'],
      netamount: json['netamount'],
      counter: json['counter'],
      cgst: json['cgst'],
      sgst: json['sgst'],
      igst: json['igst'],
      couponbyadmin: json['couponbyadmin'],
      combinecoupon: json['combinecoupon'],
      companyId: int.tryParse('${json['company_id'] ?? ''}'),
      companyName: json['company_name']?.toString(),
      companyPhoto: json['company_photo']?.toString(),
      companyCity: json['company_city']?.toString(),
      sellerGroups: json['seller_groups'] != null
          ? (json['seller_groups'] as List)
              .map((item) => SellerGroupModel.fromJson(item))
              .toList()
          : null,
      allSellersCanCheckout: json['all_sellers_can_checkout'],
      data: (json['data'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((list) => (list as List)
                  .map((item) => ProductCategory.fromJson(item))
                  .toList())
              .toList(),
        ),
      ),
    );
  }

  // Method to convert UserCartModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'code': code,
      'msg': msg,
      'grandtotal': grandTotal,
      'netamount':netamount,
      'counter': counter,
      'cgst':cgst,
      'sgst':sgst,
      'igst':igst,
      'couponbyadmin':couponbyadmin,
      'combinecoupon':combinecoupon,
      'data': data.map(
        (key, value) => MapEntry(
          key,
          value
              .map((list) => list.map((item) => item.toJson()).toList())
              .toList(),
        ),
      ),
    };
  }
}

class ProductCategory {
  final int cartid;
  final int productid;

  final String productName;
  final String productImage;
  final List<AttributeData> attributeData;
  final List<AvailableAttribute>? otherAttributes;

  ProductCategory({
    required this.cartid,
    required this.productid,
    required this.productName,
    required this.productImage,
    required this.attributeData,
    this.otherAttributes,
  });

  // Factory method to parse JSON into ProductCategory
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      cartid: json['cartid'] is int ? json['cartid'] : int.tryParse('${json['cartid'] ?? ''}') ?? 0,
      productid: json['productid'] is int ? json['productid'] : int.tryParse('${json['productid'] ?? ''}') ?? 0,
      productName: json['productname'] ?? '',
      productImage: json['productimage'] ?? '',
      attributeData: (json['attributedata'] as List? ?? [])
          .map((item) => AttributeData.fromJson(item))
          .toList(),
      otherAttributes: json['other_attributes'] != null
          ? (json['other_attributes'] as List)
              .map((item) => AvailableAttribute.fromJson(item))
              .toList()
          : null,
    );
  }

  // Method to convert ProductCategory to JSON
  Map<String, dynamic> toJson() {
    return {
      'cartyid':cartid,
      'productid': productid,
      'productname': productName,
      'productimage': productImage,
      'attributedata': attributeData.map((item) => item.toJson()).toList(),
      if (otherAttributes != null)
        'other_attributes': otherAttributes!.map((item) => item.toJson()).toList(),
    };
  }
}

class AvailableAttribute {
  final int id;
  final int productId;
  final String packSize;
  final num price;
  final String color;

  AvailableAttribute({
    required this.id,
    required this.productId,
    required this.packSize,
    required this.price,
    required this.color,
  });

  factory AvailableAttribute.fromJson(Map<String, dynamic> json) {
    return AvailableAttribute(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id'] ?? ''}') ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse('${json['product_id'] ?? ''}') ?? 0,
      packSize: json['pack_size']?.toString() ?? '1 Unit',
      price: num.tryParse('${json['price'] ?? ''}') ?? (json['price'] is num ? json['price'] : 0),
      color: json['color']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'pack_size': packSize,
      'price': price,
      'color': color,
    };
  }
}

class AttributeData {
  final String boxPacking;
  final String color;
  num? totalPrice;
  int? qty;
  final int? attributeid;
  final int? prprice;
  final int? boxpcs;
  num? unitprice;
  final int? productattributeid;
  final num? couponamount;

  AttributeData(
      {required this.boxPacking,
      required this.color,
      required this.totalPrice,
      required this.qty,
      required this.attributeid,
      required this.prprice,
      required this.boxpcs,
      required this.unitprice, 
      required this.productattributeid,
      required this.couponamount});

  // Factory method to parse JSON into AttributeData
  factory AttributeData.fromJson(Map<String, dynamic> json) {
    return AttributeData(
        boxPacking: json['boxpacking'],
        color: json['color'],
        totalPrice: json['totalprice'],
        qty: json['qty'],
        attributeid: json['attributeid'],
        prprice: json['prprice'],
        boxpcs: json['boxpcs'],
        unitprice: json['unitprice'],
        productattributeid: json['productattributeid'],
        couponamount: json['couponamount']);
  }

  // Method to convert AttributeData to JSON
  Map<String, dynamic> toJson() {
    return {
      'boxpacking': boxPacking,
      'color': color,
      'totalprice': totalPrice,
      'qty': qty,
      'attributeid': attributeid,
      'prprice': prprice,
      'boxpcs':boxpcs,
      'unitprice':unitprice,
      'productattributeid':productattributeid,
      'couponamount':couponamount
    };
  }
}

class SellerGroupModel {
  final int companyId;
  final String companyName;
  final String companyStatus;
  final bool isSellerActive;
  final int itemsCount;
  final int totalQuantity;
  final num sellerSubtotal;
  final num sellerTax;
  final num sellerGrandTotal;
  final num freightAmount;
  final num configuredMov;
  final num movShortfall;
  final num movProgressPercentage;
  final String movStatus;
  final bool isMovSatisfied;
  final bool canCheckout;

  SellerGroupModel({
    required this.companyId,
    required this.companyName,
    required this.companyStatus,
    required this.isSellerActive,
    required this.itemsCount,
    required this.totalQuantity,
    required this.sellerSubtotal,
    required this.sellerTax,
    required this.sellerGrandTotal,
    required this.freightAmount,
    required this.configuredMov,
    required this.movShortfall,
    required this.movProgressPercentage,
    required this.movStatus,
    required this.isMovSatisfied,
    required this.canCheckout,
  });

  factory SellerGroupModel.fromJson(Map<String, dynamic> json) {
    return SellerGroupModel(
      companyId: json['company_id'] ?? 0,
      companyName: json['company_name'] ?? 'Manufacturer',
      companyStatus: json['company_status']?.toString() ?? 'Active',
      isSellerActive: json['is_seller_active'] ?? true,
      itemsCount: json['items_count'] ?? 0,
      totalQuantity: json['total_quantity'] ?? 0,
      sellerSubtotal: json['seller_subtotal'] ?? 0,
      sellerTax: json['seller_tax'] ?? 0,
      sellerGrandTotal: json['seller_grand_total'] ?? 0,
      freightAmount: json['freight_amount'] ?? 0,
      configuredMov: json['configured_mov'] ?? 0,
      movShortfall: json['mov_shortfall'] ?? 0,
      movProgressPercentage: json['mov_progress_percentage'] ?? 100,
      movStatus: json['mov_status'] ?? 'not_configured',
      isMovSatisfied: json['is_mov_satisfied'] ?? true,
      canCheckout: json['can_checkout'] ?? true,
    );
  }
}




