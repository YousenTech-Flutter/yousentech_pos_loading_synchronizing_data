
import 'package:pos_shared_preferences/models/account_journal/data/account_journal.dart';
import 'package:pos_shared_preferences/models/account_tax/data/account_tax.dart';
import 'package:pos_shared_preferences/models/customer_model.dart';
import 'package:pos_shared_preferences/models/pos_categories_data/pos_category.dart';
import 'package:pos_shared_preferences/models/product_data/product.dart';
import 'package:pos_shared_preferences/models/product_unit/data/product_unit.dart';
import 'package:shared_widgets/config/app_odoo_models.dart';
import 'package:yousentech_pos_loading_synchronizing_data/loading_sync/config/app_enums.dart';
import 'package:yousentech_pos_local_db/yousentech_pos_local_db.dart';

getLocalInstanceType<T>({T? type}) {
  GeneralLocalDB<dynamic>? instance;
  switch (type ?? T) {
    case const (Product):
      instance =
          GeneralLocalDB.getInstance<Product>(fromJsonFun: Product.fromJson);
      break;
    case const (PosCategory) :
      instance = GeneralLocalDB.getInstance<PosCategory>(
          fromJsonFun: PosCategory.fromJson);
      break;
    case const (Customer):
      instance =
          GeneralLocalDB.getInstance<Customer>(fromJsonFun: Customer.fromJson);
      break;
    case const (ProductUnit):
      instance = GeneralLocalDB.getInstance<ProductUnit>(
          fromJsonFun: ProductUnit.fromJson);
      break;
    case const (AccountTax):
      instance = GeneralLocalDB.getInstance<AccountTax>(
          fromJsonFun: AccountTax.fromJson);
      break;
    case const (AccountJournal):
      instance = GeneralLocalDB.getInstance<AccountJournal>(
          fromJsonFun: AccountJournal.fromJson);
      break;

    default:
  }
  return instance;
}
Type getModelClass(String type) {
  if (type == Loaddata.products.toString()) {
    return Product;
  } else if (type == Loaddata.categories.toString()) {
    return PosCategory;
  } else if (type == Loaddata.customers.toString()) {
    return Customer;
  } else if (type == Loaddata.productUnit.toString()) {
    return ProductUnit;
  } else if (type == Loaddata.accountTax.toString()) {
    return AccountTax;
  } else if (type == Loaddata.accountJournal.toString()) {
    return AccountJournal;
  }
  return Product;
}
String getNamesOfSync<T>() {
  String typeNameX = '';
  if (T == Product) {
    typeNameX =  "products";
  } else if (T == PosCategory) {
    typeNameX = "categories";
  } else if (T == Customer) {
    typeNameX = "customers";
  } else if (T == ProductUnit) {
    typeNameX = "units";
  } else if (T == AccountTax) {
    typeNameX = "pos_account_tax_list";
  } else if (T == AccountJournal) {
    typeNameX = "pos_account_journal_list";
  }
  return typeNameX;
}
String getOdooModels<T>() {
  String typeNameX = '';
  if (T == Product) {
    typeNameX = OdooModels.productTemplate;
  } else if (T == PosCategory) {
    typeNameX = OdooModels.posCategory;
  } else if (T == Customer) {
    typeNameX = OdooModels.customer;
  } else if (T == ProductUnit) {
    typeNameX = OdooModels.uomUomMain;
  } else if (T == AccountTax) {
    typeNameX = OdooModels.accountTax;
  } else if (T == AccountJournal) {
    typeNameX = OdooModels.accountJournal;
  }
  return typeNameX;
}
getLocalInstanceTypeByName({required String name}) {

  Type typeX = getModelClass(name);

  return getLocalInstanceType(type: typeX);
}
