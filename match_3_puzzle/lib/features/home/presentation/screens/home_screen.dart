import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 72.r,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: 12.h),
              Text(
                'Match-3 Puzzle',
                style: TextStyle(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/levels'),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Text('Play', style: TextStyle(fontSize: 17.sp)),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/settings'),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child:
                        Text('Settings', style: TextStyle(fontSize: 17.sp)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
