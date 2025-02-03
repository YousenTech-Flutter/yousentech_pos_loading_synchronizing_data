import 'package:get/get.dart';

class LoadingItemsCountController extends GetxController {
  var loadingItemCount = 0.obs;

  void increaseLoadingItemCount() {
    loadingItemCount.value++;
  }

  void resetLoadingItemCount() {
    loadingItemCount.value = 0;
  }
}