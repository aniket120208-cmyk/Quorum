import 'package:flutter/services.dart';

final List<TextInputFormatter> emailInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9@._%+\-]")),
  LengthLimitingTextInputFormatter(254),
];

final RegExp _emailRegExp = RegExp(
  r'^[a-zA-Z0-9](?:[a-zA-Z0-9._%+\-]*[a-zA-Z0-9])?'
  r'@(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$',
);

bool isValidEmail(String value) {
  final email = value.trim();
  if (email.length > 254 || email.contains('..')) return false;
  return _emailRegExp.hasMatch(email);
}

String? validateName(String value) {
  final name = value.trim();
  if (name.isEmpty) return 'Please enter your name.';
  if (name.length < 2) return 'Name must be at least 2 characters.';

  final validName = RegExp(r"^[\p{L}\p{M}][\p{L}\p{M} .'\-]*$", unicode: true);
  if (!validName.hasMatch(name)) {
    return 'Name can only contain letters, spaces, . \' and -';
  }
  return null;
}

class PasswordRules {
  static bool hasMinLength(String p) => p.length >= 8;
  static bool hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p);
  static bool hasLowercase(String p) => RegExp(r'[a-z]').hasMatch(p);
  static bool hasSpecial(String p) =>
      RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/;`~']''').hasMatch(p);
}

String? validatePassword(String p) {
  if (p.isEmpty) return 'Please enter a password.';
  if (!PasswordRules.hasMinLength(p) ||
      !PasswordRules.hasUppercase(p) ||
      !PasswordRules.hasLowercase(p) ||
      !PasswordRules.hasSpecial(p)) {
    return 'Password does not meet the requirements.';
  }
  return null;
}