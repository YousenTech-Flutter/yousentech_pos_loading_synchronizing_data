
import 'package:pos_shared_preferences/models/basic_item_history.dart';
import 'package:pos_shared_preferences/models/customer_model.dart';

import 'main_history_item_processor.dart';

class CustomerProcessor extends BasicItemProcessor<Customer> {
  final List<int> localIds;
  CustomerProcessor({required this.localIds});

  @override
  bool shouldInsert({required BasicItemHistory element, List<int>? posCategoryIds}) {
    if(element.customer == null) {
      return false;
    }
    return (!localIds.contains(element.customerId) && element.isAdded! && !element.isDeleted!)
        ||(!localIds.contains(element.customerId) && element.isAdded! && element.isDeleted!);
  }

  @override
  bool shouldUpdate({required BasicItemHistory element, List<int>? posCategoryIds}) {
    if(element.customer == null) {
      return false;
    }
    return (!element.isAdded! && !element.isDeleted!) ||
        (localIds.contains(element.customerId) &&
            element.isAdded! &&
            !element.isDeleted!);
  }

  @override
  bool shouldDelete({required BasicItemHistory element}) {
    return localIds.contains(element.customerId) && element.isDeleted!;
  }

  @override
  dynamic processElement({required BasicItemHistory element, bool isDelete = false}) {
    return !isDelete ? element.customer! : element.customerId;
  }
}
