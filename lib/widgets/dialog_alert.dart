import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:live_13/Config/app_spacing.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/commonWidgets/customTextField.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/constants/selected_tags.dart';
import 'package:live_13/services/create_room.dart';
import 'package:live_13/widgets/custom_chips.dart';
import 'package:live_13/widgets/small_button.dart';

void showCustomDialog({
  required BuildContext context, 
}) {
  final TextEditingController NameController = TextEditingController();
    final TextEditingController DescController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      // title: Text("Alert Dialog Box"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppText.CreateNewRoom,
            style: style(family: AppFOnts.gBold, size: 20),
          ),
          SizedBox(
            height: space10,
          ),
          CustomTextField(
            controller: NameController,
            hintText: AppText.EnterRoomName,
          ),
          SizedBox(
            height: space8,
          ),
          CustomTextField(
            controller: DescController,
            hintText: AppText.EnterDesc,
          ),
          SizedBox(
            height: space4,
          ),
          Chips(),
          // SizedBox(
          //   height: space10,
          // ),
          SmallCustomButton(
            text: 'Create Room',
            onTap: () {
             addRoomData(
              NameController.text.toString(),
              DescController.text.toString(),
              selectedTags,
              context
            );
            },
          )
        ],
      ),
    ),
  );
}
