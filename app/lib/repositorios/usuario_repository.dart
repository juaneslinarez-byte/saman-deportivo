import 'package:saman_deportivo/modelos/modelos.dart';

/// Perfiles de los usuarios. Cada perfil usa el mismo id que su cuenta en
/// [AuthRepository] y se convierte en la subclase correcta con
/// [Persona.fromMap].
abstract class UsuarioRepository {
  /// Devuelve el perfil, o null si todavía no existe.
  Future<Persona?> obtener(String id);

  /// Emite el perfil cada vez que cambia.
  Stream<Persona?> observar(String id);

  /// Guarda el perfil de un usuario recién registrado.
  Future<void> crear(Persona persona);

  /// Guarda los cambios del perfil (RF-EST-07, RF-ENT-07, RF-ADM-09).
  ///
  /// No cambia el actor ni la solvencia: esos campos solo los modifica el
  /// administrador.
  Future<void> actualizarPerfil(Persona persona);

  /// Lista los usuarios, opcionalmente de un solo tipo (RF-ADM-08).
  Future<List<Persona>> listar({Actor? actor});

  /// Guarda el perfil completo, incluidos el actor, la solvencia y si está
  /// habilitado. Solo lo usa el administrador (RF-ADM-08, RF-SIS-07), y las
  /// reglas de seguridad lo rechazan para cualquier otro usuario.
  ///
  /// Sirve para habilitar o deshabilitar una cuenta, marcar la solvencia y
  /// convertir en entrenador a alguien que se registró como estudiante:
  /// se pasa un [Entrenador] con el mismo id y el perfil se reemplaza.
  Future<void> actualizarComoAdministrador(Persona persona);
}
