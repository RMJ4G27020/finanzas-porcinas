import SwiftUI
import UIKit

/// Ilustración de un cerdo según su raza. Si el animal tiene foto propia, se muestra la foto.
struct AvatarCerdo: View {
    let raza: Raza
    var foto: Data? = nil

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack {
                fondo
                if let foto, let imagen = UIImage(data: foto) {
                    Image(uiImage: imagen)
                        .resizable()
                        .scaledToFill()
                        .frame(width: g.size.width, height: g.size.height)
                        .clipped()
                } else {
                    cerdo(s)
                        .position(x: g.size.width / 2, y: g.size.height * 0.54)
                }
            }
            .frame(width: g.size.width, height: g.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    // MARK: Paleta por raza

    private var fondo: Color {
        switch raza {
        case .comun:   return Color(red: 0.84, green: 0.92, blue: 0.86)
        case .minipig: return Color(red: 0.98, green: 0.90, blue: 0.78)
        case .cruza:   return Color(red: 0.86, green: 0.89, blue: 0.96)
        }
    }
    private var piel: Color {
        switch raza {
        case .comun, .cruza: return Color(red: 0.96, green: 0.71, blue: 0.69)
        case .minipig:       return Color(red: 0.99, green: 0.96, blue: 0.90)
        }
    }
    private var oreja: Color {
        switch raza {
        case .comun:   return Color(red: 0.91, green: 0.60, blue: 0.60)
        case .minipig: return Color(red: 0.29, green: 0.25, blue: 0.23)
        case .cruza:   return Color(red: 0.73, green: 0.53, blue: 0.40)
        }
    }
    private var mancha: Color {
        switch raza {
        case .comun:   return .clear
        case .minipig: return Color(red: 0.29, green: 0.25, blue: 0.23)
        case .cruza:   return Color(red: 0.73, green: 0.53, blue: 0.40)
        }
    }
    private let hocico = Color(red: 0.98, green: 0.80, blue: 0.77)
    private let narina = Color(red: 0.76, green: 0.45, blue: 0.45)
    private let tinta = Color(red: 0.14, green: 0.12, blue: 0.11)

    // MARK: Dibujo

    private func cerdo(_ s: CGFloat) -> some View {
        let orejaCaida = raza != .minipig
        return ZStack {
            // Orejas
            Group {
                Ellipse().fill(oreja)
                    .frame(width: 0.30 * s, height: orejaCaida ? 0.34 * s : 0.40 * s)
                    .rotationEffect(.degrees(orejaCaida ? -32 : -14))
                    .offset(x: -0.31 * s, y: orejaCaida ? -0.22 * s : -0.30 * s)
                Ellipse().fill(oreja)
                    .frame(width: 0.30 * s, height: orejaCaida ? 0.34 * s : 0.40 * s)
                    .rotationEffect(.degrees(orejaCaida ? 32 : 14))
                    .offset(x: 0.31 * s, y: orejaCaida ? -0.22 * s : -0.30 * s)
            }
            // Cabeza con manchas recortadas a su forma
            ZStack {
                Ellipse().fill(piel)
                if raza == .minipig {
                    Ellipse().fill(mancha).frame(width: 0.34 * s, height: 0.30 * s)
                        .offset(x: -0.22 * s, y: -0.10 * s)
                }
                if raza == .cruza {
                    Ellipse().fill(mancha).frame(width: 0.36 * s, height: 0.30 * s)
                        .offset(x: 0.20 * s, y: -0.16 * s)
                }
            }
            .frame(width: 0.78 * s, height: 0.70 * s)
            .clipShape(Ellipse())
            .offset(y: 0.02 * s)

            // Mejillas
            Group {
                Circle().fill(Color(red: 0.95, green: 0.50, blue: 0.52).opacity(0.35))
                    .frame(width: 0.12 * s).offset(x: -0.27 * s, y: 0.10 * s)
                Circle().fill(Color(red: 0.95, green: 0.50, blue: 0.52).opacity(0.35))
                    .frame(width: 0.12 * s).offset(x: 0.27 * s, y: 0.10 * s)
            }

            // Hocico
            Ellipse().fill(hocico)
                .frame(width: 0.36 * s, height: 0.25 * s)
                .offset(y: 0.14 * s)
            Ellipse().fill(narina)
                .frame(width: 0.05 * s, height: 0.08 * s)
                .offset(x: -0.07 * s, y: 0.14 * s)
            Ellipse().fill(narina)
                .frame(width: 0.05 * s, height: 0.08 * s)
                .offset(x: 0.07 * s, y: 0.14 * s)

            // Ojos
            Group {
                Circle().fill(tinta).frame(width: 0.075 * s).offset(x: -0.16 * s, y: -0.07 * s)
                Circle().fill(.white).frame(width: 0.024 * s).offset(x: -0.145 * s, y: -0.085 * s)
                Circle().fill(tinta).frame(width: 0.075 * s).offset(x: 0.16 * s, y: -0.07 * s)
                Circle().fill(.white).frame(width: 0.024 * s).offset(x: 0.175 * s, y: -0.085 * s)
            }
        }
        .frame(width: s, height: s)
    }
}

/// Avatar con esquinas redondeadas, para tarjetas y listas.
struct FotoAnimal: View {
    let animal: Animal
    var radio: CGFloat = 16

    var body: some View {
        AvatarCerdo(raza: animal.raza, foto: animal.foto)
            .clipShape(RoundedRectangle(cornerRadius: radio, style: .continuous))
            .accessibilityLabel("Foto de \(animal.arete)")
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(Raza.allCases) { r in
            AvatarCerdo(raza: r).frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    .padding()
}
