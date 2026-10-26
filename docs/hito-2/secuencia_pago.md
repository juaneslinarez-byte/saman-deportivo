# Diagrama de secuencia: Pago de solvencia

**Casos de uso:** CU-12 Pagar solvencia y CU-16 Revisar pagos · **Requisitos:** RF-EST-08, RF-ADM-05, RF-SIS-07, RF-SIS-11, RF-SIS-12

Muestra las dos fases del pago: el estudiante paga a través de la pasarela y el administrador revisa el pago. El estudiante pasa a estar solvente solo cuando el administrador lo aprueba.

```mermaid
sequenceDiagram
    autonumber
    actor E as Estudiante
    actor A as Administrador
    participant V as Vista
    participant VM as ViewModel
    participant PR as PagoRepository
    participant PG as Pasarela de pagos
    participant FS as Firestore

    Note over E,FS: Fase 1 - El estudiante paga
    E->>V: Entra a «Pagar solvencia» y confirma el monto
    V->>VM: pagar(monto)
    VM->>PR: pagar(estudiante, monto)
    PR->>PG: Procesar el pago
    alt La pasarela rechaza el pago o no responde
        PG-->>PR: Error
        PR-->>VM: Excepción
        VM-->>V: Muestra el error
        V-->>E: Informa el motivo y permite reintentar
    else La pasarela aprueba la operación
        PG-->>PR: Código de operación (referencia)
        PR->>FS: Guardar el Pago en estado pendiente
        FS-->>PR: Pago guardado
        PR-->>VM: Pago pendiente
        VM-->>V: Pago registrado
        V-->>E: Muestra la referencia e indica que está en revisión
    end

    Note over E,FS: Fase 2 - El administrador revisa
    A->>V: Abre «Pagos pendientes»
    V->>VM: observarPendientes()
    VM->>PR: observarPendientes()
    PR->>FS: Leer los pagos pendientes
    FS-->>PR: Pagos pendientes
    PR-->>VM: Lista de pagos
    VM-->>V: Lista de pagos
    V-->>A: Muestra los pagos con su referencia y monto
    A->>V: Elige un pago y decide
    alt Aprueba el pago
        V->>VM: aprobar(pago)
        VM->>PR: aprobar(pago)
        PR->>FS: Marcar el pago como aprobado y al estudiante como solvente
        FS-->>PR: Actualizado
        PR-->>VM: Listo
        VM-->>V: Pago aprobado
        V-->>A: Confirma y retira el pago de la lista
    else Rechaza el pago
        V->>VM: rechazar(pago)
        VM->>PR: rechazar(pago)
        PR->>FS: Marcar el pago como rechazado sin cambiar la solvencia
        FS-->>PR: Actualizado
        PR-->>VM: Listo
        VM-->>V: Pago rechazado
        V-->>A: Confirma y retira el pago de la lista
    end

    Note over E,FS: El estudiante ve el nuevo estado en «Mis pagos»
```

## Notas

- `pagar`, `observarPendientes`, `aprobar` y `rechazar` son los métodos de la interfaz `PagoRepository`. Los nombres de los métodos del ViewModel son propuestos.
- El pago nace en estado `pendiente` y solo cambia a `aprobado` o `rechazado` por decisión del administrador. Un pago ya revisado no se puede revisar de nuevo.
- Si la pasarela rechaza la operación, no se guarda ningún pago.
- Este flujo se puede probar sin Firebase ni pasarela con `FakePagoRepository` (opciones `pasarelaRechaza` y `debeFallar`) junto con `FakeUsuarioRepository`.
