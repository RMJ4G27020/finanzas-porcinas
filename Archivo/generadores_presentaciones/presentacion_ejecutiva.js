const fs = require("fs");
const pptxgen = require("pptxgenjs");
const SK = "/Users/joserico/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/805aae63-7cf0-4743-8bcd-1c13064bad77/0b4967d2-8cd3-4801-95dd-dd8ed4a09324/skills/pptx";
const { applyTheme } = require(SK + "/scripts/apply_theme.js");

const OUT = process.argv[2];
const VIDEO = process.argv[3];
const ENCUESTA = process.argv[4]; // JSON opcional con los resultados reales
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
pres.title = "Presentación ejecutiva · Finanzas Porcinas";
pres.author = "José Guadalupe Rico Moreno";
const C = pres.SchemeColor;

pres.defineSlideMaster({
  title: "EJECUTIVA",
  background: { color: "FFFFFF" },
  slideNumber: { x: 9.2, y: 5.2, w: 0.4, h: 0.3, fontSize: 11, color: C.accent5, align: "right" },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.5, y: 0.25, w: 9.0, h: 0.7, fontSize: 28, bold: true, color: C.text2, valign: "middle", align: "left", margin: 0 }, text: "" } },
  ],
});
const BODY = { fontFace: "Calibri", isTextBox: true, margin: 0 };

// ---------- Diapositiva 1 ----------
pres.addSection({ title: "Presentación ejecutiva" });
let s = pres.addSlide({ masterName: "EJECUTIVA", sectionTitle: "Presentación ejecutiva" });
s.addText("Finanzas Porcinas: objetivo, plan y resultados", { placeholder: "title" });

// Columna izquierda
s.addText("Objetivo general", { ...BODY, x: 0.5, y: 1.1, w: 3.5, h: 0.3, fontSize: 15, bold: true, color: C.text2, fontFace: "Cambria", objectName: "Título objetivo" });
s.addText("Construir una app de iOS para el Criadero Fam Rico Moreno que registre los cerdos, las tareas del día y las compras y ventas, en lugar de llevarlo de memoria y en libretas.", { ...BODY, x: 0.5, y: 1.42, w: 3.5, h: 1.25, fontSize: 13, color: C.text1, valign: "top", objectName: "Texto objetivo" });
s.addText("Resultados obtenidos", { ...BODY, x: 0.5, y: 2.8, w: 3.5, h: 0.3, fontSize: 15, bold: true, color: C.text2, fontFace: "Cambria", objectName: "Título resultados" });
s.addText([
  { text: "App funcional en 3 pestañas: Hoy, Animales y Dinero", options: { bullet: true, breakLine: true } },
  { text: "19 de 26 requerimientos funcionales implementados; 3 retirados (pedidos) y 4 pendientes", options: { bullet: true, breakLine: true } },
  { text: "Casos de prueba de componente e integración aprobados en simulador", options: { bullet: true, breakLine: true } },
  { text: "Versión final aprobada por la titular, Virginia del Carmen Moreno", options: { bullet: true } },
], { ...BODY, x: 0.5, y: 3.12, w: 3.6, h: 2.1, fontSize: 12, color: C.text1, valign: "top", paraSpaceAfter: 4, objectName: "Resultados" });

// Tabla: plan de acción y entregables
s.addText("Plan de acción y entregable de cada etapa", { ...BODY, x: 4.4, y: 1.1, w: 5.1, h: 0.3, fontSize: 15, bold: true, color: C.text2, fontFace: "Cambria", objectName: "Título plan" });
const H = (t) => ({ text: t, options: { bold: true, color: C.background1, fill: { color: C.accent1 }, fontSize: 11, fontFace: "Calibri", valign: "middle" } });
const R = (t, opt = {}) => ({ text: t, options: { fontSize: 11, fontFace: "Calibri", color: C.text1, valign: "middle", ...opt } });
const OK = (t) => R(t, { bold: true, color: C.accent1 });
const PR = (t) => R(t, { bold: true, color: C.accent2 });
const rows = [
  [H("Etapa"), H("Fechas"), H("Entregable"), H("Estado")],
  [R("Análisis"), R("26 oct–1 nov"), R("Listado de requerimientos"), OK("Cumplido")],
  [R("Diseño"), R("2–8 nov"), R("Documento de diseño de solución"), OK("Cumplido")],
  [R("Construcción"), R("9–18 nov"), R("Archivos de programación y de diseño"), OK("Cumplido")],
  [R("Pruebas"), R("19–24 nov"), R("Prototipos y resultados de prueba"), OK("Cumplido")],
  [R("Integración"), R("25–29 nov"), R("App completa y funcional"), PR("En curso · 94 %")],
  [R("Entrega"), R("30 nov"), R("Documento integrado de la Fase III"), PR("30 nov")],
];
s.addTable(rows, {
  x: 4.4, y: 1.45, w: 5.1, colW: [1.0, 0.95, 2.15, 1.0], rowH: 0.45,
  border: { type: "solid", pt: 0.75, color: C.accent6 }, margin: [0.04, 0.08, 0.04, 0.08],
  fill: { color: C.background1 }, objectName: "Tabla plan de acción",
});
s.addNotes("Objetivo general: construir Finanzas Porcinas, una app de iOS para el Criadero Fam Rico Moreno que registre los cerdos, las tareas del día y las compras y ventas, que antes se llevaban de memoria y en libretas. El plan se organizó en cinco etapas más la entrega, cada una con su entregable: requerimientos, diseño, programación, pruebas y la app completa; el documento integrado se entrega el 30 de noviembre. Resultados: la app funciona en tres pestañas, se implementaron 19 de los 26 requerimientos funcionales, tres se retiraron (la sección de pedidos) y cuatro quedaron pendientes. La integración va al 94 por ciento. Las pruebas en simulador salieron aprobadas y la titular, mi mamá, aprobó la versión final.");

// ---------- Diapositiva 2 ----------
s = pres.addSlide({ masterName: "EJECUTIVA", sectionTitle: "Presentación ejecutiva" });
s.addText("Satisfacción del cliente y demostración", { placeholder: "title" });

s.addText(ENCUESTA && fs.existsSync(ENCUESTA) ? "Índice de satisfacción del cliente" : "Satisfacción del cliente", { ...BODY, x: 0.5, y: 1.1, w: 5.6, h: 0.3, fontSize: 15, bold: true, color: C.text2, fontFace: "Cambria", objectName: "Título encuesta" });
let enc = null;
if (ENCUESTA && fs.existsSync(ENCUESTA)) enc = JSON.parse(fs.readFileSync(ENCUESTA, "utf-8"));
if (enc) {
  const labels = enc.preguntas.map((p) => p.texto);
  const vals = enc.preguntas.map((p) => p.calificacion);
  const prom = vals.reduce((a, b) => a + b, 0) / vals.length;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.5, y: 1.5, w: 1.7, h: 1.4, rectRadius: 0.12, fill: { color: C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Tarjeta promedio" });
  s.addText(prom.toFixed(1), { ...BODY, x: 0.5, y: 1.55, w: 1.7, h: 0.8, fontSize: 40, bold: true, color: C.text2, fontFace: "Cambria", align: "center", valign: "middle", objectName: "Promedio" });
  s.addText("de " + enc.escalaMax + " en promedio", { ...BODY, x: 0.5, y: 2.35, w: 1.7, h: 0.4, fontSize: 12, color: C.text1, align: "center", valign: "middle", objectName: "Etiqueta promedio" });
  s.addChart(pres.charts.BAR, [{ name: "Calificación", labels, values: vals }], {
    x: 2.4, y: 1.45, w: 3.8, h: 3.6, barDir: "bar", chartColors: ["2F5D46"],
    showValue: true, dataLabelPosition: "outEnd", dataLabelFontSize: 11, dataLabelColor: "1D1B16",
    catAxisLabelFontSize: 11, catAxisLabelColor: "1D1B16", catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt",
    valAxisMinVal: 0, valAxisMaxVal: enc.escalaMax + 0.6, valAxisHidden: true, valGridLine: { style: "none" }, catGridLine: { style: "none" },
    showLegend: false, dataLabelFontFace: "+mn-lt",
  });
  s.addText(enc.nota || "", { ...BODY, x: 0.5, y: 3.05, w: 1.7, h: 1.9, fontSize: 11, color: C.accent5, valign: "top", objectName: "Nota encuesta" });
} else {
  const reacciones = [
    ["Iteración 1 · 25 oct", "“La app no es muy buena.”", "No satisfecha: se preparó una segunda iteración."],
    ["Iteración 2 · 26 oct", "“No me termina de gustar nada el diseño: no tiene imágenes de los animales y es cero intuitivo.”", "No satisfecha: se reconstruyó el diseño desde cero."],
    ["Versión final", "La titular aprobó la versión final de la aplicación.", "Satisfecha: aprobada por la titular del criadero."],
  ];
  reacciones.forEach((r, i) => {
    const y = 1.5 + i * 1.18;
    const ok = i === 2;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.5, y, w: 5.6, h: 1.05, rectRadius: 0.1, fill: { color: ok ? C.accent3 : C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Tarjeta reacción " + (i + 1) });
    s.addText(r[0], { ...BODY, x: 0.7, y: y + 0.08, w: 1.6, h: 0.9, fontSize: 13, bold: true, color: ok ? C.accent1 : C.accent2, valign: "middle", objectName: "Entrega " + (i + 1) });
    s.addText([
      { text: r[1], options: { breakLine: true, color: C.text1 } },
      { text: r[2], options: { bold: true, color: ok ? C.accent1 : C.accent5 } },
    ], { ...BODY, x: 2.35, y: y + 0.06, w: 3.6, h: 0.93, fontSize: 12, valign: "middle", paraSpaceAfter: 3, objectName: "Reacción " + (i + 1) });
  });
}

// Video
s.addText("Demostración de la app", { ...BODY, x: 6.6, y: 1.1, w: 2.9, h: 0.3, fontSize: 15, bold: true, color: C.text2, fontFace: "Cambria", objectName: "Título video" });
s.addMedia({ type: "video", path: VIDEO, cover: "data:image/png;base64," + fs.readFileSync("poster.png").toString("base64"), x: 7.25, y: 1.5, w: 1.59, h: 3.45, objectName: "Video demostración" });
s.addText("Grabación del simulador: tareas, guía de razas, animales y venta", { ...BODY, x: 6.6, y: 5.0, w: 2.6, h: 0.45, fontSize: 10, color: C.accent5, align: "left", valign: "top", objectName: "Pie video" });
s.addNotes("En la parte izquierda está el índice de satisfacción de la titular, Virginia del Carmen Moreno Gallegos: calificó con 5, de un máximo de 5, las ocho afirmaciones sobre la app, para un promedio de 5.0. Antes había rechazado las dos primeras versiones del diseño y aprobó la versión final. A la derecha, el video de demostración: muestra cómo se marcan las tareas del día, la guía de razas, la búsqueda y ficha de un cerdo, el registro de una venta con su historial y la comparación de precios entre proveedores. Es una grabación del simulador de iPhone.");

(async () => {
  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("OK", OUT, enc ? "con encuesta" : "sin encuesta");
})();
