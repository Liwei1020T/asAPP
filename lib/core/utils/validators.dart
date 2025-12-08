// 表单验证工具类

/// 密码强度等级
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// 密码验证结果
class PasswordValidationResult {
  final bool isValid;
  final PasswordStrength strength;
  final List<String> errors;
  final List<String> suggestions;

  const PasswordValidationResult({
    required this.isValid,
    required this.strength,
    this.errors = const [],
    this.suggestions = const [],
  });

  /// 获取强度显示文本
  String get strengthText {
    switch (strength) {
      case PasswordStrength.weak:
        return '弱';
      case PasswordStrength.medium:
        return '中';
      case PasswordStrength.strong:
        return '强';
    }
  }

  /// 获取强度对应的进度值 (0.0 - 1.0)
  double get strengthValue {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}

/// 密码验证器
/// 
/// 密码要求：
/// - 最少 8 位
/// - 包含大写字母
/// - 包含小写字母
/// - 包含数字
class PasswordValidator {
  static const int minLength = 8;

  /// 验证密码并返回详细结果
  static PasswordValidationResult validate(String password) {
    final errors = <String>[];
    final suggestions = <String>[];
    int score = 0;

    // 检查长度
    if (password.length < minLength) {
      errors.add('密码长度至少为 $minLength 位');
    } else {
      score++;
      if (password.length >= 12) {
        score++; // 额外加分
      }
    }

    // 检查小写字母
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('密码需包含小写字母');
    } else {
      score++;
    }

    // 检查大写字母
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('密码需包含大写字母');
    } else {
      score++;
    }

    // 检查数字
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('密码需包含数字');
    } else {
      score++;
    }

    // 检查特殊字符（非必须，但增加强度）
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score++;
      suggestions.add('包含特殊字符，安全性更高');
    } else if (errors.isEmpty) {
      suggestions.add('添加特殊字符可提高安全性');
    }

    // 计算强度等级
    PasswordStrength strength;
    if (score <= 2) {
      strength = PasswordStrength.weak;
    } else if (score <= 4) {
      strength = PasswordStrength.medium;
    } else {
      strength = PasswordStrength.strong;
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      strength: strength,
      errors: errors,
      suggestions: suggestions,
    );
  }

  /// 简单验证密码是否有效
  static bool isValid(String password) {
    return validate(password).isValid;
  }

  /// 获取密码错误信息（用于表单验证）
  static String? getErrorMessage(String? password) {
    if (password == null || password.isEmpty) {
      return '请输入密码';
    }
    final result = validate(password);
    if (!result.isValid) {
      return result.errors.first;
    }
    return null;
  }
}

/// 确认密码验证器
class ConfirmPasswordValidator {
  /// 验证确认密码是否与原密码一致
  static String? validate(String? confirmPassword, String password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return '请确认密码';
    }
    if (confirmPassword != password) {
      return '两次输入的密码不一致';
    }
    return null;
  }
}

/// 邮箱验证器
class EmailValidator {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// 验证邮箱格式
  static bool isValid(String email) {
    return _emailRegExp.hasMatch(email);
  }

  /// 获取邮箱错误信息（用于表单验证）
  static String? getErrorMessage(String? email) {
    if (email == null || email.isEmpty) {
      return '请输入邮箱地址';
    }
    if (!isValid(email)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }
}

/// 手机号验证器
/// 支持马来西亚手机号格式
class PhoneValidator {
  // 马来西亚手机号格式：+60 开头或 01x 开头
  // 例如：+60123456789, 0123456789, 60123456789
  static final RegExp _phoneRegExp = RegExp(
    r'^(\+?60|0)1[0-9]{8,9}$',
  );

  /// 验证手机号格式
  static bool isValid(String phone) {
    // 移除空格和横线
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    return _phoneRegExp.hasMatch(cleanPhone);
  }

  /// 标准化手机号（去除空格和横线）
  static String normalize(String phone) {
    return phone.replaceAll(RegExp(r'[\s-]'), '');
  }

  /// 获取手机号错误信息（用于表单验证）
  static String? getErrorMessage(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '请输入手机号码';
    }
    if (!isValid(phone)) {
      return '请输入有效的手机号码（马来西亚格式）';
    }
    return null;
  }
}

/// 姓名验证器
class NameValidator {
  static const int minLength = 2;
  static const int maxLength = 50;

  /// 验证姓名
  static bool isValid(String name) {
    final trimmed = name.trim();
    return trimmed.length >= minLength && trimmed.length <= maxLength;
  }

  /// 获取姓名错误信息（用于表单验证）
  static String? getErrorMessage(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '请输入姓名';
    }
    if (name.trim().length < minLength) {
      return '姓名至少需要 $minLength 个字符';
    }
    if (name.trim().length > maxLength) {
      return '姓名不能超过 $maxLength 个字符';
    }
    return null;
  }
}
