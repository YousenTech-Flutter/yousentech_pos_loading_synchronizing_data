import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_widgets/config/app_enum.dart';
import 'package:shared_widgets/shared_widgets/app_dialog.dart';
import 'package:yousentech_authentication/authentication/presentation/views/employees_list.dart';
import 'package:yousentech_pos_local_db/yousentech_pos_local_db.dart';

void failLoadingDialog() {
  CustomDialog.getInstance().dialog(
      title: 'error_message',
      message: 'loading_error'.tr,
      fontSizetext: 3.sp,
      dialogType: MessageTypes.error,
      icon: "assets/image/warning.svg",
      buttonwidth: 80.w,
      primaryButtonText: 'retry',
      onPressed: () async {
        try {
          Get.back();
          await DbHelper.backupDatabase();
          await DBHelper.dropDBTable(isDeleteBasicData: true);
          await DBHelper.createDBTables();
          await DbHelper.restoreDatabase();
          // change
          // Get.offAll(() => const HomePage());
          //===
        } catch (e) {
          return;
        }
      },
      secondaryOnPressed: () async {
        await DbHelper.backupDatabase();
        await DBHelper.dropDBTable(isDeleteBasicData: true);
        await DBHelper.createDBTables();
        await DbHelper.restoreDatabase();
        Get.offAll(() => const EmployeesListScreen());
      });
}
