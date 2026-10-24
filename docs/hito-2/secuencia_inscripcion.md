# Diagrama de secuencia: Inscribirse en una disciplina

**Casos de uso:** CU-03 Inscribirse (incluye CU-05 Validar solvencia) · **Requisitos:** RF-EST-04, RF-SIS-01, RF-SIS-02, RF-SIS-03, RF-SIS-04, RNF-05, RNF-07

Muestra el flujo completo con sus flujos alternos. El cupo se verifica y descuenta en una sola transacción, para que dos inscripciones simultáneas nunca superen el cupo (RNF-07).

```mermaid
sequenceDiagram
    autonumber
    actor E as Estudiante
    participant V as Vista
    participant VM as ViewModel
    participant IR as InscripcionRepository
    participant FS as Firestore

    E->>V: Pulsa «Inscribirme»
    V-->>E: Muestra el resumen y pide confirmar
    E->>V: Confirma
    V->>VM: inscribir(estudiante, deporte)
    VM->>IR: inscribir(estudiante, deporte)
    alt Estudiante no solvente (CU-05)
        IR-->>VM: InscripcionRechazada(noSolvente)
        VM-->>V: Muestra el motivo
        V-->>E: Debes estar solvente para inscribirte
    else Estudiante solvente
        IR->>FS: Buscar una inscripción activa en ese deporte
        FS-->>IR: Resultado
        alt Ya está inscrito
            IR-->>VM: InscripcionRechazada(yaInscrito)
            VM-->>V: Muestra el motivo
            V-->>E: Ya estás inscrito y lo lleva a Mis inscripciones
        else Sin inscripción previa
            IR->>FS: Transacción: verifica el cupo, crea la inscripción y descuenta el cupo
            alt Cupo agotado
                FS-->>IR: Transacción rechazada
                IR-->>VM: InscripcionRechazada(sinCupo)
                VM-->>V: Muestra el motivo
                V-->>E: La disciplina no tiene cupos y vuelve al catálogo
            else Cupo disponible
                FS-->>IR: Inscripción creada y cupo descontado
                IR-->>VM: Inscripcion
                VM-->>V: Inscripción confirmada
                V-->>E: Muestra la confirmación y actualiza Mis inscripciones
            end
        end
    end
```

## Notas

- Las reglas se validan dentro de `inscribir()`, en este orden: solvencia, inscripción duplicada y cupo. Es el mismo orden de CU-03 (pasos 2, 3 y 6) y el que implementa `FakeInscripcionRepository`.
- Según la documentación de `InscripcionRepository`, los tres rechazos se informan con `InscripcionRechazada` y un `MotivoRechazo` (`noSolvente`, `yaInscrito`, `sinCupo`), cada uno con su mensaje para el usuario.
- Diferencia con la Figura 4 del Hito 1: allí la solvencia se consultaba antes de pedir la confirmación. Aquí la confirmación va primero, porque todas las validaciones quedaron dentro de `inscribir()`. El modelo guarda la solvencia en `Estudiante.solvente`, que cambia al aprobar un pago (RF-SIS-07).
- Los nombres de los métodos del ViewModel son propuestos. Los de los repositorios salen de las interfaces.
