import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_shared_preferences/pos_shared_preferences.dart';
import 'package:shared_widgets/config/app_colors.dart';
import 'package:shared_widgets/config/app_styles.dart';
import 'package:shared_widgets/shared_widgets/app_button.dart';
import 'package:shared_widgets/shared_widgets/app_dialog.dart';
import 'package:shared_widgets/utils/responsive_helpers/size_helper_extenstions.dart';
import 'package:shared_widgets/utils/responsive_helpers/size_provider.dart';
import 'package:yousentech_pos_invoice/invoices/presentation/invoice_home.dart';
import 'package:yousentech_pos_local_db/yousentech_pos_local_db.dart';

void failLoadingDialog() {
  dialogcontent(
    context: Get.context!,
    content:
        // title: 'error_message',
        // message: 'loading_error'.tr,
        // fontSizetext: 3.sp,
        // dialogType: MessageTypes.error,
        // icon: "assets/image/warning.svg",
        // buttonwidth: 80.w,
        // primaryButtonText: 'retry',
        // onPressed: () async {
        //   try {
        //     Get.back();
        //     await DbHelper.backupDatabase();
        //     await DBHelper.dropDBTable(isDeleteBasicData: true);
        //     await DBHelper.createDBTables();
        //     await DbHelper.restoreDatabase();
        //     Get.offAll(() => const InvoiceHome());
        //   } catch (e) {
        //     return;
        //   }
        // },
        // secondaryOnPressed: () async {
        //   await DbHelper.backupDatabase();
        //   await DBHelper.dropDBTable(isDeleteBasicData: true);
        //   await DBHelper.createDBTables();
        //   await DbHelper.restoreDatabase();
        //   Get.offAll(() => const EmployeesListScreen());
        // }
        Builder(
      builder: (context) {
        return SizeProvider(
          baseSize: Size(context.setWidth(454.48), context.setHeight(350)),
          width: context.setWidth(454.48),
          height: context.setHeight(350),
          child: Obx(
            () => SizedBox(
              width: context.setWidth(80),
              height: context.setHeight(350),
              child: Padding(
                padding: EdgeInsets.all(context.setMinSize(20)),
                child: Column(
                  spacing: context.setHeight(10),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "error_message".tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SharedPr.isDarkMode!
                            ? Colors.white
                            : const Color(0xFF2E2E2E),
                        fontSize: context.setSp(16),
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColor.red,
                      size: context.setMinSize(50),
                    ),
                    Text(
                      "loading_error".tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SharedPr.isDarkMode!
                            ? Colors.white
                            : const Color(0xFF2E2E2E),
                        fontSize: context.setSp(14),
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Spacer(),
                    Row(
                      spacing: context.setWidth(10),
                      children: [
                        Expanded(
                          child: ButtonElevated(
                            text: "retry".tr,
                            height: context.setHeight(35),
                            borderRadius: context.setMinSize(5),
                            backgroundColor: AppColor.cyanTeal,
                            showBoxShadow: true,
                            textStyle: AppStyle.textStyle(
                              color: Colors.white,
                              fontSize: context.setSp(12),
                              fontWeight: FontWeight.normal,
                            ),
                            onPressed: () async {
                              try {
                                Get.back();
                                await DbHelper.backupDatabase();
                                await DBHelper.dropDBTable(
                                    isDeleteBasicData: true);
                                await DBHelper.createDBTables();
                                await DbHelper.restoreDatabase();
                                Get.offAll(() => const InvoiceHome());
                              } catch (e) {
                                return;
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ButtonElevated(
                            text: 'cancel'.tr,
                            height: context.setHeight(35),
                            borderRadius: context.setMinSize(5),
                            borderColor: AppColor.paleAqua,
                            textStyle: AppStyle.textStyle(
                              color: AppColor.slateGray,
                              fontSize: context.setSp(12),
                              fontWeight: FontWeight.normal,
                            ),
                            onPressed: () async {
                              Get.back();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
