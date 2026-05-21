/// Shared form validators for the authentication screens.
class AuthValidators {
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'El correo es obligatorio';
    }

    if (!email.contains('@')) {
      return 'Ingrese un correo válido';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'La contraseña es obligatoria';
    }

    if (password.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

    return null;
  }
}