import 'package:br_thp_meubenapp/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ButtonDefault extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final IconData? iconLeft;
  final IconData? iconRight;

  const ButtonDefault({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.iconLeft,
    this.iconRight,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconLeft != null) ...[
                  Icon(iconLeft),
                  const SizedBox(width: 8),
                ],
                Text(text),
                if (iconRight != null) ...[
                  const SizedBox(width: 8),
                  Icon(iconRight),
                ],
              ],
            ),
    );
  }
}
