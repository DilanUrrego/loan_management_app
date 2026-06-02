class FormValidators {
  static String? requiredField(String? value, [String message = 'Campo requerido']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Correo requerido';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Formato de correo inválido';
    }
    return null;
  }

  static String? passwordValidator(String? value, [int minLength = 6]) {
    if (value == null || value.trim().isEmpty) {
      return 'Contraseña requerida';
    }
    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }
    return null;
  }

  static String? matchValidator(String? value, String target, [String message = 'Las contraseñas no coinciden']) {
    if (value != target) {
      return message;
    }
    return null;
  }
}
