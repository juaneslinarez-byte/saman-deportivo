import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/modelos.dart';
import 'resena_repository.dart';

/// Reseñas en Cloud Firestore, colección `resenas`.
class ResenaRepositoryFirebase implements ResenaRepository {
  ResenaRepositoryFirebase({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _resenas =>
      _db.collection('resenas');

  @override
  Future<void> guardar({
    required Estudiante estudiante,
    required String idDeporte,
    required int calificacion,
    required String comentario,
  }) async {
    // Solo reseña quien se inscribió alguna vez (activa o cancelada). Las
    // reglas de Firestore lo vuelven a comprobar.
    final id = Inscripcion.idPara(estudiante.id, idDeporte);
    final inscripcion = await _db.collection('inscripciones').doc(id).get();
    if (!inscripcion.exists) {
      throw Exception(
        'Solo puedes reseñar disciplinas en las que te inscribiste.',
      );
    }

    final anterior = await _resenas.doc(id).get();
    final resena = Resena(
      idDeporte: idDeporte,
      idEstudiante: estudiante.id,
      nombreEstudiante: estudiante.nombreCompleto,
      calificacion: calificacion,
      comentario: comentario.trim(),
      fecha: DateTime.now(),
      editada: anterior.exists,
    );
    await _resenas.doc(id).set(resena.toMap());
  }

  @override
  Future<void> eliminar(Resena resena) => _resenas.doc(resena.id).delete();

  @override
  Stream<List<Resena>> observarPorDeporte(String idDeporte) {
    return _resenas.where('idDeporte', isEqualTo: idDeporte).snapshots().map((
      snapshot,
    ) {
      final lista = snapshot.docs
          .map((doc) => Resena.fromMap(doc.data()))
          .toList();
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  @override
  Stream<Resena?> observarMia(String idEstudiante, String idDeporte) {
    return _resenas.doc(Resena.idPara(idEstudiante, idDeporte)).snapshots().map(
      (doc) {
        final datos = doc.data();
        return datos == null ? null : Resena.fromMap(datos);
      },
    );
  }
}
