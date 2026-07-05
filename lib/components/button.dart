import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;

  const MyButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppColors.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.buttonRadius),
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
