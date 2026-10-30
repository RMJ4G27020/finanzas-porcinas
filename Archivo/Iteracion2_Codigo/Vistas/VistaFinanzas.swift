import SwiftUI

struct VistaFinanzas: View {
    enum Pestana: String, CaseIterable, Identifiable {
        case ventas = "Costos y ventas"
        case compras = "Compras"
        var id: String { rawValue }
    }

    @State private var pestana: Pestana = .ventas

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()
                VStack(spacing: 16) {
                    TituloPantalla(titulo: "Finanzas", subtitulo: subtitulo)
                        .padding(.horizontal, 20)

                    Picker("Sección de finanzas", selection: $pestana) {
                        ForEach(Pestana.allCases) { p in Text(p.rawValue).tag(p) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    switch pestana {
                    case .ventas: VistaCostosVentas()
                    case .compras: VistaCompras()
                    }
                }
                .padding(.top, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var subtitulo: String {
        switch pestana {
        case .ventas: return "Costos y ventas · \(Empresa.titular)"
        case .compras: return "Compras de insumos · \(Empresa.titular)"
        }
    }
}
