import 'package:get/get.dart';

class LoadingItemsCountController extends GetxController {
  var loadingItemCount = 0.obs;

  /// ============================ [ Increase Loading Item Count ] ============================
  /// Functionality:
  /// - This function increments the `loadingItemCount` by 1.
  /// - It is used to track the number of items being loaded or processed.
  ///
  /// Process:
  /// 1. The value of the `loadingItemCount` variable is increased by 1 each time this function is called.
  /// 2. The state of the `loadingItemCount` variable is updated, and changes can be logged in debug mode if needed.
  ///
  /// Input:
  /// - No explicit input. The function works with the existing `loadingItemCount` variable.
  ///
  /// Raises:
  /// - No explicit exceptions.
  ///
  /// Returns:
  /// - No return value. It modifies the state of the `loadingItemCount` variable.
  void increaseLoadingItemCount() {
    loadingItemCount.value++;
    // if (kDebugMode) {
    //   print('increase loadingItemCount: ${loadingItemCount.value}');
    // }
  }

  /// ============================ [ Increase Loading Item Count ] ============================
  /// ============================ [ Reset Loading Item Count ] ============================
  /// Functionality:
  /// - This function resets the `loadingItemCount` to 0.
  /// - It is commonly used after completing a loading or processing operation.
  ///
  /// Process:
  /// 1. The `loadingItemCount` value is reset to 0 after the items have been processed or loaded.
  /// 2. The state of the `loadingItemCount` variable is updated, and changes can be logged in debug mode if needed.
  ///
  /// Input:
  /// - No explicit input. The function works with the existing `loadingItemCount` variable.
  ///
  /// Raises:
  /// - No explicit exceptions.
  ///
  /// Returns:
  /// - No return value. It resets the `loadingItemCount` variable to 0.

  void resetLoadingItemCount() {
    loadingItemCount.value = 0;
    // if (kDebugMode) {
    //   print('reset loadingItemCount: ${loadingItemCount.value}');
    // }
  }

  /// ============================ [ Reset Loading Item Count ] ============================
}
