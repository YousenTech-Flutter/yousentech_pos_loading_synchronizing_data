import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_widgets/config/app_colors.dart';

Padding definitionColorTable() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 5.r),
    child: Row(
      children: [
        Row(
          children: [
            Container(
                width: 7.r,
                height: 7.r,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(1.r)),
                    color: AppColor.lightGreen)),
            SizedBox(
              width: 2.r,
            ),
            Text('addition'.tr,
                style: TextStyle(fontSize: 8.r, color: AppColor.strongDimGray)),
          ],
        ),
        SizedBox(
          width: 7.r,
        ),
        Row(
          children: [
            Container(
                width: 7.r,
                height: 7.r,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(1.r)),
                    color: AppColor.cyanTeal.withOpacity(0.2))),
            SizedBox(
              width: 2.r,
            ),
            Text('edit'.tr,
                style: TextStyle(fontSize: 8.r, color: AppColor.strongDimGray)),
          ],
        ),
        SizedBox(
          width: 7.r,
        ),
        Row(
          children: [
            Container(
                width: 7.r,
                height: 7.r,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(1.r)),
                    color: AppColor.crimsonLight)),
            SizedBox(
              width: 2.r,
            ),
            Text(
              'delete'.tr,
              style: TextStyle(fontSize: 8.r, color: AppColor.strongDimGray),
            ),
          ],
        ),
      ],
    ),
  );
}
