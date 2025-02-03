import 'package:pos_shared_preferences/models/basic_item_history.dart';

abstract class BasicItemProcessor<T> {
  bool shouldInsert({required BasicItemHistory element, List<int>? posCategoryIds});
  bool shouldUpdate({required BasicItemHistory element, List<int>? posCategoryIds});
  bool shouldDelete({required BasicItemHistory element});

  // object T or int
  dynamic processElement({required BasicItemHistory element, bool isDelete = false});
}
