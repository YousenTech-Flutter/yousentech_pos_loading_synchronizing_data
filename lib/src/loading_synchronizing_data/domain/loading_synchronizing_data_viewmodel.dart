// ignore_for_file: type_literal_in_constant_pattern, unnecessary_type_check

import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:pos_shared_preferences/helper/app_enum.dart';
import 'package:pos_shared_preferences/models/account_journal/data/account_journal.dart';
import 'package:pos_shared_preferences/models/account_journal/data/account_journal_name.dart';
import 'package:pos_shared_preferences/models/account_tax/data/account_tax.dart';
import 'package:pos_shared_preferences/models/basic_item_history.dart';
import 'package:pos_shared_preferences/models/count_items.dart';
import 'package:pos_shared_preferences/models/customer_model.dart';
import 'package:pos_shared_preferences/models/pos_categories_data/pos_category.dart';
import 'package:pos_shared_preferences/models/pos_session_model.dart';
import 'package:pos_shared_preferences/models/pos_setting_info_model.dart';
import 'package:pos_shared_preferences/models/printing_prefrences.dart';
import 'package:pos_shared_preferences/models/product_data/product.dart';
import 'package:pos_shared_preferences/models/product_unit/data/product_unit.dart';
import 'package:pos_shared_preferences/pos_shared_preferences.dart';
import 'package:shared_widgets/config/app_enum.dart';
import 'package:shared_widgets/shared_widgets/app_snack_bar.dart';
import 'package:shared_widgets/shared_widgets/handle_exception_helper.dart';
import 'package:shared_widgets/utils/mac_address_helper.dart';
import 'package:shared_widgets/utils/response_result.dart';
import 'package:yousentech_pos_basic_data_management/yousentech_pos_basic_data_management.dart';
import 'package:yousentech_pos_loading_synchronizing_data/config/app_enums.dart';
import 'package:yousentech_pos_loading_synchronizing_data/config/app_list.dart';
import 'package:yousentech_pos_loading_synchronizing_data/src/loading_synchronizing_data/domain/loading_item_count_controller.dart';
import 'package:yousentech_pos_loading_synchronizing_data/src/loading_synchronizing_data/utils/fail_loading_dialog.dart';
import 'package:yousentech_pos_loading_synchronizing_data/src/loading_synchronizing_data/utils/pos_category_processor.dart';
import 'package:yousentech_pos_loading_synchronizing_data/utils/define_type_function.dart';
import 'package:yousentech_pos_local_db/yousentech_pos_local_db.dart';
import '../utils/customer_processor.dart';
import '../utils/main_history_item_processor.dart';
import '../utils/product_processor.dart';
import 'loading_synchronizing_data_service.dart';

class LoadingDataController extends GetxController {
  var isLoad = false.obs;
  var isRefresh = false.obs;
  var isUpdate = false.obs;
  var loadTital = ''.obs;
  Map itemdata = {};
  bool isSelctedAll = false;
  String? itemUpdate;
  var countLoadData = RxMap();
  var lengthRemote = 0.obs;
  var isLoadData = false.obs;
  GeneralLocalDB? _instance;

  int count = 0;
  late LoadingSynchronizingDataService loadingSynchronizingDataService =
      LoadingSynchronizingDataService();
  List<int> posCategoryIdsList = [];

  final ItemHistoryController _itemHistoryController = ItemHistoryController();

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      await loadingPosCategoryIdsList();
      await executeLoadingProcessBasedOnType();

      update(['loading']);
    } catch (e) {
      failLoadingDialog();
    }
  }

  executeLoadingProcessBasedOnType() async {
    await loadingPosCategories(posCategoriesIds: posCategoryIdsList);
    await loadingProduct(posCategoriesIds: posCategoryIdsList);
    await loadingCustomer();
    await loadingProductUnit();
    await loadingAccountTax();
    await loadingAccountJournal();
    await loadingPosSession();
    await getitems();
  }

  Future<int?> checkCount<T>() async {
    _instance = getLocalInstanceType<T>();
    int? count = await _instance!.checkIfThereIsRowsInTable();
    return count;
  }

  // =================================================== [ LOADING CURRENT POS SETTING ] ==========================================================
  Future<dynamic> loadingCurrentPosSetting({required int posSettingId}) async {
    isLoad.value = true;
    dynamic result = await loadingSynchronizingDataService
        .loadCurrentUserPosSettingInfo(posSettingId: posSettingId);
    if (result is PosSettingInfo) {
      await SharedPr.setCurrentPosObj(posObject: result);
      // change
      // await SharedPr.setPrintingPreferenceObj(
      //     printingPreferenceObj: PrintingPreference(
      //   showPreview: result.showPreview,
      //   isSilentPrinting:
      //       result.printingMode == PrintingType.is_silent_printing.name
      //           ? true
      //           : false,
      //   isShowPrinterDialog:
      //       result.printingMode == PrintingType.is_show_printer_dialog.name
      //           ? true
      //           : false,
      //   isDownloadPDF: result.isDownloadPDF,
      //   downloadPath: result.downloadPath,
      //   showPosPaymentSummary: result.showPosPaymentSummary,
      //   disablePrinting:
      //       result.printingMode == PrintingType.disable_printing.name
      //           ? true
      //           : false,
      // ));
      //===
      var company = await loadingSynchronizingDataService.loadCurrentCompany(
          companyId: SharedPr.currentPosObject!.companyId!);
      if (company != null && company is Customer) {
        await SharedPr.setCurrentCompany(company: company);
        result = ResponseResult(
            status: true, message: "Successful".tr, data: result);
      } else {
        result = ResponseResult(status: true, message: " ".tr, data: result);
      }
    } else {
      result = ResponseResult(message: result);
    }
    isLoad.value = false;
    return result;
  }

  // =================================================== [ LOADING CURRENT POS SETTING ] ==========================================================

  // =================================================== [ LOADING CURRENT POS SETTING CATEGORIES ] ==========================================================
  Future<dynamic> loadingPosCategoryIdsList() async {
    ResponseResult posSettingInfoListResult = await loadingCurrentPosSetting(
        posSettingId: SharedPr.currentPosObject!.id!);

    if (posSettingInfoListResult.status &&
        (posSettingInfoListResult.data as PosSettingInfo)
            .posCategoryIds!
            .isNotEmpty) {
      posCategoryIdsList =
          (posSettingInfoListResult.data as PosSettingInfo).posCategoryIds!;
    }
    return posCategoryIdsList;
  }

  // =================================================== [ LOADING CURRENT POS SETTING CATEGORIES ] ==========================================================

  // ============================================================= [ START LOADING BASIC DATA ] ====================================================================

  // [ LOADING PRODUCT UNITS ] ==========================================================
  Future<void> loadingProductUnit() async {
    int? count = await checkCount<ProductUnit>();
    List<ProductUnit> list = [];
    try {
      if (count != null && count == 0) {
        isLoad.value = true;
        loadTital.value = "Product Unit Loading";
        isLoadData.value = true;
        lengthRemote.value = 0;
        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        list = await loadingSynchronizingDataService.loadProductUnitData();
        isLoadData.value = false;
        if (list is List) {
          loadTital.value = "Create Product Unit";
          lengthRemote.value = list.length;
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      await saveInLocalDB<ProductUnit>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }

  Future<void> loadingAccountTax() async {
    int? count = await checkCount<AccountTax>();
    List<AccountTax> list = [];
    try {
      if (count != null && count == 0) {
        isLoad.value = true;
        loadTital.value = "Account Tax Loading";
        isLoadData.value = true;
        lengthRemote.value = 0;
        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        list = await loadingSynchronizingDataService.loadAccountTaxData();
        isLoadData.value = false;
        if (list is List) {
          loadTital.value = "Create Account Tax";
          lengthRemote.value = list.length;
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      await saveInLocalDB<AccountTax>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }

  Future<void> loadingAccountJournal() async {
    int? count = await checkCount<AccountJournal>();
    List<AccountJournal> list = [];
    try {
      if (count != null && count == 0) {
        isLoad.value = true;
        loadTital.value = "Account Journal Loading";
        isLoadData.value = true;
        lengthRemote.value = 0;
        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        list = await loadingSynchronizingDataService.loadAccountJournalData();
        isLoadData.value = false;
        if (list is List) {
          list.add(AccountJournal(
            id: SharedPr.currentPosObject!.creditJournalId,
            name: AccountJournalName(
                enUS: SharedPr.currentPosObject!.creditJournalName,
                ar001: "فاتورة العميل"),
            postPaidAccount: true,
          ));
          loadTital.value = "Create Account Journal";
          lengthRemote.value = list.length;
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      await saveInLocalDB<AccountJournal>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }

  Future<void> loadingPosSession() async {
    List<PosSession> list = [];
    try {
      isLoad.value = true;
      loadTital.value = "Pos Session Loading";
      isLoadData.value = true;

      final LoadingItemsCountController loadingItemsCountController =
          Get.put(LoadingItemsCountController());
      loadingItemsCountController.resetLoadingItemCount();
      lengthRemote.value = 0;
      list = await loadingSynchronizingDataService.loadPosSession();
      isLoadData.value = false;
      if (list is List) {
        loadTital.value = "Create Pos Session";
        lengthRemote.value = list.length;
        _instance = GeneralLocalDB.getInstance<PosSession>(
            fromJsonFun: PosSession.fromJson);
        await _instance!.deleteData();

        if (list.isNotEmpty) {
          await _instance!.createList(recordsList: list);
          var currentSaleSession = list
              .where((e) => e.userOpenId == SharedPr.chosenUserObj!.id)
              .toList();
          if (currentSaleSession.isNotEmpty) {
            if (currentSaleSession.last.state == SessionState.openSession) {
              await SharedPr.setCurrentSaleSessionId(
                  currentSaleSessionId: currentSaleSession.last);
            }
          }
        }
      }
      loadTital.value = 'Completed';
      isLoad.value = false;
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }

  // [ LOADING PRODUCTS ] ===============================================================
  Future<void> loadingProduct({required List<int> posCategoriesIds}) async {
    int? count = await checkCount<Product>();
    List<Product> list = [];
    try {
      if (count != null && count == 0) {
        isLoad.value = true;
        loadTital.value = "Product Loading";
        isLoadData.value = true;

        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        lengthRemote.value = 0;
        list = await loadingSynchronizingDataService
            .loadProductDataBasedOnPosCategory(
                posCategoriesIds: posCategoriesIds);
        Set<Product> productSet = Set.from(list);
        list = productSet.toList();
        isLoadData.value = false;
        if (list is List) {
          loadTital.value = "Create Product";
          lengthRemote.value = list.length;
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      await saveInLocalDB<Product>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }

  // [ LOADING POS CATEGORIES ] ===============================================================
  Future<void> loadingPosCategories(
      {required List<int> posCategoriesIds}) async {
    int? count = await checkCount<PosCategory>();
    List<PosCategory> list = [];
    try {
      if (count != null && count == 0) {
        isLoad.value = true;

        loadTital.value = "Pos Category Loading";
        isLoadData.value = true;

        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        lengthRemote.value = 0;
        list =
            await loadingSynchronizingDataService.loadPosCategoryBasedOnUser();
        isLoadData.value = false;
        if (list is List) {
          loadTital.value = "Create Pos Category";
          lengthRemote.value = list.length;
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      await saveInLocalDB<PosCategory>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }

  // [ LOADING CUSTOMERS ] ===============================================================
  Future<void> loadingCustomer() async {
    int? count = await checkCount<Customer>();
    List<Customer> list = [];
    try {
      if (count != null && count == 0) {
        isLoad.value = true;
        loadTital.value = "Customer Loading";
        isLoadData.value = true;

        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        lengthRemote.value = 0;
        list = await loadingSynchronizingDataService.loadCustomerInfo();
        isLoadData.value = false;
        if (list is List) {
          loadTital.value = "Create Customer";
          lengthRemote.value = list.length;
        }

        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      await saveInLocalDB<Customer>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }

  // ============================================================= [ END LOADING BASIC DATA ] ====================================================================

  // ============================================================= [ START SYNCHRONIZE LOCAL DB ] ====================================================================
  Future loadingData({required String type}) async {
    Type typex = getModelClass(type);
    try {
      if (typex == Product) {
        await loadingProduct(posCategoriesIds: posCategoryIdsList);
      } else if (typex == Customer) {
        await loadingCustomer();
      } else if (typex == ProductUnit) {
        await loadingProductUnit();
      } else if (typex == PosCategory) {
        await loadingPosCategories(posCategoriesIds: posCategoryIdsList);
      }
      return true;
    } catch (e) {
      handleException(
          exception: e, navigation: false, methodName: "loadingData $typex");
    }
  }

  Future synchronizeDB<T>({bool show = true}) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        // CHECK IF DEVICE IS TRUSTED
        bool isTrustedDevice = await MacAddressHelper.isTrustedDevice();
        if (!isTrustedDevice) {
          return null;
        }
        // CHECK CHECKSUM OF TWO LOCAL DB
        bool? isIdenticalChecksum =
            await compareDataChecksum<T>(posCategoriesIds: posCategoryIdsList);
        if (isIdenticalChecksum != null && isIdenticalChecksum) {
          return true;
        } else if (isIdenticalChecksum != null && !isIdenticalChecksum) {
          if (show) {
            var name = getNamesOfSync<T>();

            appSnackBar(
                message:
                    'synchronize_now_by_name'.trParams({"field_name": name.tr}),
                messageType: MessageTypes.success,
                isDismissible: false);
          }
          await updateHistoryBasedOnItemType<T>();
          return false;
        }
      } else {
        return 'no_connection'.tr;
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  Future displayAll<T>({bool returnDiffData = false}) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        // CHECK IF DEVICE IS TRUSTED
        bool isTrustedDevice = await MacAddressHelper.isTrustedDevice();
        if (!isTrustedDevice) {
          return null;
        }
        // CHECK CHECKSUM OF TWO LOCAL DB
        bool? isIdenticalChecksum =
            await compareDataChecksum<T>(posCategoriesIds: posCategoryIdsList);
        if (isIdenticalChecksum != null && isIdenticalChecksum) {
          return [];
        } else if (isIdenticalChecksum != null && !isIdenticalChecksum) {
          return await updateHistoryBasedOnItemType<T>(
              returnDiffData: returnDiffData);
        }
      } else {
        return 'no_connection'.tr;
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<bool?> compareDataChecksum<T>(
      {required List<int> posCategoriesIds}) async {
    late dynamic remoteCheckSum, itemsList;

    remoteCheckSum = await loadingSynchronizingDataService
        .getItemCheckSumRemotely<T>(posCategoriesId: posCategoriesIds);
    _instance = getLocalInstanceType<T>();

    itemsList = await _instance!.index();

    if (remoteCheckSum is String) {
      var localChecksum = await loadingSynchronizingDataService
          .getCheckSumLocally<T>(recordsList: itemsList);
      if (localChecksum is String) {
        if (remoteCheckSum == localChecksum) {
          return true;
        } else {
          return false;
        }
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  saveInLocalDB<T>({List<T>? list}) async {
    _instance = getLocalInstanceType<T>();

    if (list != null && list.isNotEmpty) {
      await _instance!.createList(recordsList: list);
      await _itemHistoryController.updateHistoryRecordOnFirstLogin<T>();
      await checkIsRegisteredController<T>();
    } else {
      await updateHistoryBasedOnItemType<T>();
    }
  }

  // ============================================================= [ END SYNCHRONIZE LOCAL DB ] ====================================================================

// ========================================== [ GET PRODUCT HISTORY ] =============================================
  Future<ResponseResult> getProductHistory() async {
    var result = await loadingSynchronizingDataService.getProductHistory();
    if (result is List<BasicItemHistory>) {
      return ResponseResult(status: true, data: result);
    } else if (result == []) {
      return ResponseResult(message: "empty_list".tr);
    } else if (result is SocketException) {
      return ResponseResult(message: "no_connection".tr);
    } else {
      return ResponseResult(message: result);
    }
  }

  Future<ResponseResult> getFilteredHistory(
      {required List<int> excludeIds, required String typeName}) async {
    var result = await loadingSynchronizingDataService.getFilteredHistory(
        excludeIds: excludeIds,
        typeName: typeName,
        // userPosCategories: posCategoryIdsList);
        currentPosId: SharedPr.currentPosObject!.id!);
    if (result is List<BasicItemHistory>) {
      return ResponseResult(status: true, data: result);
    } else if (result == []) {
      return ResponseResult(message: "empty_list".tr);
    } else if (result is SocketException) {
      return ResponseResult(message: "no_connection".tr);
    } else {
      return ResponseResult(message: result);
    }
  }

  // [ STEP (2) - DIVIDE ITEMS BASED ON STATUS ] =================================================================

  Future divideItemsBasedOnStatus<T>(
      {required ResponseResult itemsHistoryList,
      bool returnDiffData = false}) async {
    if ([ProductUnit, AccountTax, AccountJournal].contains(T)) {
      return;
    }
    _instance ??= getLocalInstanceType<T>();

    List<dynamic> localIds = await _instance!.getIdsOnly();

    BasicItemProcessor<T> processor =
        getProcessor<T>(localIds: localIds.map<int>((e) => e).toList());
    return processItems<T>(
        itemsHistoryList: itemsHistoryList.data,
        processor: processor,
        returnDiffData: returnDiffData);
  }

  BasicItemProcessor<T> getProcessor<T>({required List<int> localIds}) {
    if (T == Product) {
      return ProductProcessor(localIds: localIds) as BasicItemProcessor<T>;
    } else if (T == Customer) {
      return CustomerProcessor(localIds: localIds) as BasicItemProcessor<T>;
    } else if (T == PosCategory) {
      return PosCategoryProcessor(localIds: localIds) as BasicItemProcessor<T>;
    } else {
      throw Exception('Processor not defined for type $T');
    }
  }

  Future processItems<T>(
      {required List<BasicItemHistory> itemsHistoryList,
      required BasicItemProcessor<T> processor,
      bool returnDiffData = false}) async {
    List<T> insertList = [];
    List<T> updateList = [];
    List<int> deleteList = [];
    List<T> deleteListItem = [];
    List allItem = [];
    for (BasicItemHistory element in itemsHistoryList) {
      if (processor.shouldInsert(
          element: element, posCategoryIds: posCategoryIdsList)) {
        insertList.add(processor.processElement(element: element) as T);
      } else if (processor.shouldUpdate(
          element: element, posCategoryIds: posCategoryIdsList)) {
        updateList.add(processor.processElement(element: element) as T);
      } else if (processor.shouldDelete(element: element)) {
        if (returnDiffData) {
          deleteListItem.add(processor.processElement(element: element) as T);
        } else {
          deleteList.add(processor.processElement(
              element: element, isDelete: true) as int);
        }
      }
    }
    if (!returnDiffData) {
      if (updateList.isNotEmpty) {
        await _instance!.updateList(recordsList: updateList, whereKey: 'id');
      }

      if (insertList.isNotEmpty) {
        await _instance!.createList(recordsList: insertList);
      }

      if (deleteList.isNotEmpty) {
        await _instance!.deleteList(
            recordsList: deleteList,
            whereKey: T == Product ? 'product_id' : 'id');
      }
    }
    if (returnDiffData) {
      for (int i = 0; i < updateList.length; i++) {
        allItem.add({"item": updateList[i], "vale": 0}); // update
      }
      for (int i = 0; i < insertList.length; i++) {
        allItem.add({"item": insertList[i], "vale": 1}); // add
      }
      for (int i = 0; i < deleteListItem.length; i++) {
        allItem.add({"item": deleteListItem[i], "vale": -1}); // delete
      }
      return allItem;
    }
  }

  // [ STEP (3) - UPDATE ITEM HISTORY REMOTELY ] =================================================================
  updateItemHistoryRemotely({required String typeName}) async {
    await loadingSynchronizingDataService.updateItemHistory(typeName: typeName);
  }

  // [ STEP (4) - UPDATE HISTORY BASED ON ITEM TYPE ] =================================================================
  updateHistoryBasedOnItemType<T>({bool returnDiffData = false}) async {
    String typeNameX = getOdooModels<T>();

    var result = await getFilteredHistory(
        excludeIds: <int>[SharedPr.currentPosObject!.id!], typeName: typeNameX);
    if (result.status) {
      var data = await divideItemsBasedOnStatus<T>(
          itemsHistoryList: result, returnDiffData: returnDiffData);
      if (returnDiffData) {
        return data;
      }

      if (!returnDiffData) {
        await updateItemHistoryRemotely(typeName: typeNameX);
        await checkIsRegisteredController<T>();
      }
    } else {}
  }

  // =========================================================== [ SAVE IN LOCAL DB ] ==========================================================
  Future checkIsRegisteredController<T>() async {
    if (T == PosCategory) {
      bool categoryControllerRegistered =
          Get.isRegistered<PosCategoryController>(
              tag: 'categoryControllerMain');
      if (categoryControllerRegistered) {
        _instance = GeneralLocalDB.getInstance<PosCategory>(
            fromJsonFun: PosCategory.fromJson);
        PosCategoryController posCategoryController =
            Get.find(tag: 'categoryControllerMain');
        posCategoryController.posCategoryList
            .assignAll((await _instance!.index()) as List<PosCategory>);

        posCategoryController.update();
      }
    } else if (T == Product) {
      bool productControllerRegistered =
          Get.isRegistered<ProductController>(tag: 'productControllerMain');
      if (productControllerRegistered) {
        ProductController productController =
            Get.find(tag: 'productControllerMain');
        productController.hasMore.value = true;
        productController.hasLess.value = false;
        // stop that
        _instance = GeneralLocalDB.getInstance<PosCategory>(
            fromJsonFun: PosCategory.fromJson);
        productController.categoriesList
            .assignAll((await _instance!.index()) as List<PosCategory>);
        _instance =
            GeneralLocalDB.getInstance<Product>(fromJsonFun: Product.fromJson);
        productController.productList.assignAll((await _instance!.index(
            offset: productController.page.value * productController.limit,
            limit: productController.limit)) as List<Product>);
        productController.pagingList.assignAll((await _instance!.index(
            offset: productController.page.value * productController.limit,
            limit: productController.limit)) as List<Product>);
        productController.update();
      }
    } else if (T == Customer) {
      bool customerControllerRegistered =
          Get.isRegistered<CustomerController>(tag: 'customerControllerMain');
      if (customerControllerRegistered) {
        _instance = GeneralLocalDB.getInstance<Customer>(
            fromJsonFun: Customer.fromJson);
        CustomerController customerController =
            Get.find(tag: 'customerControllerMain');

        customerController.hasMore.value = true;
        customerController.customerList.assignAll((await _instance!.index(
            offset: customerController.page.value * customerController.limit,
            limit: customerController.limit)) as List<Customer>);

        customerController.customerpagingList.assignAll((await _instance!.index(
            offset: customerController.page.value * customerController.limit,
            limit: customerController.limit)) as List<Customer>);

        customerController.update();
      }
    }
  }

// ========================================== [ GET PRODUCT HISTORY ] =============================================

  Future<ResponseResult> countAll() async {
    var result = await loadingSynchronizingDataService.countAll();
    if (result is CountItems) {
      return ResponseResult(status: true, data: result);
    } else {
      return ResponseResult(
          status: true,
          data:
              CountItems(categoryCount: 0, productCount: 0, customerCount: 0));
    }
  }

// ========================================== [ GET PRODUCT HISTORY ] =============================================

  Future getSelectedLoadDataCount() async {
    int count = 0;
    loaddata.forEach((key, value) {
      if (value[0] == true) {
        count++;
      }
    });
    return count;
  }

  Future selectLoadData(
      bool newValue, MapEntry<Loaddata, List<bool>> map) async {
    var selectedLoadData = loaddata.entries.firstWhere((element) {
      return element.key == map.key;
    });
    loaddata[selectedLoadData.key] = [newValue];
    count = await getSelectedLoadDataCount();
    if (count > 0) {
      if (loaddata.length == count) {
        isSelctedAll = true;
      } else {
        isSelctedAll = false;
      }
    }
    update(["selected load data"]);
  }

  Future selectAllLoadData() async {
    for (var key in loaddata.keys) {
      var value = loaddata[key];
      loaddata[key] = value!.map((item) => item is bool ? true : item).toList();
    }
    isSelctedAll = true;
    count = await getSelectedLoadDataCount();
    update(["selected load data"]);
  }

  Future<ResponseResult> updateAllLoadData() async {
    if (count == 0 || count == loaddata.length) {
    } else {}
    return ResponseResult(
      status: true,
    );
  }

  Future deletSelected() async {
    for (var key in loaddata.keys) {
      var value = loaddata[key];
      loaddata[key] =
          value!.map((item) => item is bool ? false : item).toList();
    }
    isSelctedAll = false;
    count = 0;
    update(["selected load data"]);
  }

  Future getitems() async {
    try {
      final remoteCount = await countAll();
      final productCount =
          await loadingSynchronizingDataService.getCountDataLocal<Product>();
      final customerCount =
          await loadingSynchronizingDataService.getCountDataLocal<Customer>();
      final categoryCount = await loadingSynchronizingDataService
          .getCountDataLocal<PosCategory>();
      final productUnit = await loadingSynchronizingDataService
          .getCountDataLocal<ProductUnit>();
      final accountTax =
          await loadingSynchronizingDataService.getCountDataLocal<AccountTax>();

      final accountJournal = await loadingSynchronizingDataService
          .getCountDataLocal<AccountJournal>();

      itemdata[Loaddata.products.name.toString()] = {
        "remote": remoteCount.data.productCount,
        "local": productCount is int ? productCount : 0
      };

      itemdata[Loaddata.customers.name.toString()] = {
        "remote": remoteCount.data.customerCount,
        "local": customerCount is int ? customerCount : 0
      };

      itemdata[Loaddata.categories.name.toString()] = {
        "remote": remoteCount.data.categoryCount,
        "local": categoryCount is int ? categoryCount : 0
      };
      itemdata[Loaddata.priceList.name.toString()] = {
        "remote": 0,
        "local": productUnit is int ? productUnit : 0
      };
      itemdata[Loaddata.accountTax.name.toString()] = {
        "remote": 0,
        "local": accountTax is int ? accountTax : 0
      };
      itemdata[Loaddata.accountJournal.name.toString()] = {
        "remote": 0,
        "local": accountJournal is int ? accountJournal : 0
      };
      update(['card_loading_data']);
      update(['pagin']);
      return ResponseResult(status: true, data: itemdata);
    } catch (e) {
      return ResponseResult(status: false, message: 'Failed to fetch items');
    }
  }

  Future refreshDataFromRemoteServer({required String name}) async {
    try {
      isRefresh.value = true;
      if (name == 'products') {
        loadTital.value = 'refresh Product';
        await updateHistoryBasedOnItemType<Product>();
      } else if (name == 'customers') {
        loadTital.value = 'refresh customers';
        await updateHistoryBasedOnItemType<Customer>();
      } else if (name == 'categories') {
        loadTital.value = 'refresh categories';
        await updateHistoryBasedOnItemType<PosCategory>();
      }
      loadTital.value = 'Completed';
      isRefresh.value = false;
    } catch (e) {
      return handleException(
          exception: e,
          navigation: false,
          methodName: "refreshDataFromRemoteServer");
    }
  }

  Future updateAll({required String name}) async {
    try {
      itemUpdate = name;
      isUpdate.value = true;
      update(['loading']);
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        // CHECK IF DEVICE IS TRUSTED
        bool isTrustedDevice = await MacAddressHelper.isTrustedDevice();
        if (!isTrustedDevice) {
          isUpdate.value = false;
          update(['card_loading_data']);
          update(['loading']);
          return;
        }
        _instance = getLocalInstanceTypeByName(name: name);
        await _instance!.deleteData();
        await loadingPosCategoryIdsList();
        bool result = await loadingData(type: name);
        isUpdate.value = false;
        await getitems();
        update(['card_loading_data']);
        update(['loading']);
        if (result) {
          return true;
        } else {
          return false;
        }
      } else {
        isUpdate.value = false;
        update(['loading']);
        return "no_connection".tr;
      }
    } catch (e) {
      isUpdate.value = false;
      update(['loading']);
      return false;
    }
  }
}
