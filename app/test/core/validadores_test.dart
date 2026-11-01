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

  group('Validadores de datos personales', () {
    test('nombrePropio acepta nombres con tildes, ñ, apóstrofo y guion', () {
      expect(Validadores.nombrePropio('José'), isNull);
      expect(Validadores.nombrePropio('María José'), isNull);
      expect(Validadores.nombrePropio('Núñez-D\'Ángelo'), isNull);
    });

    test('nombrePropio rechaza números, vacíos y una sola letra', () {
      expect(Validadores.nombrePropio('12345678'), 'Solo se permiten letras');
      expect(Validadores.nombrePropio('Ana3'), 'Solo se permiten letras');
      expect(Validadores.nombrePropio('   '), isNotNull);
      expect(Validadores.nombrePropio('A'), isNotNull);
    });

    test('cedula acepta de 6 a 9 dígitos con prefijo y separadores', () {
      expect(Validadores.cedula('28123456'), isNull);
      expect(Validadores.cedula('V-28.123.456'), isNull);
      expect(Validadores.cedula('e12345678'), isNull);
    });

    test('cedula rechaza letras y largos fuera de rango', () {
      expect(Validadores.cedula('abc'), isNotNull);
      expect(Validadores.cedula('12345'), isNotNull);
      expect(Validadores.cedula('1234567890'), isNotNull);
      expect(Validadores.cedula(''), isNotNull);
    });

    test('carnet acepta solo números de 8 a 12 dígitos', () {
      expect(Validadores.carnet('20231110245'), isNull);
      expect(Validadores.carnet('2023-111'), isNotNull);
      expect(Validadores.carnet('1234567'), isNotNull);
      expect(Validadores.carnet('carnet'), isNotNull);
    });

    test('textoDescriptivo acepta carreras y cargos, sin números', () {
      expect(Validadores.textoDescriptivo('Ing. de Sistemas'), isNull);
      expect(Validadores.textoDescriptivo('Coordinación de Deportes'), isNull);
      expect(Validadores.textoDescriptivo('asd123'), isNotNull);
      expect(Validadores.textoDescriptivo('..'), isNotNull);
      expect(Validadores.textoDescriptivo('...'), isNotNull);
    });
  });

  test('Validadores.aniosExperiencia acepta enteros entre 0 y 60', () {
    expect(Validadores.aniosExperiencia('0'), isNull);
    expect(Validadores.aniosExperiencia(' 12 '), isNull);
    expect(Validadores.aniosExperiencia('61'), isNotNull);
    expect(Validadores.aniosExperiencia('-1'), isNotNull);
    expect(Validadores.aniosExperiencia('dos'), isNotNull);
    expect(Validadores.aniosExperiencia(''), isNotNull);
  });

  test('Validadores.requerido rechaza textos vacíos o solo con espacios', () {
    expect(Validadores.requerido('Ana'), isNull);
    expect(Validadores.requerido('   '), isNotNull);
    expect(Validadores.requerido(null), isNotNull);
  });
}
