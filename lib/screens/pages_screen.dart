import 'package:apni_factory/provider/homeScreen_provider.dart';
import 'package:apni_factory/res/widgets/app_state_views.dart';
import 'package:apni_factory/res/widgets/back_button_widget.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:provider/provider.dart';

class PagesScreen extends StatefulWidget {
  final String slug;
  const PagesScreen({super.key, required this.slug});

  @override
  State<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends State<PagesScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Provider.of<HomeScreenProvider>(context, listen: false)
          .getPage(context: context, slug: widget.slug);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Consumer<HomeScreenProvider>(
        builder: (context, provider, child) {
          if (provider.loadingGetPages) {
            return CircularProgressIndicatorWidget();
          }
          final String pageContent = provider.getPagesModel?.data ?? "";
          final String pageTitle =
              provider.getPagesModel?.name ?? widget.slug.toUpperCase();
          return ListView(
            children: [
              SizedBox(height: height / 26.6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width / 16.2),
                child: BackButtonWidget(title: pageTitle),
              ),
              SizedBox(height: height / 23.5),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width / 16.2),
                child: pageContent.trim().isEmpty
                    ? AppEmptyStateView(
                        title: 'Page content unavailable',
                        subtitle:
                            'No published content was returned for "$pageTitle".',
                        icon: Icons.article_outlined,
                      )
                    : HtmlWidget(pageContent),
              ),
              SizedBox(height: height / 23.5),
            ],
          );
        },
      ),
    );
  }
}
