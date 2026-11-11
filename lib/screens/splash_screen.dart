import 'package:apni_factory/api_services/notification_services.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/screens/all_screen.dart';
import 'package:apni_factory/screens/sign_in.dart';
import 'package:apni_factory/shared_pref.dart';
import 'package:flutter/material.dart';

class SpalshScreen extends StatefulWidget {
  final Duration splashDelay;

  const SpalshScreen({
    super.key,
    this.splashDelay = const Duration(milliseconds: 800),
  });

  @override
  State<SpalshScreen> createState() => _SpalshScreenState();
}

class _SpalshScreenState extends State<SpalshScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Init notifications non-blockingly and safely even if Firebase is unconfigured
    NotificationServices().init(context).catchError((_) {});

    final bool isLoggedIn = await SharedPref.getIsLoggedIn();
    if (widget.splashDelay > Duration.zero) {
      await Future.delayed(widget.splashDelay);
    }

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AllScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
      double height = MediaQuery.of(context).size.height;
   
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Center(
        child: Image.asset(AppAssetImage.logo,height: height/15,),
      ),
    );
  }
}
