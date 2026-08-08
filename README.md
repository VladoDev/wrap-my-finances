# 💸 Wrap My Finances

Una aplicación de registro de gastos diseñada para la velocidad. Registra tus gastos en menos de
3 segundos con una arquitectura **Offline-First**, y recibe un resumen mensual estilo "Wrapped"
con animaciones fluidas y un diseño amigable.

## 📖 Documentación (Spec Kit)

Toda la definición del producto, arquitectura y diseño vive en `/docs`. Léelos en este orden
antes de escribir código:

1. [Product Context](docs/PRODUCT_CONTEXT.md) — visión, métricas de éxito y anti-objetivos.
2. [Environments & Flavors](docs/ENVIRONMENTS.md) — flavors, los dos proyectos de Firebase y el
   runbook de aprovisionamiento. **Empieza aquí si vas a tocar infraestructura.**
3. [UI & UX Specs](docs/UI_UX_SPEC.md) — sistema de diseño "Modern Playful" y flujos de usuario.
4. [Architecture](docs/ARCHITECTURE.md) — Feature-first Clean Architecture.
5. [Tech Stack](docs/TECH_STACK.md) — librerías y herramientas.
6. [Data Model](docs/DATA_MODEL.md) — esquema de Firestore, índices y Security Rules.
7. [Roadmap](docs/ROADMAP.md) — fases de desarrollo y lanzamiento.

## 🌍 Entornos

El proyecto tiene **dos flavors**, cada uno apuntando a su propio proyecto de Firebase:

| Flavor | Proyecto Firebase | App ID | Nombre |
| --- | --- | --- | --- |
| `dev` | `wrap-my-finances-dev` | `com.yourorg.wrapmyfinances.dev` | Wrap Dev |
| `prod` | `wrap-my-finances-prod` | `com.yourorg.wrapmyfinances` | Wrap |

Ambos se pueden instalar al mismo tiempo en el mismo dispositivo. Los detalles completos están en
[ENVIRONMENTS.md](docs/ENVIRONMENTS.md).

## 🚀 Inicio Rápido

### Prerrequisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) — canal stable
- [Firebase CLI](https://firebase.google.com/docs/cli) — `npm install -g firebase-tools`
- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) —
  `dart pub global activate flutterfire_cli`
- Xcode 15+ (iOS) y Android Studio con JDK 17 (Android)
- Una cuenta de Google con permisos para crear proyectos de Firebase

### Instalación

```bash
git clone https://github.com/tu-usuario/wrap-my-finances.git
cd wrap-my-finances
flutter pub get
```

### Configuración de Firebase (solo la primera vez)

Sigue el runbook completo en [ENVIRONMENTS.md § 5](docs/ENVIRONMENTS.md). En resumen:

```bash
firebase login
firebase projects:create wrap-my-finances-dev  --display-name "Wrap My Finances (Dev)"
firebase projects:create wrap-my-finances-prod --display-name "Wrap My Finances"
# ...crear Firestore y activar Anonymous Auth en cada proyecto...
# ...luego flutterfire configure una vez por flavor...
```

Antes de correr nada, reemplaza `yourorg` por tu dominio invertido real en todo el repositorio.
**No uses `com.example.*`**: Google Play lo rechaza y el ID es inmutable después de la primera
publicación.

### Generación de código

```bash
dart run build_runner build --delete-conflicting-outputs
# o, durante desarrollo:
dart run build_runner watch -d
```

### Ejecutar

```bash
# Dev contra el proyecto dev en la nube
flutter run --flavor dev -t lib/main_dev.dart

# Dev contra los emuladores locales
firebase emulators:start --only auth,firestore
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATORS=true

# Prod
flutter run --flavor prod -t lib/main_prod.dart --release
```

`--flavor` siempre va acompañado de `-t`. No existe `lib/main.dart`: es intencional, para que
olvidar el entrypoint falle de inmediato en vez de compilar contra el Firebase equivocado.

### Compilar releases

```bash
flutter build appbundle --flavor prod -t lib/main_prod.dart
flutter build ipa       --flavor prod -t lib/main_prod.dart
```

### Tests

```bash
flutter test                                   # unit + widget
flutter test --update-goldens                  # regenerar goldens del design system
flutter test integration_test                  # integración
cd firestore-tests && npm test                 # Security Rules contra el emulador
```

### Desplegar reglas e índices

```bash
firebase deploy --only firestore:rules,firestore:indexes -P dev
firebase deploy --only firestore:rules,firestore:indexes -P prod   # requiere confirmación
```

El alias `default` de `.firebaserc` apunta a **dev** a propósito: un `firebase deploy` accidental
debe pegarle al proyecto desechable, nunca a producción.

## 🤖 Nota para agentes de IA

Si eres un agente con acceso a la cuenta de Firebase, lee
[ENVIRONMENTS.md § 5.1 Guardrails](docs/ENVIRONMENTS.md) **antes** de ejecutar cualquier comando.
Resumen: nada destructivo sin confirmación humana explícita, nunca datos de prueba en `prod`,
nunca commitear `google-services.json`, `GoogleService-Info.plist` ni keystores.

## 📄 Licencia

Por definir.
