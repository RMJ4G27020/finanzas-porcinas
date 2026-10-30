import SwiftUI
import SwiftData

struct VistaBitacora: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: [SortDescriptor(\Tarea.fecha, order: .reverse)]) private var tareas: [Tarea]

    @State private var kilosTexto: String = ""
    @State private var hora: Date = Date()
    @State private var notas: String = ""
    @State private var mostrarConfirmacion: Bool = false
    @FocusState private var campoActivo: Campo?
    @Environment(\.dynamicTypeSize) private var tamanoTexto

    private enum Campo: Hashable { case kilos, notas }

    private let calendario = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TituloPantalla(
                            titulo: "Bitácora",
                            subtitulo: "Alimentación y limpieza · \(fechaLarga(Date()))"
                        )

                        tarjetaHoy
                        tarjetaRegistro

                        EtiquetaSeccion(texto: "Días anteriores")
                            .accessibilityAddTraits(.isHeader)

                        if diasAnteriores.isEmpty {
                            Tarjeta {
                                Text("Todavía no hay días cerrados. Lo de hoy aparecerá aquí mañana.")
                                    .font(.system(.callout))
                                    .foregroundStyle(Tema.secundario)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } else {
                            tarjetaDiasAnteriores
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { campoActivo = nil }
                }
            }
            .task { crearTareasDeHoySiFaltan() }
        }
    }

    // MARK: - Hoy

    private var tarjetaHoy: some View {
        Tarjeta {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                EtiquetaSeccion(texto: "Hoy")
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Chip(
                    texto: "\(hechasHoy) de \(tareasDeHoy.count) hechas",
                    estilo: (!tareasDeHoy.isEmpty && hechasHoy == tareasDeHoy.count) ? .exito : .pendiente
                )
            }

            ForEach(tareasDeHoy) { tarea in
                renglon(tarea)
                if tarea.id != tareasDeHoy.last?.id {
                    Divider().overlay(Tema.linea)
                }
            }
        }
    }

    private func renglon(_ tarea: Tarea) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                circulo(hecha: tarea.hecha)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tarea.tipo.rawValue)
                        .font(.system(.callout, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(tarea.detalle)
                        .font(.system(.subheadline))
                        .foregroundStyle(Tema.secundario)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if tarea.hecha {
                    Chip(texto: "Hecho", estilo: .exito)
                }
            }
            .accessibilityElement(children: .combine)

            if !tarea.hecha {
                Button {
                    marcarHecha(tarea)
                } label: {
                    Text("Marcar hecho")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: Tema.radioControl)
                                .fill(Tema.verde)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Marcar hecho: \(tarea.tipo.rawValue)")
            }
        }
        .padding(.vertical, 4)
    }

    private func circulo(hecha: Bool) -> some View {
        ZStack {
            if hecha {
                Circle().fill(Tema.verde)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle().stroke(Tema.terracota, lineWidth: 2)
            }
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }

    // MARK: - Alimentación de la tarde

    private var tarjetaRegistro: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 4) {
                EtiquetaSeccion(texto: "Alimentación de la tarde")
                    .accessibilityAddTraits(.isHeader)
                Text("Lo que anotes aquí se guarda en la tarea «Alimentación · tarde».")
                    .font(.system(.footnote))
                    .foregroundStyle(Tema.secundario)
                    .fixedSize(horizontal: false, vertical: true)
            }

            disposicionKilosHora {
                columnaKilos
                columnaHora
            }

            columnaNotas

            VStack(spacing: 8) {
                Button("Guardar kilos de la tarde") { guardarRegistro() }
                    .buttonStyle(BotonPrimario())
                    .opacity(kilosCapturados == nil ? 0.4 : 1)
                    .disabled(kilosCapturados == nil)

                if kilosCapturados == nil && !mostrarConfirmacion {
                    Text("Escribe los kilos de alimento para poder guardar.")
                        .font(.system(.footnote))
                        .foregroundStyle(Tema.secundario)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if mostrarConfirmacion {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(.footnote))
                            .foregroundStyle(Tema.verde)
                            .accessibilityHidden(true)
                        Text(mensajeConfirmacion)
                            .font(.system(.footnote))
                            .foregroundStyle(Tema.exitoTexto)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity)
                }
            }
        }
    }

    private var textoGrande: Bool { tamanoTexto.isAccessibilitySize }

    /// Kilos y hora van lado a lado; con texto muy grande se apilan para que nada se corte.
    private var disposicionKilosHora: AnyLayout {
        textoGrande
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: 12))
    }

    private var anchoColumnaHora: CGFloat? { textoGrande ? nil : 132 }

    private var fondoCampo: some View {
        RoundedRectangle(cornerRadius: Tema.radioControl)
            .fill(Tema.fondo)
            .overlay(
                RoundedRectangle(cornerRadius: Tema.radioControl)
                    .stroke(Tema.linea, lineWidth: 1)
            )
    }

    private var columnaKilos: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Alimento servido (kg)")
                .font(.system(.subheadline))
                .foregroundStyle(Tema.secundario)
                .fixedSize(horizontal: false, vertical: true)
            TextField(
                "Alimento servido en kilos",
                text: $kilosTexto,
                prompt: Text("0").foregroundStyle(Tema.secundario)
            )
            .keyboardType(.decimalPad)
            .focused($campoActivo, equals: .kilos)
            .font(.system(.callout))
            .foregroundStyle(Tema.tinta)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(fondoCampo)
            .contentShape(RoundedRectangle(cornerRadius: Tema.radioControl))
            .onTapGesture { campoActivo = .kilos }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var columnaHora: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hora")
                .font(.system(.subheadline))
                .foregroundStyle(Tema.secundario)
            DatePicker("Hora", selection: $hora, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Tema.verde)
                .frame(minHeight: 44)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .background(fondoCampo)
        }
        .frame(width: anchoColumnaHora, alignment: .leading)
    }

    private var columnaNotas: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notas para \(Empresa.titular)")
                .font(.system(.subheadline))
                .foregroundStyle(Tema.secundario)
                .fixedSize(horizontal: false, vertical: true)
            TextField(
                "Notas para \(Empresa.titular)",
                text: $notas,
                prompt: Text("Algo que reportar").foregroundStyle(Tema.secundario),
                axis: .vertical
            )
            .lineLimit(2...3)
            .focused($campoActivo, equals: .notas)
            .font(.system(.callout))
            .foregroundStyle(Tema.tinta)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 44, alignment: .topLeading)
            .background(fondoCampo)
            .contentShape(RoundedRectangle(cornerRadius: Tema.radioControl))
            .onTapGesture { campoActivo = .notas }
        }
    }

    // MARK: - Días anteriores

    private var tarjetaDiasAnteriores: some View {
        Tarjeta {
            ForEach(diasAnteriores, id: \.fecha) { dia in
                HStack(spacing: 12) {
                    Text(fechaLarga(dia.fecha))
                        .font(.system(.callout))
                        .foregroundStyle(Tema.tinta)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if dia.completo {
                        Chip(texto: "Completo", estilo: .exito)
                    } else {
                        Chip(texto: "Incompleto", estilo: .pendiente)
                    }
                }
                .frame(minHeight: 44)

                if dia.fecha != diasAnteriores.last?.fecha {
                    Divider().overlay(Tema.linea)
                }
            }
        }
    }

    // MARK: - Datos derivados

    private var tareasDeHoy: [Tarea] {
        tareas
            .filter { calendario.isDateInToday($0.fecha) }
            .sorted { $0.tipo.orden < $1.tipo.orden }
    }

    private struct DiaBitacora {
        let fecha: Date
        let tareas: [Tarea]
        var completo: Bool { !tareas.isEmpty && tareas.allSatisfy { $0.hecha } }
    }

    private var diasAnteriores: [DiaBitacora] {
        let hoy = calendario.startOfDay(for: Date())
        let pasadas = tareas.filter { calendario.startOfDay(for: $0.fecha) < hoy }
        let grupos = Dictionary(grouping: pasadas) { calendario.startOfDay(for: $0.fecha) }
        return grupos.keys.sorted(by: >).map { clave in
            DiaBitacora(
                fecha: clave,
                tareas: (grupos[clave] ?? []).sorted { $0.tipo.orden < $1.tipo.orden }
            )
        }
    }

    private var hechasHoy: Int { tareasDeHoy.filter { $0.hecha }.count }

    private var tardeYaHecha: Bool {
        tareasDeHoy.first(where: { $0.tipo == .alimentacionTarde })?.hecha ?? false
    }

    private var mensajeConfirmacion: String {
        tardeYaHecha
            ? "Guardado en Alimentación · tarde."
            : "Guardado en Alimentación · tarde. Falta marcarla como hecha."
    }

    private var kilosCapturados: Double? {
        let limpio = kilosTexto
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let valor = Double(limpio), valor > 0 else { return nil }
        return valor
    }

    // MARK: - Acciones

    private func crearTareasDeHoySiFaltan() {
        let hoy = calendario.startOfDay(for: Date())
        let existentes = Set(tareasDeHoy.map { $0.tipoRaw })
        var huboCambios = false

        for tipo in TipoTarea.allCases where !existentes.contains(tipo.rawValue) {
            contexto.insert(Tarea(fecha: hoy, tipo: tipo, hecha: false, detalle: "Pendiente"))
            huboCambios = true
        }
        if huboCambios { try? contexto.save() }
    }

    private func marcarHecha(_ tarea: Tarea) {
        tarea.hecha = true
        tarea.detalle = "Ahora · \(Empresa.operador)"
        try? contexto.save()
    }

    private func guardarRegistro() {
        guard let kilos = kilosCapturados else { return }
        guard let tarde = tareasDeHoy.first(where: { $0.tipo == .alimentacionTarde }) else { return }

        let nota = notas
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        tarde.kilosAlimento = kilos
        tarde.detalle = "\(horaTexto(hora)) · \(Int(kilos)) kg · \(Empresa.operador)"
            + (nota.isEmpty ? "" : " · \(nota)")
        try? contexto.save()

        campoActivo = nil
        kilosTexto = ""
        notas = ""
        withAnimation(.easeOut(duration: 0.2)) { mostrarConfirmacion = true }
        AccessibilityNotification.Announcement(mensajeConfirmacion).post()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeOut(duration: 0.2)) { mostrarConfirmacion = false }
        }
    }

    private func horaTexto(_ fecha: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "H:mm"
        return f.string(from: fecha)
    }
}

#Preview {
    VistaBitacora()
        .modelContainer(
            for: [Animal.self, Tarea.self, Compra.self, Venta.self, VisitaVeterinario.self, Pedido.self],
            inMemory: true
        )
}
