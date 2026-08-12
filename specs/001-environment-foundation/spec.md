# Feature Specification: Fundación de Entornos (dev / prod)

**Feature Branch**: `001-environment-foundation`

**Created**: 2026-08-07

**Status**: Draft

**Input**: User description: "Fundación de entornos: dos flavors con proyectos Firebase separados. El proyecto Flutter existe y se puede compilar y ejecutar en dos variantes independientes, dev y prod, cada una escribiendo a su propio proyecto de Firebase, instalables simultáneamente en un mismo dispositivo sin conflicto."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Un desarrollador ejecuta la app contra el entorno de desarrollo (Priority: P1)

Un desarrollador que acaba de clonar el repositorio quiere levantar la app localmente sin ningún
riesgo de tocar datos reales de producción. Ejecuta el comando de la variante de desarrollo y la
app arranca, se conecta al proyecto Firebase de desarrollo, y se identifica visualmente como una
build de desarrollo.

**Why this priority**: Sin esto no hay forma de empezar a construir ninguna otra funcionalidad del
producto. Es el prerrequisito de todo el trabajo de features posterior (Fase 0 según el roadmap).

**Independent Test**: Se puede probar por completo ejecutando el comando de arranque de la
variante de desarrollo y observando que la app abre, muestra un indicador de entorno visible, y
cualquier dato que se escriba desde la pantalla mínima de verificación llega al proyecto Firebase
de desarrollo.

**Acceptance Scenarios**:

1. **Given** el repositorio recién clonado con las dependencias instaladas, **When** el
   desarrollador ejecuta la variante de desarrollo, **Then** la app arranca y queda conectada al
   proyecto Firebase de desarrollo.
2. **Given** la app de desarrollo corriendo, **When** el desarrollador mira la pantalla de la app,
   **Then** ve un indicador visible que confirma que está en el entorno de desarrollo.

---

### User Story 2 - Se genera una build de producción libre de artefactos de depuración (Priority: P1)

Antes de publicar la app en las tiendas, alguien necesita generar una build que se conecte
exclusivamente al proyecto Firebase de producción y que no exponga ningún indicador, menú o
comportamiento de depuración a los usuarios finales.

**Why this priority**: Es igual de crítico que la Historia 1: sin una build de producción limpia y
correctamente aislada, no hay forma segura de publicar la app ni de proteger los datos reales de
los usuarios. Ambas variantes deben existir para que la fundación de entornos esté completa.

**Independent Test**: Se puede probar por completo ejecutando el comando de arranque de la
variante de producción y confirmando que conecta al proyecto Firebase de producción y que ninguna
pantalla muestra indicadores de depuración.

**Acceptance Scenarios**:

1. **Given** el repositorio con las dependencias instaladas, **When** se ejecuta la variante de
   producción, **Then** la app arranca y queda conectada al proyecto Firebase de producción.
2. **Given** la app de producción corriendo, **When** el usuario navega por la pantalla mínima
   disponible, **Then** no encuentra ningún indicador, etiqueta o control de depuración.

---

### User Story 3 - Ambas variantes conviven en el mismo dispositivo sin interferirse (Priority: P2)

Un desarrollador o probador necesita tener instaladas al mismo tiempo la build de desarrollo y la
build de producción en su propio teléfono, para poder comparar comportamiento o hacer pruebas
exploratorias sin desinstalar una para probar la otra.

**Why this priority**: Es una consecuencia necesaria de un buen aislamiento de entornos, pero
depende de que las Historias 1 y 2 ya funcionen por separado; su valor es de conveniencia y
seguridad operativa (evita que alguien pruebe "producción" cuando en realidad tiene instalado
desarrollo) más que un bloqueador para empezar a construir features.

**Independent Test**: Se puede probar instalando ambas variantes en el mismo dispositivo físico o
emulador y confirmando que aparecen como dos apps distintas, cada una con su propio ícono, nombre y
datos, sin que instalar o desinstalar una afecte a la otra.

**Acceptance Scenarios**:

1. **Given** un dispositivo sin ninguna de las dos variantes instaladas, **When** se instalan la
   build de desarrollo y la build de producción una después de la otra, **Then** ambas quedan
   instaladas simultáneamente como aplicaciones separadas.
2. **Given** ambas variantes instaladas en el mismo dispositivo, **When** el usuario mira la
   pantalla de inicio, **Then** distingue cuál es cuál por nombre e ícono.
3. **Given** ambas variantes instaladas, **When** se desinstala una de ellas, **Then** la otra
   sigue funcionando sin cambios.

---

### User Story 4 - Los datos de un entorno nunca contaminan al otro (Priority: P1)

Alguien que trabaja registrando datos de prueba en desarrollo necesita la garantía absoluta de que
esos datos jamás aparecerán en producción, y viceversa: que la información real de producción
nunca queda expuesta o mezclada en el entorno de desarrollo.

**Why this priority**: Es el objetivo de negocio central de tener dos entornos separados. Si los
datos se mezclan, la fundación de entornos no cumplió su propósito, sin importar que los comandos
de arranque funcionen. Se marca P1 junto con las Historias 1 y 2 porque las tres, en conjunto,
constituyen el mínimo indispensable de esta feature.

**Independent Test**: Se puede probar de forma aislada escribiendo un documento de prueba desde la
pantalla mínima de verificación en la variante de desarrollo, y confirmando por separado, desde la
variante de producción, que ese documento no existe ahí — y repitiendo la prueba en la dirección
opuesta.

**Acceptance Scenarios**:

1. **Given** la variante de desarrollo corriendo, **When** se escribe un documento de prueba desde
   la pantalla mínima de verificación, **Then** el documento existe en el almacenamiento asociado
   al entorno de desarrollo.
2. **Given** ese mismo documento de prueba creado en desarrollo, **When** se abre la variante de
   producción y se consulta el mismo tipo de dato, **Then** el documento no aparece.
3. **Given** un documento de prueba creado en producción, **When** se consulta desde desarrollo,
   **Then** tampoco aparece.

---

### User Story 5 - Un build mal configurado falla de forma ruidosa en vez de conectar al proyecto equivocado (Priority: P2)

Un desarrollador comete el error, humano y previsible, de compilar con el flavor nativo `prod`
pero apuntando por accidente al punto de entrada de Dart de `dev` (o viceversa). En vez de que la
app arranque silenciosamente y escriba datos en el proyecto Firebase equivocado, el sistema debe
detectar la inconsistencia y detenerse con un mensaje claro.

**Why this priority**: Protege contra el error más costoso posible en un sistema de flavors (una
build de producción que termina hablando con el proyecto de desarrollo, o peor, datos de prueba
llegando a producción), pero es una salvaguarda sobre una fundación que ya debe funcionar
correctamente por default; de ahí su prioridad P2 relativa a las historias P1.

**Independent Test**: Se puede probar generando deliberadamente una combinación inconsistente
entre el flavor nativo y el punto de entrada de Dart, y confirmando que la app se detiene al
arrancar con un mensaje que identifica exactamente el desajuste, en lugar de continuar y conectar
silenciosamente a un proyecto Firebase.

**Acceptance Scenarios**:

1. **Given** una build compilada con el flavor nativo `prod`, **When** se arranca usando el punto
   de entrada de Dart correspondiente a `dev` (o viceversa), **Then** la app falla al arrancar y
   muestra un mensaje que identifica cuál es el flavor nativo y cuál el entorno de Dart en
   conflicto.
2. **Given** esa misma condición de desajuste, **When** ocurre el fallo, **Then** en ningún momento
   se establece conexión con ningún proyecto Firebase.

---

### User Story 6 - Las reglas de acceso a datos se despliegan igual a ambos entornos (Priority: P3)

Quien mantiene el proyecto necesita la certeza de que las reglas de seguridad y los índices que
protegen los datos en producción son exactamente los mismos que ya se probaron en desarrollo,
desplegados desde los mismos archivos, y que el comando de despliegue usado sin especificar
entorno nunca aterriza en producción por accidente.

**Why this priority**: Es esencial para la integridad a largo plazo del sistema de entornos, pero
no bloquea el poder empezar a construir y probar features con las Historias 1-5 ya resueltas; es
una garantía operativa que se verifica una vez que la fundación básica ya existe.

**Independent Test**: Se puede probar desplegando las reglas e índices a ambos proyectos desde el
mismo conjunto de archivos y comparando que el resultado desplegado es idéntico en ambos, y
además ejecutando el comando de despliegue sin indicar explícitamente el entorno y confirmando que
el destino fue desarrollo.

**Acceptance Scenarios**:

1. **Given** un conjunto de reglas e índices en el repositorio, **When** se despliegan a los dos
   proyectos Firebase, **Then** ambos proyectos terminan con exactamente las mismas reglas e
   índices.
2. **Given** el comando de despliegue ejecutado sin especificar explícitamente un entorno,
   **When** el despliegue se completa, **Then** el entorno afectado fue el de desarrollo, nunca
   producción.

---

### Edge Cases

- ¿Qué pasa si alguien intenta escribir datos de prueba en producción desde la pantalla mínima de
  verificación? La variante de producción no debe ofrecer ninguna vía para crear documentos de
  prueba; esa capacidad existe únicamente en la variante de desarrollo.
- ¿Qué pasa si el dispositivo no tiene conexión a internet al momento de escribir el documento de
  prueba? La escritura debe quedar registrada localmente y sincronizarse en cuanto haya
  conectividad, sin que la ausencia de red se trate como un error visible para quien prueba (ver
  Principio 2 de la constitución del proyecto: offline-first).
- ¿Qué pasa si se intenta compilar sin especificar el punto de entrada de Dart en absoluto? La
  compilación debe fallar de forma explícita porque no existe un punto de entrada por default.
- ¿Qué pasa si alguien intenta desplegar las reglas apuntando a producción? El sistema debe exigir
  una confirmación humana explícita antes de proceder; no debe ser una operación de un solo paso
  accidental.
- ¿Qué pasa si la app se instala por primera vez sin ninguna conectividad disponible? La sesión
  anónima silenciosa de FR-015 requiere red la primera vez que se establece (igual que la primera
  sincronización de Firestore); en ese caso, el intento de escribir un documento de prueba espera
  a que haya conectividad para completarse, en lugar de fallar de forma visible — no se trata como
  un error, sino como una condición temporal (ver Principio 2 de la constitución).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE ofrecer dos variantes de arranque completamente independientes,
  identificadas como `dev` y `prod`, cada una a través de su propio comando de arranque explícito.
- **FR-002**: Cada variante DEBE conectarse exclusivamente a su propio proyecto de backend: la
  variante `dev` únicamente al proyecto de desarrollo, la variante `prod` únicamente al proyecto de
  producción. Ninguna variante debe poder alcanzar el proyecto de la otra bajo condiciones
  normales de arranque.
- **FR-003**: Las dos variantes DEBEN poder instalarse y coexistir en el mismo dispositivo físico
  o emulador de forma simultánea, sin que instalar, actualizar o desinstalar una afecte a la otra.
- **FR-004**: Cada variante instalada DEBE mostrar un nombre y un ícono en la pantalla de inicio
  del dispositivo que la distingan claramente de la otra variante.
- **FR-005**: La variante `dev` DEBE mostrar, en algún punto visible de su interfaz, un indicador
  que confirme sin ambigüedad que se trata del entorno de desarrollo.
- **FR-006**: La variante `prod` NO DEBE mostrar ningún indicador, etiqueta, menú o control de
  depuración en ninguna pantalla.
- **FR-007**: El sistema DEBE proveer una vía, disponible únicamente en la variante `dev`, para
  escribir un documento de prueba identificable, con el propósito exclusivo de verificar el
  aislamiento de datos entre entornos.
- **FR-008**: Un documento de prueba escrito desde la variante `dev` NUNCA DEBE ser visible ni
  accesible desde la variante `prod`, y un documento equivalente escrito desde `prod` NUNCA DEBE
  ser visible desde `dev`.
- **FR-015**: El sistema DEBE establecer una sesión anónima silenciosa, sin ninguna pantalla ni
  interacción visible para quien usa la app, antes de permitir cualquier escritura hacia el
  backend, exclusivamente como mecanismo para que las reglas de acceso puedan exigir una sesión
  válida en lugar de permitir escrituras de cualquier origen no identificado. Esto no introduce
  ninguna funcionalidad de inicio de sesión visible ni de vinculación de cuentas — ver Assumptions.
- **FR-009**: El sistema DEBE detectar, al momento de arrancar, cualquier inconsistencia entre el
  flavor de compilación nativo y el entorno de Dart con el que fue empaquetado, y DEBE detener el
  arranque con un mensaje que identifique explícitamente cuáles son los dos valores en conflicto,
  antes de establecer ninguna conexión con un proyecto backend.
- **FR-010**: Compilar o ejecutar sin especificar de forma explícita tanto el flavor como el punto
  de entrada correspondiente DEBE fallar de forma clara, en lugar de ejecutar silenciosamente
  contra un entorno por default.
- **FR-011**: Las reglas de acceso a datos y los índices asociados DEBEN desplegarse a ambos
  proyectos backend a partir del mismo conjunto de archivos versionados en el repositorio; no debe
  existir una copia separada de reglas por entorno.
- **FR-012**: El comando de despliegue de reglas e índices, cuando se ejecuta sin indicar
  explícitamente un entorno, DEBE dirigirse siempre al proyecto de desarrollo.
- **FR-013**: Desplegar reglas, índices, o cualquier cambio hacia el proyecto de producción DEBE
  requerir una confirmación explícita separada del comando por default; no debe ocurrir como
  efecto colateral de un comando genérico.
- **FR-014**: Fuera de la pantalla mínima de verificación (indicador de entorno + capacidad de
  escribir un documento de prueba en `dev`), el sistema NO DEBE incluir ninguna otra
  funcionalidad de producto en esta feature — sin teclado numérico, registro de gastos,
  categorías, ni pantallas o flujos de autenticación visibles para la persona usuaria. La sesión
  anónima silenciosa de FR-015 es infraestructura, no una funcionalidad de producto, y no cuenta
  como excepción a esta regla.

### Key Entities

- **Documento de prueba**: Un registro mínimo, sin significado de negocio, cuyo único propósito es
  demostrar que una escritura realizada desde un entorno queda confinada a ese entorno. No
  representa un gasto, categoría, ni ninguna otra entidad futura del producto.
- **Entorno**: Una de dos configuraciones con nombre (`dev`, `prod`) que determina a qué proyecto
  backend se conecta la app, si se muestra un indicador de depuración, y si está permitido escribir
  documentos de prueba.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Una persona que sigue el comando de arranque documentado para `dev` obtiene la app
  corriendo y conectada al entorno de desarrollo en un solo intento, sin pasos adicionales no
  documentados.
- **SC-002**: Una persona que sigue el comando de arranque documentado para `prod` obtiene la app
  corriendo y conectada al entorno de producción en un solo intento, sin pasos adicionales no
  documentados.
- **SC-003**: El 100% de los documentos de prueba escritos en un entorno permanecen invisibles
  desde el otro entorno, verificado repitiendo la prueba en ambas direcciones.
- **SC-004**: Ambas variantes permanecen instaladas y funcionando correctamente después de
  instalar, usar y desinstalar la otra variante en el mismo dispositivo, sin pérdida de datos ni
  fallos.
- **SC-005**: Toda combinación inconsistente entre flavor nativo y entorno de Dart es detectada
  antes de que ocurra cualquier intento de conexión a un proyecto backend, el 100% de las veces
  que se produce esa combinación.
- **SC-006**: Una comparación de las reglas de acceso e índices desplegados en ambos proyectos no
  muestra ninguna diferencia entre sí.
- **SC-007**: Ejecutar el comando de despliegue sin especificar entorno nunca resulta, en ninguna
  ejecución, en un cambio aplicado al proyecto de producción.

## Assumptions

- Existe ya una decisión sobre los identificadores de entorno documentada en `docs/ENVIRONMENTS.md`
  (nombre de la organización, identificadores de aplicación, IDs de proyecto); esta especificación
  no redefine esos valores, solo exige que el resultado final los respete.
- La "pantalla mínima de verificación" es una única vista temporal que existe solo para cumplir el
  criterio de aislamiento de datos (Historia 4) y se espera que sea reemplazada por pantallas de
  producto reales en features posteriores; no forma parte del producto final.
- El dispositivo o emulador usado para verificar la coexistencia de ambas variantes (Historia 3)
  tiene espacio de almacenamiento suficiente para tener ambas instaladas al mismo tiempo.
- Ninguna funcionalidad de autenticación *visible* (pantallas de inicio de sesión, vinculación de
  cuentas Google/Apple, gestión de cuenta) está en el alcance de esta feature — eso sigue siendo
  Fase 3 según `ROADMAP.md`. Sin embargo, esta feature sí adelanta la sesión anónima silenciosa
  (FR-015) desde `ROADMAP.md` Fase 1, exclusivamente porque las reglas de acceso a datos exigen
  una sesión autenticada para cualquier escritura, y verificar el aislamiento de datos (Historia 4)
  requiere que esa escritura efectivamente ocurra. El documento de prueba no necesita estar
  asociado a un usuario específico — solo a *alguna* sesión autenticada — para cumplir su
  propósito de verificación.
- Quien ejecute el despliegue de reglas hacia producción es un humano con las credenciales
  correspondientes; esta feature no automatiza esa confirmación, solo exige que exista como paso
  separado.
