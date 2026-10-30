import Foundation
import SwiftData

// MARK: - Enumeraciones del dominio

enum Raza: String, Codable, CaseIterable, Identifiable {
    case comun = "Común"
    case minipig = "Minipig"
    case cruza = "Cruza"
    var id: String { rawValue }
}

enum Sexo: String, Codable, CaseIterable, Identifiable {
    case hembra = "Hembra"
    case macho = "Macho"
    var id: String { rawValue }
}

enum Destino: String, Codable, CaseIterable, Identifiable {
    case crianza = "Crianza"
    case venta = "Venta"
    var id: String { rawValue }
}

enum TipoTarea: String, Codable, CaseIterable, Identifiable {
    case alimentacionManana = "Alimentación · mañana"
    case limpieza = "Limpieza de corrales"
    case alimentacionTarde = "Alimentación · tarde"
    var id: String { rawValue }
    var orden: Int {
        switch self {
        case .alimentacionManana: return 0
        case .limpieza: return 1
        case .alimentacionTarde: return 2
        }
    }
}

enum Canal: String, Codable, CaseIterable, Identifiable {
    case facebook = "Facebook"
    case whatsapp = "WhatsApp"
    var id: String { rawValue }
    var detalle: String {
        switch self {
        case .facebook: return "Cuenta de Virginia"
        case .whatsapp: return "Grupo Col. Constitución"
        }
    }
    var simbolo: String {
        switch self {
        case .facebook: return "globe"
        case .whatsapp: return "bubble.left.and.bubble.right"
        }
    }
}

enum EstadoPedido: String, Codable, CaseIterable, Identifiable {
    case nuevo = "Nuevo"
    case porEntregar = "Por entregar"
    case entregado = "Entregado"
    var id: String { rawValue }
}

/// Precios de venta reales del criadero: $40 o $80 por kilogramo según la raza.
enum PrecioKg: Double, Codable, CaseIterable, Identifiable {
    case cuarenta = 40
    case ochenta = 80
    var id: Double { rawValue }
    var etiqueta: String { "$\(Int(rawValue))" }
}

// MARK: - Modelos persistidos

@Model
final class Animal {
    var arete: String = ""
    var razaRaw: String = Raza.comun.rawValue
    var sexoRaw: String = Sexo.hembra.rawValue
    var pesoKg: Double = 0
    var destinoRaw: String = Destino.crianza.rawValue
    var fechaAlta: Date = Date()
    var notas: String = ""

    init(arete: String, raza: Raza, sexo: Sexo, pesoKg: Double, destino: Destino,
         fechaAlta: Date = Date(), notas: String = "") {
        self.arete = arete
        self.razaRaw = raza.rawValue
        self.sexoRaw = sexo.rawValue
        self.pesoKg = pesoKg
        self.destinoRaw = destino.rawValue
        self.fechaAlta = fechaAlta
        self.notas = notas
    }

    var raza: Raza {
        get { Raza(rawValue: razaRaw) ?? .comun }
        set { razaRaw = newValue.rawValue }
    }
    var sexo: Sexo {
        get { Sexo(rawValue: sexoRaw) ?? .hembra }
        set { sexoRaw = newValue.rawValue }
    }
    var destino: Destino {
        get { Destino(rawValue: destinoRaw) ?? .crianza }
        set { destinoRaw = newValue.rawValue }
    }
    var resumen: String { "\(raza.rawValue) · \(sexo.rawValue) · \(Int(pesoKg)) kg" }
}

@Model
final class Tarea {
    var fecha: Date = Date()
    var tipoRaw: String = TipoTarea.alimentacionManana.rawValue
    var hecha: Bool = false
    var detalle: String = ""
    var responsable: String = "José"
    var kilosAlimento: Double = 0

    init(fecha: Date, tipo: TipoTarea, hecha: Bool, detalle: String,
         responsable: String = "José", kilosAlimento: Double = 0) {
        self.fecha = fecha
        self.tipoRaw = tipo.rawValue
        self.hecha = hecha
        self.detalle = detalle
        self.responsable = responsable
        self.kilosAlimento = kilosAlimento
    }

    var tipo: TipoTarea {
        get { TipoTarea(rawValue: tipoRaw) ?? .alimentacionManana }
        set { tipoRaw = newValue.rawValue }
    }
}

@Model
final class Compra {
    var fecha: Date = Date()
    var concepto: String = ""
    var proveedor: String = ""
    var cantidad: Double = 0
    var unidad: String = "bulto"
    var precioUnitario: Double = 0

    init(fecha: Date, concepto: String, proveedor: String, cantidad: Double,
         unidad: String, precioUnitario: Double) {
        self.fecha = fecha
        self.concepto = concepto
        self.proveedor = proveedor
        self.cantidad = cantidad
        self.unidad = unidad
        self.precioUnitario = precioUnitario
    }

    var total: Double { cantidad * precioUnitario }
    var detalle: String {
        let plural = cantidad == 1 ? unidad : unidad + "s"
        return "\(proveedor) · \(Int(cantidad)) \(plural) × \(pesos(precioUnitario))"
    }
}

@Model
final class Venta {
    var fecha: Date = Date()
    var areteAnimal: String = ""
    var kilos: Double = 0
    var precioPorKg: Double = 40

    init(fecha: Date, areteAnimal: String, kilos: Double, precioPorKg: Double) {
        self.fecha = fecha
        self.areteAnimal = areteAnimal
        self.kilos = kilos
        self.precioPorKg = precioPorKg
    }

    var total: Double { kilos * precioPorKg }
}

@Model
final class VisitaVeterinario {
    var fecha: Date = Date()
    var tipoAtencion: String = ""
    var alcance: String = ""
    var notas: String = ""

    init(fecha: Date, tipoAtencion: String, alcance: String, notas: String = "") {
        self.fecha = fecha
        self.tipoAtencion = tipoAtencion
        self.alcance = alcance
        self.notas = notas
    }
}

@Model
final class Pedido {
    var folio: Int = 0
    var fecha: Date = Date()
    var canalRaw: String = Canal.whatsapp.rawValue
    var kilos: Double = 0
    var precioPorKg: Double = 40
    var estadoRaw: String = EstadoPedido.nuevo.rawValue

    init(folio: Int, fecha: Date, canal: Canal, kilos: Double,
         precioPorKg: Double, estado: EstadoPedido) {
        self.folio = folio
        self.fecha = fecha
        self.canalRaw = canal.rawValue
        self.kilos = kilos
        self.precioPorKg = precioPorKg
        self.estadoRaw = estado.rawValue
    }

    var canal: Canal {
        get { Canal(rawValue: canalRaw) ?? .whatsapp }
        set { canalRaw = newValue.rawValue }
    }
    var estado: EstadoPedido {
        get { EstadoPedido(rawValue: estadoRaw) ?? .nuevo }
        set { estadoRaw = newValue.rawValue }
    }
    var total: Double { kilos * precioPorKg }
    var titulo: String { String(format: "Pedido %03d", folio) }
    var cuenta: String { "\(Int(kilos)) kg × \(pesos(precioPorKg)) = \(pesos(total))" }
    var chip: EstiloChip {
        switch estado {
        case .nuevo: return .pendiente
        case .porEntregar: return .neutro
        case .entregado: return .exito
        }
    }
}

// MARK: - Datos de la empresa

enum Empresa {
    static let nombre = "Criadero Fam Rico Moreno"
    static let titular = "Virginia"
    static let titularCompleto = "Virginia del Carmen Moreno Gallegos"
    static let operador = "José"
    static let veterinario = "Dr. Rafael de Leija Lara"
    static let domicilio = "Constitución, Playa del Carmen 111, Aldama, Tamaulipas"
    static let animalesDeCrianza = 17
    static let puercosParaVentaAlAnio = 12
}
