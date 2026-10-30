import SwiftUI
import SwiftData

@main
struct FinanzasPorcinasApp: App {
    let contenedor: ModelContainer

    init() {
        do {
            contenedor = try ModelContainer(
                for: Animal.self, Tarea.self, Compra.self, Venta.self,
                     VisitaVeterinario.self, Pedido.self
            )
            DatosIniciales.sembrarSiHaceFalta(ModelContext(contenedor))
        } catch {
            fatalError("No se pudo crear el almacén local: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            VistaPrincipal()
        }
        .modelContainer(contenedor)
    }
}
