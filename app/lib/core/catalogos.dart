/// Listas cerradas que el usuario elige en lugar de escribir, para que los
/// datos guardados sean siempre válidos y se puedan filtrar.
abstract final class Catalogos {
  /// Carreras de pregrado de la UNIMET, según la página de flujogramas de
  /// pregrado de la universidad (unimet.edu.ve/estudios/flujogramas-pregrado).
  static const List<String> carreras = [
    'Ciencias Administrativas',
    'Comunicación Social y Empresarial',
    'Contaduría Pública',
    'Derecho',
    'Economía Empresarial',
    'Educación, mención Educación Inicial',
    'Educación, mención Educación Integral',
    'Educación, mención Gerencia',
    'Estudios Internacionales, mención Derecho Internacional',
    'Estudios Internacionales, mención Economía Internacional',
    'Estudios Liberales',
    'Idiomas Modernos',
    'Ingeniería Civil',
    'Ingeniería de Producción',
    'Ingeniería de Sistemas',
    'Ingeniería Eléctrica',
    'Ingeniería Mecánica',
    'Ingeniería Química',
    'Matemáticas Industriales',
    'Psicología',
    'TSU en Sistemas Inteligentes',
    'Turismo Sostenible, mención Gestión de la Hospitalidad',
  ];

  /// Disciplinas que puede dirigir un entrenador.
  static const List<String> especialidades = [
    'Ajedrez',
    'Atletismo',
    'Baloncesto',
    'Béisbol',
    'Fútbol',
    'Fútbol sala',
    'Judo',
    'Karate',
    'Natación',
    'Softbol',
    'Taekwondo',
    'Tenis',
    'Tenis de mesa',
    'Voleibol',
  ];

  /// Prefijos de la cédula de identidad: venezolano o extranjero.
  static const List<String> prefijosCedula = ['V', 'E'];
}
