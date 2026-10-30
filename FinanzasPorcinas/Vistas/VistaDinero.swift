import SwiftUI
import SwiftData
import UIKit

/// Pantalla "Dinero": responde "¿cuánto gano o gasto?".
/// Arriba, acceso a las compras de insumos. Abajo, dos botones: Vender (flujo de venta
/// en tres pasos) e Historial (ventas ya registradas).
struct VistaDinero: View {
    @Environment(\.modelContext) private var contexto

    @Query(sort: [SortDescriptor(\Animal.arete)]) private var animales: [Animal]
    @Query(sort: [SortDescriptor(\Venta.fecha, order: .reverse)]) private var ventas: [Venta]

    // Estado de la pantalla
    @State private var modo: ModoDinero = .vender
    @State private var areteElegido = ""
    @State private var kilosTexto = ""
    @State private var precio: PrecioKg = .cuarenta
    @State private var costoTexto = ""
    @State private var ventaRegistrada: ResumenVenta?
    @State private var contadorVentas = 0
    @State private var irAlInicio = 0
    @FocusState private var campo: CampoDinero?

    @ScaledMetric(relativeTo: .largeTitle) private var tamanoTotal: CGFloat = 44
    @ScaledMetric(relativeTo: .title) private var tamanoCampo: CGFloat = 28

    // MARK: - Tipos privados

    private enum ModoDinero: Hashable { case vender, historial }
    private enum CampoDinero: Hashable { case kilos, costo }
    private enum Ancla: Hashable { case arriba, pasoCerdo, confirmacion }

    /// Kilos con hasta dos decimales y sin ceros sobrantes ("96", "96.5", "96.25").
    private static let formatoKilos: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    private struct ResumenVenta: Equatable {
        let arete: String
        let kilos: Double
        let total: Double
    }

    // MARK: - Datos derivados (se calculan en Swift, no en @Query)

    private var animalesVenta: [Animal] {
        animales.filter { $0.destino == .venta }
    }

    /// El cerdo elegido; si no se ha tocado ninguno, el primero de la fila.
    private var animalElegido: Animal? {
        animalesVenta.first { $0.arete == areteElegido } ?? animalesVenta.first
    }

    private var kilos: Double { numero(kilosTexto) ?? 0 }
    private var total: Double { kilos * precio.rawValue }
    private var costo: Double? {
        guard let valor = numero(costoTexto), valor >= 0 else { return nil }
        return valor
    }
    private var puedeRegistrar: Bool { animalElegido != nil && kilos > 0 }

    private var textoAyuda: String? {
        if animalElegido == nil { return "Primero elige el cerdo que vas a vender." }
        if kilos <= 0 { return "Escribe cuántos kilos pesa para poder registrar la venta." }
        return nil
    }

    private func numero(_ texto: String) -> Double? {
        let limpio = texto
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let valor = Double(limpio), valor.isFinite else { return nil }
        return valor
    }

    private func kilosEnTexto(_ valor: Double) -> String {
        Self.formatoKilos.string(from: NSNumber(value: valor)) ?? "0"
    }

    private func reiniciarKilos() {
        if let animal = animalElegido {
            kilosTexto = kilosEnTexto(animal.pesoKg)
        } else {
            kilosTexto = ""
        }
    }

    // MARK: - Cuerpo

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            TituloPantalla(titulo: "Dinero", subtitulo: "Lo que vendo y lo que compro")
                                .accessibilityAddTraits(.isHeader)
                                .id(Ancla.arriba)

                            enlaceCompras
                            selectorModo

                            if modo == .vender {
                                flujoVenta
                            } else {
                                historial
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: modo) { _, _ in
                        withAnimation { proxy.scrollTo(Ancla.arriba, anchor: .top) }
                    }
                    .onChange(of: irAlInicio) { _, _ in
                        withAnimation { proxy.scrollTo(Ancla.pasoCerdo, anchor: .top) }
                    }
                    .onChange(of: contadorVentas) { _, _ in
                        // Deja a la vista el aviso "Venta registrada" completo.
                        DispatchQueue.main.async {
                            withAnimation { proxy.scrollTo(Ancla.confirmacion, anchor: .center) }
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { campo = nil }
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .onAppear {
                if kilosTexto.isEmpty { reiniciarKilos() }
            }
            .onChange(of: animalElegido?.arete) { _, _ in
                reiniciarKilos()
                costoTexto = "" // el costo de criar es de cada cerdo
                ventaRegistrada = nil
            }
            .onChange(of: kilosTexto) { _, _ in ventaRegistrada = nil }
            .onChange(of: precio) { _, _ in ventaRegistrada = nil }
        }
        .sensoryFeedback(.success, trigger: contadorVentas)
    }

    // MARK: - Acceso a compras

    private var enlaceCompras: some View {
        NavigationLink {
            VistaCompras()
                .navigationTitle("Compras de insumos")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Tema.fondo, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar(.visible, for: .navigationBar)
        } label: {
            Tarjeta {
                HStack(spacing: 14) {
                    Image(systemName: "cart")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Tema.verde)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Tema.exitoFondo))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compras de insumos")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                        Text("Compara precios por proveedor")
                            .font(.system(size: 15))
                            .foregroundStyle(Tema.secundario)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Tema.secundario)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Abre las compras de insumos")
    }

    // MARK: - Control Vender / Historial

    private var selectorModo: some View {
        HStack(spacing: 12) {
            botonModo(.vender, titulo: "Vender", icono: "banknote")
            botonModo(.historial, titulo: "Historial", icono: "clock.arrow.circlepath")
        }
    }

    private func botonModo(_ destino: ModoDinero, titulo: String, icono: String) -> some View {
        let activo = modo == destino
        return Button {
            campo = nil
            modo = destino
        } label: {
            Label {
                Text(titulo).font(.system(size: 18, weight: .bold))
            } icon: {
                Image(systemName: icono).font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(activo ? Color.white : Tema.verde)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(activo ? Tema.verde : Tema.superficie)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(activo ? Tema.verde : Tema.linea, lineWidth: activo ? 0 : 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titulo)
        .accessibilityAddTraits(activo ? .isSelected : [])
    }

    // MARK: - Flujo de venta

    private var flujoVenta: some View {
        VStack(alignment: .leading, spacing: 16) {
            pasoCerdo.id(Ancla.pasoCerdo)
            pasoKilos
            pasoPrecio
            tarjetaResultado
            bloqueCosto
            seccionRegistrar.id(Ancla.confirmacion)
        }
    }

    // Paso 1

    private var pasoCerdo: some View {
        Tarjeta {
            EncabezadoPaso(numero: 1, pregunta: "¿Qué cerdo vendes?")

            if animalesVenta.isEmpty {
                sinCerdosParaVenta
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(animalesVenta) { animal in
                            opcionCerdo(animal)
                        }
                    }
                    .padding(4)
                }
                .padding(.horizontal, -4)
            }
        }
    }

    private var sinCerdosParaVenta: some View {
        VStack(spacing: 10) {
            Image(systemName: "pawprint")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Tema.verde)
                .accessibilityHidden(true)
            Text("No hay cerdos marcados para venta")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .multilineTextAlignment(.center)
            Text("Abre la ficha del cerdo en Animales y cámbialo a Venta.")
                .font(.system(size: 17))
                .foregroundStyle(Tema.secundario)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func opcionCerdo(_ animal: Animal) -> some View {
        let elegido = animal.arete == animalElegido?.arete
        return Button {
            campo = nil
            areteElegido = animal.arete
        } label: {
            VStack(spacing: 6) {
                FotoAnimal(animal: animal, radio: 14)
                    .frame(width: 84, height: 84)
                    .overlay(alignment: .topTrailing) {
                        if elegido {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Tema.verde)
                                .background(Circle().fill(Tema.superficie))
                                .padding(4)
                        }
                    }
                Text(animal.arete)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(kilosEnTexto(animal.pesoKg)) kg")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(width: 108)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(elegido ? Tema.exitoFondo : Tema.superficie)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(elegido ? Tema.verde : Tema.linea, lineWidth: elegido ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(animal.arete), \(kilosEnTexto(animal.pesoKg)) kilos")
        .accessibilityAddTraits(elegido ? [.isButton, .isSelected] : .isButton)
    }

    // Paso 2

    private var pasoKilos: some View {
        Tarjeta {
            EncabezadoPaso(numero: 2, pregunta: "¿Cuántos kilos?")

            campoNumerico(titulo: "Kilos", texto: $kilosTexto, id: .kilos, sufijo: "kg")

            if let animal = animalElegido {
                Text("Este cerdo pesa \(kilosEnTexto(animal.pesoKg)) kg.")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            }
        }
    }

    // Paso 3

    private var pasoPrecio: some View {
        Tarjeta {
            EncabezadoPaso(numero: 3, pregunta: "¿A cómo el kilo?")

            HStack(spacing: 12) {
                ForEach(PrecioKg.allCases) { opcion in
                    botonPrecio(opcion)
                }
            }
        }
    }

    private func botonPrecio(_ opcion: PrecioKg) -> some View {
        let elegido = precio == opcion
        return Button {
            campo = nil
            precio = opcion
        } label: {
            VStack(spacing: 4) {
                Text(opcion.etiqueta)
                    .font(.system(size: 40, weight: .bold))
                Text("por kilo")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(elegido ? Color.white : Tema.tinta)
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(elegido ? Tema.verde : Tema.fondo)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(elegido ? Tema.verde : Tema.linea, lineWidth: elegido ? 3 : 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if elegido {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(opcion.rawValue)) pesos por kilo")
        .accessibilityAddTraits(elegido ? [.isButton, .isSelected] : .isButton)
    }

    // Resultado

    private var tarjetaResultado: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Te pagan")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92))
            Text(pesos(total))
                .font(.system(size: tamanoTotal, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(kilosEnTexto(kilos)) kg × \(pesos(precio.rawValue))")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Tema.radioTarjeta + 4, style: .continuous)
                .fill(Tema.verde)
        )
        .accessibilityElement(children: .combine)
    }

    // Costo de criarlo (opcional)

    private var bloqueCosto: some View {
        Tarjeta {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("¿Cuánto costó criarlo?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Text("Opcional")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            }

            campoNumerico(titulo: "Costo de criarlo en pesos", texto: $costoTexto, id: .costo, prefijo: "$")

            // Sin kilos no hay venta que comparar contra el costo.
            if let costo, kilos > 0 {
                resultadoGanancia(costo: costo)
            }
        }
    }

    private func resultadoGanancia(costo: Double) -> some View {
        let ganancia = (total - costo).rounded()
        let texto: String
        let icono: String
        let color: Color
        if ganancia > 0 {
            texto = "Ganas \(pesos(ganancia))"
            icono = "arrow.up.right.circle.fill"
            color = Tema.verde
        } else if ganancia < 0 {
            texto = "Pierdes \(pesos(abs(ganancia)))"
            icono = "arrow.down.right.circle.fill"
            color = Tema.terracota
        } else {
            texto = "Ni ganas ni pierdes"
            icono = "equal.circle.fill"
            color = Tema.secundario
        }
        return HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 28))
                .accessibilityHidden(true)
            Text(texto)
                .font(.system(size: 28, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // Campo numérico grande, reutilizado en kilos y costo

    private func campoNumerico(titulo: String, texto: Binding<String>, id: CampoDinero,
                               prefijo: String? = nil, sufijo: String? = nil) -> some View {
        let enfocado = campo == id
        return HStack(spacing: 8) {
            if let prefijo {
                Text(prefijo)
                    .font(.system(size: tamanoCampo, weight: .bold))
                    .foregroundStyle(Tema.secundario)
            }
            TextField("0", text: texto)
                .font(.system(size: tamanoCampo, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .keyboardType(.decimalPad)
                .focused($campo, equals: id)
                .accessibilityLabel(titulo)
            if let sufijo {
                Text(sufijo)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Tema.secundario)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                .fill(Tema.fondo)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                .stroke(enfocado ? Tema.verde : Tema.linea, lineWidth: enfocado ? 2.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { campo = id }
    }

    // Registrar

    @ViewBuilder
    private var seccionRegistrar: some View {
        if let resumen = ventaRegistrada {
            confirmacion(resumen)
        } else {
            VStack(spacing: 10) {
                Button {
                    registrarVenta()
                } label: {
                    Label("Registrar venta", systemImage: "checkmark.circle")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(BotonPrimario())
                .disabled(!puedeRegistrar)
                .opacity(puedeRegistrar ? 1 : 0.45)

                if let ayuda = textoAyuda {
                    Label(ayuda, systemImage: "info.circle")
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func confirmacion(_ resumen: ResumenVenta) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Tema.verde)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Venta registrada")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Tema.exitoTexto)
                    Text("\(resumen.arete) · \(kilosEnTexto(resumen.kilos)) kg · \(pesos(resumen.total))")
                        .font(.system(size: 17))
                        .foregroundStyle(Tema.exitoTexto)
                }
            }
            .accessibilityElement(children: .combine)

            Button {
                modo = .historial
            } label: {
                Label("Ver historial", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(BotonPrimario())

            Button {
                ventaRegistrada = nil
                costoTexto = ""
                irAlInicio += 1
            } label: {
                Label("Vender otro cerdo", systemImage: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(BotonSecundario())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                .fill(Tema.exitoFondo)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                .stroke(Tema.verde, lineWidth: 2)
        )
    }

    private func registrarVenta() {
        guard ventaRegistrada == nil, let animal = animalElegido, kilos > 0 else { return }
        campo = nil
        let venta = Venta(fecha: Date(), areteAnimal: animal.arete,
                          kilos: kilos, precioPorKg: precio.rawValue)
        contexto.insert(venta)
        try? contexto.save()
        ventaRegistrada = ResumenVenta(arete: animal.arete, kilos: venta.kilos, total: venta.total)
        contadorVentas += 1
        UIAccessibility.post(notification: .announcement, argument: "Venta registrada")
    }

    // MARK: - Historial

    @ViewBuilder
    private var historial: some View {
        if ventas.isEmpty {
            historialVacio
        } else {
            let porArete = Dictionary(animales.map { ($0.arete, $0) },
                                      uniquingKeysWith: { primero, _ in primero })

            TituloSeccion(texto: "Ventas registradas", icono: "list.bullet.rectangle")

            ForEach(ventas) { venta in
                filaVenta(venta, animal: porArete[venta.areteAnimal])
            }
        }
    }

    private var historialVacio: some View {
        Tarjeta {
            VStack(spacing: 14) {
                Image(systemName: "banknote")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Tema.verde)
                    .accessibilityHidden(true)
                Text("Todavía no has vendido ningún cerdo")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .multilineTextAlignment(.center)
                Text("Cuando registres una venta, aparecerá aquí.")
                    .font(.system(size: 17))
                    .foregroundStyle(Tema.secundario)
                    .multilineTextAlignment(.center)
                Button {
                    modo = .vender
                } label: {
                    Label("Registrar mi primera venta", systemImage: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(BotonPrimario())
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func filaVenta(_ venta: Venta, animal: Animal?) -> some View {
        Tarjeta {
            HStack(spacing: 14) {
                fotoVenta(animal)
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(venta.areteAnimal)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                        .lineLimit(1)
                    Text("\(fechaCorta(venta.fecha)) · \(kilosEnTexto(venta.kilos)) kg × \(pesos(venta.precioPorKg))")
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Text(pesos(venta.total))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(venta.areteAnimal). \(fechaCorta(venta.fecha)). \(kilosEnTexto(venta.kilos)) kilos a \(kilosEnTexto(venta.precioPorKg)) pesos el kilo. Total \(pesos(venta.total)).")
    }

    @ViewBuilder
    private func fotoVenta(_ animal: Animal?) -> some View {
        if let animal {
            FotoAnimal(animal: animal, radio: 12)
        } else {
            AvatarCerdo(raza: .comun)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Encabezado numerado de cada paso

private struct EncabezadoPaso: View {
    let numero: Int
    let pregunta: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(numero)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Tema.verde))
                .accessibilityHidden(true)
            Text(pregunta)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Tema.tinta)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Paso \(numero). \(pregunta)")
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Vista previa

/// Siembra los datos de ejemplo en el contenedor en memoria de la vista previa.
private struct PruebaVistaDinero: View {
    @Environment(\.modelContext) private var contexto

    var body: some View {
        VistaDinero()
            .task { DatosIniciales.sembrarSiHaceFalta(contexto) }
    }
}

#Preview {
    PruebaVistaDinero()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                              VisitaVeterinario.self, Pedido.self], inMemory: true)
}
