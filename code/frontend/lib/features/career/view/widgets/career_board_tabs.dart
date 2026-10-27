import 'package:flutter/material.dart';

/// Alumni switch between the public board and their complete author history.
class CareerBoardTabs extends StatelessWidget {
  const CareerBoardTabs({
    required this.alumni,
    required this.secondarySelected,
    required this.onChanged,
    super.key,
  });

  final bool alumni;
  final bool secondarySelected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: const Text('Browse opportunities'),
        avatar: const Icon(Icons.search, size: 18),
        selected: !secondarySelected,
        onSelected: onChanged == null ? null : (_) => onChanged!(false),
      ),
      ChoiceChip(
        label: Text(alumni ? 'My career posts' : 'Saved'),
        avatar: Icon(
          alumni ? Icons.work_outline : Icons.bookmark_border,
          size: 18,
        ),
        selected: secondarySelected,
        onSelected: onChanged == null ? null : (_) => onChanged!(true),
      ),
    ],
  );
}
