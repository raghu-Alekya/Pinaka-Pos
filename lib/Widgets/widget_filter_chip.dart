import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget { // Build #1.0.8, Surya added
  final String label;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const FilterChipWidget({
    Key? key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Chip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor:
          selectedValue != "All" ? Colors.redAccent : Colors.grey.shade200,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label ',
                    // ': $selectedValue',
                style: TextStyle(
                    color: selectedValue != "All" ? Colors.white : Colors.black),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: selectedValue != "All" ? Colors.white : Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
