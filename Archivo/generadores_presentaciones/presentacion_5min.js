const pptxgen = require("pptxgenjs");
const SK = "/Users/joserico/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/805aae63-7cf0-4743-8bcd-1c13064bad77/0b4967d2-8cd3-4801-95dd-dd8ed4a09324/skills/pptx";
const { applyTheme } = require(SK + "/scripts/apply_theme.js");

const OUT = process.argv[2];
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
pres.title = "Finanzas Porcinas";
pres.author = "José Guadalupe Rico Moreno";
const C = pres.SchemeColor;

// ---------- Layouts ----------
pres.defineSlideMaster({
  title: "PORTADA",
  background: { color: "2F5D46" },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 1.2, w: 5.0, h: 1.4, fontSize: 44, bold: true, color: C.background1, valign: "top", align: "left", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "CONTENIDO",
  background: { color: "FFFFFF" },
  slideNumber: { x: 9.1, y: 5.15, w: 0.5, h: 0.3, fontSize: 11, color: C.accent5, align: "right" },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.4, w: 5.9, h: 0.8, fontSize: 32, bold: true, color: C.text2, valign: "middle", align: "left", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "ANCHO",
  background: { color: "FFFFFF" },
  slideNumber: { x: 9.1, y: 5.15, w: 0.5, h: 0.3, fontSize: 11, color: C.accent5, align: "right" },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.4, w: 8.8, h: 0.8, fontSize: 32, bold: true, color: C.text2, valign: "middle", align: "left", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "CIERRE",
  background: { color: "2F5D46" },
  slideNumber: { x: 9.1, y: 5.15, w: 0.5, h: 0.3, fontSize: 11, color: C.background2, align: "right" },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.4, w: 8.8, h: 0.8, fontSize: 32, bold: true, color: C.background1, valign: "middle", align: "left", margin: 0 }, text: "" } },
  ],
});

const BODY = { fontFace: "Calibri", isTextBox: true, margin: 0 };

// Lista numerada con círculo: devuelve los elementos para una fila
function filas(slide, items, x, y, w, gap, color) {
  items.forEach((t, i) => {
    const yy = y + i * gap;
    slide.addShape(pres.shapes.OVAL, { x, y: yy, w: 0.42, h: 0.42, fill: { color: C.accent1 }, line: { color: C.accent1 }, objectName: "Círculo " + (i + 1) });
    slide.addText(String(i + 1), { ...BODY, x, y: yy, w: 0.42, h: 0.42, fontSize: 16, bold: true, color: C.background1, align: "center", valign: "middle", objectName: "Número " + (i + 1) });
    slide.addText(t, { ...BODY, x: x + 0.62, y: yy - 0.12, w: w - 0.62, h: 0.66, fontSize: 16, color: color || C.text1, valign: "middle", objectName: "Punto " + (i + 1) });
  });
}

// ---------- 1. Portada ----------
pres.addSection({ title: "Presentación" });
let s = pres.addSlide({ masterName: "PORTADA", sectionTitle: "Presentación" });
s.addText("Finanzas Porcinas", { placeholder: "title" });
s.addText("La app del criadero: cerdos, tareas y dinero en un solo lugar", { ...BODY, x: 0.6, y: 2.75, w: 4.9, h: 0.8, fontSize: 20, color: C.background2, valign: "top", objectName: "Subtítulo" });
s.addText([
  { text: "José Guadalupe Rico Moreno · AL03063503", options: { breakLine: true, bold: true } },
  { text: "Desarrollo de proyecto de aplicaciones móviles", options: { breakLine: true } },
  { text: "Universidad Tecmilenio · Profesora Eva María Francisco Santiago", options: {} },
], { ...BODY, x: 0.6, y: 3.9, w: 5.0, h: 1.0, fontSize: 14, color: C.background1, valign: "top", paraSpaceAfter: 4, objectName: "Autor" });
s.addImage({ path: "portada.png", x: 5.95, y: 0.9, w: 3.5, h: 3.5, altText: "Foto real de un cerdo miniatura (minipig)", objectName: "Foto minipig" });
s.addText("Foto: Fcobmz · CC BY-SA 4.0 · Wikimedia Commons", { ...BODY, x: 5.95, y: 4.5, w: 3.5, h: 0.3, fontSize: 10, color: C.background2, align: "left", objectName: "Crédito foto" });
s.addNotes("Buenas tardes. Soy José Guadalupe Rico Moreno y les presento Finanzas Porcinas, la app que hice para el Criadero Fam Rico Moreno, el emprendimiento de crianza de puercos de mi familia en Aldama, Tamaulipas. Es el proyecto integrador de la materia Desarrollo de proyecto de aplicaciones móviles. En cinco minutos les muestro para qué sirve, cómo se usa y cómo fue cambiando con lo que pidió el cliente.");

// ---------- 2. El criadero y la necesidad ----------
s = pres.addSlide({ masterName: "ANCHO", sectionTitle: "Presentación" });
s.addText("El criadero y lo que necesita", { placeholder: "title" });
const stats = [["17", "cerdos de crianza"], ["12", "cerdos al año para venta"], ["$40 u $80", "por kilo, según la raza"]];
stats.forEach((t, i) => {
  const x = 0.6 + i * 3.0;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.5, w: 2.8, h: 1.7, rectRadius: 0.15, fill: { color: C.background2 }, line: { color: C.accent6, width: 1 }, objectName: "Tarjeta dato " + (i + 1) });
  s.addText(t[0], { ...BODY, x, y: 1.65, w: 2.8, h: 0.9, fontSize: i === 2 ? 34 : 54, bold: true, color: C.text2, fontFace: "Cambria", align: "center", valign: "middle", objectName: "Dato " + (i + 1) });
  s.addText(t[1], { ...BODY, x, y: 2.6, w: 2.8, h: 0.45, fontSize: 16, color: C.text1, align: "center", valign: "middle", objectName: "Etiqueta dato " + (i + 1) });
});
s.addText("Quién la usa", { ...BODY, x: 0.6, y: 3.55, w: 8.8, h: 0.4, fontSize: 20, bold: true, color: C.text2, fontFace: "Cambria", objectName: "Título quién la usa" });
const quien = [["Virginia del Carmen Moreno", "Titular. Lleva el dinero"], ["José", "Limpieza y alimentación"], ["Dr. Rafael de Leija Lara", "Veterinario. Se registran sus visitas"]];
quien.forEach((t, i) => {
  const x = 0.6 + i * 3.0;
  s.addText([
    { text: t[0], options: { bold: true, breakLine: true, color: C.text1 } },
    { text: t[1], options: { color: C.accent5 } },
  ], { ...BODY, x, y: 4.0, w: 2.8, h: 0.9, fontSize: 15, valign: "top", paraSpaceAfter: 3, objectName: "Persona " + (i + 1) });
});
s.addNotes("El criadero empezó en 2018 con 5 puercos. Hoy tenemos 17 de crianza y vendemos unos 12 al año. Las razas son común, minipig y cruzas, y se vende por kilo a 40 u 80 pesos según la raza. Mi mamá, Virginia, lleva el dinero; yo me encargo de la limpieza y la alimentación en vacaciones; y el doctor Rafael de Leija Lara es el veterinario. La app tiene que servirnos a los tres: saber qué toca hoy, cuáles son los cerdos y cuánto se vende y se gasta.");

// ---------- 3. Hoy ----------
pres.addSection({ title: "La app" });
s = pres.addSlide({ masterName: "CONTENIDO", sectionTitle: "La app" });
s.addText("Hoy: ¿qué toca hoy?", { placeholder: "title" });
filas(s, [
  "Tareas del día con barra de progreso: alimentación y limpieza",
  "Atajos de un toque: agregar cerdo, vender y guía de razas",
  "Mis cerdos: la foto de cada uno de los 17 de crianza",
], 0.6, 1.8, 5.4, 1.15);
s.addImage({ path: "p_hoy.png", x: 7.0, y: 0.5, w: 2.16, h: 4.6, altText: "Pantalla Hoy de la app", objectName: "Pantalla Hoy" });
s.addNotes("La primera pestaña es Hoy y responde una sola pregunta: qué toca hoy. Arriba están las tareas del día, alimentación de la mañana, limpieza y alimentación de la tarde, con una barra que muestra cuántas van hechas; se marcan con un toque. Debajo hay tres atajos grandes: agregar cerdo, vender y la guía de razas. Y más abajo, las fotos de los cerdos de crianza. Todo con botones grandes, porque se usa de pie en el corral.");

// ---------- 4. Mis cerdos ----------
s = pres.addSlide({ masterName: "CONTENIDO", sectionTitle: "La app" });
s.addText("Mis cerdos", { placeholder: "title" });
filas(s, [
  "Cada cerdo se reconoce por su foto: foto real de la raza o la suya propia",
  "Filtra por Todos, Crianza o Venta y busca por nombre o raza",
  "La ficha muestra peso, destino y raza, y permite vender o actualizar el peso",
], 0.6, 1.6, 4.3, 1.25);
s.addImage({ path: "p_animales.png", x: 5.35, y: 0.7, w: 1.95, h: 4.16, altText: "Pantalla Mis cerdos", objectName: "Pantalla Mis cerdos" });
s.addImage({ path: "p_ficha.png", x: 7.45, y: 0.7, w: 1.95, h: 4.16, altText: "Ficha de un cerdo", objectName: "Pantalla ficha" });
s.addNotes("En la pestaña Animales están los 20 cerdos del ejemplo, 17 de crianza y 3 para venta. Cada uno se reconoce por su foto: por defecto aparece una foto real de su raza y, desde la ficha, se puede subir la foto propia del cerdo. Se filtra por crianza o venta y se busca por nombre o raza. Al tocar uno se abre su ficha con el peso, el destino y la raza, con botones para venderlo o actualizar el peso.");

// ---------- 5. Guía de razas ----------
s = pres.addSlide({ masterName: "CONTENIDO", sectionTitle: "La app" });
s.addText("Guía de razas", { placeholder: "title" });
filas(s, [
  "Común, Minipig y Cruza: datos y foto real de cada una",
  "Textos de Wikipedia y fotos de Wikimedia Commons, con licencia libre",
  "Cada foto muestra su autor, licencia y enlace",
], 0.6, 1.8, 5.4, 1.15);
s.addImage({ path: "p_guia.png", x: 7.0, y: 0.5, w: 2.16, h: 4.6, altText: "Pantalla Guía de razas", objectName: "Pantalla guía" });
s.addNotes("Esta es la parte nueva: imágenes e información reales de los cerdos. La Guía de razas explica cada raza, común, minipig y cruza, con datos como la gestación de unos 114 días en el cerdo doméstico, o que un minipig tarda unos cuatro años en alcanzar su tamaño completo. Los textos son un resumen de Wikipedia y las fotos son de Wikimedia Commons con licencia libre; cada foto trae su autor y licencia. Son fotos de ejemplo de la raza, no de nuestros cerdos.");

// ---------- 6. Dinero ----------
s = pres.addSlide({ masterName: "CONTENIDO", sectionTitle: "La app" });
s.addText("Dinero: vender y comprar", { placeholder: "title" });
filas(s, [
  "Vender en 3 pasos: elegir el cerdo, los kilos y el precio ($40 u $80 por kilo)",
  "Historial de ventas guardado en el teléfono",
  "Compras de insumos: compara precios entre proveedores",
  "Visitas del veterinario: registro y agenda",
], 0.6, 1.55, 5.4, 0.95);
s.addImage({ path: "p_dinero.png", x: 7.0, y: 0.5, w: 2.16, h: 4.6, altText: "Pantalla Dinero", objectName: "Pantalla Dinero" });
s.addNotes("La pestaña Dinero es la de mi mamá. Para vender, la app pregunta tres cosas: qué cerdo, cuántos kilos y a cuánto el kilo, 40 u 80 pesos, y calcula el total; por ejemplo 96 kilos a 40 pesos son 3,840 pesos. Las ventas quedan en el historial. También están las compras de insumos, donde se comparan los precios entre proveedores, porque varían de uno a otro, y las visitas del veterinario con su agenda. Todo se guarda en el teléfono y funciona sin internet.");

// ---------- 7. Cierre ----------
pres.addSection({ title: "Cierre" });
s = pres.addSlide({ masterName: "CIERRE", sectionTitle: "Cierre" });
s.addText("Cómo evolucionó y qué sigue", { placeholder: "title" });
const cols = [
  ["Tres diseños", "El cliente rechazó los dos primeros: «la app no es muy buena» y «no tiene imágenes de los animales y es cero intuitiva». El tercero es visual y con botones grandes."],
  ["Última mejora", "Se quitó el contacto por Facebook y WhatsApp y se agregaron fotos e información reales de los cerdos."],
  ["Lo que sigue", "Probar la subida de la foto propia en un iPhone real. Hecha con SwiftUI y SwiftData, local y sin internet."],
];
cols.forEach((t, i) => {
  const x = 0.6 + i * 3.0;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.5, w: 2.8, h: 2.8, rectRadius: 0.15, fill: { color: C.background2 }, line: { color: C.background2 }, objectName: "Tarjeta cierre " + (i + 1) });
  s.addText(t[0], { ...BODY, x: x + 0.2, y: 1.65, w: 2.4, h: 0.45, fontSize: 20, bold: true, color: C.text2, fontFace: "Cambria", valign: "middle", objectName: "Título cierre " + (i + 1) });
  s.addText(t[1], { ...BODY, x: x + 0.2, y: 2.2, w: 2.4, h: 2.0, fontSize: 15, color: C.text1, valign: "top", objectName: "Texto cierre " + (i + 1) });
});
s.addText("Fotos: Steven Walling, Fcobmz y Beatrice Kaseke · Wikimedia Commons · CC BY-SA", { ...BODY, x: 0.6, y: 4.85, w: 8.0, h: 0.3, fontSize: 10, color: C.background2, objectName: "Créditos fotos" });
s.addNotes("Para cerrar: la app pasó por tres diseños guiados por el cliente. El primero no le gustó, porque dijo que la app no era muy buena. Del segundo dijo que no tenía imágenes de los animales y que era cero intuitiva, así que el tercero es visual, con fotos y botones grandes. La última mejora fue quitar el contacto por Facebook y WhatsApp y agregar fotos e información reales. Lo que sigue es probar la subida de la foto propia en un iPhone real, porque el simulador no tiene fotos. Gracias, quedo atento a sus preguntas.");

(async () => {
  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("OK", OUT);
})();
