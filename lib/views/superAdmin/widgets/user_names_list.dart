import 'package:flutter/material.dart';
import '../../../data/user_names_model.dart';


class UserNamesList extends StatelessWidget {

  final List<UserNamesModel> userNames;
  final List<UserNamesModel> selectedUserNames;
  final void Function(UserNamesModel) onUserSelected;

  const UserNamesList({super.key,
    required this.userNames,
    required this.selectedUserNames,
    required this.onUserSelected
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: userNames.length,
      itemBuilder: (context, index) {
        return CheckboxListTile(
          title: Text(userNames[index].name),
          subtitle: Text(userNames[index].email),
          value: selectedUserNames.contains(userNames[index]),
          onChanged: (bool? value) {
            onUserSelected(userNames[index]);
          },
        );
      },
    );
  }

}
