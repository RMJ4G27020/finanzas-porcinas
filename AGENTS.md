# Finanzas Porcinas

App iOS para el **Criadero Fam Rico Moreno**, un emprendimiento familiar de crianza de puercos en Aldama, Tamaulipas. Es el Proyecto Integrador (Fase III. Ejecución) de José Guadalupe Rico Moreno, matrícula AL03063503, materia "Desarrollo de proyecto de aplicaciones móviles", Universidad Tecmilenio. Profesora: Eva María Francisco Santiago. **Entrega: lunes 30 de noviembre de 2026.** Modelo ágil evolutivo.

Todo texto visible al usuario va en **español de México**.

## Quién la usa
- **Virginia del Carmen Moreno Gallegos**: titular, lleva el dinero. Usa Dinero.
- **José**: limpieza y alimentación. Usa Hoy.
- **Dr. Rafael de Leija Lara**: veterinario. Se registran sus visitas.

Se usa **de pie, en el corral, con sol y con guantes**: botones grandes, texto grande, nada que haya que adivinar.

## Datos reales (no inventar nada fuera de esto)
- 17 animales de crianza; 12 puercos al año para venta de carne y derivados.
- Razas: **Común, Minipig y Cruza**.
- Precio de venta: **$40 u $80 por kilogramo según la raza**. **Nunca asignes qué raza vale $80**: el usuario elige el precio.
- Los precios de los insumos varían según el proveedor.
- Los pedidos llegan por Facebook y WhatsApp, pero la app **ya no los maneja** (esa sección se quitó el 20/11/2026): no volver a agregar canales ni pedidos.
- Los datos de ejemplo (20 animales "Cerdo 01" a "Cerdo 20", proveedores A/B/C, 4 visitas) están en `DatosIniciales.swift` y son ilustrativos. Sin KPIs ni totales inventados: todo total se calcula de los datos.

## Cómo compilar y correr
- Xcode 26.4, Swift 5 (language mode), **iOS 18.0 o superior**, SwiftUI + SwiftData, **local y sin internet**, sin dependencias externas.
- Proyecto: `FinanzasPorcinas.xcodeproj`, esquema `FinanzasPorcinas`. Bundle id: `mx.tecmilenio.al03063503.FinanzasPorcinas`.

```bash
xcodebuild -project FinanzasPorcinas.xcodeproj -scheme FinanzasPorcinas \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

Argumentos de lanzamiento para abrir una pantalla directo (sirven para capturas de evidencia):
- `-pantalla hoy | animales | dinero`
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
  VistaPrincipal.swift        TabView de 3 pestañas: Hoy, Animales, Dinero
  Modelos.swift               5 @Model: Animal (con foto: Data?), Tarea, Compra, Venta, VisitaVeterinario; enums; Empresa
  DatosIniciales.swift        siembra del primer arranque
  Tema.swift                  colores, Chip, Tarjeta, estilos de botón, pesos(), fechaCorta()
  AvatarCerdo.swift           imagen del cerdo: foto propia > foto real de la raza > dibujo
  GuiaRazas.swift             info real de cada raza + pantalla Guía de razas (créditos de fotos)
  Componentes.swift           AccionRapida, BarraProgreso, ChipRaza, TituloSeccion, Navegacion, barraEstadoOpaca
  Vistas/
    VistaHoy.swift            saludo, progreso, tareas del día, atajos, Mis cerdos
    VistaAnimales.swift       cuadrícula, filtro, búsqueda, alta
    VistaFichaAnimal.swift    foto, peso, destino, notas, venta, baja
    VistaDinero.swift         venta en 3 pasos + Historial
    VistaCompras.swift        compras y comparación de proveedores
    VistaVeterinario.swift    visitas y agenda
```

## Principios de diseño (el cliente rechazó dos diseños anteriores)
El cliente dijo: *"no tiene imágenes de los animales y es cero intuitivo"*. Por eso:
1. **Visual primero**: cada animal se reconoce por su imagen (`AvatarCerdo` / foto propia), no por texto.
2. **Una pantalla = una pregunta**: Hoy ¿qué toca hoy? · Animales ¿cuáles son mis cerdos? · Dinero ¿cuánto gano o gasto?
3. **Acción principal = botón grande con verbo** (56 pt o más): Agregar cerdo, Vender, Guía de razas.
4. **Cero jerga contable**: "cerdo", "kilos", "vender", "comprar".
5. **Un solo camino por tarea**, sin menús ocultos. Siempre hay estado vacío con invitación a actuar y confirmación visible tras guardar.
6. Texto de 17 pt o más en cuerpo; mínimo 13 pt. Objetivos táctiles de 44 pt o más.

Reglas de código:
- `@Query` solo ordena por propiedades **almacenadas**; filtra en Swift por las calculadas (`total`, `resumen`, `destino`, `raza`, `tipo`).
- Campos numéricos con `@State String` convertido con `Double(...replacingOccurrences(of: ",", with: "."))`, nunca binding directo a `Double`.
- Colores solo de `Tema`. Iconos SF Symbols. Sin emoji ni logotipos de marcas.
- Relleno inferior de 100 pt en cada `ScrollView` para que la barra de pestañas no tape lo último.

## Fotos e información reales (20/11/2026)
- Cada raza usa una **foto real** de Wikimedia Commons (licencia CC BY-SA) como imagen por defecto: `Assets.xcassets/foto_comun`, `foto_minipig`, `foto_cruza`. Son fotos de ejemplo de la raza, no de los cerdos del criadero; la ficha lo indica. Si el animal tiene foto propia (PhotosPicker), esa tiene prioridad.
- `GuiaRazas.swift` guarda los textos (resumidos de Wikipedia) y el crédito de cada foto: autor, licencia y enlace. **No inventar datos de razas**: todo dato nuevo debe tener fuente y crédito. Nunca asignes un precio por raza.
- Atajo "Guía de razas" en Hoy, botón "Razas" en Animales y tarjeta "Sobre la raza" en la ficha.
- Código de la iteración 3 (con Pedidos) archivado en `Archivo/Iteracion3_Codigo`. **El repositorio de GitHub (RMJ4G27020/finanzas-porcinas) y las capturas de él en el informe siguen con la iteración 3**; subir la iteración 4 requiere permiso del alumno. Capturas de esta iteración en `Pruebas/Iteracion4_Fotos_reales`.

## Estado
**Hecho y probado a mano en simulador:** tarea con kilos de alimento, alta de cerdo (también desde el atajo de Hoy), búsqueda y filtro, venta de 96 kg a $40 y a $80, historial con persistencia, compra y comparador de proveedores, agendar visita, y (iteración 4, CP-15, 20/11/2026) la foto real por raza en lista y ficha y la Guía de razas. Casos vigentes: 12 de componente y 4 de integración. Requerimientos: 26 funcionales (19 implementados, 3 retirados, 4 pendientes).

**Pendiente:**
- **Subir una foto real** (`PhotosPicker`): no se pudo probar, el simulador no tiene fotos. Probar en un iPhone.
- RF-21 historial de pesos por animal (hoy cada actualización reemplaza el peso).
- RF-22 ración y dieta por propósito del animal.
- RF-23 conversión del alimento y costo real por kilogramo calculado (hoy el costo se escribe a mano y no se guarda).
- RF-24 calendario y sanidad por animal.
- RNF-10 accesibilidad de texto escalable según el tamaño configurado en iOS.
- Observación sin causa: dos veces un primer toque en un botón no respondió y funcionó al repetirlo.

**Completado:** certificado de LinkedIn Learning "Swift 5: Protocol-Oriented Programming", emitido a José el 25 de octubre de 2026. Está en `Entregables/Certificado_Swift_5_Protocol_Oriented_Programming.pdf` y se incluye en el informe.

**Fuera de alcance:** sincronización en la nube, pedidos y contacto por Facebook/WhatsApp (se quitaron), pagos electrónicos, Android, cuentas de usuario.

## Entregables y documentación
- `Entregables/Fase_III_Finanzas_Porcinas.docx` (y su `.pdf`): documento maestro estructurado según la actividad de la Fase III. Once capítulos más tres anexos: 1 Introducción, 2 Parte 2 (plan de acción: rumbo, sector y cliente, categorías, prioridades y acciones), 3 Cronograma, 4 Fase I, 5 Fase II, 6 Fase III, 7 Fase IV, 8 Fase V, 9 Evolución del diseño, 10 Certificado, 11 Conclusiones, Referencias y Anexos A (acuerdos verbales), B (carta de firmas) y C (formato de pruebas). Formato fijo: marco en bordes, títulos en Avenir Next 20, cuerpo Arial 10.5 justificado, tablas con encabezado verde #1F3A2E.
- **No editar el .docx a mano.** Se genera con `Archivo/build_fase3.py` a partir de `Archivo/Fase_III_Finanzas_Porcinas_ORIGINAL_2026-10-30.docx` (copia intacta del documento anterior). El script renumera capítulos, inserta las secciones nuevas, reconstruye el índice y calcula sus páginas exportando el PDF con LibreOffice. Los cambios de la iteración 4 (sin Pedidos, fotos reales, Guía de razas) se aplican con `Archivo/iteracion4.py`, que el script importa; los requerimientos y pruebas de Pedidos (RF-06, RF-19, RF-20, CP-09, CP-10, PI-02) se marcan como **retirados**, no se borran. Las líneas de código y el número de archivos se cuentan del código real. Usar el Python 3.12 del runtime de Codex (`~/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3.12`; trae `python-docx`, `openpyxl` y `Pillow`; el Python del sistema es 3.9) y revisar el PDF resultante. Versión anterior (30/10/2026): `Archivo/Fase_III_Finanzas_Porcinas_iteracion3_2026-10-30.docx`.
- El índice es texto estático: sus páginas se calculan del PDF exportado con LibreOffice, así que hay que regenerarlo si cambia el contenido.
- El informe incluye el Anexo A, una síntesis por perfil de los acuerdos verbales; no inventar nombres, fechas individuales ni citas de conversaciones que no se conservaron.
- `Entregables/01_Cronograma_FaseIII.xlsx` y `.png` (imagen insertada como Figura 1 en el capítulo 3). Estado al 23/11/2026, con la actividad 4.5 (ajuste final); se genera con `Archivo/actualiza_cronograma.py` a partir de la copia del 30/10 (`Archivo/01_Cronograma_FaseIII_2026-10-30.xlsx`). Si cambia la imagen, vuelve a correr `build_fase3.py`.
- `Entregables/Por_separado/04_Registro_Prueba_CP-13.docx` (iteración 3) y `06_Registro_Prueba_CP-15.docx` (iteración 4, se genera con `Archivo/registro_cp15.py`): fichas de componente con el formato de pruebas de la materia; ambas van en el Anexo C. La subida de foto real (CP-14) sigue pendiente. `02_Listado_de_Requerimientos.docx`, `03_Diseno_de_Solucion.docx` y `05_Prototipos_y_Pruebas.docx` se **regeneran del documento maestro** con `Archivo/build_sueltos.py` (correr después de `build_fase3.py`): 02 = capítulo 4, 03 = capítulo 5, 05 = capítulos 7 y 9; no editarlos a mano.
- **`Entregables/Presentacion_Ejecutiva_Completa_Finanzas_Porcinas.pptx`**: 27 diapositivas con las fases 1 a 4, con diapositivas de **evidencias** (capturas de documentos, certificados, registros de pruebas) por fase, la evolución del diseño y la justificación de los cambios, el video, la satisfacción y las lecciones (José la pidió completa el 23/11/2026; el enunciado dice "máximo dos diapositivas", por eso se conserva también la versión de 2). Se genera con `Archivo/generadores_presentaciones/presentacion_completa.js`.
- Fase final (Parte 2, ejercicio de cierre): `Entregables/Presentacion_Ejecutiva_Finanzas_Porcinas.pptx` (2 diapositivas con el video e índice de satisfacción 5.0 de 5: 8 afirmaciones, todas en 5, **comunicadas por Virginia a José y reportadas por él el 23/11/2026**; no hay comentarios suyos textuales; los datos están en `Archivo/generadores_presentaciones/encuesta_resultados.json`. `Entregables/Encuesta_Satisfaccion_Cliente.docx` es el cuestionario en blanco usado), `Video_Demo_Finanzas_Porcinas.mp4` (grabación del simulador, no del cliente), `Hallazgos_y_Lecciones_Aprendidas.docx` (5 páginas, con el certificado) y `Certificado_Swift_Delegations_and_Data_Sources.pdf` (1/9/2026, extraído del reporte de la fase 2) y `Certificado_Complete_Guide_to_SwiftUI.pdf` (LinkedIn Learning, 23/11/2026, 10 h 57 min; certificado de la fase 4) y `Presentacion_Finanzas_Porcinas.pptx` (7 diapositivas para exponer en 5 minutos).
- `Pruebas/Iteracion1_Diseno_original`, `Iteracion2_Diseno_mejorado`, `Iteracion3_Rediseno`: capturas de las tres iteraciones. **Conservarlas siempre**: el capítulo 9 del documento justifica los cambios con ellas (Figuras 8, 10 y 11).
- `Archivo/Iteracion2_Codigo`: código de la iteración 2, archivado.

## Cómo trabajar con José
- Sé **literal con lo que pide el enunciado**: no agregues secciones, datos ni supuestos que no se pidieron. Si falta un dato, haz **una sola tanda de preguntas**.
- Entrega **completo** (sin campos en blanco para que él los llene) y **responde corto**.
- No le propongas ejercicios guiados del libro *App Development with Swift* (por ejemplo el Proyecto Restaurant): los descartó. El capítulo de la Parte 1 (Restaurant) se eliminó del informe por decisión de José; no volver a agregarlo.
- Si cambias la app, vuelve a compilar y comprueba la pantalla con una captura antes de decir que funciona.
