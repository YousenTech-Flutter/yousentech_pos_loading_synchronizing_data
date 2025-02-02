import 'package:get/get.dart';
import 'package:yousentech_pos_loading_synchronizing_data/yousentech_pos_loading_synchronizing_data.dart';

LoadingDataController loadingDataController = Get.find<LoadingDataController>();

// LoadingDataController loadingDataController = Get.put(LoadingDataController());
// Future<void> fetchData({required Loaddata loadData}) async {
//   print("loadData+++++++++ ${loadData.name}");
//   loaddata[loadData]!.first = false;
//   loaddata[loadData]!.last = false;
//   loadingDataController.update(['card_loading_data']);
//   ResponseResult? responseResult;
//   switch (loadData) {
//     case Loaddata.products:
//       responseResult = await loadingDataController.fetchData<Product>();
//
//       break;
//     case Loaddata.categories:
//       responseResult = await loadingDataController.fetchData<PosCategory>();
//
//       break;
//     case Loaddata.customers:
//       responseResult = await loadingDataController.fetchData<Customer>();
//
//       break;
//     case Loaddata.paymentType:
//       responseResult =
//           ResponseResult(status: true, data: {"remote": 0, "local": 0});
//       break;
//     case Loaddata.posInfo:
//       responseResult = ResponseResult(
//           status: true,
//           data: {"remote": SharedPr.userObj!.posConfigIds!.length, "local": 0});
//       break;
//     case Loaddata.productUnit:
//       responseResult = await loadingDataController.fetchData<ProductUnit>();
//       break;
//     case Loaddata.priceList:
//       responseResult =
//           ResponseResult(status: true, data: {"remote": 0, "local": 0});
//       break;
//     case Loaddata.stockWarehouses:
//       responseResult =
//           ResponseResult(status: true, data: {"remote": 0, "local": 0});
//       break;
//     case Loaddata.userPermissions:
//       responseResult =
//           ResponseResult(status: true, data: {"remote": 0, "local": 0});
//       break;
//     case Loaddata.vendors:
//       responseResult =
//           ResponseResult(status: true, data: {"remote": 0, "local": 0});
//       break;
//     default:
//   }
//
//   print("hhhhhhhhhhi ++++++++");
//
//   if (responseResult!.status) {
//     print("status 1 ++++++++");
//     loadingDataController.itemdata[loadData.name.toString()] =
//         responseResult.data;
//     print("status 2 ++++++++");
//     loaddata[loadData]!.first = true;
//     print("status 3 ++++++++");
//   } else {
//     print("status 4 ++++++++");
//     loaddata[loadData]!.first = true;
//     print("status 5 ++++++++");
//     loaddata[loadData]!.last = true;
//     print("status 6++++++++");
//   }
//   print("status 7 ++++++++");
//   loadingDataController.update(['card_loading_data']);
//   print("status 8 ++++++++");
// }
