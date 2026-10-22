import 'package:saman_deportivo/modelos/modelos.dart';

/// Deportes del catálogo y sus sesiones semanales.
abstract class DeporteRepository {
  /// Emite la lista de deportes cada vez que cambia, por ejemplo cuando
  /// alguien se inscribe y baja un cupo (RF-SIS-03).
  Stream<List<Deporte>> observarDeportes({bool soloVisibles = true});

  Future<Deporte?> obtener(String id);

  Stream<List<Sesion>> observarSesiones(String idDeporte);

  /// Crea el deporte y devuelve su id (RF-ADM-01).
  Future<String> crear(Deporte deporte);

  Future<void> actualizar(Deporte deporte);

  /// Solo elimina deportes sin inscritos activos (RF-SIS-09).
  Future<void> eliminar(String id);
}
