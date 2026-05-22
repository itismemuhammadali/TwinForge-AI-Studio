import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppFonts.poppins(
                size: 10,
                weight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1A1A1A),
            items: options.map<DropdownMenuItem<String>>((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    option,
                    style: AppFonts.poppins(
                      size: 12,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
            style: AppFonts.poppins(
              size: 12,
              color: AppColors.white,
            ),
            icon: Icon(
              Icons.expand_more,
              color: AppColors.gold.withValues(alpha: 0.6),
            ),
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
