import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

import 'asistencia_repository.dart';

/// Implementación de [AsistenciaRepository] con Cloud Firestore.
///
/// Cada registro se guarda en `asistencias/{idInscripcion_idSesion_AAAAMMDD}`
/// (ver [Asistencia.idPara]). La fecha se guarda siempre a la medianoche de
/// ese día, así una sesión se busca por igualdad y no hace falta un índice
/// compuesto en Firestore.
class AsistenciaRepositoryFirebase implements AsistenciaRepository {
  AsistenciaRepositoryFirebase({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _asistencias =>
      _firestore.collection('asistencias');

  @override
  Future<void> registrar(List<Asistencia> asistencias) async {
    if (asistencias.isEmpty) return;

    // Toda la sesión en una sola operación (RF-ENT-03): o se guardan todos
    // los registros o ninguno. set() con el id fijo corrige la asistencia
    // del mismo día en lugar de duplicarla.
    final lote = _firestore.batch();
    for (final asistencia in asistencias) {
      final fecha = _soloDia(asistencia.fecha);
      final id = Asistencia.idPara(
        asistencia.idInscripcion,
        asistencia.idSesion,
        fecha,
      );
      final registro = Asistencia(
        id: id,
        idInscripcion: asistencia.idInscripcion,
        idEstudiante: asistencia.idEstudiante,
        idDeporte: asistencia.idDeporte,
        idSesion: asistencia.idSesion,
        fecha: fecha,
        presente: asistencia.presente,
      );
      lote.set(_asistencias.doc(id), registro.toMap());
    }
    await lote.commit();
  }

  @override
  Stream<List<Asistencia>> observarPorSesion(String idSesion, DateTime fecha) {
    final consulta = _asistencias
        .where('idSesion', isEqualTo: idSesion)
        .where('fecha', isEqualTo: Timestamp.fromDate(_soloDia(fecha)));
    return _observar(consulta);
  }

  /// Historial del entrenador (RF-ENT-04). Sin orderBy para no requerir un
  /// índice; el orden lo decide el ViewModel.
  @override
  Stream<List<Asistencia>> observarPorDeporte(String idDeporte) =>
      _observar(_asistencias.where('idDeporte', isEqualTo: idDeporte));

  /// Historial del estudiante (RF-EST-06). Las reglas solo le dejan leer sus
  /// propios registros, y este filtro coincide con esa condición.
  @override
  Stream<List<Asistencia>> observarPorEstudiante(String idEstudiante) =>
      _observar(_asistencias.where('idEstudiante', isEqualTo: idEstudiante));

  Stream<List<Asistencia>> _observar(Query<Map<String, dynamic>> consulta) =>
      consulta.snapshots().map(_aLista);

  List<Asistencia> _aLista(QuerySnapshot<Map<String, dynamic>> resultado) {
    return [
      for (final documento in resultado.docs)
        Asistencia.fromMap(documento.id, documento.data()),
    ];
  }

  /// La fecha a la medianoche de ese día, igual al guardar y al buscar.
  DateTime _soloDia(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);
}
