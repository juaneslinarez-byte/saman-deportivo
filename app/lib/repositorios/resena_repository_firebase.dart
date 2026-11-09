import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/inscripcion.dart';
import '../modelos/resena.dart';
import 'resena_repository.dart';

class ResenaRepositoryFirebase implements ResenaRepository {
  final FirebaseFirestore _firestore;

  ResenaRepositoryFirebase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  get _resenasRef => _firestore.collection('resenas');
  get _inscripcionesRef => _firestore.collection('inscripciones');
  get _usuariosRef => _firestore.collection('usuarios');

  @override
  Future<void> guardar(
    String idEstudiante,
    String idDeporte,
    int calificacion,
    String comentario,
  ) async {
    final idInscripcion = Inscripcion.idPara(idEstudiante, idDeporte);
    final docInscripcion = await _inscripcionesRef.doc(idInscripcion).get();

    if (!docInscripcion.exists) {
      throw Exception('Solo puedes reseñar disciplinas en las que te inscribiste');
    }

    final docUsuario = await _usuariosRef.doc(idEstudiante).get();
    String nombreEstudiante = '';
    if (docUsuario.exists && docUsuario.data() != null) {
      final data = docUsuario.data() as Map<String, dynamic>;
      final nombre = data['nombre'] as String? ?? '';
      final apellido = data['apellido'] as String? ?? '';
      nombreEstudiante = '$nombre $apellido'.trim();
    }

    final idResena = '${idEstudiante}_$idDeporte';
    final docResena = await _resenasRef.doc(idResena).get();
    final editada = docResena.exists;

    final resena = Resena(
      idDeporte: idDeporte,
      idEstudiante: idEstudiante,
      nombreEstudiante: nombreEstudiante,
      calificacion: calificacion,
      comentario: comentario,
      fecha: DateTime.now(),
      editada: editada,
    );

    await _resenasRef.doc(idResena).set(resena.toMap());
  }

  @override
  Future<void> eliminar(Resena resena) async {
    await _resenasRef.doc(resena.id).delete();
  }

  @override
  Stream<List<Resena>> observarPorDeporte(String idDeporte) {
    return _resenasRef
        .where('idDeporte', isEqualTo: idDeporte)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      final lista = snapshot.docs
          .map((doc) => Resena.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  @override
  Stream<Resena?> observarMia(String idEstudiante, String idDeporte) {
    final idResena = '${idEstudiante}_$idDeporte';
    return _resenasRef.doc(idResena).snapshots().map((DocumentSnapshot doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Resena.fromMap(doc.data() as Map<String, dynamic>);
    });
  }
}
