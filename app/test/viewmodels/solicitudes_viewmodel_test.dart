import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/viewmodels/solicitudes_admin_viewmodel.dart';
import 'package:saman_deportivo/viewmodels/solicitudes_entrenador_viewmodel.dart';

import '../fakes/fake_deporte_repository.dart';
import '../fakes/fake_solicitud_repository.dart';

void main() {
  const maria = Entrenador(
    id: 't1',
    nombre: 'María',
    apellido: 'Bolívar',
    cedula: 'V-12345678',
    correo: 'maria@correo.unimet.edu.ve',
    especialidad: 'Voleibol',
    aniosExperiencia: 5,
  );
  const voleibol = Deporte(
    id: 'vol',
    codigo: 'VOL-01',
    nombre: 'Voleibol',
    descripcion: '',
    lugar: 'Gimnasio',
    cupoMaximo: 20,
    cuposDisponibles: 20,
    idsEntrenadores: ['t1'],
    visible: true,
  );
  const natacion = Deporte(
    id: 'nat',
    codigo: 'NAT-01',
    nombre: 'Natación',
    descripcion: '',
    lugar: 'Piscina',
    cupoMaximo: 15,
    cuposDisponibles: 15,
    idsEntrenadores: ['t2'],
    visible: true,
  );

  late FakeDeporteRepository deportes;
  late FakeSolicitudRepository solicitudes;

  setUp(() {
    deportes = FakeDeporteRepository()
      ..agregar(voleibol)
      ..agregar(natacion);
    solicitudes = FakeSolicitudRepository(deportes);
  });

  Future<SolicitudesEntrenadorViewModel> entrenadorListo() async {
    final vm = SolicitudesEntrenadorViewModel(
      deporteRepository: deportes,
      solicitudRepository: solicitudes,
      entrenador: maria,
    )..cargar();
    await pumpEventQueue();
    return vm;
  }

  test('el entrenador solo ve las disciplinas que no dirige', () async {
    final vm = await entrenadorListo();
    expect(vm.estado, SolicitudesEntrenadorEstado.listo);
    expect(vm.opciones.map((o) => o.deporte.id), ['nat']);
  });

  test('la búsqueda ignora las tildes', () async {
    final vm = await entrenadorListo();
    vm.busqueda = 'natacion';
    expect(vm.opciones, hasLength(1));
    vm.busqueda = 'futbol';
    expect(vm.opciones, isEmpty);
  });

  test('al solicitar queda pendiente y no se puede repetir', () async {
    final vm = await entrenadorListo();
    expect(
      await vm.solicitar(natacion, mensaje: ' Tengo experiencia '),
      isNull,
    );
    await pumpEventQueue();
    expect(vm.opciones.single.solicitud?.estado, EstadoSolicitud.pendiente);
    expect(vm.pendientes, 1);
    expect(
      await vm.solicitar(natacion),
      'Ya enviaste una solicitud para esta disciplina.',
    );
    expect(solicitudes.buscar('t1_nat')?.mensaje, 'Tengo experiencia');
  });

  test('al aprobar, el entrenador queda asignado a la disciplina', () async {
    final vmEntrenador = await entrenadorListo();
    await vmEntrenador.solicitar(natacion);

    final vmAdmin = SolicitudesAdminViewModel(solicitudRepository: solicitudes)
      ..cargar();
    await pumpEventQueue();
    expect(vmAdmin.pendientes, hasLength(1));

    expect(await vmAdmin.aprobar(vmAdmin.pendientes.single), isNull);
    await pumpEventQueue();
    expect(vmAdmin.pendientes, isEmpty);
    final nat = await deportes.obtener('nat');
    expect(nat!.idsEntrenadores, containsAll(['t2', 't1']));
    // Ya la dirige: deja de aparecer entre las que puede pedir.
    expect(vmEntrenador.opciones, isEmpty);
  });

  test('si se la rechazan, puede volver a solicitarla', () async {
    final vm = await entrenadorListo();
    await vm.solicitar(natacion);
    await solicitudes.rechazar(solicitudes.buscar('t1_nat')!);
    await pumpEventQueue();
    expect(vm.opciones.single.solicitud?.estado, EstadoSolicitud.rechazada);
    expect(await vm.solicitar(natacion), isNull);
  });
}
