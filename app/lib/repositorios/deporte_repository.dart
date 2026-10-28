import 'package:saman_deportivo/modelos/modelos.dart';

/// Deportes del catálogo y sus sesiones semanales.
abstract class DeporteRepository {
  /// Emite la lista de deportes cada vez que cambia, por ejemplo cuando
  /// alguien se inscribe y baja un cupo (RF-SIS-03).
  Stream<List<Deporte>> observarDeportes({bool soloVisibles = true});

  Future<Deporte?> obtener(String id);

  /// Deportes asignados a un entrenador, para su nómina y su asistencia
  /// (RF-ENT-01).
  Stream<List<Deporte>> observarPorEntrenador(String idEntrenador);

  Stream<List<Sesion>> observarSesiones(String idDeporte);

  /// Agrega una sesión al horario de un deporte y devuelve su id (RF-ADM-03).
  Future<String> crearSesion(Sesion sesion);

  Future<void> actualizarSesion(Sesion sesion);

  Future<void> eliminarSesion(String idSesion);

  /// Crea el deporte y devuelve su id (RF-ADM-01).
  Future<String> crear(Deporte deporte);

  Future<void> actualizar(Deporte deporte);

  /// Solo elimina deportes sin inscritos activos (RF-SIS-09).
  Future<void> eliminar(String id);
}
