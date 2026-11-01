import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saman_deportivo/modelos/modelos.dart';

import 'usuario_repository.dart';

/// Implementación de [UsuarioRepository] con Cloud Firestore.
///
/// Cada perfil se guarda en `usuarios/{id}`, donde el id es el mismo de la
/// cuenta en Firebase Authentication.
class UsuarioRepositoryFirebase implements UsuarioRepository {
  UsuarioRepositoryFirebase({FirebaseFirestore? firestore})
    : _usuarios = (firestore ?? FirebaseFirestore.instance).collection(
        'usuarios',
      );

  final CollectionReference<Map<String, dynamic>> _usuarios;

  @override
  Future<Persona?> obtener(String id) async {
    final documento = await _usuarios.doc(id).get();
    return _aPersona(documento);
  }

  @override
  Stream<Persona?> observar(String id) =>
      _usuarios.doc(id).snapshots().map(_aPersona);

  @override
  Future<void> crear(Persona persona) =>
      _usuarios.doc(persona.id).set(persona.toMap());

  @override
  Future<void> actualizarPerfil(Persona persona) {
    // El actor y la solvencia solo los cambia el administrador (RF-SIS-07),
    // así que no se envían. update() falla si el perfil no existe.
    final datos = persona.toMap()
      ..remove('actor')
      ..remove('solvente');
    return _usuarios.doc(persona.id).update(datos);
  }

  @override
  Future<void> actualizarComoAdministrador(Persona persona) =>
      // set() reemplaza el documento: al convertir a un estudiante en
      // entrenador no quedan los campos que ya no aplican (carnet, carrera…).
      _usuarios.doc(persona.id).set(persona.toMap());

  @override
  Future<List<Persona>> listar({Actor? actor}) async {
    final consulta = actor == null
        ? _usuarios
        : _usuarios.where('actor', isEqualTo: actor.name);
    final resultado = await consulta.get();
    return resultado.docs
        .map((documento) => Persona.fromMap(documento.id, documento.data()))
        .toList();
  }

  /// Convierte un documento en la subclase de [Persona] que corresponde,
  /// o devuelve null si el documento no existe.
  Persona? _aPersona(DocumentSnapshot<Map<String, dynamic>> documento) {
    final datos = documento.data();
    if (!documento.exists || datos == null) return null;
    return Persona.fromMap(documento.id, datos);
  }
}
