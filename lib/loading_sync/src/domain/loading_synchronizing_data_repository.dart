

abstract class LoadingSynchronizingDataRepository {
  Future loadUserPosSettingInfo({
    required List<int> posSettingIds,
  });

  Future loadCurrentUserPosSettingInfo({
    required int posSettingId,
  });

  Future loadProductDataBasedOnPosCategory({
    required List<int> posCategoriesIds,
  });

  Future getProductHistory();
  Future loadProductUnitData();
  Future getFilteredHistory({required List<int> excludeIds, required String typeName, required int currentPosId});
  Future deleteProductHistory({required List<int> ids});
  Future refreshLocalDataFromRemoteServer({required String typeName , required List<int> userPosCategories });
  Future getProductByIds({required List ids});
  Future updateItemHistory({required String typeName});
  Future loadPosCategoryBasedOnUser();
  Future getItemCheckSumRemotely<T>({required List<int> posCategoriesId});
  // Future getProductCheckSumLocally();
  Future loadPosSession();
  Future loadUserSalePrices();
  Future loadCategorySalePrices();
  Future<dynamic> loadCustomerInfo();
  Future loadPosPrinter();
}
