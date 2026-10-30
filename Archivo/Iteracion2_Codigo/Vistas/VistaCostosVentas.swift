import SwiftUI
import SwiftData

/// Calculadora de venta por kilogramo y registro de ventas del criadero.
/// Se muestra dentro de VistaFinanzas, que ya pone el título y el selector.
struct VistaCostosVentas: View {

    @Environment(\.modelContext) private var contexto

    @Query(sort: [SortDescriptor(\Animal.arete)]) private var animales: [Animal]
    @Query(sort: [SortDescriptor(\Venta.fecha, order: .reverse)]) private var ventas: [Venta]

    @State private var areteSeleccionado: String = ""
    @State private var kilosTexto: String = ""
    @State private var precio: PrecioKg = .cuarenta
    @State private var costoTexto: String = ""
    @State private var confirmacion: String = ""
    @State private var marcaConfirmacion: UUID = UUID()

    private enum Campo: Hashable { case kilos, costo }
    @FocusState private var campoActivo: Campo?

    // MARK: - Datos derivados

    /// Solo los animales cuyo destino es la venta.
    private var animalesEnVenta: [Animal] {
        animales.filter { $0.destino == .venta }
    }

    private var animalSeleccionado: Animal? {
        animalesEnVenta.first { $0.arete == areteSeleccionado }
    }

    private var kilos: Double {
        VistaCostosVentas.numero(kilosTexto) ?? 0
    }

    private var costo: Double? {
        VistaCostosVentas.numero(costoTexto)
    }

    /// Ingreso de la venta: kilos × precio por kilogramo.
    private var ingreso: Double {
        kilos * precio.rawValue
    }

    private var puedeRegistrar: Bool {
        animalSeleccionado != nil && kilos > 0
    }

    // MARK: - Cuerpo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                tarjetaCalculo
                tarjetaCosto
                bloqueRegistro
                bloqueVentas
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 96)
        }
        .background(Tema.fondo.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { campoActivo = nil }
            }
        }
        .onAppear { sincronizarSeleccion() }
        .onChange(of: animalesEnVenta.count) { _, _ in sincronizarSeleccion() }
        .onChange(of: areteSeleccionado) { _, nuevo in
            // Al cambiar de animal, los kilos se reinician al peso de ese animal.
            if let animal = animalesEnVenta.first(where: { $0.arete == nuevo }) {
                kilosTexto = String(Int(animal.pesoKg))
            }
        }
    }

    // MARK: - 1. Calcular venta

    private var tarjetaCalculo: some View {
        Tarjeta {
            Text("Calcular venta")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Tema.tinta)

            if animalesEnVenta.isEmpty {
                Text("No hay animales con destino de venta.")
                    .font(.system(size: 14))
                    .foregroundStyle(Tema.secundario)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Animal")
                        .font(.system(size: 14))
                        .foregroundStyle(Tema.secundario)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Picker("Animal", selection: $areteSeleccionado) {
                        ForEach(animalesEnVenta) { animal in
                            Text("\(animal.arete) · \(animal.raza.rawValue) · \(Int(animal.pesoKg)) kg")
                                .tag(animal.arete)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(Tema.tinta)
                    .font(.system(size: 16))
                    .foregroundStyle(Tema.tinta)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: Tema.radioControl)
                            .fill(Tema.fondo)
                            .overlay(
                                RoundedRectangle(cornerRadius: Tema.radioControl)
                                    .stroke(Tema.linea, lineWidth: 1)
                            )
                    )
                    .accessibilityLabel("Animal para la venta")
                }

                Divider().background(Tema.linea)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kilos vendidos")
                            .font(.system(size: 14))
                            .foregroundStyle(Tema.secundario)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        TextField("0", text: $kilosTexto)
                            .keyboardType(.decimalPad)
                            .focused($campoActivo, equals: .kilos)
                            .modifier(CampoTextoCostosVentas())
                            .accessibilityLabel("Kilos vendidos")
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Precio por kilo")
                            .font(.system(size: 14))
                            .foregroundStyle(Tema.secundario)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        HStack(spacing: 8) {
                            ForEach(PrecioKg.allCases) { opcion in
                                Button {
                                    precio = opcion
                                } label: {
                                    Text(opcion.etiqueta)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(precio == opcion ? .white : Tema.tinta)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: Tema.radioControl)
                                                .fill(precio == opcion ? Tema.verde : Tema.fondo)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Tema.radioControl)
                                                        .stroke(Tema.linea, lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Precio \(opcion.etiqueta) por kilo")
                                .accessibilityAddTraits(precio == opcion ? [.isSelected] : [])
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Divider().background(Tema.linea)

                VStack(alignment: .leading, spacing: 4) {
                    EtiquetaSeccion("Ingreso de la venta")
                    Text(pesos(ingreso))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Tema.verde)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("\(kilos.formatted(.number.precision(.fractionLength(0...1)))) kg × \(pesos(precio.rawValue))")
                        .font(.system(size: 14))
                        .foregroundStyle(Tema.secundario)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 2. Costo del animal

    private var tarjetaCosto: some View {
        Tarjeta {
            Text("Costo y ganancia")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Tema.tinta)

            VStack(alignment: .leading, spacing: 6) {
                Text("Costo acumulado ($)")
                    .font(.system(size: 14))
                    .foregroundStyle(Tema.secundario)
                TextField("Suma de sus compras", text: $costoTexto)
                    .keyboardType(.decimalPad)
                    .focused($campoActivo, equals: .costo)
                    .modifier(CampoTextoCostosVentas())
                    .accessibilityLabel("Costo acumulado en pesos")
            }

            Divider().background(Tema.linea)

            VStack(alignment: .leading, spacing: 4) {
                EtiquetaSeccion("Ganancia estimada")
                if let costo {
                    let ganancia = ingreso - costo
                    Text(pesos(ganancia))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(ganancia >= 0 ? Tema.verde : Tema.terracota)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    Text("Captura el costo para verla")
                        .font(.system(size: 14))
                        .foregroundStyle(Tema.secundario)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
    }

    // MARK: - 3. Registrar venta

    /// Explica por qué el botón está apagado.
    private var motivoBloqueo: String {
        animalSeleccionado == nil
            ? "Elige el animal y escribe los kilos"
            : "Escribe los kilos vendidos"
    }

    private var bloqueRegistro: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !confirmacion.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Tema.exitoTexto)
                        .accessibilityHidden(true)
                    Text(confirmacion)
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.exitoTexto)
                }
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Tema.radioControl)
                        .fill(Tema.exitoFondo)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel(confirmacion)
            }

            Button("Registrar venta") { registrarVenta() }
                .buttonStyle(BotonPrimario())
                .disabled(!puedeRegistrar)
                .opacity(puedeRegistrar ? 1 : 0.85)

            if !puedeRegistrar {
                Text(motivoBloqueo)
                    .font(.system(size: 14))
                    .foregroundStyle(Tema.secundario)
            }
        }
    }

    private func registrarVenta() {
        guard let animal = animalSeleccionado, kilos > 0 else { return }
        let venta = Venta(fecha: Date(),
                          areteAnimal: animal.arete,
                          kilos: kilos,
                          precioPorKg: precio.rawValue)
        contexto.insert(venta)
        try? contexto.save()

        confirmacion = "Venta registrada de \(animal.arete) · \(kilos.formatted(.number.precision(.fractionLength(0...1)))) kg"
        let marca = UUID()
        marcaConfirmacion = marca
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if marcaConfirmacion == marca { confirmacion = "" }
        }
    }

    // MARK: - 4. Ventas registradas

    private var bloqueVentas: some View {
        VStack(alignment: .leading, spacing: 12) {
            EtiquetaSeccion("Ventas registradas")

            Tarjeta {
                if ventas.isEmpty {
                    Text("Todavía no hay ventas registradas.")
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                        .frame(minHeight: 44, alignment: .leading)
                } else {
                    ForEach(Array(ventas.enumerated()), id: \.element.persistentModelID) { indice, venta in
                        if indice > 0 { Divider().background(Tema.linea) }
                        let kilosVenta = venta.kilos.formatted(.number.precision(.fractionLength(0...1)))
                        HStack(spacing: 12) {
                            Text(fechaCorta(venta.fecha))
                                .font(.system(size: 14))
                                .foregroundStyle(Tema.secundario)
                                .frame(width: 64, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(venta.areteAnimal)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Tema.tinta)
                                Text("\(kilosVenta) kg × \(pesos(venta.precioPorKg))")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Tema.secundario)
                            }
                            Spacer(minLength: 8)
                            Text(pesos(venta.total))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Tema.tinta)
                        }
                        .frame(minHeight: 44)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Venta del \(fechaCorta(venta.fecha)), \(venta.areteAnimal), \(kilosVenta) kg a \(pesos(venta.precioPorKg)) el kilo, total \(pesos(venta.total))")
                    }
                }
            }
        }
    }

    // MARK: - Apoyos

    private func sincronizarSeleccion() {
        guard let primero = animalesEnVenta.first else { return }
        if animalSeleccionado == nil {
            areteSeleccionado = primero.arete
            kilosTexto = String(Int(primero.pesoKg))
        }
    }

    /// Lee un número escrito con punto o con coma decimal. Devuelve nil si el campo está vacío.
    private static func numero(_ texto: String) -> Double? {
        let limpio = texto
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard !limpio.isEmpty else { return nil }
        return Double(limpio)
    }
}

/// Estilo de campo de captura con los tokens de Tema.
private struct CampoTextoCostosVentas: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16))
            .foregroundStyle(Tema.tinta)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Tema.radioControl)
                    .fill(Tema.fondo)
                    .overlay(
                        RoundedRectangle(cornerRadius: Tema.radioControl)
                            .stroke(Tema.linea, lineWidth: 1)
                    )
            )
    }
}

#Preview {
    VistaCostosVentas()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self, VisitaVeterinario.self, Pedido.self], inMemory: true)
}
