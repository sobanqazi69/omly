import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:live_13/data/user_names_model.dart';
import 'package:live_13/views/superAdmin/controller/super_admin_controller.dart';
import 'package:live_13/views/superAdmin/widgets/user_names_list.dart';
import '../../Config/app_colors.dart';
import '../../config/app_fonts.dart';
import '../../constants/constant_text.dart';
import '../../services/auth_service.dart';
import '../../services/databaseService/database_services.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  bool loading = true;
  bool isAssigningAdmin = false;
  bool isAssigningParticipant = false;
  bool isBlockingUsers = false;
  bool isUnblockingUsers = false;

  List<UserNamesModel> participantUserNames = [];
  List<UserNamesModel> adminUserNames = [];
  List<UserNamesModel> blockedUserNames = [];
  List<UserNamesModel> unblockedUserNames = [];

  List<UserNamesModel> selectedAdminUserNames = [];
  List<UserNamesModel> selectedParticipantUserNames = [];
  List<UserNamesModel> selectedBlockedUserNames = [];
  List<UserNamesModel> selectedUnblockedUserNames = [];

  SuperAdminController _superAdminController = Get.put(SuperAdminController());

  @override
  void initState() {
    fetchingUserNames();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.red,
          actions: [
            IconButton(
              onPressed: () {
                AuthService().signOutFromGoogle(context);
              },
              icon: Icon(Icons.logout),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Participants'),
              Tab(text: 'Admins'),
              Tab(text: 'Blocked Users'),
              Tab(text: 'Unblocked Users'),
            ],
          ),
        ),
        body: loading
            ? Center(
          child: CircularProgressIndicator(
            color: AppColor.red,
          ),
        )
            : TabBarView(
          children: [
            buildUserList(
              userNames: participantUserNames,
              selectedUserNames: selectedParticipantUserNames,
              onUserSelected: handleParticipantUserSelected,
              onAssignRole: assignAdminRole,
              buttonText: AppText.addAsAdmin,
              isLoading: isAssigningAdmin,
            ),
            buildUserList(
              userNames: adminUserNames,
              selectedUserNames: selectedAdminUserNames,
              onUserSelected: handleAdminUserSelected,
              onAssignRole: assignParticipantRole,
              buttonText: AppText.removeFromAdmin,
              isLoading: isAssigningParticipant,
            ),
            buildUserList(
              userNames: blockedUserNames,
              selectedUserNames: selectedBlockedUserNames,
              onUserSelected: handleBlockedUserSelected,
              onAssignRole: unblockUsers,
              buttonText: AppText.unblockTheseUsers,
              isLoading: isUnblockingUsers,
            ),
            buildUserList(
              userNames: unblockedUserNames,
              selectedUserNames: selectedUnblockedUserNames,
              onUserSelected: handleUnblockedUserSelected,
              onAssignRole: blockUsers,
              buttonText: AppText.blockTheseUsers,
              isLoading: isBlockingUsers,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserList({
    required List<UserNamesModel> userNames,
    required List<UserNamesModel> selectedUserNames,
    required void Function(UserNamesModel) onUserSelected,
    required Future<void> Function() onAssignRole,
    required String buttonText,
    required bool isLoading,
  }) {
    return Column(
      children: [
        Expanded(
          child: UserNamesList(
            userNames: userNames,
            selectedUserNames: selectedUserNames,
            onUserSelected: onUserSelected,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: isLoading ? null : onAssignRole,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              padding: EdgeInsets.all(15),
            ),
            child: isLoading
                ? CircularProgressIndicator(
              color: Colors.white,
            )
                : Text(
              buttonText,
              style: TextStyle(
                fontFamily: AppFonts.gSemiBold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> assignAdminRole() async {
    setState(() {
      isAssigningAdmin = true;
    });
    if (selectedParticipantUserNames.isNotEmpty) {
      bool success = await _superAdminController.assignAdminRole(selectedParticipantUserNames);
      if (success) {
        setState(() {
          for (var user in selectedParticipantUserNames) {
            participantUserNames.remove(user);
            adminUserNames.add(user);
          }
          selectedParticipantUserNames.clear();
        });
      } else {
        Get.snackbar(
          AppText.error,
          AppText.failedToAssignRole,
          backgroundColor: HexColor('#cccccc'),
        );
      }
    } else {
      Get.snackbar(
        AppText.error,
        AppText.selectUsersToAssignAdminRole,
        backgroundColor: HexColor('#cccccc'),
      );
    }
    setState(() {
      isAssigningAdmin = false;
    });
  }

  Future<void> assignParticipantRole() async {
    setState(() {
      isAssigningParticipant = true;
    });
    if (selectedAdminUserNames.isNotEmpty) {
      bool success = await _superAdminController.assignParticipantRole(selectedAdminUserNames);
      if (success) {
        setState(() {
          for (var user in selectedAdminUserNames) {
            adminUserNames.remove(user);
            participantUserNames.add(user);
          }
          selectedAdminUserNames.clear();
        });
      } else {
        Get.snackbar(
          AppText.error,
          AppText.failedToAssignRole,
          backgroundColor: HexColor('#cccccc'),
        );
      }
    } else {
      Get.snackbar(
        AppText.error,
        AppText.selectUsersToAssignAdminRole,
        backgroundColor: HexColor('#cccccc'),
      );
    }
    setState(() {
      isAssigningParticipant = false;
    });
  }

  Future<void> blockUsers() async {
    setState(() {
      isBlockingUsers = true;
    });
    if (selectedUnblockedUserNames.isNotEmpty) {
      bool success = await _superAdminController.blockUsers(selectedUnblockedUserNames);
      if (success) {
        setState(() {
          for (var user in selectedUnblockedUserNames) {
            unblockedUserNames.remove(user);
            blockedUserNames.add(user);
          }
          selectedUnblockedUserNames.clear();
        });
      } else {
        Get.snackbar(
          AppText.error,
          AppText.failedToAssignRole,
          backgroundColor: HexColor('#cccccc'),
        );
      }
    } else {
      Get.snackbar(
        AppText.error,
        AppText.selectUsersToBlock,
        backgroundColor: HexColor('#cccccc'),
      );
    }
    setState(() {
      isBlockingUsers = false;
    });
  }

  Future<void> unblockUsers() async {
    setState(() {
      isUnblockingUsers = true;
    });
    if (selectedBlockedUserNames.isNotEmpty) {
      bool success = await _superAdminController.unblockUsers(selectedBlockedUserNames);
      if (success) {
        setState(() {
          for (var user in selectedBlockedUserNames) {
            blockedUserNames.remove(user);
            unblockedUserNames.add(user);
          }
          selectedBlockedUserNames.clear();
        });
      } else {
        Get.snackbar(
          AppText.error,
          AppText.failedToUnblockUsers,
          backgroundColor: HexColor('#cccccc'),
        );
      }
    } else {
      Get.snackbar(
        AppText.error,
        AppText.selectUsersToUnblock,
        backgroundColor: HexColor('#cccccc'),
      );
    }
    setState(() {
      isUnblockingUsers = false;
    });
  }

  fetchingUserNames() async {
    List<UserNamesModel> adminAndParticipantUsers = [
      ...await DatabaseServices().fetchAdminUserNames(),
      ...await DatabaseServices().fetchParticipantUserNames()
    ];

    setState(() {
      adminUserNames = adminAndParticipantUsers.where((user) => !user.isBlocked).toList();
      participantUserNames = adminAndParticipantUsers.where((user) => !user.isBlocked).toList();
      blockedUserNames = adminAndParticipantUsers.where((user) => user.isBlocked).toList();
      unblockedUserNames = adminAndParticipantUsers.where((user) => !user.isBlocked).toList();
      loading = false;
    });
  }

  void handleParticipantUserSelected(UserNamesModel user) {
    setState(() {
      if (selectedParticipantUserNames.contains(user)) {
        selectedParticipantUserNames.remove(user);
      } else {
        selectedParticipantUserNames.add(user);
      }
    });
  }

  void handleAdminUserSelected(UserNamesModel user) {
    setState(() {
      if (selectedAdminUserNames.contains(user)) {
        selectedAdminUserNames.remove(user);
      } else {
        selectedAdminUserNames.add(user);
      }
    });
  }

  void handleBlockedUserSelected(UserNamesModel user) {
    setState(() {
      if (selectedBlockedUserNames.contains(user)) {
        selectedBlockedUserNames.remove(user);
      } else {
        selectedBlockedUserNames.add(user);
      }
    });
  }

  void handleUnblockedUserSelected(UserNamesModel user) {
    setState(() {
      if (selectedUnblockedUserNames.contains(user)) {
        selectedUnblockedUserNames.remove(user);
      } else {
        selectedUnblockedUserNames.add(user);
      }
    });
  }
}
