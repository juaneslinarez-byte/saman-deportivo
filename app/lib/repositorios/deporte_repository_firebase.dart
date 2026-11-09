import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/modelos.dart';
import 'deporte_repository.dart';

/// Deportes y sesiones en Cloud Firestore.
class DeporteRepositoryFirebase implements DeporteRepository {
  DeporteRepositoryFirebase({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<Deporte>> observarDeportes({bool soloVisibles = true}) {
    Query query = _db.collection('deportes');
    if (soloVisibles) {
      query = query.where('visible', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Deporte.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  @override
  Future<Deporte?> obtener(String id) async {
    final doc = await _db.collection('deportes').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Deporte.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Una disciplina puede tener varios entrenadores, y las creadas antes
  /// solo guardan `idEntrenador`. Por eso se filtra en la app con
  /// [Deporte.tieneAlEntrenador], que entiende los dos formatos; el
  /// catálogo es pequeño y el entrenador ya puede leerlo completo.
  @override
  Stream<List<Deporte>> observarPorEntrenador(String idEntrenador) {
    return _db.collection('deportes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Deporte.fromMap(doc.id, doc.data()))
          .where((deporte) => deporte.tieneAlEntrenador(idEntrenador))
          .toList();
    });
  }

  @override
  Stream<List<Sesion>> observarSesiones(String idDeporte) {
    return _db
        .collection('sesiones')
        .where('idDeporte', isEqualTo: idDeporte)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Sesion.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Future<String> crear(Deporte deporte) async {
    final ref = await _db.collection('deportes').add(deporte.toMap());
    return ref.id;
  }

  @override
  Future<void> actualizar(Deporte deporte) async {
    await _db.collection('deportes').doc(deporte.id).update(deporte.toMap());
  }

  /// Solo elimina deportes sin inscritos activos (RF-SIS-09), igual que el
  /// repositorio falso. Borra también sus sesiones en la misma operación.
  @override
  Future<void> eliminar(String id) async {
    final deporte = await obtener(id);
    if (deporte == null) {
      throw StateError('No existe el deporte $id');
    }
    if (deporte.inscritos > 0) {
      throw StateError('No se puede eliminar un deporte con inscritos');
    }
    final sesiones = await _db
        .collection('sesiones')
        .where('idDeporte', isEqualTo: id)
        .get();
    final lote = _db.batch();
    for (final sesion in sesiones.docs) {
      lote.delete(sesion.reference);
    }
    lote.delete(_db.collection('deportes').doc(id));
    await lote.commit();
  }

  @override
  Future<String> crearSesion(Sesion sesion) async {
    final ref = await _db.collection('sesiones').add(sesion.toMap());
    return ref.id;
  }

  @override
  Future<void> actualizarSesion(Sesion sesion) async {
    await _db.collection('sesiones').doc(sesion.id).update(sesion.toMap());
  }

  @override
  Future<void> eliminarSesion(String idSesion) async {
    await _db.collection('sesiones').doc(idSesion).delete();
  }
}
