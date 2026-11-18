import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/modelos.dart';
import 'reserva_repository.dart';

/// Reservas en Cloud Firestore (colección `reservas`). Cada cambio de
/// estado que ocupa o libera lugares mueve el cupo del evento en la misma
/// transacción, igual que las inscripciones con los deportes.
class ReservaRepositoryFirebase implements ReservaRepository {
  ReservaRepositoryFirebase({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reservas =>
      _db.collection('reservas');

  DocumentReference<Map<String, dynamic>> _evento(String id) =>
      _db.collection('eventos').doc(id);

  @override
  Future<Reserva> reservar({
    required Estudiante estudiante,
    required Evento evento,
    required int personas,
    required String referencia,
  }) async {
    final refEvento = _evento(evento.id);
    final refReserva = _reservas.doc(Reserva.idPara(estudiante.id, evento.id));

    return _db.runTransaction((transaccion) async {
      final docEvento = await transaccion.get(refEvento);
      final datosEvento = docEvento.data();
      if (datosEvento == null) throw Exception('El evento ya no existe.');
      final actual = Evento.fromMap(docEvento.id, datosEvento);

      final ahora = DateTime.now();
      if (actual.estaCancelado) throw Exception('El evento fue cancelado.');
      if (actual.yaEmpezo(ahora)) {
        throw Exception('El evento ya empezó: no se puede reservar.');
      }
      if (personas < 1 || personas > actual.maxPorReserva) {
        throw Exception(
          'Puedes reservar de 1 a ${actual.maxPorReserva} personas.',
        );
      }
      if (actual.cuposDisponibles < personas) {
        throw Exception(
          actual.hayCupo
              ? 'Solo quedan ${actual.cuposDisponibles} cupos.'
              : 'No quedan cupos en este evento.',
        );
      }

      final docReserva = await transaccion.get(refReserva);
      final anterior = docReserva.data();
      if (anterior != null &&
          Reserva.fromMap(docReserva.id, anterior).vigente) {
        throw Exception('Ya tienes una reserva en este evento.');
      }

      final reserva = Reserva(
        id: refReserva.id,
        idEvento: actual.id,
        idEstudiante: estudiante.id,
        nombreEstudiante: estudiante.nombreCompleto,
        carnetEstudiante: estudiante.carnet,
        tituloEvento: actual.titulo,
        inicioEvento: actual.inicio,
        personas: personas,
        monto: actual.monto * personas,
        referencia: referencia,
        fecha: ahora,
      );
      transaccion.set(refReserva, reserva.toMap());
      transaccion.update(refEvento, {
        'cuposDisponibles': actual.cuposDisponibles - personas,
      });
      return reserva;
    });
  }

  @override
  Future<void> cancelar(Reserva reserva) => _liberar(
    reserva,
    EstadoReserva.cancelada,
    validarEvento: (evento) {
      if (evento.yaEmpezo(DateTime.now())) {
        throw Exception(
          'El evento ya empezó: la reserva no se puede cancelar.',
        );
      }
    },
  );

  @override
  Future<void> rechazar(Reserva reserva) =>
      _liberar(reserva, EstadoReserva.rechazada, soloEnRevision: true);

  @override
  Future<void> aprobar(Reserva reserva) async {
    final ref = _reservas.doc(reserva.id);
    await _db.runTransaction((transaccion) async {
      final doc = await transaccion.get(ref);
      final datos = doc.data();
      if (datos == null) throw Exception('La reserva ya no existe.');
      if (datos['estado'] != EstadoReserva.enRevision.name) {
        throw Exception('Esta reserva ya fue revisada.');
      }
      transaccion.update(ref, {'estado': EstadoReserva.aprobada.name});
    });
  }

  /// Pasa la reserva a [nuevo] y devuelve sus lugares al evento.
  Future<void> _liberar(
    Reserva reserva,
    EstadoReserva nuevo, {
    bool soloEnRevision = false,
    void Function(Evento evento)? validarEvento,
  }) async {
    final refReserva = _reservas.doc(reserva.id);
    final refEvento = _evento(reserva.idEvento);
    await _db.runTransaction((transaccion) async {
      final doc = await transaccion.get(refReserva);
      final datos = doc.data();
      if (datos == null) throw Exception('La reserva ya no existe.');
      final actual = Reserva.fromMap(doc.id, datos);
      if (soloEnRevision && actual.estado != EstadoReserva.enRevision) {
        throw Exception('Esta reserva ya fue revisada.');
      }
      if (!actual.vigente) throw Exception('Esta reserva ya no está vigente.');

      final docEvento = await transaccion.get(refEvento);
      final datosEvento = docEvento.data();
      if (datosEvento == null) throw Exception('El evento ya no existe.');
      final evento = Evento.fromMap(docEvento.id, datosEvento);
      validarEvento?.call(evento);

      transaccion.update(refReserva, {'estado': nuevo.name});
      transaccion.update(refEvento, {
        'cuposDisponibles': evento.cuposDisponibles + actual.personas,
      });
    });
  }

  /// Las reglas solo dejan al estudiante leer las suyas, por eso el filtro
  /// por idEstudiante es obligatorio. Del evento más próximo al más lejano.
  @override
  Stream<List<Reserva>> observarPorEstudiante(String idEstudiante) => _reservas
      .where('idEstudiante', isEqualTo: idEstudiante)
      .snapshots()
      .map(_lista);

  @override
  Stream<List<Reserva>> observarPorEvento(String idEvento) =>
      _reservas.where('idEvento', isEqualTo: idEvento).snapshots().map(_lista);

  @override
  Stream<List<Reserva>> observarEnRevision() => _reservas
      .where('estado', isEqualTo: EstadoReserva.enRevision.name)
      .snapshots()
      .map(_lista);

  List<Reserva> _lista(QuerySnapshot<Map<String, dynamic>> consulta) {
    final lista = [
      for (final doc in consulta.docs) Reserva.fromMap(doc.id, doc.data()),
    ];
    lista.sort((a, b) => a.fecha.compareTo(b.fecha));
    return lista;
  }
}
