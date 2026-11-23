# Finanzas Porcinas — contexto de la app

Estado al **23 de noviembre de 2026**. Entrega: **lunes 30 de noviembre de 2026**.

## Qué es
App iOS nativa para el **Criadero Fam Rico Moreno** (emprendimiento familiar de crianza de puercos, Constitución, Playa del Carmen 111, Aldama, Tamaulipas). Es el Proyecto Integrador (Fase III. Ejecución) de la materia *Desarrollo de proyecto de aplicaciones móviles*, Universidad Tecmilenio. Modelo ágil evolutivo.

- **Alumno:** José Guadalupe Rico Moreno, matrícula AL03063503 (AL03063503@tecmilenio.mx).
- **Profesora titular:** Eva María Francisco Santiago.
- **Cliente / titular:** Virginia del Carmen Moreno Gallegos (mamá de José; lleva el dinero).
- **Operador:** José (limpieza y alimentación en vacaciones).
- **Veterinario:** Dr. Rafael de Leija Lara.

## Datos reales del negocio (no inventar nada fuera de esto)
- Empezó en 2018 con 5 puercos; hoy **17 de crianza** y **12 al año para venta** de carne y derivados.
- Razas: **Común, Minipig y Cruza**.
- Precio de venta: **$40 u $80 por kilogramo según la raza**. La app **nunca asigna** qué raza vale $80: la persona elige el precio en cada venta.
- Los precios de los insumos varían según el proveedor.
- Los pedidos llegaban por Facebook (cuenta personal de Virginia) y por grupos de WhatsApp de las colonias. **La app ya no maneja pedidos** (la sección se quitó el 20/11/2026).
- Los 20 animales ("Cerdo 01" a "Cerdo 20"), los proveedores A/B/C, 3 compras y 4 visitas de `DatosIniciales.swift` son **datos de ejemplo**.

## Uso real
Se usa **de pie, en el corral, con sol y con guantes**: botones grandes (56 pt o más), texto de 17 pt o más, nada que haya que adivinar. Todo texto visible va en **español de México**.

## Las 3 pestañas
| Pestaña | Pregunta que responde | Contenido |
|---|---|---|
| **Hoy** | ¿Qué toca hoy? | Saludo, tareas del día (alimentación mañana, limpieza de corrales, alimentación tarde; con kilos de alimento y nota), atajos (Agregar cerdo, Vender, Guía de razas), carrusel "Mis cerdos", visitas del veterinario, días anteriores |
| **Animales** | ¿Cuáles son mis cerdos? | Cuadrícula con foto, filtros Todos/Crianza/Venta, buscador por nombre o raza, alta de cerdo, ficha (foto, peso, destino, notas, vender, actualizar peso, baja con confirmación), botón Razas |
| **Dinero** | ¿Cuánto gano o gasto? | Venta en 3 pasos (qué cerdo, cuántos kilos, a cómo el kilo; total en grande; costo de criar opcional), Historial de ventas, Compras de insumos con comparador de proveedores |

Además: **Guía de razas** (datos reales y foto de cada raza, con créditos) accesible desde Hoy, Animales y la ficha.

## Imágenes e información reales (desde el 20/11/2026)
- Cada raza usa una **foto real de Wikimedia Commons** (CC BY-SA) como imagen por defecto: Común (*Large White sow*, Steven Walling, CC BY-SA 3.0), Minipig (*Mini Pig*, Fcobmz, CC BY-SA 4.0), Cruza (*Mixed pigs a large white and the durac*, Beatrice Kaseke, CC BY-SA 4.0). Son fotos de ejemplo de la raza; la ficha lo indica.
- Prioridad de imagen: **foto propia del animal** (PhotosPicker) > **foto real de la raza** > dibujo.
- Los textos de la guía son resumen de Wikipedia (CC BY-SA). **Todo dato nuevo debe tener fuente y crédito.**

## Tecnología
- Xcode 26.4, Swift 5 (language mode), **iOS 18.0+**, SwiftUI + SwiftData, **local y sin internet**, sin dependencias externas.
- Proyecto `FinanzasPorcinas.xcodeproj`, esquema `FinanzasPorcinas`, bundle id `mx.tecmilenio.al03063503.FinanzasPorcinas`.
- Probado en el simulador **iPhone 17 Pro, iOS 26.4**.

```bash
xcodebuild -project FinanzasPorcinas.xcodeproj -scheme FinanzasPorcinas \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```
Argumentos de lanzamiento para capturas: `-pantalla hoy | animales | dinero` y `-ficha`. Para reiniciar con los datos de ejemplo: `xcrun simctl uninstall booted <bundle id>`.

## Modelo de datos (5 @Model)
- `Animal`: arete, raza, sexo, pesoKg, destino (crianza/venta), fechaAlta, notas, foto (`Data?`, almacenamiento externo).
- `Tarea`: fecha, tipo, hecha, detalle, responsable, kilosAlimento.
- `Compra`: fecha, concepto, proveedor, cantidad, unidad, precioUnitario (total calculado).
- `Venta`: fecha, areteAnimal, kilos, precioPorKg (total calculado).
- `VisitaVeterinario`: fecha, tipoAtencion, alcance, notas.
- Enums: `Raza`, `Sexo`, `Destino`, `TipoTarea`, `PrecioKg` ($40/$80), `Empresa` (datos fijos).

## Código (14 archivos Swift, 5,403 líneas)
`FinanzasPorcinasApp`, `VistaPrincipal` (TabView), `Modelos`, `DatosIniciales`, `Tema`, `AvatarCerdo` (foto propia > foto de raza > dibujo), `GuiaRazas`, `Componentes`, y en `Vistas/`: `VistaHoy`, `VistaAnimales`, `VistaFichaAnimal`, `VistaDinero`, `VistaCompras`, `VistaVeterinario`.

Reglas de código: `@Query` solo ordena por propiedades almacenadas (filtrar en Swift lo calculado); campos numéricos con `@State String` convertidos con `Double(...replacingOccurrences(of: ",", with: "."))`; colores solo de `Tema`; SF Symbols, sin emoji ni logotipos; relleno inferior de 100 pt en cada `ScrollView`.

## Evolución del diseño (por qué es como es)
1. **25 oct** — iteración 1 (5 pestañas: Inicio, Animales, Bitácora, Finanzas, Pedidos). Cliente: *"La app no es muy buena."*
2. **26 oct** — iteración 2 (mejoras de jerarquía). Cliente: *"No me termina de gustar nada el diseño: no tiene imágenes de los animales y es cero intuitivo."* → se reconstruyó desde cero.
3. **26 oct** — iteración 3 (4 pestañas visuales con ilustración por raza).
4. **20 nov** — iteración 4: se quitó Pedidos, foto real por raza, Guía de razas. Versión final **aprobada por Virginia**.

## Requerimientos y pruebas
- 26 funcionales: **19 implementados**, **3 retirados** (RF-06, RF-19, RF-20 de Pedidos) y **4 pendientes** (RF-21 historial de pesos, RF-22 ración y dieta, RF-23 costo real por kg, RF-24 calendario y sanidad). 10 no funcionales (RNF-10, texto escalable, pendiente). 5 fuera de alcance.
- Pruebas vigentes: **12 de componente y 4 de integración**, aprobadas en simulador. CP-09, CP-10 y PI-02 retiradas con Pedidos. **CP-14 (subir foto propia) no ejecutada**: el simulador no tiene fotos; falta probar en un iPhone real.
- Observación sin causa: en varias ocasiones el primer toque en un botón no respondió y funcionó al repetirlo.

## Entregables (carpeta `Entregables/`)
- `Fase_III_Finanzas_Porcinas.docx` / `.pdf` — documento maestro (68 págs.), se genera con `Archivo/build_fase3.py` + `Archivo/iteracion4.py`. **No editar a mano.**
- `01_Cronograma_FaseIII.xlsx` / `.png` — estado al 23/11/2026 (`Archivo/actualiza_cronograma.py`).
- `Por_separado/`: `04_Registro_Prueba_CP-13.docx`, `06_Registro_Prueba_CP-15.docx`; `02`, `03` y `05` se regeneran del documento maestro (`Archivo/build_sueltos.py`) y están al 23/11/2026.
- `Certificado_Swift_5_Protocol_Oriented_Programming.pdf` (LinkedIn Learning, 25/10/2026).
- Fase final: `Presentacion_Ejecutiva_Completa_Finanzas_Porcinas.pptx` (27 diapositivas: fases 1 a 4, con evidencias por fase, cambios y justificaciones, video, satisfacción y lecciones), `Presentacion_Ejecutiva_Finanzas_Porcinas.pptx` (versión de 2 diapositivas + video), `Video_Demo_Finanzas_Porcinas.mp4` (grabación del simulador, no del cliente), `Hallazgos_y_Lecciones_Aprendidas.docx`, `Presentacion_Finanzas_Porcinas.pptx` (7 diapositivas, 5 minutos), `Encuesta_Satisfaccion_Cliente.docx` (cuestionario en blanco).
- Capturas por iteración en `Pruebas/`; código anterior en `Archivo/Iteracion2_Codigo` y `Archivo/Iteracion3_Codigo`.

## Pendientes
- **Encuesta de satisfacción:** índice 5.0 de 5 (8 afirmaciones, todas en 5), comunicado por Virginia a José y reportado por él el 23/11/2026; sin comentarios textuales de ella. Ya está en la presentación ejecutiva y en el documento de lecciones. No agregar justificaciones que ella no dijo.
- (Resuelto) Los 4 certificados de LinkedIn Learning existen: Swift 5 Essential Training (fase 1), Swift: Delegations and Data Sources (1/9/2026, está en el reporte de la fase 2), Protocol-Oriented Programming (25/10/2026) y, de la fase 4, *Complete Guide to SwiftUI*, LinkedIn Learning, 23/11/2026, 10 h 57 min (`Entregables/Certificado_Complete_Guide_to_SwiftUI.pdf`). Ya está en la presentación completa y en el documento de lecciones.
- Probar la subida de foto propia en un iPhone real (CP-14).
- GitHub (`RMJ4G27020/finanzas-porcinas`) sigue en la iteración 3; subir la 4 requiere permiso de José.

## Cómo trabajar con José
- Ser **literal** con lo que pide el enunciado; no agregar ni asumir. Si falta un dato, **una sola tanda de preguntas**.
- Entregar **completo** y responder **corto**. Un solo Word cuando lo pide así.
- No proponer ejercicios guiados del libro *App Development with Swift* (p. ej. Restaurant); los descartó.
- No atribuir al cliente cambios que no se sabe que pidió.
- Si se cambia la app: compilar y comprobar con captura antes de decir que funciona.
