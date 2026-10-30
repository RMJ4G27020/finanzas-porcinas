import SwiftUI
import SwiftData

/// Pantalla "Hoy": responde a la pregunta "¿qué toca hoy?".
struct VistaHoy: View {
    @Environment(Navegacion.self) private var navegacion
    @Binding var seleccion: Seccion

    @Environment(\.modelContext) private var contexto
    @Environment(\.scenePhase) private var faseEscena

    @Query(sort: \Tarea.fecha, order: .reverse) private var tareas: [Tarea]
    @Query(sort: \Animal.arete) private var animales: [Animal]
    @Query(sort: \Pedido.folio, order: .reverse) private var pedidos: [Pedido]

    @State private var tareaConKilos: Tarea?
    @State private var avisoPendiente: String?
    @State private var aviso: HoyAviso?

    private let margen: CGFloat = 20

    // MARK: Datos derivados (todo se filtra en Swift)

    private var tareasDeHoy: [Tarea] {
        tareas
            .filter { Calendar.current.isDateInToday($0.fecha) }
            .sorted { $0.tipo.orden < $1.tipo.orden }
    }

    private var hechasHoy: Int { tareasDeHoy.filter { $0.hecha }.count }

    private var animalesDeCrianza: [Animal] {
        animales.filter { $0.destino == .crianza }
    }

    private var pedidosPorEntregar: [Pedido] {
        pedidos.filter { $0.estado == .nuevo || $0.estado == .porEntregar }
    }

    private var saludo: String {
        let hora = Calendar.current.component(.hour, from: Date())
        switch hora {
        case 5..<12: return "Buenos días"
        case 12..<20: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }

    // MARK: Cuerpo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    encabezado
                    seccionTareas
                    seccionAtajos
                    seccionCerdos
                    tarjetaPedidos
                    botonVeterinario
                    enlaceDiasAnteriores
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background { Tema.fondo.ignoresSafeArea() }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) { bannerDeAviso }
        }
        .onAppear { prepararTareasDeHoy() }
        .onChange(of: faseEscena) { _, nueva in
            if nueva == .active { prepararTareasDeHoy() }
        }
        .sheet(item: $tareaConKilos, onDismiss: {
            if let texto = avisoPendiente {
                avisoPendiente = nil
                mostrarAviso(texto)
            }
        }) { tarea in
            HoyHojaKilos(tarea: tarea) { texto in
                avisoPendiente = texto
            }
        }
        .task(id: aviso) {
            guard aviso != nil else { return }
            do { try await Task.sleep(for: .seconds(2.5)) } catch { return }
            withAnimation(.easeIn(duration: 0.25)) { aviso = nil }
        }
        .sensoryFeedback(.success, trigger: hechasHoy)
    }

    // MARK: 1. Saludo

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(saludo)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .accessibilityAddTraits(.isHeader)
            Text(fechaLarga(Date()))
                .font(.system(size: 17))
                .foregroundStyle(Tema.secundario)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, margen)
    }

    // MARK: 2. Tareas de hoy

    private var seccionTareas: some View {
        VStack(alignment: .leading, spacing: 16) {
            TituloSeccion(texto: "Tareas de hoy", icono: "checklist")
            Tarjeta {
                VStack(alignment: .leading, spacing: 16) {
                    BarraProgreso(hechas: hechasHoy, total: tareasDeHoy.count)

                    if tareasDeHoy.isEmpty {
                        Text("Todavía no hay tareas para hoy.")
                            .font(.system(size: 17))
                            .foregroundStyle(Tema.secundario)
                        Button {
                            prepararTareasDeHoy()
                        } label: {
                            Label("Preparar las tareas de hoy", systemImage: "plus.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .frame(minHeight: 56)
                        }
                        .buttonStyle(BotonPrimario())
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(tareasDeHoy.enumerated()), id: \.element.persistentModelID) { indice, tarea in
                                if indice > 0 { Divider().overlay(Tema.linea) }
                                HoyFilaTarea(tarea: tarea) { marcarHecha(tarea) }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, margen)
    }

    // MARK: 3. Atajos

    private var seccionAtajos: some View {
        VStack(alignment: .leading, spacing: 16) {
            TituloSeccion(texto: "Atajos")
            HStack(spacing: 16) {
                AccionRapida(icono: "plus.circle.fill", titulo: "Agregar cerdo") {
                    navegacion.abrirAltaAnimal = true
                    seleccion = .animales
                }
                AccionRapida(icono: "banknote.fill", titulo: "Vender") {
                    seleccion = .dinero
                }
                AccionRapida(icono: "bag.fill", titulo: "Nuevo pedido", color: Tema.terracota) {
                    navegacion.abrirNuevoPedido = true
                    seleccion = .pedidos
                }
            }
        }
        .padding(.horizontal, margen)
    }

    // MARK: 4. Mis cerdos

    private var seccionCerdos: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                TituloSeccion(texto: "Mis cerdos", icono: "pawprint")
                Text("\(animalesDeCrianza.count) de crianza")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
                    .fixedSize()
            }
            .padding(.horizontal, margen)

            if animalesDeCrianza.isEmpty {
                Tarjeta {
                    HStack(spacing: 16) {
                        AvatarCerdo(raza: .comun)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text("Todavía no tienes cerdos de crianza.")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                    }
                    Button {
                        seleccion = .animales
                    } label: {
                        Label("Agregar cerdo", systemImage: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .frame(minHeight: 56)
                    }
                    .buttonStyle(BotonPrimario())
                }
                .padding(.horizontal, margen)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(animalesDeCrianza) { animal in
                            Button {
                                seleccion = .animales
                            } label: {
                                VStack(spacing: 8) {
                                    FotoAnimal(animal: animal, radio: 16)
                                        .frame(width: 92, height: 92)
                                    Text(animal.arete)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Tema.tinta)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                }
                                .frame(width: 92)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(animal.arete). Ver mis cerdos")
                        }
                    }
                }
                .contentMargins(.horizontal, margen, for: .scrollContent)
            }
        }
    }

    // MARK: 5. Pedidos por entregar

    @ViewBuilder
    private var tarjetaPedidos: some View {
        if !pedidosPorEntregar.isEmpty {
            Button {
                seleccion = .pedidos
            } label: {
                Tarjeta {
                    HStack(spacing: 16) {
                        Image(systemName: "bag")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Tema.pendienteTexto)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Tema.pendienteFondo))
                            .accessibilityHidden(true)
                        Text(textoPedidos)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Tema.secundario)
                            .accessibilityHidden(true)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, margen)
            .accessibilityLabel(textoPedidos)
            .accessibilityHint("Abre la pantalla de pedidos")
        }
    }

    private var textoPedidos: String {
        let n = pedidosPorEntregar.count
        return n == 1 ? "1 pedido por entregar" : "\(n) pedidos por entregar"
    }

    // MARK: 6. Veterinario

    private var botonVeterinario: some View {
        NavigationLink {
            VistaVeterinario()
        } label: {
            Label("Visitas del veterinario", systemImage: "stethoscope")
                .font(.system(size: 17, weight: .bold))
                .frame(minHeight: 56)
        }
        .buttonStyle(BotonSecundario())
        .padding(.horizontal, margen)
    }

    // MARK: 7. Días anteriores

    private var enlaceDiasAnteriores: some View {
        NavigationLink {
            HoyDiasAnteriores()
        } label: {
            HStack(spacing: 6) {
                Text("Ver días anteriores")
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Tema.secundario)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, margen)
    }

    // MARK: Confirmación visible

    @ViewBuilder
    private var bannerDeAviso: some View {
        if let aviso {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .accessibilityHidden(true)
                Text(aviso.texto)
                    .font(.system(size: 17, weight: .bold))
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Tema.verde))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            .padding(.horizontal, margen)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityElement(children: .combine)
        }
    }

    private func mostrarAviso(_ texto: String) {
        withAnimation(.easeOut(duration: 0.25)) { aviso = HoyAviso(texto: texto) }
        UIAccessibility.post(notification: .announcement, argument: texto)
    }

    // MARK: Acciones

    /// Crea las tareas de hoy que falten (alimentación mañana, limpieza, alimentación tarde).
    private func prepararTareasDeHoy() {
        let calendario = Calendar.current
        let inicio = calendario.startOfDay(for: Date())
        guard let fin = calendario.date(byAdding: .day, value: 1, to: inicio) else { return }
        let descriptor = FetchDescriptor<Tarea>(
            predicate: #Predicate<Tarea> { $0.fecha >= inicio && $0.fecha < fin }
        )
        let existentes = (try? contexto.fetch(descriptor)) ?? []
        let tiposExistentes = Set(existentes.map { $0.tipo })
        var seCreo = false
        for tipo in TipoTarea.allCases where !tiposExistentes.contains(tipo) {
            contexto.insert(Tarea(fecha: inicio, tipo: tipo, hecha: false, detalle: "Pendiente"))
            seCreo = true
        }
        if seCreo { try? contexto.save() }
    }

    private func marcarHecha(_ tarea: Tarea) {
        guard !tarea.hecha else { return }
        tarea.hecha = true
        tarea.responsable = Empresa.operador
        tarea.detalle = "Ahora · \(Empresa.operador)"
        try? contexto.save()

        let texto = "\(tarea.tipo.rawValue): hecha"
        switch tarea.tipo {
        case .alimentacionManana, .alimentacionTarde:
            avisoPendiente = texto
            tareaConKilos = tarea
        case .limpieza:
            mostrarAviso(texto)
        }
    }
}

// MARK: - Piezas privadas

private struct HoyAviso: Equatable {
    let id = UUID()
    let texto: String
}

private func hoyTextoKilos(_ valor: Double) -> String {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "es_MX")
    f.numberStyle = .decimal
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 1
    return f.string(from: NSNumber(value: valor)) ?? "\(valor)"
}

/// Fila alta de una tarea del día, con botón circular de 52 pt.
private struct HoyFilaTarea: View {
    let tarea: Tarea
    let alMarcar: () -> Void

    private var simbolo: String {
        switch tarea.tipo {
        case .alimentacionManana, .alimentacionTarde: return "fork.knife"
        case .limpieza: return "sparkles"
        }
    }

    private var detalleVisible: String {
        if tarea.hecha && tarea.kilosAlimento > 0 {
            return "\(tarea.detalle) · \(hoyTextoKilos(tarea.kilosAlimento)) kg"
        }
        return tarea.detalle
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: simbolo)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tarea.hecha ? Tema.exitoTexto : Tema.neutroTexto)
                .frame(width: 48, height: 48)
                .background(Circle().fill(tarea.hecha ? Tema.exitoFondo : Tema.neutroFondo))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(tarea.tipo.rawValue)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(2)
                Text(detalleVisible)
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            if tarea.hecha {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Tema.verde))
                    .accessibilityLabel("Hecha")
            } else {
                Button(action: alMarcar) {
                    Circle()
                        .strokeBorder(Tema.terracota, lineWidth: 3)
                        .frame(width: 52, height: 52)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Marcar como hecha: \(tarea.tipo.rawValue)")
            }
        }
        .frame(minHeight: 72)
    }
}

/// Hoja corta que se abre al terminar de alimentar: kilos y nota, ambos opcionales.
private struct HoyHojaKilos: View {
    let tarea: Tarea
    let alGuardar: (String) -> Void

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar

    @State private var kilosTexto = ""
    @State private var nota = ""
    @State private var kilosInvalidos = false
    @FocusState private var enfocado: Campo?

    private enum Campo: Hashable { case kilos, nota }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("¿Cuántos kilos de alimento se sirvieron?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kilos (opcional)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Tema.secundario)
                        HStack(spacing: 8) {
                            TextField("Por ejemplo: 12", text: $kilosTexto)
                                .keyboardType(.decimalPad)
                                .focused($enfocado, equals: .kilos)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Tema.tinta)
                                .onChange(of: kilosTexto) { _, _ in kilosInvalidos = false }
                            Text("kg")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Tema.secundario)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 56)
                        .background(campoFondo)

                        if kilosInvalidos {
                            Text("Escribe un número mayor que cero, por ejemplo 12.5")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Tema.pendienteTexto)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nota (opcional)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Tema.secundario)
                        TextField("Por ejemplo: comieron todo", text: $nota)
                            .font(.system(size: 17))
                            .foregroundStyle(Tema.tinta)
                            .focused($enfocado, equals: .nota)
                            .submitLabel(.done)
                            .onSubmit { enfocado = nil }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 56)
                            .background(campoFondo)
                    }

                    Button(action: guardar) {
                        Label("Listo", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .frame(minHeight: 56)
                    }
                    .buttonStyle(BotonPrimario())

                    Button("Omitir") { cerrar() }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Tema.secundario)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { Tema.fondo.ignoresSafeArea() }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { enfocado = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var campoFondo: some View {
        RoundedRectangle(cornerRadius: Tema.radioControl)
            .fill(Tema.superficie)
            .overlay(
                RoundedRectangle(cornerRadius: Tema.radioControl)
                    .stroke(Tema.linea, lineWidth: 1)
            )
    }

    private func guardar() {
        let escrito = kilosTexto.trimmingCharacters(in: .whitespaces)
        var kilos: Double? = nil
        if !escrito.isEmpty {
            guard let valor = Double(escrito.replacingOccurrences(of: ",", with: ".")),
                  valor.isFinite, valor > 0 else {
                kilosInvalidos = true
                return
            }
            kilos = valor
        }

        if let kilos { tarea.kilosAlimento = kilos }
        let notaLimpia = nota.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notaLimpia.isEmpty { tarea.detalle += " · \(notaLimpia)" }
        try? contexto.save()

        if let kilos {
            alGuardar("Guardado: \(hoyTextoKilos(kilos)) kg de alimento")
        } else {
            alGuardar("\(tarea.tipo.rawValue): hecha")
        }
        cerrar()
    }
}

/// Tareas de días pasados, agrupadas por día.
private struct HoyDiasAnteriores: View {
    @Environment(\.dismiss) private var cerrar
    @Query(sort: \Tarea.fecha, order: .reverse) private var tareas: [Tarea]

    private struct Dia: Identifiable {
        let id: Date
        let tareas: [Tarea]
        var completo: Bool { !tareas.isEmpty && tareas.allSatisfy { $0.hecha } }
    }

    private var dias: [Dia] {
        let calendario = Calendar.current
        let inicioHoy = calendario.startOfDay(for: Date())
        let pasadas = tareas.filter { $0.fecha < inicioHoy }
        let grupos = Dictionary(grouping: pasadas) { calendario.startOfDay(for: $0.fecha) }
        return grupos.keys.sorted(by: >).map { dia in
            let delDia = (grupos[dia] ?? []).sorted { $0.tipo.orden < $1.tipo.orden }
            return Dia(id: dia, tareas: delDia)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if dias.isEmpty {
                    vacio
                } else {
                    ForEach(dias) { dia in
                        tarjetaDelDia(dia)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background { Tema.fondo.ignoresSafeArea() }
        .navigationTitle("Días anteriores")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
    }

    private func tarjetaDelDia(_ dia: Dia) -> some View {
        Tarjeta {
            HStack(alignment: .center, spacing: 12) {
                Text(fechaLarga(dia.id))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .frame(maxWidth: .infinity, alignment: .leading)
                chipDelDia(completo: dia.completo)
            }
            ForEach(dia.tareas) { tarea in
                HStack(spacing: 10) {
                    Image(systemName: tarea.hecha ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(tarea.hecha ? Tema.verde : Tema.terracota)
                        .accessibilityHidden(true)
                    Text(tarea.tipo.rawValue)
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if tarea.hecha && tarea.kilosAlimento > 0 {
                        Text("\(hoyTextoKilos(tarea.kilosAlimento)) kg")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Tema.secundario)
                    }
                }
                .frame(minHeight: 32)
                .accessibilityElement(children: .combine)
                .accessibilityValue(tarea.hecha ? "Hecha" : "Sin hacer")
            }
        }
    }

    /// Chip propio de 14 pt (el Chip compartido es de 12 pt y aquí nada baja de 13 pt).
    private func chipDelDia(completo: Bool) -> some View {
        let estilo: EstiloChip = completo ? .exito : .pendiente
        return Text(completo ? "Completo" : "Incompleto")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(estilo.texto)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(estilo.fondo))
            .fixedSize()
    }

    private var vacio: some View {
        Tarjeta {
            AvatarCerdo(raza: .comun)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text("Todavía no hay días anteriores")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Tema.tinta)
            Text("Cuando pasen los días, aquí verás qué se hizo en cada uno.")
                .font(.system(size: 17))
                .foregroundStyle(Tema.secundario)
            Button {
                cerrar()
            } label: {
                Label("Volver a hoy", systemImage: "sun.max")
                    .font(.system(size: 18, weight: .bold))
                    .frame(minHeight: 56)
            }
            .buttonStyle(BotonPrimario())
        }
    }
}

// MARK: - Vista previa

/// Siembra los datos de ejemplo antes de mostrar la pantalla.
private struct HoyVistaPrevia: View {
    @Environment(\.modelContext) private var contexto
    @State private var listo = false

    var body: some View {
        Group {
            if listo {
                VistaHoy(seleccion: .constant(.hoy))
            } else {
                Color.clear
            }
        }
        .task {
            DatosIniciales.sembrarSiHaceFalta(contexto)
            listo = true
        }
    }
}

#Preview {
    HoyVistaPrevia()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self, VisitaVeterinario.self, Pedido.self], inMemory: true)
}
