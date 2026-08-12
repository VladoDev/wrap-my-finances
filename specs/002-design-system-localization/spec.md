# Feature Specification: Sistema de Diseño y Fundación de Localización

**Feature Branch**: `002-design-system-localization`

**Created**: 2026-08-08

**Status**: Draft

**Input**: User description: "Sistema de diseño y fundación de localización. Resultado esperado: existe un sistema de diseño consumible y una infraestructura de localización completa en cinco idiomas, verificables mediante tests, sin que exista todavía ninguna pantalla de producto. Fuera de alcance: el esquema de color oscuro, teclado numérico, categorías, gastos, autenticación, y cualquier pantalla de producto. Esta feature entrega piezas, no flujos."

## User Scenarios & Testing *(mandatory)*

<!--
  Esta feature no entrega pantallas de producto — entrega piezas reutilizables (tokens,
  componentes primitivos, infraestructura de idioma) que las features futuras consumirán. Por
  eso las "personas usuarias" de estas historias son, en su mayoría, quienes construyen sobre
  estas piezas (desarrolladores, CI) y, donde corresponde, la persona final que verá el
  resultado de esas piezas una vez montadas en una pantalla real de una feature posterior.
-->

### User Story 1 - Construir un componente sin escribir un valor de diseño literal (Priority: P1)

Quien desarrolla una pantalla nueva en cualquier feature futura necesita poder construir esa
pantalla usando exclusivamente nombres semánticos (`background`, `onSurface`, `spacingMd`, etc.)
resueltos desde el tema activo, sin tener que escribir ni conocer un valor hexadecimal, un tamaño
de fuente o un número de píxeles concreto en ningún widget.

**Why this priority**: Es la razón de existir de esta feature. Si los tokens no son consumibles de
esta forma, no hay sistema de diseño — solo una paleta documentada que cada feature reinterpreta a
su manera, que es exactamente el problema que el Principio 9 de la constitución prohíbe.

**Independent Test**: Se puede probar por completo construyendo un widget de prueba que consuma
únicamente tokens desde el `BuildContext` y confirmando, mediante un test o lint automatizado, que
ningún archivo fuera del archivo único de definición de paleta contiene un literal hexadecimal de
color.

**Acceptance Scenarios**:

1. **Given** el sistema de diseño instalado, **When** un desarrollador necesita un color, una
   tipografía, un radio de borde o un espaciado para un widget, **Then** obtiene ese valor
   resuelto desde el `BuildContext` a través de una `ThemeExtension`, sin importar ninguna
   constante global.
2. **Given** el código fuente completo del proyecto, **When** se ejecuta el lint o test que
   verifica literales de color, **Then** el único archivo que contiene valores hexadecimales es el
   archivo de definición de paleta, y cualquier literal hexadecimal fuera de ese archivo hace
   fallar la verificación.

---

### User Story 2 - El tema permanece claro sin importar la configuración del dispositivo (Priority: P1)

Una persona usuaria con su teléfono configurado en modo oscuro del sistema operativo abre la app y
la ve exactamente igual — mismos colores, mismo contraste — que si su teléfono estuviera en modo
claro.

**Why this priority**: Un modo oscuro a medias (algunos widgets reaccionan al brillo del sistema,
otros no) es peor que no tener modo oscuro: produce pantallas ilegibles por combinaciones de color
no diseñadas. Fijar el modo explícitamente es lo único que evita ese resultado mientras el esquema
oscuro real no existe.

**Independent Test**: Se puede probar por completo configurando el brillo del sistema operativo en
oscuro, abriendo la app, y comparando visualmente (o mediante un test de widget que fuerce
`Brightness.dark` en el `MediaQuery` del entorno de prueba) que la app renderiza con los mismos
colores que en brillo claro.

**Acceptance Scenarios**:

1. **Given** un dispositivo con el sistema operativo configurado en modo oscuro, **When** se abre
   la app, **Then** la app se renderiza con el mismo esquema de color que en un dispositivo en modo
   claro.
2. **Given** la configuración raíz de la app, **When** se inspecciona cómo se determina el modo de
   tema, **Then** el modo está fijado explícitamente en claro y no depende de
   `MediaQuery.platformBrightnessOf` ni de ninguna otra señal de preferencia del sistema operativo.

---

### User Story 3 - Una persona usuaria ve la interfaz en su propio idioma (Priority: P1)

Una persona usuaria cuyo dispositivo está configurado en inglés, español, portugués, italiano o
francés ve todo el texto de los componentes del sistema de diseño en ese idioma, sin necesidad de
cambiar ningún ajuste dentro de la app.

**Why this priority**: Es, junto con las Historias 1 y 2, un requisito de primer orden de la
constitución (Principio 9): ninguna feature de producto puede considerarse terminada sin
traducción completa a los cinco idiomas, así que la infraestructura que lo hace posible debe
existir antes de que exista la primera pantalla.

**Independent Test**: Se puede probar por completo cambiando el locale del dispositivo o del
entorno de prueba entre los cinco idiomas soportados y confirmando que un componente que muestra
texto localizado (por ejemplo, un botón de prueba en un catálogo de componentes) muestra la
traducción correspondiente en cada caso.

**Acceptance Scenarios**:

1. **Given** un dispositivo con el locale del sistema configurado en inglés, español, portugués,
   italiano o francés, **When** se abre un componente que muestra texto localizado, **Then** el
   texto se muestra en el idioma correspondiente al locale activo.
2. **Given** un componente que muestra texto localizado, **When** se inspecciona el código fuente
   del widget, **Then** ninguna cadena de texto visible está escrita literalmente en Dart; toda
   proviene de la clase de localización generada a partir de archivos ARB.

---

### User Story 4 - Una clave de traducción faltante rompe el build antes de llegar a producción (Priority: P1)

Quien mantiene el repositorio agrega una clave nueva al archivo ARB plantilla (inglés) pero olvida
traducirla en uno o más de los otros cuatro idiomas. La integración continua detecta la
inconsistencia y falla el build, en lugar de dejar pasar una pantalla que en producción mostrará la
clave sin traducir o un texto de repuesto.

**Why this priority**: Sin este mecanismo, la garantía de "traducción completa en cinco idiomas"
de la Historia 3 se degrada con el tiempo a medida que se agregan claves nuevas — es la diferencia
entre una garantía verificada por máquina y una que depende de que nadie se olvide. Se agrupa como
P1 junto con la Historia 3 porque ambas, en conjunto, son la garantía real de localización
completa.

**Independent Test**: Se puede probar por completo agregando una clave nueva únicamente al ARB de
inglés (sin agregarla a los otros cuatro archivos) y confirmando que el pipeline de CI falla con un
mensaje que identifica la clave y el locale faltante.

**Acceptance Scenarios**:

1. **Given** una clave presente en el archivo ARB plantilla (inglés) y ausente en al menos uno de
   los archivos ARB de los otros cuatro idiomas, **When** se ejecuta el build en integración
   continua, **Then** el build falla.
2. **Given** una clave presente y traducida en los cinco archivos ARB, **When** se ejecuta el build
   en integración continua, **Then** el build no falla por motivo de localización.

---

### User Story 5 - Los contrastes de color se verifican por máquina, no por ojo (Priority: P2)

Quien revisa un cambio al sistema de diseño no necesita abrir la app y comparar colores a simple
vista para saber si un par texto/fondo es legible: un test automatizado calcula el ratio de
contraste de cada combinación definida por los tokens y falla si alguna no alcanza WCAG AA.

**Why this priority**: Sin este test, "cumple WCAG AA" es una afirmación de la documentación
(`docs/UI_UX_SPEC.md`) que nadie vuelve a verificar una vez que el código diverge del documento. Es
P2 porque depende de que los tokens de la Historia 1 ya existan como estructura verificable, pero
no bloquea que las Historias 1-4 se construyan primero.

**Independent Test**: Se puede probar por completo ejecutando el test de contraste sobre el
esquema de color claro definido en el archivo de paleta y confirmando que reporta el ratio exacto
de cada par texto/fondo declarado, fallando si alguno cae por debajo del umbral.

**Acceptance Scenarios**:

1. **Given** el conjunto de pares texto/fondo definidos por los tokens del sistema de diseño,
   **When** se ejecuta el test automatizado de contraste, **Then** cada par reporta un ratio de al
   menos 4.5:1 para texto normal o 3:1 para texto grande.
2. **Given** un cambio hipotético que introduce un par texto/fondo por debajo del umbral WCAG AA,
   **When** se ejecuta el test de contraste, **Then** el test falla e identifica el par
   específico que no cumple.

---

### User Story 6 - Un componente primitivo no se rompe con la traducción más larga a escala máxima (Priority: P2)

Quien revisa un componente primitivo (botón, chip, tarjeta, etiqueta) necesita confirmar que ese
componente, mostrando la traducción más larga entre los cinco idiomas soportados y con la escala de
texto del sistema operativo al 200%, sigue mostrando el texto completo — reflowing en vez de
recortar o desbordar.

**Why this priority**: Es la combinación de accesibilidad (Principio 8: texto debe escalar a 200%
sin recorte) y localización (Principio 9: los layouts deben tolerar expansión de texto) aplicada al
peor caso simultáneo. Es P2 porque depende de que los componentes primitivos (Historia 1) y las
traducciones (Historia 3) ya existan.

**Independent Test**: Se puede probar por completo renderizando cada componente primitivo con la
etiqueta traducida más larga de los cinco idiomas, a 200% de escala de texto, y confirmando
mediante un test de widget que no hay overflow ni recorte.

**Acceptance Scenarios**:

1. **Given** un componente primitivo del sistema de diseño, **When** se le asigna la etiqueta
   traducida más larga entre los cinco idiomas soportados y se renderiza a 200% de escala de
   texto, **Then** el texto completo permanece visible, envolviendo a una línea adicional o
   ensanchando el componente en vez de recortarse o desbordar sus límites.

---

### User Story 7 - Un catálogo de golden tests detecta regresiones visuales (Priority: P3)

Quien modifica el sistema de diseño (por ejemplo, ajusta un radio de borde o un espaciado) obtiene
una señal inmediata en CI si ese cambio altera visualmente algún componente primitivo de forma no
intencional, comparando contra una imagen de referencia aprobada.

**Why this priority**: Es una red de seguridad sobre las Historias 1-6, no un requisito
independiente: su valor es detectar regresiones en piezas que ya deben existir y ya deben cumplir
las historias anteriores. Se marca P3 porque el sistema de diseño es funcionalmente correcto sin
esto, solo más frágil ante cambios futuros.

**Independent Test**: Se puede probar por completo modificando deliberadamente un valor visual de
un componente primitivo (por ejemplo, su color de fondo) y confirmando que el golden test
correspondiente falla, luego revirtiendo el cambio y confirmando que vuelve a pasar.

**Acceptance Scenarios**:

1. **Given** cada componente primitivo del sistema de diseño, **When** se ejecuta la suite de
   golden tests sobre el esquema de color claro, **Then** existe al menos un golden test por
   componente y todos pasan contra las imágenes de referencia aprobadas.
2. **Given** un golden test existente, **When** se introduce un cambio visual no intencional en el
   componente que cubre, **Then** el golden test falla en vez de pasar silenciosamente.

---

### Edge Cases

- ¿Qué pasa si alguien agrega un literal hexadecimal de color dentro de un widget, fuera del
  archivo de definición de paleta? El lint o test correspondiente (Historia 1) falla el build antes
  de que ese código pueda integrarse.
- ¿Qué pasa si a futuro se agrega un esquema de color oscuro? Debe ser posible agregando una nueva
  instancia de la extensión de tema con sus propios valores por token, sin modificar ningún widget
  existente que ya consuma esos tokens — ver FR-007 y FR-008 sobre cómo se verifica esta propiedad
  sin implementar el esquema oscuro en esta feature.
- ¿Qué pasa si una clave ARB existe en los cinco idiomas pero con una traducción vacía o solo
  espacios en blanco? Se trata igual que una clave faltante a efectos de esta feature: el
  comportamiento exacto de detección de cadenas vacías se deja para la fase de implementación, pero
  el build no debe considerar "traducida" una clave sin contenido real.
- ¿Qué pasa si dos idiomas producen exactamente el mismo largo de etiqueta para una clave dada? La
  Historia 6 se verifica con la etiqueta de mayor longitud medible; un empate no invalida la
  prueba, cualquiera de las etiquetas empatadas es válida como caso de prueba.
- ¿Qué pasa si un componente primitivo no contiene ningún texto (por ejemplo, un contenedor
  decorativo)? La Historia 6 no le aplica; solo aplica a componentes que renderizan texto
  localizado.
- ¿Qué pasa si el dispositivo usa un locale no soportado (por ejemplo, alemán)? El sistema debe
  resolver a un idioma de repuesto (el locale plantilla, inglés) en vez de fallar o mostrar claves
  sin traducir.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE definir todos los valores de color, tipografía, radio de borde y
  espaciado que consume la interfaz como tokens semánticos con nombre (por ejemplo `background`,
  `onSurface`, `radiusLg`, `spacingMd`), resueltos desde el `BuildContext` mediante una
  `ThemeExtension`, nunca mediante constantes globales importadas directamente por los widgets.
- **FR-002**: Todo valor literal hexadecimal de color DEBE existir en un único archivo de
  definición de paleta; ningún otro archivo del código fuente puede contener un literal
  hexadecimal de color.
- **FR-003**: Un lint o test automatizado DEBE fallar el build si detecta un literal hexadecimal de
  color en cualquier archivo distinto del archivo de definición de paleta autorizado.
- **FR-004**: Ningún widget puede construir un `TextStyle`, un `BorderRadius` o un valor de
  espaciado a partir de un literal ad hoc; todos DEBEN provenir de los tokens semánticos
  correspondientes.
- **FR-005**: La app DEBE fijar explícitamente el modo de tema en claro (`ThemeMode.light`) en su
  configuración raíz y NO DEBE leer ni reaccionar a la preferencia de brillo del sistema operativo
  del dispositivo.
- **FR-006**: La app renderizada en un dispositivo con el sistema operativo en modo oscuro DEBE
  verse visualmente idéntica a la misma app renderizada en un dispositivo en modo claro.
- **FR-007**: La estructura de tokens DEBE permitir agregar un segundo esquema de color completo
  (oscuro) mediante una nueva instancia de la extensión de tema, sin requerir cambios en ningún
  archivo de widget que ya consuma esos tokens.
- **FR-008**: Esta especificación DEBE describir un mecanismo verificable — un test que instancie
  un esquema de color alternativo de prueba y confirme que los componentes primitivos existentes lo
  renderizan sin modificación de código — que demuestre la propiedad de FR-007 sin que el esquema
  oscuro real forme parte del alcance de esta feature.
- **FR-009**: Todo par texto/fondo definido por los tokens del sistema de diseño DEBE cumplir el
  contraste mínimo WCAG AA (4.5:1 para texto normal, 3:1 para texto grande), verificado mediante un
  test automatizado que calcule el ratio de contraste, no mediante inspección visual.
- **FR-010**: El sistema DEBE resolver todo texto visible de los componentes primitivos mediante la
  clase de localización generada a partir de archivos ARB, en cinco idiomas — inglés, español,
  portugués, italiano y francés — seleccionados según el locale activo del dispositivo, con inglés
  como idioma de repuesto para locales no soportados.
- **FR-011**: Ninguna cadena de texto visible para la persona usuaria puede estar escrita
  literalmente en código Dart.
- **FR-012**: El proceso de construcción DEBE fallar en integración continua si una clave presente
  en el archivo ARB plantilla (inglés) está ausente, vacía, o sin traducir en cualquiera de los
  otros cuatro archivos ARB de locale.
- **FR-013**: Cada componente primitivo del sistema de diseño que renderiza texto localizado DEBE
  tolerar, sin recortar ni desbordar su contenido, la etiqueta traducida más larga entre los cinco
  idiomas soportados, renderizada a 200% de escala de texto del sistema operativo.
- **FR-014**: Debe existir al menos un golden test por cada componente primitivo del sistema de
  diseño, ejecutado sobre el único esquema de color entregado por esta feature (claro).
- **FR-015**: Esta feature NO DEBE incluir ningún esquema de color oscuro implementado, teclado
  numérico, categorías, gastos, autenticación, ni ninguna pantalla o flujo de producto —
  únicamente componentes primitivos del sistema de diseño y la infraestructura de localización que
  los soporta.

### Key Entities

- **Token semántico de diseño**: un valor de color, tipografía, radio o espaciado identificado por
  su propósito (por ejemplo `background`, `onSurface`, `radiusLg`) en lugar de por su valor
  concreto, resuelto en tiempo de ejecución desde el esquema de tema activo.
- **Esquema de color**: un conjunto completo de valores concretos asignados a cada token semántico
  de color, empaquetado como una instancia de la extensión de tema; esta feature entrega
  exactamente uno (claro).
- **Componente primitivo**: un widget reutilizable de bajo nivel del sistema de diseño (botón,
  campo de entrada, tarjeta, chip, etiqueta, etc.) que consume exclusivamente tokens semánticos, no
  contiene texto literal ni lógica de producto, y es el bloque de construcción de futuras pantallas.
- **Clave de traducción (ARB key)**: identificador único que vincula un texto fuente en inglés con
  su traducción equivalente en cada uno de los cuatro idiomas restantes soportados.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de los valores de color, tipografía, radio y espaciado consumidos por los
  componentes primitivos provienen de tokens resueltos desde el tema activo — verificado por un
  test o lint automatizado que falla ante cualquier literal fuera del archivo de paleta único.
- **SC-002**: La app se ve visualmente idéntica al ejecutarse en un dispositivo con el sistema
  operativo en modo claro y en uno en modo oscuro, en el 100% de los componentes primitivos
  evaluados.
- **SC-003**: Agregar un esquema de color de prueba (simulando un futuro esquema oscuro) requiere
  cero cambios en archivos de widgets existentes, confirmado por un test que lo instancia y
  renderiza los componentes primitivos existentes sin tocar su código.
- **SC-004**: El 100% de los pares texto/fondo definidos por el sistema de diseño pasan un test
  automatizado de contraste WCAG AA.
- **SC-005**: Un componente que muestra texto localizado renderiza correctamente el texto
  correspondiente en el 100% de los cinco idiomas soportados al cambiar el locale del entorno de
  prueba.
- **SC-006**: Un pull request que agrega una clave nueva únicamente al ARB de inglés y no a los
  otros cuatro falla en integración continua el 100% de las veces que ocurre esa condición.
- **SC-007**: El 100% de los componentes primitivos que muestran texto localizado renderizan sin
  recorte ni desbordamiento al mostrar la etiqueta traducida más larga de los cinco idiomas a 200%
  de escala de texto.
- **SC-008**: Cada componente primitivo del sistema de diseño tiene al menos un golden test que
  pasa contra el esquema de color claro, y ese test falla si se introduce una regresión visual no
  intencional en el componente que cubre.

## Assumptions

- "Componentes primitivos" se refiere a los widgets base reutilizables (botones, campos de
  entrada, tarjetas, chips, etiquetas, indicadores, etc.) descritos o implícitos en
  `docs/UI_UX_SPEC.md` sección 1, no a pantallas ni flujos compuestos de producto. La lista
  concreta de componentes a construir se define en la fase de planificación, no en esta spec.
- El inglés es el locale plantilla (fuente de verdad estructural) para las claves ARB, según
  `docs/TECH_STACK.md`; las traducciones a los otros cuatro idiomas deben existir para cada clave
  usada por un componente primitivo, aunque su calidad lingüística final (revisión por hablante
  nativo para copy con voz de producto) es una preocupación de features posteriores que sí
  introduzcan ese copy.
- La etiqueta traducida "más larga" (Historia 6) se determina por comparación de longitud de
  cadena renderizada entre los cinco idiomas para cada clave usada en un componente primitivo
  dado; francés y portugués son los candidatos más probables según `docs/UI_UX_SPEC.md` sección 7.
- No existen todavía pantallas de producto que consuman estos componentes; la verificación de
  todas las historias de usuario ocurre mediante harnesses de prueba (tests de widget, golden
  tests, un catálogo de componentes aislado de desarrollo), no mediante flujos de usuario real
  navegables. Un catálogo de componentes, si se construye, es una herramienta de desarrollo y no
  cuenta como pantalla de producto a efectos del Fuera de Alcance.
- El esquema de color oscuro queda fuera de alcance como *implementación de producto*, pero la
  arquitectura de tokens debe soportarlo sin refactor (FR-007); esto se verifica con una instancia
  de esquema de color de prueba, no con un segundo esquema publicado o accesible desde la app.
- Los tests de contraste WCAG AA y de golden tests se ejecutan como parte de la suite de pruebas
  del proyecto (ver `docs/TECH_STACK.md` — tabla de Testing) y no requieren infraestructura de CI
  nueva más allá de lo que Principio 9 y Principio 7 de la constitución ya exigen para otras
  verificaciones.
