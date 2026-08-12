# Feature Specification: Historial de Gastos con Borrado Reversible

**Feature Branch**: `005-expense-history-undo`

**Created**: 2026-08-12

**Status**: Draft

**Input**: User description: "Historial de gastos con borrado reversible. Resultado esperado: el usuario puede revisar lo que ha registrado y deshacer un error de captura, sin que ninguna de esas acciones toque la ruta de registro. Criterios de aceptación: (1) el historial presenta los gastos en orden cronológico, agrupados por día, con el subtotal de cada día; (2) cada entrada muestra monto, categoría y hora, con la categoría identificable sin depender del color; (3) borrar un gasto se hace deslizando la entrada, sin diálogo de confirmación; (4) el borrado es reversible durante unos segundos mediante una acción de deshacer — la entrada desaparece de inmediato de la vista, pero el dato no se elimina de forma definitiva hasta que la ventana de deshacer expira; (5) deshacer restaura la entrada en su posición original, con todos sus datos intactos; (6) un gasto borrado deja de contar en los subtotales diarios y en cualquier agregación posterior, desde el instante del borrado; (7) borrar y deshacer funcionan sin conexión de red, con el mismo comportamiento y sin espera; (8) existe navegación entre la pantalla de captura y el historial, y la captura es siempre el destino inicial al abrir la app, sin importar dónde estaba el usuario al cerrarla; (9) el estado vacío del historial es ilustrado y acogedor, no un mensaje de ausencia de datos; (10) los gastos borrados hace más de treinta días se eliminan de forma definitiva; (11) toda la pantalla usa los tokens del sistema de diseño y está localizada en los cinco idiomas; (12) ninguna de estas funciones afecta el tiempo de registro medido en la feature 004. Fuera de alcance: edición de un gasto ya registrado, notas, filtros, búsqueda, rangos de fecha, gestión de categorías, ajustes y el resumen mensual."

## User Scenarios & Testing *(mandatory)*

<!--
  Esta feature entrega la segunda pantalla de producto de la app (después de la captura de la
  004) y, con ella, la primera navegación real entre pantallas. Es también un prerrequisito
  documentado de la futura feature de resumen mensual (Wrapped, ver docs/ROADMAP.md Fase 2):
  el resumen no puede construirse sobre datos que la persona usuaria no puede corregir, así que
  esta feature — la capacidad de revisar y corregir — se adelantó en el roadmap para ir antes.
-->

### User Story 1 - Revisar el historial de gastos, agrupado y con contexto (Priority: P1)

Una persona abre el historial y ve todos sus gastos ordenados del más reciente al más antiguo,
agrupados por día, con el total de cada día visible de un vistazo. Cada gasto individual muestra
lo suficiente — monto, categoría, hora — para reconocerlo sin tener que abrirlo.

**Why this priority**: Es la razón de ser completa de esta feature: sin poder ver lo que se ha
registrado, no hay forma de notar ni de corregir un error. Es P1 porque toda otra historia de esta
feature (deshacer, navegación) no tiene sentido si esta no existe primero.

**Independent Test**: Se puede probar por completo registrando varios gastos en distintos días y
categorías, abriendo el historial, y confirmando que aparecen agrupados por día en orden
cronológico descendente, cada día con su subtotal correcto, y cada entrada con monto, categoría y
hora visibles.

**Acceptance Scenarios**:

1. **Given** varios gastos registrados en distintos días, **When** se abre el historial, **Then**
   los gastos aparecen agrupados por día, del día más reciente al más antiguo, y cada grupo
   muestra el subtotal de ese día.
2. **Given** un grupo de un solo día con varios gastos, **When** se inspecciona el orden dentro del
   grupo, **Then** los gastos de ese día aparecen en orden cronológico.
3. **Given** una entrada del historial, **When** se observa sin interactuar con ella, **Then**
   muestra el monto, la categoría y la hora de registro, y la categoría es identificable (ícono y
   texto) sin depender únicamente de su color.

---

### User Story 2 - Deshacer un error de captura sin fricción (Priority: P1)

Una persona nota un gasto mal registrado, lo desliza para borrarlo, y lo ve desaparecer al
instante — sin que se le pregunte "¿estás seguro?". Si se equivocó al borrar, tiene unos segundos
para tocar "Deshacer" y recuperarlo exactamente como estaba. Si no lo deshace, el gasto queda
fuera de cualquier total desde el momento en que lo deslizó, no desde que expiró la ventana de
deshacer.

**Why this priority**: Es, junto con la Historia 1, el propósito central de esta feature — "revisar
y deshacer un error de captura" es literalmente el resultado esperado. Se agrupa como P1 porque sin
esto, el historial es de solo lectura y no cumple su función correctiva.

**Independent Test**: Se puede probar por completo deslizando un gasto para borrarlo, confirmando
que desaparece de inmediato y que el subtotal de su día se actualiza al instante, luego tocando
"Deshacer" dentro de la ventana y confirmando que el gasto vuelve a su posición original con todos
sus datos; y por separado, dejando expirar la ventana sin deshacer y confirmando que el gasto no
vuelve a aparecer.

**Acceptance Scenarios**:

1. **Given** una entrada del historial, **When** se desliza para borrarla, **Then** desaparece de
   la vista de inmediato, sin ningún diálogo de confirmación.
2. **Given** un gasto recién borrado, **When** se observa el subtotal de su día y cualquier total
   agregado, **Then** ya no lo incluyen, desde el instante del deslizamiento.
3. **Given** un gasto recién borrado, **When** la persona toca "Deshacer" dentro de la ventana de
   unos segundos, **Then** el gasto reaparece en su posición cronológica original, con monto,
   categoría y hora intactos, y vuelve a contar en los subtotales.
4. **Given** un gasto recién borrado, **When** la ventana de deshacer expira sin que se toque
   "Deshacer", **Then** el gasto queda eliminado de forma reversible únicamente a nivel de dato
   (ver Historia 5 para su eliminación definitiva) y no reaparece en el historial.
5. **Given** el dispositivo sin conexión de red, **When** se borra un gasto y se lo deshace dentro
   de la ventana, **Then** ambas acciones se completan con el mismo comportamiento e igual de
   rápido que con conexión.

---

### User Story 3 - Moverse entre captura e historial sin tocar la ruta sagrada (Priority: P2)

Una persona registra un gasto y luego quiere revisar su historial; encuentra cómo llegar sin salir
de la app. Cuando vuelve a abrir la app más tarde — sin importar en qué pantalla la dejó — aterriza
directo en la captura, lista para registrar, tal como la Fase 1 ya garantiza.

**Why this priority**: Habilita el uso combinado de las Historias 1 y 2 como parte del flujo diario
de la persona, pero no es en sí misma el valor central de la feature (que es ver y corregir). Es P2
porque el historial ya es útil y probable de forma aislada (por ejemplo, alcanzable temporalmente
por otra vía) antes de que exista una navegación pulida.

**Independent Test**: Se puede probar por completo navegando desde la pantalla de captura al
historial y de regreso, y por separado cerrando la app estando en el historial y confirmando que,
al reabrirla, la primera pantalla visible es la de captura.

**Acceptance Scenarios**:

1. **Given** la pantalla de captura, **When** la persona busca revisar sus gastos, **Then**
   encuentra un control de navegación visible que la lleva al historial.
2. **Given** la pantalla de historial, **When** la persona busca volver a registrar un gasto,
   **Then** encuentra un control de navegación visible que la lleva de regreso a la captura.
3. **Given** la app cerrada mientras se estaba en el historial, **When** se vuelve a abrir,
   **Then** la primera pantalla visible es la de captura, no el historial.
4. **Given** la pantalla de captura con la navegación de esta feature ya presente, **When** se mide
   el tiempo y número de toques del flujo de registro (feature 004), **Then** ambos permanecen
   exactamente iguales a como estaban antes de esta feature.

---

### User Story 4 - Un historial vacío que no se siente vacío (Priority: P3)

Alguien sin gastos registrados todavía abre el historial y ve una ilustración cálida invitándola a
empezar, no un mensaje seco de ausencia de datos.

**Why this priority**: Mejora la primera impresión de una pantalla que, para una persona nueva,
estará vacía la mayor parte de las primeras horas de uso — pero no bloquea ni condiciona a ninguna
otra historia. Es P3 porque el historial ya cumple su función correctiva sin este pulido.

**Independent Test**: Se puede probar por completo abriendo el historial en una cuenta sin ningún
gasto registrado y confirmando que se muestra una ilustración cálida en lugar de un mensaje de
texto plano.

**Acceptance Scenarios**:

1. **Given** ningún gasto registrado todavía, **When** se abre el historial, **Then** se muestra un
   estado vacío ilustrado y cálido, no un mensaje de texto plano de "no hay datos".

---

### User Story 5 - Los gastos borrados no viven para siempre (Priority: P3)

Quien mantiene el proyecto necesita que los gastos que alguien borró hace tiempo dejen de ocupar
espacio y de existir del todo, no solo estar ocultos.

**Why this priority**: Es una garantía de higiene de datos, invisible para la persona usuaria en el
día a día, y no bloquea el uso normal del historial ni del deshacer. Es P3 porque las Historias 1-2
ya son completas y correctas sin ella; esta solo evita una acumulación indefinida.

**Independent Test**: Se puede probar por completo confirmando que un gasto borrado hace más de
treinta días ya no existe en el almacenamiento, mientras uno borrado hace menos de treinta días
sigue existiendo (oculto, no definitivo).

**Acceptance Scenarios**:

1. **Given** un gasto borrado hace más de treinta días, **When** transcurre ese plazo, **Then** el
   dato se elimina de forma definitiva.
2. **Given** un gasto borrado hace menos de treinta días, **When** se inspecciona el
   almacenamiento, **Then** el dato todavía existe, aunque oculto de toda vista y agregación.

---

### Edge Cases

- ¿Qué pasa si la persona desliza para borrar dos o más gastos distintos antes de que expire la
  ventana de deshacer del primero? Cada uno tiene su propia ventana independiente; deshacer uno no
  afecta a los demás, y cada uno se vuelve definitivo (a nivel de dato oculto) en su propio momento.
- ¿Qué pasa si la persona cierra la app o la manda a segundo plano durante la ventana de deshacer?
  El comportamiento por defecto es que el borrado se confirma como si la ventana hubiera expirado —
  no hay forma de mostrar "Deshacer" si la app no está en primer plano.
- ¿Qué pasa si dos días distintos tienen exactamente el mismo subtotal? No afecta el agrupamiento
  ni el orden; cada día se muestra por separado con su propia fecha.
- ¿Qué pasa si un gasto pertenece a una categoría que después se desactivó o renombró? El
  historial resuelve el nombre de la categoría en el momento de la lectura, no al momento del
  registro — un renombrado se refleja retroactivamente, consistente con `docs/DATA_MODEL.md`.
- ¿Qué pasa si el historial se abre con miles de gastos acumulados? Queda fuera del alcance de esta
  feature optimizar para ese volumen (ver Assumptions) — el comportamiento correcto (orden,
  agrupamiento, subtotales) es el requisito; el rendimiento a gran escala no lo es.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE presentar los gastos de la persona usuaria en una pantalla de
  historial, ordenados del más reciente al más antiguo, agrupados por día calendario.
- **FR-002**: Cada grupo de día DEBE mostrar un subtotal de los gastos de ese día.
- **FR-003**: Cada entrada del historial DEBE mostrar, como mínimo, el monto, la categoría y la
  hora de registro del gasto.
- **FR-004**: La categoría de cada entrada DEBE ser identificable por al menos un medio distinto
  del color (ícono, texto, o ambos) — el color nunca es el único portador de esa información.
- **FR-005**: La persona usuaria DEBE poder borrar un gasto deslizando su entrada en el historial,
  sin que se le presente ningún diálogo de confirmación.
- **FR-006**: Al deslizar para borrar, la entrada DEBE desaparecer de la vista de inmediato, y el
  gasto DEBE dejar de contar en cualquier subtotal o agregación visible desde ese mismo instante —
  independientemente de si la ventana de deshacer ya expiró.
- **FR-007**: El sistema DEBE ofrecer una acción de "Deshacer" disponible durante una ventana de
  varios segundos después de cada borrado, independiente para cada gasto borrado.
- **FR-008**: Tocar "Deshacer" dentro de la ventana DEBE restaurar el gasto en su posición
  cronológica original, con todos sus datos (monto, categoría, fecha, hora) intactos, y DEBE
  volver a incluirlo en los subtotales.
- **FR-009**: El dato de un gasto borrado NO DEBE eliminarse de forma definitiva hasta que la
  ventana de deshacer expire sin que se haya tocado "Deshacer".
- **FR-010**: Borrar un gasto y deshacer ese borrado DEBEN completarse con el mismo comportamiento
  y sin demora perceptible, con o sin conexión de red — ninguna de las dos acciones espera al
  servidor.
- **FR-011**: DEBE existir un control de navegación visible entre la pantalla de captura y la
  pantalla de historial, alcanzable en ambos sentidos.
- **FR-012**: La pantalla de captura DEBE seguir siendo el destino inicial de la app en todo
  arranque, sin importar en qué pantalla se encontraba la persona usuaria cuando la app se cerró o
  se mandó a segundo plano.
- **FR-013**: Ninguna adición de esta feature (incluida la navegación de FR-011) DEBE incrementar
  el tiempo ni el número de toques del flujo de registro medidos por la feature 004 — el
  presupuesto de tres segundos y de dos toques de la Constitución (Principio 1) permanece intacto.
- **FR-014**: Cuando no exista ningún gasto registrado, el historial DEBE mostrar un estado vacío
  ilustrado y cálido, no un mensaje de texto plano de ausencia de datos.
- **FR-015**: Los gastos borrados hace más de treinta días DEBEN eliminarse de forma definitiva del
  almacenamiento, no solo permanecer ocultos.
- **FR-016**: Toda la pantalla de historial DEBE construirse exclusivamente con los tokens del
  sistema de diseño existentes y con texto localizado en los cinco idiomas soportados — inglés,
  español, portugués, italiano y francés.
- **FR-017**: Esta feature NO DEBE incluir edición de un gasto ya registrado, notas en el gasto,
  filtros, búsqueda, selección de rango de fechas, gestión de categorías (crear, renombrar,
  desactivar), ninguna pantalla de ajustes, ni el resumen mensual.

### Key Entities

- **Gasto (en el historial)**: la misma entidad de gasto que la feature 004 registra, presentada
  aquí en modo lectura y con la capacidad adicional de marcarse como borrado. Esta feature no
  añade campos nuevos a su forma de captura ni permite modificar monto, categoría o fecha.
- **Estado de borrado pendiente**: la condición transitoria de un gasto entre el instante en que se
  desliza para borrarlo y el instante en que la ventana de deshacer expira o se deshace. Determina
  si el gasto se excluye de la vista y de los subtotales, sin implicar todavía una eliminación
  definitiva del dato.
- **Grupo de día**: una agrupación de gastos que comparten la misma fecha calendario, con su propio
  subtotal, usada únicamente para la presentación del historial.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los gastos registrados aparecen en el historial agrupados por día, en
  orden cronológico descendente, con un subtotal correcto por cada día.
- **SC-002**: El 100% de los borrados se reflejan en la vista y en los subtotales en menos de un
  segundo desde el deslizamiento, sin ningún diálogo de confirmación.
- **SC-003**: El 100% de las acciones de "Deshacer" realizadas dentro de la ventana disponible
  restauran el gasto con sus datos originales intactos.
- **SC-004**: El 100% de los borrados y deshacer se completan con éxito sin conexión de red, con el
  mismo tiempo de respuesta que con conexión.
- **SC-005**: El tiempo y el número de toques del flujo de registro de la feature 004, medidos
  después de esta feature, no varían respecto a su medición antes de esta feature.
- **SC-006**: El 100% de los gastos borrados hace más de treinta días quedan eliminados de forma
  definitiva, verificado por inspección directa del almacenamiento.
- **SC-007**: El 100% de las pantallas de esta feature se muestran correctamente en los cinco
  idiomas soportados, sin texto sin traducir.

## Assumptions

- La ventana de deshacer dura unos segundos — se asume un valor de referencia de 5 segundos,
  consistente con `docs/UI_UX_SPEC.md` §4, ajustable en la fase de planificación sin requerir una
  nueva especificación.
- El mecanismo de "borrado reversible durante unos segundos, definitivo después" ya está modelado a
  nivel de dato desde `docs/DATA_MODEL.md` (el campo de borrado suave y su purga a los treinta
  días); esta feature es la primera en darle una interfaz real, no en diseñar el modelo desde cero.
- El control de navegación entre captura e historial sigue el patrón ya documentado en
  `docs/UI_UX_SPEC.md` §4 (una barra de navegación flotante); esta feature lo introduce con sus dos
  destinos ya existentes (captura, historial) — el tercer destino documentado (Ajustes) no existe
  todavía como pantalla y se añade en una feature posterior sin requerir un rediseño de este
  control.
- El rendimiento del historial con un volumen muy grande de gastos acumulados (más allá del uso
  normal de una persona a lo largo de varios años) no es un requisito de esta feature.
- La eliminación definitiva a los treinta días (Historia 5) puede ejecutarse por cualquier mecanismo
  que cumpla el resultado observable descrito — el momento exacto de creación de esta capacidad
  dentro de esta misma entrega, frente a una posterior, es una decisión de planificación, no de
  esta especificación.
