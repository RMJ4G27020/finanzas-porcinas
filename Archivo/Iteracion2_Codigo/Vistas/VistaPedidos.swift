import SwiftUI
import SwiftData

struct VistaPedidos: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Pedido.folio, order: .reverse)]) private var pedidos: [Pedido]

    @State private var filtro: FiltroCanal = .todos
    @State private var mostrandoFormulario = false
    @State private var errorGuardado: String?
    @State private var cambiosGuardados = 0

    enum FiltroCanal: String, CaseIterable, Identifiable {
        case todos = "Todos"
        case facebook = "Facebook"
        case whatsapp = "WhatsApp"
        var id: String { rawValue }
    }

    private var pedidosFiltrados: [Pedido] {
        switch filtro {
        case .todos: return pedidos
        case .facebook: return pedidos.filter { $0.canal == .facebook }
        case .whatsapp: return pedidos.filter { $0.canal == .whatsapp }
        }
    }

    /// Subtítulo con un dato vivo de la lista en lugar de una frase publicitaria.
    private var subtituloPedidos: String? {
        if pedidos.isEmpty { return nil }
        let porEntregar = pedidos.filter { $0.estado != .entregado }.count
        switch porEntregar {
        case 0: return "Todo entregado"
        case 1: return "1 pedido por entregar"
        default: return "\(porEntregar) pedidos por entregar"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        TituloPantalla(
                            titulo: "Pedidos",
                            subtitulo: subtituloPedidos
                        )

                        Picker("Canal", selection: $filtro) {
                            ForEach(FiltroCanal.allCases) { f in Text(f.rawValue).tag(f) }
                        }
                        .pickerStyle(.segmented)
                        .frame(height: 44)

                        Tarjeta {
                            if pedidosFiltrados.isEmpty {
                                EstadoVacioPedidos(
                                    titulo: filtro == .todos
                                        ? "Todavía no hay pedidos"
                                        : "Sin pedidos de \(filtro.rawValue)",
                                    detalle: filtro == .todos
                                        ? "Toca Nuevo pedido para anotar el primero."
                                        : "Elige otro canal para ver los demás pedidos."
                                )
                            } else {
                                ForEach(Array(pedidosFiltrados.enumerated()), id: \.element.persistentModelID) { indice, pedido in
                                    if indice > 0 {
                                        Divider().overlay(Tema.linea)
                                    }
                                    RenglonPedido(pedido: pedido) { nuevo in
                                        cambiarEstado(de: pedido, a: nuevo)
                                    }
                                }
                            }
                        }

                        Button("Nuevo pedido") { mostrandoFormulario = true }
                            .buttonStyle(BotonPrimario())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 96)
                }
            }
            .sensoryFeedback(.success, trigger: cambiosGuardados)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $mostrandoFormulario) {
                FormularioPedido(siguienteFolio: (pedidos.map(\.folio).max() ?? 0) + 1)
            }
            .alert(
                "No se guardó",
                isPresented: Binding(
                    get: { errorGuardado != nil },
                    set: { if !$0 { errorGuardado = nil } }
                )
            ) {
                Button("Entendido", role: .cancel) { errorGuardado = nil }
            } message: {
                Text(errorGuardado ?? "")
            }
        }
    }

    /// Cambia el estado del pedido y lo guarda. Si no se puede guardar, regresa
    /// el estado anterior para que la pantalla no diga algo que no quedó escrito.
    private func cambiarEstado(de pedido: Pedido, a nuevo: EstadoPedido) {
        let anterior = pedido.estado
        guard anterior != nuevo else { return }
        withAnimation(.easeOut(duration: 0.2)) { pedido.estado = nuevo }
        do {
            try modelContext.save()
            cambiosGuardados += 1
        } catch {
            withAnimation(.easeOut(duration: 0.2)) { pedido.estado = anterior }
            errorGuardado = "No se pudo guardar el cambio. Vuelve a intentarlo."
        }
    }
}

/// Estado vacío de la lista: centrado y con una salida, para que no parezca un error.
private struct EstadoVacioPedidos: View {
    let titulo: String
    let detalle: String

    @ScaledMetric(relativeTo: .title) private var tIcono: CGFloat = 28
    @ScaledMetric(relativeTo: .headline) private var tTitulo: CGFloat = 16
    @ScaledMetric(relativeTo: .subheadline) private var tDetalle: CGFloat = 14

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag")
                .font(.system(size: tIcono))
                .foregroundStyle(Tema.inactivo)
                .accessibilityHidden(true)
            Text(titulo)
                .font(.system(size: tTitulo, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .multilineTextAlignment(.center)
            Text(detalle)
                .font(.system(size: tDetalle))
                .foregroundStyle(Tema.secundario)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
    }
}

private struct RenglonPedido: View {
    let pedido: Pedido
    let cambiarEstado: (EstadoPedido) -> Void

    @ScaledMetric(relativeTo: .headline) private var tTitulo: CGFloat = 15
    @ScaledMetric(relativeTo: .subheadline) private var tSecundario: CGFloat = 14
    @ScaledMetric(relativeTo: .title3) private var tImporte: CGFloat = 18
    @ScaledMetric(relativeTo: .footnote) private var tCuenta: CGFloat = 13

    /// Kilos sin decimales si son enteros ("5") y con un decimal si no ("2.5").
    private var kilosTexto: String {
        pedido.kilos.formatted(
            .number.precision(.fractionLength(0...1)).locale(Locale(identifier: "es_MX"))
        )
    }

    var body: some View {
        // Si el texto no cabe junto al estado (letra grande), el estado baja debajo del texto.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                icono
                textos(lineaUnica: true)
                Spacer(minLength: 8)
                menuEstado
            }
            HStack(alignment: .top, spacing: 12) {
                icono
                VStack(alignment: .leading, spacing: 8) {
                    textos(lineaUnica: false)
                    menuEstado
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
    }

    private var icono: some View {
        ZStack {
            Circle().fill(Tema.neutroFondo).frame(width: 36, height: 36)
            Image(systemName: pedido.canal.simbolo)
                .font(.system(size: 17))
                .foregroundStyle(Tema.verde)
        }
        .accessibilityHidden(true)
    }

    private func textos(lineaUnica: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pedido.titulo)
                .font(.system(size: tTitulo, weight: .semibold))
                .foregroundStyle(Tema.tinta)
            Text("\(pedido.canal.rawValue) · \(fechaCorta(pedido.fecha))")
                .font(.system(size: tSecundario))
                .foregroundStyle(Tema.secundario)
                .lineLimit(lineaUnica ? 1 : nil)
            importe
        }
    }

    private var importe: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(pesos(pedido.total))
                .font(.system(size: tImporte, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Tema.tinta)
            Text("\(kilosTexto) kg × \(pesos(pedido.precioPorKg))")
                .font(.system(size: tCuenta))
                .foregroundStyle(Tema.secundario)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(kilosTexto) \(pedido.kilos == 1 ? "kilo" : "kilos") a \(pesos(pedido.precioPorKg)) el kilo. Total \(pesos(pedido.total))"
        )
    }

    private var menuEstado: some View {
        Menu {
            ForEach(EstadoPedido.allCases) { estado in
                Button(estado.rawValue) { cambiarEstado(estado) }
            }
        } label: {
            HStack(spacing: 4) {
                Chip(texto: pedido.estado.rawValue, estilo: pedido.chip)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Tema.secundario)
            }
            .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Estado del \(pedido.titulo): \(pedido.estado.rawValue). Tocar para cambiar.")
    }
}

private struct FormularioPedido: View {
    let siguienteFolio: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var canal: Canal = .whatsapp
    @State private var kilosTexto: String = ""
    @State private var precio: PrecioKg = .cuarenta
    @State private var estado: EstadoPedido = .nuevo

    private var kilos: Double { Double(kilosTexto.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Canal") {
                    Picker("Canal", selection: $canal) {
                        ForEach(Canal.allCases) { c in Text(c.rawValue).tag(c) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Venta") {
                    TextField("Kilos", text: $kilosTexto)
                        .keyboardType(.decimalPad)
                    if kilos <= 0 {
                        Text("Anota los kilos para poder guardar.")
                            .font(.footnote)
                            .foregroundStyle(Tema.secundario)
                    }
                    Picker("Precio por kg", selection: $precio) {
                        ForEach(PrecioKg.allCases) { p in Text(p.etiqueta).tag(p) }
                    }
                    .pickerStyle(.segmented)
                    LabeledContent("Total", value: pesos(kilos * precio.rawValue))
                }
                Section("Estado") {
                    Picker("Estado", selection: $estado) {
                        ForEach(EstadoPedido.allCases) { e in Text(e.rawValue).tag(e) }
                    }
                }
            }
            .navigationTitle("Nuevo pedido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }
                        .disabled(kilos <= 0)
                }
            }
        }
    }

    private func guardar() {
        let pedido = Pedido(
            folio: siguienteFolio,
            fecha: Date(),
            canal: canal,
            kilos: kilos,
            precioPorKg: precio.rawValue,
            estado: estado
        )
        modelContext.insert(pedido)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    VistaPedidos()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                              VisitaVeterinario.self, Pedido.self], inMemory: true)
}
