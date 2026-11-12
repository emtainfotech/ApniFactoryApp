import 'dart:convert';
import 'package:apni_factory/api_services/api_client.dart';
import 'package:apni_factory/api_services/creator_api_services.dart';
import 'package:apni_factory/api_services/hash_service';
import 'package:apni_factory/config/api_config.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/res/widgets/app_network_image.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/res/widgets/round_button.dart';
import 'package:apni_factory/screens/payment_failure_screen.dart';
import 'package:apni_factory/screens/payment_successful_screen.dart';
import 'package:flutter/material.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:provider/provider.dart';
import '../res/asset_image.dart';
import '../res/colors.dart';
import '../res/textstyle.dart';
import '../res/widgets/back_button_widget.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen>
    implements PayUCheckoutProProtocol {
  String? serverHash;
  bool _isSubmittingOrder = false;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Provider.of<CartScreenProvider>(context, listen: false).checkoutPro =
          PayUCheckoutProFlutter(this);
      // Provider.of<CheckoutProvider>(context, listen: false)
      //     .getAddress(context: context);
    });
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Consumer<CartScreenProvider>(
        builder: (context, provider, child) {
          return
              // provider.loadingGetAddress ||
              provider.loadingAddAddress ||
                      provider.loadingGetAddressDetail ||
                      provider.loadingDeleteAddress ||
                      provider.loadingorder
                  ? CircularProgressIndicatorWidget()
                  : Stack(
                      children: [
                        Align(
                            alignment: Alignment.topRight,
                            child: Image.asset(
                              AppAssetImage.signUpCurve,
                              color: AppColors.primaryColor,
                            )),
                        ListView(
                          children: [
                            SizedBox(
                              height: height / 26.6,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width / 16.2),
                              child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: BackButtonWidget()),
                            ),
                            SizedBox(
                              height: height / 26.6,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width / 16.2),
                              child: Text(
                                "Select payment method",
                                style: AppTextStyle.poppinsRegular16(
                                    context: context,color: AppColors.secondaryColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              height: height / 22,
                            ),
                          
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width / 16.2),
                              child: Text(
                                "Payment method",
                                style: AppTextStyle.poppinsRegular14(
                                    context: context,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              height: height / 42,
                            ),
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: provider.paymentList.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: width / 16.2,
                                      vertical: height / 80),
                                  child: Container(
                                    height: height / 17.7,
                                    width: width,
                                    decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                              blurRadius: 32,
                                              color: AppColors.blackColor
                                                  .withOpacity(0.1))
                                        ], // border: Border.all(color: AppColors.primaryColor),
                                        borderRadius: BorderRadius.circular(
                                            height / 66.6),
                                        color: AppColors.whiteColor),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: width / 16.2),
                                      child: Row(
                                        children: [
                                          AppNetworkImage(
                                            imageUrl:
                                                "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/MasterCard_Logo.svg/1280px-MasterCard_Logo.svg.png",
                                            height: height / 40,
                                            width: height / 24,
                                            fit: BoxFit.contain,
                                            fallbackIcon: Icons.credit_card,
                                          ),
                                          SizedBox(
                                            width: width / 20,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  provider.paymentList[index],
                                                  style: AppTextStyle.poppinsBold13(
                                                      context: context,
                                                      color: AppColors
                                                          .secondaryColor),
                                                ),
                                                Text(
                                                  (provider.orderModel?.payuMode == 'production')
                                                      ? "PayU Live Production Gateway"
                                                      : "PayU UAT Gateway (Auto-switches to Live with production keys)",
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Radio(
                                            activeColor: AppColors.primaryColor,
                                            value: provider.paymentList[index],
                                            groupValue:
                                                provider.selectedPayment,
                                            onChanged: (value) {
                                              provider.selectPayment(value,
                                                  context: context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(
                              height: height / 21,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width / 16.2),
                              child: RoundButton(
                                title:
                                    _isSubmittingOrder ? "Processing..." : "Pay",
                                onPressed: () async {
                                  if (_isSubmittingOrder) return;
                                  setState(() => _isSubmittingOrder = true);
                                  try {
                                    await provider.order(
                                      context: context,
                                      height: height,
                                      addressId:
                                          provider.selectedAddressId ?? "",
                                    );
                                    if (!mounted) return;
                                    final orderModel = provider.orderModel;
                                    if (orderModel == null ||
                                        orderModel.data == null ||
                                        orderModel.hashparameter == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Order creation failed")),
                                      );
                                      return;
                                    }
                                    final orderData = orderModel.data!;
                                    final hashParameter =
                                        orderModel.hashparameter!;
                                    String phone = "";
                                    if (orderData.address != null) {
                                      try {
                                        final addressJson =
                                            orderData.address is String
                                                ? jsonDecode(
                                                    orderData.address ?? "")
                                                : orderData.address;
                                        phone = addressJson['phoneno'] ?? "";
                                      } catch (e) {
                                        ApiClient.safeLog('CheckOutScreen',
                                            'Address parse failed');
                                      }
                                    }
                                    final String txnId =
                                        hashParameter.txnid?.toString() ?? "";
                                    final String amount =
                                        hashParameter.amount?.toString() ?? "0.00";
                                    final String productInfo =
                                        hashParameter.productinfo?.toString() ?? "Order";
                                    final String firstName =
                                        hashParameter.firstname?.toString() ?? "Buyer";
                                    final String email =
                                        hashParameter.email?.toString() ?? "";
                                    final String resolvedEnv =
                                        (orderModel.payuEnvironment ?? '').isNotEmpty
                                            ? orderModel.payuEnvironment!
                                            : ApiConfig.payuEnvironment;

                                    provider.checkoutPro.openCheckoutScreen(
                                      payUPaymentParams: {
                                        PayUPaymentParamKey.key:
                                            orderModel.hashparameter?.key,
                                        PayUPaymentParamKey.userCredential:
                                            "default",
                                        PayUPaymentParamKey.transactionId:
                                            txnId,
                                        PayUPaymentParamKey.amount: amount,
                                        PayUPaymentParamKey.productInfo:
                                            productInfo,
                                        PayUPaymentParamKey.firstName:
                                            firstName,
                                        PayUPaymentParamKey.email: email,
                                        PayUPaymentParamKey.phone: phone,
                                        PayUPaymentParamKey.ios_surl:
                                            orderModel.surl,
                                        PayUPaymentParamKey.ios_furl:
                                            orderModel.furl,
                                        PayUPaymentParamKey.android_surl:
                                            orderModel.surl,
                                        PayUPaymentParamKey.android_furl:
                                            orderModel.furl,
                                        PayUPaymentParamKey.environment:
                                            resolvedEnv,
                                        PayUPaymentParamKey.additionalParam: {
                                          PayUAdditionalParamKeys.udf1:
                                              hashParameter.udf1 ?? "",
                                          PayUAdditionalParamKeys.udf2:
                                              hashParameter.udf2 ?? "",
                                          PayUAdditionalParamKeys.udf3:
                                              hashParameter.udf3 ?? "",
                                        },
                                      },
                                      payUCheckoutProConfig: {
                                        "showExitConfirmationOnPaymentScreen":
                                            true,
                                      },
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(
                                          () => _isSubmittingOrder = false);
                                    }
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              height: height / 21,
                            ),
                          ],
                        )
                      ],
                    );
        },
      ),
    );
  }

  @override
  generateHash(Map response) {
    _generateAndDeliverHash(response);
  }

  Future<void> _generateAndDeliverHash(Map response) async {
    try {
      Map? hashResponse = await CreatorApiServices.generatePayuHash(response);
      if (hashResponse == null && HashService.hasLocalHashConfig) {
        hashResponse = HashService.generateHash(response);
      }
      if (hashResponse != null) {
        if (!mounted) return;
        Provider.of<CartScreenProvider>(context, listen: false)
            .checkoutPro
            .hashGenerated(hash: hashResponse);
        return;
      }
      throw StateError('Unable to obtain PayU hash from server.');
    } catch (e) {
      ApiClient.safeLog('CheckOutScreen', 'PayU hash error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment configuration unavailable. Please contact support or retry shortly.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  onError(Map? response) {
    ApiClient.safeLog('CheckOutScreen', 'PayU Error: $response');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment gateway error. Please retry.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  onPaymentCancel(Map? response) {
    ApiClient.safeLog('CheckOutScreen', 'Payment cancelled by user');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const PaymentFailureScreen(
            error: "Payment cancelled by user",
          ),
        ),
        (route) => false,
      );
    });
  }

  Map<String, dynamic> _extractPayuResponseMap(dynamic response, String fallbackStatus) {
    final provider = Provider.of<CartScreenProvider>(context, listen: false);
    final hp = provider.orderModel?.hashparameter;
    final Map<String, dynamic> payload = {
      'status': fallbackStatus,
      'txnid': hp?.txnid ?? '',
      'udf3': hp?.udf3 ?? '',
    };
    if (response is Map) {
      response.forEach((k, v) {
        payload[k.toString()] = v;
      });
      final inner = response['payuResponse'];
      if (inner is String && inner.isNotEmpty) {
        try {
          final decoded = jsonDecode(inner);
          if (decoded is Map) {
            final result = decoded['result'] is Map ? decoded['result'] : decoded;
            (result as Map).forEach((k, v) {
              payload[k.toString()] = v;
            });
          }
        } catch (_) {}
      }
    }
    return payload;
  }

  @override
  onPaymentFailure(response) {
    ApiClient.safeLog('CheckOutScreen', 'Payment Failure: $response');
    final payload = _extractPayuResponseMap(response, 'failure');
    CreatorApiServices.recordPayuCallback(success: false, payload: payload);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailureScreen(
            error: response?['error_Message']?.toString() ?? "Payment Failed",
          ),
        ),
        (route) => false,
      );
    });
  }

  @override
  onPaymentSuccess(response) {
    ApiClient.safeLog('CheckOutScreen', 'Payment Success: $response');
    final payload = _extractPayuResponseMap(response, 'success');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await CreatorApiServices.recordPayuCallback(
          success: true, payload: payload);
      if (!mounted) return;
      await Provider.of<CartScreenProvider>(context, listen: false)
          .userCart(context: context, isSilent: true);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const PaymentSuccessfulScreen(),
        ),
        (route) => false,
      );
    });
  }
}
