# Feature Specification: Cuentas Vinculadas e Integridad de la Aplicación

**Feature Branch**: `007-account-linking-integrity`

**Created**: 2026-08-12

**Status**: Draft

**Input**: User description: "Cuentas vinculadas e integridad de la aplicación. Resultado
esperado: el usuario puede conservar su historial al cambiar o perder el dispositivo, sin que se
le haya exigido crear una cuenta en ningún momento previo, y el acceso a los datos está protegido
contra clientes no legítimos. Criterios de aceptación: (1) vincular una cuenta es siempre
opcional y se ofrece desde ajustes, nunca como interrupción ni como requisito para usar la
aplicación; (2) al vincular, todo el historial acumulado de forma anónima se conserva y queda
asociado a la cuenta, sin pérdida ni duplicación; (3) tras vincular en un dispositivo, instalar
en otro e iniciar sesión con la misma cuenta recupera el historial completo; (4) si la cuenta
elegida ya está asociada a otro historial, la situación se comunica con claridad y el usuario
decide qué ocurre con cada conjunto de datos, sin que se descarte nada sin decisión explícita;
(5) vincular sin conexión no corrompe el estado — se comunica como no disponible y el historial
local permanece intacto; (6) el acceso desde clientes no legítimos queda bloqueado sin afectar la
app instalada legítimamente; (7) existe un modo de depuración que permite que las compilaciones
de desarrollo sigan funcionando bajo esa protección; (8) el usuario puede eliminar su cuenta y
todos sus datos de forma permanente, con confirmación explícita, cumpliendo el requisito de
ambas tiendas; (9) ajustes permite gestionar categorías — crear, renombrar, cambiar color e
icono, reordenar y archivar, sin afectar gastos históricos; (10) renombrar una categoría por
defecto la convierte en categoría de usuario y deja de traducirse; (11) el usuario puede cambiar
moneda y zona horaria, sin que cambiar la zona horaria reasigne gastos ya registrados a otro mes;
(12) toda la pantalla usa los tokens del sistema de diseño y está localizada en los cinco
idiomas. Fuera de alcance: exportación de datos, compartir cuentas entre usuarios, roles,
suscripciones, y cualquier forma de sincronización con servicios de terceros."

## User Scenarios & Testing *(mandatory)*

<!--
  Esta es la feature de docs/ROADMAP.md Fase 3 ("Accounts, Integrity & Management"). Introduce la
  pantalla de Ajustes por primera vez — ninguna feature anterior la construyó (004/005/006 todas
  dejaron constancia explícita de que Ajustes quedaba fuera de su alcance). También es la primera
  vez que el proyecto añade un método de inicio de sesión real (Google/Apple) sobre el anónimo que
  existe desde la 003, y la primera vez que se despliega App Check.
-->

### User Story 1 - Vincular una cuenta sin perder nada (Priority: P1)

Una persona que ha estado usando la app de forma completamente anónima decide, por su cuenta y
desde Ajustes, vincular una cuenta (Google o Apple). Todo lo que había registrado hasta ese
momento —cada gasto, cada categoría que creó— sigue exactamente igual después de vincular, ahora
asociado a esa cuenta.

**Why this priority**: Es la mitad de la promesa central de esta feature — sin poder vincular sin
pérdida de datos, la feature no tiene valor. Es P1 porque es el punto de entrada de todo lo demás:
ninguna otra historia de esta feature tiene sentido si vincular no es seguro.

**Independent Test**: Se puede probar por completo registrando varios gastos y categorías de forma
anónima, vinculando una cuenta desde Ajustes, y confirmando que el historial completo —cada gasto,
cada categoría, sin duplicados— sigue presente y accesible inmediatamente después.

**Acceptance Scenarios**:

1. **Given** una persona usando la app sin haber vinculado cuenta nunca, **When** abre Ajustes,
   **Then** ve una opción para vincular una cuenta, presentada como una acción disponible, no como
   una interrupción de ningún flujo.
2. **Given** un historial de varios gastos y categorías registrados de forma anónima, **When** la
   persona vincula una cuenta, **Then** cada gasto y cada categoría del historial anterior sigue
   existiendo, sin duplicados, ahora asociado a esa cuenta.
3. **Given** la app recién instalada, **When** la persona la usa sin tocar Ajustes en ningún
   momento, **Then** nunca se le pide ni se le sugiere de forma interruptiva crear o vincular una
   cuenta.

---

### User Story 2 - Recuperar el historial en un dispositivo nuevo (Priority: P1)

La misma persona cambia de teléfono, o pierde el que tenía. Instala la app en el dispositivo
nuevo, inicia sesión con la cuenta que vinculó antes, y encuentra ahí todo su historial, completo.

**Why this priority**: Es la otra mitad de la promesa central — "conservar su historial al cambiar
o perder el dispositivo" es literalmente el resultado esperado de esta feature. Sin esto, vincular
una cuenta (US1) no habría servido para nada.

**Independent Test**: Se puede probar vinculando una cuenta en un dispositivo con historial
conocido, luego iniciando sesión con esa misma cuenta desde una instalación distinta (o un estado
completamente limpio) y confirmando que el historial completo aparece, sin pasos adicionales.

**Acceptance Scenarios**:

1. **Given** una cuenta ya vinculada a un historial en el dispositivo A, **When** la persona
   instala la app en el dispositivo B e inicia sesión con esa misma cuenta, **Then** ve el
   historial completo del dispositivo A, sin necesidad de ninguna acción adicional.

---

### User Story 3 - Ninguna decisión de datos se toma en automático (Priority: P1)

Una persona intenta vincular una cuenta que —sin que lo supiera, quizás por haberla usado antes en
otro dispositivo— ya tiene su propio historial guardado. Ahora hay dos conjuntos de datos en
juego: el que trae este dispositivo (anónimo) y el que ya tenía esa cuenta. La app no elige por
ella; se lo explica con claridad y le pide que decida.

**Why this priority**: Es la salvaguarda que hace segura a US1 en el caso que de otro modo sería
más peligroso: perder datos silenciosamente. Es P1 porque un solo caso de pérdida silenciosa de
datos rompe la confianza en toda la promesa de esta feature.

**Independent Test**: Se puede probar preparando una cuenta que ya tiene historial propio,
generando además historial anónimo distinto en el dispositivo, intentando vincular esa cuenta, y
confirmando que la app presenta la situación con claridad y ofrece opciones explícitas — nunca
progresa sin que la persona elija.

**Acceptance Scenarios**:

1. **Given** una cuenta que ya tiene su propio historial asociado, **When** la persona intenta
   vincularla desde un dispositivo con historial anónimo distinto, **Then** la app le informa
   claramente que existen dos historiales y le presenta opciones explícitas para decidir qué
   ocurre con cada uno — nunca combina, reemplaza ni descarta ninguno por su cuenta.
2. **Given** esa misma situación, **When** la persona elige conservar ambos historiales
   combinados, **Then** el resultado final incluye la totalidad de ambos conjuntos de datos, sin
   pérdidas.
3. **Given** esa misma situación, **When** la persona elige conservar solo el historial ya
   asociado a la cuenta y descartar el del dispositivo, **Then** esa es una decisión que tomó
   explícitamente — la app se lo pidió confirmar como tal, nombrando lo que se va a descartar,
   antes de proceder.

---

### User Story 4 - Vincular sin conexión no rompe nada (Priority: P2)

La persona intenta vincular una cuenta en un momento en que no tiene conexión a internet. La app
no se queda en un estado a medias: le dice que no puede completar la acción ahora mismo, y su
historial local sigue exactamente igual de intacto y utilizable que antes de intentarlo.

**Why this priority**: Es un endurecimiento de US1 frente a un caso real y común (el dispositivo
sin señal), no una capacidad nueva — por eso es P2 en vez de P1: la app ya es correcta sin
conexión en todo lo demás (Principio 2 de la constitución), y esto extiende esa misma garantía al
único flujo nuevo que introduce una dependencia real de red.

**Independent Test**: Se puede probar intentando vincular una cuenta con el dispositivo en modo
avión, confirmando que la app comunica la imposibilidad de completar la acción, y que el registro
y la revisión de gastos siguen funcionando con total normalidad después del intento fallido.

**Acceptance Scenarios**:

1. **Given** el dispositivo sin conexión de red, **When** la persona intenta vincular una cuenta,
   **Then** la app comunica que la acción no está disponible en este momento, sin quedar en un
   estado ambiguo ni a medio completar.
2. **Given** ese intento fallido, **When** la persona continúa usando la app, **Then** todo su
   historial local sigue intacto y el registro de nuevos gastos sigue funcionando con normalidad.

---

### User Story 5 - Solo la aplicación legítima puede acceder a los datos (Priority: P1)

Cada gasto que alguien registra es información financiera sensible. Esta historia asegura que
solo la aplicación real, instalada de forma legítima, puede leer o escribir esos datos — un
cliente falsificado o un script que se hace pasar por la app queda bloqueado, sin que la persona
que usa la app real note ninguna diferencia. Quien desarrolla la app, en cambio, puede seguir
trabajando con normalidad en las compilaciones de desarrollo.

**Why this priority**: Es la otra mitad del resultado esperado de esta feature ("el acceso a los
datos está protegido contra clientes no legítimos"), independiente de si la persona vinculó una
cuenta o sigue siendo anónima — protege a todo el mundo por igual. P1 porque es una capa de
seguridad, no una conveniencia.

**Independent Test**: Se puede probar confirmando que una solicitud a la base de datos que no
proviene de una instancia verificada de la aplicación es rechazada, mientras que la aplicación
instalada legítimamente —incluyendo una compilación de desarrollo, usando su mecanismo de
depuración— sigue leyendo y escribiendo con normalidad.

**Acceptance Scenarios**:

1. **Given** una solicitud a los datos que no proviene de una instancia verificada de la
   aplicación, **When** esa solicitud llega, **Then** se rechaza.
2. **Given** la aplicación instalada legítimamente en un dispositivo, **When** una persona la usa
   con normalidad, **Then** ninguna operación se ve afectada por esta protección.
3. **Given** una compilación de desarrollo, **When** se ejecuta con su mecanismo de depuración
   habilitado, **Then** puede leer y escribir datos con normalidad bajo la misma protección —sin
   necesidad de desactivarla— y ese mecanismo no existe en absoluto en una compilación de
   producción.

---

### User Story 6 - Eliminar la cuenta y los datos, de forma permanente (Priority: P2)

Una persona decide que ya no quiere que la app conserve su información. Desde la propia app,
confirma explícitamente que quiere eliminar su cuenta, y a partir de ese momento ni la cuenta ni
ninguno de sus datos existen ya en ningún sitio accesible.

**Why this priority**: Es un requisito de cumplimiento de ambas tiendas de aplicaciones, no
opcional para publicar — pero es una acción independiente y autocontenida frente al resto de la
feature (no bloquea ni es bloqueada por vincular cuentas o gestionar categorías), por lo que P2 es
apropiado.

**Independent Test**: Se puede probar iniciando sesión con una cuenta que tiene datos, solicitando
la eliminación, confirmándola explícitamente, y verificando que ni la cuenta ni ninguno de sus
gastos o categorías son accesibles después.

**Acceptance Scenarios**:

1. **Given** una cuenta vinculada con datos, **When** la persona solicita eliminarla desde la app,
   **Then** se le pide una confirmación explícita antes de proceder — la eliminación nunca ocurre
   de un solo toque accidental.
2. **Given** esa confirmación explícita, **When** se completa la eliminación, **Then** ni la
   cuenta ni ninguno de sus gastos o categorías siguen siendo accesibles, de forma permanente.

---

### User Story 7 - Gestionar categorías desde Ajustes (Priority: P2)

Una persona quiere que sus categorías reflejen mejor cómo gasta: crea una nueva, le cambia el
color a una existente, renombra una que ya no le sirve tal como está, cambia el orden en que
aparecen, y archiva una que ya no usa — todo desde Ajustes, sin que nada de eso afecte los gastos
que ya registró con esas categorías.

**Why this priority**: Es valioso y estaba comprometido para esta fase, pero es independiente de
la promesa central de cuentas/integridad de esta feature — la app ya funciona plenamente sin él
(las categorías por defecto cubren el uso normal). P2 porque extiende, no bloquea, el resto de la
feature.

**Independent Test**: Se puede probar creando, renombrando, recoloreando, reordenando y archivando
categorías desde Ajustes, y confirmando en cada caso que los gastos históricos que referencian esa
categoría no cambian y siguen mostrándose correctamente.

**Acceptance Scenarios**:

1. **Given** la pantalla de gestión de categorías en Ajustes, **When** la persona crea una
   categoría nueva, **Then** queda disponible de inmediato en el selector de categorías de la
   captura.
2. **Given** una categoría existente, **When** la persona le cambia el nombre, color, icono, o
   posición, **Then** el cambio se refleja de inmediato y ningún gasto histórico que la referencia
   cambia de valor ni deja de mostrarse correctamente.
3. **Given** una categoría con gastos históricos asociados, **When** la persona la archiva,
   **Then** deja de aparecer en el selector de captura, pero cada gasto histórico que la referencia
   sigue existiendo y mostrándose con esa categoría con normalidad.

---

### User Story 8 - Cambiar moneda y zona horaria (Priority: P3)

Una persona se muda de país, o simplemente se equivocó al configurar su zona horaria o moneda al
principio. Desde Ajustes, las cambia. Nada de lo que ya registró se ve alterado por ese cambio.

**Why this priority**: Es la historia más autocontenida y de menor alcance de esta feature —dos
campos de preferencia con un guardado directo— por lo que P3 es apropiado frente al resto.

**Independent Test**: Se puede probar registrando gastos, cambiando la zona horaria y la moneda
desde Ajustes, y confirmando que ningún gasto ya registrado cambia de mes o de cifra como
consecuencia de ese cambio.

**Acceptance Scenarios**:

1. **Given** gastos ya registrados en un mes determinado, **When** la persona cambia su zona
   horaria desde Ajustes, **Then** esos gastos permanecen asignados al mismo mes que antes del
   cambio.
2. **Given** la moneda configurada, **When** la persona la cambia desde Ajustes, **Then** los
   gastos ya registrados conservan la cifra y la moneda con la que fueron guardados originalmente.

---

### Edge Cases

- ¿Qué pasa si la persona intenta vincular una cuenta que ya está vinculada a este mismo
  historial (por ejemplo, tras un reintento)? La app lo reconoce como ya vinculado y no lo trata
  como un conflicto de historiales distintos.
- ¿Qué pasa si la persona cierra la app a mitad del proceso de vinculación? El estado anónimo
  original permanece intacto y utilizable hasta que una vinculación se complete con éxito de
  principio a fin — no hay un estado "a medio vincular" persistente.
- ¿Qué pasa si se intenta archivar la última categoría activa, dejando el selector de captura sin
  ninguna opción? La ruta de captura es sagrada (Principio 1 de la constitución) y nunca puede
  quedarse sin al menos una categoría disponible; archivar la última categoría activa se impide o
  se comunica claramente en el momento.
- ¿Qué pasa si alguien elimina su cuenta mientras tiene la app abierta en otro dispositivo con la
  misma sesión? La siguiente operación de ese otro dispositivo contra los datos ya no encuentra
  nada que leer o escribir, de forma consistente con que la cuenta y sus datos ya no existen.
- ¿Qué pasa si se renombra una categoría por defecto a un texto vacío? La app no permite guardar
  un nombre de categoría vacío.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Vincular una cuenta DEBE presentarse únicamente como una acción disponible desde
  Ajustes — nunca como una interrupción del flujo de captura, ni como un requisito para registrar
  gastos, revisar el historial, o usar cualquier otra parte de la aplicación.
- **FR-002**: Vincular una cuenta DEBE conservar la totalidad del historial de gastos y categorías
  acumulado de forma anónima hasta ese momento, sin pérdida ni duplicación de ningún registro.
- **FR-003**: Iniciar sesión con una cuenta ya vinculada, desde cualquier instalación de la
  aplicación, DEBE recuperar el historial completo asociado a esa cuenta.
- **FR-004**: Si la cuenta que se intenta vincular ya tiene su propio historial asociado, el
  sistema DEBE comunicar esa situación con claridad antes de proceder, y DEBE presentar opciones
  explícitas sobre qué hacer con cada conjunto de datos en juego.
- **FR-005**: Ningún dato DEBE descartarse como consecuencia de un conflicto de vinculación sin
  que la persona lo haya elegido explícitamente, nombrando lo que se descarta.
- **FR-006**: Intentar vincular una cuenta sin conexión de red DEBE comunicarse como una acción no
  disponible en ese momento, sin corromper ni alterar el historial local existente.
- **FR-007**: El acceso a los datos DEBE rechazarse cuando la solicitud no proviene de una
  instancia verificada de la aplicación legítima.
- **FR-008**: Esta protección NO DEBE afectar ninguna operación normal de la aplicación instalada
  legítimamente, en ningún dispositivo.
- **FR-009**: DEBE existir un mecanismo de depuración que permita que las compilaciones de
  desarrollo seguidas operando bajo la misma protección, sin desactivarla; ese mecanismo NO DEBE
  existir en las compilaciones de producción.
- **FR-010**: El usuario DEBE poder eliminar su cuenta y la totalidad de sus datos de forma
  permanente desde dentro de la aplicación, tras una confirmación explícita distinta del gesto que
  la solicita.
- **FR-011**: Una vez completada la eliminación, ni la cuenta ni ninguno de sus datos DEBEN seguir
  siendo accesibles, de forma permanente.
- **FR-012**: Ajustes DEBE permitir crear, renombrar, cambiar color, cambiar icono, reordenar, y
  archivar categorías.
- **FR-013**: Archivar una categoría DEBE ocultarla del selector de categorías de la captura, sin
  alterar ni ocultar ningún gasto histórico que la referencia.
- **FR-014**: Renombrar una categoría por defecto DEBE convertirla en una categoría de usuario —
  deja de resolverse por traducción y pasa a conservar el texto literal que la persona escribió,
  según el invariante ya establecido en `docs/DATA_MODEL.md`.
- **FR-015**: El usuario DEBE poder cambiar su moneda y su zona horaria configuradas desde
  Ajustes.
- **FR-016**: Cambiar la zona horaria configurada NO DEBE reasignar a otro mes ningún gasto ya
  registrado.
- **FR-017**: Cambiar la moneda configurada NO DEBE alterar la cifra ni la moneda con la que ya
  fue guardado ningún gasto existente — el cambio afecta únicamente a los gastos que se registren
  a partir de ese momento.
- **FR-018**: Toda pantalla introducida por esta feature DEBE construirse con los tokens del
  sistema de diseño existentes y presentarse localizada en los cinco idiomas soportados.
- **FR-019**: Esta feature NO DEBE incluir exportación de datos, compartir una cuenta entre varias
  personas, roles de usuario, suscripciones, ni ninguna forma de sincronización con servicios de
  terceros ajenos a los ya establecidos para autenticación y almacenamiento.

### Key Entities

- **Cuenta vinculada**: la identidad persistente (Google o Apple) a la que una sesión, antes
  puramente anónima, queda asociada. Una cuenta vinculada puede acceder a su historial desde
  cualquier instalación de la aplicación en la que se inicie sesión con ella.
- **Conflicto de vinculación**: la situación detectada cuando la cuenta elegida para vincular ya
  tiene un historial propio distinto del historial anónimo del dispositivo actual — resuelta
  siempre por una decisión explícita de la persona, nunca de forma automática.
- **Categoría**: ya definida en `docs/DATA_MODEL.md`; esta feature añade las operaciones de
  gestión (crear, renombrar, recolorear, reordenar, archivar) sobre la entidad existente, sin
  cambiar su forma.
- **Preferencias de cuenta**: moneda y zona horaria configuradas, editables de forma independiente
  entre sí y sin efecto retroactivo sobre gastos ya registrados.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los historiales anónimos permanecen completos —cada gasto y cada
  categoría, sin pérdidas ni duplicados— inmediatamente después de vincular una cuenta.
- **SC-002**: El 100% de los inicios de sesión con una cuenta ya vinculada, desde una instalación
  distinta a la original, recuperan el historial completo asociado a esa cuenta.
- **SC-003**: El 100% de los conflictos de vinculación (cuenta con historial propio distinto)
  resultan en una decisión explícita de la persona antes de que cualquier dato se combine,
  reemplace o descarte.
- **SC-004**: El 100% de los intentos de vinculación sin conexión de red dejan el historial local
  exactamente igual de íntegro y utilizable que antes del intento.
- **SC-005**: El 100% de las solicitudes de acceso a datos que no provienen de una instancia
  verificada de la aplicación son rechazadas, con cero solicitudes legítimas afectadas.
- **SC-006**: El 100% de las eliminaciones de cuenta confirmadas dejan la cuenta y sus datos
  permanentemente inaccesibles.
- **SC-007**: El 100% de los gastos históricos permanecen sin cambios (cifra, moneda, categoría
  visible, mes asignado) tras cualquier operación de gestión de categorías, cambio de moneda, o
  cambio de zona horaria.
- **SC-008**: El 100% de las pantallas de esta feature se muestran correctamente en los cinco
  idiomas soportados, usando los tokens del sistema de diseño existentes.

## Assumptions

- **La eliminación de cuenta (criterio 8) adelanta una porción del alcance documentado en
  `docs/ROADMAP.md` Fase 4** ("Account deletion flow (required by both stores)"). Se incluye aquí
  tal como la pidió explícitamente el criterio de aceptación 8; a diferencia de la enmienda de
  `docs/ROADMAP.md` que hizo la feature 005, esta vez no se modifica el ROADMAP, ya que el criterio
  de aceptación no lo solicitó — se deja constancia aquí para que quede claro que Fase 4 tendrá ese
  ítem ya resuelto de antemano cuando se llegue a él.
- **Cambiar la moneda configurada (criterio 11) requirió una corrección de `docs/DATA_MODEL.md`**:
  el texto anterior decía que `currencyCode` "se elige una vez" — eso nunca fue cierto de
  `timeZone` (ya documentado como editable) y no había ninguna razón real para que lo fuera de
  `currencyCode`. El anti-goal constitucional es la *conversión* entre monedas (Principio 3), no la
  posibilidad de cambiar la preferencia hacia adelante. Se corrigió `docs/DATA_MODEL.md` en el
  mismo commit que esta especificación — una enmienda de documentación, no constitucional, con el
  mismo criterio que la enmienda de `docs/ROADMAP.md` de la feature 005.
- **El mecanismo de depuración del criterio 7** se resuelve con el proveedor de depuración propio
  del sistema de integridad de la aplicación (equivalente, del lado de la plataforma, a como ya
  funciona hoy el banner de `dev` de la Fase 0: visible y activo solo en compilaciones `dev`,
  estructuralmente ausente de `prod`) — el mecanismo exacto es una decisión de planificación, no de
  esta especificación.
- **La resolución de un conflicto de vinculación (criterio 4)** ofrece, como mínimo, dos caminos
  explícitos: combinar ambos historiales en uno solo, o conservar únicamente el historial ya
  asociado a la cuenta y descartar explícitamente el del dispositivo actual — nunca un descarte
  implícito. La interfaz exacta de esa decisión es una decisión de planificación.
