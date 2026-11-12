class OrderModel {
  bool? status;
  int? code;
  String? msg;
  Data? data;
  String? hash;
  String? furl;
  String? surl;
  Hashparameter? hashparameter;
  String? payuEnvironment;
  bool? isUat;
  String? payuMode;
  String? checkoutUrl;

  OrderModel(
      {this.status,
      this.code,
      this.msg,
      this.data,
      this.hash,
      this.furl,
      this.surl,
      this.hashparameter,
      this.payuEnvironment,
      this.isUat,
      this.payuMode,
      this.checkoutUrl});

  OrderModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    code = json['code'];
    msg = json['msg'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    hash = json['hash']?.toString();
    furl = json['furl']?.toString();
    surl = json['surl']?.toString();
    payuEnvironment = json['payu_environment']?.toString();
    isUat = json['is_uat'] is bool ? json['is_uat'] : null;
    payuMode = json['payu_mode']?.toString();
    checkoutUrl = json['checkout_url']?.toString();
    hashparameter = json['hashparameter'] != null
        ? Hashparameter.fromJson(json['hashparameter'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['code'] = code;
    data['msg'] = msg;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['hash'] = hash;
    data['furl'] = furl;
    data['surl'] = surl;
    data['payu_environment'] = payuEnvironment;
    data['is_uat'] = isUat;
    data['payu_mode'] = payuMode;
    data['checkout_url'] = checkoutUrl;
    if (hashparameter != null) {
      data['hashparameter'] = hashparameter!.toJson();
    }
    return data;
  }
}

class Data {
  String? orderno;
  String? customerId;
  int? userId;
  String? address;
  num? sellercouponamount;
  num? admincouponamount;
  String? admincoupondetail;
  num? netamount;
  String? taxdetail;
  num? taxamount;
  num? grandtotal;

  Data(
      {this.orderno,
      this.customerId,
      this.userId,
      this.address,
      this.sellercouponamount,
      this.admincouponamount,
      this.admincoupondetail,
      this.netamount,
      this.taxdetail,
      this.taxamount,
      this.grandtotal});

  Data.fromJson(Map<String, dynamic> json) {
    orderno = json['orderno']?.toString();
    customerId = json['customer_id']?.toString();
    userId = int.tryParse(json['user_id']?.toString() ?? '');
    address = json['address']?.toString();
    sellercouponamount = json['sellercouponamount'];
    admincouponamount = json['admincouponamount'];
    admincoupondetail = json['admincoupondetail']?.toString();
    netamount = json['netamount'];
    taxdetail = json['taxdetail']?.toString();
    taxamount = json['taxamount'];
    grandtotal = json['grandtotal'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['orderno'] = this.orderno;
    data['customer_id'] = this.customerId;
    data['user_id'] = this.userId;
    data['address'] = this.address;
    data['sellercouponamount'] = this.sellercouponamount;
    data['admincouponamount'] = this.admincouponamount;
    data['admincoupondetail'] = this.admincoupondetail;
    data['netamount'] = this.netamount;
    data['taxdetail'] = this.taxdetail;
    data['taxamount'] = this.taxamount;
    data['grandtotal'] = this.grandtotal;
    return data;
  }
}

class Hashparameter {
  String? key;
  String? txnid;
  String? amount;
  String? productinfo;
  String? firstname;
  String? email;
  String? udf1;
  String? udf2;
  String? udf3;

  Hashparameter(
      {this.key,
      this.txnid,
      this.amount,
      this.productinfo,
      this.firstname,
      this.email,
      this.udf1,
      this.udf2,
      this.udf3});

  Hashparameter.fromJson(Map<String, dynamic> json) {
    key = json['key']?.toString();
    txnid = json['txnid']?.toString();
    amount = json['amount']?.toString();
    productinfo = json['productinfo']?.toString();
    firstname = json['firstname']?.toString();
    email = json['email']?.toString();
    udf1 = json['udf1']?.toString();
    udf2 = json['udf2']?.toString();
    udf3 = json['udf3']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['txnid'] = txnid;
    data['amount'] = amount;
    data['productinfo'] = productinfo;
    data['firstname'] = firstname;
    data['email'] = email;
    data['udf1'] = udf1;
    data['udf2'] = udf2;
    data['udf3'] = udf3;
    return data;
  }
}