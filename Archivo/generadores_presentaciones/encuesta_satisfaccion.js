const fs = require("fs");
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType, AlignmentType, BorderStyle, ShadingType, Footer, PageBorderDisplay, PageBorderOffsetFrom, PageBorderZOrder } = require("docx");
const OUT = process.argv[2];
const VERDE = "2F5D46", F = "Arial";
const t = (text, o = {}) => new TextRun({ text, font: F, size: 22, ...o });
const p = (runs, o = {}) => new Paragraph({ alignment: AlignmentType.JUSTIFIED, spacing: { after: 120 }, children: Array.isArray(runs) ? runs : [t(runs)], ...o });
const borde = { style: BorderStyle.SINGLE, size: 4, color: "C3CDC1" };
const bordes = { top: borde, bottom: borde, left: borde, right: borde };
const celda = (txt, w, o = {}) => new TableCell({
  width: { size: w, type: WidthType.DXA }, borders: bordes,
  shading: o.fill ? { type: ShadingType.CLEAR, fill: o.fill, color: "auto" } : undefined,
  margins: { top: 70, bottom: 70, left: 100, right: 100 },
  children: [new Paragraph({ alignment: o.center ? AlignmentType.CENTER : AlignmentType.LEFT, children: [t(txt, { size: o.size || 21, bold: o.bold, color: o.color })] })],
});
const W = [520, 5240, 3300 / 5, 3300 / 5, 3300 / 5, 3300 / 5, 3300 / 5].map(Math.round);
const preguntas = [
  "Registrar las tareas del día (alimentación y limpieza) en la app es fácil.",
  "Reconocer y encontrar a cada cerdo (fotos, búsqueda y filtros) es fácil.",
  "Vender un cerdo en tres pasos (cerdo, kilos y precio) es claro.",
  "Comparar los precios de los insumos entre proveedores me es útil.",
  "La guía de razas, con fotos e información, me es útil.",
  "Los botones y los textos se ven y se tocan bien, de pie y con guantes en el corral.",
  "En general, estoy satisfecha con la aplicación Finanzas Porcinas.",
  "Recomendaría la aplicación a otro criador.",
];
const filas = [new TableRow({ tableHeader: true, children: [
  celda("#", W[0], { fill: VERDE, color: "FFFFFF", bold: true, center: true }),
  celda("Afirmación", W[1], { fill: VERDE, color: "FFFFFF", bold: true }),
  ...["1", "2", "3", "4", "5"].map((n, i) => celda(n, W[2 + i], { fill: VERDE, color: "FFFFFF", bold: true, center: true })),
] })];
preguntas.forEach((q, i) => filas.push(new TableRow({ children: [
  celda(String(i + 1), W[0], { center: true }), celda(q, W[1]),
  ...[0, 1, 2, 3, 4].map((k) => celda("☐", W[2 + k], { center: true, size: 26 })),
] })));
const doc = new Document({
  styles: { default: { document: { run: { font: F, size: 22 } } } },
  sections: [{
    properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1300, right: 1300, bottom: 1300, left: 1300 },
      borders: { pageBorders: { display: PageBorderDisplay.ALL_PAGES, offsetFrom: PageBorderOffsetFrom.PAGE, zOrder: PageBorderZOrder.FRONT },
        pageBorderTop: { style: BorderStyle.SINGLE, size: 12, color: VERDE, space: 24 }, pageBorderBottom: { style: BorderStyle.SINGLE, size: 12, color: VERDE, space: 24 },
        pageBorderLeft: { style: BorderStyle.SINGLE, size: 12, color: VERDE, space: 24 }, pageBorderRight: { style: BorderStyle.SINGLE, size: 12, color: VERDE, space: 24 } } } },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "José Guadalupe Rico Moreno · AL03063503 · Universidad Tecmilenio · Desarrollo de proyecto de aplicaciones móviles", font: F, size: 16, color: "5E574B" })] })] }) },
    children: [
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "Encuesta de satisfacción del cliente", font: "Avenir Next", size: 40, bold: true, color: VERDE })] }),
      new Paragraph({ spacing: { after: 160 }, children: [t("Aplicación Finanzas Porcinas · Criadero Fam Rico Moreno", { size: 24, color: "5E574B" })] }),
      p([t("Nombre de quien responde: ", { bold: true }), t("____________________________________")]),
      p([t("Cargo: ", { bold: true }), t("Titular del criadero        "), t("Fecha: ", { bold: true }), t("____ / ____ / 2026")]),
      p("Marque con una X qué tan de acuerdo está con cada afirmación: 1 = nada de acuerdo, 5 = totalmente de acuerdo."),
      new Table({ width: { size: 9360, type: WidthType.DXA }, columnWidths: W, rows: filas }),
      new Paragraph({ spacing: { before: 200, after: 80 }, children: [t("Comentarios", { bold: true })] }),
      p("¿Qué fue lo que más le gustó de la aplicación?"),
      p("______________________________________________________________________________"),
      p("¿Qué cambiaría o agregaría?"),
      p("______________________________________________________________________________"),
      p([t("Índice de satisfacción: ", { bold: true }), t("se calcula como el promedio de las calificaciones de las 8 afirmaciones, de 1 a 5.")]),
    ],
  }],
});
Packer.toBuffer(doc).then((b) => { fs.writeFileSync(OUT, b); console.log("OK"); });
