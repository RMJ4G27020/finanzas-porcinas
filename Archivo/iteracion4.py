# -*- coding: utf-8 -*-
"""
Iteracion 4 (20-23 nov 2026): se quita la seccion Pedidos y se agregan fotos reales
de las razas y la Guia de razas.

Este modulo ajusta el documento ORIGINAL (cuyo contenido describe la iteracion 3) para que
refleje la app vigente. Lo usa build_fase3.py justo despues de abrir el documento.
Los requerimientos y pruebas de Pedidos NO se borran: se marcan como retirados, para
conservar la trazabilidad. Las secciones de diseno que describen el codigo si se corrigen.
"""
import copy
import re
from pathlib import Path

from docx.oxml.ns import qn
from PIL import Image, ImageDraw, ImageFont

XML_SPACE = '{http://www.w3.org/XML/1998/namespace}space'
FECHA_RETIRO = '20 de noviembre de 2026'


# ------------------------------------------------------------------ utilidades
def ptext(el):
    return ''.join(t.text or '' for t in el.iter(qn('w:t')))


def set_ptext(p, texto):
    """Pone el texto en la primera corrida y vacia las demas."""
    ts = list(p.iter(qn('w:t')))
    assert ts, 'parrafo sin texto'
    ts[0].text = texto
    ts[0].set(XML_SPACE, 'preserve')
    for t in ts[1:]:
        t.text = ''


class Editor:
    def __init__(self, doc, body):
        self.doc = doc
        self.body = body
        self.cambios = 0

    def paragraphs(self):
        return list(self.body.iter(qn('w:p')))

    def sub(self, viejo, nuevo, veces=1):
        """Reemplaza `viejo` por `nuevo` en `veces` parrafos (con tablas incluidas)."""
        hechos = 0
        for p in self.paragraphs():
            texto = ptext(p)
            if viejo not in texto:
                continue
            # primero dentro de una sola corrida (conserva el formato)
            hecho = False
            for t in p.iter(qn('w:t')):
                if t.text and viejo in t.text:
                    t.text = t.text.replace(viejo, nuevo)
                    hecho = True
                    break
            if not hecho:
                set_ptext(p, texto.replace(viejo, nuevo))
            hechos += 1
        if veces is not None:
            assert hechos == veces, 'sub(%r): %d parrafos, se esperaban %d' % (viejo[:60], hechos, veces)
        self.cambios += hechos

    def find(self, prefijo, exacto=False):
        for p in self.paragraphs():
            t = ptext(p).strip()
            if (t == prefijo) if exacto else t.startswith(prefijo):
                return p
        raise KeyError(prefijo)

    def drop_between(self, inicio, fin, incluir_vacio_final=False):
        """Quita los elementos del cuerpo desde el parrafo `inicio` hasta el `fin` (inclusive)."""
        a = self.find(inicio)
        b = self.find(fin)
        el = a
        quitar = []
        while True:
            quitar.append(el)
            if el is b:
                break
            el = el.getnext()
            assert el is not None, 'no se llego a %r' % fin
        if incluir_vacio_final:
            sig = b.getnext()
            if sig is not None and sig.tag == qn('w:p') and not ptext(sig).strip():
                quitar.append(sig)
        for e in quitar:
            e.getparent().remove(e)
        self.cambios += len(quitar)

    def drop_one(self, prefijo):
        p = self.find(prefijo)
        p.getparent().remove(p)
        self.cambios += 1

    def retirar(self, etiqueta, nota):
        """Marca un bloque (RF/CP/PI) como retirado: sustituye su linea de estado."""
        lab = self.find(etiqueta, exacto=False)
        el = lab
        while el is not None and ptext(el).strip():
            for t in el.iter(qn('w:t')):
                if t.text and ('Implementado' in t.text or 'Aprobada' in t.text):
                    t.text = t.text.replace('Implementado.', nota).replace('Aprobada.', nota)
                    self.cambios += 1
                    return
            el = el.getnext()
        raise AssertionError('no se encontro el estado de %r' % etiqueta)


def lineas_swift(base):
    """Cuenta las lineas reales de los archivos Swift vigentes."""
    carpeta = Path(base) / 'FinanzasPorcinas'
    out = {}
    for f in list(carpeta.glob('*.swift')) + list((carpeta / 'Vistas').glob('*.swift')):
        n = sum(1 for _ in f.open(encoding='utf-8'))
        rel = f.name if f.parent == carpeta else 'Vistas/' + f.name
        out[rel] = n
    return out


# ------------------------------------------------------------------ edicion
def editar_original(doc, body, base):
    E = Editor(doc, body)
    L = lineas_swift(base)
    total = sum(L.values())
    assert len(L) == 14, len(L)

    # ---- portada: fecha
    E.sub('30 de octubre de 2026 · Entrega de la Fase III: 30 de noviembre de 2026',
          '23 de noviembre de 2026 · Entrega de la Fase III: 30 de noviembre de 2026')

    # ---- capitulo de requerimientos
    E.sub('y el formulario de nuevo pedido.', 'y la Guía de razas.')
    E.retirar('RF-06 ', 'Retirado el ' + FECHA_RETIRO + ' (se quitó la sección de pedidos).')
    E.retirar('RF-19 ', 'Retirado el ' + FECHA_RETIRO + ' (se quitó la sección de pedidos).')
    E.retirar('RF-20 ', 'Retirado el ' + FECHA_RETIRO + ' (se quitó la sección de pedidos).')
    E.sub('RF-08 Ilustración del cerdo por raza', 'RF-08 Imagen del cerdo por raza')
    E.sub('Cada raza (Común, Minipig y Cruza) tiene su propio dibujo, con fondo, orejas y manchas propios, y una etiqueta de raza del mismo tono. Así se reconoce la raza de un vistazo en las pantallas con animales.',
          'Cada raza (Común, Minipig y Cruza) tiene su propia imagen y una etiqueta de raza del mismo tono. Desde la iteración 4 la imagen es una foto real de la raza (RF-25); la ilustración dibujada de la iteración 3 queda como último recurso. Así se reconoce la raza de un vistazo en las pantallas con animales.')
    E.sub('(animales, tareas, compras, ventas, visitas y pedidos) se guarda', '(animales, tareas, compras, ventas y visitas) se guarda')
    E.sub('(filtros, canales, cerrar,', '(filtros, cerrar,')
    E.sub('(totales de venta, pedido y compra, y fecha de la próxima visita) escalan con el tamaño de texto del sistema en Dinero, Pedidos, Compras y Veterinario',
          '(totales de venta y compra, y fecha de la próxima visita) escalan con el tamaño de texto del sistema en Dinero, Compras y Veterinario')
    E.sub('RNF-06 Navegación en cuatro secciones', 'RNF-06 Navegación en tres secciones')
    E.sub('Una barra inferior con Hoy, Animales, Dinero y Pedidos organiza la app por tarea;',
          'Una barra inferior con Hoy, Animales y Dinero organiza la app por tarea;')
    E.sub('3 compras, 4 visitas y 5 pedidos. Con animales', '3 compras y 4 visitas. Con animales')
    E.sub('visita, pedido o tarea, la app muestra', 'visita o tarea, la app muestra')
    E.sub('registrar la primera venta, anotar un pedido o preparar las tareas de hoy', 'registrar la primera venta o preparar las tareas de hoy')
    E.sub('FA-02 Lectura automática de pedidos desde Facebook y WhatsApp', 'FA-02 Pedidos y contacto con clientes por Facebook y WhatsApp')
    E.sub('Razón: los pedidos llegan por la cuenta personal de Virginia y por grupos de WhatsApp de las colonias, y la app no usa internet; por ello se capturan a mano en Nuevo pedido.',
          'Razón: los pedidos llegan por la cuenta personal de Virginia y por grupos de WhatsApp de las colonias, y la app no usa internet. El %s la sección de pedidos se retiró de la aplicación y esos pedidos se atienden fuera de ella.' % FECHA_RETIRO)
    E.sub('Razón: la app solo registra ventas, pedidos y compras;', 'Razón: la app solo registra ventas y compras;')

    # RF nuevos: se clonan las lineas de RF-24
    rf24 = E.find('RF-24 ')
    bloque = [rf24, rf24.getnext(), rf24.getnext().getnext(), rf24.getnext().getnext().getnext()]
    assert not ptext(bloque[3]).strip() and ptext(bloque[2]).startswith('Prioridad'), [ptext(b)[:30] for b in bloque]
    nuevos = [
        ('RF-25 Foto real de la raza',
         'Cuando un animal no tiene foto propia, la lista, la ficha, la selección de cerdo para vender y el historial muestran una foto real de su raza (Común, Minipig o Cruza), tomada de Wikimedia Commons con licencia libre. La ficha indica que es una foto de ejemplo. Si el animal tiene foto propia, esa tiene prioridad.',
         'Prioridad: Alta. Complejidad: Baja. Estado: Implementado.'),
        ('RF-26 Guía de razas',
         'Una pantalla reúne datos del cerdo doméstico y de las razas Común, Minipig y Cruza, con su foto real, datos resumidos de Wikipedia y el crédito de cada foto (autor, licencia y enlace). Se abre desde el atajo Guía de razas de Hoy, el botón Razas de Animales y la tarjeta Sobre la raza de la ficha.',
         'Prioridad: Media. Complejidad: Baja. Estado: Implementado.'),
    ]
    ancla = bloque[3]
    for etiqueta, desc, prio in nuevos:
        copia = [copy.deepcopy(b) for b in bloque]
        set_ptext(copia[0], etiqueta)
        set_ptext(copia[1], desc)
        # la linea de prioridad conserva sus dos corridas (etiqueta y valor)
        ts = list(copia[2].iter(qn('w:t')))
        if len(ts) >= 2:
            ts[0].text = prio.split(' Estado:')[0] + ' '
            ts[1].text = 'Estado: Implementado.'
            for t in ts[2:]:
                t.text = ''
        else:
            set_ptext(copia[2], prio)
        for c in copia:
            ancla.addnext(c)
            ancla = c

    # ---- diseno de solucion
    E.sub('(Hoy, Animales, Dinero y Pedidos) y no por módulos contables', '(Hoy, Animales y Dinero) y no por módulos contables')
    E.sub('sea su foto propia o la ilustración de su raza', 'sea su foto propia o la foto real de su raza')
    E.sub('VistaCompras, VistaVeterinario y VistaPedidos)', 'VistaCompras y VistaVeterinario) y la Guía de razas (VistaGuiaRazas, en GuiaRazas.swift)')
    E.sub('con seis modelos (Animal, Tarea, Compra, Venta, VisitaVeterinario y Pedido)', 'con cinco modelos (Animal, Tarea, Compra, Venta y VisitaVeterinario)')
    E.sub('un TabView de cuatro secciones (Hoy, Animales, Dinero y Pedidos)', 'un TabView de tres secciones (Hoy, Animales y Dinero)')
    E.sub('-pantalla (animales, dinero o pedidos)', '-pantalla (animales o dinero)')
    E.sub('con las banderas abrirAltaAnimal y abrirNuevoPedido. Los atajos de Hoy activan la bandera y cambian de pestaña',
          'con la bandera abrirAltaAnimal. El atajo Agregar cerdo de Hoy activa la bandera y cambia de pestaña')
    E.sub('3 compras, 4 visitas del veterinario y 5 pedidos.', '3 compras y 4 visitas del veterinario.', veces=3)
    # modelo Pedido y enumeraciones Canal / EstadoPedido
    E.drop_between('Pedido. Registra los pedidos', 'Propiedades calculadas: canal, estado, total')
    E.drop_one('- Canal: Facebook')
    E.drop_one('- EstadoPedido: Nuevo')
    E.sub('La persona elige el precio en cada venta o pedido.', 'La persona elige el precio en cada venta.')
    E.sub('Animales (título "Mis cerdos"), Dinero y Pedidos.', 'Animales (título "Mis cerdos") y Dinero.')
    E.sub('Agendar visita, Registrar atención y Nuevo pedido.', 'Agendar visita y Registrar atención.')
    E.sub('toca Hoy, Animales, Dinero o Pedidos en la barra inferior', 'toca Hoy, Animales o Dinero en la barra inferior')
    # transiciones de Pedidos -> transiciones de la Guia de razas
    p297 = E.find('- Hoy → toca el atajo "Nuevo pedido"')
    set_ptext(p297, '- Hoy → toca el atajo "Guía de razas" → Guía de razas | Entrada: ninguna | Salida: pantalla Guía de razas con las tres razas, su foto y el crédito de cada foto')
    p301 = E.find('- Hoy → toca la tarjeta "N pedidos por entregar"')
    set_ptext(p301, '- Animales → toca el botón "Razas" o, en la ficha de un cerdo, la tarjeta "Sobre la raza" → Guía de razas | Entrada: ninguna (desde la ficha, la raza del animal) | Salida: Guía de razas, desplazada a la raza del animal si se llegó desde su ficha')
    E.drop_between('Transiciones desde Pedidos', '- Pedidos → toca un filtro')
    E.sub('la X de cerrar (Registrar compra, Agendar visita, Registrar atención y Nuevo pedido)', 'la X de cerrar (Registrar compra, Agendar visita y Registrar atención)')
    E.sub('atajo "Nuevo pedido", cinta "Venta", botón "Marcar por entregar" y acciones de quitar', 'atajo "Guía de razas", cinta "Venta" y acciones de quitar')
    E.sub('como el icono del canal sin elegir, las barras', 'como las barras')
    E.sub(' El estilo del pedido sale de su estado: Nuevo es pendiente, Por entregar es neutro y Entregado es éxito.', '')
    E.sub('con las banderas abrirAltaAnimal y abrirNuevoPedido.', 'con la bandera abrirAltaAnimal.')
    E.sub(' Pedidos: "¿qué tengo que entregar?".', '')
    E.sub(' "Marcar por entregar", "Registrar compra"', ' "Registrar compra"')
    E.sub(' El botón que avanza un pedido es propio de Pedidos: 52 pt de alto y radio de 14 pt, terracota para "Marcar por entregar" y verde para "Marcar entregado".', '')
    E.sub('en Dinero, Compras, Pedidos y Veterinario un texto breve', 'en Dinero, Compras y Veterinario un texto breve')
    E.sub('Las cifras grandes de Dinero, Pedidos, Compras y Veterinario usan', 'Las cifras grandes de Dinero, Compras y Veterinario usan')
    E.sub('Hoy, Dinero, Compras, Veterinario y Pedidos añaden', 'Hoy, Dinero, Compras y Veterinario añaden')
    E.sub('huella (Animales), billete (Dinero) y bolsa (Pedidos).', 'huella (Animales) y billete (Dinero).')
    E.sub('Luego los atajos Agregar cerdo, Vender y Nuevo pedido.', 'Luego los atajos Agregar cerdo, Vender y Guía de razas.')
    E.sub('Después aparece la tarjeta "N pedidos por entregar" (solo si hay pedidos pendientes), el botón', 'Después aparece el botón')
    E.sub('- Entra: Tarea, Animal y Pedido mediante @Query;', '- Entra: Tarea y Animal mediante @Query;')
    # componente Pedidos -> componente Guia de razas
    p_tit = E.find('Pedidos (Vistas/VistaPedidos.swift)')
    p_mu = p_tit.getnext()
    p_en = p_mu.getnext()
    p_sa = p_en.getnext()
    set_ptext(p_tit, 'Guía de razas (GuiaRazas.swift)')
    set_ptext(p_mu, '- Muestra: título "Guía de razas"; una tarjeta "El cerdo doméstico" con tres datos generales; una tarjeta por raza (Común, Minipig y Cruza) con su foto real, una etiqueta "Foto de ejemplo", su resumen, sus datos, el autor y la licencia de la foto y el enlace "Ver en Wikimedia Commons"; y las fuentes de los textos (Wikipedia, licencia CC BY-SA).')
    set_ptext(p_en, '- Entra: la raza a la que se desplaza la guía, solo cuando se abre desde la ficha de un cerdo; los textos y los créditos están en GuiaRazas.swift y las fotos, en Assets.xcassets.')
    set_ptext(p_sa, '- Sale: ninguna escritura de datos; el enlace "Ver en Wikimedia Commons" abre la página de la foto en el navegador.')

    # ---- archivos de programacion
    E.sub('Consta de 14 archivos Swift y 6,057 líneas.', 'Consta de 14 archivos Swift y {:,} líneas.'.format(total))
    tabla = next(t for t in body.iter(qn('w:tbl')) if 'FinanzasPorcinasApp.swift' in ptext(t))
    filas = tabla.findall(qn('w:tr'))
    plantilla_fila = None
    for tr in list(filas):
        celdas = tr.findall(qn('w:tc'))
        nombre = ptext(celdas[0]).strip()
        if nombre == 'Vistas/VistaPedidos.swift':
            plantilla_fila = copy.deepcopy(tr)
            tr.getparent().remove(tr)
            continue
        if nombre in L:
            set_ptext(celdas[2].find(qn('w:p')), str(L[nombre]))
    ajustes = {
        'FinanzasPorcinasApp.swift': 'Punto de entrada. Crea el almacén local SwiftData con las cinco entidades y siembra los datos iniciales.',
        'VistaPrincipal.swift': 'Barra de pestañas con las tres secciones: Hoy, Animales y Dinero.',
        'Modelos.swift': 'Cinco modelos SwiftData (Animal, Tarea, Compra, Venta, VisitaVeterinario), enumeraciones del dominio y datos de la empresa.',
        'DatosIniciales.swift': 'Datos sembrados al primer arranque: 20 animales, tareas del día, 3 compras y 4 visitas del veterinario.',
        'AvatarCerdo.swift': 'Imagen del cerdo: foto propia del animal, foto real de su raza o, como último recurso, la ilustración dibujada.',
        'Vistas/VistaHoy.swift': 'Pantalla Hoy: saludo, tareas del día, atajos, Mis cerdos y botones de veterinario y días anteriores.',
    }
    for tr in tabla.findall(qn('w:tr')):
        celdas = tr.findall(qn('w:tc'))
        nombre = ptext(celdas[0]).strip()
        if nombre in ajustes:
            set_ptext(celdas[1].find(qn('w:p')), ajustes[nombre])
    nueva = plantilla_fila
    celdas = nueva.findall(qn('w:tc'))
    set_ptext(celdas[0].find(qn('w:p')), 'GuiaRazas.swift')
    set_ptext(celdas[1].find(qn('w:p')), 'Información real de cada raza, foto de ejemplo y crédito de cada foto; pantalla Guía de razas.')
    set_ptext(celdas[2].find(qn('w:p')), str(L['GuiaRazas.swift']))
    # va despues de AvatarCerdo.swift
    for tr in tabla.findall(qn('w:tr')):
        if ptext(tr.findall(qn('w:tc'))[0]).strip() == 'AvatarCerdo.swift':
            tr.addnext(nueva)
            break

    # ---- pruebas
    E.sub('Los casos CP-01 a CP-14 corresponden a esa ejecución.',
          'Los casos CP-01 a CP-14 corresponden a esa ejecución. El %s se retiró la sección de pedidos: CP-09, CP-10 y PI-02 quedan registrados como retirados, y se probó la iteración 4 con el caso CP-15. Las pantallas que cambiaron en la iteración 4 (Hoy, Animales, ficha, Dinero y Compras) se volvieron a recorrer sin diferencias en su comportamiento.' % FECHA_RETIRO)
    for cp in ('CP-09', 'CP-10'):
        E.retirar(cp, 'Retirada el ' + FECHA_RETIRO + ' (se quitó la sección de pedidos; el resultado obtenido corresponde a la iteración 3).')
    E.retirar('CP-13', 'Aprobada (iteración 3; la iteración 4 lo complementa con CP-15).')
    E.retirar('PI-02', 'Retirada el ' + FECHA_RETIRO + ' (se quitó la sección de pedidos; el resultado obtenido corresponde a la iteración 3).')
    E.sub('5.5 Evidencia de la iteración 3: diseño vigente', '5.5 Evidencia de la iteración 3', veces=2)
    E.sub('Las capturas de la iteración 3 corresponden al diseño vigente y se tomaron', 'Las capturas de la iteración 3 corresponden al diseño anterior a la iteración 4 y se tomaron')
    E.drop_between('04_pedidos.png', 'Pantalla Pedidos. Demuestra el avance de tres pasos', incluir_vacio_final=True)
    E.sub('Se ejecutaron 13 casos de prueba de componente y 5 de integración sobre la iteración 3; todos los casos ejecutados resultaron aprobados.',
          'Sobre la iteración 3 se ejecutaron 13 casos de prueba de componente y 5 de integración, todos aprobados. Con la iteración 4 se retiraron CP-09, CP-10 y PI-02 (sección de pedidos) y se ejecutó CP-15, también aprobado; los casos vigentes son 12 de componente y 4 de integración.')

    # caso nuevo CP-15: se clona el bloque de CP-13
    lab13 = E.find('CP-13', exacto=True)
    blq = []
    el = lab13
    while True:
        blq.append(el)
        if not ptext(el).strip() and len(blq) > 1:
            break
        el = el.getnext()
    textos = [
        'CP-15',
        'Módulo: Animales, Ficha del animal, Guía de razas',
        'Qué se prueba: foto real por raza y Guía de razas.',
        'Pasos: abrir Animales; buscar “Minipig”; abrir la ficha de un cerdo; tocar Razas y recorrer la guía.',
        'Resultado esperado: cada cerdo sin foto propia se muestra con la foto real de su raza y la etiqueta “Foto de ejemplo”; la guía muestra los datos de cada raza y el crédito de su foto.',
        'Resultado obtenido: la lista y la ficha mostraron la foto real de Común, Minipig y Cruza; la ficha mostró “Foto de ejemplo de la raza”; la guía mostró cada raza con su resumen, sus datos y el autor, la licencia y el enlace de la foto.',
        'Estado: Aprobada.',
        '',
    ]
    assert len(blq) == len(textos), (len(blq), [ptext(b)[:25] for b in blq])
    # el bloque de CP-14 termina justo antes del encabezado de pruebas de integracion
    h_pi = E.find('5.3 Pruebas de integración')
    for src, txt in zip(blq, textos):
        c = copy.deepcopy(src)
        if txt:
            set_ptext(c, txt)
        else:
            for t in c.iter(qn('w:t')):
                t.text = ''
        h_pi.addprevious(c)

    # ---- evolucion del diseno
    tabla_it = next(t for t in body.iter(qn('w:tbl')) if 'Observación del cliente' in ptext(t) and 'Respuesta' in ptext(t))
    filas_it = tabla_it.findall(qn('w:tr'))
    ult = filas_it[-1]
    c3 = ult.findall(qn('w:tc'))
    set_ptext(c3[3].find(qn('w:p')), 'Sin rechazo registrado; ajustado en la iteración 4.')
    set_ptext(c3[4].find(qn('w:p')), 'Documentado en los capítulos 2, 3 y 5.')
    f4 = copy.deepcopy(ult)
    c4 = f4.findall(qn('w:tc'))
    set_ptext(c4[0].find(qn('w:p')), '4')
    set_ptext(c4[1].find(qn('w:p')), '20 de noviembre de 2026')
    set_ptext(c4[2].find(qn('w:p')), 'Tres pestañas: Hoy, Animales y Dinero, con foto real de cada raza y Guía de razas. Se quitó la sección Pedidos.')
    set_ptext(c4[3].find(qn('w:p')), 'Ajuste final antes de la entrega.')
    set_ptext(c4[4].find(qn('w:p')), 'Diseño vigente. Documentado en 9.7 y 7.6.')
    ult.addnext(f4)
    E.sub('Diseño vigente (iteración 3)', 'Diseño de la iteración 3')
    E.sub('Se conservaron los seis modelos de datos,', 'Se conservaron los seis modelos de datos de la iteración 3,')

    E.sub('El diseño pasó por tres iteraciones. Este capítulo conserva la evidencia de las tres y explica por qué cambió cada una,',
          'El diseño pasó por cuatro iteraciones: tres por observación del cliente y una de ajuste final del alcance. Este capítulo conserva la evidencia de las cuatro y explica por qué cambió cada una,')

    # ---- app funcional
    E.sub('Integra en una sola app los seis módulos: animales, alimentación y limpieza, compras, costos y ventas, veterinario y pedidos, organizados en cuatro pestañas.',
          'Integra en una sola app los cinco módulos que quedan vigentes: animales, alimentación y limpieza, compras, costos y ventas, y veterinario, más la Guía de razas, organizados en tres pestañas: Hoy, Animales y Dinero.')

    # ---- anexo A
    ult_p = E.find('Las siete sesiones con Virginia tienen fecha registrada.')
    nuevo = copy.deepcopy(ult_p)
    set_ptext(nuevo, 'Cambio posterior: el %s se retiró de la aplicación la sección de pedidos. Los acuerdos sobre pedidos de este anexo se conservan como antecedente del levantamiento; los pedidos se atienden fuera de la aplicación, por los mismos canales por los que llegan.' % FECHA_RETIRO)
    ult_p.addnext(nuevo)

    return E, L, total


# ------------------------------------------------------------------ montajes
def _fuente(tam):
    for ruta in ('/System/Library/Fonts/Helvetica.ttc', '/System/Library/Fonts/Supplemental/Arial.ttf',
                 '/Library/Fonts/Arial.ttf'):
        try:
            return ImageFont.truetype(ruta, tam)
        except OSError:
            continue
    return ImageFont.load_default()


def montaje(base, archivos, etiquetas, salida, ancho_tel=520):
    """Une capturas verticales de iPhone en una sola imagen, con una etiqueta bajo cada una."""
    base = Path(base)
    ims = []
    for f in archivos:
        im = Image.open(base / f).convert('RGB')
        h = round(im.height * ancho_tel / im.width)
        ims.append(im.resize((ancho_tel, h), Image.LANCZOS))
    sep, mar, alto_et = 28, 20, 64
    W = mar * 2 + ancho_tel * len(ims) + sep * (len(ims) - 1)
    H = mar * 2 + max(i.height for i in ims) + alto_et
    lienzo = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(lienzo)
    fuente = _fuente(30)
    for i, (im, et) in enumerate(zip(ims, etiquetas)):
        x = mar + i * (ancho_tel + sep)
        lienzo.paste(im, (x, mar))
        d.rectangle((x, mar, x + ancho_tel - 1, mar + im.height - 1), outline=(195, 205, 193), width=2)
        bbox = d.textbbox((0, 0), et, font=fuente)
        d.text((x + (ancho_tel - (bbox[2] - bbox[0])) / 2, mar + im.height + 14), et, fill=(30, 36, 30), font=fuente)
    out = base / salida
    out.parent.mkdir(parents=True, exist_ok=True)
    lienzo.save(out, optimize=True)
    return out
