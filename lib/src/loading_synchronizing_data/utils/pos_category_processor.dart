
import 'package:pos_shared_preferences/models/basic_item_history.dart';
import 'package:pos_shared_preferences/models/pos_categories_data/pos_category.dart';

import 'main_history_item_processor.dart';

class PosCategoryProcessor extends BasicItemProcessor<PosCategory> {
  final List<int> localIds;

  PosCategoryProcessor({required this.localIds});

  @override
  bool shouldInsert({required BasicItemHistory element, posCategoryIds}) {
    return !localIds.contains(element.categoryId) && element.isAdded!;
  }

  @override
  bool shouldUpdate({required BasicItemHistory element, posCategoryIds}) {
    return (!element.isAdded! && !element.isDeleted!) ||
        (localIds.contains(element.categoryId) &&
            element.isAdded! &&
            !element.isDeleted!);
  }

  @override
  bool shouldDelete({required BasicItemHistory element}) {
    return localIds.contains(element.categoryId) && element.isDeleted!;
  }

  @override
  dynamic processElement({required BasicItemHistory element, bool isDelete = false}) {
    return !isDelete ? element.category! : element.categoryId!;
  }
}
