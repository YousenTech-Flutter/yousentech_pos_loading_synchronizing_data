// ignore_for_file: type_literal_in_constant_pattern

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pos_shared_preferences/models/account_journal/data/account_journal.dart';
import 'package:pos_shared_preferences/models/account_tax/data/account_tax.dart';
import 'package:pos_shared_preferences/models/basic_item_history.dart';
import 'package:pos_shared_preferences/models/category_sale_price.dart';
import 'package:pos_shared_preferences/models/count_items.dart';
import 'package:pos_shared_preferences/models/customer_model.dart';
import 'package:pos_shared_preferences/models/pos_categories_data/pos_category.dart';
import 'package:pos_shared_preferences/models/pos_session/posSession.dart';
import 'package:pos_shared_preferences/models/pos_setting_info_model.dart';
import 'package:pos_shared_preferences/models/printing_setting.dart';
import 'package:pos_shared_preferences/models/product_data/product.dart';
import 'package:pos_shared_preferences/models/product_unit/data/product_unit.dart';
import 'package:pos_shared_preferences/models/user_sale_price.dart';
import 'package:pos_shared_preferences/pos_shared_preferences.dart';
import 'package:shared_widgets/config/app_odoo_models.dart';
import 'package:shared_widgets/shared_widgets/handle_exception_helper.dart';
import 'package:shared_widgets/shared_widgets/odoo_connection_helper.dart';
import 'package:yousentech_pos_loading_synchronizing_data/loading_sync/utils/define_type_function.dart';
import 'package:yousentech_pos_local_db/yousentech_pos_local_db.dart';
import 'loading_synchronizing_data_repository.dart';

class LoadingSynchronizingDataService
    extends LoadingSynchronizingDataRepository {
  GeneralLocalDB? _instance;

  LoadingSynchronizingDataService({type}) {
    _instance = getLocalInstanceType(type: type);
  }

  @override
  Future<dynamic> loadUserPosSettingInfo(
      {required List<int> posSettingIds}) async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.posSetting,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {},
          'domain': [
            ['id', 'in', posSettingIds],
          ],
          'fields': [],
        },
      });

      return result.isEmpty
          ? <PosSettingInfo>[]
          : (result as List).map((e) => PosSettingInfo.fromJson(e)).toList();
    } catch (e) {
      return await handleException(
          exception: e,
          navigation: false,
          methodName: "loadUserPosSettingInfo");
    }
  }

  @override
  Future<dynamic> loadCustomerInfo() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.customer,
        'method': 'get_customers',
        'args': [],
        'kwargs': {},
      });
      return result.isEmpty
          ? <Customer>[]
          : (result as List)
              .map((e) => Customer.fromJson(e, fromLocal: false))
              .toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "loadCustomerInfo");
    }
  }

  @override
  Future<dynamic> loadCurrentUserPosSettingInfo(
      {required int posSettingId}) async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.posSetting,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {},
          'domain': [
            ['id', '=', posSettingId],
          ],
          'fields': [],
        },
      });
      return result == null ? null : PosSettingInfo.fromJson(result.first);
    } catch (e) {
      return await handleException(
          exception: e,
          navigation: false,
          methodName: "loadCurrentUserPosSettingInfo");
    }
  }

  // @override
  Future<dynamic> loadCurrentCompany({required int companyId}) async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.customer,
        'method': 'get_customers',
        'args': [companyId],
        'kwargs': {
        },
      });
      return result == null || (result is List && result.isEmpty)
          ? null
          : Customer.fromJson(result.first, fromLocal: false);
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "loadCurrentCompany");
    }
  }

  @override
  Future loadPosCategoryBasedOnUser() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.posCategoryTransit,
        'method': 'get_translated_category_names',
        'args': [SharedPr.currentPosObject!.id],
        'kwargs': {
        },
      });
      return result.isEmpty
          ? <PosCategory>[]
          : (result as List)
              .map((e) => PosCategory.fromJson(e, fromPosCategoryModel: false))
              .toList();
    } catch (e) {
      return await handleException(
          exception: e,
          navigation: false,
          methodName: "loadPosCategoryBasedOnUser");
    }
  }

  @override
  Future loadProductUnitData() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.uomUom,
        'method': 'get_translated_uom_names',
        'args': [],
        'kwargs': {
        },
      });
      return result.isEmpty
          ? <ProductUnit>[]
          : (result as List)
              .map((e) => ProductUnit.fromJson(e, fromLocal: false))
              .toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "loadProductUnitData");
    }
  }

  Future loadAccountTaxData() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.accountTaxTransit,
        'method': 'get_translated_account_tax_names',
        'args': [],
        'kwargs': {
        },
      });
      return result.isEmpty
          ? <AccountTax>[]
          : (result as List)
              .map((e) => AccountTax.fromJson(e, fromLocal: false))
              .toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "loadAccountTaxData");
    }
  }

  Future loadAccountJournalData() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.accountJournalTransit,
        'method': 'get_translated_account_journal_names',
        'args': [SharedPr.currentPosObject!.paymentTypeJournalId],
        'kwargs': {
        },
      });
      return result.isEmpty
          ? <AccountJournal>[]
          : (result as List)
              .map((e) => AccountJournal.fromJson(e, fromLocal: false))
              .toList();
    } catch (e) {
      return await handleException(
          exception: e,
          navigation: false,
          methodName: "loadAccountJournalData");
    }
  }

  @override
  Future loadPosSession() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': 'so.pos.session',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {},
          'domain': [
            ['pos_id', '=', SharedPr.currentPosObject!.id],
            ['user_id', '=', SharedPr.chosenUserObj!.id]
          ],
        },
      });
      return result.isEmpty || result == null
          ? <PosSession>[]
          : (result as List)
              .map((e) => PosSession.fromJson(e, fromLocal: false))
              .toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getAllPosSession");
    }
  }

    @override
  Future loadUserSalePrices() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.userSalePrice,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {},
          'domain': [
            // ['pos_id', '=', SharedPr.currentPosObject!.id],
            ['user_id', '=', SharedPr.chosenUserObj!.id]
          ],
        },
      });
      return result.isEmpty || result == null
          ? <UserSalePrice>[]
          : (result as List)
          .map((e) => UserSalePrice.fromJson(e, fromLocal: false))
          .toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getAllUserSalePrice");
    }
  }

    @override
  Future loadCategorySalePrices() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.categorySalePrice,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {},
          'domain': [
            ['user_id', '=', SharedPr.chosenUserObj!.id]
          ],
        },
      });
      return result.isEmpty || result == null
          ? <CategorySalePrice>[]
          : (result as List)
          .map((e) => CategorySalePrice.fromJson(e, fromLocal: false))
          .toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "loadCategorySalePrice");
    }
  }

  @override
  Future getItemCheckSumRemotely<T>(
      {required List<int> posCategoriesId}) async {
    Map<dynamic, Map> checksumMethodsBasedOnModel = {
      Product: {
        'model': OdooModels.productTemplate,
        'method': 'get_checksum_of_products'
      },
      PosCategory: {
        'model': OdooModels.posCategory,
        'method': 'get_checksum_of_categories'
      },
      Customer: {
        'model': OdooModels.customer,
        'method': 'get_checksum_of_customers'
      },
    };

    var item = checksumMethodsBasedOnModel[T];
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': item!['model'],
        'method': item['method'],
        'args': [SharedPr.currentPosObject!.id],
        'kwargs': {
        },
      });

      return result;
    } catch (e) {
      return await handleException(
          exception: e,
          navigation: true,
          methodName: "getItemCheckSumRemotely");
    }
  }

  String hashString(String inputString) {
    // Convert the string to bytes, then hash
    var bytes = utf8.encode(inputString);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  Future getCheckSumLocally<T>(
      {required List<T> recordsList, bool isRepModuleInstalled = false}) async {
    late String recordData, checksum;
    final List<String> listHashes = [];
    if (T == Product) {
      for (Product record in (recordsList as List<Product>)) {
        recordData =
            '{"uom_id": "${record.uomId}","detailed_type":"product","default_code": "${[
          '',
          null
        ].contains(record.defaultCode) ? "False" : record.defaultCode}","name": {"en_US": "${record.productName!.enUS}","ar_001": "${record.productName!.ar001}"},"barcode": "${record.barcode ?? "False"}","pos_available": "True","list_price": "${record.unitPrice}","so_pos_categ_id": "${record.soPosCategId}","quick_menu_availability": "${[
          1,
          true
        ].contains(record.quickMenuAvailability) ? "True" : "False"}","taxes_id": "${record.taxesId}","qty_available": "${record.availableQty}"}';
        var digest = hashString(recordData);
        listHashes.add(digest.toString());
      }
    } else if (T == PosCategory) {
      for (PosCategory record in (recordsList as List<PosCategory>)) {
        recordData =
            '{"name": {"en_US": "${record.name!.enUS}","ar_001": "${record.name!.ar001}"}}';
        var digest = hashString(recordData);
        listHashes.add(digest.toString());
      }
    } else if (T == Customer) {
      for (Customer record in (recordsList as List<Customer>)) {
        if(isRepModuleInstalled){
          recordData ='{"name": "${record.name}", "email": "${record.email ?? "False"}", "phone": "${record.phone ?? ""}", "customer_rank": "${record.customerRank ?? "False"}", "image_1920": "${record.image ?? "False"}", "vat": "${record.vat ?? "False"}", "city": "${record.city ?? "False"}", "country_id": "${record.country?.countryId ?? "False"}", "company_id": "${record.companyId==0|| record.companyId==null? "False" :record.companyId }", "is_company": "${record.isCompany !=null ?capitalize(record.isCompany.toString()) : "False"}", "street": "${record.street ?? "False"}", "other_seller_id": "${record.otherSelleId ?? "False"}", "zip": "${record.postalCode ?? "False"}", "l10n_sa_additional_identification_number": "${record.additionalNo ?? "False"}", "l10n_sa_edi_building_number": "${record.buildingNo ?? "False"}", "street2": "${record.district ?? "False"}", "l10n_sa_edi_plot_identification": "${record.l10nSaEdiPlotIdentification ?? "False"}"}';

        }
        else{
          recordData ='{"name": "${record.name}", "email": "${record.email ?? "False"}", "phone": "${record.phone ?? ""}", "customer_rank": "${record.customerRank ?? "False"}", "image_1920": "${record.image ?? "False"}", "vat": "${record.vat ?? "False"}", "city": "${record.city ?? "False"}", "country_id": "${record.country?.countryId ?? "False"}", "company_id": "${record.companyId==0|| record.companyId==null? "False" :record.companyId }", "is_company": "${record.isCompany !=null ?capitalize(record.isCompany.toString()) : "False"}", "street": "${record.street ?? "False"}", "other_seller_id": "${record.otherSelleId ?? "False"}", "Postal_code": "${record.postalCode ?? "False"}", "additional_no": "${record.additionalNo ?? "False"}", "building_no": "${record.buildingNo ?? "False"}", "District": "${record.district ?? "False"}"}';

        }

        if (kDebugMode) {
          print(recordData);
        }
        var digest = hashString(recordData);
        listHashes.add(digest.toString());
      }
    }
    listHashes.sort();
    checksum = md5.convert(utf8.encode(listHashes.join(''))).toString();

    return checksum;
  }

  @override
  Future loadProductDataBasedOnPosCategory(
      {required List<int> posCategoriesIds}) async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.productProductTransit,
        'method': 'get_products_by_pos_category',
        'args': [SharedPr.currentPosObject!.id],
        'kwargs': {},
      });
      return result.isEmpty
          ? <Product>[]
          : (result as List).map<Product>((e) => Product.fromJson(e)).toList();
    } catch (e) {
      return await handleException(
          exception: e,
          navigation: false,
          methodName: "loadProductDataBasedOnPosCategory");
    }
  }

  @override
  Future getProductHistory() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.itemsHistory,
        'method': 'search_read',
        'args': [],
        'domain': [
          ['type_name', '=', 'product.template'],
        ],
        'kwargs': {},
      });

      return result.isEmpty
          ? <int>[]
          : (result as List).map((e) => e["product_id"][0]).toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getProductHistory");
    }
  }

  @override
  Future getFilteredHistory(
      {required List<int> excludeIds,
      required String typeName,
      required int currentPosId,
      List<int>? productIds}) async {
    try {
      List paramsList = [excludeIds, typeName, SharedPr.currentPosObject!.id];
      if (productIds != null) {
        paramsList.add(productIds);
      }
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.itemsHistory,
        'method': 'get_filtered_history',
        'args': [excludeIds, typeName, SharedPr.currentPosObject!.id],
        'domain': [],
        'kwargs': {},
      });
      return result.isEmpty || result == null
          ? <BasicItemHistory>[]
          : (result as List).map((e) => BasicItemHistory.fromJson(e)).toList();
    } 
    catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getFilteredHistory");
    }
  }

  Future getFilteredHistoryIsNotLocall({
    required List<int> excludeIds,
    required String typeName,
    required List<int> userPosCategories,
    required List ids,
    required String domain,
  }) async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.itemsHistory,
        'method': 'get_filtered_history',
        'args': [excludeIds, typeName, userPosCategories],
        'domain': ids.isEmpty
            ? [
                ['is_added', '=', false],
              ]
            : [
                [domain, 'not in', ids],
                ['is_added', '=', false],
              ],
        'kwargs': {},
      });
      return result.isEmpty || result == null
          ? <BasicItemHistory>[]
          : (result as List).map((e) => BasicItemHistory.fromJson(e)).toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getFilteredHistory");
    }
  }

  @override
  Future getProductByIds({required List ids}) async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.product,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            ['id', 'in', ids],
            ['active', '=', true],
            ['pos_available', '=', true]
          ],
          'fields': [
            'id',
            'name',
            'product_tmpl_id',
            'uom_id',
            'uom_name',
            'so_pos_categ_id',
            'default_code',
            'barcode',
            'image_1920',
            'currency_id',
            'unit_price'
          ],
        },
      });

      result.isEmpty
          ? null
          : (result as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getProductByIds");
    }
  }


  @override
  Future updateItemHistory({required String typeName, int? itemId}) async {
    try {
      var listToSend = [SharedPr.currentPosObject!.id, typeName];
      listToSend.addIf(itemId != null, itemId);
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.itemsHistory,
        'method': 'bulk_update_used_by',
        'args': listToSend,
        'kwargs': {},
      });

      return result == null ? false : true;
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "updateItemHistory");
    }
  }

  @override
  Future deleteProductHistory({required List<int> ids}) async {
    try {
      bool result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.itemsHistory,
        'method': 'unlink',
        'args': [ids],
        'kwargs': {},
      });

      return result;
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "deleteProductHistory");
    }
  }

  @override
  Future refreshLocalDataFromRemoteServer(
      {required String typeName, required List<int> userPosCategories}) async {
    try {
      var remoteProductHistory = await getFilteredHistory(
          excludeIds: <int>[SharedPr.currentPosObject!.id!],
          typeName: typeName,
          currentPosId: SharedPr.currentPosObject!.id!);

      // check If there is any  data
      if (remoteProductHistory!.isNotEmpty &&
          remoteProductHistory.runtimeType != String) {
        List<Product> productToInsert =
            (remoteProductHistory as List<BasicItemHistory>)
                .where((element) => element.isAdded!)
                .map((e) => e.product!)
                .toList();

        List<Product> productToUpdate = (remoteProductHistory)
            .where((element) => !element.isAdded!)
            .map((e) => e.product!)
            .toList();

        var updateCount = await _instance!
            .updateList(recordsList: productToUpdate, whereKey: 'product_id');

        var createCount =
            await _instance!.createList(recordsList: productToInsert);

        var prodects = remoteProductHistory.map((e) => e.productId!).toList();
        if ((productToUpdate.isNotEmpty && updateCount > 0) ||
            (productToInsert.isNotEmpty && createCount > 0)) {
          // delete the data from the server model product_history
          await deleteProductHistory(ids: prodects);
        }
      }
    } catch (e) {
      return await handleException(
          exception: e,
          navigation: false,
          methodName: "refreshLocalDataFromRemoteServer");
    }
  }

  Future getLocalIds<T>() async {
    try {
      _instance = getLocalInstanceType<T>();
      List result = await _instance!.index();
      return result.isEmpty ? [] : result.map((e) => e.id).toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getLocal$T Ids");
    }
  }

  Future getLocalData<T>({required ids}) async {
    try {
      List result;
      _instance = getLocalInstanceType<T>();
      if (T == Product) {
        result = await _instance!.filter(
            where:
                'product_id IN (${List.generate(ids.length, (_) => '?').join(', ')})',
            whereArgs: ids);
      } else {
        result = await _instance!.filter(
            where:
                'id IN (${List.generate(ids.length, (_) => '?').join(', ')})',
            whereArgs: ids);
      }

      return result;
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getLocalData$T");
    }
  }



  Future getRemotProductIsNotIds(
      {required List<int> ids, required List<int> posCategoriesIds}) async {
    try {
      List result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.productTemplate,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            ['id', 'not in', ids],
            ['so_pos_categ_id', 'in', posCategoriesIds],
            ['active', '=', true],
            ['pos_available', '=', true]
          ],
          'context': {'lang': SharedPr.lang == 'ar' ? 'ar_001' : 'en_US'}
        },
      });
      return result.isEmpty
          ? null
          : result.map((e) => Product.fromJson(e, fromTemblet: true)).toList();
    } catch (e) {
      return await handleException(
          exception: e,
          navigation: false,
          methodName: "getRemotProductIsNotIds");
    }
  }

  Future getCountDataLocal<T>() async {
    try {
      _instance = getLocalInstanceType<T>();

      var result = await _instance!.checkIfThereIsRowsInTable();
      return result;
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getCountLocal$T");
    }
  }

  Future countAll() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.itemsHistory,
        'method': 'count_all',
        'args': [SharedPr.currentPosObject!.id],
        'kwargs': {},
      });
      return CountItems.fromJson(result);
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "countAll");
    }
  }

  Future getCountDeleteData(
      {required List<int> excludeIds, required String typeName}) async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.itemsHistory,
        'method': 'get_filtered_history',
        'args': [excludeIds, typeName, SharedPr.currentPosObject!.id],
        'domain': [
          ["is_deleted", '=', true]
        ],
        'kwargs': {},
      });
      return result.isEmpty || result == null
          ? <BasicItemHistory>[]
          : (result as List).map((e) => BasicItemHistory.fromJson(e)).toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "getCountDeleteData");
    }
  }

  String capitalize(String input) {
  return input[0].toUpperCase() + input.substring(1);
}


  @override
  Future loadPosPrinter() async {
    try {
      var result = await OdooProjectOwnerConnectionHelper.odooClient.callKw({
        'model': OdooModels.posPrinter,
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {},
          'domain': [
            ['pos_setting_id', '=', SharedPr.currentPosObject!.id!]
          ],
        },
      });
      return result.isEmpty || result == null
          ? <PrintingSetting>[]
          : (result as List)
          .map((e) => PrintingSetting.fromJson(e))
          .toList();
    } catch (e) {
      return await handleException(
          exception: e, navigation: false, methodName: "loadPosPrinter");
    }
  }
}
