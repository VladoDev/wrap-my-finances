# Feature Specification: Resumen Mensual Animado y Compartible

**Feature Branch**: `006-monthly-wrapped-summary`

**Created**: 2026-08-12

**Status**: Draft

**Input**: User description: "Resumen mensual animado y compartible. Resultado esperado: al abrir la app por primera vez en un mes nuevo, el usuario recibe un resumen animado de su mes anterior, navegable y compartible, que hace que revisar sus finanzas se sienta como una recompensa. Criterios de aceptación: (1) el resumen aparece automáticamente en la primera apertura de un mes calendario nuevo, evaluado en la zona horaria almacenada del usuario, y aparece exactamente una vez por mes aunque el usuario tenga varios dispositivos; (2) un mes con menos de cinco gastos no dispara el resumen automáticamente — se ofrece de forma discreta y descartable, sin interrumpir; (3) el resumen está disponible manualmente para cualquier mes pasado con datos, en todo momento; (4) la secuencia avanza sola cada pocos segundos y permite avanzar, retroceder, pausar sosteniendo, y salir deslizando, con progreso visible; (5) descartar el resumen lo marca como visto y no vuelve a interrumpir ese mes; (6) las cifras aparecen con animación de conteo y los elementos entran con física de rebote — con reducción de movimiento activada, toda la animación se sustituye por transiciones breves y las cifras aparecen en su valor final de inmediato; (7) el resumen presenta el total gastado, la categoría dominante, el número de registros en esa categoría, y el gasto individual más alto del mes; (8) cuando los datos locales aún no están completos, el resumen indica que está sincronizando en lugar de mostrar un total que no puede sostener; (9) los gastos borrados no cuentan en ninguna cifra del resumen; (10) los nombres de categoría se resuelven en el momento de mostrar el resumen, de modo que una categoría renombrada aparece con su nombre actual; (11) la tarjeta final es compartible como imagen generada por la app, no como captura de pantalla, dimensionada para formato vertical de historias; (12) la tarjeta compartida no incluye ninguna cifra monetaria salvo que el usuario lo active explícitamente mediante un control visible, mostrando por defecto categoría dominante, número de registros y mes; (13) el resumen está localizado en los cinco idiomas, con cifras y fechas formateadas según el locale activo; (14) ninguna cifra monetaria, nota ni nombre de categoría escrito por el usuario sale en eventos de analítica — solo se registra la proporción de finalización. Fuera de alcance: comparación entre meses, gráficas, proyecciones, presupuestos, resúmenes anuales, y personalización del contenido del resumen."

## User Scenarios & Testing *(mandatory)*

<!--
  Esta es la feature que docs/ROADMAP.md (Fase 2, enmendada en la 005) identifica como la razón de
  negocio de retención del producto — pero solo tiene sentido sobre datos que la persona usuaria ya
  pudo revisar y corregir (historial + borrado, entregados en la 005). Las historias 1-3 son la
  experiencia sorpresa central; las historias 4-5 la extienden.
-->

### User Story 1 - El resumen aparece solo, en el momento correcto (Priority: P1)

Una persona abre la app por primera vez en un mes calendario nuevo. Si su mes anterior tuvo
actividad suficiente, el resumen aparece de inmediato, sin que lo haya pedido. Si lo cierra
deslizando, no vuelve a aparecer para ese mes — en ese dispositivo ni en ningún otro. Si el mes
anterior tuvo muy poca actividad, la app no la interrumpe con un resumen pobre, pero le deja una
invitación discreta por si quiere verlo de todas formas.

**Why this priority**: Es el disparador que hace que todo lo demás exista — sin él, el resumen es
una pantalla que nadie encuentra. Es P1 porque el valor de retención completo de esta feature
depende de que la sorpresa llegue sola, en el momento correcto, sin fatiga por repetición.

**Independent Test**: Se puede probar por completo simulando el cambio de mes calendario con datos
suficientes del mes anterior, abriendo la app, y confirmando que el resumen aparece automáticamente
una sola vez; y por separado, simulando un mes con pocos datos y confirmando que en su lugar aparece
solo una invitación discreta y descartable.

**Acceptance Scenarios**:

1. **Given** el primer arranque de la app en un mes calendario nuevo, **When** el mes anterior, en
   la zona horaria de la persona usuaria, tuvo cinco o más gastos, **Then** el resumen de ese mes
   aparece automáticamente sin acción previa.
2. **Given** ese mismo resumen ya mostrado y descartado, **When** la persona abre la app de nuevo,
   en el mismo dispositivo o en otro distinto, dentro del mismo mes calendario, **Then** el resumen
   no vuelve a aparecer automáticamente.
3. **Given** un mes anterior con menos de cinco gastos, **When** se abre la app por primera vez en
   el mes nuevo, **Then** el resumen no aparece automáticamente, pero una invitación pequeña y
   descartable a verlo igual está disponible.
4. **Given** el resumen mostrado automáticamente, **When** la persona lo descarta, **Then** queda
   registrado como visto para ese mes de forma permanente.

---

### User Story 2 - La secuencia se navega como una historia (Priority: P1)

Dentro del resumen, cada cifra aparece como una escena que avanza sola cada pocos segundos. La
persona puede adelantarla tocando a la derecha, retroceder tocando a la izquierda, pausarla
sosteniendo el dedo, y salir deslizando hacia abajo — y siempre ve cuánto le falta gracias a una
barra de progreso. Si tiene activada la reducción de movimiento del sistema, la experiencia sigue
siendo completamente usable, solo que sin los rebotes: las transiciones son breves y las cifras
aparecen ya completas.

**Why this priority**: El formato de "historia" es lo que distingue este resumen de una pantalla de
reporte — es P1 porque sin la navegación completa y el respeto a la reducción de movimiento, la
experiencia dejaría de sentirse como una recompensa y podría directamente excluir a personas con
sensibilidad al movimiento.

**Independent Test**: Se puede probar por completo abriendo un resumen y ejercitando cada uno de los
cuatro controles (avanzar, retroceder, pausar, salir) confirmando el comportamiento esperado y la
barra de progreso visible; y por separado, activando la reducción de movimiento del sistema y
confirmando que las animaciones de rebote y conteo se sustituyen por transiciones breves con valores
finales inmediatos.

**Acceptance Scenarios**:

1. **Given** el resumen abierto en cualquier escena, **When** no hay interacción, **Then** avanza
   automáticamente a la siguiente escena después de unos segundos, con una barra de progreso visible
   indicando cuánto falta.
2. **Given** el resumen abierto, **When** la persona toca el lado derecho, izquierdo, sostiene el
   dedo, o desliza hacia abajo, **Then** avanza, retrocede, se pausa, o se cierra, respectivamente.
3. **Given** la reducción de movimiento activada en el sistema, **When** se abre el resumen,
   **Then** ninguna escena usa física de rebote y toda cifra aparece en su valor final de inmediato,
   sin animación de conteo.

---

### User Story 3 - Las cifras que muestra son correctas y confiables (Priority: P1)

Lo que el resumen presenta —cuánto gastó en total, en qué categoría más, cuántas veces, y cuál fue
su gasto más alto— siempre corresponde exactamente a lo que la persona realmente registró y no
borró, con los nombres de categoría tal como existen hoy. Si sus datos locales todavía no
terminaron de sincronizarse, el resumen lo dice en vez de mostrarle un número que podría estar
incompleto.

**Why this priority**: Un resumen bonito pero incorrecto rompe la confianza en toda la app, no solo
en esta feature — es P1 porque la recompensa emocional que promete esta feature depende
completamente de que la persona pueda confiar en lo que ve.

**Independent Test**: Se puede probar por completo registrando un conjunto conocido de gastos en un
mes, incluyendo algunos borrados, y confirmando que el resumen calcula el total, la categoría
dominante, su conteo, y el gasto más alto exactamente sobre los gastos no borrados; y por separado,
simulando una sincronización local incompleta y confirmando que el resumen muestra un estado de
sincronización en vez de un total.

**Acceptance Scenarios**:

1. **Given** un mes con gastos conocidos en varias categorías, **When** se calcula el resumen,
   **Then** el total gastado, la categoría con más gasto acumulado, el número de registros en esa
   categoría, y el gasto individual más alto coinciden exactamente con los datos no borrados de ese
   mes.
2. **Given** un gasto de ese mes que fue borrado, **When** se calcula el resumen, **Then** ese gasto
   no participa en ninguna de las cuatro cifras.
3. **Given** una categoría usada ese mes que fue renombrada después, **When** se muestra el resumen,
   **Then** aparece con su nombre actual, no con el que tenía cuando se registraron los gastos.
4. **Given** una instalación reciente donde la caché local todavía no tiene todos los datos del mes,
   **When** se intenta mostrar el resumen, **Then** se indica que está sincronizando en vez de
   mostrar un total que podría ser incompleto.

---

### User Story 4 - Cualquier mes pasado, cuando quiera verlo (Priority: P2)

Más allá de la sorpresa automática, la persona puede volver a ver el resumen de cualquier mes
anterior que tenga datos, cuando quiera, sin esperar a que empiece un mes nuevo.

**Why this priority**: Extiende el valor de la feature más allá del momento único de sorpresa, pero
no es indispensable para que la experiencia central (Historias 1-3) entregue su valor. Es P2 porque
el resumen automático ya es la recompensa principal; el acceso manual es una comodidad adicional.

**Independent Test**: Se puede probar por completo seleccionando un mes pasado con datos desde
cualquier punto de la app y confirmando que su resumen se muestra igual que si hubiera aparecido
automáticamente.

**Acceptance Scenarios**:

1. **Given** un mes pasado con al menos un gasto no borrado, **When** la persona lo selecciona
   manualmente, **Then** su resumen se muestra completo, en cualquier momento, sin necesidad de
   esperar al cambio de mes.

---

### User Story 5 - Compartir sin exponer cifras por accidente (Priority: P2)

Al final del resumen, la persona puede compartir una tarjeta visual generada por la app,
dimensionada para historias, sin que su monto gastado se filtre a menos que ella misma decida
mostrarlo con un control visible.

**Why this priority**: Es la mecánica de crecimiento orgánico del producto, pero depende de que las
Historias 1-3 ya entreguen una experiencia completa — sin eso no hay nada que compartir. Es P2
porque el resumen ya es valioso para la persona sin necesidad de compartirlo.

**Independent Test**: Se puede probar por completo llegando a la tarjeta final y confirmando que la
imagen generada por defecto no incluye ninguna cifra monetaria, mostrando en cambio categoría
dominante, número de registros y el mes; y por separado, activando el control de mostrar montos y
confirmando que la imagen generada entonces sí los incluye.

**Acceptance Scenarios**:

1. **Given** la tarjeta final del resumen, **When** se comparte sin activar ningún control
   adicional, **Then** la imagen generada muestra la categoría dominante, el número de registros, y
   el mes, sin ninguna cifra monetaria.
2. **Given** esa misma tarjeta, **When** la persona activa explícitamente el control visible para
   mostrar montos, **Then** la imagen generada a partir de ese momento sí incluye las cifras
   monetarias.
3. **Given** la tarjeta compartida en cualquiera de los dos modos, **When** se genera la imagen,
   **Then** es una imagen renderizada por la app, no una captura de pantalla, dimensionada para
   formato vertical de historias.

---

### Edge Cases

- ¿Qué pasa si dos categorías empatan como la de mayor gasto acumulado en el mes? Se desempata de
  forma determinística y estable (por ejemplo, por orden de creación de la categoría), de modo que
  el resultado no cambie entre una apertura y otra del mismo resumen.
- ¿Qué pasa si la persona no abre la app durante varios meses seguidos? Al volver a abrirla, el
  resumen automático evalúa únicamente el mes calendario inmediatamente anterior al momento actual
  — no se acumula ni se ofrece un resumen por cada mes que se saltó.
- ¿Qué pasa si el resumen automático se dispara casi simultáneamente en dos dispositivos antes de
  que el estado de "visto" alcance a sincronizarse entre ellos? Es una condición límite aceptada:
  el resumen podría aparecer una vez en cada dispositivo en ese caso extremo; en cuanto la
  sincronización ocurre, ningún dispositivo vuelve a mostrarlo para ese mes.
- ¿Qué pasa si una categoría usada ese mes ya no existe como categoría activa (fue desactivada, no
  borrada, ya que las categorías nunca se eliminan por completo)? Su nombre se resuelve igual,
  consistente con cómo el historial (005) ya resuelve categorías inactivas.
- ¿Qué pasa si el mes tiene exactamente cinco gastos? Cumple el mínimo y el resumen se dispara
  automáticamente con normalidad.
- ¿Qué pasa si se solicita el resumen de un mes sin ningún gasto? No hay nada que mostrar; no aplica
  ni el resumen automático ni el acceso manual a un contenido vacío.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mostrar automáticamente el resumen del mes calendario inmediatamente
  anterior en la primera apertura de la app dentro de un mes calendario nuevo, evaluado en la zona
  horaria de la persona usuaria, siempre que ese mes anterior tenga cinco o más gastos no borrados.
- **FR-002**: El sistema DEBE mostrar el resumen automático exactamente una vez por mes calendario,
  de forma consistente sin importar desde cuál de los dispositivos de la persona usuaria se abra la
  app.
- **FR-003**: Cuando el mes anterior tenga menos de cinco gastos no borrados, el sistema NO DEBE
  mostrar el resumen automáticamente, pero DEBE ofrecer un acceso discreto y descartable a verlo de
  todas formas, sin interrumpir el uso normal de la app.
- **FR-004**: Descartar el resumen, automático o no, DEBE registrarlo como visto para ese mes de
  forma permanente, sin volver a interrumpir con él.
- **FR-005**: El resumen DEBE estar disponible manualmente para cualquier mes pasado que tenga al
  menos un gasto no borrado, en cualquier momento, independientemente de si ya fue visto.
- **FR-006**: El resumen DEBE presentarse como una secuencia de escenas que avanza automáticamente
  cada pocos segundos, con una indicación de progreso visible en todo momento.
- **FR-007**: La navegación del resumen DEBE responder a las cuatro acciones esperadas del formato
  de historia: avanzar, retroceder, pausar mientras se sostiene el toque, y salir deslizando.
- **FR-008**: Las cifras del resumen DEBEN presentarse con animación de conteo y los elementos con
  física de rebote — excepto cuando la preferencia de reducción de movimiento del sistema esté
  activa, en cuyo caso toda animación de rebote y de conteo DEBE sustituirse por transiciones breves
  con las cifras ya en su valor final.
- **FR-009**: El resumen DEBE presentar, como mínimo: el total gastado en el mes, la categoría con
  mayor gasto acumulado, el número de gastos registrados en esa categoría, y el monto del gasto
  individual más alto del mes.
- **FR-010**: Todas las cifras del resumen DEBEN calcularse exclusivamente sobre gastos no borrados
  del mes correspondiente — un gasto borrado, en cualquier momento antes de mostrarse el resumen, NO
  DEBE participar en ninguna de sus cifras.
- **FR-011**: Los nombres de categoría del resumen DEBEN resolverse en el momento de mostrarse, de
  modo que una categoría renombrada después de que sus gastos fueron registrados aparezca con su
  nombre vigente.
- **FR-012**: Cuando el sistema no pueda confirmar que los datos locales del mes están completos, el
  resumen DEBE mostrar un estado de sincronización en lugar de cualquier cifra que dependa de un
  total potencialmente incompleto.
- **FR-013**: La escena final del resumen DEBE ofrecer compartir una imagen generada por la propia
  app —no una captura de pantalla del dispositivo— dimensionada para formato vertical de historias.
- **FR-014**: La imagen compartida generada por defecto NO DEBE incluir ninguna cifra monetaria;
  DEBE mostrar la categoría dominante, el número de registros, y el mes.
- **FR-015**: DEBE existir un control visible y explícito que, al activarse, incluya las cifras
  monetarias en la imagen compartida generada a partir de ese momento; sin esa activación, ninguna
  cifra monetaria sale de la app a través de esta función.
- **FR-016**: Toda la experiencia del resumen DEBE construirse con los tokens del sistema de diseño
  existentes y presentarse localizada en los cinco idiomas soportados, con cifras y fechas
  formateadas según el locale activo de la persona usuaria.
- **FR-017**: Ningún evento de analítica generado por esta feature DEBE incluir una cifra monetaria,
  una nota, o un nombre de categoría escrito por la persona usuaria; como máximo DEBE registrarse la
  proporción de finalización de la secuencia.
- **FR-018**: Esta feature NO DEBE incluir comparación entre meses, gráficas, proyecciones,
  presupuestos, resúmenes anuales, ni ninguna forma de personalizar qué contenido incluye el
  resumen.

### Key Entities

- **Resumen mensual**: la agregación calculada de los gastos no borrados de una persona usuaria
  para un mes calendario específico — total, categoría dominante, conteo en esa categoría, y gasto
  más alto. Se calcula al momento de mostrarse, no se guarda como un registro propio.
- **Escena**: una unidad individual de la secuencia narrativa del resumen (por ejemplo, el total del
  mes, la categoría dominante, el hábito, el gasto más alto, la tarjeta final), con su propio tiempo
  de permanencia dentro de la barra de progreso general.
- **Tarjeta compartible**: la imagen final generada a partir del resumen, en dos variantes posibles
  (con y sin cifras monetarias) según la elección explícita de la persona usuaria en el momento de
  compartir.
- **Estado de "visto"**: la marca, por mes calendario, de que el resumen automático de ese mes ya
  fue mostrado y descartado, usada para no volver a interrumpir con él — debe ser consistente entre
  los dispositivos de una misma persona usuaria.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los meses con cinco o más gastos no borrados disparan el resumen
  automático en la primera apertura de la app dentro del mes calendario siguiente.
- **SC-002**: El 100% de los meses ya vistos y descartados no vuelven a interrumpir automáticamente,
  verificado desde más de un dispositivo de la misma persona usuaria.
- **SC-003**: El 100% de las cuatro cifras principales del resumen (total, categoría dominante,
  conteo, gasto más alto) coinciden exactamente con el cálculo esperado sobre los gastos no borrados
  del mes, en pruebas con conjuntos de datos conocidos.
- **SC-004**: El 100% de los gastos borrados quedan excluidos de las cifras del resumen, sin
  excepción.
- **SC-005**: El 100% de las aperturas del resumen con reducción de movimiento activada completan la
  secuencia sin ninguna animación de rebote, con las cifras visibles en su valor final desde el
  primer cuadro de cada escena.
- **SC-006**: El 100% de las imágenes compartidas sin activar el control de montos excluyen toda
  cifra monetaria.
- **SC-007**: El 100% de las pantallas de esta feature se muestran correctamente en los cinco
  idiomas soportados, con cifras y fechas formateadas según el locale activo.
- **SC-008**: El 0% de los eventos de analítica generados por esta feature contienen una cifra
  monetaria, una nota, o un nombre de categoría escrito por la persona usuaria.

## Assumptions

- El disparo del resumen automático "exactamente una vez por mes, entre varios dispositivos"
  requiere una marca de "visto" persistida a nivel de la cuenta de la persona usuaria (no solo en un
  dispositivo) — este dato todavía no existe en ninguna feature entregada hasta ahora y esta feature
  es la que lo introduce, junto con la zona horaria usada para evaluar el límite del mes. Mientras
  no exista una pantalla de ajustes donde la persona pueda configurar su zona horaria explícitamente
  (fuera del alcance de esta feature), se asume la zona horaria del dispositivo en el momento de la
  evaluación como valor por defecto razonable.
- El acceso manual a un mes pasado (Historia 4) no depende de que exista una pantalla de ajustes
  todavía inexistente — el punto de entrada concreto (por ejemplo, desde el historial ya entregado
  en la 005) es una decisión de planificación, no de esta especificación.
- El umbral de "pocos segundos" para el avance automático de cada escena sigue el rango ya
  documentado en `docs/UI_UX_SPEC.md` §3 (5 a 7 segundos), no un valor nuevo de esta especificación.
- El desempate entre categorías con el mismo gasto acumulado no tiene una regla previamente
  documentada; se asume un criterio determinístico y estable (por ejemplo, la categoría creada
  primero), ajustable en planificación sin cambiar el resultado observable para la persona usuaria.
- La agregación del resumen se calcula bajo demanda a partir de los gastos ya sincronizados
  localmente, consistente con `docs/DATA_MODEL.md` — no se introduce una colección de resúmenes
  precalculados.
