import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MaskTextInputFormatter implements TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final value = _format((newValue.text.replaceAll(RegExp(r'[\D]'), '')));
    final pos = value.lastIndexOf(RegExp(r'[\d]')) + 1;
    return TextEditingValue(
        text: value,
        selection: TextSelection(baseOffset: pos, extentOffset: pos));
  }

  String _format(String value) {
    String mask = '+38(0~~)-~~~-~~-~~~';
    final chars = value.split('');
    chars.forEach((element) {
      mask = mask.replaceFirst('~', element);
    });
    return mask;
  }
}
