import 'package:flutter/material.dart';

class BackgroundScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool resizeToAvoidBottomInset;

  const BackgroundScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/islamic_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: body,
      ),
    );
  }
}
