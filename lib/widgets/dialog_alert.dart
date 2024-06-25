import 'package:flutter/material.dart';
import 'package:live_13/Config/app_spacing.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/commonWidgets/customTextField.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/constants/selected_tags.dart';
import 'package:live_13/data/user_names_model.dart';
import 'package:live_13/services/create_room.dart';
import 'package:live_13/services/databaseService/database_services.dart';
import 'package:live_13/widgets/custom_chips.dart';
import 'package:live_13/widgets/small_button.dart';
import '../views/adminScreens/widgets/searchUserField.dart';

void showCustomDialog({
  required BuildContext context,
}) async {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController userController = TextEditingController();

  List<UserNamesModel> userNames = await DatabaseServices().fetchAdminUserNames();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              AppText.CreateNewRoom,
              style: style(family: AppFonts.gBold, size: 20),
            ),
            SizedBox(height: space10),
            CustomTextField(
              controller: nameController,
              hintText: AppText.EnterRoomName,
            ),
            SizedBox(height: space8),
            CustomTextField(
              controller: descController,
              hintText: AppText.EnterDesc,
            ),
            SizedBox(height: space8),
            // CustomDropdownTextField(
            //   controller: userController,
            //   hintText: 'Select User',
            //   items: userNames,
            // ),
            SizedBox(height: space4),
            Chips(),
            SmallCustomButton(
              text: 'Create Room',
              onTap: () {
                addRoomData(
                    nameController.text.toString(),
                    descController.text.toString(),
                    selectedTags,
                    context
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
