import 'package:flutter/material.dart';
import 'package:live_13/data/user_names_model.dart';
import 'package:live_13/views/superAdmin/widgets/user_names_list.dart';
import '../../Config/app_colors.dart';
import '../../config/app_fonts.dart';
import '../../constants/constant_text.dart';
import '../../services/databaseService/database_services.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {

  bool loading = true;
  List<UserNamesModel> userNames = [];
  List<UserNamesModel> selectedUserNames = [];

  @override
  void initState() {
    fetchingUserNames();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading && userNames.isEmpty
      ? Center(
        child: CircularProgressIndicator(
          color: AppColor.red,
        ),
      ):userNames.isEmpty
          ? Center(
            child: Text(AppText.noDataFound,style: TextStyle(fontSize: 22,fontFamily: AppFonts.gSemiBold),)
      ):
      UserNamesList(
        userNames: userNames,
        selectedUserNames: selectedUserNames,
        onUserSelected: handleUserSelected,
      ),
    );
  }

  fetchingUserNames() async {
    userNames = await DatabaseServices().fetchUsernames();
    setState(() {
      loading = false;
    });
  }
  void handleUserSelected(UserNamesModel user) {
    setState(() {
      if (selectedUserNames.contains(user)) {
        selectedUserNames.remove(user);
      } else {
        selectedUserNames.add(user);
      }
    });
  }
}
