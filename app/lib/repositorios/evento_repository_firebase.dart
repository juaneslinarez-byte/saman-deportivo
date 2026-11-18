import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/modelos.dart';
import 'evento_repository.dart';

/// Eventos en Cloud Firestore (colección `eventos`).
class EventoRepositoryFirebase implements EventoRepository {
  EventoRepositoryFirebase({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _eventos =>
      _db.collection('eventos');

  /// Solo se filtra por estado (no hace falta un índice compuesto); los que
  /// ya terminaron se quitan aquí.
  @override
  Stream<List<Evento>> observarProximos() => _eventos
      .where('estado', isEqualTo: EstadoEvento.publicado.name)
      .snapshots()
      .map((consulta) {
        final ahora = DateTime.now();
        return _ordenados(consulta).where((e) => !e.yaPaso(ahora)).toList();
      });

  @override
  Stream<List<Evento>> observarTodos() => _eventos.snapshots().map(_ordenados);

  @override
  Future<String> crear(Evento evento) async {
    final ref = _eventos.doc();
    await ref.set(
      evento
          .copyWith(
            cuposDisponibles: evento.cupo,
            estado: EstadoEvento.publicado,
          )
          .toMap(),
    );
    return ref.id;
  }

  /// Lee el evento en una transacción para recalcular los cupos disponibles
  /// con lo reservado en ese momento, aunque alguien acabe de reservar.
  @override
  Future<void> actualizar(Evento evento) async {
    final ref = _eventos.doc(evento.id);
    await _db.runTransaction((transaccion) async {
      final doc = await transaccion.get(ref);
      final datos = doc.data();
      if (datos == null) throw Exception('El evento ya no existe.');
      final actual = Evento.fromMap(doc.id, datos);
      if (actual.estaCancelado) {
        throw Exception('Un evento cancelado no se puede editar.');
      }
      if (evento.cupo < actual.reservados) {
        throw Exception(
          'Ya hay ${actual.reservados} personas con reserva: el cupo no '
          'puede ser menor.',
        );
      }
      if (evento.maxPorReserva > evento.cupo) {
        throw Exception(
          'Las personas por reserva no pueden ser más que el cupo.',
        );
      }
      final nuevo = evento.copyWith(
        cuposDisponibles: evento.cupo - actual.reservados,
        estado: actual.estado,
      );
      transaccion.set(ref, nuevo.toMap());
    });
  }

  @override
  Future<void> cancelar(Evento evento) async {
    final ref = _eventos.doc(evento.id);
    await _db.runTransaction((transaccion) async {
      final doc = await transaccion.get(ref);
      final datos = doc.data();
      if (datos == null) throw Exception('El evento ya no existe.');
      if (datos['estado'] == EstadoEvento.cancelado.name) {
        throw Exception('El evento ya estaba cancelado.');
      }
      transaccion.update(ref, {'estado': EstadoEvento.cancelado.name});
    });
  }

  @override
  Future<void> eliminar(Evento evento) async {
    final ref = _eventos.doc(evento.id);
    await _db.runTransaction((transaccion) async {
      final doc = await transaccion.get(ref);
      final datos = doc.data();
      if (datos == null) return;
      if (Evento.fromMap(doc.id, datos).reservados > 0) {
        throw Exception(
          'El evento tiene reservas: cancélalo en lugar de eliminarlo.',
        );
      }
      transaccion.delete(ref);
    });
  }

  List<Evento> _ordenados(QuerySnapshot<Map<String, dynamic>> consulta) {
    final lista = [
      for (final doc in consulta.docs) Evento.fromMap(doc.id, doc.data()),
    ];
    lista.sort((a, b) => a.inicio.compareTo(b.inicio));
    return lista;
  }
}
