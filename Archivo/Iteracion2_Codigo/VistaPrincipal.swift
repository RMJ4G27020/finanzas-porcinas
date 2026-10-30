import SwiftUI

enum Seccion: Hashable {
    case inicio, animales, bitacora, finanzas, pedidos
}

struct VistaPrincipal: View {
    @State private var seleccion: Seccion = VistaPrincipal.pantallaInicial()

    /// Permite abrir la app directamente en una pestaña para capturar evidencia de pruebas.
    static func pantallaInicial() -> Seccion {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-pantalla"), i + 1 < args.count else { return .inicio }
        switch args[i + 1] {
        case "animales": return .animales
        case "bitacora": return .bitacora
        case "finanzas": return .finanzas
        case "pedidos": return .pedidos
        default: return .inicio
        }
    }

    init() {
        let apariencia = UITabBarAppearance()
        apariencia.configureWithOpaqueBackground()
        apariencia.backgroundColor = UIColor.white
        UITabBar.appearance().standardAppearance = apariencia
        UITabBar.appearance().scrollEdgeAppearance = apariencia
    }

    var body: some View {
        TabView(selection: $seleccion) {
            VistaInicio(seleccion: $seleccion)
                .tabItem { Label("Inicio", systemImage: "house") }
                .tag(Seccion.inicio)

            VistaAnimales()
                .tabItem { Label("Animales", systemImage: "tag") }
                .tag(Seccion.animales)

            VistaBitacora()
                .tabItem { Label("Bitácora", systemImage: "list.clipboard") }
                .tag(Seccion.bitacora)

            VistaFinanzas()
                .tabItem { Label("Finanzas", systemImage: "creditcard") }
                .tag(Seccion.finanzas)

            VistaPedidos()
                .tabItem { Label("Pedidos", systemImage: "bag") }
                .tag(Seccion.pedidos)
        }
        .tint(Tema.verde)
    }
}
