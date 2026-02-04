// ignore_for_file: type_literal_in_constant_pattern, unnecessary_type_check

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:pos_shared_preferences/helper/app_enum.dart';
import 'package:pos_shared_preferences/models/account_journal/data/account_journal.dart';
import 'package:pos_shared_preferences/models/account_journal/data/account_journal_name.dart';
import 'package:pos_shared_preferences/models/account_tax/data/account_tax.dart';
import 'package:pos_shared_preferences/models/basic_item_history.dart';
import 'package:pos_shared_preferences/models/category_sale_price.dart';
import 'package:pos_shared_preferences/models/count_items.dart';
import 'package:pos_shared_preferences/models/customer_model.dart';
import 'package:pos_shared_preferences/models/invoice_setting.dart';
import 'package:pos_shared_preferences/models/pos_categories_data/pos_category.dart';
import 'package:pos_shared_preferences/models/pos_session/posSession.dart';
import 'package:pos_shared_preferences/models/pos_setting_info_model.dart';
import 'package:pos_shared_preferences/models/printing/data/printing_prefrences.dart';
import 'package:pos_shared_preferences/models/printing_setting.dart';
import 'package:pos_shared_preferences/models/product_data/product.dart';
import 'package:pos_shared_preferences/models/product_unit/data/product_unit.dart';
import 'package:pos_shared_preferences/models/user_sale_price.dart';
import 'package:pos_shared_preferences/pos_shared_preferences.dart';
import 'package:shared_widgets/config/app_enums.dart';
import 'package:shared_widgets/shared_widgets/app_snack_bar.dart';
import 'package:shared_widgets/shared_widgets/handle_exception_helper.dart';
import 'package:shared_widgets/utils/mac_address_helper.dart';
import 'package:shared_widgets/utils/response_result.dart';
import 'package:yousentech_pos_basic_data_management/basic_data_management/src/customer/domain/customer_viewmodel.dart';
import 'package:yousentech_pos_basic_data_management/basic_data_management/src/item_history/domain/item_history_viewmodel.dart';
import 'package:yousentech_pos_basic_data_management/basic_data_management/src/pos_categories/domain/pos_category_viewmodel.dart';
import 'package:yousentech_pos_basic_data_management/basic_data_management/src/products/domain/product_viewmodel.dart';
import 'package:yousentech_pos_basic_data_management/basic_data_management/src/user_sale_price/domain/user_sale_price_service.dart';
import 'package:yousentech_pos_invoice_printing/print_invoice/config/app_enums.dart';
import 'package:yousentech_pos_loading_synchronizing_data/loading_sync/config/app_enums.dart';
import 'package:yousentech_pos_loading_synchronizing_data/loading_sync/config/app_list.dart';
import 'package:yousentech_pos_loading_synchronizing_data/loading_sync/src/domain/loading_item_count_controller.dart';
import 'package:yousentech_pos_loading_synchronizing_data/loading_sync/src/utils/fail_loading_dialog.dart';
import 'package:yousentech_pos_loading_synchronizing_data/loading_sync/src/utils/pos_category_processor.dart';
import 'package:yousentech_pos_loading_synchronizing_data/loading_sync/utils/define_type_function.dart';
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
    await loadingPosIPPrinter();
    await loadingGeneralSettings();
    if (!SharedPr.userObj!.isPriceControlModuleInstalled!) {
      await GeneralLocalDB.getInstance<UserSalePrice>(
              fromJsonFun: UserSalePrice.fromJson)!
          .dropTable();
      await GeneralLocalDB.getInstance<CategorySalePrice>(
              fromJsonFun: CategorySalePrice.fromJson)!
          .dropTable();
    } else {
      await loadingUserSalePrices();
      await loadingCategorySalePrice();
    }
    await getitems();
  }

// # ===================================================== [ CHECK COUNT ] =====================================================
  // # Functionality:
  // # - This method is used to check if there are any rows in a table associated with the specified type `T`.
  // # - It gets the local instance of the type `T` using `getLocalInstanceType<T>()`, then calls `checkIfThereIsRowsInTable()` on that instance.
  // # - The method returns the count of rows (if any) present in the table for that specific type.
  // # Input:
  // # - Type `T`: This represents the type for which the count of rows in the table is being checked.
  // # Output:
  // # - `int?`: The count of rows in the table (if any), or `null` if no rows exist or there is an issue fetching the count.

  Future<int?> checkCount<T>() async {
    _instance = getLocalInstanceType<T>();
    int? count = await _instance!.checkIfThereIsRowsInTable();
    return count;
  }
// # ===================================================== [ CHECK COUNT ] =====================================================

// # ===================================================== [ LOADING CURRENT POS SETTING ] =====================================================
  // # Functionality:
  // # - This function is responsible for loading the current POS settings for a given POS setting ID.
  // # - It loads the current user POS setting info and updates the `SharedPr` storage with relevant preferences such as printing settings.
  // # - It also loads the company information for the current POS and updates it in the shared preferences.
  // # Input:
  // # - `posSettingId`: The ID of the POS setting to be loaded.
  // # Output:
  // # - A `ResponseResult` containing the status, message, and data. It could be a success response with the loaded data, or an error response if something fails.
  Future<dynamic> loadingCurrentPosSetting({required int posSettingId}) async {
    isLoad.value = true;
    dynamic result = await loadingSynchronizingDataService
        .loadCurrentUserPosSettingInfo(posSettingId: posSettingId);
    if (result is PosSettingInfo) {
      await SharedPr.setCurrentPosObj(posObject: result);
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
      //   disablePrinting: result.disablePrinting
      //       // result.printingMode == PrintingType.disable_printing.name
      //       //     ? true
      //       //     : false,
      // ));
      await SharedPr.setPrintingPreferenceObj(
          printingPreferenceObj: PrintingPreference(
        showPreview: result.showPreview,
        // isSilentPrinting:
        //     result.printingMode == PrintingType.is_silent_printing.name
        //         ? true
        //         : false,
        // isShowPrinterDialog:
        //     result.printingMode == PrintingType.is_show_printer_dialog.name
        //         ? true
        //         : false,
        isDownloadPDF: result.isDownloadPDF,
        downloadPath: result.downloadPath,
        showPosPaymentSummary: result.showPosPaymentSummary,
        // disablePrinting: result.disablePrinting
        //     result.printingMode == PrintingType.disable_printing.name
        //         ? true
        //         : false,
      ));
      var invoiceSettingItems = SharedPr.invoiceSetting ?? InvoiceSetting();
      invoiceSettingItems.showOrderType = result.enableOrderType;
      invoiceSettingItems.showOrderCardCount = result.enableOrderCardCount;
      invoiceSettingItems.orderTypeMode = result.orderTypeMode;
      await SharedPr.setInvoiceSettingObj(setting: invoiceSettingItems);
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
// # ===================================================== [ LOADING CURRENT POS SETTING ] =====================================================

//   # ===================================================== [ LOADING POS CATEGORY IDS LIST ] =====================================================
  // # Functionality:
  // # - This function loads the list of POS category IDs associated with the current POS setting.
  // # - It first loads the current POS setting using the `loadingCurrentPosSetting` method.
  // # - If the POS setting is successfully loaded and contains a non-empty list of POS category IDs, it stores the list.
  // # Input:
  // # - None directly, but it uses the `SharedPr.currentPosObject` to get the current POS ID.
  // # Output:
  // # - A list of POS category IDs (`posCategoryIdsList`) if the current POS setting contains them.
  // #   If no categories are found, it returns an empty list.

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
//   # ===================================================== [ LOADING POS CATEGORY IDS LIST ] =====================================================

// # ===================================================== [ LOADING PRODUCT UNIT ] =====================================================
  // # Functionality:
  // # - This function loads product unit data and saves it locally if the local database does not already have any data.
  // # - It first checks if there are any existing product units in the local database.
  // # - If no product units are found, it initiates a process to load data from a remote source.
  // # - After loading, the product units are saved to the local database.
  // # Input:
  // # - None directly, but the method checks the local database for existing product unit data using `checkCount<ProductUnit>()`.
  // # Output:
  // # - Updates UI states and saves product unit data into the local database.

  Future<void> loadingProductUnit({bool isUpdateAll = false}) async {
    List<ProductUnit> list = [];
    int? count = await checkCount<ProductUnit>();
    try {
      if (count != null && count == 0) {
        isLoad.value = true;
        loadTital.value = "Product Unit Loading";
        isLoadData.value = true;
        lengthRemote.value = 0;
        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        var result =
            await loadingSynchronizingDataService.loadProductUnitData();
        isLoadData.value = false;
        if (result is List) {
          loadTital.value = "Create Product Unit";
          lengthRemote.value = result.length;
          list = (result as List<ProductUnit>);
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      if (isUpdateAll && list.isNotEmpty) {
        _instance = GeneralLocalDB.getInstance<ProductUnit>(
            fromJsonFun: ProductUnit.fromJson);
        await _instance!.deleteData();
      }
      await saveInLocalDB<ProductUnit>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }
// # ===================================================== [ LOADING PRODUCT UNIT ] =====================================================

// # ===================================================== [ LOADING ACCOUNT TAX ] =====================================================
  // # Functionality:
  // # - This function checks if account tax data exists in the local database.
  // # - If no data exists, it loads account tax data remotely.
  // # - After loading, the data is saved to the local database.
  // # - During the loading process, it shows appropriate loading messages and progress.
  // # Input:
  // # - No direct input, but it checks the local database for existing account tax data using `checkCount<AccountTax>()`.
  // # Output:
  // # - Updates the UI states, shows loading progress, and saves the data to the local database.

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
        var result = await loadingSynchronizingDataService.loadAccountTaxData();
        isLoadData.value = false;
        if (result is List) {
          loadTital.value = "Create Account Tax";
          lengthRemote.value = result.length;
          list = (result as List<AccountTax>);
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
// # ===================================================== [ LOADING ACCOUNT TAX ] =====================================================

// # ===================================================== [ LOADING ACCOUNT JOURNAL ] =====================================================
  // # Functionality:
  // # - This function checks if account journal data exists in the local database.
  // # - If no data exists, it loads account journal data remotely.
  // # - After loading, the data is saved to the local database.
  // # - During the loading process, it shows appropriate loading messages and progress.
  // # Input:
  // # - No direct input, but it checks the local database for existing account journal data using `checkCount<AccountJournal>()`.
  // # Output:
  // # - Updates the UI states, shows loading progress, and saves the data to the local database.

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
        var result =
            await loadingSynchronizingDataService.loadAccountJournalData();
        isLoadData.value = false;
        if (result is List) {
          list = (result as List<AccountJournal>);
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
// # ===================================================== [ LOADING ACCOUNT JOURNAL ] =====================================================

// # ===================================================== [ LOADING POS SESSION ] =====================================================
  // # Functionality:
  // # - This function loads the POS (Point of Sale) session data.
  // # - If no session data exists, it will fetch and store POS session data remotely.
  // # - It also manages the loading states and displays appropriate messages.
  // # - If the session data is related to the current user, it marks the session as "open".
  // # Input:
  // # - No direct input, but it checks for the current user's session (`SharedPr.chosenUserObj`).
  // # Output:
  // # - Updates the UI states, loads data remotely, and saves it in the local database.

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
      var reslut = await loadingSynchronizingDataService.loadPosSession();
      isLoadData.value = false;
      if (reslut is List) {
        loadTital.value = "Create Pos Session";
        lengthRemote.value = reslut.length;
        _instance = GeneralLocalDB.getInstance<PosSession>(
            fromJsonFun: PosSession.fromJson);
        await _instance!.deleteData();
        // print("list.isNotEmpty :: ${list.isNotEmpty}");
        if (reslut.isNotEmpty) {
          list = (reslut as List<PosSession>);
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
      // print("loadPosSession ## $e");
      isLoad.value = false;
      isLoadData.value = false;
    }
  }
// # ===================================================== [ LOADING POS SESSION ] =====================================================

//   # ===================================================== [ LOADING PRODUCTS BASED ON POS CATEGORY ] =====================================================
  // # Functionality:
  // # - This function loads product data based on POS category IDs passed as input.
  // # - If the product data is not already available in the local database, it fetches it remotely.
  // # - The function handles loading indicators, displaying messages, and processing the loaded data (removing duplicates).
  // # - After fetching and processing the data, it saves the data in the local database.
  // # Input:
  // # - `posCategoriesIds`: A list of POS category IDs used to filter products.
  // # Output:
  // # - Updates the UI with appropriate loading states and saves the fetched data locally.

  Future<void> loadingProduct(
      {required List<int> posCategoriesIds, bool isUpdateAll = false}) async {
    List<Product> list = [];
    int? count = await checkCount<Product>();
    try {
      if (isUpdateAll || (count != null && count == 0)) {
        isLoad.value = true;
        loadTital.value = "Product Loading";
        isLoadData.value = true;
        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        lengthRemote.value = 0;
        var result = await loadingSynchronizingDataService
            .loadProductDataBasedOnPosCategory(
                posCategoriesIds: posCategoriesIds);
        if (result is List) {
          loadTital.value = "Create Product";
          lengthRemote.value = result.length;
          Set<Product> productSet = Set.from(result);
          list = productSet.toList();
          isLoadData.value = false;
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      if (isUpdateAll && list.isNotEmpty) {
        _instance =
            GeneralLocalDB.getInstance<Product>(fromJsonFun: Product.fromJson);
        await _instance!.deleteData();
      }
      await saveInLocalDB<Product>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }
//   # ===================================================== [ LOADING PRODUCTS BASED ON POS CATEGORY ] =====================================================

//   # ===================================================== [ LOADING POS CATEGORIES ] =====================================================
  // # Functionality:
  // # - This function loads POS category data from a remote source, based on the provided user criteria.
  // # - If the POS category data is not already available in the local database, it fetches it remotely.
  // # - The function handles loading indicators, displaying messages, and processing the loaded data.
  // # - After fetching and processing the data, it saves the data in the local database.
  // # Input:
  // # - `posCategoriesIds`: A list of POS category IDs used to filter categories (not used directly in the method, might be useful for further development).
  // # Output:
  // # - Updates the UI with appropriate loading states and saves the fetched data locally.

  Future<void> loadingPosCategories(
      {required List<int> posCategoriesIds, bool isUpdateAll = false}) async {
    int? count = await checkCount<PosCategory>();
    List<PosCategory> list = [];
    try {
      if (isUpdateAll || (count != null && count == 0)) {
        isLoad.value = true;
        loadTital.value = "Pos Category Loading";
        isLoadData.value = true;
        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        lengthRemote.value = 0;
        var result =
            await loadingSynchronizingDataService.loadPosCategoryBasedOnUser();

        isLoadData.value = false;
        if (result is List) {
          list = (result as List<PosCategory>);
          loadTital.value = "Create Pos Category";
          lengthRemote.value = result.length;
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      if (isUpdateAll && list.isNotEmpty) {
        _instance = GeneralLocalDB.getInstance<PosCategory>(
            fromJsonFun: PosCategory.fromJson);
        await _instance!.deleteData();
      }
      await saveInLocalDB<PosCategory>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }
//   # ===================================================== [ LOADING POS CATEGORIES ] =====================================================

//   # ===================================================== [ LOADING CUSTOMER ] =====================================================
  // # Functionality:
  // # - This function loads customer data from a remote source if the data is not already present in the local database.
  // # - It displays loading indicators, updates messages for different loading states, and processes the loaded data.
  // # - Once the data is fetched, it saves the customer data in the local database.
  // # Input:
  // # - None (it directly fetches all customers).
  // # Output:
  // # - Updates the UI with loading states and saves the fetched customer data locally.

  Future<void> loadingCustomer({bool isUpdateAll = false}) async {
    List<Customer> list = [];
    int? count = await checkCount<Customer>();
    try {
      if (isUpdateAll || (count != null && count == 0)) {
        isLoad.value = true;
        loadTital.value = "Customer Loading";
        isLoadData.value = true;
        final LoadingItemsCountController loadingItemsCountController =
            Get.put(LoadingItemsCountController());
        loadingItemsCountController.resetLoadingItemCount();
        lengthRemote.value = 0;
        var result = await loadingSynchronizingDataService.loadCustomerInfo();
        isLoadData.value = false;
        if (result is List) {
          loadTital.value = "Create Customer";
          lengthRemote.value = list.length;
          list = (result as List<Customer>);
        }
        loadTital.value = 'Completed';
        isLoad.value = false;
      }
      if (isUpdateAll && list.isNotEmpty) {
        _instance = GeneralLocalDB.getInstance<Customer>(
            fromJsonFun: Customer.fromJson);
        await _instance!.deleteData();
      }
      await saveInLocalDB<Customer>(list: list);
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }
//   # ===================================================== [ LOADING CUSTOMER ] =====================================================

//   # ===================================================== [ LOADING USER SALE Prices ] =====================================================
  // TODO ::: CHECK LOADING OF USER SALE ORDER
  Future<void> loadingUserSalePrices() async {
    List<UserSalePrice> list = [];
    try {
      isLoad.value = true;
      loadTital.value = "User Sale Price Loading";
      isLoadData.value = true;

      final LoadingItemsCountController loadingItemsCountController =
          Get.put(LoadingItemsCountController());
      loadingItemsCountController.resetLoadingItemCount();
      lengthRemote.value = 0;
      var result = await loadingSynchronizingDataService.loadUserSalePrices();
      isLoadData.value = false;
      if (result is List) {
        loadTital.value = "Create User Sale Prices";
        lengthRemote.value = result.length;
        list = (result as List<UserSalePrice>);
        _instance = GeneralLocalDB.getInstance<UserSalePrice>(
            fromJsonFun: UserSalePrice.fromJson);
        bool isExsit = await _instance!.checkIfTableExists();
        if (!isExsit) {
          await UserSalePriceService.getInstance().createTable();
        }
        await _instance!.deleteData();
        if (list.isNotEmpty) {
          await _instance!.createList(recordsList: list);
        }
      }
      loadTital.value = 'Completed';
      isLoad.value = false;
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }
//   # ===================================================== [ LOADING USER SALE Prices ] =====================================================

//   # ===================================================== [ LOADING Category SALE Prices ] =====================================================
  // TODO ::: CHECK LOADING OF Category Sale Price
  Future<void> loadingCategorySalePrice() async {
    List<CategorySalePrice> list = [];
    try {
      isLoad.value = true;
      loadTital.value = "Category Sale Prices Loading";
      isLoadData.value = true;

      final LoadingItemsCountController loadingItemsCountController =
          Get.put(LoadingItemsCountController());
      loadingItemsCountController.resetLoadingItemCount();
      lengthRemote.value = 0;
      var result =
          await loadingSynchronizingDataService.loadCategorySalePrices();
      isLoadData.value = false;
      if (result is List) {
        loadTital.value = "Create Category Sale Prices";
        lengthRemote.value = result.length;
        list = (result as List<CategorySalePrice>);
        _instance = GeneralLocalDB.getInstance<CategorySalePrice>(
            fromJsonFun: CategorySalePrice.fromJson);
        bool isExsit = await _instance!.checkIfTableExists();
        if (!isExsit) {
          await UserSalePriceService.getInstance().createTable();
        }
        await _instance!.deleteData();

        if (list.isNotEmpty) {
          await _instance!.createList(recordsList: list);
        }
      }
      loadTital.value = 'Completed';
      isLoad.value = false;
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }
//   # ===================================================== [ LOADING Category SALE Prices ] =====================================================

// # ===================================================== [ LOADING DATA ] =====================================================
  // # Functionality:
  // # - This function handles the dynamic loading of data based on the type passed as an argument.
  // # - It determines the model type using the `getModelClass()` function and then calls the appropriate loading function.
  // # - Each type corresponds to a different data loading function, which handles different types of data such as `Product`, `Customer`, etc.
  // # - If an error occurs during loading, it is handled using a custom `handleException` function.
  // # Input:
  // # - `type`: A string indicating the model class (e.g., `Product`, `Customer`).
  // # Output:
  // # - It returns a `true` value when the loading process is successful. If an error occurs, it is handled and no return is made in the case of an exception.

  Future loadingData({required String type}) async {
    Type typex = getModelClass(type);
    try {
      if (typex == Product) {
        await loadingProduct(
            posCategoriesIds: posCategoryIdsList, isUpdateAll: true);
      } else if (typex == Customer) {
        await loadingCustomer(isUpdateAll: true);
      } else if (typex == ProductUnit) {
        await loadingProductUnit(isUpdateAll: true);
      } else if (typex == PosCategory) {
        await loadingPosCategories(
            posCategoriesIds: posCategoryIdsList, isUpdateAll: true);
      }
      return true;
    } catch (e) {
      handleException(
          exception: e, navigation: false, methodName: "loadingData $typex");
    }
  }
// # ===================================================== [ LOADING DATA ] =====================================================

// # ===================================================== [ SYNC DATABASE ] =====================================================
  // # Functionality:
  // # - This function handles the synchronization of a local database with a remote system.
  // # - It checks for network connectivity, whether the device is trusted, and compares the checksum of the local database with the remote system's data.
  // # - If there are differences in the local and remote databases, it triggers a synchronization process.
  // # - If the local and remote databases are already synchronized, it returns true. If not, it performs the update based on the item type.
  // # Input:
  // # - `show`: A boolean indicating whether or not to show a snackbar message for synchronization.
  // # Output:
  // # - It returns a boolean (`true` or `false`) indicating the synchronization status or a localized message if there's no connection.
  // # - It returns `null` if an error occurs during the process.

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
      return e.toString();
    }

    // return null;
  }
// # ===================================================== [ SYNC DATABASE ] =====================================================

//   # ===================================================== [ DISPLAY ALL ] =====================================================
  // # Functionality:
  // # - This function is used to display all records of a specific type (generic type T), with an option to return only the records with differences from the local data.
  // # - It first checks for network connectivity and whether the device is trusted.
  // # - Then, it compares the checksum of the local database with the remote database to check if they are synchronized.
  // # - If they are synchronized, it returns an empty list; if not, it triggers the synchronization of the data and returns the updated data.
  // # Input:
  // # - `returnDiffData`: A boolean flag that determines whether to return only the records with differences (default is false).
  // # Returns:
  // # - It returns a list of data of type T (the updated or synchronized data).
  // # - If there's no connection, it returns a localized message `'no_connection'`.
  // # - If an error occurs, it returns an empty list.

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
      return e.toString();
    }

    // return [];
  }
//   # ===================================================== [ DISPLAY ALL ] =====================================================

// # =================================================== [ COMPARE DATA CHECKSUM ] ===================================================
  // # Functionality:
  // # - This function compares the checksum of local data with remote data to check whether both databases (local and remote) are synchronized.
  // # - The function checks if the local and remote databases have the same checksum, indicating that the data is the same.
  // # - If the checksums are identical, it returns `true`; if they are different, it returns `false`.
  // # - If there is an issue (like missing checksum or an error), it returns `null`.
  // # Input:
  // # - `posCategoriesIds`: A list of IDs that categorize the data being synchronized.
  // # Returns:
  // # - `true` if local and remote data are in sync (checksums match).
  // # - `false` if the checksums differ.
  // # - `null` in case of errors or missing checksum data.

  Future<bool?> compareDataChecksum<T>(
      {required List<int> posCategoriesIds}) async {
    late dynamic remoteCheckSum, itemsList;
    bool isRepModuleInstalled = false;
    remoteCheckSum = await loadingSynchronizingDataService
        .getItemCheckSumRemotely<T>(posCategoriesId: posCategoriesIds);
    _instance = getLocalInstanceType<T>();

    itemsList = await _instance!.index();
    if (T == Customer) {
      isRepModuleInstalled = remoteCheckSum["is_rep_module_installed"];
      await SharedPr.setModelL10nSaEdieInstall(flage: isRepModuleInstalled);
      remoteCheckSum = remoteCheckSum["checksum"];
    }
    if (remoteCheckSum is String) {
      var localChecksum =
          await loadingSynchronizingDataService.getCheckSumLocally<T>(
              recordsList: itemsList,
              isRepModuleInstalled: isRepModuleInstalled);
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
// # =================================================== [ COMPARE DATA CHECKSUM ] ===================================================

// # =================================================== [ SAVE IN LOCAL DB ] ===================================================
  // # Functionality:
  // # - This function saves a list of items into a local database and handles additional synchronization steps.
  // # - If a list of items is provided and is not empty, the function creates a list of records in the local database and updates the item history.
  // # - If no list is provided or the list is empty, it will update the item history based on the item type.
  // # Input:
  // # - `list`: A list of items to be saved in the local database (generic type T).
  // # Returns:
  // # - None (void).

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
// # =================================================== [ SAVE IN LOCAL DB ] ===================================================

//   # =================================================== [ GET PRODUCT HISTORY ] ===================================================
  // # Functionality:
  // # - This function retrieves the product history from a remote service and handles different scenarios based on the result.
  // # - It checks if the result is a list of `BasicItemHistory` objects and returns a success response.
  // # - If the result is an empty list, it returns a response indicating that the list is empty.
  // # - If a `SocketException` occurs, it returns a response indicating a lack of internet connection.
  // # - In case of other errors or unexpected results, it returns the result as an error message.
  // # Input:
  // # - None.
  // # Returns:
  // # - A `ResponseResult` containing either the product history or an error message.

  Future<ResponseResult> getProductHistory() async {
    var result = await loadingSynchronizingDataService.getProductHistory();
    if (result is List<BasicItemHistory>) {
      return ResponseResult(status: true, data: result);
    } else if (result == []) {
      return ResponseResult(message: "empty_list".tr);
    } else if (result is SocketException) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return ResponseResult(message: "no_connection".tr);
      }
      if (result.toString().contains("timeout period has expired") ||
          result
              .toString()
              .contains("The remote computer refused the network connection")) {
        return ResponseResult(message: 'failed_connect_server'.tr);
      }
      return ResponseResult(message: "no_connection".tr);
    } else {
      return ResponseResult(message: result);
    }
  }
//   # =================================================== [ GET PRODUCT HISTORY ] ===================================================

// # =================================================== [ GET FILTERED HISTORY ] ===================================================
  // # Functionality:
  // # - This function retrieves filtered history based on specified `excludeIds` and `typeName`.
  // # - It calls a remote service to get the filtered history and handles different scenarios based on the result.
  // # - It returns the history if it's successfully retrieved as a list of `BasicItemHistory` objects.
  // # - If the result is an empty list, it returns a response indicating the list is empty.
  // # - If a `SocketException` occurs, it returns a response indicating a lack of internet connection.
  // # - In case of other errors or unexpected results, it returns the result as an error message.
  // # Input:
  // # - `excludeIds`: A list of IDs to exclude from the history.
  // # - `typeName`: The type of history being fetched (e.g., product history, customer history, etc.).
  // # Returns:
  // # - A `ResponseResult` containing either the filtered history or an error message.

  Future<ResponseResult> getFilteredHistory(
      {required List<int> excludeIds, required String typeName}) async {
    var result = await loadingSynchronizingDataService.getFilteredHistory(
        excludeIds: excludeIds,
        typeName: typeName,
        currentPosId: SharedPr.currentPosObject!.id!);
    if (result is List<BasicItemHistory>) {
      return ResponseResult(status: true, data: result);
    } else if (result == []) {
      return ResponseResult(message: "empty_list".tr);
    } else if (result is SocketException) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return ResponseResult(message: "no_connection".tr);
      }
      if (result.toString().contains("timeout period has expired") ||
          result
              .toString()
              .contains("The remote computer refused the network connection")) {
        return ResponseResult(message: 'failed_connect_server'.tr);
      }
      return ResponseResult(message: "no_connection".tr);
    } else {
      return ResponseResult(message: result);
    }
  }
// # =================================================== [ GET FILTERED HISTORY ] ===================================================

//   # =================================================== [ DIVIDE ITEMS BASED ON STATUS ] ===================================================
  // # Functionality:
  // # - This function divides the provided items history based on certain statuses, returning the processed items.
  // # - It filters the process depending on the item type (e.g., ProductUnit, AccountTax, AccountJournal).
  // # - It retrieves local IDs associated with the provided item type, processes the items using a processor, and then processes the history.
  // # Input:
  // # - `itemsHistoryList`: A `ResponseResult` object containing the items' history to be processed.
  // # - `returnDiffData`: A boolean flag to determine whether to return the different data.
  // # Returns:
  // # - It processes the `itemsHistoryList` based on the item type and status, calling another method (`processItems`).

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
//   # =================================================== [ DIVIDE ITEMS BASED ON STATUS ] ===================================================

//   # =================================================== [ GET PROCESSOR ] ===================================================
  // # Functionality:
  // # - Dynamically retrieves the appropriate processor based on the type parameter T.
  // # - Ensures that the localIds list is passed to the specific processor for proper handling.
  // # - Throws an exception if the processor for the specified type is not defined.
  // # Input:
  // # - T: The type parameter (could be Product, Customer, or PosCategory).
  // # - localIds: A list of integer IDs related to the type to be processed.
  // # Raises:
  // # - Exception: If the processor for the type T is not defined.
  // # Returns:
  // # - A processor object specific to the type T, which extends BasicItemProcessor.
  // # Example:
  // #   - For Product: Returns ProductProcessor(localIds: localIds).
  // #   - For Customer: Returns CustomerProcessor(localIds: localIds).
  // #   - For PosCategory: Returns PosCategoryProcessor(localIds: localIds).

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
//   # =================================================== [ GET PROCESSOR ] ===================================================

// # ===================================================== [ PROCESS ITEMS ] =====================================================
  // # Functionality:
  // # - Processes a list of items based on the specified processor for a given type T.
  // # - The function handles insertions, updates, and deletions based on conditions defined in the processor.
  // # - The function also manages different data handling strategies for diff data (inserts/updates/deletes).
  // #
  // # Input:
  // # - itemsHistoryList: List of items that need to be processed.
  // # - processor: The specific processor used to handle each item in the list.
  // # - returnDiffData: A flag to determine if diff data (changes) should be returned instead of applying operations.
  // #
  // # Logic:
  // # - The function checks each item in the `itemsHistoryList` to determine whether it should be inserted, updated, or deleted.
  // # - For each operation (insert/update/delete), the function interacts with the local database to apply changes using the `_instance`.
  // # - If `returnDiffData` is set to `true`, the function returns a list indicating which items have been added, updated, or deleted (with corresponding flags: 1 for add, 0 for update, and -1 for delete).
  // #
  // # Raises:
  // # - None specified.
  // #
  // # Returns:
  // # - If `returnDiffData` is true: A list of items with the respective operation flag (add, update, delete).
  // # - If `returnDiffData` is false: The changes are directly applied to the database without returning diff data.
  // #
  // # Example:
  // #   - Insert a new item: `insertList.add(processor.processElement(element: element) as T)`
  // #   - Update an existing item: `updateList.add(processor.processElement(element: element) as T)`
  // #   - Delete an item: `deleteList.add(processor.processElement(element: element, isDelete: true) as int)`

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
// # ===================================================== [ PROCESS ITEMS ] =====================================================

// # ===================================================== [ UPDATE ITEM HISTORY REMOTELY ] =====================================================
  // # Functionality:
  // # - Updates the item history remotely by calling the appropriate service function.
  // # Input:
  // # - typeName: A string representing the type of the item whose history needs to be updated.

  // [ STEP (3) - UPDATE ITEM HISTORY REMOTELY ] =================================================================
  updateItemHistoryRemotely({required String typeName}) async {
    await loadingSynchronizingDataService.updateItemHistory(typeName: typeName);
  }
// # ===================================================== [ UPDATE ITEM HISTORY REMOTELY ] =====================================================

//   # ===================================================== [ UPDATE HISTORY BASED ON ITEM TYPE ] =====================================================
  // # Functionality:
  // # - Updates the item history based on the type of item, either returning the difference or updating remotely.
  // # - Retrieves filtered history, processes the items, and updates the item history based on the type.
  // # - Calls relevant functions for processing items, updating history, and ensuring proper registration status.
  // #
  // # Input:
  // # - returnDiffData: A boolean flag indicating whether to return the differences in the data (default is false).
  // # Returns:
  // # - Either the processed differences if `returnDiffData` is true, or void if history is updated remotely.

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

        // change
        await checkIsRegisteredController<T>();
      }
    }
  }
//   # ===================================================== [ UPDATE HISTORY BASED ON ITEM TYPE ] =====================================================

//   # ===================================================== [ CHECK IF REGISTERED CONTROLLER ] =====================================================
  // # Functionality:
  // # - Verifies if a controller for a specific model (PosCategory, Product, or Customer) is registered in GetX.
  // # - If the controller is registered, it updates the controller’s lists with data from the local database.
  // # - Handles loading and assigning the list of items (PosCategories, Products, or Customers) to the respective controllers.
  // # - Ensures proper paging and data updates for each type of model.
  // #
  // # Input:
  // # - None (uses the generic type T to determine which controller to check and update).
  // # Returns:
  // # - Void.

  Future checkIsRegisteredController<T>() async {
    if (T == PosCategory) {
      // DONE :)
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
      // DONE :)
      bool customerControllerRegistered =
          Get.isRegistered<CustomerController>(tag: 'customerControllerMain');
      if (customerControllerRegistered) {
        _instance = GeneralLocalDB.getInstance<Customer>(
            fromJsonFun: Customer.fromJson);
        CustomerController customerController =
            Get.find(tag: 'customerControllerMain');

        customerController.hasMore.value = true;
        // stop that
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
//   # ===================================================== [ CHECK IF REGISTERED CONTROLLER ] =====================================================

// # ===================================================== [ COUNT ALL ITEMS ] =====================================================
  // # Functionality:
  // # - Retrieves the total count of categories, products, and customers from the synchronizing data service.
  // # - If the count data is successfully retrieved, it returns a `ResponseResult` with the count data.
  // # - In case of an error or no count data, it returns a default `ResponseResult` with zero counts for categories, products, and customers.
  // #
  // # Input:
  // # - None.
  // # Returns:
  // # - `ResponseResult`: Contains the count data or a default response indicating zero counts.

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
// # ===================================================== [ COUNT ALL ITEMS ] =====================================================

// # ===================================================== [ GET SELECTED LOAD DATA COUNT ] =====================================================
  // # Functionality:
  // # - Iterates through the `loaddata` map and counts the number of entries where the first value is `true`.
  // # - Returns the total count of such selected entries.
  // #
  // # Input:
  // # - None.
  // # Returns:
  // # - `int`: The count of entries where the first value is `true`.

  Future getSelectedLoadDataCount() async {
    int count = 0;
    loaddata.forEach((key, value) {
      if (value[0] == true) {
        count++;
      }
    });
    return count;
  }
// # ===================================================== [ GET SELECTED LOAD DATA COUNT ] =====================================================

// # ===================================================== [ SELECT LOAD DATA ] =====================================================
  // # Functionality:
  // # - Toggles the selection state of a specific load data entry (based on `newValue`).
  // # - Updates the `loaddata` map by setting the selection state for the given `map` entry to `newValue`.
  // # - Tracks the count of selected entries and determines if all entries are selected.
  // # - Notifies listeners to update the UI by calling `update()`.

  // # Input:
  // # - `newValue` (bool): The new selection state to be applied to the entry (true or false).
  // # - `map` (MapEntry<Loaddata, List<bool>>): The key-value pair from the `loaddata` map that is being updated.

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
// # ===================================================== [ SELECT LOAD DATA ] =====================================================

//   # ===================================================== [ SELECT ALL LOAD DATA ] =====================================================
  // # Functionality:
  // # - Selects all load data entries by setting each entry's value to `true`.
  // # - Updates the `isSelctedAll` flag to indicate that all entries are selected.
  // # - Recalculates the count of selected entries.
  // # - Calls `update()` to refresh the UI and reflect the changes.
  // #
  // # Input:
  // # - None.
  // # Returns:
  // # - `Future`: The function is asynchronous and does not return a value.
  Future selectAllLoadData() async {
    for (var key in loaddata.keys) {
      var value = loaddata[key];
      loaddata[key] = value!.map((item) => item is bool ? true : item).toList();
    }
    isSelctedAll = true;
    count = await getSelectedLoadDataCount();
    update(["selected load data"]);
  }
//   # ===================================================== [ SELECT ALL LOAD DATA ] =====================================================

// # ===================================================== [ UPDATE ALL LOAD DATA ] =====================================================
  // # Functionality:
  // # - Determines whether to update all load data entries or only the selected ones.
  // # - If all entries are selected or no entries are selected, it performs a full update.
  // # - If only some entries are selected, it performs a partial update based on the selected items.
  // # - Returns a `ResponseResult` indicating the status of the update operation.
  // #
  // # Input:
  // # - None.
  // # Returns:
  // # - `ResponseResult`: An object indicating the status of the update operation.
  // #
  // # Example:
  // # - If all entries are selected, a full update of all load data is performed.
  // # - If only a subset of entries are selected, only those selected entries are updated.
  Future<ResponseResult> updateAllLoadData() async {
    if (count == 0 || count == loaddata.length) {
      //// update all data
    } else {
      /// update only selected
    }
    return ResponseResult(
      status: true,
    );
  }
// # ===================================================== [ UPDATE ALL LOAD DATA ] =====================================================

// # ===================================================== [ DELETE SELECTED LOAD DATA ] =====================================================
  // # Functionality:
  // # - Deselects all selected load data entries by setting each entry's value to `false`.
  // # - Updates the `isSelctedAll` flag to indicate that not all entries are selected.
  // # - Resets the `count` of selected items to `0`.
  // # - Calls `update()` to refresh the UI and reflect the changes.
  // #
  // # Input:
  // # - None.
  // # Returns:
  // # - `Future`: The function is asynchronous and does not return a value.

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
// # ===================================================== [ DELETE SELECTED LOAD DATA ] =====================================================

//   # ===================================================== [ GET ITEMS DATA ] =====================================================
  // # Functionality:
  // # - Retrieves counts of various data types (Product, Customer, PosCategory, ProductUnit, AccountTax, AccountJournal)
  // #   both remotely (from a remote source) and locally (from a local database).
  // # - Updates the `itemdata` map with the fetched counts for each category.
  // # - Notifies UI components about the changes by calling `update()` with the appropriate keys.
  // #
  // # Input:
  // # - None.
  // # Returns:
  // # - `ResponseResult`: An object that contains the status (`true` for success, `false` for failure) and the data (`itemdata`).
  // #   If the fetch fails, a failure message is returned in the response.

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
      String message = await handleException(
          exception: e, navigation: false, methodName: "getitems");
      return ResponseResult(status: false, message: message);
    }
  }
//   # ===================================================== [ GET ITEMS DATA ] =====================================================

//   # ===================================================== [ REFRESH DATA FROM REMOTE SERVER ] =====================================================
  // # Functionality:
  // # - Refreshes data for specific entities (Products, Customers, PosCategories) from a remote server.
  // # - Based on the provided entity name, the corresponding data (products, customers, or categories) is refreshed by calling
  // #   the respective update methods.
  // # - Updates the `loadTital` value to provide the user with feedback on the data refresh process.
  // # - Handles errors gracefully with a custom exception handler.
  // #
  // # Input:
  // # - `name`: A string parameter that specifies which entity to refresh. Possible values are `'products'`, `'customers'`, or `'categories'`.
  // # Returns:
  // # - None.

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
      return await handleException(
          exception: e,
          navigation: false,
          methodName: "refreshDataFromRemoteServer");
    }
  }
//   # ===================================================== [ REFRESH DATA FROM REMOTE SERVER ] =====================================================

// # ===================================================== [ UPDATE ALL ] =====================================================
  // # Functionality:
  // # - Updates the specified data type (identified by the `name` parameter) by performing synchronization with the remote server.
  // # - Ensures the device is trusted before proceeding with the update process.
  // # - Fetches the updated data and refreshes the UI accordingly.
  // # - Provides feedback to the user by updating the `isUpdate` and `loading` states during the update process.
  // # - Handles network connectivity and device trust validation before performing any update.
  // #
  // # Input:
  // # - `name`: A string that specifies which data type (e.g., 'products', 'customers', etc.) should be updated.
  // # Returns:
  // # - `true`: If the update is successful.
  // # - `false`: If the update fails or an error occurs.
  // # - `"no_connection".tr`: If there is no internet connectivity.

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
      return e.toString();
    }
  }

// # ===================================================== [ UPDATE ALL ] =====================================================
  Future<void> loadingPosIPPrinter() async {
    List<PrintingSetting> list = [];
    try {
      isLoad.value = true;
      loadTital.value = "Pos IP Printer Loading";
      isLoadData.value = true;
      final LoadingItemsCountController loadingItemsCountController =
          Get.put(LoadingItemsCountController());
      loadingItemsCountController.resetLoadingItemCount();
      lengthRemote.value = 0;
      var result = await loadingSynchronizingDataService.loadPosPrinter();
      isLoadData.value = false;
      if (result is List) {
        loadTital.value = "Create Pos IP Printer";
        lengthRemote.value = result.length;
        list = (result as List<PrintingSetting>);
        _instance = GeneralLocalDB.getInstance<PrintingSetting>(
            fromJsonFun: PrintingSetting.fromJson);
        bool isExsit = await _instance!.checkIfTableExists();
        if (!isExsit) {
          await await _instance!.createTable(
              structure: LocalDatabaseStructure.posPrinterStructure);
        }
        await _instance!.deleteData();
        if (list.isNotEmpty) {
          await _instance!.createList(recordsList: list);
        }
      }
      loadTital.value = 'Completed';
      isLoad.value = false;
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }

  Future<void> loadingGeneralSettings() async {
    try {
      isLoad.value = true;
      loadTital.value = "General Settings";
      isLoadData.value = true;
      final LoadingItemsCountController loadingItemsCountController =
          Get.put(LoadingItemsCountController());
      loadingItemsCountController.resetLoadingItemCount();
      lengthRemote.value = 0;
      var result = await loadingSynchronizingDataService.loadGeneralSettings();
      isLoadData.value = false;
      if (result is List) {
        loadTital.value = "Create General Settings";
        lengthRemote.value = result.length;
        await SharedPr.setGeneralSettingsObj(generalSettings: result[0]);
      }
      loadTital.value = 'Completed';
      isLoad.value = false;
    } catch (e) {
      isLoad.value = false;
      isLoadData.value = false;
    }
  }
}
