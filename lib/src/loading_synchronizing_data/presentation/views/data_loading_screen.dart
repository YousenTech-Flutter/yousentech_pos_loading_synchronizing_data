// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:pos_desktop/core/utils/response_result.dart';
// import 'package:pos_desktop/features/loading_synchronizing_data/domain/loading_synchronizing_data_viewmodel.dart';

// import '../../../../core/config/app_colors.dart';
// import '../../../../core/config/app_lists.dart';
// import '../../../../core/config/app_shared_pr.dart';
// import '../../../../core/shared_widgets/app_button.dart';
// import '../../../../core/shared_widgets/app_close_dialog.dart';

// class ShowLoadedData extends StatefulWidget {
//   const ShowLoadedData({
//     super.key,
//   });

//   @override
//   State<ShowLoadedData> createState() => _ShowLoadedDataState();
// }

// class _ShowLoadedDataState extends State<ShowLoadedData> {
//   LoadingDataController loadingDataController =
//       Get.put(LoadingDataController());
//   // CustomerController customerController = Get.put(CustomerController());
//   late ResponseResult _responseResult;
//   final List<Map> _itemsData = [];
//   final bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();

//     flutterWindowCloseshow(context);
   
//   }


//   @override
//   Widget build(BuildContext context) {
//     return
        
//         Container(
//             width: MediaQuery.of(context).size.width -
//                 MediaQuery.of(context).size.width / 8,
//             height: MediaQuery.of(context).size.height,
//             padding: const EdgeInsets.all(16),
//             color: AppColor.greyWithOpcity,
//             child: GetBuilder<LoadingDataController>(
//                 id: "selected load data",
//                 builder: (_) {
//                   return SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             loadingDataController.count != 0
//                                 ? IconButton(
//                                     icon: loadingDataController.isSelctedAll
//                                         ? const Icon(Icons.check_box_sharp)
//                                         : const Icon(
//                                             Icons.check_box_outline_blank),
//                                     onPressed: () {
//                                       loadingDataController.selectAllLoadData();
//                                     },
//                                     tooltip: "select_All".tr,
//                                     color: AppColor.purple,
//                                     iconSize:
//                                         MediaQuery.of(context).size.width / 50)
//                                 : Container(),
//                             Text(
//                               "Database_Info_Setting".tr,
//                               style: TextStyle(
//                                   fontSize:
//                                       MediaQuery.of(context).size.width * 0.02),
//                             ),
//                             Row(
//                               children: [
//                                 ButtonElevated(
//                                     text: loadingDataController.count == 0 ||
//                                             loadingDataController.isSelctedAll
//                                         ? 'Update_All'.tr
//                                         : 'Update_only'.tr,
//                                     onPressed: () {
//                                       loadingDataController.updateAllLoadData();
//                                     },
//                                     width:
//                                         MediaQuery.of(context).size.width / 10),
//                                 loadingDataController.count != 0
//                                     ? IconButton(
//                                         icon: const Icon(Icons.delete),
//                                         onPressed: () {
//                                           loadingDataController.deletSelected();
//                                         },
//                                         color: AppColor.red,
//                                         iconSize:
//                                             MediaQuery.of(context).size.width /
//                                                 50)
//                                     : Container()
//                               ],
//                             )
//                           ],
//                         ),
//                         Container(
//                             margin: const EdgeInsets.all(8),
//                             padding: const EdgeInsets.all(8),
//                             width: MediaQuery.of(context).size.width -
//                                 MediaQuery.of(context).size.width / 8,
//                             decoration: BoxDecoration(
//                                 color: AppColor.white,
//                                 borderRadius: BorderRadius.circular(15)),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Expanded(
//                                     flex: 2,
//                                     child: Row(
//                                       children: [
//                                         Expanded(flex: 1, child: Container()),
//                                         Expanded(
//                                           flex: 5,
//                                           child: Padding(
//                                             padding: EdgeInsets.only(
//                                                 left: SharedPr.lang == "en"
//                                                     ? 10.0
//                                                     : 0,
//                                                 right: SharedPr.lang == "ar"
//                                                     ? 10.0
//                                                     : 0),
//                                             child: Text(
//                                               "name".tr,
//                                               style: TextStyle(
//                                                   fontSize:
//                                                       MediaQuery.of(context)
//                                                               .size
//                                                               .width *
//                                                           0.01),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     )),
//                                 Expanded(
//                                   flex: 1,
//                                   child: Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceEvenly,
//                                     children: [
//                                       Expanded(
//                                         flex: 2,
//                                         child: Center(
//                                           child: Text(
//                                             "${"local_database".tr} / ${"remote_server".tr}",
//                                             style: TextStyle(
//                                                 fontSize: MediaQuery.of(context)
//                                                         .size
//                                                         .width *
//                                                     0.01),
//                                           ),
//                                         ),
//                                       ),
//                                       Expanded(flex: 1, child: Container())
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             )),
//                         ...loaddata.entries.map((e) {
//                           var targetIndex = _itemsData.indexWhere(
//                               (item) => item.keys.first == e.key.name);
//                           return Container(
//                               margin: const EdgeInsets.all(8),
//                               padding: const EdgeInsets.all(8),
//                               width: MediaQuery.of(context).size.width -
//                                   MediaQuery.of(context).size.width / 8,
//                               decoration: BoxDecoration(
//                                   color: AppColor.white,
//                                   borderRadius: BorderRadius.circular(15)),
//                               child: Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                       flex: 2,
//                                       child: Row(
//                                         children: [
                                         
//                                           Expanded(
//                                             flex: 5,
//                                             child: Padding(
//                                               padding: EdgeInsets.only(
//                                                   left: SharedPr.lang == "en"
//                                                       ? 10.0
//                                                       : 0,
//                                                   right: SharedPr.lang == "ar"
//                                                       ? 10.0
//                                                       : 0),
//                                               child: Text(
//                                                 e.key.name.toString().tr,
//                                                 style: TextStyle(
//                                                     fontSize:
//                                                         MediaQuery.of(context)
//                                                                 .size
//                                                                 .width *
//                                                             0.01),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       )),
//                                   Expanded(
//                                     flex: 1,
//                                     child: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceEvenly,
//                                       children: [
//                                         Expanded(
//                                           flex: 2,
//                                           child:
//                                               GetBuilder<LoadingDataController>(
//                                                   id: "card_loading_data",
//                                                   builder: (_) {
//                                                     return Center(
//                                                       child: Text(
//                                                         "${loadingDataController.itemdata.containsKey(e.key.name.toString()) ? loadingDataController.itemdata[e.key.name.toString()]['local'] : 0} / ${loadingDataController.itemdata.containsKey(e.key.name.toString()) ? loadingDataController.itemdata[e.key.name.toString()]['remote'] : 0}",
                                                        
//                                                         style: TextStyle(
//                                                             fontSize: MediaQuery.of(
//                                                                         context)
//                                                                     .size
//                                                                     .width *
//                                                                 0.01),
//                                                       ),
//                                                     );
//                                                   }),
//                                         ),
                                        
//                                         Expanded(
//                                             flex: 1,
//                                             child: Row(
//                                               children: [
//                                                 Expanded(
//                                                   flex: 2,
//                                                   child: GetBuilder<
//                                                           LoadingDataController>(
//                                                       id: "card_loading_data",
//                                                       builder: (_) {
//                                                         return loadingDataController
//                                                                 .itemdata
//                                                                 .containsKey(e
//                                                                     .key.name
//                                                                     .toString())
//                                                             ? loadingDataController.itemdata[e
//                                                                             .key
//                                                                             .name
//                                                                             .toString()]
//                                                                         [
//                                                                         'local'] !=
//                                                                     loadingDataController.itemdata[e
//                                                                             .key
//                                                                             .name
//                                                                             .toString()]
//                                                                         ['remote']
//                                                                 ? TextButton(
//                                                                     child: const Text(
//                                                                         "show items"),
//                                                                     onPressed:
//                                                                         () async {
//                                                                       await loadingDataController.showDialog(
//                                                                           name: e
//                                                                               .key
//                                                                               .name
//                                                                               .toString());
                                                                      
//                                                                     },
//                                                                   )
//                                                                 : Container()
//                                                             : Container();
//                                                       }),
//                                                 ),
//                                                 Expanded(
//                                                   flex: 1,
//                                                   child: IconButton(
//                                                       onPressed: () async {
//                                                         await loadingDataController
//                                                             .refreshDataFromRemoteServer(
//                                                                 name: e.key.name
//                                                                     .toString());
                                                       
//                                                       },
//                                                       icon: const Icon(Icons
//                                                           .settings_backup_restore_sharp)),
//                                                 ),
//                                               ],
//                                             )),
//                                       ],
//                                     ),
//                                   )
//                                 ],
//                               ));
//                         })
//                       ],
//                     ),
//                   );
//                 }));
//   }
// }
