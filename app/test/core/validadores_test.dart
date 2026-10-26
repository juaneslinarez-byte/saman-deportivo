import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/core/validadores.dart';

void main() {
  group('Validadores.correoInstitucional', () {
    test(
      'acepta un correo institucional, sin importar mayúsculas ni espacios',
      () {
        expect(
          Validadores.correoInstitucional('ana.perez@correo.unimet.edu.ve'),
          isNull,
        );
        expect(
          Validadores.correoInstitucional(' Ana.Perez@Correo.Unimet.edu.ve '),
          isNull,
        );
      },
    );

    test('rechaza un correo vacío, de otro dominio o sin usuario', () {
      expect(Validadores.correoInstitucional(''), isNotNull);
      expect(Validadores.correoInstitucional(null), isNotNull);
      expect(
        Validadores.correoInstitucional('ana@gmail.com'),
        'Debe terminar en @correo.unimet.edu.ve',
      );
      expect(
        Validadores.correoInstitucional('@correo.unimet.edu.ve'),
        'El correo no es válido',
      );
      expect(
        Validadores.correoInstitucional('a@b@correo.unimet.edu.ve'),
        'El correo no es válido',
      );
    });
  });

  group('Validadores.contrasena', () {
    test('exige al menos 6 caracteres, como Firebase', () {
      expect(Validadores.contrasena('12345'), isNotNull);
      expect(Validadores.contrasena('123456'), isNull);
      expect(Validadores.contrasena(''), isNotNull);
    });

    test('la confirmación debe coincidir con la contraseña', () {
      expect(Validadores.confirmacion('secreta1', 'secreta1'), isNull);
      expect(
        Validadores.confirmacion('secreta2', 'secreta1'),
        'Las contraseñas no coinciden',
      );
      expect(Validadores.confirmacion('', 'secreta1'), isNotNull);
    });
  });

  test('Validadores.requerido rechaza textos vacíos o solo con espacios', () {
    expect(Validadores.requerido('Ana'), isNull);
    expect(Validadores.requerido('   '), isNotNull);
    expect(Validadores.requerido(null), isNotNull);
  });
}
