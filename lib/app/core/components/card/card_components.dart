import 'package:br_thp_meubenapp/app/core/theme/app_colors.dart';
import 'package:br_thp_meubenapp/app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class CardComponents extends StatelessWidget {
  const CardComponents({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String image;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDD6E6)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Row(
              children: [
                Image.asset(image, width: 32, height: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: AppTextStyles.bodyText1.copyWith(
                          fontSize: 26 / 2,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: const Color(0xFF2F3338),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: AppTextStyles.bodyText2.copyWith(
                            fontSize: 24 / 2,
                            height: 1.1,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5E7392),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
