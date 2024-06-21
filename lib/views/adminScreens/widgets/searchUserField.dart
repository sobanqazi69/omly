import 'package:flutter/material.dart';
import 'package:live_13/Utils/custom_screen.dart';
import 'package:live_13/data/user_names_model.dart';
import '../../../config/app_fonts.dart';

class CustomDropdownTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final List<UserNamesModel> items;

  CustomDropdownTextField({
    required this.controller,
    required this.hintText,
    required this.items,
  });

  @override
  _CustomDropdownTextFieldState createState() => _CustomDropdownTextFieldState();
}

class _CustomDropdownTextFieldState extends State<CustomDropdownTextField> {
  bool _isDropdownOpened = false;
  List<UserNamesModel> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpened = !_isDropdownOpened;
    });
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: IconButton(
              icon: Icon(_isDropdownOpened ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              onPressed: _toggleDropdown,
            ),
          ),
          onChanged: (value) {
            _filterItems(value);
            if (!_isDropdownOpened) {
              setState(() {
                _isDropdownOpened = true;
              });
            }
          },
        ),
        if (_isDropdownOpened)
          Container(
            height: CustomScreenUtil.getHeightDimensions(0.2),
            width: CustomScreenUtil.getWidthDimensions(0.9),
            child: ListView(
              children: _filteredItems.map((UserNamesModel item) {
                return ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(fontFamily: AppFonts.gRegular),
                  ),
                  subtitle: Text(
                    item.email,
                    style: TextStyle(fontFamily: AppFonts.gRegular),
                  ),
                  onTap: () {
                    widget.controller.text = item.name;
                    setState(() {
                      _isDropdownOpened = false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
