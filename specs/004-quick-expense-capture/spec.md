# Feature Specification: Captura de Gasto en Menos de Tres Segundos

**Feature Branch**: `004-quick-expense-capture`

**Created**: 2026-08-11

**Status**: Draft

**Input**: User description: "Registro de gastos en menos de tres segundos. Resultado esperado: el usuario puede registrar un gasto completo desde que abre la app hasta que queda persistido, en menos de tres segundos y con dos toques después de escribir el monto. Criterios de aceptación: (1) la app abre directamente en la pantalla de captura, sin pantalla previa, dashboard, indicador de carga ni bienvenida; (2) después de escribir el monto, el gasto queda registrado con exactamente dos toques — avanzar y elegir categoría — sin paso de confirmación; (3) el tiempo desde apertura hasta persistencia local es menor a tres segundos en p90, medido de forma instrumentada; (4) elegir categoría persiste el gasto y devuelve la pantalla a su estado inicial, con retroalimentación visible y háptica de éxito, lista para el siguiente registro; (5) la retroalimentación de éxito nunca espera confirmación del servidor; (6) las categorías se presentan ordenadas por frecuencia de uso propia, sin desplazamiento; (7) las categorías por defecto se siembran en el primer arranque referenciando claves de traducción, mostradas en el idioma activo del dispositivo; (8) los montos se capturan y almacenan sin pérdida de precisión decimal; (9) el teclado admite un único separador decimal acorde al locale, limita a dos decimales, y aplica separadores de miles en vivo; (10) un monto de cero no puede registrarse, con el control de avance deshabilitado y visible sin que la disposición cambie; (11) la única condición de error en esta ruta es la imposibilidad de escribir localmente, comunicada sin bloquear y sin perder el monto capturado — la ausencia de red no es un error; (12) toda la pantalla usa los tokens del sistema de diseño y texto localizado en los cinco idiomas. Fuera de alcance: historial, edición y borrado de gastos, notas en el gasto, gestión manual de categorías, navegación inferior, resumen mensual, y cualquier pantalla de ajustes — una sola pantalla que hace una sola cosa."

## User Scenarios & Testing *(mandatory)*

<!--
  Esta es la primera feature de producto real de la app: implementa, sobre los contratos de
  dominio que la feature 003 dejó listos (`ExpenseRepository`, `CategoryRepository`, entidades
  `Expense`/`Category`/`Money`, sesión anónima con buffer de pre-autenticación), la única pantalla
  que existe al abrir la app. Las siete personas usuarias de las historias de 003 eran, en su
  mayoría, quien construye sobre la fundación; aquí la persona usuaria es, en todas las historias,
  quien registra sus propios gastos.
-->

### User Story 1 - Registrar un gasto en dos toques, sin fricción (Priority: P1)

Una persona abre la app, ve de inmediato el teclado numérico — nada más — escribe un monto, toca
"Siguiente", toca una categoría, y el gasto queda guardado. La pantalla vuelve a su estado inicial
al instante, lista para el próximo registro, sin que en ningún momento haya visto una pantalla de
carga, un diálogo de confirmación, o cualquier otro paso intermedio.

**Why this priority**: Es la razón de ser completa de esta feature y el principio no negociable de
la constitución del proyecto (Principio 1). Sin este flujo, la app no cumple su propósito
fundamental, sin importar qué tan bien funcione cualquier otra parte.

**Independent Test**: Se puede probar por completo abriendo la app, cronometrando y contando toques
desde la apertura hasta la persistencia local del gasto, y confirmando que la pantalla queda lista
para un nuevo registro sin ninguna acción adicional.

**Acceptance Scenarios**:

1. **Given** un arranque limpio de la app, **When** la app termina de inicializar, **Then** la
   primera y única pantalla visible es la de captura de gasto, con el teclado numérico ya
   disponible — sin dashboard, sin indicador de carga, sin pantalla de bienvenida.
2. **Given** un monto ya escrito y distinto de cero, **When** la persona toca "Siguiente" y luego
   toca una categoría, **Then** el gasto queda registrado con exactamente esos dos toques, sin
   ningún paso de confirmación intermedio.
3. **Given** la categoría elegida, **When** el gasto se persiste localmente, **Then** la pantalla
   muestra retroalimentación visible y háptica de éxito y regresa a su estado inicial, lista para
   capturar el siguiente gasto sin ninguna acción adicional.
4. **Given** el gasto recién persistido localmente, **When** se observa la retroalimentación de
   éxito, **Then** esta se muestra sin esperar ninguna confirmación del servidor.
5. **Given** una serie de aperturas de la app en condiciones representativas, **When** se mide de
   forma instrumentada el tiempo entre la apertura y la persistencia local del gasto, **Then** el
   percentil 90 de esas mediciones es menor a tres segundos.

---

### User Story 2 - El monto se escribe sin errores de captura ni de precisión (Priority: P1)

Al escribir un monto, la persona usuaria ve separadores de miles aplicarse en vivo, no puede
escribir más de un separador decimal ni más de dos decimales, y no puede avanzar con un monto en
cero. El valor que finalmente se guarda es exacto, sin desviación por redondeo, sin importar cuántos
gastos con centavos se sumen después.

**Why this priority**: Es la garantía de que el "resultado" del registro rápido es también
correcto. Un registro veloz que guarda el monto equivocado, o que permite registrar $0, no cumple el
propósito del producto. Se agrupa como P1 junto con la Historia 1 porque ambas son necesarias para
que un solo registro cuente como exitoso.

**Independent Test**: Se puede probar por completo escribiendo distintas secuencias de dígitos y
separadores en el teclado, confirmando el comportamiento del control de avance en cada caso, y
sumando una serie de montos con centavos ya persistidos para confirmar que el total coincide
exactamente con la suma esperada.

**Acceptance Scenarios**:

1. **Given** el teclado de captura vacío, **When** la persona escribe dígitos, **Then** se aplican
   separadores de miles en vivo conforme escribe, usando el separador decimal correspondiente al
   locale activo del dispositivo.
2. **Given** un monto que ya tiene un separador decimal, **When** la persona intenta escribir un
   segundo separador decimal, **Then** el segundo separador es ignorado.
3. **Given** un monto con dos decimales ya escritos, **When** la persona intenta escribir un tercer
   dígito decimal, **Then** ese dígito es ignorado sin mostrar ningún error.
4. **Given** el monto en cero, **When** se observa el control de avance, **Then** está visible pero
   deshabilitado, y la disposición de la pantalla es idéntica a cuando el control está habilitado.
5. **Given** una secuencia de gastos ya persistidos con montos que incluyen centavos, **When** se
   suman sus valores, **Then** el total coincide exactamente con la suma esperada, sin desviación de
   redondeo.

---

### User Story 3 - La categoría correcta está siempre a un toque de distancia (Priority: P1)

Al tocar "Siguiente", la persona ve un selector de categorías donde las que más usa aparecen
primero, sin necesidad de desplazarse. En el primer arranque de la app, esas categorías ya existen,
con nombres en el idioma del dispositivo, sin que la persona haya tenido que crear ninguna.

**Why this priority**: Es la optimización que hace posible cumplir el presupuesto de tres segundos
en la práctica, no solo en el caso ideal: sin categorías pre-sembradas y ordenadas por uso, el
segundo toque del flujo se vuelve una búsqueda. Es P1 porque sin esto, la Historia 1 solo funciona
en una demo, no en el uso real.

**Independent Test**: Se puede probar por completo instalando la app por primera vez, confirmando
que el selector ya muestra categorías traducidas al idioma activo sin ninguna siembra manual, y
luego registrando varios gastos en la misma categoría para confirmar que esa categoría sube a la
primera posición del selector.

**Acceptance Scenarios**:

1. **Given** un primer arranque de la app, **When** se abre el selector de categorías por primera
   vez, **Then** ya existen categorías por defecto, sembradas automáticamente, mostradas en el
   idioma activo del dispositivo.
2. **Given** esas categorías por defecto, **When** se inspecciona cómo se almacena su nombre,
   **Then** cada una referencia una clave de traducción, nunca un texto literal fijo.
3. **Given** un historial de uso donde una categoría se ha elegido con más frecuencia que las demás,
   **When** se abre el selector de categorías, **Then** esa categoría aparece antes que las de menor
   frecuencia de uso, visible sin necesidad de desplazamiento.

---

### User Story 4 - Un fallo de escritura local nunca hace desaparecer el monto (Priority: P2)

En el caso excepcional de que el dispositivo no pueda escribir el gasto localmente — por ejemplo,
por falta de espacio de almacenamiento — la persona usuaria se entera sin que la app se detenga, y
el monto que ya había escrito sigue en pantalla, listo para reintentar.

**Why this priority**: Cubre el único caso de error real de esta ruta. Es P2 porque es una
condición excepcional, no el camino principal, pero sigue siendo necesaria para que la Historia 1 no
pierda datos en el peor caso — la ausencia de red nunca cae en este caso, por diseño de la Historia
1.

**Independent Test**: Se puede probar por completo simulando un fallo de escritura local al intentar
persistir un gasto y confirmando que se muestra un aviso no bloqueante, que el monto capturado
permanece visible, y que la app no queda en ningún estado bloqueado.

**Acceptance Scenarios**:

1. **Given** un intento de persistir un gasto que falla porque el dispositivo no puede escribir
   localmente, **When** ese fallo ocurre, **Then** se muestra un aviso no bloqueante con opción de
   reintentar, y el monto capturado no se pierde.
2. **Given** ese mismo escenario, **When** no hay conectividad de red pero la escritura local sí es
   posible, **Then** el gasto se registra con éxito de todas formas — la ausencia de red nunca activa
   este aviso.

---

### Edge Cases

- ¿Qué pasa si dos categorías tienen exactamente el mismo número de usos? Se desempata por
  `sortOrder` (el orden de siembra original), de forma estable, para que el orden del selector nunca
  cambie de forma impredecible entre aperturas.
- ¿Qué pasa si la persona escribe el monto máximo permitido (1,000,000.00) e intenta seguir
  escribiendo? La entrada adicional se ignora silenciosamente; el monto se congela en el máximo, sin
  mostrar ningún error.
- ¿Qué pasa si la persona toca "Borrar" con el monto ya vacío? No ocurre nada — no es una acción de
  navegación ni cierra ninguna pantalla.
- ¿Qué pasa si la persona manda la app a segundo plano con un monto parcialmente escrito, sin haber
  tocado "Siguiente"? Al reabrir la app, la pantalla de captura vuelve a su estado inicial vacío — no
  existe un borrador persistente en esta feature, consistente con que la única escritura ocurre tras
  elegir categoría.
- ¿Qué pasa si el fallo de escritura local persiste después de un reintento? El aviso permanece
  disponible y el monto capturado se conserva en pantalla indefinidamente, sin bloquear el resto de
  la interacción, hasta que la escritura tenga éxito o la persona abandone el intento.
- ¿Qué pasa si la sesión anónima de la feature 003 todavía no ha resuelto un identificador de
  usuario cuando se elige la categoría? El gasto se persiste localmente de inmediato y la
  sincronización al servidor queda en el buffer de pre-autenticación ya existente, sin que la
  persona note ninguna diferencia ni espera.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La app DEBE abrir directamente en la pantalla de captura de gasto como su única
  pantalla inicial, sin pantalla previa, dashboard, indicador de carga, ni pantalla de bienvenida.
- **FR-002**: El registro de un gasto DEBE completarse con exactamente dos toques después de
  escribir el monto — uno para avanzar, uno para elegir categoría — sin ningún paso de confirmación
  intermedio.
- **FR-003**: El tiempo transcurrido entre la apertura de la app y la persistencia local del gasto
  DEBE medirse mediante instrumentación (no estimarse) y su percentil 90 DEBE ser menor a tres
  segundos.
- **FR-004**: Al elegir una categoría, el sistema DEBE persistir el gasto localmente de inmediato,
  mostrar retroalimentación visual y háptica de éxito, y devolver la pantalla a su estado inicial
  lista para un nuevo registro, sin ninguna acción adicional de la persona usuaria.
- **FR-005**: La retroalimentación de éxito NO DEBE esperar ninguna confirmación del servidor; la
  escritura al caché local es, por sí sola, la señal de éxito.
- **FR-006**: El selector de categorías DEBE ordenar las categorías activas por su frecuencia de uso
  descendente (propia de la persona usuaria), de modo que la elección más probable esté visible sin
  necesidad de desplazamiento.
- **FR-007**: Las categorías por defecto DEBEN sembrarse automáticamente en el primer arranque de la
  app, cada una referenciando una clave de traducción (nunca un texto literal), y DEBEN mostrarse
  resueltas al idioma activo del dispositivo.
- **FR-008**: Los montos DEBEN capturarse y almacenarse como el objeto de valor `Money` en unidades
  mínimas enteras ya definido por la feature 003, sin ninguna operación aritmética de punto
  flotante, de forma que una secuencia de sumas de montos con centavos produzca siempre el total
  exacto.
- **FR-009**: El teclado de captura DEBE admitir un único separador decimal acorde al locale activo,
  limitar la entrada a dos decimales — ignorando dígitos adicionales sin mostrar error — y aplicar
  separadores de miles en vivo mientras la persona escribe, mediante `intl`.
- **FR-010**: Un monto igual a cero NO DEBE poder avanzar al siguiente paso: el control de avance
  permanece visible pero deshabilitado, sin alterar en ningún momento la disposición de la pantalla.
- **FR-011**: El monto capturable NO DEBE exceder 1,000,000.00; alcanzar ese límite DEBE congelar la
  entrada silenciosamente, sin mostrar ningún error.
- **FR-012**: La única condición de error visible en esta ruta es la imposibilidad de escribir el
  gasto localmente; DEBE comunicarse mediante un aviso no bloqueante con opción de reintentar, sin
  que el monto capturado se pierda en ningún momento.
- **FR-013**: La ausencia de conectividad de red NUNCA DEBE tratarse como una condición de error en
  esta ruta; el registro DEBE completarse localmente con éxito independientemente de la
  conectividad.
- **FR-014**: Si la sesión anónima de la feature 003 aún no ha resuelto un identificador de usuario
  en el momento de elegir la categoría, el gasto DEBE persistirse localmente de inmediato y la
  escritura al servidor DEBE apoyarse en el buffer de pre-autenticación ya existente, sin bloquear
  ni mostrar ningún indicador adicional a la persona usuaria.
- **FR-015**: Toda la pantalla DEBE construirse exclusivamente con los tokens del sistema de diseño
  (`app_colors`, `app_spacing`, `app_typography`) y con texto localizado en los cinco idiomas
  soportados — inglés, español, portugués, italiano y francés — sin strings embebidos en el código
  ni valores de color, espaciado o tipografía escritos como literales.
- **FR-016**: Borrar un dígito cuando el monto ya está vacío DEBE ser una operación sin efecto,
  nunca un evento de navegación.
- **FR-017**: Esta feature NO DEBE incluir pantalla de historial, edición o borrado de gastos, notas
  en el gasto, gestión manual de categorías (crear, renombrar, desactivar), navegación inferior,
  resumen mensual, ni ninguna pantalla de ajustes.

### Key Entities

- **Gasto**: un monto asociado a una categoría, capturado en el momento del registro. Esta feature
  crea la primera implementación de datos y presentación sobre la entidad `Expense` y la interfaz
  `ExpenseRepository` que la feature 003 dejó definidas; no modifica su forma.
- **Categoría**: una de las opciones que la persona usuaria elige para clasificar un gasto, mostrada
  con su nombre resuelto (clave de traducción para las categorías por defecto), color, ícono y
  frecuencia de uso propia. Esta feature es la primera en sembrar categorías por defecto y en
  implementar `CategoryRepository` sobre Firestore.
- **Monto**: el valor numérico que la persona escribe en el teclado, representado internamente por
  el objeto de valor `Money` (unidades mínimas enteras) ya definido por la feature 003.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El percentil 90 del tiempo medido, de forma instrumentada, entre la apertura de la
  app y la persistencia local de un gasto es menor a tres segundos.
- **SC-002**: El 100% de los registros de gasto exitosos requieren exactamente dos toques después de
  escribir el monto, sin ningún paso de confirmación intermedio.
- **SC-003**: El 100% de las aperturas de la app muestran la pantalla de captura de gasto como
  primera y única pantalla, sin pantalla ni indicador intermedio.
- **SC-004**: El 100% de las secuencias de suma de montos con centavos ya persistidos producen el
  total exacto esperado, sin desviación de redondeo.
- **SC-005**: El 100% de los registros exitosos muestran su retroalimentación de éxito sin esperar
  ninguna respuesta del servidor.
- **SC-006**: El selector de categorías presenta las categorías ordenadas de mayor a menor
  frecuencia de uso en el 100% de las aperturas.
- **SC-007**: El 100% de los intentos de avanzar con un monto en cero quedan bloqueados por el
  control de avance deshabilitado, sin que la disposición de la pantalla cambie.
- **SC-008**: El 100% de las pantallas de esta feature se muestran correctamente en los cinco
  idiomas soportados, sin recorte ni desbordamiento de texto a 200% de escala.

## Assumptions

- Esta feature es la primera implementación de datos y presentación para `expenses` y
  `categories`; consume las interfaces de dominio (`ExpenseRepository`, `CategoryRepository`,
  entidades `Expense`/`Category`/`Money`) y la sesión anónima con buffer de pre-autenticación ya
  definidas por la feature 003, sin modificarlas.
- El código de moneda activo (`currencyCode`) ya está determinado en el documento de usuario antes
  de esta feature; la selección o cambio de moneda queda fuera de alcance.
- La retroalimentación háptica respeta la preferencia `hapticsEnabled` ya modelada en el documento
  de usuario (`docs/DATA_MODEL.md`), asumida en verdadero por defecto hasta que exista una pantalla
  de ajustes que la exponga.
- El idioma activo del dispositivo determina tanto el separador decimal del teclado como las
  traducciones resueltas de las categorías por defecto, reutilizando el mecanismo de localización ya
  establecido por la feature 002.
- El desempate entre categorías con igual frecuencia de uso se resuelve por `sortOrder`, el orden de
  siembra original, para mantener un orden estable y predecible en el selector.
- Ninguna categoría creada manualmente por la persona usuaria existe todavía en esta feature — el
  selector solo mostrará las categorías por defecto sembradas al primer arranque, ya que la gestión
  manual de categorías queda fuera de alcance.
