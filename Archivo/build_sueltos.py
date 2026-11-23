# -*- coding: utf-8 -*-
"""Regenera los documentos sueltos 02, 03 y 05 a partir del documento maestro de la Fase III.

Cada uno conserva la portada, el marco y el formato del maestro y toma de él los capitulos
correspondientes, para que los tres sean siempre iguales al maestro. Correr DESPUES de build_fase3.py.
"""
import copy
import re
import subprocess
import sys
from pathlib import Path

from docx import Document
from docx.oxml.ns import qn
from docx.text.paragraph import Paragraph

sys.path.insert(0, str(Path(__file__).resolve().parent))
from iteracion4 import Editor, set_ptext, ptext  # noqa: E402

BASE = Path(__file__).resolve().parent.parent
MAESTRO = BASE / 'Entregables' / 'Fase_III_Finanzas_Porcinas.docx'
SALIDA = BASE / 'Entregables' / 'Por_separado'
TMP = Path('/tmp/sueltos_build')
TMP.mkdir(exist_ok=True)
ENV = 'file:///tmp/lo_dsh_profile'


def q(t):
    return qn('w:' + t)


def estilo(el):
    pPr = el.find(q('pPr'))
    if pPr is not None and pPr.find(q('pStyle')) is not None:
        return pPr.find(q('pStyle')).get(q('val'))
    return ''


DOCS = [
    dict(archivo='02_Listado_de_Requerimientos.docx',
         titulo='Listado de requerimientos',
         subtitulo='Requerimientos posibles y alcanzables para la aplicación Finanzas Porcinas',
         entregable='Entregable 2 · Fase de Análisis de requerimientos',
         capitulos=[('4. ', 1)],
         subs=[
             ('Se entrega también como documento independiente en 02_Listado_de_Requerimientos.docx.', 'Este documento es el entregable de la fase.'),
             ('de este capítulo:', 'de este documento:'),
             ('se incluye en el Anexo A.', 'se incluye en el Anexo A del documento integrado de la Fase III.'),
         ],
         quitar_figura='Figura 2. Primera página del listado'),
    dict(archivo='03_Diseno_de_Solucion.docx',
         titulo='Documento de diseño de solución',
         subtitulo='Arquitectura, modelo de datos, navegación y diseño de la aplicación Finanzas Porcinas',
         entregable='Entregable 3 · Fase de Diseño de solución',
         capitulos=[('5. ', 1)],
         subs=[
             ('Se entrega también como 03_Diseno_de_Solucion.docx.', 'Este documento es el entregable de la fase.'),
             ('se documentan en el capítulo 9, una vez terminadas las cinco fases.', 'se documentan en el documento 05_Prototipos_y_Pruebas.docx.'),
         ]),
    dict(archivo='05_Prototipos_y_Pruebas.docx',
         titulo='Prototipos y resultados de pruebas',
         subtitulo='Pruebas de componente e integración de la aplicación Finanzas Porcinas',
         entregable='Entregable 5 · Fase de Pruebas',
         capitulos=[('7. ', 1), ('9. ', 2)],
         subs=[
             ('Se entregan también como 05_Prototipos_y_Pruebas.docx y 04_Registro_Prueba_CP-13.docx.',
              'Este documento y los registros de prueba 04_Registro_Prueba_CP-13.docx y 06_Registro_Prueba_CP-15.docx son el entregable de la fase.'),
             ('en la sección 7.2', 'en la sección 1.2'),
             ('Documentado en los capítulos 4, 5 y 7.', 'Documentado en los documentos 02, 03 y 05.'),
             ('Este capítulo conserva', 'La segunda parte de este documento conserva'),
         ]),
]


def norm(s):
    return re.sub(r'\s+', ' ', s).strip()


def construir(cfg):
    doc = Document(str(MAESTRO))
    body = doc.element.body
    els = list(body.iterchildren())
    h1 = [(i, ptext(e).strip()) for i, e in enumerate(els) if e.tag == q('p') and estilo(e) == 'Heading1']
    idx_indice = next(i for i, t in h1 if t == 'Índice')
    primero = next(i for i, t in h1 if t.startswith('1. Introducción'))
    # plantillas del indice (nivel 1 y 2) y salto de seccion del indice
    toc_old = els[idx_indice + 1:primero]
    t1, t2 = copy.deepcopy(toc_old[0]), copy.deepcopy(toc_old[1])
    sect = toc_old[-1].find('.//' + q('sectPr'))
    assert sect is not None
    sect = copy.deepcopy(sect)

    # capitulos a conservar
    bloques = []
    for prefijo, nuevo_num in cfg['capitulos']:
        a = next(i for i, t in h1 if t.startswith(prefijo))
        pos = [i for i, _ in h1 if i > a]
        b = pos[0] if pos else len(els) - 1
        bloques.append((a, b, prefijo.strip().rstrip('.'), nuevo_num))
    conservar = set()
    for a, b, _, _ in bloques:
        conservar.update(range(a, b))
    final_sect = els[-1]
    assert final_sect.tag == q('sectPr')
    for i, e in enumerate(els):
        if i < idx_indice + 1:      # portada + titulo del indice
            continue
        if i in conservar or e is final_sect:
            continue
        body.remove(e)
    for e in toc_old:
        if e.getparent() is not None:
            body.remove(e)

    E = Editor(doc, body)
    # portada
    pars = [p for p in body.iter(q('p'))]
    set_ptext(next(p for p in pars if ptext(p).strip() == 'Fase III. Ejecución'), cfg['titulo'])
    set_ptext(next(p for p in pars if ptext(p).strip().startswith('Aplicación Finanzas Porcinas para el Criadero')), cfg['subtitulo'])
    tabla = next(body.iter(q('tbl')))
    for tr in tabla.findall(q('tr')):
        tcs = tr.findall(q('tc'))
        if ptext(tcs[0]).strip() == 'Entregable':
            set_ptext(tcs[1].find(q('p')), cfg['entregable'])

    # texto
    for viejo, nuevo in cfg['subs']:
        E.sub(viejo, nuevo)
    if cfg.get('quitar_figura'):
        cap = E.find(cfg['quitar_figura'])
        quitar = [cap, cap.getprevious(), cap.getnext()]   # imagen, leyenda y justificacion
        assert quitar[0].findall('.//' + q('drawing')) or True
        for e in quitar:
            e.getparent().remove(e)

    # renumerar capitulos y secciones
    for p in list(body.iter(q('p'))):
        if estilo(p) not in ('Heading1', 'Heading2'):
            continue
        t = ptext(p).strip()
        for _, _, viejo, nuevo in bloques:
            if t.startswith(viejo + '. ') or t.startswith(viejo + '.'):
                set_ptext(p, re.sub(r'^' + re.escape(viejo) + r'(?=[. ])', str(nuevo), t, count=1))
                break
    # figuras en orden
    n = 0
    for p in body.iter(q('p')):
        t = ptext(p).strip()
        if re.match(r'^Figura\s+\d+\.', t):
            n += 1
            set_ptext(p, re.sub(r'^Figura\s+\d+\.', 'Figura %d.' % n, t, count=1))

    # imagenes huerfanas
    usados = set(re.findall(r'r:(?:embed|id|link)="(rId\d+)"', ''.join(
        __import__('lxml.etree', fromlist=['x']).tostring(body, encoding='unicode').split())))
    for rid, rel in list(doc.part.rels.items()):
        if rel.reltype.endswith('/image') and rid not in usados:
            del doc.part.rels[rid]

    # indice nuevo
    entradas = []
    for p in body.iter(q('p')):
        if estilo(p) in ('Heading1', 'Heading2'):
            t = ptext(p).strip()
            if t and t != 'Índice':
                entradas.append((t, 1 if estilo(p) == 'Heading1' else 2))
    anchor = next(p for p in body.iter(q('p')) if estilo(p) == 'Heading1' and ptext(p).strip() == 'Índice')
    nuevas, numeros = [], []
    for t, lvl in entradas:
        el = copy.deepcopy(t1 if lvl == 1 else t2)
        for s in el.iter(q('sectPr')):
            s.getparent().remove(s)
        ts = list(el.iter(q('t')))
        ts[0].text = t
        ts[-1].text = '00'
        for x in ts[1:-1]:
            x.text = ''
        nuevas.append(el)
        numeros.append(ts[-1])
    nuevas[-1].find(q('pPr')).append(sect)
    cur = anchor
    for el in nuevas:
        cur.addnext(el)
        cur = el

    ruta = TMP / cfg['archivo']
    doc.core_properties.title = cfg['titulo']
    doc.save(str(ruta))
    # paginas del indice (se exporta a PDF y se busca cada titulo)
    def pdf():
        subprocess.run(['/Applications/LibreOffice.app/Contents/MacOS/soffice', '-env:UserInstallation=' + ENV, '--headless',
                        '--convert-to', 'pdf', '--outdir', str(TMP), str(ruta)], check=True, capture_output=True, timeout=300)
        txt = subprocess.run(['pdftotext', '-layout', str(TMP / (ruta.stem + '.pdf')), '-'], capture_output=True, text=True).stdout
        pag = txt.split('\f')
        if pag and not pag[-1].strip():
            pag.pop()
        return pag
    pag = pdf()
    primer = entradas[0][0]
    inicio = next(i for i, p in enumerate(pag, 1) if i > 1 and any(norm(l) == norm(primer) for l in p.splitlines()))
    faltan = []
    for (t, _), nodo in zip(entradas, numeros):
        n_ = None
        for i in range(inicio, len(pag) + 1):
            if norm(t) in [norm(l) for l in pag[i - 1].splitlines()]:
                n_ = i
                break
        if n_ is None:
            clave = norm(t)[:34]
            for i in range(inicio, len(pag) + 1):
                if clave in norm(pag[i - 1]):
                    n_ = i
                    break
        if n_ is None:
            faltan.append(t)
            n_ = 0
        nodo.text = str(n_)
    doc2 = Document(str(ruta))
    # el documento ya esta en disco con '00': se rehace con los numeros calculados
    return ruta, entradas, numeros, faltan, doc, len(pag)


def main():
    for cfg in DOCS:
        ruta, entradas, numeros, faltan, doc, npag = construir(cfg)
        doc.save(str(ruta))
        destino = SALIDA / cfg['archivo']
        destino.write_bytes(ruta.read_bytes())
        print(cfg['archivo'], '| paginas:', npag, '| entradas de indice:', len(entradas), '| sin localizar:', faltan)


if __name__ == '__main__':
    main()
