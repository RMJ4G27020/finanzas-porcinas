# -*- coding: utf-8 -*-
"""Genera Entregables/Por_separado/06_Registro_Prueba_CP-15.docx a partir del registro de CP-13
(mismo formato de pruebas de la materia) con los datos de la iteracion 4."""
import io
from pathlib import Path

from docx import Document
from docx.oxml.ns import qn
from PIL import Image

BASE = Path(__file__).resolve().parent.parent
SRC = BASE / 'Entregables' / 'Por_separado' / '04_Registro_Prueba_CP-13.docx'
OUT = BASE / 'Entregables' / 'Por_separado' / '06_Registro_Prueba_CP-15.docx'
FOTOS = BASE / 'Pruebas' / 'Iteracion4_Fotos_reales'

doc = Document(str(SRC))
body = doc.element.body
els = list(body.iterchildren())


def set_text(el, texto):
    ts = list(el.iter(qn('w:t')))
    ts[0].text = texto
    ts[0].set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
    for t in ts[1:]:
        t.text = ''


def celda(tbl, r, c):
    return tbl.findall(qn('w:tr'))[r].findall(qn('w:tc'))[c]


def par(i, texto):
    set_text(els[i], texto)


def cel(i, r, c, texto):
    set_text(celda(els[i], r, c), texto)


par(1, 'Registro individual · CP-15 · Prueba de componente')
cel(2, 0, 0, 'Alcance: CP-15 se ejecutó en el simulador el 20/11/2026 (iteración 4) y se recorrió de nuevo el 23/11/2026 al grabar el video de demostración. Esta ficha registra la foto real por raza en la lista y la ficha y la Guía de razas; no incluye la carga de una fotografía propia.')
cel(4, 3, 1, '20/11/2026')
cel(4, 4, 1, 'Ejecución asistida por Claude Code, a solicitud de José Guadalupe Rico Moreno')
par(6, 'Validar que la lista y la ficha de cada animal sin foto propia muestren la foto real de su raza con la etiqueta «Foto de ejemplo», y que la Guía de razas muestre los datos de cada raza con el crédito de su foto.')
par(10, 'Módulos Animales, Ficha del animal y Guía de razas: la cuadrícula y la ficha muestran la foto real de la raza (Wikimedia Commons, licencia libre); la guía reúne datos resumidos de Wikipedia, la foto de cada raza y su crédito (autor, licencia y enlace).')
par(11, '5. Caso de prueba CP-15')
cel(12, 0, 1, 'CP-15 · Foto real por raza y Guía de razas')
cel(12, 1, 1, 'Comprobar que cada animal sin foto propia se muestre con la foto real de su raza y que la Guía de razas muestre datos y créditos.')
cel(12, 3, 1, 'Animales de razas Común, Minipig y Cruza; búsqueda «Minipig».')
cel(12, 4, 1, '1. Abrir la pestaña Animales y verificar las fotos de Cerdo 01 (Común), Cerdo 02 (Minipig) y Cerdo 03 (Cruza).  2. Buscar «Minipig» y verificar que cada resultado muestre la foto del minipig.  3. Abrir Cerdo 02 y verificar la etiqueta «Foto de ejemplo de la raza».  4. Tocar Razas y recorrer la guía.')
cel(12, 5, 1, 'Cada animal muestra la foto real de su raza, con la etiqueta de foto de ejemplo en la ficha; la guía muestra el resumen, los datos y el crédito de la foto de cada raza.')
cel(12, 6, 1, 'La cuadrícula mostró las fotos de Común, Minipig y Cruza; la búsqueda «Minipig» mostró cinco cerdos con la foto del minipig; la ficha de Cerdo 02 mostró «Foto de ejemplo de la raza»; la guía mostró cada raza con su resumen, sus datos y el autor, la licencia y el enlace de la foto.')
par(14, 'No aplica a CP-15, que es una prueba de componente. Los flujos de integración se registran por separado en el informe de Fase III (PI-01 y PI-03 a PI-05).')
cel(16, 3, 1, 'La cuadrícula, la ficha y la guía mostraron las fotos reales y sus textos; la guía se recorrió completa con desplazamiento.')
cel(18, 1, 1, 'No se registraron errores asociados a CP-15.')
par(20, 'Capturas tomadas durante la ejecución de CP-15 en iPhone 17 Pro Simulator con iOS 26.4. Las fotos son de ejemplo de la raza; no acreditan la carga de una fotografía propia.')
par(23, 'CP-15 fue aprobado el 20/11/2026. La cuadrícula y la ficha mostraron la foto real de cada raza y la guía presentó los datos y el crédito de cada foto. En una ocasión el primer toque en el atajo de la guía no respondió y funcionó al repetirlo; se conserva como observación sin causa identificada.')
par(25, 'Probar CP-14 en un iPhone con una fotografía disponible. La carga de una foto propia no se pudo ejecutar en el simulador y permanece pendiente; esta ficha no la considera aprobada.')

# leyendas de las figuras (misma celda que las imagenes)
fila_fig = els[21].findall(qn('w:tr'))[0].findall(qn('w:tc'))
for tc, nuevo in zip(fila_fig, ['Figura 1. Lista en iPhone 17 Pro Simulator · fotos reales de Común, Minipig y Cruza.',
                                 'Figura 2. Ficha de Cerdo 03 · Cruza con la etiqueta Foto de ejemplo de la raza.']):
    ts = list(tc.iter(qn('w:t')))
    ts[0].text = nuevo
    for t in ts[1:]:
        t.text = ''

# imagenes: JPEG de 368 x 800 como en CP-13
for sh, nombre in zip(doc.inline_shapes, ['02_animales.png', '05_ficha_animal.png']):
    im = Image.open(FOTOS / nombre).convert('RGB').resize((368, 800), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, 'JPEG', quality=88)
    rid = sh._inline.find('.//' + qn('a:blip')).get(qn('r:embed'))
    doc.part.related_parts[rid]._blob = buf.getvalue()

doc.core_properties.title = 'Registro de prueba CP-15'
doc.save(str(OUT))
print('Registro CP-15:', OUT)
