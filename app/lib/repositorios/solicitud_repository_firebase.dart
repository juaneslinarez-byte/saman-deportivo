import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/modelos.dart';
import 'solicitud_repository.dart';

/// Solicitudes en Cloud Firestore (colección `solicitudes`).
class SolicitudRepositoryFirebase implements SolicitudRepository {
  SolicitudRepositoryFirebase({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _solicitudes =>
      _db.collection('solicitudes');

  @override
  Stream<List<Solicitud>> observarPorEntrenador(String idEntrenador) =>
      _solicitudes
          .where('idEntrenador', isEqualTo: idEntrenador)
          .snapshots()
          .map((consulta) {
            final lista = _leer(consulta);
            lista.sort((a, b) => b.fecha.compareTo(a.fecha));
            return lista;
          });

  @override
  Stream<List<Solicitud>> observarPendientes() => _solicitudes
      .where('estado', isEqualTo: EstadoSolicitud.pendiente.name)
      .snapshots()
      .map((consulta) {
        final lista = _leer(consulta);
        lista.sort((a, b) => a.fecha.compareTo(b.fecha));
        return lista;
      });

  @override
  Future<void> solicitar({
    required Entrenador entrenador,
    required Deporte deporte,
    String mensaje = '',
  }) async {
    if (deporte.tieneAlEntrenador(entrenador.id)) {
      throw Exception('Ya diriges esta disciplina.');
    }
    final ref = _solicitudes.doc(Solicitud.idPara(entrenador.id, deporte.id));
    final anterior = await ref.get();
    final datos = anterior.data();
    if (datos != null && datos['estado'] == EstadoSolicitud.pendiente.name) {
      throw Exception('Ya enviaste una solicitud para esta disciplina.');
    }
    final solicitud = Solicitud(
      idEntrenador: entrenador.id,
      nombreEntrenador: entrenador.nombreCompleto,
      idDeporte: deporte.id,
      nombreDeporte: deporte.nombre,
      fecha: DateTime.now(),
      mensaje: mensaje.trim(),
    );
    await ref.set(solicitud.toMap());
  }

  /// Lee la disciplina en una transacción para agregar al entrenador sin
  /// perder a los que se hayan asignado mientras tanto.
  @override
  Future<void> aprobar(Solicitud solicitud) async {
    final refSolicitud = _solicitudes.doc(solicitud.id);
    final refDeporte = _db.collection('deportes').doc(solicitud.idDeporte);
    await _db.runTransaction((transaccion) async {
      final docSolicitud = await transaccion.get(refSolicitud);
      final docDeporte = await transaccion.get(refDeporte);
      final datosSolicitud = docSolicitud.data();
      final datosDeporte = docDeporte.data();
      if (datosSolicitud == null ||
          datosSolicitud['estado'] != EstadoSolicitud.pendiente.name) {
        throw Exception('Esta solicitud ya fue revisada.');
      }
      if (datosDeporte == null) {
        throw Exception('La disciplina ya no existe.');
      }
      final deporte = Deporte.fromMap(docDeporte.id, datosDeporte);
      final entrenadores = {
        ...deporte.idsEntrenadores,
        solicitud.idEntrenador,
      }.toList();
      transaccion.update(refDeporte, {
        'idsEntrenadores': entrenadores,
        'idEntrenador': entrenadores.first,
      });
      transaccion.update(refSolicitud, {
        'estado': EstadoSolicitud.aprobada.name,
      });
    });
  }

  @override
  Future<void> rechazar(Solicitud solicitud) => _solicitudes
      .doc(solicitud.id)
      .update({'estado': EstadoSolicitud.rechazada.name});

  List<Solicitud> _leer(QuerySnapshot<Map<String, dynamic>> consulta) => [
    for (final doc in consulta.docs) Solicitud.fromMap(doc.data()),
  ];
}
