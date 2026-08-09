# Feature Specification: Fundación de Autenticación y Contratos de Dominio (expenses/categories)

**Feature Branch**: `003-auth-domain-foundation`

**Created**: 2026-08-09

**Status**: Draft

**Input**: User description: "Fundación de Autenticación y Contratos de Dominio (expenses/categories). Formaliza la sesión anónima y la configuración de Firestore de la 001 dentro de un feature `auth` con sus tres capas; añade las interfaces de repositorio de dominio (con entidades) para expenses y categories que la 004 implementará; el buffer de escrituras pre-autenticación vive en un use case, nunca en un widget; firestore.rules reemplaza el bloque env_checks por el ruleset completo de docs/DATA_MODEL.md; despliegue a dev automático, a prod con confirmación humana explícita; suite de rules contra el emulador en el mismo workflow de CI existente."

## User Scenarios & Testing *(mandatory)*

<!--
  Esta feature no entrega pantallas de producto — entrega la fundación de autenticación y los
  contratos de dominio que features posteriores (004 en adelante) consumirán. Las "personas
  usuarias" de la mayoría de estas historias son, por eso, quienes construyen sobre esta fundación
  (desarrolladores, CI) y, en las historias 1 y 2, la persona final que experimenta el resultado
  invisible de esta infraestructura (nunca ve una sesión, nunca ve un error de escritura).
-->

### User Story 1 - La sesión de la app se establece sin que nadie la note (Priority: P1)

Una persona abre la app por primera vez, o por enésima vez, y nunca ve una pantalla de inicio de
sesión, un botón de "continuar como invitado", ni ningún indicador de que se está autenticando.
Simplemente ve la app funcionar.

**Why this priority**: Es la base de todo lo demás: sin una sesión, ninguna escritura a Firestore
es posible (las reglas de seguridad exigen `request.auth != null` en todo). Se marca P1 junto con
la Historia 2 porque ambas, en conjunto, son el prerrequisito de cualquier feature de producto
futura que necesite persistir datos.

**Independent Test**: Se puede probar por completo arrancando la app y confirmando, por inspección
del estado interno (no de la interfaz, que no muestra nada), que existe una sesión anónima activa
antes de que transcurra el primer segundo, sin que ninguna pantalla, diálogo o control de
autenticación se haya renderizado en ningún momento.

**Acceptance Scenarios**:

1. **Given** un arranque limpio de la app, **When** la app termina de inicializar, **Then** existe
   una sesión anónima activa, sin que se haya mostrado ninguna pantalla o interacción relacionada
   con autenticación.
2. **Given** el código fuente de la app, **When** se inspecciona dónde vive la lógica de sesión,
   **Then** está encapsulada dentro de un feature `auth` con sus tres capas (dominio, datos,
   presentación), no como una llamada directa a un SDK externo desde el arranque de la app.

---

### User Story 2 - Ninguna escritura se pierde por llegar demasiado pronto (Priority: P1)

Alguien interactúa con la app en el instante exacto en que se abre, antes de que la sesión interna
haya terminado de resolverse. Lo que sea que esa interacción intente guardar no se pierde, no
falla, y no muestra ningún estado de carga — simplemente funciona, y se sincroniza en cuanto la
sesión está lista.

**Why this priority**: Es la garantía que hace posible que la sesión anónima de la Historia 1 sea
"silenciosa" de verdad. Sin este mecanismo, cualquier interacción ultra-rápida al abrir la app
tendría una ventana de fallo real. Se agrupa como P1 junto con la Historia 1 porque juntas
constituyen la fundación completa de persistencia que toda feature futura necesita.

**Independent Test**: Se puede probar por completo disparando una operación de escritura de dominio
inmediatamente al arrancar, antes de que la sesión haya resuelto (simulando un retraso en la
resolución), y confirmando que la operación se completa localmente sin error y llega al servidor en
cuanto la sesión queda disponible, sin ninguna señal de carga visible.

**Acceptance Scenarios**:

1. **Given** una operación de escritura de dominio disparada antes de que exista un UID resuelto,
   **When** la sesión anónima aún no ha terminado de establecerse, **Then** la operación se
   almacena en un buffer en memoria y se completa localmente sin error.
2. **Given** una operación ya almacenada en ese buffer, **When** la sesión anónima resuelve un UID,
   **Then** la operación se envía automáticamente, sin ninguna acción adicional de la persona
   usuaria.
3. **Given** el código fuente de esta feature, **When** se inspecciona dónde vive el buffer,
   **Then** está implementado dentro de un caso de uso de la capa de dominio, no dentro de un
   widget ni de un controlador de la capa de presentación.

---

### User Story 3 - Los contratos de dominio de gastos y categorías existen antes que su implementación (Priority: P1)

Quien construye la feature de captura de gastos (prevista para la 004) necesita poder escribir
código y tests contra una interfaz estable de "repositorio de gastos" y "repositorio de
categorías" — incluyendo las entidades que esas interfaces manejan — sin esperar a que exista
ninguna implementación real conectada a Firestore.

**Why this priority**: Desbloquea el desarrollo paralelo de la 004 y fija, por adelantado, la forma
exacta que debe respetar cualquier implementación futura. Es P1 porque sin esto, la 004 no tiene
punto de partida arquitectónico y arriesga inventar su propia forma de contrato sobre la marcha.

**Independent Test**: Se puede probar por completo escribiendo un test de Dart puro que construye
las entidades de dominio (`Expense`, `Category`, el objeto de dinero) y un doble de prueba de cada
interfaz de repositorio, sin inicializar Flutter, Firebase, ni ningún framework — y confirmando que
compila y pasa.

**Acceptance Scenarios**:

1. **Given** las entidades de dominio de esta feature, **When** se construyen dentro de un test de
   Dart puro, **Then** no requieren ninguna inicialización de Flutter ni de Firebase para existir.
2. **Given** la interfaz `ExpenseRepository`, **When** se inspecciona su ubicación y sus miembros,
   **Then** vive en la capa de dominio del feature `expenses`, es completamente abstracta, y no
   existe ninguna clase bajo `data/` o `presentation/` para ese feature en esta entrega.
3. **Given** la interfaz `CategoryRepository`, **When** se inspecciona su ubicación y sus miembros,
   **Then** aplica la misma condición que el escenario anterior para el feature `categories`.

---

### User Story 4 - Los datos reales del producto quedan protegidos, no solo el diagnóstico de entornos (Priority: P1)

Quien mantiene el proyecto necesita la certeza de que, en el momento en que exista la primera
escritura real de un gasto o una categoría, las reglas de acceso a esos datos ya están completas y
correctas — no un placeholder de diagnóstico dejado por la fundación de entornos.

**Why this priority**: Es la razón de negocio central de esta feature junto con las Historias 1-3:
sin reglas completas, ninguna escritura de producto futura tiene ninguna protección real más allá
de "cualquiera puede escribir cualquier cosa". Se marca P1 porque bloquea directamente que la 004
pueda considerarse segura.

**Independent Test**: Se puede probar por completo inspeccionando `firestore.rules` y confirmando
que el bloque `env_checks` de la feature 001 ya no existe, y que en su lugar están las funciones y
reglas anidadas para `users`, `categories` y `expenses` descritas en `docs/DATA_MODEL.md`.

**Acceptance Scenarios**:

1. **Given** el archivo `firestore.rules` de esta feature, **When** se inspecciona su contenido,
   **Then** no contiene ningún rastro del bloque `env_checks` de la feature 001.
2. **Given** ese mismo archivo, **When** se inspecciona, **Then** contiene las funciones `isOwner`,
   `isValidExpense` e `isValidCategory`, y las reglas anidadas para `users/{userId}`,
   `users/{userId}/categories/{categoryId}` y `users/{userId}/expenses/{expenseId}`.
3. **Given** un documento de categoría con `nameKey` y `name` simultáneamente no nulos, **When** se
   intenta crear ese documento, **Then** la escritura es rechazada por `isValidCategory`.
4. **Given** un documento de categoría sin `nameKey` ni `name` (ambos nulos), **When** se intenta
   crear ese documento, **Then** la escritura también es rechazada.

---

### User Story 5 - El despliegue a producción nunca ocurre por accidente (Priority: P2)

Quien despliega el nuevo conjunto de reglas necesita que el entorno de desarrollo lo reciba de
forma directa, pero que el entorno de producción exija un paso de confirmación separado y explícito
— nunca como efecto colateral del mismo comando usado para desarrollo.

**Why this priority**: Protege el entorno de producción real de un despliegue accidental de reglas
todavía no verificadas manualmente en un contexto real, consistente con las Agent Operating Rules
de la constitución. Es P2 porque depende de que el ruleset de la Historia 4 ya exista; no bloquea
que el trabajo de desarrollo avance mientras tanto.

**Independent Test**: Se puede probar por completo desplegando el ruleset al proyecto de desarrollo
y confirmando que se completa sin ningún paso adicional, y luego intentando el despliegue a
producción y confirmando que el sistema exige una confirmación humana explícita antes de proceder.

**Acceptance Scenarios**:

1. **Given** el ruleset actualizado de esta feature, **When** se despliega al proyecto de
   desarrollo, **Then** el despliegue se completa sin requerir ningún paso de confirmación
   adicional más allá del proceso normal.
2. **Given** ese mismo ruleset, **When** se intenta desplegar al proyecto de producción, **Then**
   el sistema requiere una confirmación humana explícita, separada, antes de que el despliegue
   proceda.

---

### User Story 6 - Las reglas de seguridad se verifican por una suite automática, no por lectura (Priority: P1)

Quien revisa un cambio a las reglas de acceso necesita una señal automática — no la opinión de
quien lo revisó a simple vista — de que las reglas siguen protegiendo correctamente cada caso
crítico: aislamiento entre usuarios, validación de montos, el invariante de nombre de categoría, y
el rechazo de acceso no autenticado.

**Why this priority**: Es, junto con la Historia 4, la garantía real de que las reglas hacen lo que
dicen hacer. Sin una suite automática, "las reglas están completas" es una afirmación de la
documentación que nadie vuelve a verificar cuando el código diverge. Se agrupa como P1 porque sin
esto, la Historia 4 no está realmente demostrada, solo declarada.

**Independent Test**: Se puede probar por completo ejecutando la suite de tests de reglas contra el
emulador local y confirmando que cada escenario de la lista (lectura cruzada entre usuarios, monto
inválido, `monthKey` malformado, invariante de categoría, acceso no autenticado, colección no
declarada, cambio de `uid` propio) tiene al menos un test que lo cubre y que ese test pasa.

**Acceptance Scenarios**:

1. **Given** la suite de tests de Security Rules, **When** se ejecuta contra el emulador local,
   **Then** cubre como mínimo: aislamiento de lectura entre usuarios para `expenses` y
   `categories`; rechazo de `amountMinor` negativo, cero, excesivo o de tipo decimal; rechazo de
   `monthKey` con formato inválido; rechazo de una categoría con `nameKey` y `name` simultáneos o
   con ninguno de los dos; denegación de acceso no autenticado en cada colección; denegación de
   escritura a una colección de nivel superior no declarada; y denegación de un intento de cambiar
   el `uid` propio en una actualización del documento de usuario.
2. **Given** esa misma suite, **When** se ejecuta, **Then** todos sus casos pasan contra el ruleset
   de esta feature.

---

### User Story 7 - La verificación de reglas corre sola, en el mismo lugar que todo lo demás (Priority: P2)

Quien abre un pull request que toca `firestore.rules` no tiene que acordarse de correr la suite de
reglas manualmente ni de levantar el emulador a mano — el mismo pipeline de integración continua
que ya corre el análisis estático y las pruebas de Dart también corre esta suite.

**Why this priority**: Es una garantía operativa sobre la Historia 6, no un requisito
independiente: automatiza que la verificación ya construida realmente se ejecute en cada cambio. Es
P2 porque la suite ya es correcta y ejecutable manualmente sin esto; esto solo quita la posibilidad
de que alguien olvide correrla.

**Independent Test**: Se puede probar por completo abriendo un pull request que modifica
`firestore.rules` y confirmando que el pipeline de integración continua existente levanta el
emulador local y ejecuta la suite de reglas como parte del mismo flujo que ya ejecuta análisis y
pruebas, sin ningún paso manual adicional.

**Acceptance Scenarios**:

1. **Given** un pull request que modifica cualquier archivo de reglas, **When** el pipeline de
   integración continua se ejecuta, **Then** incluye, dentro del mismo workflow que ya corre
   análisis y pruebas, un paso que levanta el emulador local de Firestore y ejecuta la suite de
   reglas.
2. **Given** un cambio que rompe deliberadamente una regla, **When** ese pipeline se ejecuta,
   **Then** el pipeline completo falla, no solo un job desconectado que nadie revisa.

---

### Edge Cases

- ¿Qué pasa si se disparan dos o más escrituras de dominio mientras el buffer está pendiente, antes
  de que exista un UID? Todas quedan en el buffer y se envían, en orden, en cuanto la sesión
  resuelve — ninguna se pierde ni se sobrescribe entre sí.
- ¿Qué pasa si la sesión anónima no puede resolverse por falta de conectividad en el primer
  arranque? El comportamiento ya establecido por la feature 001 no cambia: la sesión se resuelve en
  cuanto hay conectividad, y mientras tanto el buffer de esta feature retiene cualquier escritura
  pendiente indefinidamente, sin mostrar un error.
- ¿Qué pasa si alguien intenta seguir escribiendo en la colección `env_checks` después de esta
  feature? La escritura es rechazada por la regla catch-all final, igual que cualquier otra
  colección no declarada.
- ¿Qué pasa si un despliegue de reglas a producción se intenta sin la confirmación humana
  explícita? El despliegue no procede.
- ¿Qué pasa si el documento de usuario intenta cambiar su propio campo `uid` en una actualización?
  La escritura es rechazada.
- ¿Qué pasa con la ruta raíz de la app una vez que la pantalla de diagnóstico de la 001 pierde su
  control de escritura a `env_checks`? Ver Assumptions — no se introduce ninguna pantalla de
  producto nueva en esta feature.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE establecer una sesión anónima silenciosa durante el arranque de la
  app, sin ninguna pantalla, diálogo o interacción visible para la persona usuaria.
- **FR-002**: La lógica de sesión anónima DEBE vivir dentro de un feature `auth` con sus tres capas
  (dominio: caso de uso + repositorio abstracto; datos: implementación concreta; presentación: sin
  pantallas en esta feature), y NO como una llamada directa a un SDK de autenticación fuera de esa
  estructura.
- **FR-003**: El almacenamiento local DEBE configurarse con persistencia offline habilitada y
  caché sin límite superior, de forma que ninguna escritura de dominio dependa de una conexión de
  red para completarse localmente.
- **FR-004**: Toda escritura de dominio disparada antes de que la sesión anónima haya resuelto un
  UID DEBE almacenarse en un buffer en memoria y enviarse automáticamente en cuanto el UID esté
  disponible, sin requerir ninguna acción adicional de la persona usuaria.
- **FR-005**: El buffer de escrituras pre-sesión DEBE vivir en un caso de uso de la capa de
  dominio; ningún widget ni controlador de la capa de presentación puede implementar, contener o
  gestionar directamente ese buffer.
- **FR-006**: DEBEN existir las entidades de dominio para un gasto, una categoría, y un objeto de
  dinero en unidades mínimas enteras, construibles en un test de Dart puro sin ningún setup de
  Flutter, Firebase, o framework de UI.
- **FR-007**: DEBE existir una interfaz de repositorio abstracta para gastos en la capa de dominio
  del feature `expenses`, sin ninguna implementación concreta ni clase bajo sus capas de datos o
  presentación en esta entrega.
- **FR-008**: DEBE existir una interfaz de repositorio abstracta para categorías en la capa de
  dominio del feature `categories`, con la misma restricción que FR-007.
- **FR-009**: `firestore.rules` DEBE reemplazar por completo el bloque de diagnóstico heredado de
  la feature 001 por el ruleset de producto: funciones de validación de propiedad y de forma de
  documento para gastos y categorías, y las reglas anidadas correspondientes a usuarios,
  categorías y gastos.
- **FR-010**: La validación de categorías DEBE hacer cumplir el invariante de que exactamente uno
  de los dos campos de nombre (clave de traducción o texto literal) está presente — nunca ambos,
  nunca ninguno.
- **FR-011**: El ruleset DEBE terminar con una regla catch-all final que deniega cualquier lectura
  o escritura no explícitamente permitida por una regla anterior.
- **FR-012**: El ruleset actualizado DEBE desplegarse al proyecto de desarrollo como parte del
  flujo normal de esta feature.
- **FR-013**: El despliegue del ruleset al proyecto de producción DEBE requerir una confirmación
  humana explícita, independiente del despliegue a desarrollo, y NUNCA debe ocurrir como efecto
  colateral de un comando que no la solicite específicamente.
- **FR-014**: DEBE existir una suite automatizada de tests de reglas de seguridad, ejecutada contra
  el emulador local, que cubra como mínimo: denegación de lectura cruzada entre usuarios para
  gastos y categorías; rechazo de un monto inválido (negativo, cero, excesivo, o de tipo decimal);
  rechazo de un identificador de mes con formato inválido; rechazo de una categoría con ambos
  campos de nombre presentes o con ninguno; denegación de acceso no autenticado en cada colección;
  denegación de escritura a una colección de nivel superior no declarada; y denegación de un
  intento de modificar el identificador de usuario propio en una actualización del documento de
  usuario.
- **FR-015**: Esa suite de tests de reglas de seguridad DEBE ejecutarse en el mismo flujo de
  integración continua que ya ejecuta el análisis estático y las pruebas de Dart, no en un flujo
  separado y desconectado.
- **FR-016**: Esta feature NO DEBE incluir teclado numérico, selección de categorías en interfaz,
  siembra de categorías por defecto, pantalla de configuración, inicio de sesión con proveedores
  externos, ni ninguna implementación de las capas de datos o presentación para gastos o
  categorías.
- **FR-017**: El feature de diagnóstico de aislamiento de entornos de la feature 001 (pantalla,
  entidad, repositorio, y su bloque de reglas específico) DEBE eliminarse como parte de esta
  feature, ya que su propósito de verificación ha sido cumplido y su bloque de reglas queda
  reemplazado por el ruleset completo.

### Key Entities

- **Expense (dominio)**: representa un gasto individual — monto, referencia a categoría, fecha,
  nota opcional. No expone campos de sincronización propios de la infraestructura de datos.
- **Category (dominio)**: representa una categoría de gasto — un nombre resuelto por clave de
  traducción o por texto literal (nunca ambos), color, ícono, si es una categoría por defecto.
- **Money (objeto de valor)**: monto expresado en unidades mínimas enteras junto con su código de
  moneda; ninguna operación aritmética sobre él usa punto flotante.
- **Sesión de autenticación**: representa la identidad anónima activa de la instalación; expone
  únicamente si existe un identificador de usuario resuelto, nada más.
- **Buffer de escrituras pendientes**: cola en memoria de operaciones de dominio que esperan a que
  la sesión de autenticación resuelva un identificador de usuario antes de completarse.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los arranques de la app establecen una sesión anónima sin mostrar ninguna
  pantalla o interacción relacionada con autenticación.
- **SC-002**: El 100% de las escrituras de dominio disparadas antes de que exista un identificador
  de usuario resuelto se completan localmente sin error y se sincronizan al servidor en cuanto la
  sesión resuelve, sin pérdida de datos ni intervención manual.
- **SC-003**: Un desarrollador puede escribir y ejecutar un test unitario contra cualquiera de las
  dos interfaces de repositorio de esta feature, usando un doble de prueba, sin inicializar
  Flutter ni Firebase, el 100% de las veces.
- **SC-004**: El 100% de los escenarios cubiertos por la suite de tests de Security Rules (listados
  en FR-014) pasan contra el emulador local.
- **SC-005**: Cada pull request que modifica cualquier archivo de reglas dispara automáticamente la
  suite de reglas en integración continua, sin ningún paso manual.
- **SC-006**: El ruleset desplegado al proyecto de desarrollo y el ruleset versionado en el
  repositorio son idénticos, verificado por comparación directa.
- **SC-007**: El 100% de los despliegues al proyecto de producción, en toda la historia de esta
  feature, quedan precedidos por una confirmación humana explícita registrada en la sesión que los
  ejecuta.

## Assumptions

- La sesión anónima ya existe desde la feature 001 como una llamada directa dentro del arranque de
  la app; esta feature es un refactor arquitectónico de esa misma sesión (moverla dentro de un
  feature `auth` propiamente estructurado), no una segunda sesión ni un cambio de comportamiento
  visible para la persona usuaria.
- La feature 004 consumirá las interfaces de repositorio de gastos y categorías de esta feature
  para construir sus implementaciones de datos y sus pantallas; esta feature las habilita pero no
  las bloquea ni las anticipa.
- La ruta raíz de la app, una vez que la pantalla de diagnóstico de la feature 001 pierde su
  control de escritura a la colección eliminada, mantiene una pantalla mínima heredada (el
  indicador de entorno, sin el botón de escritura) hasta que la feature 004 entregue la pantalla
  real de producto. No se considera una pantalla de producto nueva a efectos del alcance de esta
  feature.
- El emulador local de Firestore ya está configurado desde la feature 001; esta feature reutiliza
  esa configuración para la nueva suite de tests de reglas en lugar de crear una paralela.
- Un objeto de valor de dinero en unidades mínimas enteras es suficiente para las entidades de esta
  feature; la conversión entre monedas no aplica, por ser un anti-objetivo del producto.
- "Confirmación humana explícita" para el despliegue a producción sigue el mismo mecanismo ya
  usado en la feature 001 (una pregunta directa a la persona operadora antes de ejecutar el
  comando), sin introducir una herramienta de aprobación nueva.
