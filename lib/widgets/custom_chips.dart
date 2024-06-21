import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/Utils/custom_screen.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/constants/selected_tags.dart';

class Chips extends StatelessWidget {
  final List<String> tags = ['Sport', 'Love', 'Movie', 'Music', 'Travel', 'Food'];

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(2.0),
        child: 
            CustomChipSelection(tags: tags),
           
         );
    
  }
}

class CustomChipSelection extends StatefulWidget {
  final List<String> tags;

  CustomChipSelection({required this.tags});

  @override
  _CustomChipSelectionState createState() => _CustomChipSelectionState();
}

class _CustomChipSelectionState extends State<CustomChipSelection> {

  void _toggleSelection(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        if (selectedTags.length < 3) {
          selectedTags.add(tag);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You can select up to 3 tags only')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      
      spacing: 5.0,
      children: widget.tags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return ChoiceChip(
          
          label: Text(tag),
          
          selected: isSelected,
          onSelected: (_) => _toggleSelection(tag),
          selectedColor: Colors.red,
          backgroundColor: Color.fromARGB(25, 158, 158, 158),
          labelStyle: style(family: AppFonts.gRegular, size: Get.width * .035)
        );
      }).toList(),
    );
  }
}
