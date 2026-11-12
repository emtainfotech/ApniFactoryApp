class AddToCartModel {
  bool? status;
  int? code;
  bool? conflict;
  String? existingCompanyName;
  String? newCompanyName;
  String? msg;
  num? grandtotal;
  int? counter;

  AddToCartModel(
      {this.status,
      this.code,
      this.conflict,
      this.existingCompanyName,
      this.newCompanyName,
      this.msg,
      this.grandtotal,
      this.counter});

  AddToCartModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    code = json['code'];
    conflict = json['conflict'];
    existingCompanyName = json['existing_company_name']?.toString();
    newCompanyName = json['new_company_name']?.toString();
    msg = json['msg'];
    grandtotal = json['grandtotal'];
    counter = json['counter'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['code'] = this.code;
    data['conflict'] = this.conflict;
    data['existing_company_name'] = this.existingCompanyName;
    data['new_company_name'] = this.newCompanyName;
    data['msg'] = this.msg;
    data['grandtotal'] = this.grandtotal;
    data['counter'] = this.counter;
    return data;
  }
}