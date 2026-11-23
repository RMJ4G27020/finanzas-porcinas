import SwiftUI
import SwiftData

enum Seccion: Hashable {
    case hoy, animales, dinero, pedidos
}

struct VistaPrincipal: View {
    @State private var seleccion: Seccion = VistaPrincipal.pantallaInicial()
    @State private var navegacion = Navegacion()

    init() {
        let apariencia = UITabBarAppearance()
        apariencia.configureWithOpaqueBackground()
        apariencia.backgroundColor = UIColor.white
        UITabBar.appearance().standardAppearance = apariencia
        UITabBar.appearance().scrollEdgeAppearance = apariencia
    }

    /// Permite abrir la app directamente en una pestaña para capturar evidencia de pruebas.
    static func pantallaInicial() -> Seccion {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-pantalla"), i + 1 < args.count else { return .hoy }
        switch args[i + 1] {
        case "animales": return .animales
        case "dinero": return .dinero
        case "pedidos": return .pedidos
        default: return .hoy
        }
    }

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-ficha") {
            PruebaFicha()
        } else {
            pestanas
        }
    }

    private var pestanas: some View {
        TabView(selection: $seleccion) {
            VistaHoy(seleccion: $seleccion)
                .barraEstadoOpaca()
                .tabItem { Label("Hoy", systemImage: "sun.max") }
                .tag(Seccion.hoy)

            VistaAnimales()
                .barraEstadoOpaca()
                .tabItem { Label("Animales", systemImage: "pawprint") }
                .tag(Seccion.animales)

            VistaDinero()
                .barraEstadoOpaca()
                .tabItem { Label("Dinero", systemImage: "banknote") }
                .tag(Seccion.dinero)

            VistaPedidos()
                .barraEstadoOpaca()
                .tabItem { Label("Pedidos", systemImage: "bag") }
                .tag(Seccion.pedidos)
        }
        .tint(Tema.verde)
        .environment(navegacion)
    }
}

/// Solo para capturar evidencia: abre directamente la ficha de un cerdo marcado para venta.
private struct PruebaFicha: View {
    @Query(sort: [SortDescriptor(\Animal.arete)]) private var animales: [Animal]

    var body: some View {
        NavigationStack {
            if let animal = animales.first(where: { $0.destino == .venta }) {
                VistaFichaAnimal(animal: animal)
            }
        }
    }
}
