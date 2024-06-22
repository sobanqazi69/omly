import 'package:get/get.dart';

class RoomController extends GetxController {
  var showDot = false.obs;
  var currentIndex = 0.obs;
  var previousIndex = 0.obs;
  var messagesCount = 0.obs;
  RxBool selectedConnectedTab = false.obs;

  dotValue(bool val) {
    showDot.value = val;
  }

}
