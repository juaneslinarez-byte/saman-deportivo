import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/modelos.dart';
import 'pago_repository.dart';

/// Pagos de solvencia en Cloud Firestore.
///
/// La pasarela todavía es simulada: [pagar] genera una referencia como la
/// que devolvería PayPal y guarda el pago como pendiente. El administrador
/// lo aprueba o lo rechaza, y al aprobarlo el estudiante queda solvente en
/// la misma operación (RF-ADM-05, RF-SIS-07).
class PagoRepositoryFirebase implements PagoRepository {
  PagoRepositoryFirebase({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Random _azar = Random.secure();

  CollectionReference<Map<String, dynamic>> get _pagos =>
      _db.collection('pagos');

  @override
  Future<Pago> pagar({
    required Estudiante estudiante,
    required double monto,
  }) async {
    if (monto <= 0) {
      throw Exception('El monto del pago no es válido.');
    }
    // Simula el tiempo que tarda la pasarela en responder.
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final referencia = _referencia();
    final ref = _pagos.doc();
    final pago = Pago(
      id: ref.id,
      idEstudiante: estudiante.id,
      monto: monto,
      fecha: DateTime.now(),
      referencia: referencia,
    );
    await ref.set(pago.toMap());
    return pago;
  }

  /// Referencia de 12 caracteres, como «PAYPAL-7KQ2M9XA4T1B».
  String _referencia() {
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final codigo = List.generate(
      12,
      (_) => caracteres[_azar.nextInt(caracteres.length)],
    ).join();
    return 'PAYPAL-$codigo';
  }

  /// Las reglas solo dejan al estudiante leer los suyos, por eso el filtro
  /// por idEstudiante es obligatorio. Del más reciente al más antiguo.
  @override
  Stream<List<Pago>> observarPorEstudiante(String idEstudiante) => _pagos
      .where('idEstudiante', isEqualTo: idEstudiante)
      .snapshots()
      .map(_aListaOrdenada);

  @override
  Stream<List<Pago>> observarPendientes() => _pagos
      .where('estado', isEqualTo: EstadoPago.pendiente.name)
      .snapshots()
      .map(_aListaOrdenada);

  /// Cambia el pago a aprobado y marca al estudiante como solvente en la
  /// misma operación. Si otro administrador ya lo revisó, no hace nada.
  @override
  Future<void> aprobar(Pago pago) async {
    final refPago = _pagos.doc(pago.id);
    final refUsuario = _db.collection('usuarios').doc(pago.idEstudiante);
    await _db.runTransaction((transaccion) async {
      final doc = await transaccion.get(refPago);
      final datos = doc.data();
      if (datos == null) throw Exception('El pago ya no existe.');
      if (datos['estado'] != EstadoPago.pendiente.name) {
        throw Exception('Este pago ya fue revisado.');
      }
      transaccion.update(refPago, {'estado': EstadoPago.aprobado.name});
      transaccion.update(refUsuario, {'solvente': true});
    });
  }

  @override
  Future<void> rechazar(Pago pago) async {
    final refPago = _pagos.doc(pago.id);
    await _db.runTransaction((transaccion) async {
      final doc = await transaccion.get(refPago);
      final datos = doc.data();
      if (datos == null) throw Exception('El pago ya no existe.');
      if (datos['estado'] != EstadoPago.pendiente.name) {
        throw Exception('Este pago ya fue revisado.');
      }
      transaccion.update(refPago, {'estado': EstadoPago.rechazado.name});
    });
  }

  List<Pago> _aListaOrdenada(QuerySnapshot<Map<String, dynamic>> consulta) {
    final lista = [
      for (final doc in consulta.docs) Pago.fromMap(doc.id, doc.data()),
    ];
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }
}
