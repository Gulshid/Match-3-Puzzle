import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple theme-mode provider. Riverpod equivalent of the ThemeCubit
/// pattern used in our Bloc-based apps — just a StateProvider here since
/// there's no async logic involved.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
