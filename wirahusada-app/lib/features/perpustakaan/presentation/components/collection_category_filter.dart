import 'package:flutter/material.dart';

class CollectionCategoryFilter extends StatelessWidget {
  final String selectedValue;
  final List<String> categoryList;
  final ValueChanged<String?> onChanged;

  const CollectionCategoryFilter({
    super.key,
    required this.selectedValue,
    required this.categoryList,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          items: categoryList.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
