#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Reestructura el documento de la Fase III segun la actividad:
  1 Introduccion / 2 Parte 1 / 3 Parte 2 (plan de accion) / 4 Cronograma
  5 Fase I / 6 Fase II / 7 Fase III / 8 Fase IV / 9 Iteraciones
  10 Fase V / 11 Certificado / 12 Conclusiones / Referencias / Anexo A

Conserva portada, estilos, imagenes y tablas del documento original.
"""
import copy
import re
import shutil
import subprocess
import sys
from pathlib import Path

from docx import Document
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.text.paragraph import Paragraph
from docx.shared import Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH

BASE = Path(__file__).resolve().parent.parent
SRC = BASE / 'Archivo' / 'Fase_III_Finanzas_Porcinas_ORIGINAL_2026-10-30.docx'
OUT = BASE / 'Entregables' / 'Fase_III_Finanzas_Porcinas.docx'
PDF_OUT = BASE / 'Entregables' / 'Fase_III_Finanzas_Porcinas.pdf'

doc = Document(str(SRC))
body = doc.element.body


def q(tag):
    return qn('w:' + tag)


def text_of(el):
    return ''.join(t.text or '' for t in el.iter(q('t')))


def find_par(prefix, style=None):
    for el in body.iterchildren():
        if el.tag == q('p'):
            p = Paragraph(el, doc)
            if p.text.strip().startswith(prefix) and (style is None or p.style.name == style):
                return p
    raise KeyError('No se encontro: %r (%s)' % (prefix, style))


# ---------------------------------------------------------------- plantillas
H1_T = copy.deepcopy(find_par('1. Cronograma de actividades', 'Heading 1')._p)
H2_T = copy.deepcopy(find_par('2.1 Introducción', 'Heading 2')._p)
BODY_T = copy.deepcopy(find_par('En el Criadero Fam Rico Moreno')._p)
LABEL_T = copy.deepcopy(find_par('RF-01 Saludo', 'Normal')._p)
CAPTION_T = copy.deepcopy(find_par('Figura 1. Capturas')._p)
PB_T = copy.deepcopy(find_par('Anexo A.', 'Heading 1')._p.getprevious())

IDX_HEAD = find_par('Índice', 'Heading 1')._p
H_CRONO = find_par('1. Cronograma de actividades', 'Heading 1')._p

# entradas del indice viejo (entre "Indice" y el cronograma)
toc_els = []
el = IDX_HEAD.getnext()
while el is not None and el is not H_CRONO:
    toc_els.append(el)
    el = el.getnext()
assert len(toc_els) > 30, len(toc_els)
TOC1_T = copy.deepcopy(toc_els[0])
TOC2_T = copy.deepcopy(next(e for e in toc_els
    if e.findall('.//' + q('b')) and e.findall('.//' + q('b'))[0].get(q('val')) == 'false'))
SECT = toc_els[-1].find('.//' + q('sectPr'))
assert SECT is not None
SECT.getparent().remove(SECT)  # se reutiliza al final del indice nuevo


# ---------------------------------------------------------------- utilidades
def run(text, bold=False, italic=False, font='Arial', size=10.5, color='1E241E'):
    r = OxmlElement('w:r')
    rPr = OxmlElement('w:rPr')
    rf = OxmlElement('w:rFonts')
    for a in ('ascii', 'hAnsi', 'cs', 'eastAsia'):
        rf.set(q(a), font)
    rPr.append(rf)
    if bold:
        rPr.append(OxmlElement('w:b'))
        rPr.append(OxmlElement('w:bCs'))
    if italic:
        rPr.append(OxmlElement('w:i'))
        rPr.append(OxmlElement('w:iCs'))
    c = OxmlElement('w:color')
    c.set(q('val'), color)
    rPr.append(c)
    sz = OxmlElement('w:sz')
    sz.set(q('val'), str(int(size * 2)))
    rPr.append(sz)
    szcs = OxmlElement('w:szCs')
    szcs.set(q('val'), str(int(size * 2)))
    rPr.append(szcs)
    r.append(rPr)
    t = OxmlElement('w:t')
    t.set(qn('xml:space'), 'preserve')
    t.text = text
    r.append(t)
    return r


def strip_runs(p):
    for ch in list(p):
        if ch.tag != q('pPr'):
            p.remove(ch)


def H1(text):
    p = copy.deepcopy(H1_T)
    strip_runs(p)
    r = OxmlElement('w:r')
    t = OxmlElement('w:t')
    t.set(qn('xml:space'), 'preserve')
    t.text = text
    r.append(t)
    p.append(r)
    return p


def H2(text):
    p = copy.deepcopy(H2_T)
    strip_runs(p)
    r = OxmlElement('w:r')
    t = OxmlElement('w:t')
    t.set(qn('xml:space'), 'preserve')
    t.text = text
    r.append(t)
    p.append(r)
    return p


def P(text, bold=False, size=10.5, color='1E241E', align=None):
    p = copy.deepcopy(BODY_T)
    strip_runs(p)
    p.append(run(text, bold=bold, size=size, color=color))
    if align:
        pPr = p.find(q('pPr'))
        for j in pPr.findall(q('jc')):
            pPr.remove(j)
        jc = OxmlElement('w:jc')
        jc.set(q('val'), align)
        pPr.append(jc)
    return p


def B(text):
    return P('- ' + text)


def SUB(text):
    p = copy.deepcopy(BODY_T)
    strip_runs(p)
    p.append(run(text, bold=True, color='1F3A2E'))
    return p


def CAP(text):
    p = copy.deepcopy(CAPTION_T)
    strip_runs(p)
    p.append(run(text, italic=True, color='5C665C', size=9))
    return p


def IMG(rel, width_in):
    p = copy.deepcopy(BODY_T)
    strip_runs(p)
    pPr = p.find(q('pPr'))
    for j in pPr.findall(q('jc')):
        pPr.remove(j)
    jc = OxmlElement('w:jc')
    jc.set(q('val'), 'center')
    pPr.append(jc)
    para = Paragraph(p, doc)
    r = para.add_run()
    r.add_picture(str(BASE / rel), width=Inches(width_in))
    return p


def CODE(line):
    p = OxmlElement('w:p')
    pPr = OxmlElement('w:pPr')
    shd = OxmlElement('w:shd')
    shd.set(q('val'), 'clear')
    shd.set(q('color'), 'auto')
    shd.set(q('fill'), 'F4F1E8')
    pPr.append(shd)
    sp = OxmlElement('w:spacing')
    sp.set(q('before'), '0')
    sp.set(q('after'), '0')
    sp.set(q('line'), '240')
    sp.set(q('lineRule'), 'auto')
    pPr.append(sp)
    ind = OxmlElement('w:ind')
    ind.set(q('left'), '280')
    ind.set(q('right'), '280')
    pPr.append(ind)
    jc = OxmlElement('w:jc')
    jc.set(q('val'), 'left')
    pPr.append(jc)
    p.append(pPr)
    p.append(run(line if line else ' ', font='Consolas', size=8))
    return p


def cell(text, width, header, size):
    tc = OxmlElement('w:tc')
    tcPr = OxmlElement('w:tcPr')
    tcW = OxmlElement('w:tcW')
    tcW.set(q('type'), 'dxa')
    tcW.set(q('w'), str(width))
    tcPr.append(tcW)
    shd = OxmlElement('w:shd')
    shd.set(q('val'), 'clear')
    shd.set(q('color'), 'auto')
    shd.set(q('fill'), '1F3A2E' if header else 'FFFFFF')
    tcPr.append(shd)
    mar = OxmlElement('w:tcMar')
    for side, val in (('top', '60'), ('left', '120'), ('bottom', '60'), ('right', '120')):
        e = OxmlElement('w:' + side)
        e.set(q('type'), 'dxa')
        e.set(q('w'), val)
        mar.append(e)
    tcPr.append(mar)
    va = OxmlElement('w:vAlign')
    va.set(q('val'), 'center')
    tcPr.append(va)
    tc.append(tcPr)
    p = OxmlElement('w:p')
    pPr = OxmlElement('w:pPr')
    sp = OxmlElement('w:spacing')
    sp.set(q('after'), '40')
    sp.set(q('before'), '40')
    sp.set(q('line'), '250')
    pPr.append(sp)
    jc = OxmlElement('w:jc')
    jc.set(q('val'), 'left')
    pPr.append(jc)
    p.append(pPr)
    if header:
        p.append(run(str(text), bold=True, color='FFFFFF', size=size))
    else:
        p.append(run(str(text), bold=False, color='1E241E', size=size))
    tc.append(p)
    return tc


def TABLE(rows, widths, size=9):
    assert abs(sum(widths) - 9070) < 2, (widths, sum(widths))
    tbl = OxmlElement('w:tbl')
    tblPr = OxmlElement('w:tblPr')
    tblW = OxmlElement('w:tblW')
    tblW.set(q('type'), 'dxa')
    tblW.set(q('w'), '9070')
    tblPr.append(tblW)
    borders = OxmlElement('w:tblBorders')
    for side, col, sz in (('top', '1F3A2E', '8'), ('left', '1F3A2E', '8'),
                          ('bottom', '1F3A2E', '8'), ('right', '1F3A2E', '8'),
                          ('insideH', 'C3CDC1', '4'), ('insideV', 'C3CDC1', '4')):
        e = OxmlElement('w:' + side)
        e.set(q('val'), 'single')
        e.set(q('sz'), sz)
        e.set(q('space'), '0')
        e.set(q('color'), col)
        borders.append(e)
    tblPr.append(borders)
    layout = OxmlElement('w:tblLayout')
    layout.set(q('type'), 'fixed')
    tblPr.append(layout)
    tbl.append(tblPr)
    grid = OxmlElement('w:tblGrid')
    for w in widths:
        gc = OxmlElement('w:gridCol')
        gc.set(q('w'), str(w))
        grid.append(gc)
    tbl.append(grid)
    for i, row in enumerate(rows):
        assert len(row) == len(widths), (len(row), len(widths), row[:2])
        tr = OxmlElement('w:tr')
        trPr = OxmlElement('w:trPr')
        trPr.append(OxmlElement('w:cantSplit'))
        if i == 0:
            trPr.append(OxmlElement('w:tblHeader'))
        tr.append(trPr)
        for j, val in enumerate(row):
            tr.append(cell(val, widths[j], i == 0, size))
        if len(rows) >= 3 and i in (0, 1, len(rows) - 2):
            for tc in tr.findall(q('tc')):
                for p_el in tc.findall(q('p')):
                    keep_next(p_el)
        tbl.append(tr)
    return tbl



def keep_next(p_el):
    pPr = p_el.find(q('pPr'))
    if pPr is None:
        return
    if pPr.find(q('keepNext')) is not None:
        return
    kn = OxmlElement('w:keepNext')
    pStyle = pPr.find(q('pStyle'))
    if pStyle is not None:
        pStyle.addnext(kn)
    else:
        pPr.insert(0, kn)


def page_break_before(p_el):
    pPr = p_el.find(q('pPr'))
    if pPr is None or pPr.find(q('pageBreakBefore')) is not None:
        return
    pb = OxmlElement('w:pageBreakBefore')
    kn = pPr.find(q('keepNext'))
    if kn is not None:
        kn.addnext(pb)
    else:
        ps = pPr.find(q('pStyle'))
        if ps is not None:
            ps.addnext(pb)
        else:
            pPr.insert(0, pb)


def build(items):
    out = []
    for it in items:
        k = it[0]
        if k == 'h1':
            out.append(H1(it[1]))
        elif k == 'h2':
            out.append(H2(it[1]))
        elif k == 'p':
            out.append(P(it[1]))
        elif k == 'p_left':
            out.append(P(it[1], align='left'))
        elif k == 'b':
            out.append(B(it[1]))
        elif k == 'sub':
            out.append(SUB(it[1]))
        elif k == 'cap':
            out.append(CAP(it[1]))
        elif k == 'tbl':
            out.append(TABLE(it[1], it[2]))
        elif k == 'code':
            out.extend(CODE(line) for line in it[1])
        elif k == 'img':
            out.append(IMG(it[1], it[2]))
        else:
            raise ValueError(k)
    for i, e in enumerate(out):
        if e.tag == q('tbl') and i > 0 and out[i - 1].tag == q('p'):
            keep_next(out[i - 1])
    return out


def insert_after(anchor, els):
    cur = anchor
    for e in els:
        cur.addnext(e)
        cur = e
    return cur


def insert_before(anchor, els):
    for e in els:
        anchor.addprevious(e)


# ---------------------------------------------------------------- 1. desarmar
STUB = [H_CRONO, H_CRONO.getnext(), H_CRONO.getnext().getnext()]
IMG_P, CAP_P = STUB[1], STUB[2]
assert IMG_P.tag == q('p') and IMG_P.findall('.//' + q('drawing'))
assert CAP_P.find('.//' + q('sectPr')) is not None
for e in STUB:
    body.remove(e)

for e in toc_els:
    body.remove(e)

# "2.2 Problematica": el parrafo se mueve a 1.3
h22 = find_par('2.2 Problemática a resolver', 'Heading 2')._p
P_PROB = h22.getnext()
body.remove(h22)

# ---------------------------------------------------------------- 2. contenido
FRONT = [
    ('h1', '1. Introducción'),
    ('h2', '1.1 Descripción del proyecto'),
    ('p', 'Este documento reúne los entregables de la Fase III. Ejecución de la materia Desarrollo de proyecto de aplicaciones móviles, correspondiente al Proyecto Integrador de José Guadalupe Rico Moreno, matrícula AL03063503. El proyecto consiste en el diseño, la construcción, la prueba y la integración de Finanzas Porcinas, una aplicación móvil nativa de iOS para el Criadero Fam Rico Moreno, un emprendimiento familiar de crianza de puercos en Aldama, Tamaulipas.'),
    ('p', 'La aplicación concentra en un solo lugar el control del hato, las tareas diarias de alimentación y limpieza, las compras de insumos, las ventas, las visitas del veterinario y los pedidos que llegan por Facebook y por WhatsApp. Funciona en el iPhone de la titular, en español y sin conexión a internet.'),
    ('p', 'El documento sigue el orden de la actividad. Primero presenta la introducción y la problemática; después, la Parte 2 (plan de acción con rumbo, sector y cliente, prioridades, acciones y cronograma); en seguida desarrolla las cinco fases de ejecución —análisis de requerimientos, diseño de solución, construcción, pruebas e integración—, documenta la evolución del diseño y cierra con la evidencia del curso de LinkedIn Learning, las conclusiones y los anexos.'),
    ('h2', '1.2 Objetivo'),
    ('p', 'El objetivo de la fase es realizar el plan de acción del proyecto con un modelo de desarrollo ágil, indicar la problemática que resuelve y ejecutar ese plan hasta obtener una aplicación funcional. El plan se administra en una hoja de cálculo que concentra las actividades con su inicio, su fin, sus dependencias, su complejidad, su estado y su avance, de modo que los avances, las interrupciones y los ajustes queden registrados.'),
    ('p', 'El resultado esperado es una aplicación de iOS terminada y probada, acompañada de los documentos de requerimientos, diseño, código y pruebas, y del certificado del curso de LinkedIn Learning.'),
    ('h2', '1.3 Problemática a resolver'),
    # aqui se inserta el parrafo original de la problematica
    ('h2', '1.4 Metodología de desarrollo'),
    ('p', 'Se aplicó el modelo ágil evolutivo. En lugar de congelar un diseño y construirlo por partes, se construyó una versión funcional completa, se mostró al cliente y se corrigió con sus observaciones; cada iteración volvió a recorrer las cinco fases. Se hicieron tres iteraciones del diseño, documentadas en el capítulo 9.'),
    ('p', 'El plan de acción se administra en el archivo 01_Cronograma_FaseIII.xlsx, una hoja con las cinco fases, 24 actividades y una fila de seguimiento real por fase. Cada actividad declara su inicio, su fin, su duración, su dependencia, su complejidad, su estado y su avance. Las interrupciones y los ajustes se registran en la misma hoja: si una actividad se adelanta o se pospone, se actualiza su estado y se conserva la fila real.'),
    ('p', 'Las herramientas fueron Xcode 26.4, el lenguaje Swift 5, SwiftUI para la interfaz y SwiftData para la persistencia local. Las pruebas se ejecutaron en el simulador de iPhone 17 Pro con iOS 26.4. No se usaron dependencias externas ni servicios en la nube.'),
    ('h2', '1.5 Alcance y criterios de evaluación'),
    ('p', 'La siguiente tabla relaciona cada criterio de la rúbrica con el capítulo donde se cumple y con la evidencia que lo respalda.'),
    ('tbl', [
        ['Criterio de evaluación', 'Puntaje', 'Dónde se cumple'],
        ['Listado de requerimientos posibles y alcanzables', '5', 'Capítulo 4: 24 requerimientos funcionales, 10 no funcionales y 5 fuera de alcance.'],
        ['Documento de diseño de solución', '10', 'Capítulo 5: arquitectura, modelo de datos, diagrama de navegación, requerimientos de diseño y componentes.'],
        ['Archivos de programación y archivos de diseño editables', '15', 'Capítulo 6: 14 archivos Swift, 6,057 líneas, proyecto FinanzasPorcinas.xcodeproj.'],
        ['Prototipos y resultados de cada prueba', '20', 'Capítulo 7: 13 casos de componente y 5 de integración con capturas del simulador.'],
        ['App funcional', '40', 'Capítulo 8: aplicación integrada, versión 1.0 (build 1).'],
        ['Curso de LinkedIn Learning y evidencia del certificado', '10', 'Capítulo 10: certificado del curso Swift 5: Protocol-Oriented Programming.'],
        ['Total', '100', ''],
    ], [3800, 1000, 4270]),
    ('p', 'Los entregables de la fase y su ubicación son los siguientes:'),
    ('b', 'Cronograma: capítulo 3 y 01_Cronograma_FaseIII.xlsx.'),
    ('b', 'Requerimientos: capítulo 4 y 02_Listado_de_Requerimientos.docx.'),
    ('b', 'Diseño de solución: capítulo 5 y 03_Diseno_de_Solucion.docx.'),
    ('b', 'Programación y diseño: capítulo 6 y FinanzasPorcinas.xcodeproj.'),
    ('b', 'Prototipos y pruebas: capítulo 7 y 05_Prototipos_y_Pruebas.docx.'),
    ('b', 'App funcional: capítulo 8 y la aplicación en el simulador.'),
    ('b', 'Certificado: capítulo 10 y el PDF del certificado de LinkedIn Learning.'),

]

NEW = build(FRONT)
LAST_FRONT = insert_after(IDX_HEAD, NEW)

# mover el parrafo original de la problematica a 1.3
h13 = find_par('1.3 Problemática a resolver', 'Heading 2')._p
h13.addnext(P_PROB)
P_PROB.addnext(P('La consecuencia es que las decisiones se toman con información incompleta: no se sabe cuánto costó criar a un cerdo, cuánto alimento consumió, qué pedidos están pendientes de entrega ni qué animal conviene vender. La aplicación atiende esa problemática con un registro único, capturado en el momento y en el lugar donde ocurre el trabajo.'))

# ---------------------------------------------------------------- 3. Parte 2
PARTE2 = [
    ('h1', '2. Parte 2. Plan de acción'),
    ('p', 'El plan de acción parte de dos insumos de la Parte 2 del proyecto integrador: la indagación del posicionamiento de la empresa y la minuta con el cliente. Esos insumos se levantaron en las siete sesiones de trabajo con la titular, realizadas del 24 al 30 de agosto de 2026, y se formalizaron con la carta de conformidad del 3 de octubre de 2026. En este capítulo se sintetizan en cinco pasos: rumbo y acciones, sector y cliente principal, clasificación de necesidades por categorías, prioridades y listado de acciones; el sexto paso, el cronograma, se presenta en el capítulo 3. La síntesis por perfil de los acuerdos verbales se conserva en el Anexo A.'),
    ('h2', '2.1 Rumbo y acciones para posicionar el producto'),
    ('p', 'El rumbo se definió a partir de la misión y la visión de la empresa y se tradujo en acciones concretas de promoción y posicionamiento. Cada acción se relaciona con la parte de la aplicación que la sostiene, de modo que el plan no quede en intenciones.'),
    ('sub', 'Misión'),
    ('p', 'Criar y vender carne de cerdo de calidad en Aldama, Tamaulipas, con trato directo y precio claro por kilogramo, para que las familias de la localidad tengan carne fresca y confiable y el criadero familiar crezca de forma ordenada.'),
    ('sub', 'Visión'),
    ('p', 'Ser el criadero de referencia de Aldama por la calidad de su carne y por la confianza que da a sus clientes: cada animal identificado, cada peso registrado y cada pedido entregado a tiempo.'),
    ('sub', 'Valores'),
    ('b', 'Trato directo: el cliente habla con la familia que cría al animal, no con un intermediario.'),
    ('b', 'Precio claro: el precio por kilogramo se dice antes de cerrar el pedido, sin cargos que aparezcan después.'),
    ('b', 'Registro ordenado: lo que no se anota, no existe; el peso, el alimento y el dinero se registran el mismo día.'),
    ('b', 'Cuidado del animal: la sanidad y la alimentación se atienden a tiempo, porque de eso depende la calidad de la carne.'),
    ('p', 'El rumbo se organizó en cuatro ejes. La tabla muestra, para cada eje, la acción de posicionamiento y la forma en que la aplicación la sostiene.'),
    ('tbl', [
        ['Eje', 'Acción para promover y posicionar', 'Cómo la sostiene la aplicación'],
        ['Producto y precio', 'Comunicar el precio por kilogramo sin ambigüedad y sostener los dos precios del criadero: $40 u $80 según el caso.', 'Calcula el total de cada venta y de cada pedido, y muestra el precio elegido. El precio nunca se asigna solo: lo elige la persona.'],
        ['Confianza y relación', 'Responder por el mismo canal en el que llegó el pedido y dar seguimiento hasta la entrega.', 'Registra el canal (Facebook o WhatsApp), asigna un folio consecutivo y avanza el pedido por sus tres estados.'],
        ['Orden interno y costos', 'Conocer cuánto cuesta criar a un cerdo y comparar proveedores de alimento antes de comprar.', 'Registra compras con su total, compara el precio por bulto entre proveedores y muestra si una venta deja ganancia.'],
        ['Sanidad y bienestar', 'Mostrar que los animales reciben atención veterinaria y que las visitas quedan registradas.', 'Agenda y registra las visitas del Dr. Rafael de Leija Lara, con la próxima visita y su historial.'],
    ], [2000, 3300, 3770]),
    ('h2', '2.2 Sector y cliente principal'),
    ('p', 'La empresa pertenece al sector de la porcicultura familiar y a la venta local de carne y derivados. Su cliente principal no es una empresa ni una tienda: son los hogares de Aldama y de las colonias cercanas que piden por la cuenta personal de Facebook de la titular o por los grupos de WhatsApp de las colonias. Esa clientela no usa la aplicación; la titular captura el pedido y lo da de alta.'),
    ('tbl', [
        ['Elemento', 'Descripción', 'Implicación para la aplicación'],
        ['Sector', 'Porcicultura familiar y comercio local de carne y derivados en Aldama, Tamaulipas.', 'Opera sin internet y en un solo dispositivo, el iPhone de la titular.'],
        ['Oferta', '17 animales de crianza; 12 puercos al año para venta de carne y derivados. Razas Común, Minipig y Cruza.', 'Ficha por animal con raza, peso, destino y notas; el hato completo se ve en una cuadrícula.'],
        ['Cliente principal', 'Hogares de Aldama y colonias cercanas que piden por Facebook o por grupos de WhatsApp.', 'Cada pedido guarda su canal de origen y el pedido completo se sigue por estado.'],
        ['Nivel de compra', 'Desde un pedido de pocos kilogramos hasta el cerdo completo (96 kg en el ejemplo registrado). La compra es recurrente y se acuerda por conversación.', 'Totales por kilogramo y por pedido, con el precio calculado a la vista antes de confirmar.'],
        ['Preferencias', 'Precio claro por kilogramo, carne fresca, entrega acordada y trato directo con la familia.', 'Muestra el precio elegido y el total; el lenguaje es del criadero, no contable.'],
        ['Lealtad', 'Se sostiene en la relación personal y en los grupos de WhatsApp; se pierde si el pedido se entrega incompleto o tarde.', 'Aviso de pedidos por entregar en la pantalla Hoy y avance del estado hasta Entregado.'],
    ], [1700, 3600, 3770]),
    ('p', 'De esta lectura se desprenden dos decisiones de alcance. La primera: la aplicación es de uso interno del criadero, porque quien compra no necesita una cuenta ni una app. La segunda: como la lealtad depende de la entrega, el avance del pedido es un requerimiento de negocio y no una función decorativa.'),
    ('h2', '2.3 Clasificación de necesidades por categorías'),
    ('p', 'De la minuta con el cliente se extrajeron las necesidades y se clasificaron en ocho categorías y una más de gestión del proyecto. Cada categoría agrupa necesidades del mismo tipo y se relaciona con los requerimientos que las atienden.'),
    ('tbl', [
        ['Categoría', 'Necesidades identificadas', 'Requerimientos que la atienden'],
        ['Diseño e identidad visual', 'Ver a cada animal y reconocerlo; texto grande; botones que se puedan tocar con guantes y con sol.', 'RF-08, RF-09, RNF-04, RNF-05'],
        ['Concepto de marca y confianza', 'Trato directo, precio claro, lenguaje del criadero y no contable; confirmación visible al guardar.', 'RF-14, RF-15, RF-16, RNF-02, RNF-08'],
        ['Operación diaria del corral', 'Saber qué toca hoy; marcar alimentación y limpieza; anotar los kilos servidos.', 'RF-01 a RF-07'],
        ['Control del hato', 'Listar, buscar y filtrar; dar de alta; ver la ficha; actualizar el peso; dar de baja.', 'RF-10 a RF-13'],
        ['Dinero y costos', 'Registrar ventas y compras; saber cuánto costó criar y si la venta deja ganancia.', 'RF-14 a RF-17'],
        ['Pedidos y clientes', 'Registrar pedidos por canal y avanzar su entrega hasta completarla.', 'RF-19, RF-20'],
        ['Sanidad y veterinario', 'Agendar visitas, registrar atenciones y tener presente la próxima visita.', 'RF-18, RF-24'],
        ['Uso en campo y accesibilidad', 'Usarse de pie, con sol y con guantes; letra que se lea; navegación sin menús ocultos.', 'RNF-04, RNF-05, RNF-10'],
        ['Gestión del proyecto', 'Saber qué sigue, qué se atrasó y qué cambió durante el desarrollo.', 'Capítulo 3 (cronograma) y capítulo 9 (iteraciones)'],
    ], [2300, 4300, 2470]),
    ('h2', '2.4 Prioridades por categoría'),
    ('p', 'Cada categoría recibió una prioridad, una complejidad y una duración estimada, con la fase en la que se atiende. La prioridad alta se asignó a lo que sostiene el uso diario o el dinero; la complejidad se estimó por la cantidad de reglas y de pantallas involucradas.'),
    ('tbl', [
        ['Categoría', 'Prior.', 'Compl.', 'Duración estimada', 'Fase'],
        ['Control del hato', 'Alta', 'Alta', '4 a 5 días', 'Construcción'],
        ['Dinero y costos', 'Alta', 'Alta', '4 días', 'Construcción'],
        ['Pedidos y clientes', 'Alta', 'Media', '2 a 3 días', 'Construcción'],
        ['Operación diaria del corral', 'Alta', 'Media', '2 días', 'Construcción'],
        ['Diseño e identidad visual', 'Alta', 'Media', '4 días', 'Diseño y construcción'],
        ['Concepto de marca y confianza', 'Alta', 'Baja', '2 días', 'Diseño'],
        ['Sanidad y veterinario', 'Media', 'Media', '2 días', 'Construcción'],
        ['Uso en campo y accesibilidad', 'Alta', 'Baja', '3 días', 'Todas las fases'],
        ['Gestión del proyecto', 'Media', 'Baja', '3 días', 'Todas las fases'],
    ], [2500, 850, 950, 1700, 3070]),
    ('p', 'Las duraciones son estimaciones de esfuerzo por categoría y pueden traslaparse entre sí; no se suman para obtener la duración del proyecto. La duración del proyecto se toma del cronograma del capítulo 3.'),
    ('h2', '2.5 Listado de acciones'),
    ('p', 'Cada acción del proyecto tiene un inicio, un fin, una duración, una dependencia y una complejidad. Las tres primeras se ejecutaron antes del cronograma y son el insumo de la Parte 2; las 24 actividades siguientes y la entrega final forman el cronograma de la Fase III y se muestran con las fechas planeadas. Todas las fechas de la tabla son del año 2026.'),
    ('tbl', [
        ['ID', 'Acción', 'Inicio', 'Fin', 'Días', 'Depende de', 'Comp.'],
        ['P-01', 'Indagación del posicionamiento de la empresa', '24 ago', '30 ago', '7', '—', 'Media'],
        ['P-02', 'Minuta con el cliente y clasificación de necesidades', '24 ago', '30 ago', '7', 'P-01', 'Media'],
        ['P-03', 'Carta de conformidad y firmas de la empresa', '3 oct', '3 oct', '1', 'P-02', 'Baja'],
        ['1.1', 'Entrevistas con la titular y el operador', '26 oct', '27 oct', '2', 'P-03', 'Media'],
        ['1.2', 'Revisión de los procesos del criadero', '27 oct', '28 oct', '2', '1.1', 'Media'],
        ['1.3', 'Clasificación de necesidades por módulo', '28 oct', '29 oct', '2', '1.2', 'Baja'],
        ['1.4', 'Priorización y estimación de complejidad', '29 oct', '30 oct', '2', '1.3', 'Baja'],
        ['1.5', 'Listado de requerimientos alcanzables', '30 oct', '1 nov', '3', '1.4', 'Media'],
        ['2.1', 'Requerimientos funcionales por módulo', '2 nov', '3 nov', '2', '1.5', 'Alta'],
        ['2.2', 'Modelo de datos del hato', '3 nov', '4 nov', '2', '2.1', 'Media'],
        ['2.3', 'Diagrama de navegación de la app', '4 nov', '5 nov', '2', '2.2', 'Media'],
        ['2.4', 'Identidad visual y componentes', '5 nov', '6 nov', '2', '2.3', 'Media'],
        ['2.5', 'Documento de diseño de solución', '6 nov', '8 nov', '3', '2.4', 'Alta'],
        ['3.1', 'Proyecto Xcode y modelo SwiftData', '9 nov', '10 nov', '2', '2.5', 'Media'],
        ['3.2', 'Módulo de animales y veterinario', '10 nov', '12 nov', '3', '3.1', 'Alta'],
        ['3.3', 'Módulo de bitácora de alimentación y limpieza', '12 nov', '13 nov', '2', '3.2', 'Media'],
        ['3.4', 'Módulo de costos, ventas y compras', '13 nov', '16 nov', '4', '3.3', 'Alta'],
        ['3.5', 'Módulo de pedidos', '16 nov', '17 nov', '2', '3.4', 'Media'],
        ['3.6', 'Documentación del código y versión', '17 nov', '18 nov', '2', '3.5', 'Baja'],
        ['4.1', 'Pruebas de componente en el simulador', '19 nov', '20 nov', '2', '3.6', 'Media'],
        ['4.2', 'Pruebas de integración entre pestañas', '20 nov', '21 nov', '2', '4.1', 'Media'],
        ['4.3', 'Corrección de defectos detectados', '21 nov', '23 nov', '3', '4.2', 'Media'],
        ['4.4', 'Evidencia: capturas y resultados', '23 nov', '24 nov', '2', '4.3', 'Baja'],
        ['5.1', 'Integración de módulos en una sola app', '25 nov', '26 nov', '2', '4.4', 'Media'],
        ['5.2', 'Validación funcional de extremo a extremo', '26 nov', '27 nov', '2', '5.1', 'Alta'],
        ['5.3', 'Curso LinkedIn Learning y certificado', '27 nov', '28 nov', '2', '5.2', 'Baja'],
        ['5.4', 'Integración de entregables y entrega', '28 nov', '29 nov', '2', '5.3', 'Media'],
        ['E-01', 'Entrega de la Fase III', '30 nov', '30 nov', '1', '5.4', 'Baja'],
    ], [700, 3700, 900, 900, 700, 1150, 1020]),
]

N2 = build(PARTE2)
LAST_P2 = insert_after(LAST_FRONT, N2)

# ---------------------------------------------------------------- 4. cronograma
CAP_P = STUB[2]
# la leyenda del cronograma pasa a ser Figura 1
for t in CAP_P.iter(q('t')):
    if t.text and t.text.startswith('Cronograma de la Fase III'):
        t.text = 'Figura 1. ' + t.text

# ruptura de seccion (retrato) antes del cronograma
sect_p = OxmlElement('w:p')
pPr = OxmlElement('w:pPr')
sp = OxmlElement('w:spacing')
sp.set(q('before'), '0')
sp.set(q('after'), '0')
sp.set(q('line'), '240')
sp.set(q('lineRule'), 'auto')
pPr.append(sp)
pPr.append(copy.deepcopy(SECT))
sect_p.append(pPr)

insert_after(LAST_P2, [sect_p] + STUB)

# el cronograma se amplia al ancho util de la pagina horizontal
Paragraph(IMG_P, doc).alignment = WD_ALIGN_PARAGRAPH.CENTER
for sh in doc.inline_shapes:
    if abs(sh.width.inches - 7.65625) < 0.05:
        ratio = sh.height / sh.width
        sh.width = Inches(9.0)
        sh.height = int(Inches(9.0) * ratio)

# 4.1 y 4.2 en la seccion retrato siguiente
CRONO_EXTRA = [
    ('h2', '3.1 Fases del cronograma'),
    ('p', 'El cronograma organiza el trabajo en cinco fases y una entrega final. La tabla resume, para cada fase, sus fechas, su duración, el número de actividades y el entregable comprometido.'),
    ('tbl', [
        ['Fase', 'Inicio', 'Fin', 'Días', 'Act.', 'Entregable de la fase'],
        ['Análisis de requerimientos', '26 oct', '1 nov', '7', '5', 'Listado de requerimientos posibles y alcanzables'],
        ['Diseño de solución', '2 nov', '8 nov', '7', '5', 'Documento de diseño de solución'],
        ['Construcción', '9 nov', '18 nov', '10', '6', 'Archivos de programación y de diseño editables'],
        ['Pruebas', '19 nov', '24 nov', '6', '4', 'Prototipos y resultados de cada prueba'],
        ['Integración', '25 nov', '29 nov', '5', '4', 'App completa y funcional'],
        ['Entrega', '30 nov', '30 nov', '1', '—', 'Documento integrado de la Fase III'],
    ], [2500, 1300, 1300, 800, 800, 2370]),
    ('h2', '3.2 Seguimiento, interrupciones y ajustes'),
    ('p', 'El cronograma se administra en 01_Cronograma_FaseIII.xlsx. Cada fila declara inicio, fin, duración, estado (Programada, En curso o Concluida) y porcentaje de avance, y cada fase tiene una fila Real que conserva lo que ocurrió, de modo que el plan y la realidad se comparan en la misma hoja. Con esa hoja se registran los avances, las interrupciones y los ajustes del proyecto. Al 30 de octubre de 2026 las fases de análisis y de diseño están concluidas al 100 %, y las de construcción, pruebas e integración están en curso con 83 %, 98 % y 88 % de avance, porque el desarrollo se adelantó a las fechas planeadas.'),
    ('p', 'Los ajustes registrados durante la ejecución son los siguientes.'),
    ('tbl', [
        ['Fecha', 'Interrupción o ajuste', 'Efecto en el plan'],
        ['25 oct', 'El cliente revisa la iteración 1 y responde: “La app no es muy buena.”', 'Se revisa cada pantalla contra su captura y su código, y se prepara una segunda iteración del diseño.'],
        ['26 oct', 'El cliente revisa la iteración 2: “No me termina de gustar nada el diseño: no tiene imágenes de los animales y es cero intuitivo.”', 'Se descarta el diseño y se reconstruye desde cero en cuatro pestañas; se agregan las ilustraciones por raza. El alcance de diseño crece y se compensa con trabajo en paralelo.'],
        ['30 oct', 'La subida de una foto real no se puede probar porque el simulador no tiene fotografías (CP-14).', 'Se documenta como caso no ejecutado y se traslada a pruebas en un iPhone; no bloquea la entrega de la fase.'],
    ], [1100, 4000, 3970]),
]

N4 = build(CRONO_EXTRA)
insert_after(CAP_P, N4)

# ---------------------------------------------------------------- 5. renombres
RENAME = {
    '1. Cronograma de actividades': '3. Cronograma de actividades',
    '2. Listado de requerimientos posibles y alcanzables': '4. Fase I. Análisis de requerimientos',
    '2.1 Introducción': '4.1 Introducción',
    '2.3 Requerimientos funcionales': '4.2 Requerimientos funcionales',
    '2.4 Requerimientos no funcionales': '4.3 Requerimientos no funcionales',
    '2.5 Requerimientos fuera de alcance': '4.4 Requerimientos fuera de alcance',
    '3. Documento de diseño de solución': '5. Fase II. Diseño de solución',
    '3.1 Introducción': '5.1 Introducción',
    '3.2 Arquitectura de la solución': '5.2 Arquitectura de la solución',
    '3.3 Modelo de datos': '5.3 Modelo de datos',
    '3.4 Diagrama de navegación': '5.4 Diagrama de navegación',
    '3.5 Requerimientos de diseño': '5.5 Requerimientos de diseño',
    '3.6 Componentes funcionales': '5.6 Componentes funcionales',
    '4. Archivos de programación y archivos de diseño editables': '6. Fase III. Construcción',
    '4.1 Archivos de programación': '6.1 Archivos de programación',
    '4.2 Archivos de diseño editables': '6.2 Archivos de diseño editables',
    '5. Prototipos y resultados de pruebas': '7. Fase IV. Pruebas',
    '5.1 Introducción': '7.1 Introducción',
    '5.2 Casos de prueba de componente': '7.2 Casos de prueba de componente',
    '5.3 Pruebas de integración': '7.3 Pruebas de integración',
    '5.4 Defectos encontrados y corregidos': '7.4 Defectos encontrados y corregidos',
    '5.5 Evidencia de la iteración 3: diseño vigente': '7.5 Evidencia de la iteración 3: diseño vigente',
    '5.6 Conclusión': '7.6 Conclusión',
    '6. Evolución del diseño y justificación de los cambios': '9. Evolución del diseño y justificación de los cambios',
    '6.1 Introducción': '9.1 Introducción',
    '6.2 Resumen de las iteraciones': '9.2 Resumen de las iteraciones',
    '6.3 Iteración 1: diseño original': '9.3 Iteración 1: diseño original',
    '6.4 Iteración 2: diseño mejorado': '9.4 Iteración 2: diseño mejorado',
    '6.5 Justificación de los cambios solicitados por el cliente': '9.5 Justificación de los cambios solicitados por el cliente',
    '6.6 Qué cambió y qué se conservó': '9.6 Qué cambió y qué se conservó',
    '7. App funcional': '8. Fase V. Integración: app funcional',
    '8. Evidencia del certificado de LinkedIn Learning': '10. Certificado de LinkedIn Learning',
}
renamed = 0
for el in body.iterchildren():
    if el.tag != q('p'):
        continue
    p = Paragraph(el, doc)
    if p.style.name not in ('Heading 1', 'Heading 2'):
        continue
    txt = p.text.strip()
    if txt in RENAME:
        runs = p.runs
        runs[0].text = RENAME[txt]
        for r in runs[1:]:
            r._r.getparent().remove(r._r)
        renamed += 1
assert renamed == len(RENAME), (renamed, len(RENAME))

# ---------------------------------------------------------------- 6. insertos
# 5.1: parrafo de entrada
h51 = find_par('4.1 Introducción', 'Heading 2')._p
h51.addnext(P('Esta fase corresponde al análisis de requerimientos: las entrevistas con la titular y el operador, la revisión de los procesos del criadero y la identificación de oportunidades para la aplicación. El resultado es el listado de requerimientos posibles y alcanzables que se presenta en las secciones siguientes.'))

# 5.5 Entregable
h6 = find_par('5. Fase II. Diseño de solución', 'Heading 1')._p
insert_before(h6, build([
    ('h2', '4.5 Entregable de la fase'),
    ('p', 'El entregable de esta fase es el listado de requerimientos posibles y alcanzables de este capítulo: 24 requerimientos funcionales, 10 no funcionales y 5 fuera de alcance, cada uno con su prioridad, su complejidad y su estado. Se entrega también como documento independiente en 02_Listado_de_Requerimientos.docx.'),
]))

# 6.7 Entregable
h7 = find_par('6. Fase III. Construcción', 'Heading 1')._p
insert_before(h7, build([
    ('h2', '5.7 Entregable de la fase'),
    ('p', 'El entregable de esta fase es este documento de diseño de solución, que integra la arquitectura, el modelo de datos, el diagrama de navegación con la entrada y la salida de cada transición, los requerimientos de diseño y los componentes funcionales. Se entrega también como 03_Diseno_de_Solucion.docx.'),
]))

# 7.3 y 7.4
h8 = find_par('7. Fase IV. Pruebas', 'Heading 1')._p
CODE_LINES = [
    'enum Raza: String, Codable, CaseIterable, Identifiable {',
    '    case comun = "Común"',
    '    case minipig = "Minipig"',
    '    case cruza = "Cruza"',
    '    var id: String { rawValue }',
    '}',
    '',
    '@Model',
    'final class Animal {',
    '    var arete: String = ""',
    '    var razaRaw: String = Raza.comun.rawValue',
    '    var pesoKg: Double = 0',
    '    var destinoRaw: String = Destino.crianza.rawValue',
    '    var fechaAlta: Date = Date()',
    '    var notas: String = ""',
    '    @Attribute(.externalStorage) var foto: Data? = nil',
    '',
    '    var raza: Raza {',
    '        get { Raza(rawValue: razaRaw) ?? .comun }',
    '        set { razaRaw = newValue.rawValue }',
    '    }',
    '    …',
    '}',
]
insert_before(h8, build([
    ('h2', '6.3 Evidencia de código y documentación'),
    ('p', 'El código está organizado por responsabilidad: un archivo por modelo, un archivo por pantalla y dos archivos de componentes reutilizables (Tema.swift y Componentes.swift). Cada archivo abre con comentarios de sección y las decisiones que no son evidentes están documentadas en el propio código; por ejemplo, por qué el precio se elige en cada venta y no se deduce de la raza.'),
    ('p', 'El fragmento siguiente reproduce parte de Modelos.swift, el archivo que define el dominio. Los puntos suspensivos indican líneas omitidas en el documento; el código completo está en el proyecto.'),
    ('code', CODE_LINES),
    ('p', 'La tabla siguiente registra el tamaño y la complejidad de cada componente, y los casos de prueba que lo cubren. Esa relación es la que permite estimar el impacto de una actualización futura.'),
    ('tbl', [
        ['Componente', 'Archivo', 'Líneas', 'Compl.', 'Pruebas que lo cubren'],
        ['Hoy', 'Vistas/VistaHoy.swift', '710', 'Alta', 'CP-01, CP-02'],
        ['Animales', 'Vistas/VistaAnimales.swift', '819', 'Alta', 'CP-03, CP-04, CP-05, CP-13'],
        ['Ficha del animal', 'Vistas/VistaFichaAnimal.swift', '769', 'Alta', 'CP-06, CP-14'],
        ['Dinero', 'Vistas/VistaDinero.swift', '743', 'Alta', 'CP-07, CP-08'],
        ['Compras', 'Vistas/VistaCompras.swift', '705', 'Media', 'CP-11'],
        ['Veterinario', 'Vistas/VistaVeterinario.swift', '596', 'Media', 'CP-12'],
        ['Pedidos', 'Vistas/VistaPedidos.swift', '846', 'Alta', 'CP-09, CP-10'],
        ['Navegación', 'VistaPrincipal.swift', '78', 'Baja', 'PI-01 a PI-05'],
        ['Datos, tema y componentes', 'Modelos, DatosIniciales, Tema y Componentes', '618', 'Media', '—'],
        ['Ilustraciones', 'AvatarCerdo.swift', '147', 'Media', 'CP-13'],
    ], [2000, 2900, 900, 1000, 2270]),
    ('p', 'La versión quedó registrada como 1.0 (build 1). El número de compilación se incrementa con cada entrega y el nombre de la versión cambia solo cuando se agrega un requerimiento nuevo, de modo que el historial de cambios se pueda reconstruir.'),
    ('h2', '6.4 Entregable de la fase'),
    ('p', 'El entregable de esta fase son los archivos de programación (14 archivos Swift, 6,057 líneas) y los archivos de diseño editables: el tema, los componentes y las ilustraciones en código, más las capturas de las tres iteraciones. El proyecto completo, con el esquema FinanzasPorcinas, está en FinanzasPorcinas.xcodeproj.'),
]))

# 8.7 Entregable
h9 = find_par('9. Evolución del diseño', 'Heading 1')._p
insert_before(h9, build([
    ('h2', '7.7 Entregable de la fase'),
    ('p', 'El entregable de esta fase son los prototipos funcionales y el resultado de cada prueba: 13 casos de componente y 5 de integración ejecutados en el simulador, con sus capturas y sus defectos corregidos. Se entregan también como 05_Prototipos_y_Pruebas.docx y 04_Registro_Prueba_CP-13.docx.'),
]))

# 10.1 / 10.2
h10 = find_par('8. Fase V.', 'Heading 1')._p
h10.addnext(H2('8.1 La aplicación integrada'))
p_app = h10.getnext().getnext()
tbl_app = p_app.getnext()
assert tbl_app.tag == q('tbl')
insert_after(tbl_app, build([
    ('h2', '8.2 Entregable de la fase'),
    ('p', 'El entregable de esta fase es la App completa y funcional: los seis módulos integrados en una sola aplicación, con los componentes de cada pantalla conectados a los datos y al servicio local, y con la identidad gráfica del criadero.'),
]))

# ---- figuras con justificacion por fase ----
# Fase I: captura del listado de requerimientos
insert_before(find_par('4.5 Entregable de la fase', 'Heading 2')._p, build([
    ('img', 'Entregables/Capturas/Requerimientos_Listado_p1.png', 5.2),
    ('cap', 'Figura 0. Primera página del listado de requerimientos entregado (02_Listado_de_Requerimientos.docx).'),
    ('p', 'Justificación: esta captura es la evidencia del entregable de la fase; muestra que cada requerimiento queda registrado con su prioridad, su complejidad y su estado, para que el listado sea auditable por la titular del criadero.'),
]))

# Fase II: diagrama de navegacion + referencia a la justificacion del cambio de diseno
insert_before(find_par('5.5 Requerimientos de diseño', 'Heading 2')._p, build([
    ('img', 'Entregables/Capturas/Diagrama_Navegacion.png', 6.2),
    ('cap', 'Figura 0. Diagrama de navegación de la aplicación.'),
    ('p', 'Justificación: el diagrama resume las transiciones de la sección anterior e indica, en cada caso, la entrada y la salida; sirve de plano para construir cada pantalla en la Fase III.'),
]))
insert_before(find_par('5.7 Entregable de la fase', 'Heading 2')._p, build([
    ('p', 'El diseño se iteró tres veces por indicación del cliente; la justificación de cada cambio y las capturas de las iteraciones se documentan en el capítulo 9, una vez terminadas las cinco fases.'),
]))

# Fase III: codigo publicado en GitHub
insert_before(find_par('6.4 Entregable de la fase', 'Heading 2')._p, build([
    ('sub', 'Código publicado en GitHub'),
    ('p', 'El proyecto está versionado y publicado en https://github.com/RMJ4G27020/finanzas-porcinas. Las siguientes capturas, tomadas del repositorio, muestran el código real que se entrega.'),
    ('img', 'Entregables/Capturas/GitHub/gh_repo.png', 5.6),
    ('cap', 'Figura 0. Repositorio finanzas-porcinas en GitHub.'),
    ('p', 'Justificación: demuestra que el código está versionado y disponible para el cliente y la docente, con la estructura de 14 archivos Swift descrita en la sección 6.1.'),
    ('img', 'Entregables/Capturas/GitHub/gh_modelos.png', 4.6),
    ('cap', 'Figura 0. Modelos.swift en GitHub.'),
    ('p', 'Justificación: evidencia el modelo de datos (seis @Model) y las enumeraciones del dominio que implementan los requerimientos RF-08 a RF-17 y RNF-01.'),
    ('img', 'Entregables/Capturas/GitHub/gh_principal.png', 4.6),
    ('cap', 'Figura 0. VistaPrincipal.swift en GitHub.'),
    ('p', 'Justificación: muestra la navegación por pestañas (Hoy, Animales, Dinero y Pedidos) que materializa el requerimiento RNF-06.'),
    ('img', 'Entregables/Capturas/GitHub/gh_hoy.png', 4.6),
    ('cap', 'Figura 0. VistaHoy.swift en GitHub.'),
    ('p', 'Justificación: evidencia la pantalla Hoy, que atiende los requerimientos RF-01 a RF-07 (saludo, tareas del día, atajos y mis cerdos).'),
]))

# Fase IV: justificacion de las capturas del simulador
insert_before(find_par('7.6 Conclusión', 'Heading 2')._p, build([
    ('p', 'Justificación de las imágenes: estas capturas demuestran el cumplimiento de los casos CP-01 a CP-13 en el simulador de iPhone 17 Pro con iOS 26.4; cada una corresponde a una pantalla o a un flujo probado y aprobado en la sección 7.2.'),
]))

# Fase V: captura de la app integrada
insert_after(p_app, build([
    ('img', 'Pruebas/Iteracion3_Rediseno/01_hoy.png', 3.2),
    ('cap', 'Figura 0. Pantalla Hoy de la aplicación integrada.'),
    ('p', 'Justificación: evidencia la App completa y funcional (entregable de la Fase V): una sola aplicación con la identidad gráfica del criadero, ejecutada en el simulador de iPhone.'),
]))

# ---- renumerar figuras en orden ----
def renumber_figures():
    n = 0
    for el in body.iterchildren():
        if el.tag != q('p'):
            continue
        runs = el.findall('.//' + q('t'))
        if not runs:
            continue
        full = ''.join(t.text or '' for t in runs).strip()
        if re.match(r'^Figura\s+\d+\.', full):
            n += 1
            new = re.sub(r'^Figura\s+\d+\.', 'Figura %d.' % n, full, count=1)
            runs[0].text = new
            for t in runs[1:]:
                t.text = ''
# (la renumeracion de figuras se hace al final, tras mover la evolucion)

# las cinco fases quedan consecutivas: la evolucion se mueve despues de la fase V
h_evo = find_par('9. Evolución del diseño', 'Heading 1')._p
h_fasev = find_par('8. Fase V.', 'Heading 1')._p
bloque = []
el = h_evo
while el is not None and el is not h_fasev:
    bloque.append(el)
    el = el.getnext()
assert len(bloque) > 20, len(bloque)
for e in bloque:
    body.remove(e)
h11 = find_par('10. Certificado de LinkedIn Learning', 'Heading 1')._p
for e in bloque:
    h11.addprevious(e)

# 11: fecha del certificado
h11 = find_par('10. Certificado de LinkedIn Learning', 'Heading 1')._p
p_curso = h11.getnext()
insert_after(p_curso, [P('El certificado se emitió a nombre de José Guadalupe Rico Moreno el 25 de octubre de 2026 y se incluye a continuación.')])

# 12 Conclusiones + Referencias, antes del salto de pagina del anexo
h_anexo = find_par('Anexo A.', 'Heading 1')._p
pb = h_anexo.getprevious()
assert pb is not None and pb.findall('.//' + q('br')), 'no se encontro el salto de pagina'
CIERRE = [
    ('h1', '11. Conclusiones y reflexión'),
    ('p', 'La Fase III se cumplió. La aplicación Finanzas Porcinas está construida, probada e integrada: reúne el control del hato, las tareas del día, las compras, las ventas, las visitas del veterinario y los pedidos, en cuatro pestañas que responden a las cuatro preguntas del criadero. Son 14 archivos Swift y 6,057 líneas, con 13 casos de prueba de componente y 5 de integración aprobados, y el certificado del curso de LinkedIn Learning está anexado.'),
    ('p', 'Los siete entregables de la actividad están cubiertos: el cronograma (capítulo 3), el listado de requerimientos (capítulo 4), el documento de diseño (capítulo 5), los archivos de programación y de diseño (capítulo 6), los prototipos y resultados de prueba (capítulo 7), la app funcional (capítulo 8) y la evidencia del certificado (capítulo 10). El plan de acción de la Parte 2 se desarrolló en el capítulo 2 y su ejecución se documenta fase por fase.'),
    ('p', 'Quedan pendientes que no se ocultaron: la subida de una foto real (CP-14) porque el simulador no tiene fotografías, el escalado de toda la letra con el tamaño de texto del sistema (RNF-10), el historial de pesos por animal (RF-21), la ración y la dieta por propósito (RF-22), la conversión del alimento y el costo real por kilogramo (RF-23) y el calendario de sanidad por animal (RF-24). También quedó registrada, sin causa identificada, la observación de que en dos ocasiones un primer toque en un botón no produjo efecto y funcionó al repetirlo.'),
    ('p', 'La reflexión final es que el modelo ágil evolutivo no fue una formalidad: las tres iteraciones cambiaron la aplicación de fondo, y el cliente fue quien decidió qué era intuitivo y qué no. La app no se parece al primer diseño y eso es un resultado, no un fracaso. El siguiente paso es probarla en un iPhone real, en el corral y con guantes, que es el escenario para el que se diseñó.'),
    ('h1', 'Referencias'),
    ('p_left', 'Apple Inc. (s. f.). SwiftUI. https://developer.apple.com/documentation/swiftui'),
    ('p_left', 'Apple Inc. (s. f.). SwiftData. https://developer.apple.com/documentation/swiftdata'),
    ('p_left', 'Apple Education. (s. f.). App Development with Swift. Apple Inc.'),
    ('p_left', 'LinkedIn Learning. (s. f.). Swift 5: Protocol-Oriented Programming. https://www.linkedin.com/learning'),
    ('p_left', 'Universidad Tecmilenio. (2026). Desarrollo de proyecto de aplicaciones móviles. Fase III. Ejecución [actividad de la materia].'),
]
insert_before(pb, build(CIERRE))

# ---- anexos: carta de firmas y formato de pruebas ----
ANEXOS = build([
    ('h1', 'Anexo B. Carta de conformidad y firmas'),
    ('p', 'Carta de conformidad de la Parte 2 del proyecto integrador: manifiesta el interés del Criadero Fam Rico Moreno en integrarse al mercado de soluciones móviles y la aprobación del maestro titular, con los espacios de firma de la empresa, del alumno y del profesor.'),
    ('img', 'Entregables/Capturas/Anexos/AnexoB_Carta_Firmas.png', 6.0),
    ('cap', 'Carta de conformidad y firmas (Parte 2).'),
    ('h1', 'Anexo C. Formato de pruebas — Desarrollo de App en Swift'),
    ('p', 'Formato usado para registrar cada caso de prueba (secciones 1 a 11). Se anexa la plantilla en blanco y, como ejemplo resuelto, el registro de la prueba de componente CP-13.'),
    ('img', 'Entregables/Capturas/Anexos/AnexoC_Formato_Pruebas_p1.png', 6.0),
    ('img', 'Entregables/Capturas/Anexos/AnexoC_Formato_Pruebas_p2.png', 6.0),
    ('cap', 'Formato de pruebas (plantilla), páginas 1 y 2.'),
    ('img', 'Entregables/Capturas/Anexos/AnexoC_CP13_p1.png', 6.0),
    ('img', 'Entregables/Capturas/Anexos/AnexoC_CP13_p2.png', 6.0),
    ('img', 'Entregables/Capturas/Anexos/AnexoC_CP13_p3.png', 6.0),
    ('cap', 'Registro de la prueba CP-13 (ejemplo resuelto), páginas 1 a 3.'),
])
final_sect = list(body.iterchildren())[-1]
assert final_sect.tag == q('sectPr')
for e in ANEXOS:
    final_sect.addprevious(e)
for htxt in ('Anexo B.', 'Anexo C.'):
    hx = find_par(htxt, 'Heading 1')._p
    page_break_before(hx)



# ---------------------------------------------------------------- 7. figuras
FIG = {
    'Figura 1. Capturas de la iteración 3.': 'Figura 2. Capturas de la iteración 3.',
    'Figura 2. Capturas de la iteración 1.': 'Figura 3. Capturas de la iteración 1.',
    'Figura 3. Capturas de la iteración 2.': 'Figura 4. Capturas de la iteración 2.',
}
for el in body.iterchildren():
    if el.tag != q('p'):
        continue
    txt = text_of(el).strip()
    if txt in FIG:
        for t in el.iter(q('t')):
            if t.text and t.text.strip() == txt:
                t.text = FIG[txt]

# referencia cruzada dentro de la tabla de iteraciones
for tbl in doc.tables:
    for row in tbl.rows:
        for c in row.cells:
            if 'capítulos 2, 3 y 5' in c.text:
                for t in c._tc.iter(q('t')):
                    if t.text and 'capítulos 2, 3 y 5' in t.text:
                        t.text = t.text.replace('capítulos 2, 3 y 5', 'capítulos 4, 5 y 7')

# portada: descripcion del entregable
for row in doc.tables[0].rows:
    if row.cells[0].text.strip() == 'Entregable':
        for t in row.cells[1]._tc.iter(q('t')):
            if t.text and t.text.startswith('Entregables de la Fase III'):
                t.text = 'Documento integrado de la Fase III: plan de acción, cinco fases y evidencias'

# ---------------------------------------------------------------- 8. indice
SKIP = {'Índice', 'Titular del criadero', 'Operador del criadero', 'Clientela potencial', 'Decisiones compartidas'}
entries = []
for el in body.iterchildren():
    if el.tag != q('p'):
        continue
    p = Paragraph(el, doc)
    if p.style.name not in ('Heading 1', 'Heading 2'):
        continue
    txt = p.text.strip()
    if not txt or txt in SKIP:
        continue
    entries.append((txt, 1 if p.style.name == 'Heading 1' else 2))

toc_elements = []
num_runs = []
for txt, lvl in entries:
    tmpl = TOC1_T if lvl == 1 else TOC2_T
    p = copy.deepcopy(tmpl)
    pPr = p.find(q('pPr'))
    for s in pPr.findall(q('sectPr')):
        pPr.remove(s)
    strip_runs(p)
    p.append(run(txt, bold=(lvl == 1), size=10.5 if lvl == 1 else 10))
    r2 = OxmlElement('w:r')
    rPr = OxmlElement('w:rPr')
    rf = OxmlElement('w:rFonts')
    for a in ('ascii', 'hAnsi', 'cs', 'eastAsia'):
        rf.set(q(a), 'Arial')
    rPr.append(rf)
    c = OxmlElement('w:color')
    c.set(q('val'), '1E241E')
    rPr.append(c)
    sz = OxmlElement('w:sz')
    sz.set(q('val'), '20')
    rPr.append(sz)
    r2.append(rPr)
    r2.append(OxmlElement('w:tab'))
    t = OxmlElement('w:t')
    t.text = '00'
    r2.append(t)
    p.append(r2)
    toc_elements.append(p)
    num_runs.append(t)

toc_elements[-1].find(q('pPr')).append(SECT)
insert_after(IDX_HEAD, toc_elements)

CHAPTERS = ('2. ', '4. ', '5. ', '6. ', '7. ', '8. ', '9. ', '11. ')
# quitar parrafos vacios que quedaron antes de un capitulo (provocan paginas en blanco)
for el in list(body.iterchildren()):
    if el.tag == q('p'):
        p = Paragraph(el, doc)
        if p.style.name == 'Heading 1' and p.text.strip().startswith(CHAPTERS):
            prev = el.getprevious()
            while (prev is not None and prev.tag == q('p') and not text_of(prev).strip()
                   and prev.find('.//' + q('sectPr')) is None
                   and prev.find('.//' + q('drawing')) is None):
                nxt = prev.getprevious()
                body.remove(prev)
                prev = nxt

for el in body.iterchildren():
    if el.tag == q('p'):
        p = Paragraph(el, doc)
        if p.style.name == 'Heading 1' and p.text.strip().startswith(CHAPTERS):
            page_break_before(el)

renumber_figures()

allowed = {q('p'), q('tbl'), q('sectPr')}
bad = [el.tag for el in body.iterchildren() if el.tag not in allowed]
assert not bad, 'elementos invalidos en el cuerpo: %r' % bad
doc.save(str(OUT))
print('Documento construido: %d entradas de indice, %d parrafos' % (len(toc_elements), len(doc.paragraphs)))

# ---------------------------------------------------------------- 9. paginas
TMP = Path('/tmp/fase3_build')
TMP.mkdir(exist_ok=True)
env = 'file:///tmp/lo_dsh_profile'


def export_pdf(target):
    subprocess.run([
        '/Applications/LibreOffice.app/Contents/MacOS/soffice',
        '-env:UserInstallation=' + env, '--headless', '--convert-to', 'pdf',
        '--outdir', str(target.parent), str(OUT)],
        check=True, capture_output=True, timeout=300)
    return target


pdf_tmp = TMP / (OUT.stem + '.pdf')
export_pdf(pdf_tmp)

txt = subprocess.run(['pdftotext', '-layout', str(pdf_tmp), '-'], capture_output=True, text=True).stdout
pages = txt.split('\f')
if pages and not pages[-1].strip():
    pages.pop()
print('Paginas del PDF:', len(pages))


def norm(s):
    return re.sub(r'\s+', ' ', s).strip()


# primera pagina del cuerpo = donde esta el titulo del capitulo 1
body_start = None
for i, page in enumerate(pages, start=1):
    if any(norm(l) == '1. Introducción' for l in page.splitlines()):
        body_start = i
        break
assert body_start, 'no se encontro el inicio del cuerpo'

missing = []
for (title, lvl), t_el in zip(entries, num_runs):
    target = norm(title)
    page_no = None
    for i in range(body_start, len(pages) + 1):
        lines = [norm(l) for l in pages[i - 1].splitlines()]
        if target in lines:
            page_no = i
            break
    if page_no is None:
        key = target[:34]
        for i in range(body_start, len(pages) + 1):
            if key in norm(pages[i - 1]):
                page_no = i
                break
    if page_no is None:
        missing.append(title)
        page_no = 0
    t_el.text = str(page_no)

print('Sin localizar:', missing)
doc.save(str(OUT))

# export final
export_pdf(PDF_OUT)
print('PDF final:', PDF_OUT)
