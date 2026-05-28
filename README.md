# CoachOS

Aplicación móvil **B2B2C** para entrenadores personales y sus clientes. Permite gestionar clientes, rutinas, dietas, revisiones, tarifas, comunicación en tiempo real y suscripciones desde un único ecosistema nativo (iOS y Android).

---

## Funcionalidades principales

### Entrenador (coach)
- Panel de clientes con filtros, semáforo de suscripción y límite de plazas por plan
- Ficha de cliente con pestañas: perfil, entrenamiento, dieta y revisiones
- Bibliotecas reutilizables de rutinas, dietas y plantillas de revisión (CRUD)
- **Mi Despacho**: dashboard financiero (MRR, ARPU), tarifas, QR de captación e interesados (leads)
- Chat en tiempo real con clientes
- Planes de suscripción del coach (incluye integración PayPal Sandbox)

### Cliente
- Dashboard personalizado con estado de cuota y tarifa
- Consulta de rutina y dieta asignadas
- Envío de revisiones con formulario dinámico y fotos (Firebase Storage)
- Chat con el entrenador
- Onboarding para leads: explorar entrenadores, perfil público del coach y contratación

### Administrador
- Panel de supervisión de entrenadores y clientes

---

## Stack tecnológico

| Área | Tecnología |
|------|------------|
| Frontend | Flutter (Dart SDK ^3.10) |
| Autenticación | Firebase Auth |
| Base de datos | Cloud Firestore |
| Archivos | Firebase Storage |
| Pagos (coach) | PayPal REST API (Sandbox) + deep links |
| Gráficos | fl_chart |
| Nutrición | Open Food Facts (API externa) |
| UI | Material + Cupertino (estética iOS) |

---

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (compatible con Dart ^3.10)
- Xcode (para iOS) y/o Android Studio (para Android)
- Proyecto en [Firebase Console](https://console.firebase.google.com/)
- Cuenta [PayPal Developer](https://developer.paypal.com/) (Sandbox, solo para pagos del coach)

---

## Estructura del proyecto

```
lib/
├── config/          # Tema corporativo y configuración PayPal
├── models/          # Modelos de datos (parseo desde Firestore)
├── services/        # Auth, Firestore, chat, PayPal, API nutrición
├── ui/
│   ├── screens/
│   │   ├── coach/       # Entorno del entrenador
│   │   ├── cliente/     # Entorno del cliente y onboarding
│   │   ├── compartidos/ # Ajustes, chats, pagos
│   │   └── admin/       # Panel administrador
│   └── widgets/     # Componentes reutilizables
├── main.dart
└── firebase_options.dart
```

---

## Limitaciones y trabajo futuro

- Pagos del cliente simulados (cuota mensual); integración real de cobros al cliente pendiente
- Deep links `coachos://` configurados en iOS; revisar intent-filters en Android si se requiere paridad
- Panel admin en fase básica
- Tests automatizados limitados

---

## Licencia

Proyecto académico (TFG). Todos los derechos reservados salvo indicación contraria por el autor.


