enum AreaOfActivity {
  noSpecification,
  entrepreneurship,
  health,
  education;

  static AreaOfActivity fromString(String? value) {
    return switch (value) {
      'NO_SPECIFICATION' => AreaOfActivity.noSpecification,
      'ENTREPRENEURSHIP' => AreaOfActivity.entrepreneurship,
      'HEALTH' => AreaOfActivity.health,
      'EDUCATION' => AreaOfActivity.education,
      _ => AreaOfActivity.noSpecification,
    };
  }

  String get label => switch (this) {
    AreaOfActivity.noSpecification => 'Sem especificação',
    AreaOfActivity.entrepreneurship => 'Empreendedorismo',
    AreaOfActivity.health => 'Saúde',
    AreaOfActivity.education => 'Educação',
  };
}
