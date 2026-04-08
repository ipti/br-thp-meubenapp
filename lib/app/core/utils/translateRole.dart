class TranslateRole {
  static String translateRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'USER':
        return 'Usuário';
      case 'REAPPLICATORS':
        return 'Reaplicador';
      case 'COORDINATORS':
        return 'Coordenador';
      default:
        return role;
    }
  }
}
