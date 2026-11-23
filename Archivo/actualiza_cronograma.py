# -*- coding: utf-8 -*-
"""Actualiza 01_Cronograma_FaseIII.xlsx al 23 de noviembre de 2026 (iteracion 4).
Parte de la copia del 30 de octubre (Archivo/01_Cronograma_FaseIII_2026-10-30.xlsx)."""
import copy
import datetime as dt
from pathlib import Path

import openpyxl
from openpyxl.styles import PatternFill

BASE = Path(__file__).resolve().parent.parent
SRC = BASE / 'Archivo' / '01_Cronograma_FaseIII_2026-10-30.xlsx'
OUT = BASE / 'Entregables' / '01_Cronograma_FaseIII.xlsx'

wb = openpyxl.load_workbook(SRC)
ws = wb.active
MAXC = 43  # AQ
FIRST_DAY_COL = 7  # G = 25 oct


def col_de(fecha):
    base = dt.date(2026, 10, 25)
    return FIRST_DAY_COL + (fecha - base).days


def copiar_estilo(origen, destino):
    destino.font = copy.copy(origen.font)
    destino.fill = copy.copy(origen.fill)
    destino.border = copy.copy(origen.border)
    destino.alignment = copy.copy(origen.alignment)
    destino.number_format = origen.number_format


REF = {k: (copy.copy(ws[c].fill), copy.copy(ws[c].font))
       for k, c in (('Concluida', 'E7'), ('En curso', 'E22'), ('Programada', 'E28'))}

# ---- 1. insertar la actividad 4.5 (se mueve todo desde la fila 36 hacia abajo)
alturas = {r: ws.row_dimensions[r].height for r in range(30, 56)}
ws.move_range('A36:AQ54', rows=1, cols=0, translate=True)
for r in range(54, 35, -1):
    ws.row_dimensions[r + 1].height = alturas.get(r)
ws.row_dimensions[36].height = alturas.get(35)
for c in range(1, MAXC + 1):
    copiar_estilo(ws.cell(35, c), ws.cell(36, c))
ws['A36'] = '4.5 Ajuste final: sin pedidos y fotos reales'
ws['B36'] = dt.datetime(2026, 11, 20)
ws['C36'] = dt.datetime(2026, 11, 23)
ws['D36'] = '=C36-B36+1'
ws['E36'] = 'Concluida'
ws['F36'] = 1
# barras: base igual a la fila en blanco (sabados y domingos) y el plan en azul
BLANCA = 30
for c in range(FIRST_DAY_COL, MAXC + 1):
    ws.cell(36, c).fill = copy.copy(ws.cell(BLANCA, c).fill)
AZUL = copy.copy(ws['I7'].fill)  # actividad programada
for d in range(20, 24):
    ws.cell(36, col_de(dt.date(2026, 11, d))).fill = copy.copy(AZUL)

# ---- 2. estados al 23 de noviembre (filas ya desplazadas)
def estado(fila, texto, avance):
    relleno, fuente = REF[texto]
    ws.cell(fila, 5).value = texto
    ws.cell(fila, 5).fill = copy.copy(relleno)
    ws.cell(fila, 5).font = copy.copy(fuente)
    ws.cell(fila, 6).value = avance


# localizar filas por texto (las posiciones cambiaron desde la 36)
def fila(prefijo, desde=1):
    for r in range(desde, ws.max_row + 1):
        v = ws.cell(r, 1).value
        if isinstance(v, str) and v.startswith(prefijo):
            return r
    raise KeyError(prefijo)


f_constr = fila('Fase de Construcción')
estado(f_constr, 'Concluida', 1)
estado(fila('3.6'), 'Concluida', 1)
estado(fila('5.3'), 'Concluida', 1)
ws.cell(fila('3.5'), 1).value = '3.5 Módulo de pedidos (retirado el 20 nov)'
estado(f_constr + 7, 'Concluida', 1)  # Real de construccion (fila 29)
assert ws.cell(f_constr + 7, 1).value == 'Real'

f_prue = fila('Fase de Pruebas')
estado(f_prue, 'Concluida', 1)
estado(fila('4.1'), 'Concluida', 1)
f_real_prue = fila('4.5') + 1
assert ws.cell(f_real_prue, 1).value == 'Real'
estado(f_real_prue, 'Concluida', 1)
ws.cell(f_real_prue, 3).value = dt.datetime(2026, 11, 23)

f_integ = fila('Fase de Integración')
estado(f_integ, 'En curso', 0.9375)
estado(fila('5.4'), 'En curso', 0.75)
f_real_integ = fila('5.4') + 1
assert ws.cell(f_real_integ, 1).value == 'Real'
estado(f_real_integ, 'En curso', 0.9375)
ws.cell(f_real_integ, 3).value = dt.datetime(2026, 11, 23)

# barras rojas de las filas Real que se extienden hasta el 23 nov
ROJO = copy.copy(ws['H12'].fill)
for f_real, ini in ((f_real_prue, dt.date(2026, 10, 26)), (f_real_integ, dt.date(2026, 10, 30))):
    for c in range(FIRST_DAY_COL, MAXC + 1):
        ws.cell(f_real, c).fill = copy.copy(ws.cell(BLANCA, c).fill)
    for c in range(col_de(ini), col_de(dt.date(2026, 11, 23)) + 1):
        ws.cell(f_real, c).fill = copy.copy(ROJO)

# ---- 3. marcador "Hoy": de la columna L (30 oct) a la AJ (23 nov)
COL_VIEJA, COL_NUEVA = col_de(dt.date(2026, 10, 30)), col_de(dt.date(2026, 11, 23))
MARCA = 'FFFCE4D6'
ultima = fila('Entrega de la Fase III')
for r in range(3, ultima + 1):
    vieja, nueva = ws.cell(r, COL_VIEJA), ws.cell(r, COL_NUEVA)
    if r in (3, 4):  # encabezado: el dia resaltado
        vc, nc = ws.cell(r, COL_VIEJA - 1), ws.cell(r, COL_NUEVA - 1)
        marca_f, marca_font = copy.copy(vieja.fill), copy.copy(vieja.font)
        base_f, base_font = copy.copy(vc.fill), copy.copy(vc.font)
        vieja.fill, vieja.font = base_f, base_font
        nueva.fill, nueva.font = marca_f, marca_font
        continue
    if vieja.fill.fgColor.rgb == MARCA:
        vieja.fill = PatternFill(fill_type=None)
    if nueva.fill.fill_type is None:
        nueva.fill = PatternFill('solid', fgColor=MARCA)

# ---- 4. leyenda y notas
for r in range(ultima + 1, ws.max_row + 1):
    for c in range(1, MAXC + 1):
        v = ws.cell(r, c).value
        if isinstance(v, str) and v.startswith('Hoy:'):
            ws.cell(r, c).value = 'Hoy: 23/11/2026'
        elif isinstance(v, str) and v.startswith('Estado al viernes 30 de octubre'):
            ws.cell(r, c).value = ('Estado al lunes 23 de noviembre de 2026. Análisis, diseño, construcción y pruebas concluidos; '
                                   'integración en curso (falta la encuesta de satisfacción).')
        elif isinstance(v, str) and v.startswith('Completado: curso de LinkedIn'):
            ws.cell(r, c).value = ('El 20/11 se retiró la sección Pedidos y se agregaron fotos reales y la Guía de razas (4.5). '
                                   'LinkedIn Learning completado el 25/10/2026. Falta probar una foto propia en iPhone.')

wb.save(OUT)
print('cronograma actualizado:', OUT)

# ---- 5. impresion en una hoja y imagen PNG
from openpyxl.worksheet.properties import PageSetupProperties
wb = openpyxl.load_workbook(OUT)
ws = wb.active
ws.page_setup.orientation = 'landscape'
ws.page_setup.fitToWidth = 1
ws.page_setup.fitToHeight = 1
ws.sheet_properties.pageSetUpPr = PageSetupProperties(fitToPage=True)
ws.print_area = 'A1:AQ%d' % ws.max_row
ws.page_margins.left = ws.page_margins.right = 0.2
ws.page_margins.top = ws.page_margins.bottom = 0.2
wb.save(OUT)

import subprocess
tmp = BASE / 'Archivo' / '_png_tmp'
tmp.mkdir(exist_ok=True)
subprocess.run(['/Applications/LibreOffice.app/Contents/MacOS/soffice', '-env:UserInstallation=file:///private/tmp/claude-501/lo_prof_ppt',
                '--headless', '--convert-to', 'pdf', '--outdir', str(tmp), str(OUT)], check=True, capture_output=True, timeout=300)
subprocess.run(['pdftoppm', '-r', '200', '-png', '-singlefile', str(tmp / (OUT.stem + '.pdf')), str(tmp / 'crono')], check=True)
from PIL import Image, ImageChops
im = Image.open(tmp / 'crono.png').convert('RGB')
bg = Image.new('RGB', im.size, 'white')
caja = ImageChops.difference(im, bg).getbbox()
im = im.crop((max(caja[0] - 12, 0), max(caja[1] - 12, 0), min(caja[2] + 12, im.width), min(caja[3] + 12, im.height)))
im.save(BASE / 'Entregables' / '01_Cronograma_FaseIII.png', optimize=True)
print('PNG', im.size)
