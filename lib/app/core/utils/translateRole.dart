class TranslateRole {
  static String translateRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'USER':
        return 'Usuário';
      case 'REAPPLICATOR':
      case 'REAPPLICATORS':
        return 'Reaplicador';
      case 'COORDINATOR':
      case 'COORDINATORS':
        return 'Coordenador';
      default:
        return role;
    }
  }
}
