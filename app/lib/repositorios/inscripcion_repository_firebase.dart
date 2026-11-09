import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/modelos.dart';
import 'inscripcion_repository.dart';

/// Inscripciones en Cloud Firestore, con control estricto de cupos (RNF-07).
///
/// Inscribir y cancelar son transacciones: la inscripción y el cupo del
/// deporte cambian juntos o no cambia ninguno. Las reglas de seguridad lo
/// exigen, así dos estudiantes nunca ocupan el mismo último cupo.
class InscripcionRepositoryFirebase implements InscripcionRepository {
  InscripcionRepositoryFirebase({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _inscripciones =>
      _db.collection('inscripciones');

  CollectionReference<Map<String, dynamic>> get _deportes =>
      _db.collection('deportes');

  /// Mismas reglas y mismo orden que el repositorio falso: solvencia,
  /// inscripción duplicada y cupo (RF-SIS-01, RF-SIS-02, RF-SIS-04).
  @override
  Future<Inscripcion> inscribir(Estudiante estudiante, Deporte deporte) async {
    if (!estudiante.solvente) {
      throw const InscripcionRechazada(MotivoRechazo.noSolvente);
    }

    final id = Inscripcion.idPara(estudiante.id, deporte.id);
    final refInscripcion = _inscripciones.doc(id);
    final refDeporte = _deportes.doc(deporte.id);

    // En la web, una excepción lanzada dentro de la transacción llega
    // envuelta y pierde su tipo, así que el motivo se guarda aparte y se
    // lanza al terminar.
    MotivoRechazo? rechazo;
    final resultado = await _db.runTransaction<Inscripcion?>((
      transaccion,
    ) async {
      // En una transacción se lee todo antes de escribir.
      final docDeporte = await transaccion.get(refDeporte);
      final docInscripcion = await transaccion.get(refInscripcion);

      final datosDeporte = docDeporte.data();
      if (datosDeporte == null) {
        throw StateError('No existe el deporte ${deporte.id}');
      }
      final cupos = Deporte.fromMap(docDeporte.id, datosDeporte);

      final anterior = docInscripcion.data() == null
          ? null
          : Inscripcion.fromMap(id, docInscripcion.data()!);
      if (anterior != null && anterior.estaActiva) {
        rechazo = MotivoRechazo.yaInscrito;
        return null;
      }
      if (!cupos.hayCupo) {
        rechazo = MotivoRechazo.sinCupo;
        return null;
      }

      final ahora = DateTime.now();
      if (anterior == null) {
        // El nombre y el carnet se copian para la nómina del entrenador; las
        // reglas comprueban que coincidan con el perfil.
        final nueva = Inscripcion(
          id: id,
          idEstudiante: estudiante.id,
          nombreEstudiante: estudiante.nombreCompleto,
          carnetEstudiante: estudiante.carnet,
          idDeporte: deporte.id,
          fecha: ahora,
        );
        transaccion.set(refInscripcion, nueva.toMap());
      } else {
        // Volver a inscribirse: se reactiva la misma inscripción y solo
        // cambian el estado y la fecha, que es lo que permiten las reglas.
        transaccion.update(refInscripcion, {
          'estado': EstadoInscripcion.activa.name,
          'fecha': ahora,
        });
      }
      transaccion.update(refDeporte, {
        'cuposDisponibles': cupos.cuposDisponibles - 1,
      });

      return Inscripcion(
        id: id,
        idEstudiante: estudiante.id,
        nombreEstudiante:
            anterior?.nombreEstudiante ?? estudiante.nombreCompleto,
        carnetEstudiante: anterior?.carnetEstudiante ?? estudiante.carnet,
        idDeporte: deporte.id,
        fecha: ahora,
      );
    });
    final motivo = rechazo;
    if (motivo != null) throw InscripcionRechazada(motivo);
    return resultado!;
  }

  /// Cancela y devuelve el cupo en la misma transacción. La inscripción no
  /// se borra: queda en el historial como cancelada.
  @override
  Future<void> cancelar(Inscripcion inscripcion) async {
    final refInscripcion = _inscripciones.doc(inscripcion.id);
    final refDeporte = _deportes.doc(inscripcion.idDeporte);

    await _db.runTransaction((transaccion) async {
      final docInscripcion = await transaccion.get(refInscripcion);
      final docDeporte = await transaccion.get(refDeporte);

      final datos = docInscripcion.data();
      if (datos == null) {
        throw StateError('No existe la inscripción ${inscripcion.id}');
      }
      final guardada = Inscripcion.fromMap(inscripcion.id, datos);
      // Ya estaba cancelada (por ejemplo, desde otra pestaña): no hay nada
      // que hacer y el cupo no se devuelve dos veces.
      if (!guardada.estaActiva) return;

      final datosDeporte = docDeporte.data();
      if (datosDeporte == null) {
        throw StateError('No existe el deporte ${inscripcion.idDeporte}');
      }
      final deporte = Deporte.fromMap(docDeporte.id, datosDeporte);

      transaccion.update(refInscripcion, {
        'estado': EstadoInscripcion.cancelada.name,
      });
      transaccion.update(refDeporte, {
        'cuposDisponibles': deporte.cuposDisponibles + 1,
      });
    });
  }

  /// Las reglas solo dejan al estudiante consultar las suyas, por eso el
  /// filtro por idEstudiante es obligatorio.
  @override
  Stream<List<Inscripcion>> observarPorEstudiante(String idEstudiante) =>
      _inscripciones
          .where('idEstudiante', isEqualTo: idEstudiante)
          .snapshots()
          .map(_aLista);

  /// Solo las activas: es la nómina del entrenador (RF-ENT-02).
  @override
  Stream<List<Inscripcion>> observarPorDeporte(String idDeporte) =>
      _inscripciones
          .where('idDeporte', isEqualTo: idDeporte)
          .where('estado', isEqualTo: EstadoInscripcion.activa.name)
          .snapshots()
          .map(_aLista);

  List<Inscripcion> _aLista(QuerySnapshot<Map<String, dynamic>> consulta) => [
    for (final doc in consulta.docs) Inscripcion.fromMap(doc.id, doc.data()),
  ];
}
