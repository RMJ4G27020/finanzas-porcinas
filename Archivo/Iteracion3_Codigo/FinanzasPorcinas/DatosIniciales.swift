import Foundation
import SwiftData

/// Siembra el hato y los registros de ejemplo la primera vez que se abre la app.
enum DatosIniciales {

    static func sembrarSiHaceFalta(_ contexto: ModelContext) {
        let existentes = (try? contexto.fetchCount(FetchDescriptor<Animal>())) ?? 0
        guard existentes == 0 else { return }

        for animal in animales() { contexto.insert(animal) }
        for tarea in tareasDeHoy() { contexto.insert(tarea) }
        for compra in compras() { contexto.insert(compra) }
        for visita in visitas() { contexto.insert(visita) }
        for pedido in pedidos() { contexto.insert(pedido) }
        try? contexto.save()
    }

    static func dia(_ anio: Int, _ mes: Int, _ dia: Int) -> Date {
        var c = DateComponents()
        c.year = anio; c.month = mes; c.day = dia; c.hour = 9
        return Calendar(identifier: .gregorian).date(from: c) ?? Date()
    }

    /// Hato de ejemplo: 7 animales con nombre, raza, sexo, peso y destino.
    static func animales() -> [Animal] {
        [
            Animal(arete: "Cerdo 01", raza: .comun,   sexo: .hembra, pesoKg: 142, destino: .crianza),
            Animal(arete: "Cerdo 02", raza: .minipig, sexo: .macho,  pesoKg: 58,  destino: .crianza),
            Animal(arete: "Cerdo 03", raza: .cruza,   sexo: .hembra, pesoKg: 96,  destino: .venta),
            Animal(arete: "Cerdo 04", raza: .comun,   sexo: .macho,  pesoKg: 181, destino: .crianza),
            Animal(arete: "Cerdo 05", raza: .cruza,   sexo: .macho,  pesoKg: 88,  destino: .venta),
            Animal(arete: "Cerdo 06", raza: .minipig, sexo: .hembra, pesoKg: 49,  destino: .crianza),
            Animal(arete: "Cerdo 07", raza: .comun,   sexo: .hembra, pesoKg: 101, destino: .venta),
            Animal(arete: "Cerdo 08", raza: .comun,   sexo: .hembra, pesoKg: 134, destino: .crianza),
            Animal(arete: "Cerdo 09", raza: .cruza,   sexo: .hembra, pesoKg: 118, destino: .crianza),
            Animal(arete: "Cerdo 10", raza: .minipig, sexo: .macho,  pesoKg: 52,  destino: .crianza),
            Animal(arete: "Cerdo 11", raza: .comun,   sexo: .macho,  pesoKg: 167, destino: .crianza),
            Animal(arete: "Cerdo 12", raza: .cruza,   sexo: .hembra, pesoKg: 109, destino: .crianza),
            Animal(arete: "Cerdo 13", raza: .comun,   sexo: .hembra, pesoKg: 125, destino: .crianza),
            Animal(arete: "Cerdo 14", raza: .minipig, sexo: .hembra, pesoKg: 46,  destino: .crianza),
            Animal(arete: "Cerdo 15", raza: .cruza,   sexo: .macho,  pesoKg: 94,  destino: .crianza),
            Animal(arete: "Cerdo 16", raza: .comun,   sexo: .hembra, pesoKg: 151, destino: .crianza),
            Animal(arete: "Cerdo 17", raza: .comun,   sexo: .macho,  pesoKg: 173, destino: .crianza),
            Animal(arete: "Cerdo 18", raza: .minipig, sexo: .hembra, pesoKg: 55,  destino: .crianza),
            Animal(arete: "Cerdo 19", raza: .cruza,   sexo: .hembra, pesoKg: 112, destino: .crianza),
            Animal(arete: "Cerdo 20", raza: .comun,   sexo: .hembra, pesoKg: 139, destino: .crianza),
        ]
    }

    static func tareasDeHoy() -> [Tarea] {
        let hoy = Calendar.current.startOfDay(for: Date())
        return [
            Tarea(fecha: hoy, tipo: .alimentacionManana, hecha: true,  detalle: "7:30 · José"),
            Tarea(fecha: hoy, tipo: .limpieza,           hecha: true,  detalle: "8:15 · José"),
            Tarea(fecha: hoy, tipo: .alimentacionTarde,  hecha: false, detalle: "Pendiente"),
        ]
    }

    static func compras() -> [Compra] {
        [
            Compra(fecha: dia(2026, 9, 15), concepto: "Alimento",      proveedor: "Proveedor B", cantidad: 4, unidad: "bulto", precioUnitario: 485),
            Compra(fecha: dia(2026, 9, 8),  concepto: "Alimento",      proveedor: "Proveedor A", cantidad: 3, unidad: "bulto", precioUnitario: 520),
            Compra(fecha: dia(2026, 8, 25), concepto: "Desparasitante", proveedor: "Proveedor C", cantidad: 1, unidad: "pieza", precioUnitario: 180),
        ]
    }

    static func visitas() -> [VisitaVeterinario] {
        [
            VisitaVeterinario(fecha: dia(2026, 9, 14), tipoAtencion: "Revisión general",       alcance: "Todos los animales"),
            VisitaVeterinario(fecha: dia(2026, 9, 2),  tipoAtencion: "Aplicación de vitaminas", alcance: "Cerdo 02"),
            VisitaVeterinario(fecha: dia(2026, 8, 26), tipoAtencion: "Desparasitación",         alcance: "Todos los animales"),
            VisitaVeterinario(fecha: dia(2026, 8, 11), tipoAtencion: "Revisión de patas",       alcance: "Cerdo 04"),
        ]
    }

    static func pedidos() -> [Pedido] {
        [
            Pedido(folio: 14, fecha: dia(2026, 9, 18), canal: .whatsapp, kilos: 5,  precioPorKg: 40, estado: .nuevo),
            Pedido(folio: 13, fecha: dia(2026, 9, 17), canal: .facebook, kilos: 10, precioPorKg: 40, estado: .porEntregar),
            Pedido(folio: 12, fecha: dia(2026, 9, 16), canal: .whatsapp, kilos: 3,  precioPorKg: 80, estado: .porEntregar),
            Pedido(folio: 11, fecha: dia(2026, 9, 12), canal: .facebook, kilos: 8,  precioPorKg: 80, estado: .entregado),
            Pedido(folio: 10, fecha: dia(2026, 9, 9),  canal: .whatsapp, kilos: 12, precioPorKg: 40, estado: .entregado),
        ]
    }
}
