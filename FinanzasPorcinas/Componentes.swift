import SwiftUI
import Observation

/// Botón grande de acción con icono: se entiende de un vistazo y se toca fácil con guantes.
struct AccionRapida: View {
    let icono: String
    let titulo: String
    var color: Color = Tema.verde
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            VStack(spacing: 8) {
                Image(systemName: icono)
                    .font(.system(size: 28, weight: .semibold))
                    .accessibilityHidden(true)
                Text(titulo)
                    .font(.system(size: 15, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 92)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(color))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titulo)
    }
}

/// Barra de progreso con texto, para "2 de 3 tareas hechas".
struct BarraProgreso: View {
    let hechas: Int
    let total: Int

    private var fraccion: Double { total == 0 ? 0 : Double(hechas) / Double(total) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(total > 0 && hechas == total ? "¡Todo listo por hoy!" : "\(hechas) de \(total) tareas hechas")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Tema.tinta)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Tema.neutroFondo)
                    Capsule().fill(Tema.verde).frame(width: g.size.width * fraccion)
                }
            }
            .frame(height: 10)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Etiqueta de raza con el color de su ilustración.
struct ChipRaza: View {
    let raza: Raza

    private var colores: (fondo: Color, texto: Color) {
        switch raza {
        case .comun:   return (Tema.exitoFondo, Tema.exitoTexto)
        case .minipig: return (Tema.pendienteFondo, Tema.pendienteTexto)
        case .cruza:   return (Color(red: 0.86, green: 0.89, blue: 0.96), Color(red: 0.20, green: 0.27, blue: 0.45))
        }
    }

    var body: some View {
        Text(raza.rawValue)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(colores.texto)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(colores.fondo))
    }
}

/// Título de sección con icono, para separar bloques sin etiquetas en mayúsculas.
struct TituloSeccion: View {
    let texto: String
    var icono: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icono {
                Image(systemName: icono).foregroundStyle(Tema.verde).accessibilityHidden(true)
            }
            Text(texto)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Tema.tinta)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}


/// Permite que un atajo de Hoy abra directamente un formulario en otra pestaña.
@Observable
final class Navegacion {
    var abrirAltaAnimal = false
    var abrirNuevoPedido = false
}

extension View {
    /// Evita que el contenido pase por debajo de la hora y la batería al desplazarse.
    func barraEstadoOpaca() -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            Color.clear
                .frame(height: 0)
                .background { Tema.fondo.ignoresSafeArea(edges: .top) }
        }
    }
}
