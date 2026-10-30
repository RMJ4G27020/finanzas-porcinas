# Finanzas Porcinas

App iOS para el **Criadero Fam Rico Moreno**, un emprendimiento familiar de crianza de puercos en Aldama, Tamaulipas. Es el Proyecto Integrador (Fase III. Ejecución) de José Guadalupe Rico Moreno, matrícula AL03063503, materia "Desarrollo de proyecto de aplicaciones móviles", Universidad Tecmilenio. Profesora: Eva María Francisco Santiago. **Entrega: lunes 30 de noviembre de 2026.** Modelo ágil evolutivo.

Todo texto visible al usuario va en **español de México**.

## Quién la usa
- **Virginia del Carmen Moreno Gallegos**: titular, lleva el dinero. Usa Dinero y Pedidos.
- **José**: limpieza y alimentación. Usa Hoy.
- **Dr. Rafael de Leija Lara**: veterinario. Se registran sus visitas.

Se usa **de pie, en el corral, con sol y con guantes**: botones grandes, texto grande, nada que haya que adivinar.

## Datos reales (no inventar nada fuera de esto)
- 17 animales de crianza; 12 puercos al año para venta de carne y derivados.
- Razas: **Común, Minipig y Cruza**.
- Precio de venta: **$40 u $80 por kilogramo según la raza**. **Nunca asignes qué raza vale $80**: el usuario elige el precio.
- Los precios de los insumos varían según el proveedor.
- Los pedidos llegan por Facebook (cuenta personal de Virginia) y por grupos de WhatsApp de las colonias.
- Los datos de ejemplo (20 animales "Cerdo 01" a "Cerdo 20", proveedores A/B/C, 5 pedidos, 4 visitas) están en `DatosIniciales.swift` y son ilustrativos. Sin KPIs ni totales inventados: todo total se calcula de los datos.

## Cómo compilar y correr
- Xcode 26.4, Swift 5 (language mode), **iOS 18.0 o superior**, SwiftUI + SwiftData, **local y sin internet**, sin dependencias externas.
- Proyecto: `FinanzasPorcinas.xcodeproj`, esquema `FinanzasPorcinas`. Bundle id: `mx.tecmilenio.al03063503.FinanzasPorcinas`.

```bash
xcodebuild -project FinanzasPorcinas.xcodeproj -scheme FinanzasPorcinas \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

Argumentos de lanzamiento para abrir una pantalla directo (sirven para capturas de evidencia):
- `-pantalla hoy | animales | dinero | pedidos`
- `-ficha`: abre la ficha de un cerdo marcado para venta.

```bash
xcrun simctl launch booted mx.tecmilenio.al03063503.FinanzasPorcinas -pantalla dinero
xcrun simctl io booted screenshot /ruta/captura.png
```

Para reiniciar con los datos de ejemplo, desinstala la app: `xcrun simctl uninstall booted <bundle id>`.

## Estructura (14 archivos Swift)
```
FinanzasPorcinas/
  FinanzasPorcinasApp.swift   entrada; crea el ModelContainer y siembra datos
  VistaPrincipal.swift        TabView de 4 pestañas: Hoy, Animales, Dinero, Pedidos
  Modelos.swift               6 @Model: Animal (con foto: Data?), Tarea, Compra, Venta, VisitaVeterinario, Pedido; enums; Empresa
  DatosIniciales.swift        siembra del primer arranque
  Tema.swift                  colores, Chip, Tarjeta, estilos de botón, pesos(), fechaCorta()
  AvatarCerdo.swift           ilustración del cerdo por raza; foto propia si existe
  Componentes.swift           AccionRapida, BarraProgreso, ChipRaza, TituloSeccion, Navegacion, barraEstadoOpaca
  Vistas/
    VistaHoy.swift            saludo, progreso, tareas del día, atajos, Mis cerdos
    VistaAnimales.swift       cuadrícula, filtro, búsqueda, alta
    VistaFichaAnimal.swift    foto, peso, destino, notas, venta, baja
    VistaDinero.swift         venta en 3 pasos + Historial
    VistaCompras.swift        compras y comparación de proveedores
    VistaVeterinario.swift    visitas y agenda
    VistaPedidos.swift        pedidos por canal con avance de estado
```

## Principios de diseño (el cliente rechazó dos diseños anteriores)
El cliente dijo: *"no tiene imágenes de los animales y es cero intuitivo"*. Por eso:
1. **Visual primero**: cada animal se reconoce por su imagen (`AvatarCerdo` / foto propia), no por texto.
2. **Una pantalla = una pregunta**: Hoy ¿qué toca hoy? · Animales ¿cuáles son mis cerdos? · Dinero ¿cuánto gano o gasto? · Pedidos ¿qué tengo que entregar?
3. **Acción principal = botón grande con verbo** (56 pt o más): Agregar cerdo, Vender, Nuevo pedido, Marcar por entregar, Marcar entregado.
4. **Cero jerga contable**: "cerdo", "kilos", "vender", "comprar", "pedido".
5. **Un solo camino por tarea**, sin menús ocultos. Siempre hay estado vacío con invitación a actuar y confirmación visible tras guardar.
6. Texto de 17 pt o más en cuerpo; mínimo 13 pt. Objetivos táctiles de 44 pt o más.

Reglas de código:
- `@Query` solo ordena por propiedades **almacenadas**; filtra en Swift por las calculadas (`total`, `resumen`, `canal`, `estado`, `destino`, `raza`, `tipo`).
- Campos numéricos con `@State String` convertido con `Double(...replacingOccurrences(of: ",", with: "."))`, nunca binding directo a `Double`.
- Colores solo de `Tema`. Iconos SF Symbols. Sin emoji ni logotipos de marcas.
- Relleno inferior de 100 pt en cada `ScrollView` para que la barra de pestañas no tape lo último.

## Estado
**Hecho y probado a mano en simulador:** tarea con kilos de alimento, alta de cerdo (también desde el atajo de Hoy), búsqueda y filtro, venta de 96 kg a $40 y a $80, historial con persistencia, pedido nuevo y avance de estado, compra y comparador de proveedores, agendar visita, y las ilustraciones de Común, Minipig y Cruza en la lista y ficha de animales (CP-13, ejecutada en simulador el 30/10/2026).

**Pendiente:**
- **Subir una foto real** (`PhotosPicker`): no se pudo probar, el simulador no tiene fotos. Probar en un iPhone.
- RF-21 historial de pesos por animal (hoy cada actualización reemplaza el peso).
- RF-22 ración y dieta por propósito del animal.
- RF-23 conversión del alimento y costo real por kilogramo calculado (hoy el costo se escribe a mano y no se guarda).
- RF-24 calendario y sanidad por animal.
- RNF-10 accesibilidad de texto escalable según el tamaño configurado en iOS.
- Observación sin causa: dos veces un primer toque en un botón no respondió y funcionó al repetirlo.

**Completado:** certificado de LinkedIn Learning "Swift 5: Protocol-Oriented Programming", emitido a José el 25 de octubre de 2026. Está en `Entregables/Certificado_Swift_5_Protocol_Oriented_Programming.pdf` y se incluye en el informe.

**Fuera de alcance:** sincronización en la nube, leer pedidos de Facebook/WhatsApp automáticamente, pagos electrónicos, Android, cuentas de usuario.

## Entregables y documentación
- `Entregables/Fase_III_Finanzas_Porcinas.docx` (y su `.pdf`): documento maestro estructurado según la actividad de la Fase III. Once capítulos más tres anexos: 1 Introducción, 2 Parte 2 (plan de acción: rumbo, sector y cliente, categorías, prioridades y acciones), 3 Cronograma, 4 Fase I, 5 Fase II, 6 Fase III, 7 Fase IV, 8 Fase V, 9 Evolución del diseño, 10 Certificado, 11 Conclusiones, Referencias y Anexos A (acuerdos verbales), B (carta de firmas) y C (formato de pruebas). Formato fijo: marco en bordes, títulos en Avenir Next 20, cuerpo Arial 10.5 justificado, tablas con encabezado verde #1F3A2E.
- **No editar el .docx a mano.** Se genera con `Archivo/build_fase3.py` a partir de `Archivo/Fase_III_Finanzas_Porcinas_ORIGINAL_2026-10-30.docx` (copia intacta del documento anterior). El script renumera capítulos, inserta las secciones nuevas, reconstruye el índice y calcula sus páginas exportando el PDF con LibreOffice. Usar el Python del runtime (trae `python-docx` y `Pillow`) y revisar el PDF resultante.
- El índice es texto estático: sus páginas se calculan del PDF exportado con LibreOffice, así que hay que regenerarlo si cambia el contenido.
- El informe incluye el Anexo A, una síntesis por perfil de los acuerdos verbales; no inventar nombres, fechas individuales ni citas de conversaciones que no se conservaron.
- `Entregables/01_Cronograma_FaseIII.xlsx` y `.png` (imagen insertada como Figura 1 en el capítulo 4).
- `Entregables/Por_separado/04_Registro_Prueba_CP-13.docx`: ficha de componente con capturas del simulador. La subida de foto real (CP-14) sigue pendiente.
- `Pruebas/Iteracion1_Diseno_original`, `Iteracion2_Diseno_mejorado`, `Iteracion3_Rediseno`: capturas de las tres iteraciones. **Conservarlas siempre**: el capítulo 9 del documento justifica los cambios con ellas (Figuras 8, 10 y 11).
- `Archivo/Iteracion2_Codigo`: código de la iteración 2, archivado.

## Cómo trabajar con José
- Sé **literal con lo que pide el enunciado**: no agregues secciones, datos ni supuestos que no se pidieron. Si falta un dato, haz **una sola tanda de preguntas**.
- Entrega **completo** (sin campos en blanco para que él los llene) y **responde corto**.
- No le propongas ejercicios guiados del libro *App Development with Swift* (por ejemplo el Proyecto Restaurant): los descartó. El capítulo de la Parte 1 (Restaurant) se eliminó del informe por decisión de José; no volver a agregarlo.
- Si cambias la app, vuelve a compilar y comprueba la pantalla con una captura antes de decir que funciona.
