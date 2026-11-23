import SwiftUI
import SwiftData

/// "¿Qué tengo que entregar?"
/// Cada pedido es una tarjeta grande con su total, sus tres pasos y un solo botón para avanzar.
struct VistaPedidos: View {
    @Environment(Navegacion.self) private var navegacion
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Pedido.folio, order: .reverse)]) private var pedidos: [Pedido]

    @State private var filtro: FiltroEstadoPedido = .porEntregar
    @State private var canalElegido: Canal? = nil
    @State private var mostrandoFormulario = false
    @State private var errorGuardado: String?
    @State private var aviso: String?
    @State private var cambiosGuardados = 0

    enum FiltroEstadoPedido: String, CaseIterable, Identifiable {
        case porEntregar = "Por entregar"
        case entregados = "Entregados"
        case todos = "Todos"
        var id: String { rawValue }
    }

    // MARK: - Datos derivados (se calculan en Swift, no en @Query)

    /// Pedidos Nuevo + Por entregar, de todos los canales.
    private var porEntregar: Int {
        pedidos.filter { $0.estado != .entregado }.count
    }

    private var pedidosDelCanal: [Pedido] {
        guard let canalElegido else { return pedidos }
        return pedidos.filter { $0.canal == canalElegido }
    }

    private var pedidosFiltrados: [Pedido] {
        switch filtro {
        case .porEntregar: return pedidosDelCanal.filter { $0.estado != .entregado }
        case .entregados:  return pedidosDelCanal.filter { $0.estado == .entregado }
        case .todos:       return pedidosDelCanal
        }
    }

    private func cuenta(de filtro: FiltroEstadoPedido) -> Int {
        switch filtro {
        case .porEntregar: return pedidosDelCanal.filter { $0.estado != .entregado }.count
        case .entregados:  return pedidosDelCanal.filter { $0.estado == .entregado }.count
        case .todos:       return pedidosDelCanal.count
        }
    }

    // MARK: - Cuerpo

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        TituloPantalla(titulo: "Pedidos", subtitulo: "\(porEntregar) por entregar")

                        botonesDeFiltro
                        filtroDeCanal

                        if pedidosFiltrados.isEmpty {
                            estadoVacio
                        } else {
                            ForEach(pedidosFiltrados, id: \.persistentModelID) { pedido in
                                PedidosTarjeta(pedido: pedido) { avanzar(pedido) }
                                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { barraNuevoPedido }
            .overlay(alignment: .top) {
                if let aviso {
                    PedidosAviso(texto: aviso)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .task(id: aviso) {
                guard aviso != nil else { return }
                try? await Task.sleep(for: .seconds(2.5))
                if !Task.isCancelled {
                    withAnimation(.easeOut(duration: 0.25)) { aviso = nil }
                }
            }
            .sensoryFeedback(.success, trigger: cambiosGuardados)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: navegacion.abrirNuevoPedido) { _, nuevo in
                if nuevo { mostrandoFormulario = true; navegacion.abrirNuevoPedido = false }
            }
            .onAppear {
                if navegacion.abrirNuevoPedido { mostrandoFormulario = true; navegacion.abrirNuevoPedido = false }
            }
            .sheet(isPresented: $mostrandoFormulario) {
                PedidosFormulario(siguienteFolio: (pedidos.map(\.folio).max() ?? 0) + 1) { guardado in
                    pedidoGuardado(guardado)
                }
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

    // MARK: - Filtros

    /// Tres botones grandes: por entregar, entregados y todos.
    private var botonesDeFiltro: some View {
        HStack(spacing: 8) {
            ForEach(FiltroEstadoPedido.allCases) { opcion in
                let activo = filtro == opcion
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { filtro = opcion }
                } label: {
                    VStack(spacing: 2) {
                        Text("\(cuenta(de: opcion))")
                            .font(.system(size: 26, weight: .bold))
                            .monospacedDigit()
                        Text(opcion.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.87)
                    }
                    .foregroundStyle(activo ? Tema.superficie : Tema.tinta)
                    .frame(maxWidth: .infinity, minHeight: 68)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(activo ? Tema.verde : Tema.superficie)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(activo ? Tema.verde : Tema.linea, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(opcion.rawValue), \(cuenta(de: opcion))")
                .accessibilityAddTraits(activo ? .isSelected : [])
            }
        }
    }

    /// Dos fichas para ver solo un canal. Si no hay ninguna activa, se ven todos.
    private var filtroDeCanal: some View {
        HStack(spacing: 8) {
            Text("Ver solo:")
                .font(.system(size: 15))
                .foregroundStyle(Tema.secundario)
            ForEach(Canal.allCases) { canal in
                let activo = canalElegido == canal
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        canalElegido = activo ? nil : canal
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: canal.simbolo)
                            .font(.system(size: 15, weight: .semibold))
                            .accessibilityHidden(true)
                        Text(canal.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(activo ? Tema.superficie : Tema.tinta)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(activo ? Tema.verde : Tema.superficie))
                    .overlay(Capsule().stroke(activo ? Tema.verde : Tema.linea, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ver solo \(canal.rawValue)")
                .accessibilityAddTraits(activo ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Estado vacío

    private var textosVacio: (icono: String, titulo: String, detalle: String) {
        if let canalElegido {
            return ("magnifyingglass",
                    "No hay pedidos de \(canalElegido.rawValue) aquí",
                    "Prueba con el otro canal o toca «Nuevo pedido».")
        }
        switch filtro {
        case .porEntregar:
            return ("shippingbox",
                    "No tienes pedidos por entregar",
                    "Cuando te llegue uno, toca «Nuevo pedido» para anotarlo.")
        case .entregados:
            return ("checkmark.circle",
                    "Todavía no hay pedidos entregados",
                    "Aquí aparecerán cuando marques uno como entregado.")
        case .todos:
            return ("bag",
                    "Todavía no hay pedidos",
                    "Toca «Nuevo pedido» para anotar el primero.")
        }
    }

    private var estadoVacio: some View {
        let textos = textosVacio
        return VStack(spacing: 12) {
            ZStack {
                Circle().fill(Tema.neutroFondo).frame(width: 104, height: 104)
                Image(systemName: textos.icono)
                    .font(.system(size: 46))
                    .foregroundStyle(Tema.verde)
            }
            .accessibilityHidden(true)

            Text(textos.titulo)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .multilineTextAlignment(.center)

            Text(textos.detalle)
                .font(.system(size: 17))
                .foregroundStyle(Tema.secundario)
                .multilineTextAlignment(.center)

            if canalElegido != nil {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { canalElegido = nil }
                } label: {
                    Text("Ver todos los canales")
                        .font(.system(size: 17, weight: .bold))
                        .frame(minHeight: 52)
                }
                .buttonStyle(BotonSecundario())
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Botón fijo

    private var barraNuevoPedido: some View {
        Button {
            mostrandoFormulario = true
        } label: {
            PedidosEtiquetaBoton(icono: "plus", titulo: "Nuevo pedido", alto: 56)
        }
        .buttonStyle(BotonPrimario())
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            Tema.fondo
                .overlay(alignment: .top) {
                    Rectangle().fill(Tema.linea).frame(height: 1)
                }
        )
    }

    // MARK: - Acciones

    /// Pasa el pedido al siguiente paso y lo guarda. Si no se puede guardar,
    /// regresa el estado anterior para que la pantalla no diga algo que no quedó escrito.
    private func avanzar(_ pedido: Pedido) {
        let anterior = pedido.estado
        let siguiente: EstadoPedido
        switch anterior {
        case .nuevo:       siguiente = .porEntregar
        case .porEntregar: siguiente = .entregado
        case .entregado:   return
        }

        withAnimation(.easeInOut(duration: 0.25)) { pedido.estado = siguiente }
        do {
            try modelContext.save()
            cambiosGuardados += 1
            avisar(siguiente == .entregado
                   ? "\(pedido.titulo) entregado"
                   : "\(pedido.titulo) listo para entregar")
        } catch {
            withAnimation(.easeInOut(duration: 0.25)) { pedido.estado = anterior }
            errorGuardado = "No se pudo guardar el cambio. Vuelve a intentarlo."
        }
    }

    /// Tras crear un pedido se muestra en la lista y se confirma con un aviso.
    private func pedidoGuardado(_ pedido: Pedido) {
        withAnimation(.easeInOut(duration: 0.25)) {
            filtro = .porEntregar
            if let canalElegido, canalElegido != pedido.canal { self.canalElegido = nil }
        }
        cambiosGuardados += 1
        avisar("\(pedido.titulo) guardado")
    }

    private func avisar(_ texto: String) {
        withAnimation(.spring(duration: 0.3)) { aviso = texto }
        AccessibilityNotification.Announcement(texto).post()
    }
}

// MARK: - Aviso de confirmación

private struct PedidosAviso: View {
    let texto: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .accessibilityHidden(true)
            Text(texto)
                .font(.system(size: 17, weight: .bold))
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(Tema.superficie)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Tema.verde))
        .shadow(color: Tema.tinta.opacity(0.25), radius: 8, y: 3)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Etiqueta de botón con icono

private struct PedidosEtiquetaBoton: View {
    let icono: String
    let titulo: String
    let alto: CGFloat

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 20, weight: .bold))
                .accessibilityHidden(true)
            Text(titulo)
                .font(.system(size: 19, weight: .bold))
        }
        .frame(maxWidth: .infinity, minHeight: alto)
    }
}

/// Botón grande de color para el paso de cada pedido.
private struct PedidosBotonPaso: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Tema.superficie)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// MARK: - Tarjeta de pedido

private struct PedidosTarjeta: View {
    let pedido: Pedido
    let avanzar: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var tTotal: CGFloat = 34
    @ScaledMetric(relativeTo: .headline) private var tTitulo: CGFloat = 17
    @ScaledMetric(relativeTo: .body) private var tCuenta: CGFloat = 17

    /// Kilos sin decimales si son enteros ("5") y con un decimal si no ("2.5").
    private var kilosTexto: String {
        pedido.kilos.formatted(
            .number.precision(.fractionLength(0...1)).locale(Locale(identifier: "es_MX"))
        )
    }

    var body: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 18) {
                encabezado
                importe
                PedidosPasos(actual: pedido.estado)
                accion
            }
            .padding(4)
        }
    }

    private var encabezado: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Tema.neutroFondo)
                Image(systemName: pedido.canal.simbolo)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Tema.verde)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(pedido.titulo)
                    .font(.system(size: tTitulo, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text("\(pedido.canal.rawValue) · \(fechaCorta(pedido.fecha))")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var importe: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pesos(pedido.total))
                .font(.system(size: tTotal, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Tema.tinta)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(kilosTexto) kg × \(pesos(pedido.precioPorKg))")
                .font(.system(size: tCuenta))
                .foregroundStyle(Tema.secundario)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Total \(pesos(pedido.total)). \(kilosTexto) \(pedido.kilos == 1 ? "kilo" : "kilos") a \(pesos(pedido.precioPorKg)) el kilo."
        )
    }

    /// Un solo botón visible: avanza al siguiente paso. Si ya se entregó, solo se muestra el sello.
    @ViewBuilder
    private var accion: some View {
        switch pedido.estado {
        case .nuevo:
            Button(action: avanzar) {
                paso(icono: "shippingbox", titulo: "Marcar por entregar")
            }
            .buttonStyle(PedidosBotonPaso(color: Tema.terracota))
            .accessibilityLabel("Marcar \(pedido.titulo) por entregar")

        case .porEntregar:
            Button(action: avanzar) {
                paso(icono: "checkmark.circle", titulo: "Marcar entregado")
            }
            .buttonStyle(PedidosBotonPaso(color: Tema.verde))
            .accessibilityLabel("Marcar \(pedido.titulo) como entregado")

        case .entregado:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .accessibilityHidden(true)
                Text("Entregado")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(Tema.exitoTexto)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Tema.exitoFondo))
            .accessibilityElement(children: .combine)
        }
    }

    private func paso(icono: String, titulo: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 20, weight: .bold))
                .accessibilityHidden(true)
            Text(titulo)
                .font(.system(size: 18, weight: .bold))
        }
    }
}

// MARK: - Los tres pasos: Nuevo → Por entregar → Entregado

private struct PedidosPasos: View {
    let actual: EstadoPedido

    private var indiceActual: Int {
        EstadoPedido.allCases.firstIndex(of: actual) ?? 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(EstadoPedido.allCases.enumerated()), id: \.offset) { indice, estado in
                if indice > 0 {
                    Capsule()
                        .fill(indice <= indiceActual ? Tema.verde : Tema.linea)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.horizontal, 6)
                }
                paso(estado, indice)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estado: \(actual.rawValue). Paso \(indiceActual + 1) de \(EstadoPedido.allCases.count).")
    }

    private func paso(_ estado: EstadoPedido, _ indice: Int) -> some View {
        let hecho = indice < indiceActual
        let esActual = indice == indiceActual
        let lleno = hecho || esActual
        let conPalomita = hecho || (esActual && estado == .entregado)

        return VStack(spacing: 6) {
            ZStack {
                Circle().fill(lleno ? Tema.verde : Tema.superficie)
                Circle().stroke(lleno ? Tema.verde : Tema.linea, lineWidth: 2)
                if conPalomita {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Tema.superficie)
                } else if esActual {
                    Circle().fill(Tema.superficie).frame(width: 10, height: 10)
                }
            }
            .frame(width: 28, height: 28)
            .overlay {
                if esActual {
                    Circle()
                        .stroke(Tema.verde.opacity(0.25), lineWidth: 6)
                        .padding(-3)
                }
            }

            Text(estado.rawValue)
                .font(.system(size: 14, weight: esActual ? .bold : .regular))
                .foregroundStyle(esActual ? Tema.tinta : Tema.secundario)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 78)
    }
}

// MARK: - Formulario "Nuevo pedido"

private struct PedidosFormulario: View {
    let siguienteFolio: Int
    let alGuardar: (Pedido) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var canal: Canal = .whatsapp
    @State private var kilosTexto: String = ""
    @State private var precio: PrecioKg = .cuarenta
    @FocusState private var kilosEnfocado: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var tKilos: CGFloat = 34
    @ScaledMetric(relativeTo: .largeTitle) private var tTotal: CGFloat = 40

    private var kilos: Double {
        let limpio = kilosTexto
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let valor = Double(limpio), valor.isFinite, valor > 0 else { return 0 }
        return valor
    }
    private var total: Double { kilos * precio.rawValue }
    private var sePuedeGuardar: Bool { kilos > 0 }

    private var kilosFormateados: String {
        kilos.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "es_MX")))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        encabezado
                        bloqueCanal
                        bloqueKilos
                        bloquePrecio
                        bloqueTotal
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { barraGuardar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { kilosEnfocado = false }
                        .font(.system(size: 17, weight: .bold))
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Bloques

    private var encabezado: some View {
        HStack(alignment: .top, spacing: 12) {
            TituloPantalla(
                titulo: "Nuevo pedido",
                subtitulo: String(format: "Pedido %03d", siguienteFolio)
            )
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Tema.neutroFondo))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar sin guardar")
        }
    }

    private var bloqueCanal: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "¿Por dónde llegó el pedido?")
            HStack(spacing: 12) {
                ForEach(Canal.allCases) { opcion in
                    PedidosOpcionCanal(canal: opcion, elegido: canal == opcion) {
                        canal = opcion
                    }
                }
            }
        }
    }

    private var bloqueKilos: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "¿Cuántos kilos?")
            HStack(spacing: 8) {
                TextField("0", text: $kilosTexto)
                    .font(.system(size: tKilos, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .keyboardType(.decimalPad)
                    .focused($kilosEnfocado)
                    .accessibilityLabel("Kilos del pedido")
                Text("kg")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Tema.secundario)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 76)
            .background(
                RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                    .fill(Tema.superficie)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                    .stroke(kilosEnfocado ? Tema.verde : Tema.linea, lineWidth: kilosEnfocado ? 3 : 1.5)
            )
            .contentShape(Rectangle())
            .onTapGesture { kilosEnfocado = true }
        }
    }

    private var bloquePrecio: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "¿A cómo el kilo?")
            HStack(spacing: 12) {
                ForEach(PrecioKg.allCases) { opcion in
                    let activo = precio == opcion
                    Button {
                        kilosEnfocado = false
                        precio = opcion
                    } label: {
                        VStack(spacing: 2) {
                            Text(opcion.etiqueta)
                                .font(.system(size: 40, weight: .bold))
                                .monospacedDigit()
                            Text("por kilo")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(activo ? Tema.superficie : Tema.tinta)
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .background(
                            RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                                .fill(activo ? Tema.verde : Tema.superficie)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                                .stroke(activo ? Tema.verde : Tema.linea, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(opcion.etiqueta) por kilo")
                    .accessibilityAddTraits(activo ? .isSelected : [])
                }
            }
        }
    }

    private var bloqueTotal: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total del pedido")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Tema.secundario)
                Text(pesos(total))
                    .font(.system(size: tTotal, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(sePuedeGuardar
                     ? "\(kilosFormateados) kg × \(pesos(precio.rawValue))"
                     : "Anota los kilos para ver el total")
                    .font(.system(size: 17))
                    .foregroundStyle(Tema.secundario)
            }
            .padding(4)
            .accessibilityElement(children: .combine)
        }
    }

    private var barraGuardar: some View {
        VStack(spacing: 8) {
            if !sePuedeGuardar {
                Text("Anota los kilos para poder guardar.")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            }
            Button {
                guardar()
            } label: {
                PedidosEtiquetaBoton(icono: "checkmark", titulo: "Guardar pedido", alto: 56)
            }
            .buttonStyle(BotonPrimario())
            .disabled(!sePuedeGuardar)
            .opacity(sePuedeGuardar ? 1 : 0.45)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            Tema.fondo
                .overlay(alignment: .top) {
                    Rectangle().fill(Tema.linea).frame(height: 1)
                }
        )
    }

    // MARK: Guardar

    private func guardar() {
        guard sePuedeGuardar else { return }
        let pedido = Pedido(
            folio: siguienteFolio,
            fecha: Date(),
            canal: canal,
            kilos: kilos,
            precioPorKg: precio.rawValue,
            estado: .nuevo
        )
        modelContext.insert(pedido)
        try? modelContext.save()
        alGuardar(pedido)
        dismiss()
    }
}

/// Tarjeta grande para elegir el canal por el que llegó el pedido.
private struct PedidosOpcionCanal: View {
    let canal: Canal
    let elegido: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            VStack(spacing: 8) {
                Image(systemName: canal.simbolo)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(elegido ? Tema.verde : Tema.inactivo)
                    .accessibilityHidden(true)
                Text(canal.rawValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text(canal.detalle)
                    .font(.system(size: 14))
                    .foregroundStyle(Tema.secundario)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 132)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                    .fill(elegido ? Tema.exitoFondo : Tema.superficie)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                    .stroke(elegido ? Tema.verde : Tema.linea, lineWidth: elegido ? 3 : 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if elegido {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Tema.verde)
                        .padding(10)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(canal.rawValue), \(canal.detalle)")
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }
}

#Preview {
    VistaPedidos()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                              VisitaVeterinario.self, Pedido.self], inMemory: true)
}
