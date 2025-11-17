import 'package:flutter/material.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/styles/app.text.dart';

class AppButton extends StatelessWidget {
  late Function pressed;
  AppButton({super.key, required this.textString, required this.pressed});
  final String textString;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: pressed(),
        child: Text(textString, style: AppText.subtitle3),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lighter,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ));
  }
}
