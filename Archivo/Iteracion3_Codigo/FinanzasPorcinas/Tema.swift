import SwiftUI

/// Tokens visuales del mockup aprobado de Finanzas Porcinas.
enum Tema {
    static let fondo       = Color(red: 0.965, green: 0.949, blue: 0.918) // #F6F2EA
    static let superficie  = Color.white                                   // #FFFFFF
    static let tinta       = Color(red: 0.114, green: 0.106, blue: 0.086) // #1D1B16
    static let secundario  = Color(red: 0.369, green: 0.341, blue: 0.294) // #5E574B
    static let linea       = Color(red: 0.894, green: 0.867, blue: 0.816) // #E4DDD0
    static let verde       = Color(red: 0.184, green: 0.365, blue: 0.275) // #2F5D46
    static let terracota   = Color(red: 0.706, green: 0.325, blue: 0.227) // #B4533A
    static let inactivo    = Color(red: 0.420, green: 0.392, blue: 0.341) // #6B6457

    static let exitoFondo    = Color(red: 0.890, green: 0.937, blue: 0.902) // #E3EFE6
    static let exitoTexto    = Color(red: 0.141, green: 0.325, blue: 0.235) // #24533C
    static let pendienteFondo = Color(red: 0.969, green: 0.902, blue: 0.827) // #F7E6D3
    static let pendienteTexto = Color(red: 0.541, green: 0.294, blue: 0.118) // #8A4B1E
    static let neutroFondo   = Color(red: 0.929, green: 0.906, blue: 0.859) // #EDE7DB
    static let neutroTexto   = Color(red: 0.290, green: 0.267, blue: 0.227) // #4A443A

    static let radioTarjeta: CGFloat = 16
    static let radioControl: CGFloat = 12
}

enum EstiloChip {
    case exito, pendiente, neutro

    var fondo: Color {
        switch self {
        case .exito: return Tema.exitoFondo
        case .pendiente: return Tema.pendienteFondo
        case .neutro: return Tema.neutroFondo
        }
    }
    var texto: Color {
        switch self {
        case .exito: return Tema.exitoTexto
        case .pendiente: return Tema.pendienteTexto
        case .neutro: return Tema.neutroTexto
        }
    }
}

struct Chip: View {
    let texto: String
    var estilo: EstiloChip = .neutro

    var body: some View {
        Text(texto)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(estilo.texto)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(estilo.fondo))
            .accessibilityLabel(texto)
    }
}

struct Tarjeta<Contenido: View>: View {
    @ViewBuilder var contenido: Contenido

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { contenido }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Tema.radioTarjeta)
                    .fill(Tema.superficie)
                    .overlay(
                        RoundedRectangle(cornerRadius: Tema.radioTarjeta)
                            .stroke(Tema.linea, lineWidth: 1)
                    )
            )
    }
}

struct EtiquetaSeccion: View {
    let texto: String

    init(_ texto: String) { self.texto = texto }
    init(texto: String) { self.texto = texto }

    var body: some View {
        Text(texto.uppercased())
            .font(.system(size: 13, weight: .bold))
            .kerning(0.8)
            .foregroundStyle(Tema.secundario)
    }
}

struct TituloPantalla: View {
    let titulo: String
    var subtitulo: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Tema.tinta)
            if let subtitulo {
                Text(subtitulo)
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BotonPrimario: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 14).fill(Tema.verde))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct BotonSecundario: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Tema.verde)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: Tema.radioControl)
                    .fill(Tema.superficie)
                    .overlay(
                        RoundedRectangle(cornerRadius: Tema.radioControl)
                            .stroke(Tema.linea, lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Formato de pesos mexicanos sin decimales: $3,840
func pesos(_ valor: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "MXN"
    f.currencySymbol = "$"
    f.maximumFractionDigits = 0
    f.locale = Locale(identifier: "es_MX")
    return f.string(from: NSNumber(value: valor)) ?? "$0"
}

/// Fecha corta en español: "18 sep"
func fechaCorta(_ fecha: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "es_MX")
    f.dateFormat = "d MMM"
    return f.string(from: fecha)
}

/// Fecha larga en español: "viernes 18 de septiembre"
func fechaLarga(_ fecha: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "es_MX")
    f.dateFormat = "EEEE d 'de' MMMM"
    return f.string(from: fecha).capitalizedPrimera
}

extension String {
    var capitalizedPrimera: String {
        guard let primera = first else { return self }
        return primera.uppercased() + dropFirst()
    }
}
