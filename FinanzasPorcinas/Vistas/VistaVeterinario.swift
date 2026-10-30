import SwiftUI
import SwiftData

/// "¿Cuándo vino el doctor y cuándo vuelve?"
/// Se presenta empujada, por eso no declara NavigationStack propio.
struct VistaVeterinario: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: [SortDescriptor(\VisitaVeterinario.fecha, order: .reverse)])
    private var visitas: [VisitaVeterinario]
    @Query(sort: [SortDescriptor(\Animal.arete)]) private var animales: [Animal]

    @State private var modo: VeterinarioModoHoja?
    @State private var aviso: String?
    @State private var cambiosGuardados = 0

    @ScaledMetric(relativeTo: .title2) private var tNombre: CGFloat = 24
    @ScaledMetric(relativeTo: .title) private var tFecha: CGFloat = 28

    // MARK: - Datos derivados

    /// Visita agendada: la más próxima con fecha posterior a ahora.
    private var proxima: VisitaVeterinario? {
        let ahora = Date()
        return visitas.filter { $0.fecha > ahora }.min { $0.fecha < $1.fecha }
    }

    /// Atenciones ya realizadas, de la más reciente a la más antigua.
    private var pasadas: [VisitaVeterinario] {
        let ahora = Date()
        return visitas.filter { $0.fecha <= ahora }
    }

    /// Tipos de atención ya usados, para tocar en lugar de escribir.
    private var tiposConocidos: [String] {
        var vistos = Set<String>()
        var resultado: [String] = []
        for visita in visitas {
            let limpio = visita.tipoAtencion.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !limpio.isEmpty, vistos.insert(limpio.lowercased()).inserted else { continue }
            resultado.append(limpio)
        }
        return resultado
    }

    /// Si el alcance de la atención es un cerdo en particular ("Cerdo 02"), devuelve ese animal
    /// para mostrar su imagen. "Todos los animales" no corresponde a ninguno.
    private func animal(de alcance: String) -> Animal? {
        let buscado = alcance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !buscado.isEmpty else { return nil }
        return animales.first {
            $0.arete.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(buscado) == .orderedSame
        }
    }

    /// Una visita agendada vale todo el día elegido: se guarda al final de ese día
    /// para que el mismo día de la visita siga apareciendo como "Próxima visita".
    private func finDelDia(_ fecha: Date) -> Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: fecha) ?? fecha
    }

    /// "Es mañana", "Faltan 5 días".
    private func textoFaltan(_ fecha: Date) -> String {
        let calendario = Calendar.current
        let dias = calendario.dateComponents(
            [.day],
            from: calendario.startOfDay(for: Date()),
            to: calendario.startOfDay(for: fecha)
        ).day ?? 0
        switch dias {
        case ..<1: return "Es hoy"
        case 1:    return "Es mañana"
        default:   return "Faltan \(dias) días"
        }
    }

    // MARK: - Cuerpo

    var body: some View {
        ZStack {
            Tema.fondo.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    encabezado
                    tarjetaProximaVisita
                    TituloSeccion(texto: "Visitas anteriores", icono: "clock.arrow.circlepath")
                    bloqueHistorial

                    Button {
                        modo = .registrar
                    } label: {
                        VeterinarioEtiquetaBoton(icono: "square.and.pencil", titulo: "Registrar atención")
                    }
                    .buttonStyle(BotonSecundario())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .overlay(alignment: .top) {
            if let aviso {
                VeterinarioAviso(texto: aviso)
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
        .navigationTitle("Veterinario")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Tema.fondo, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .sheet(item: $modo) { modoActual in
            VeterinarioHoja(modo: modoActual, sugerencias: tiposConocidos) { fecha, tipo in
                guardar(modo: modoActual, fecha: fecha, tipoAtencion: tipo)
            }
        }
    }

    // MARK: - Encabezado

    private var encabezado: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Tema.verde)
                Image(systemName: "stethoscope")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Tema.superficie)
            }
            .frame(width: 72, height: 72)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(Empresa.veterinario)
                    .font(.system(size: tNombre, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Veterinario del criadero")
                    .font(.system(size: 17))
                    .foregroundStyle(Tema.secundario)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Próxima visita

    private var tarjetaProximaVisita: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 14) {
                TituloSeccion(texto: "Próxima visita", icono: "calendar")

                if let proxima {
                    Text(fechaLarga(proxima.fecha))
                        .font(.system(size: tFecha, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Text(textoFaltan(proxima.fecha))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Tema.exitoTexto)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Tema.exitoFondo))
                        if !proxima.tipoAtencion.isEmpty {
                            Text(proxima.tipoAtencion)
                                .font(.system(size: 17))
                                .foregroundStyle(Tema.secundario)
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Tema.pendienteFondo)
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Tema.pendienteTexto)
                        }
                        .frame(width: 52, height: 52)
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Por agendar")
                                .font(.system(size: tFecha, weight: .bold))
                                .foregroundStyle(Tema.tinta)
                            Text("Todavía no hay una visita programada.")
                                .font(.system(size: 17))
                                .foregroundStyle(Tema.secundario)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Button {
                    modo = .agendar
                } label: {
                    VeterinarioEtiquetaBoton(icono: "calendar.badge.plus", titulo: "Agendar visita")
                }
                .buttonStyle(BotonPrimario())
            }
            .padding(4)
        }
    }

    // MARK: - Línea de tiempo

    @ViewBuilder
    private var bloqueHistorial: some View {
        if pasadas.isEmpty {
            Tarjeta {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Tema.neutroFondo).frame(width: 88, height: 88)
                        Image(systemName: "cross.case")
                            .font(.system(size: 38))
                            .foregroundStyle(Tema.verde)
                    }
                    .accessibilityHidden(true)
                    Text("Todavía no hay visitas anotadas")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                        .multilineTextAlignment(.center)
                    Text("Toca «Registrar atención» para anotar la primera.")
                        .font(.system(size: 17))
                        .foregroundStyle(Tema.secundario)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)
            }
        } else {
            Tarjeta {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(pasadas.enumerated()), id: \.element.persistentModelID) { indice, visita in
                        filaDeTiempo(visita, esUltima: indice == pasadas.count - 1)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func filaDeTiempo(_ visita: VisitaVeterinario, esUltima: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Tema.verde)
                    .frame(width: 16, height: 16)
                    .padding(.top, 3)
                if !esUltima {
                    Rectangle()
                        .fill(Tema.linea)
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 4)
                }
            }
            .frame(width: 16)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(Self.fechaConAnio(visita.fecha))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Tema.secundario)
                Text(visita.tipoAtencion)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .fixedSize(horizontal: false, vertical: true)
                if !visita.alcance.isEmpty {
                    HStack(spacing: 10) {
                        if let cerdo = animal(de: visita.alcance) {
                            FotoAnimal(animal: cerdo, radio: 10)
                                .frame(width: 44, height: 44)
                                .accessibilityHidden(true)
                        }
                        Text(visita.alcance)
                            .font(.system(size: 17))
                            .foregroundStyle(Tema.secundario)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.bottom, esUltima ? 0 : 22)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private static func fechaConAnio(_ fecha: Date) -> String {
        let formato = DateFormatter()
        formato.locale = Locale(identifier: "es_MX")
        formato.dateFormat = "d MMM yyyy"
        return formato.string(from: fecha).replacingOccurrences(of: ".", with: "")
    }

    // MARK: - Guardar

    private func guardar(modo: VeterinarioModoHoja, fecha: Date, tipoAtencion: String) {
        let limpio = tipoAtencion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return }
        let fechaGuardada = modo == .agendar ? finDelDia(fecha) : fecha
        contexto.insert(VisitaVeterinario(fecha: fechaGuardada, tipoAtencion: limpio, alcance: ""))
        try? contexto.save()
        self.modo = nil
        cambiosGuardados += 1

        let texto = modo == .agendar
            ? "Visita agendada: \(fechaLarga(fecha))"
            : "Atención registrada: \(limpio)"
        withAnimation(.spring(duration: 0.3)) { aviso = texto }
        AccessibilityNotification.Announcement(texto).post()
    }
}

// MARK: - Piezas pequeñas

private struct VeterinarioEtiquetaBoton: View {
    let icono: String
    let titulo: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 20, weight: .bold))
                .accessibilityHidden(true)
            Text(titulo)
                .font(.system(size: 19, weight: .bold))
        }
        .frame(maxWidth: .infinity, minHeight: 56)
    }
}

private struct VeterinarioAviso: View {
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

// MARK: - Modo de la hoja

private enum VeterinarioModoHoja: String, Identifiable {
    case agendar
    case registrar
    var id: String { rawValue }
}

// MARK: - Hoja para agendar o registrar

private struct VeterinarioHoja: View {
    let modo: VeterinarioModoHoja
    let sugerencias: [String]
    let alGuardar: (Date, String) -> Void

    @Environment(\.dismiss) private var cerrar
    @State private var fecha: Date
    @State private var tipoAtencion: String = ""
    @FocusState private var escribiendo: Bool

    init(modo: VeterinarioModoHoja, sugerencias: [String],
         alGuardar: @escaping (Date, String) -> Void) {
        self.modo = modo
        self.sugerencias = sugerencias
        self.alGuardar = alGuardar
        _fecha = State(initialValue: modo == .agendar ? VeterinarioHoja.manana() : Date())
    }

    private static func manana() -> Date {
        let calendario = Calendar.current
        let inicioHoy = calendario.startOfDay(for: Date())
        return calendario.date(byAdding: .day, value: 1, to: inicioHoy) ?? Date()
    }

    private var rango: ClosedRange<Date> {
        let calendario = Calendar.current
        switch modo {
        case .agendar:
            let inicio = calendario.startOfDay(for: Date())
            let fin = calendario.date(byAdding: .year, value: 2, to: inicio) ?? inicio
            return inicio...fin
        case .registrar:
            let fin = Date()
            let inicio = calendario.date(byAdding: .year, value: -5, to: fin) ?? fin
            return inicio...fin
        }
    }

    private var titulo: String {
        modo == .agendar ? "Agendar visita" : "Registrar atención"
    }

    private var subtitulo: String {
        modo == .agendar
            ? "Visita futura con \(Empresa.veterinario)"
            : "Atención ya realizada por \(Empresa.veterinario)"
    }

    private var preguntaFecha: String {
        modo == .agendar ? "¿Qué día viene?" : "¿Qué día fue?"
    }

    private var listaParaGuardar: Bool {
        !tipoAtencion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        encabezado
                        bloqueFecha
                        bloqueTipo
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
                    Button("Listo") { escribiendo = false }
                        .font(.system(size: 17, weight: .bold))
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var encabezado: some View {
        HStack(alignment: .top, spacing: 12) {
            TituloPantalla(titulo: titulo, subtitulo: subtitulo)
            Button {
                cerrar()
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

    private var bloqueFecha: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: preguntaFecha, icono: "calendar")
            Tarjeta {
                DatePicker("Fecha de la atención",
                           selection: $fecha,
                           in: rango,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(Tema.verde)
                    .environment(\.locale, Locale(identifier: "es_MX"))
                    .accessibilityLabel("Fecha de la atención")
            }
        }
    }

    private var bloqueTipo: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "¿Qué atención es?", icono: "cross.case")

            TextField("Revisión general", text: $tipoAtencion)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Tema.tinta)
                .textInputAutocapitalization(.sentences)
                .focused($escribiendo)
                .submitLabel(.done)
                .onSubmit { escribiendo = false }
                .padding(.horizontal, 16)
                .frame(minHeight: 64)
                .background(
                    RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                        .fill(Tema.superficie)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                        .stroke(escribiendo ? Tema.verde : Tema.linea, lineWidth: escribiendo ? 3 : 1.5)
                )
                .contentShape(Rectangle())
                .onTapGesture { escribiendo = true }
                .accessibilityLabel("Tipo de atención")

            if !sugerencias.isEmpty {
                fichas
            }
        }
    }

    /// Atenciones ya registradas: un toque llena el campo.
    private var fichas: some View {
        let actual = tipoAtencion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(sugerencias, id: \.self) { opcion in
                    let activo = opcion.lowercased() == actual
                    Button {
                        tipoAtencion = opcion
                        escribiendo = false
                    } label: {
                        Text(opcion)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(activo ? Tema.superficie : Tema.tinta)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 48)
                            .background(Capsule().fill(activo ? Tema.verde : Tema.superficie))
                            .overlay(Capsule().stroke(activo ? Tema.verde : Tema.linea, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(activo ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var barraGuardar: some View {
        VStack(spacing: 8) {
            if !listaParaGuardar {
                Text("Escribe qué atención fue para poder guardar.")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            }
            Button {
                alGuardar(fecha, tipoAtencion)
            } label: {
                VeterinarioEtiquetaBoton(
                    icono: modo == .agendar ? "calendar.badge.plus" : "checkmark",
                    titulo: titulo
                )
            }
            .buttonStyle(BotonPrimario())
            .disabled(!listaParaGuardar)
            .opacity(listaParaGuardar ? 1 : 0.45)
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
}

#Preview {
    NavigationStack {
        VistaVeterinario()
    }
    .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                          VisitaVeterinario.self, Pedido.self], inMemory: true)
}
