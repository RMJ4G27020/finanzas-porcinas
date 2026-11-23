const fs = require("fs");
const {
  Document, Packer, ImageRun, Paragraph, TextRun, AlignmentType, Footer, Header, PageNumber,
  BorderStyle, Table, TableRow, TableCell, WidthType, ShadingType, PageBorderDisplay, PageBorderOffsetFrom, PageBorderZOrder, ExternalHyperlink, LineRuleType,
} = require("docx");

const OUT = process.argv[2];
const VERDE = "2F5D46";
const TITULO = "Avenir Next";
const CUERPO = "Arial";

const t = (text, o = {}) => new TextRun({ text, font: CUERPO, size: 22, ...o });

const titulo = (text, o = {}) =>
  new Paragraph({
    alignment: AlignmentType.JUSTIFIED,
    spacing: { before: o.before ?? 360, after: 120 },
    keepNext: true,
    children: [new TextRun({ text, font: TITULO, size: 40, bold: true, color: VERDE })],
  });

const pregunta = (text) =>
  new Paragraph({
    alignment: AlignmentType.JUSTIFIED,
    spacing: { after: 120, line: 276, lineRule: LineRuleType.AUTO },
    children: [t(text, { italics: true, color: "5E574B" })],
  });

const parrafo = (runs) =>
  new Paragraph({
    alignment: AlignmentType.JUSTIFIED,
    spacing: { after: 140, line: 276, lineRule: LineRuleType.AUTO },
    children: Array.isArray(runs) ? runs : [t(runs)],
  });

const viñeta = (runs) =>
  new Paragraph({
    alignment: AlignmentType.JUSTIFIED,
    numbering: { reference: "vineta", level: 0 },
    spacing: { after: 80, line: 276, lineRule: LineRuleType.AUTO },
    children: Array.isArray(runs) ? runs : [t(runs)],
  });

const dato = (etiqueta, valor, enlace) =>
  new Paragraph({
    alignment: AlignmentType.LEFT,
    spacing: { after: 60 },
    children: [
      t(etiqueta + ": ", { bold: true }),
      enlace
        ? new ExternalHyperlink({ link: enlace, children: [t(valor, { color: "0563C1", underline: {} })] })
        : t(valor),
    ],
  });

const B = (s) => t(s, { bold: true });


const brd = { style: BorderStyle.SINGLE, size: 4, color: "C3CDC1" };
const brds = { top: brd, bottom: brd, left: brd, right: brd };
const celda = (txt, w, o = {}) => new TableCell({
  width: { size: w, type: WidthType.DXA }, borders: brds,
  shading: o.fill ? { type: ShadingType.CLEAR, fill: o.fill, color: "auto" } : undefined,
  margins: { top: 70, bottom: 70, left: 100, right: 100 },
  children: [new Paragraph({ alignment: AlignmentType.LEFT, children: [t(txt, { size: 20, bold: o.bold, color: o.color })] })],
});
const tablaSatisfaccion = () => {
  const W = [1700, 4300, 3360];
  const filas = [
    ["Iteración 1 · 25 oct 2026", "“La app no es muy buena.”", "No satisfecha: se revisó cada pantalla y se preparó una segunda iteración."],
    ["Iteración 2 · 26 oct 2026", "“No me termina de gustar nada el diseño: no tiene imágenes de los animales y es cero intuitivo.”", "No satisfecha: se descartó el diseño y se reconstruyó desde cero."],
    ["Versión final · iteración 4", "Aprobó la versión final de la aplicación.", "Satisfecha: queda aprobada por la titular del criadero."],
  ];
  return new Table({ width: { size: 9360, type: WidthType.DXA }, columnWidths: W, rows: [
    new TableRow({ tableHeader: true, children: ["Entrega", "Reacción del cliente", "Resultado"].map((h, i) => celda(h, W[i], { fill: VERDE, color: "FFFFFF", bold: true })) }),
    ...filas.map((f) => new TableRow({ children: f.map((c, i) => celda(c, W[i])) })),
  ] });
};
const tablaIndice = () => {
  const W = [700, 7160, 1500];
  const items = [
    "Registrar las tareas del día (alimentación y limpieza) en la app es fácil.",
    "Reconocer y encontrar a cada cerdo (fotos, búsqueda y filtros) es fácil.",
    "Vender un cerdo en tres pasos (cerdo, kilos y precio) es claro.",
    "Comparar los precios de los insumos entre proveedores me es útil.",
    "La guía de razas, con fotos e información, me es útil.",
    "Los botones y los textos se ven y se tocan bien, de pie y con guantes en el corral.",
    "En general, estoy satisfecha con la aplicación Finanzas Porcinas.",
    "Recomendaría la aplicación a otro criador.",
  ];
  return new Table({ width: { size: 9360, type: WidthType.DXA }, columnWidths: W, rows: [
    new TableRow({ tableHeader: true, children: ["#", "Afirmación", "Calificación"].map((h, i) => celda(h, W[i], { fill: VERDE, color: "FFFFFF", bold: true })) }),
    ...items.map((q, i) => new TableRow({ children: [celda(String(i + 1), W[0]), celda(q, W[1]), celda("5 de 5", W[2], { bold: true })] })),
    new TableRow({ children: [celda("", W[0], { fill: "E3EFE6" }), celda("Índice de satisfacción (promedio de las 8 afirmaciones)", W[1], { fill: "E3EFE6", bold: true }), celda("5.0 de 5", W[2], { fill: "E3EFE6", bold: true })] }),
  ] });
};
const children = [];

// Encabezado del documento
children.push(
  new Paragraph({
    alignment: AlignmentType.JUSTIFIED,
    spacing: { before: 0, after: 80 },
    children: [new TextRun({ text: "Hallazgos y lecciones aprendidas", font: TITULO, size: 40, bold: true, color: VERDE })],
  }),
  new Paragraph({
    alignment: AlignmentType.LEFT,
    spacing: { after: 200 },
    children: [t("Proyecto integrador: Finanzas Porcinas, Criadero Fam Rico Moreno", { size: 24, color: "5E574B" })],
  }),
  dato("Alumno", "José Guadalupe Rico Moreno"),
  dato("Matrícula", "AL03063503@tecmilenio.mx"),
  dato("Materia", "Desarrollo de proyecto de aplicaciones móviles", "https://cursos.tecmilenio.mx/courses/242019"),
  dato("Profesora", "Eva María Francisco Santiago"),
  dato("Fecha", "23 de noviembre de 2026"),
);

// 1
children.push(
  titulo("1. Plazos y presupuesto"),
  pregunta("¿El proceso de desarrollo se llevó a cabo de acuerdo con los plazos y el presupuesto establecidos?"),
  parrafo([
    B("Sí. "),
    t("El cronograma organizó el trabajo en cinco fases y una entrega: análisis (26 oct–1 nov), diseño (2–8 nov), construcción (9–18 nov), pruebas (19–24 nov), integración (25–29 nov) y entrega el 30 de noviembre de 2026, fecha en la que se presenta el proyecto. El desarrollo incluso se adelantó: al 30 de octubre el análisis y el diseño estaban concluidos al 100 % y la construcción, las pruebas y la integración llevaban 83 %, 98 % y 88 %."),
  ]),
  parrafo("Los cambios que pidió el cliente (la reconstrucción del diseño tras las iteraciones 1 y 2, del 25 y 26 de octubre) y los ajustes finales del 20 de noviembre se absorbieron dentro del mismo calendario. En cuanto al presupuesto, el proyecto no tuvo presupuesto asignado ni generó gasto en dinero."),
);

// 2
children.push(
  titulo("2. Requisitos del cliente"),
  pregunta("¿La aplicación cumplió con los requisitos del cliente?"),
  parrafo([
    B("Sí, en lo esencial. "),
    t("Se levantaron 24 requerimientos funcionales, 10 no funcionales y 5 fuera de alcance; el 20 de noviembre se agregaron 2 funcionales más (RF-25 y RF-26), con lo que son 26. El resultado es el siguiente:"),
  ]),
  viñeta([B("19 implementados: "), t("tareas del día con alimento servido, animales con foto y ficha, venta en tres pasos, historial de ventas, compras con comparación de proveedores, visitas del veterinario, foto real por raza (RF-25) y Guía de razas (RF-26).")]),
  viñeta([B("3 retirados "), t("el 20 de noviembre (RF-06, RF-19 y RF-20): la sección de pedidos por Facebook y WhatsApp.")]),
  viñeta([B("4 pendientes: "), t("historial de pesos por animal (RF-21), ración y dieta por propósito (RF-22), conversión del alimento y costo real por kilogramo (RF-23) y calendario y sanidad por animal (RF-24). También quedó pendiente el escalado de toda la letra con el tamaño de texto del sistema (RNF-10).")]),
  parrafo("Virginia del Carmen Moreno Gallegos, titular del criadero, aprobó la versión final de la aplicación."),
);

// 3
children.push(
  titulo("3. Proceso fluido y colaborativo"),
  pregunta("¿El proceso de desarrollo fue fluido y colaborativo?"),
  parrafo([
    B("Fue colaborativo, pero no fluido al principio. "),
    t("Colaborativo, porque el cliente revisó cada iteración y sus comentarios dirigieron el diseño: sobre la primera dijo “la app no es muy buena” y sobre la segunda “no me termina de gustar nada el diseño: no tiene imágenes de los animales y es cero intuitivo”."),
  ]),
  parrafo("No fue fluido porque esas dos respuestas obligaron a descartar el diseño y reconstruirlo desde cero en cuatro pestañas con ilustraciones por raza. A partir de la tercera iteración el trabajo avanzó sin rechazos de fondo: los cambios posteriores fueron ajustes puntuales y la titular aprobó la versión final."),
);

// 4
children.push(
  titulo("4. Problemas evitables"),
  pregunta("¿Hubo algún problema o imprevisto que hubiera podido evitarse?"),
  parrafo([B("Sí, tres. ")]),
  viñeta([B("Los dos diseños rechazados. "), t("Se construyeron antes de confirmar con el cliente lo que más le importaba: ver imágenes de los animales y que la app fuera intuitiva. Se pudo evitar mostrando un prototipo con imágenes reales antes de programar.")]),
  viñeta([B("El módulo de pedidos. "), t("Se construyó porque los pedidos llegan por Facebook y WhatsApp, y al final se decidió quitarlo de la aplicación. Confirmar el alcance con el cliente antes de construirlo habría ahorrado ese trabajo y la actualización posterior de los documentos.")]),
  viñeta([B("La subida de una foto propia. "), t("No se pudo probar (CP-14) porque el simulador no tiene fotografías. Se pudo prever programando desde el inicio una prueba en un iPhone real.")]),
  parrafo("Además quedó registrada una observación sin causa identificada: en dos ocasiones el primer toque en un botón no respondió y funcionó al repetirlo."),
);

// 5
children.push(
  titulo("5. Comunicación entre los miembros"),
  pregunta("¿Qué podemos hacer para mejorar la comunicación entre los miembros del equipo?"),
  parrafo("Quienes participamos somos la titular del criadero (Virginia), yo en limpieza y alimentación y el veterinario, el Dr. Rafael de Leija Lara. Para comunicarnos mejor propongo:"),
  viñeta("Una reunión corta y fija cada semana, con la app abierta en el teléfono del cliente, para que vea el avance y no solo lo escuche."),
  viñeta("Mostrar capturas o un prototipo antes de programar cada pantalla, para recibir observaciones cuando cambiar es barato."),
  viñeta("Anotar por escrito, al terminar cada reunión, lo que dijo el cliente con sus propias palabras y lo que se acordó."),
  viñeta("Usar un solo canal para dudas y avisos, por ejemplo un grupo de WhatsApp, que es el medio que el criadero ya utiliza."),
);

// 6
children.push(
  titulo("6. Documentación del proceso"),
  pregunta("¿Qué podemos hacer para mejorar la documentación del proceso?"),
  parrafo("La documentación fue completa, pero se desactualizó cuando cambió el alcance. Para mejorarla propongo:"),
  viñeta("Mantener el cronograma con el estado real de cada actividad, actualizado el mismo día en que cambia."),
  viñeta("Llevar la trazabilidad entre requerimientos y casos de prueba, y revisarla cada vez que se agrega o se retira una función."),
  viñeta("Registrar el comentario del cliente el mismo día, con la fecha y la decisión que provocó."),
  viñeta("Conservar de cada iteración las capturas y el código archivado, como se hizo con las iteraciones 1 a 3, porque permitió justificar cada cambio."),
  viñeta("Usar desde el inicio el formato de registro de pruebas de la materia, en lugar de adaptarlo al final."),
);

// 7. Satisfacción del cliente
children.push(
  titulo("7. Satisfacción del cliente"),
  parrafo("La satisfacción de la titular del criadero, Virginia del Carmen Moreno Gallegos, se siguió en cada entrega y quedó registrada con sus propias palabras. La tabla resume su reacción y lo que se hizo en respuesta."),
  tablaSatisfaccion(),
  new Paragraph({ spacing: { after: 120 }, children: [] }),
  parrafo("Al final se le pidió calificar ocho afirmaciones sobre la aplicación, de 1 (nada de acuerdo) a 5 (totalmente de acuerdo). Ella comunicó sus calificaciones al alumno y todas fueron 5, por lo que el índice de satisfacción es 5.0 de 5."),
  tablaIndice(),
  new Paragraph({ spacing: { after: 120 }, children: [] }),
  parrafo("La reacción pasó de dos rechazos de diseño a la aprobación de la versión final y a una satisfacción plena con la aplicación terminada."),
);

// 8. Certificado
children.push(
  titulo("8. Certificado de LinkedIn Learning"),
  parrafo("Como parte de esta fase se completó el curso Complete Guide to SwiftUI de LinkedIn Learning, con una duración de 10 horas y 57 minutos, el 23 de noviembre de 2026. Cubre las aptitudes iOS y SwiftUI, las mismas con las que se construyó la aplicación. El certificado se incluye a continuación."),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 160 }, children: [
    new ImageRun({ type: "png", data: fs.readFileSync("cert.png"), transformation: { width: 540, height: 417 },
      altText: { title: "Certificado", description: "Certificado de finalización del curso Complete Guide to SwiftUI", name: "certificado" } }),
  ] }),
);

// Conclusión
children.push(
  titulo("Conclusión general"),
  parrafo("El proyecto me dejó aprendizajes técnicos y de trabajo con un cliente real. El más importante es que quien decide si una aplicación es buena es quien la usa: la app final no se parece al primer diseño, y eso es un resultado, no un fracaso. Aprendí que preguntar y mostrar pronto cuesta menos que corregir después."),
  parrafo("En lo técnico, construí una aplicación completa de iOS con SwiftUI y SwiftData que funciona sin internet y probé sus flujos en el simulador. Aprendí a diseñar para el uso real de un criadero, de pie y con guantes, con botones grandes y pocas decisiones por pantalla, y a usar información con fuente: los datos de las razas son un resumen de Wikipedia y las fotos son de Wikimedia Commons, con su autor y su licencia."),
  parrafo("Quedan pendientes que no oculto: probar la subida de la foto propia en un iPhone real y los requerimientos de historial de pesos, ración y dieta, costo real por kilogramo y calendario de sanidad. Me llevo, además, la certeza de que un proyecto de este tipo se sostiene con comunicación frecuente y documentación al día."),
);

const doc = new Document({
  creator: "José Guadalupe Rico Moreno",
  title: "Hallazgos y lecciones aprendidas",
  styles: { default: { document: { run: { font: CUERPO, size: 22 } } } },
  numbering: {
    config: [{
      reference: "vineta",
      levels: [{ level: 0, format: "bullet", text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 560, hanging: 280 } }, run: { font: CUERPO, color: VERDE } } }],
    }],
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440, header: 560, footer: 560 },
        borders: {
          pageBorderTop: { style: BorderStyle.SINGLE, size: 12, color: VERDE, space: 24 },
          pageBorderRight: { style: BorderStyle.SINGLE, size: 12, color: VERDE, space: 24 },
          pageBorderBottom: { style: BorderStyle.SINGLE, size: 12, color: VERDE, space: 24 },
          pageBorderLeft: { style: BorderStyle.SINGLE, size: 12, color: VERDE, space: 24 },
          pageBorders: { display: PageBorderDisplay.ALL_PAGES, offsetFrom: PageBorderOffsetFrom.PAGE, zOrder: PageBorderZOrder.FRONT },
        },
      },
    },
    footers: {
      default: new Footer({
        children: [
          new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [
              new TextRun({ text: "José Guadalupe Rico Moreno · AL03063503 · ", font: CUERPO, size: 18, color: "5E574B" }),
              new TextRun({ children: [PageNumber.CURRENT], font: CUERPO, size: 18, color: "5E574B" }),
              new TextRun({ text: " / ", font: CUERPO, size: 18, color: "5E574B" }),
              new TextRun({ children: [PageNumber.TOTAL_PAGES], font: CUERPO, size: 18, color: "5E574B" }),
            ],
          }),
          new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ text: "Universidad Tecmilenio · Desarrollo de proyecto de aplicaciones móviles · Hallazgos y lecciones aprendidas", font: CUERPO, size: 16, color: "5E574B" })],
          }),
        ],
      }),
    },
    children,
  }],
});

Packer.toBuffer(doc).then((b) => { fs.writeFileSync(OUT, b); console.log("OK", OUT); });
