class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'البريد الإلكتروني مطلوب';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'بريد إلكتروني غير صالح';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'يجب أن تحتوي حرف كبير واحد';
    if (!value.contains(RegExp(r'[0-9]'))) return 'يجب أن تحتوي رقم واحد';
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'اسم المستخدم مطلوب';
    if (value.length < 3) return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    if (value.length > 30) return 'اسم المستخدم يجب ألا يتجاوز 30 حرف';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) return 'اسم المستخدم يحتوي أحرف غير مسموحة';
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) return 'الاسم مطلوب';
    if (value.length > 60) return 'الاسم يجب ألا يتجاوز 60 حرف';
    return null;
  }

  static String? validateTweetContent(String? value) {
    if (value == null || value.trim().isEmpty) return 'محتوى التغريدة مطلوب';
    if (value.length > 500) return 'التغريدة يجب ألا تتجاوز 500 حرف';
    return null;
  }

  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) return 'الرسالة مطلوبة';
    return null;
  }
}