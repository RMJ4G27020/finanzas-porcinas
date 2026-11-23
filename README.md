# Finanzas Porcinas 🐷

Aplicación iOS para el **Criadero Fam Rico Moreno**, un emprendimiento familiar de crianza de
puercos en Aldama, Tamaulipas. Es el Proyecto Integrador — **Fase III. Ejecución** — de la materia
*Desarrollo de proyecto de aplicaciones móviles* (Universidad Tecmilenio).

**Alumno:** José Guadalupe Rico Moreno · matrícula AL03063503.

## Qué hace

Concentra en un solo lugar el control del criadero, organizado en tres pestañas:

- **Hoy** — tareas del día (alimentación y limpieza), atajos y mis cerdos.
- **Animales** — hato completo con foto, ficha, peso, destino y foto propia, y la **Guía de razas**.
- **Dinero** — venta en tres pasos, historial, compras y comparación de proveedores.

Todo en español de México, **local y sin internet**, pensado para usarse de pie, en el corral,
con sol y con guantes: botones grandes, texto grande y una acción principal por pantalla.

### Iteración 4 (20 de noviembre de 2026)

- Se quitó la sección de pedidos (Facebook / WhatsApp).
- Cada raza usa una **foto real** de ejemplo; si el cerdo tiene foto propia, esa tiene prioridad.
- Nueva **Guía de razas** con datos resumidos de Wikipedia y el crédito de cada foto.

Fotos de Wikimedia Commons (licencia CC BY-SA): *Large White sow* (Steven Walling, CC BY-SA 3.0),
*Mini Pig* (Fcobmz, CC BY-SA 4.0) y *Mixed pigs a large white and the durac* (Beatrice Kaseke,
CC BY-SA 4.0). Los textos de la guía resumen Wikipedia (CC BY-SA).

## Tecnología

- Xcode 26.4 · Swift 5 · SwiftUI · SwiftData
- iOS 18.0 o superior · sin dependencias externas

## Estructura

```
FinanzasPorcinas/
  FinanzasPorcinasApp.swift   entrada; ModelContainer y siembra de datos
  VistaPrincipal.swift        TabView de 3 pestañas
  Modelos.swift               5 @Model + enumeraciones del dominio
  DatosIniciales.swift        datos de ejemplo del primer arranque
  Tema.swift                  colores, tipografía y componentes
  AvatarCerdo.swift           imagen del cerdo: foto propia, foto de la raza o dibujo
  GuiaRazas.swift             información de las razas, créditos y pantalla Guía de razas
  Componentes.swift           AccionRapida, BarraProgreso, ChipRaza, …
  Vistas/                     VistaHoy, VistaAnimales, VistaFichaAnimal,
                              VistaDinero, VistaCompras, VistaVeterinario
```

## Ejecutar

```bash
xcodebuild -project FinanzasPorcinas.xcodeproj -scheme FinanzasPorcinas \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

## Pantallas (iteración 4)

| Hoy | Animales | Dinero | Guía de razas |
| --- | --- | --- | --- |
| ![Hoy](Pruebas/Iteracion4_Fotos_reales/01_hoy.png) | ![Animales](Pruebas/Iteracion4_Fotos_reales/02_animales.png) | ![Dinero](Pruebas/Iteracion4_Fotos_reales/03_dinero.png) | ![Guía de razas](Pruebas/Iteracion4_Fotos_reales/04_guia_razas_1.png) |

El diseño anterior, con cuatro pestañas y pedidos, está en `Pruebas/Iteracion3_Rediseno` y su código en
`Archivo/Iteracion3_Codigo`.

## Documentación

El informe completo de la Fase III está en
[`Entregables/Fase_III_Finanzas_Porcinas.pdf`](Entregables/Fase_III_Finanzas_Porcinas.pdf).
La presentación ejecutiva, el video de demostración y el documento de lecciones aprendidas están en
[`Entregables/`](Entregables).
