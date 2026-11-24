// Presentación ejecutiva completa: fases 1 a 4, justificaciones de cambios, video y cierre.
const fs = require("fs");
const pptxgen = require("pptxgenjs");
const SK = "/Users/joserico/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/805aae63-7cf0-4743-8bcd-1c13064bad77/0b4967d2-8cd3-4801-95dd-dd8ed4a09324/skills/pptx";
const { applyTheme } = require(SK + "/scripts/apply_theme.js");

const OUT = process.argv[2];
const VIDEO = process.argv[3];
const ENC = JSON.parse(fs.readFileSync(process.argv[4], "utf-8"));

const THEME = {
  name: "Finanzas Porcinas",
  headFontFace: "Cambria",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1D1B16", lt1: "FFFFFF", dk2: "2F5D46", lt2: "F6F2EA",
    accent1: "2F5D46", accent2: "B4533A", accent3: "E3EFE6",
    accent4: "F7E6D3", accent5: "5E574B", accent6: "E4DDD0",
    hlink: "B4533A", folHlink: "5E574B",
  },
};
const pres = new pptxgen();
pres.layout = "LAYOUT_16x9"; // 10 x 5.625 in
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
pres.title = "Presentación ejecutiva completa · Finanzas Porcinas";
pres.author = "José Guadalupe Rico Moreno";
const C = pres.SchemeColor;

pres.defineSlideMaster({
  title: "PORTADA", background: { color: "2F5D46" },
  objects: [{ placeholder: { options: { name: "title", type: "title", x: 0.6, y: 1.2, w: 5.0, h: 1.4, fontSize: 44, bold: true, color: C.background1, valign: "top", align: "left", margin: 0 }, text: "" } }],
});
pres.defineSlideMaster({
  title: "CONTENIDO", background: { color: "FFFFFF" },
  slideNumber: { x: 9.2, y: 5.2, w: 0.4, h: 0.3, fontSize: 11, color: C.accent5, align: "right" },
  objects: [{ placeholder: { options: { name: "title", type: "title", x: 0.5, y: 0.25, w: 9.0, h: 0.7, fontSize: 28, bold: true, color: C.text2, valign: "middle", align: "left", margin: 0 }, text: "" } }],
});
pres.defineSlideMaster({
  title: "CIERRE", background: { color: "2F5D46" },
  slideNumber: { x: 9.2, y: 5.2, w: 0.4, h: 0.3, fontSize: 11, color: C.background2, align: "right" },
  objects: [{ placeholder: { options: { name: "title", type: "title", x: 0.5, y: 0.25, w: 9.0, h: 0.7, fontSize: 28, bold: true, color: C.background1, valign: "middle", align: "left", margin: 0 }, text: "" } }],
});
const BODY = { fontFace: "Calibri", isTextBox: true, margin: 0 };

// ---------- ayudas ----------
const etiqueta = (s, texto, x, y, w, nombre) =>
  s.addText(texto, { ...BODY, x, y, w, h: 0.3, fontSize: 15, bold: true, color: C.text2, fontFace: "Cambria", objectName: nombre || ("Etiqueta " + texto) });
const H = (t) => ({ text: t, options: { bold: true, color: C.background1, fill: { color: C.accent1 }, fontSize: 11, fontFace: "Calibri", valign: "middle" } });
const R = (t, o = {}) => ({ text: t, options: { fontSize: 11, fontFace: "Calibri", color: C.text1, valign: "middle", ...o } });
const OK = (t) => R(t, { bold: true, color: C.accent1 });
const tabla = (s, rows, x, y, w, colW, nombre, rowH = 0.42) =>
  s.addTable(rows, { x, y, w, colW, rowH, border: { type: "solid", pt: 0.75, color: C.accent6 }, margin: [0.04, 0.08, 0.04, 0.08], fill: { color: C.background1 }, objectName: nombre });
const stat = (s, x, y, w, h, num, texto, nombre, tam = 36) => {
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.12, fill: { color: C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Tarjeta " + nombre });
  s.addText(num, { ...BODY, x, y: y + 0.08, w, h: h * 0.5, fontSize: tam, bold: true, color: C.text2, fontFace: "Cambria", align: "center", valign: "middle", objectName: "Cifra " + nombre });
  s.addText(texto, { ...BODY, x: x + 0.1, y: y + h * 0.55, w: w - 0.2, h: h * 0.4, fontSize: 12, color: C.text1, align: "center", valign: "top", objectName: "Texto " + nombre });
};
const lista = (s, items, x, y, w, h, size, nombre) =>
  s.addText(items.map((t, i) => ({ text: t, options: { bullet: true, breakLine: i < items.length - 1 } })),
    { ...BODY, x, y, w, h, fontSize: size, color: C.text1, valign: "top", paraSpaceAfter: 5, objectName: nombre });

const secciones = new Set();
const nueva = (master, sec) => {
  if (!secciones.has(sec)) { pres.addSection({ title: sec }); secciones.add(sec); }
  return pres.addSlide({ masterName: master, sectionTitle: sec });
};

// ---------- 1. Portada ----------
let s = nueva("PORTADA", "Visión general");
s.addText("Finanzas Porcinas", { placeholder: "title" });
s.addText("Presentación ejecutiva del proyecto: fases 1 a 4", { ...BODY, x: 0.6, y: 2.75, w: 4.9, h: 0.8, fontSize: 20, color: C.background2, valign: "top", objectName: "Subtítulo" });
s.addText([
  { text: "José Guadalupe Rico Moreno · AL03063503", options: { breakLine: true, bold: true } },
  { text: "Desarrollo de proyecto de aplicaciones móviles", options: { breakLine: true } },
  { text: "Universidad Tecmilenio · Profesora Eva María Francisco Santiago", options: {} },
], { ...BODY, x: 0.6, y: 3.9, w: 5.0, h: 1.0, fontSize: 14, color: C.background1, valign: "top", paraSpaceAfter: 4, objectName: "Autor" });
s.addImage({ path: "portada.png", x: 5.95, y: 0.9, w: 3.5, h: 3.5, altText: "Foto real de un cerdo miniatura (minipig)", objectName: "Foto minipig" });
s.addText("Foto: Fcobmz · CC BY-SA 4.0 · Wikimedia Commons", { ...BODY, x: 5.95, y: 4.5, w: 3.5, h: 0.3, fontSize: 10, color: C.background2, objectName: "Crédito foto" });
s.addNotes("Buenas tardes. Soy José Guadalupe Rico Moreno y presento Finanzas Porcinas, la app de iOS que hice para el Criadero Fam Rico Moreno, el emprendimiento de crianza de puercos de mi familia en Aldama, Tamaulipas. Esta presentación recorre las cuatro fases del proyecto, los cambios que pidió el cliente y por qué se hicieron, la demostración en video y los resultados de la fase final.");

// ---------- 2. Objetivo y ruta ----------
s = nueva("CONTENIDO", "Visión general");
s.addText("Objetivo general y ruta del proyecto", { placeholder: "title" });
s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.5, y: 1.1, w: 9.0, h: 0.8, rectRadius: 0.1, fill: { color: C.accent3 }, line: { color: C.accent3 }, objectName: "Caja objetivo" });
s.addText([{ text: "Objetivo general: ", options: { bold: true, color: C.text2 } },
  { text: "construir una app de iOS para el Criadero Fam Rico Moreno que registre los cerdos, las tareas del día y las compras y ventas, en lugar de llevarlo de memoria y en libretas.", options: { color: C.text1 } }],
  { ...BODY, x: 0.7, y: 1.15, w: 8.6, h: 0.7, fontSize: 14, valign: "middle", objectName: "Objetivo general" });
const fases = [
  ["Fase 1", "Fundamentos Swift", "20 ago 2026", "Portafolio de 13 evidencias, reflexión y app de lista de tareas."],
  ["Fase 2", "Planteamiento", "24 ago – 4 sep 2026", "Selección de la empresa: reporte, carta de interés, minuta y solicitud de autorización."],
  ["Fase 3", "Ejecución", "26 oct – 30 nov 2026", "App funcional y documento integrado de cinco etapas."],
  ["Fase 4", "Cierre", "Noviembre 2026", "Presentación ejecutiva, video, satisfacción del cliente y lecciones aprendidas."],
];
fases.forEach((f, i) => {
  const x = 0.5 + i * 2.3;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 2.1, w: 2.1, h: 2.95, rectRadius: 0.12, fill: { color: C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Tarjeta " + f[0] });
  s.addText(f[0], { ...BODY, x: x + 0.15, y: 2.2, w: 1.8, h: 0.35, fontSize: 20, bold: true, color: C.accent2, fontFace: "Cambria", objectName: "Fase " + (i + 1) });
  s.addText(f[1], { ...BODY, x: x + 0.15, y: 2.6, w: 1.85, h: 0.35, fontSize: 13, bold: true, color: C.text2, objectName: "Nombre " + f[0] });
  s.addText(f[2], { ...BODY, x: x + 0.15, y: 2.95, w: 1.8, h: 0.3, fontSize: 12, color: C.accent5, objectName: "Fecha " + f[0] });
  s.addText(f[3], { ...BODY, x: x + 0.15, y: 3.35, w: 1.8, h: 1.6, fontSize: 12, color: C.text1, valign: "top", objectName: "Entregable " + f[0] });
});
s.addNotes("El objetivo general es construir una app de iOS que registre los cerdos, las tareas del día y las compras y ventas del criadero, que antes se llevaban de memoria y en libretas. El proyecto tuvo cuatro fases: en la primera aprendí los fundamentos de Swift; en la segunda planteé el proyecto y elegí la empresa; en la tercera construí la app; y la cuarta es este cierre. Se trabajó con un modelo ágil evolutivo: el diseño cambió cuatro veces.");

// ---------- 3. Fase 1 ----------
s = nueva("CONTENIDO", "Fase 1");
s.addText("Fase 1 · Fundamentos de Swift", { placeholder: "title" });
stat(s, 0.5, 1.15, 2.8, 1.5, "13", "evidencias en el portafolio", "evidencias");
stat(s, 3.6, 1.15, 2.8, 1.5, "0 / 0", "errores y advertencias en el modo estricto de Swift 6", "errores", 34);
stat(s, 6.7, 1.15, 2.8, 1.5, "38", "comprobaciones automáticas en la app de tareas", "pruebas");
etiqueta(s, "Documentación entregada (20 de agosto de 2026)", 0.5, 2.95, 9.0, "Título documentación fase 1");
lista(s, [
  "Portafolio de la asignatura LSTI6005 respaldado por el certificado Swift 5 Essential Training (LinkedIn Learning).",
  "Reflexión de cuatro preguntas: conocimientos, secuencia de aprendizaje, habilidades y actitudes.",
  "App Lista de tareas en SwiftUI: agregar, completar y eliminar tareas, con persistencia en JSON; 5 errores reales documentados.",
  "Base de la Fase 3: opcionales, colecciones, protocolos y SwiftUI.",
], 0.5, 3.3, 9.0, 1.8, 14, "Documentación fase 1");
s.addNotes("La fase 1 fue el portafolio de Swift: trece evidencias, todas con cero errores y cero advertencias en el modo estricto de Swift 6, una reflexión de cuatro preguntas y una app de lista de tareas en SwiftUI con 38 comprobaciones automáticas y cinco errores reales documentados. Estuvo respaldada por el certificado Swift 5 Essential Training de LinkedIn Learning. Esta base me permitió construir después la app del criadero.");

// ---------- evidencias ----------
const EVA = JSON.parse(fs.readFileSync("ev_assets.json", "utf-8"));
const evid = (s, items, y0 = 1.1, maxH = 3.5) => {
  const n = items.length, gap = 0.3, boxW = (9.0 - gap * (n - 1)) / n;
  items.forEach((it, i) => {
    const [iw, ih] = EVA[it.n];
    const k = Math.min(boxW / iw, maxH / ih), w = iw * k, h = ih * k;
    const x = 0.5 + i * (boxW + gap) + (boxW - w) / 2;
    const ext = it.n.startsWith("f1_") ? "png" : "jpg";
    s.addImage({ path: "ev_" + it.n + "." + ext, x, y: y0 + (maxH - h) / 2, w, h, altText: it.t, objectName: "Evidencia " + it.n, ...(ext === "jpg" ? { } : {}) });
    s.addText(it.t, { ...BODY, x: 0.5 + i * (boxW + gap), y: y0 + maxH + 0.12, w: boxW, h: 0.62, fontSize: 11, color: C.accent5, align: "center", valign: "top", objectName: "Pie " + it.n });
  });
};

// ---------- Evidencias Fase 1 ----------
s = nueva("CONTENIDO", "Fase 1");
s.addText("Fase 1 · Evidencias", { placeholder: "title" });
evid(s, [
  { n: "cert_essential", t: "Certificado Swift 5 Essential Training, LinkedIn Learning" },
  { n: "f1_menu", t: "Portafolio: app de ejemplos de lo aprendido, menú principal" },
  { n: "f1_tarea1", t: "Evidencia 13: tarea ejecutada en el simulador de iPhone" },
]);
s.addNotes("Estas son las evidencias de la fase 1: el certificado del curso Swift 5 Essential Training de LinkedIn Learning que respalda el portafolio, y capturas de la app de ejemplos de lo aprendido ejecutándose en el simulador de iPhone, que forman parte de la evidencia 13.");

const evidGrid = (s, items) => {
  const gap = 0.3, cw = (9.0 - gap) / 2, ih = 1.75, ch = ih + 0.5;
  items.forEach((it, i) => {
    const [iw, ihh] = EVA[it.n];
    const k = Math.min(cw / iw, ih / ihh), w = iw * k, h = ihh * k;
    const col = i % 2, row = Math.floor(i / 2);
    const x0 = 0.5 + col * (cw + gap), y0 = 1.05 + row * (ch + 0.08);
    s.addImage({ path: "ev_" + it.n + ".jpg", x: x0 + (cw - w) / 2, y: y0 + (ih - h) / 2, w, h, altText: it.t, objectName: "Evidencia " + it.n });
    s.addText(it.t, { ...BODY, x: x0, y: y0 + ih + 0.04, w: cw, h: 0.4, fontSize: 11, color: C.accent5, align: "center", valign: "top", objectName: "Pie " + it.n });
  });
};

// ---------- 4. Fase 2 requisitos ----------
s = nueva("CONTENIDO", "Fase 2");
s.addText("Fase 2 · Planteamiento: selección de la empresa", { placeholder: "title" });
tabla(s, [
  [H("Requisito"), H("Evidencia"), H("Estado")],
  [R("1.1 La empresa no tiene app móvil"), R("Búsquedas en App Store, Google Play y web, 2 sep 2026"), OK("Cumple")],
  [R("1.2 Interés manifestado por escrito"), R("Carta de la titular, 30 ago 2026"), OK("Cumple")],
  [R("1.3 Productos y servicios para la app"), R("Capítulo 4 del reporte"), OK("Cumple")],
  [R("1.4 Aprobación con alcance académico"), R("Minuta del 30 ago 2026"), OK("Cumple")],
  [R("1.5 Aprobación de la profesora"), R("Solicitud enviada el 4 sep 2026"), R("Enviada", { bold: true, color: C.accent2 })],
], 0.5, 1.15, 9.0, [3.2, 4.4, 1.4], "Tabla requisitos fase 2", 0.45);
etiqueta(s, "Cómo se levantó la información", 0.5, 3.95, 9.0, "Título sesiones");
lista(s, [
  "7 sesiones de trabajo de 2 horas, del 24 al 30 de agosto de 2026, con la titular, Virginia del Carmen Moreno Gallegos.",
  "Reporte entregado el viernes 4 de septiembre de 2026, con la carta de manifestación de interés y la minuta como anexos.",
], 0.5, 4.3, 9.0, 0.9, 13, "Sesiones fase 2");
s.addNotes("En la fase 2 elegí la empresa candidata y verifiqué los requisitos. El criadero no tiene app en las tiendas, lo comprobé con búsquedas el 2 de septiembre. La titular manifestó su interés por escrito el 30 de agosto y la minuta de ese día asienta que es una versión con alcance académico, sin costo. La solicitud de autorización a la profesora se envió el 4 de septiembre. La información salió de siete sesiones de dos horas con mi mamá.");

// ---------- Evidencias Fase 2 (requisitos) ----------
s = nueva("CONTENIDO", "Fase 2");
s.addText("Fase 2 · Evidencias de los requisitos", { placeholder: "title" });
evidGrid(s, [
  { n: "f2_busq", t: "Búsquedas en App Store, Google Play y web, 2 sep 2026" },
  { n: "f2_carta", t: "Carta de manifestación de interés, 30 ago 2026" },
  { n: "f2_firmas", t: "Firmas de la titular y del alumno en la minuta, 30 ago 2026" },
  { n: "f2_solic", t: "Solicitud de autorización a la profesora, 4 sep 2026" },
]);
s.addNotes("Estas son las evidencias de los requisitos de la fase 2, tomadas del reporte entregado el 4 de septiembre: las búsquedas que comprueban que la empresa no tiene app, la carta de manifestación de interés de la titular, las firmas de la titular y del alumno en la minuta, y el texto de la solicitud de autorización enviada a la profesora.");

// ---------- 5. Fase 2 análisis ----------
s = nueva("CONTENIDO", "Fase 2");
s.addText("Fase 2 · Análisis de la empresa", { placeholder: "title" });
tabla(s, [
  [H("Punto"), H("Hallazgo")],
  [R("3. Antecedentes", { bold: true }), R("Empezó en 2018 con 5 puercos; hoy tiene 17 de crianza y vende 12 al año.")],
  [R("4. Productos", { bold: true }), R("Carne de puerco y derivados por kilogramo, de $40 a $80 según la raza.")],
  [R("5. Organigrama", { bold: true }), R("Tres personas: Virginia (titular, finanzas), José (limpieza y alimentación) y el Dr. Rafael de Leija Lara (veterinario).")],
  [R("6. Clientes", { bold: true }), R("Vecinos de las colonias de Aldama, por WhatsApp, y contactos de Facebook de la titular.")],
  [R("7. Competidores", { bold: true }), R("Granjas tecnificadas de Tamaulipas, carnicerías de Aldama, criaderos de traspatio y autoservicios.")],
  [R("8. Sustitutos", { bold: true }), R("Pollo (37 % del consumo nacional), res (22 %) y cerdo de granjas tecnificadas.")],
  [R("9. FODA", { bold: true }), R("Fortaleza: venta directa y precio sobre la referencia nacional ($36.98/kg). Debilidad: no registra peso, alimento ni costo. Oportunidad: consumo de cerdo de 26.5 kg per cápita. Amenaza: el cerdo en pie bajó cerca de 30 % en 2026.")],
], 0.5, 1.1, 9.0, [1.7, 7.3], "Tabla análisis empresa", 0.45);
s.addNotes("Estos son los siete puntos del análisis de la empresa. Antecedentes: empezó en 2018 con cinco puercos y hoy tiene diecisiete de crianza. Productos: carne y derivados por kilo, de 40 a 80 pesos según la raza. El organigrama tiene tres personas. Los clientes llegan por WhatsApp y Facebook. Los competidores son las granjas tecnificadas del estado y las carnicerías; los sustitutos son el pollo y la res. El FODA muestra que la debilidad principal es que no se registra peso, alimento ni costo, y eso es lo que la app resuelve.");

// ---------- 6. Fase 2 presentación ejecutiva ----------
s = nueva("CONTENIDO", "Fase 2");
s.addText("Fase 2 · Oportunidad y propuesta", { placeholder: "title" });
const cuad = [
  ["Áreas de oportunidad", "Sin registro del peso, el alimento ni la raza de cada animal; no se conoce el costo por kilo; los precios de los insumos no se comparan; los pedidos se atendían de memoria."],
  ["Medios digitales actuales", "Facebook, desde la cuenta personal de la titular, y WhatsApp, en grupos de colonias. Sin sitio web ni aplicación propia."],
  ["Propuesta de incursión", "App nativa de iOS, Finanzas Porcinas, para animales, tareas del día, compras, ventas y visitas del veterinario, sin conexión a internet."],
  ["Impacto esperado", "Registrar el día a día, fijar el precio conociendo el costo y demostrar la raza, la alimentación y la atención veterinaria de cada animal."],
];
cuad.forEach((q, i) => {
  const x = 0.5 + (i % 2) * 4.6, y = 1.15 + Math.floor(i / 2) * 2.05;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w: 4.4, h: 1.9, rectRadius: 0.12, fill: { color: i % 2 ? C.accent3 : C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Cuadro " + q[0] });
  s.addText(q[0], { ...BODY, x: x + 0.2, y: y + 0.12, w: 4.0, h: 0.35, fontSize: 16, bold: true, color: C.text2, fontFace: "Cambria", objectName: "Título " + q[0] });
  s.addText(q[1], { ...BODY, x: x + 0.2, y: y + 0.55, w: 4.0, h: 1.25, fontSize: 13, color: C.text1, valign: "top", objectName: "Texto " + q[0] });
});
s.addNotes("La presentación ejecutiva de la fase 2 tenía cuatro puntos. Áreas de oportunidad: el criadero no registra peso, alimento ni costo. Medios digitales: solo Facebook personal y WhatsApp, sin sitio web ni app. Propuesta: una app nativa de iOS sin conexión a internet. Impacto esperado: registrar el día a día y fijar el precio conociendo el costo.");

// ---------- Evidencias Fase 2 (análisis) ----------
s = nueva("CONTENIDO", "Fase 2");
s.addText("Fase 2 · Evidencias del análisis y del curso", { placeholder: "title" });
evid(s, [
  { n: "f2_org", t: "Organigrama y principales clientes de la empresa" },
  { n: "f2_foda", t: "Análisis FODA de la empresa" },
  { n: "cert_deleg", t: "Certificado Swift: Delegations and Data Sources, 1 sep 2026" },
]);
s.addNotes("Evidencias del análisis de la empresa: el organigrama con los principales clientes y el análisis FODA, ambos del reporte de la fase 2. También el certificado del curso Swift: Delegations and Data Sources de LinkedIn Learning, completado el primero de septiembre de 2026.");

// ---------- 7. Fase 3 plan de acción ----------
s = nueva("CONTENIDO", "Fase 3");
s.addText("Fase 3 · Plan de acción y entregable de cada etapa", { placeholder: "title" });
tabla(s, [
  [H("Etapa"), H("Fechas"), H("Entregable"), H("Estado")],
  [R("Análisis de requerimientos"), R("26 oct – 1 nov"), R("Listado de requerimientos posibles y alcanzables"), OK("Concluida")],
  [R("Diseño de solución"), R("2 – 8 nov"), R("Documento de diseño de solución"), OK("Concluida")],
  [R("Construcción"), R("9 – 18 nov"), R("Archivos de programación y de diseño editables"), OK("Concluida")],
  [R("Pruebas"), R("19 – 24 nov"), R("Prototipos y resultados de cada prueba"), OK("Concluida")],
  [R("Integración"), R("25 – 29 nov"), R("App completa y funcional"), R("En curso · 94 %", { bold: true, color: C.accent2 })],
  [R("Entrega"), R("30 nov"), R("Documento integrado de la Fase 3"), R("30 nov", { bold: true, color: C.accent2 })],
], 0.5, 1.15, 9.0, [2.4, 1.5, 3.6, 1.5], "Tabla plan de acción", 0.46);
lista(s, [
  "Cronograma de 25 actividades en 01_Cronograma_FaseIII.xlsx, con una fila Real por etapa para comparar plan y avance.",
  "Se terminó antes de lo planeado; el 20 de noviembre se agregó la actividad 4.5, el ajuste final (iteración 4).",
], 0.5, 4.5, 9.0, 0.8, 12, "Notas cronograma");
s.addNotes("En la fase 3 el plan de acción tiene cinco etapas más la entrega, cada una con su entregable: requerimientos, diseño, programación, pruebas y la app funcional; el documento integrado se entrega el 30 de noviembre. El cronograma tiene 25 actividades y una fila de avance real por etapa. Las cuatro primeras etapas están concluidas y la integración va al 94 por ciento, porque falta cerrar los entregables de esta fase.");

// ---------- Evidencias Fase 3 (plan) ----------
s = nueva("CONTENIDO", "Fase 3");
s.addText("Fase 3 · Evidencias del plan y los requerimientos", { placeholder: "title" });
evid(s, [
  { n: "crono", t: "Cronograma de la fase 3 al 23 de noviembre, con la fila Real de cada etapa" },
  { n: "req", t: "Listado de requerimientos, primera página (prioridad, complejidad y estado)" },
]);
s.addNotes("Evidencias del plan de acción: el cronograma de la fase 3, con el estado al 23 de noviembre y la fila de avance real de cada etapa, y la primera página del listado de requerimientos, donde cada uno tiene su prioridad, su complejidad y su estado.");

// ---------- 8. Fase 3 requerimientos y diseño ----------
s = nueva("CONTENIDO", "Fase 3");
s.addText("Fase 3 · Requerimientos y diseño de la solución", { placeholder: "title" });
stat(s, 0.5, 1.15, 2.0, 1.6, "26", "requerimientos funcionales", "RF");
stat(s, 2.65, 1.15, 2.0, 1.6, "10", "requerimientos no funcionales", "RNF");
stat(s, 4.8, 1.15, 2.0, 1.6, "5", "fuera de alcance", "FA");
s.addText("De los 26 funcionales: 19 implementados, 3 retirados el 20 de noviembre (pedidos) y 4 pendientes (historial de pesos, ración y dieta, costo real por kilo y calendario de sanidad).", { ...BODY, x: 0.5, y: 2.95, w: 6.3, h: 1.0, fontSize: 13, color: C.text1, valign: "top", objectName: "Detalle requerimientos" });
etiqueta(s, "Diseño de la solución", 7.1, 1.15, 2.4, "Título diseño");
lista(s, [
  "SwiftUI y SwiftData, iOS 18 o superior",
  "Local, sin internet",
  "5 modelos de datos",
  "3 pestañas: Hoy, Animales y Dinero",
  "Una pantalla, una pregunta",
  "Botones de 56 pt o más",
], 7.1, 1.5, 2.4, 2.9, 12, "Lista diseño");
etiqueta(s, "Entregables", 0.5, 4.0, 6.3, "Título entregables fase 3b");
s.addText("Listado de requerimientos y documento de diseño: arquitectura, modelo de datos, diagrama de navegación, requerimientos de diseño y componentes.", { ...BODY, x: 0.5, y: 4.35, w: 6.3, h: 0.8, fontSize: 12, color: C.text1, valign: "top", objectName: "Texto entregables diseño" });
s.addNotes("En requerimientos se levantaron veintiséis funcionales, diez no funcionales y cinco fuera de alcance. Hoy hay diecinueve implementados, tres retirados cuando se quitó la sección de pedidos y cuatro pendientes. El diseño usa SwiftUI y SwiftData, funciona sin internet, tiene cinco modelos de datos y tres pestañas. Cada pantalla responde una pregunta y los botones son grandes porque se usa de pie, en el corral y con guantes.");

// ---------- Evidencias Fase 3 (diseño y código) ----------
s = nueva("CONTENIDO", "Fase 3");
s.addText("Fase 3 · Evidencias del diseño y el código", { placeholder: "title" });
evid(s, [
  { n: "nav", t: "Diagrama de navegación de la app" },
  { n: "gh4", t: "Repositorio en GitHub con la iteración 4 publicada (github.com/RMJ4G27020/finanzas-porcinas)" },
  { n: "commit", t: "Commit de la iteración 4: sin pedidos, fotos reales y Guía de razas (118 archivos)" },
]);
s.addNotes("Evidencias del diseño y el código: el diagrama de navegación de la aplicación, el repositorio del proyecto en GitHub con la iteración 4 ya publicada, y el commit de esa iteración, que quita la sección de pedidos y agrega las fotos reales y la guía de razas, con ciento dieciocho archivos modificados.");

// ---------- 9. Fase 3 construcción y pruebas ----------
s = nueva("CONTENIDO", "Fase 3");
s.addText("Fase 3 · Construcción y pruebas", { placeholder: "title" });
stat(s, 0.5, 1.15, 2.7, 1.2, "14", "archivos Swift · 5,403 líneas", "archivos", 32);
stat(s, 0.5, 2.5, 2.7, 1.2, "12 + 4", "casos de componente e integración aprobados", "casos", 32);
stat(s, 0.5, 3.85, 2.7, 1.2, "6", "defectos encontrados y corregidos", "defectos", 32);
tabla(s, [
  [H("Defecto"), H("Corrección")],
  [R("DEF-01 Etiqueta de sección sin nombre de parámetro"), R("Inicializador sin etiqueta")],
  [R("DEF-02 El conteo de crianza mostraba 4"), R("Sembrado de los 17 animales reales")],
  [R("DEF-03 La última tarjeta quedaba bajo la barra"), R("Relleno inferior de 100 pt")],
  [R("DEF-04 Agregar cerdo no abría el formulario"), R("Objeto de navegación compartido")],
  [R("DEF-05 El contenido pasaba bajo la hora"), R("Franja superior con el color de fondo")],
  [R("DEF-06 Mostraba la fecha de siembra como ingreso"), R("Se sustituyó por la raza")],
], 3.5, 1.15, 6.0, [3.4, 2.6], "Tabla defectos", 0.42);
s.addText("Pendiente: CP-14, subir una foto propia, no se pudo probar porque el simulador no tiene fotografías; falta probarlo en un iPhone real.", { ...BODY, x: 3.5, y: 4.3, w: 6.0, h: 0.75, fontSize: 12, color: C.accent2, bold: true, valign: "top", objectName: "Pendiente CP-14" });
s.addNotes("La app tiene catorce archivos Swift y cinco mil cuatrocientas líneas. Hay doce casos de prueba de componente y cuatro de integración aprobados en el simulador. Se encontraron y corrigieron seis defectos, por ejemplo que el atajo Agregar cerdo solo cambiaba de pestaña, o que el contenido pasaba bajo la hora y la batería. Lo único sin probar es subir una foto propia, porque el simulador no tiene fotografías; eso falta hacerlo en un iPhone real.");

// ---------- Evidencias Fase 3 (pruebas) ----------
s = nueva("CONTENIDO", "Fase 3");
s.addText("Fase 3 · Evidencias de las pruebas", { placeholder: "title" });
evid(s, [
  { n: "cp13", t: "Registro de la prueba CP-13, formato de la materia (iteración 3)" },
  { n: "cp15a", t: "Registro de la prueba CP-15 (iteración 4)" },
  { n: "cp15c", t: "Capturas del simulador y conclusiones de CP-15" },
]);
s.addNotes("Evidencias de las pruebas: los registros de las pruebas CP-13, de la iteración 3, y CP-15, de la iteración 4, en el formato de pruebas de la materia, con el entorno, los pasos, el resultado esperado y el obtenido, y las capturas del simulador.");

// ---------- Evidencias Fase 3 (conformidad y certificado) ----------
s = nueva("CONTENIDO", "Fase 3");
s.addText("Fase 3 · Conformidad del cliente y certificado", { placeholder: "title" });
evid(s, [
  { n: "carta", t: "Carta de conformidad y firmas de la Parte 2" },
  { n: "cert_pop", t: "Certificado Swift 5: Protocol-Oriented Programming, 25 oct 2026" },
]);
s.addNotes("Evidencias de la conformidad del cliente y del curso de la fase 3: la carta de conformidad con los espacios de firma de la empresa, el alumno y la profesora, y el certificado del curso Swift 5: Protocol-Oriented Programming de LinkedIn Learning, del 25 de octubre de 2026.");

// ---------- 10. Evolución del diseño ----------
s = nueva("CONTENIDO", "Cambios");
s.addText("Evolución del diseño: cuatro iteraciones", { placeholder: "title" });
const its = [
  ["i1.png", "Iteración 1 · 25 oct", "“La app no es muy buena.”"],
  ["i2.png", "Iteración 2 · 26 oct", "“No me termina de gustar nada el diseño: no tiene imágenes de los animales y es cero intuitivo.”"],
  ["i3.png", "Iteración 3 · 26 oct", "Cuatro pestañas visuales, con una ilustración por raza."],
  ["i4.png", "Iteración 4 · 20 nov", "Sin pedidos y con fotos reales. Versión final aprobada por la titular."],
];
its.forEach((it, i) => {
  const x = 0.5 + i * 2.3;
  s.addImage({ path: it[0], x: x + 0.37, y: 1.05, w: 1.36, h: 2.9, altText: it[1], objectName: "Captura " + it[1] });
  s.addText(it[1], { ...BODY, x, y: 4.05, w: 2.1, h: 0.3, fontSize: 13, bold: true, color: i < 2 ? C.accent2 : C.text2, align: "center", objectName: "Título " + it[1] });
  s.addText(it[2], { ...BODY, x, y: 4.35, w: 2.1, h: 0.95, fontSize: 11, color: C.text1, align: "center", valign: "top", objectName: "Texto " + it[1] });
});
s.addNotes("El diseño evolucionó en cuatro iteraciones. La primera, con cinco pestañas por módulos, recibió la observación de que la app no era muy buena. La segunda mejoró la jerarquía y la accesibilidad, pero la titular dijo que no le gustaba, que no tenía imágenes de los animales y que era cero intuitiva; por eso se descartó y se reconstruyó desde cero. La tercera tiene pestañas que responden preguntas y una ilustración por raza. La cuarta es el ajuste final: sin pedidos y con fotos reales, y esa versión la aprobó la titular.");

// ---------- 11. Justificación de los cambios ----------
s = nueva("CONTENIDO", "Cambios");
s.addText("Justificación de los cambios pedidos por el cliente", { placeholder: "title" });
tabla(s, [
  [H("Lo que pidió el cliente"), H("Qué se concluyó"), H("Qué se hizo")],
  [R("“No tiene imágenes de los animales.”", { bold: true }), R("Solo por texto (“Cerdo 03”); en el corral se reconoce por su aspecto."), R("Imagen por raza en lista, Hoy, ficha y venta; luego, fotos reales.")],
  [R("“Es cero intuitivo.”", { bold: true }), R("Módulos contables (Bitácora, Finanzas) ajenos al criadero."), R("Pestañas que responden una pregunta: Hoy, Animales y Dinero.")],
  [R("Acciones difíciles de encontrar", { bold: true }), R("Vender exigía navegar y adivinar controles."), R("Un botón grande con verbo por pantalla; los atajos abren el formulario.")],
  [R("Aspecto de sistema contable", { bold: true }), R("Listas, mayúsculas y formularios con campos sueltos."), R("Venta en tres pasos numerados y el total en grande.")],
], 0.5, 1.1, 9.0, [2.3, 3.2, 3.5], "Tabla justificación", 0.62);
s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.5, y: 4.55, w: 8.6, h: 0.65, rectRadius: 0.1, fill: { color: C.accent3 }, line: { color: C.accent3 }, objectName: "Caja conservado" });
s.addText([{ text: "Se conservó: ", options: { bold: true, color: C.text2 } }, { text: "los modelos de datos, los datos del criadero, los cálculos y la regla de que la persona elige el precio, $40 u $80 por kilo.", options: { color: C.text1 } }], { ...BODY, x: 0.7, y: 4.57, w: 8.2, h: 0.6, fontSize: 12, valign: "middle", objectName: "Texto conservado" });
s.addNotes("Esta tabla justifica cada cambio: lo que pidió el cliente, lo que se concluyó y lo que se hizo. Que no había imágenes de los animales se resolvió con una imagen por raza y, al final, con fotos reales. Que era cero intuitivo se resolvió reorganizando en pestañas que responden una pregunta. Las acciones difíciles de encontrar se resolvieron con un botón grande con verbo por pantalla, y el aspecto contable con la venta en tres pasos. No cambiaron los datos ni las reglas del negocio.");

// ---------- 12. Iteración 4 ----------
s = nueva("CONTENIDO", "Cambios");
s.addText("Iteración 4 · Sin pedidos y con fotos reales", { placeholder: "title" });
tabla(s, [
  [H("Elemento"), H("Iteración 3"), H("Iteración 4")],
  [R("Pestañas"), R("Hoy, Animales, Dinero y Pedidos"), R("Hoy, Animales y Dinero")],
  [R("Imagen del cerdo"), R("Ilustración dibujada por raza"), R("Foto real de la raza o foto propia")],
  [R("Información de razas"), R("Ninguna"), R("Guía de razas con datos y créditos")],
  [R("Atajos de Hoy"), R("Agregar cerdo, Vender, Nuevo pedido"), R("Agregar cerdo, Vender, Guía de razas")],
  [R("Modelos de datos"), R("Seis"), R("Cinco (sin Pedido)")],
], 0.5, 1.1, 6.0, [1.7, 2.2, 2.1], "Tabla iteración 4", 0.46);
lista(s, [
  "Es el ajuste final antes de la entrega, del 20 de noviembre.",
  "Las fotos son de Wikimedia Commons (CC BY-SA) y los textos, un resumen de Wikipedia; cada foto muestra su autor y licencia.",
  "Los requerimientos y pruebas de pedidos quedaron marcados como retirados, no borrados.",
], 0.5, 4.05, 6.0, 1.2, 12, "Notas iteración 4");
s.addImage({ path: "p_guia.png", x: 6.85, y: 0.95, w: 1.15, h: 2.45, altText: "Guía de razas", objectName: "Pantalla guía" });
s.addImage({ path: "p_ficha.png", x: 8.2, y: 0.95, w: 1.15, h: 2.45, altText: "Ficha de un cerdo con foto de la raza", objectName: "Pantalla ficha" });
s.addText("Guía de razas y ficha con foto real de la raza", { ...BODY, x: 6.85, y: 3.5, w: 2.5, h: 0.5, fontSize: 11, color: C.accent5, align: "center", valign: "top", objectName: "Pie pantallas" });
s.addNotes("La iteración cuatro es el ajuste final del 20 de noviembre. Se quitó la sección de pedidos: la pestaña, el atajo, la tarjeta y los modelos. Se agregaron fotos reales por raza en lugar de las ilustraciones y una guía de razas con datos de Wikipedia y el crédito de cada foto. Los requerimientos y pruebas de pedidos no se borraron: quedaron marcados como retirados para conservar la trazabilidad.");

// ---------- 13. Resultados obtenidos ----------
s = nueva("CONTENIDO", "Fase 4");
s.addText("Fase 4 · Resultados obtenidos", { placeholder: "title" });
const res = [
  ["19 de 26", "requerimientos funcionales implementados", "RF"],
  ["12 + 4", "casos de prueba de componente e integración aprobados", "pruebas"],
  ["14 · 5,403", "archivos Swift y líneas de código", "codigo"],
  ["4", "iteraciones del diseño, guiadas por el cliente", "iter"],
  ["5.0 de 5", "índice de satisfacción de la titular", "sat"],
  ["4", "certificados de LinkedIn Learning, uno por fase", "cert"],
];
res.forEach((r, i) => stat(s, 0.5 + (i % 3) * 3.1, 1.15 + Math.floor(i / 3) * 1.75, 2.9, 1.55, r[0], r[1], "resultado " + r[2], 30));
s.addText("Avance del proyecto: la fase 3 tiene concluidas sus etapas de análisis, diseño, construcción y pruebas, y la integración va al 94 %. Pendientes: probar la foto propia en un iPhone real y los 4 requerimientos que quedaron fuera de esta versión.", { ...BODY, x: 0.5, y: 4.7, w: 9.0, h: 0.6, fontSize: 12, color: C.text1, valign: "top", objectName: "Avance del proyecto" });
s.addNotes("Estos son los resultados obtenidos. Se implementaron diecinueve de los veintiséis requerimientos funcionales; hay doce casos de prueba de componente y cuatro de integración aprobados; el código tiene catorce archivos y más de cinco mil líneas; el diseño pasó por cuatro iteraciones guiadas por el cliente; el índice de satisfacción de la titular es 5.0 de 5; y se completaron cuatro cursos de LinkedIn Learning, uno por fase. Quedan pendientes probar la foto propia en un iPhone real y cuatro requerimientos para una siguiente versión.");

// ---------- 14. Video ----------
s = nueva("CONTENIDO", "Fase 4");
s.addText("Fase 4 · Demostración de la app en video", { placeholder: "title" });
etiqueta(s, "Lo que muestra el video", 0.5, 1.15, 5.8, "Título video");
lista(s, [
  "Tareas del día: marcar la alimentación y registrar los kilos servidos.",
  "Guía de razas: foto, datos y crédito de cada raza.",
  "Animales: búsqueda por raza, filtros y ficha de un cerdo.",
  "Dinero: venta en tres pasos (cerdo, kilos y precio) y su historial.",
  "Compras: comparación de precios entre proveedores.",
], 0.5, 1.5, 5.8, 2.9, 14, "Lista video");
s.addText("Grabación del simulador de iPhone 17 Pro con iOS 26.4. Dura unos 2 minutos.", { ...BODY, x: 0.5, y: 4.5, w: 5.8, h: 0.6, fontSize: 12, color: C.accent5, valign: "top", objectName: "Nota video" });
s.addMedia({ type: "video", path: VIDEO, cover: "data:image/png;base64," + fs.readFileSync("poster.png").toString("base64"), x: 7.2, y: 1.15, w: 1.8, h: 3.9, objectName: "Video demostración" });
s.addNotes("Este es el video de demostración de la app: se marca la alimentación y se registran los kilos, se recorre la guía de razas, se busca por raza y se abre la ficha de un cerdo, se registra una venta en tres pasos con su historial y se comparan los precios de los proveedores. Es una grabación del simulador de iPhone.");

// ---------- 14. Entregables cumplidos ----------
s = nueva("CONTENIDO", "Fase 4");
s.addText("Fase 4 · Entregables cumplidos de las cuatro fases", { placeholder: "title" });
const ent = [
  ["Fase 1", ["Portafolio de 13 evidencias", "Reflexión de cuatro preguntas", "App Lista de tareas", "Certificado Swift 5 Essential Training"]],
  ["Fase 2", ["Reporte de selección de la empresa", "Carta de manifestación de interés", "Minuta de acuerdo", "Solicitud a la profesora", "Certificado Delegations and Data Sources"]],
  ["Fase 3", ["Cronograma y requerimientos", "Diseño y código en GitHub", "Pruebas y registros CP-13 y CP-15", "App funcional", "Certificado Protocol-Oriented Programming"]],
  ["Fase 4", ["Presentación ejecutiva", "Video de demostración", "Encuesta de satisfacción", "Hallazgos y lecciones aprendidas", "Certificado Complete Guide to SwiftUI"]],
];
ent.forEach((e, i) => {
  const x = 0.5 + i * 2.3;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.15, w: 2.1, h: 3.9, rectRadius: 0.12, fill: { color: i % 2 ? C.accent3 : C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Tarjeta entregables " + e[0] });
  s.addText(e[0], { ...BODY, x: x + 0.15, y: 1.25, w: 1.8, h: 0.4, fontSize: 18, bold: true, color: C.accent2, fontFace: "Cambria", objectName: "Título " + e[0] });
  s.addText(e[1].map((t, k) => ({ text: t, options: { bullet: true, breakLine: k < e[1].length - 1 } })),
    { ...BODY, x: x + 0.15, y: 1.75, w: 1.85, h: 3.2, fontSize: 12, color: C.text1, valign: "top", paraSpaceAfter: 6, objectName: "Lista " + e[0] });
});
s.addNotes("Estos son los entregables cumplidos en cada fase. Fase 1: el portafolio de trece evidencias, la reflexión, la app de lista de tareas y el certificado de Swift 5 Essential Training. Fase 2: el reporte de selección de la empresa, la carta de interés, la minuta, la solicitud a la profesora y el certificado de Delegations and Data Sources. Fase 3: el cronograma, los requerimientos, el diseño, el código, las pruebas, la app funcional y el certificado de Protocol-Oriented Programming. Fase 4: esta presentación, el video, la encuesta de satisfacción, las lecciones aprendidas y el certificado del curso Complete Guide to SwiftUI.");

// ---------- 15. Satisfacción ----------
s = nueva("CONTENIDO", "Fase 4");
s.addText("Fase 4 · Satisfacción del cliente", { placeholder: "title" });
const labels = ENC.preguntas.map((p) => p.texto), vals = ENC.preguntas.map((p) => p.calificacion);
const prom = vals.reduce((a, b) => a + b, 0) / vals.length;
s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.5, y: 1.15, w: 1.7, h: 1.4, rectRadius: 0.12, fill: { color: C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Tarjeta promedio" });
s.addText(prom.toFixed(1), { ...BODY, x: 0.5, y: 1.2, w: 1.7, h: 0.8, fontSize: 40, bold: true, color: C.text2, fontFace: "Cambria", align: "center", valign: "middle", objectName: "Promedio" });
s.addText("de " + ENC.escalaMax + " en promedio", { ...BODY, x: 0.5, y: 2.0, w: 1.7, h: 0.4, fontSize: 12, color: C.text1, align: "center", valign: "middle", objectName: "Etiqueta promedio" });
s.addText(ENC.nota, { ...BODY, x: 0.5, y: 2.7, w: 1.7, h: 1.9, fontSize: 11, color: C.accent5, valign: "top", objectName: "Nota encuesta" });
s.addChart(pres.charts.BAR, [{ name: "Calificación", labels, values: vals }], {
  x: 2.4, y: 1.1, w: 3.9, h: 4.0, barDir: "bar", chartColors: ["2F5D46"], showValue: true, dataLabelPosition: "outEnd", dataLabelFontSize: 11, dataLabelColor: "1D1B16",
  catAxisLabelFontSize: 11, catAxisLabelColor: "1D1B16", catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt", dataLabelFontFace: "+mn-lt",
  valAxisMinVal: 0, valAxisMaxVal: ENC.escalaMax + 0.6, valAxisHidden: true, valGridLine: { style: "none" }, catGridLine: { style: "none" }, showLegend: false,
});
etiqueta(s, "Reacción en cada entrega", 6.6, 1.15, 2.9, "Título reacciones");
const reac = [["Iteración 1", "“La app no es muy buena.”", false], ["Iteración 2", "Rechazó el diseño: sin imágenes y poco intuitivo.", false], ["Versión final", "La titular la aprobó.", true]];
reac.forEach((r, i) => {
  const y = 1.55 + i * 1.2;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 6.6, y, w: 2.9, h: 1.08, rectRadius: 0.1, fill: { color: r[2] ? C.accent3 : C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Tarjeta " + r[0] });
  s.addText([{ text: r[0], options: { bold: true, color: r[2] ? C.accent1 : C.accent2, breakLine: true } }, { text: r[1], options: { color: C.text1 } }],
    { ...BODY, x: 6.75, y: y + 0.05, w: 2.6, h: 0.98, fontSize: 12, valign: "middle", paraSpaceAfter: 2, objectName: "Texto " + r[0] });
});
s.addNotes("La satisfacción de la titular, Virginia del Carmen Moreno Gallegos, se midió con ocho afirmaciones sobre la app, calificadas de uno a cinco. Calificó con cinco todas, así que el índice de satisfacción es 5.0. A la derecha está su reacción en cada entrega: la primera versión no le gustó, la segunda la rechazó por no tener imágenes y ser poco intuitiva, y la versión final la aprobó.");

// ---------- Evidencias Fase 4 ----------
s = nueva("CONTENIDO", "Fase 4");
s.addText("Fase 4 · Evidencias", { placeholder: "title" });
evid(s, [
  { n: "enc", t: "Cuestionario de la encuesta de satisfacción (8 afirmaciones, de 1 a 5)" },
  { n: "hall3", t: "Resultados y reacciones del cliente en el documento de lecciones" },
  { n: "hall1", t: "Documento de hallazgos y lecciones aprendidas, primera página" },
]);
s.addNotes("Evidencias de la fase 4: el cuestionario de la encuesta de satisfacción, con sus ocho afirmaciones calificadas de uno a cinco; la página del documento de lecciones con los resultados y la reacción del cliente en cada entrega; y la primera página de ese documento de hallazgos y lecciones aprendidas.");

// ---------- 16. Hallazgos y lecciones ----------
s = nueva("CONTENIDO", "Fase 4");
s.addText("Fase 4 · Hallazgos y lecciones aprendidas", { placeholder: "title" });
tabla(s, [
  [H("Pregunta"), H("Respuesta")],
  [R("¿Plazos y presupuesto?", { bold: true }), R("Sí: en tiempo, con entrega el 30 de noviembre, y sin presupuesto ni gasto.")],
  [R("¿Cumplió los requisitos?", { bold: true }), R("En lo esencial: 19 de 26 implementados, 3 retirados y 4 pendientes. La titular aprobó la versión final.")],
  [R("¿Fluido y colaborativo?", { bold: true }), R("Colaborativo, pero no fluido al inicio: dos diseños rechazados obligaron a reconstruir.")],
  [R("¿Qué se pudo evitar?", { bold: true }), R("Los dos diseños rechazados (prototipo con imágenes antes de programar), el módulo de pedidos (confirmar el alcance) y no probar la foto propia en un iPhone real.")],
  [R("Comunicación", { bold: true }), R("Reunión semanal con la app en el teléfono del cliente, prototipo antes de programar, comentarios por escrito y un solo canal.")],
  [R("Documentación", { bold: true }), R("Cronograma al día, trazabilidad entre requerimientos y pruebas, comentarios del cliente con fecha y capturas de cada iteración.")],
], 0.5, 1.1, 9.0, [2.3, 6.7], "Tabla lecciones", 0.55);
s.addNotes("Estas son las respuestas del ejercicio de hallazgos y lecciones aprendidas. El proceso se entregó en tiempo y sin gasto. La app cumplió lo esencial y la titular aprobó la versión final. Fue colaborativo pero no fluido al inicio, por los dos diseños rechazados. Se pudo evitar rehacer el diseño mostrando antes un prototipo con imágenes, y construir el módulo de pedidos sin confirmar el alcance. Para mejorar la comunicación propongo reuniones semanales con la app en el teléfono del cliente; para la documentación, mantener el cronograma al día y registrar los comentarios del cliente con su fecha.");

// ---------- Certificado ----------
s = nueva("CONTENIDO", "Fase 4");
s.addText("Fase 4 · Certificado de LinkedIn Learning", { placeholder: "title" });
s.addImage({ path: "cert.png", x: 0.5, y: 1.1, w: 5.2, h: 4.02, altText: "Certificado de finalización del curso Complete Guide to SwiftUI", objectName: "Certificado Complete Guide to SwiftUI" });
etiqueta(s, "Complete Guide to SwiftUI", 6.0, 1.2, 3.5, "Título certificado");
lista(s, [
  "Curso completado por José Guadalupe Rico Moreno",
  "Fecha: 23 de noviembre de 2026",
  "Duración: 10 horas 57 minutos",
  "Aptitudes: iOS y SwiftUI",
  "Emitido por LinkedIn Learning",
], 6.0, 1.6, 3.5, 2.6, 13, "Datos certificado");
s.addNotes("Este es el certificado de la fase 4: el curso Complete Guide to SwiftUI de LinkedIn Learning, completado el 23 de noviembre de 2026, con una duración de diez horas con cincuenta y siete minutos, sobre las aptitudes iOS y SwiftUI.");

// ---------- Conclusión ----------
s = nueva("CIERRE", "Cierre");
s.addText("Conclusión y qué sigue", { placeholder: "title" });
const cols = [
  ["Lo aprendido", "Quien decide si una app es buena es quien la usa. La app final no se parece al primer diseño, y eso es un resultado, no un fracaso."],
  ["Lo técnico", "App completa de iOS con SwiftUI y SwiftData, sin internet, probada en el simulador y pensada para usarse de pie y con guantes."],
  ["Lo que sigue", "Probar la foto propia en un iPhone real y los requerimientos pendientes: historial de pesos, ración y dieta, costo real por kilo y calendario de sanidad."],
];
cols.forEach((t, i) => {
  const x = 0.5 + i * 3.1;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.3, w: 2.9, h: 3.3, rectRadius: 0.15, fill: { color: C.background2 }, line: { color: C.background2 }, objectName: "Tarjeta cierre " + (i + 1) });
  s.addText(t[0], { ...BODY, x: x + 0.2, y: 1.45, w: 2.5, h: 0.45, fontSize: 19, bold: true, color: C.text2, fontFace: "Cambria", valign: "middle", objectName: "Título cierre " + (i + 1) });
  s.addText(t[1], { ...BODY, x: x + 0.2, y: 2.0, w: 2.5, h: 2.5, fontSize: 14, color: C.text1, valign: "top", objectName: "Texto cierre " + (i + 1) });
});
s.addText("Fotos: Steven Walling, Fcobmz y Beatrice Kaseke · Wikimedia Commons · CC BY-SA", { ...BODY, x: 0.5, y: 4.85, w: 8.0, h: 0.3, fontSize: 10, color: C.background2, objectName: "Créditos fotos" });
s.addNotes("Para cerrar: el aprendizaje principal es que quien decide si una app es buena es quien la usa; la app final no se parece al primer diseño y eso es un resultado, no un fracaso. En lo técnico construí una app completa de iOS con SwiftUI y SwiftData que funciona sin internet. Lo que sigue es probar la subida de la foto propia en un iPhone real y los requerimientos pendientes. Gracias, quedo atento a sus preguntas.");

(async () => {
  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("OK", OUT);
})();
