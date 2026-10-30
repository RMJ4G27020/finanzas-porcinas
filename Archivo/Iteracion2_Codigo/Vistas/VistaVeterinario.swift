import SwiftUI
import SwiftData

/// Pantalla del veterinario del criadero: próxima visita e historial de atenciones.
/// Se presenta empujada desde VistaAnimales, por eso no declara NavigationStack propio.
struct VistaVeterinario: View {

    @Environment(\.modelContext) private var contexto
    @Query(sort: [SortDescriptor(\VisitaVeterinario.fecha, order: .reverse)])
    private var visitas: [VisitaVeterinario]

    @State private var modo: ModoVisita?

    // MARK: - Datos derivados

    /// Visita agendada: la más próxima con fecha posterior a hoy.
    private var proxima: VisitaVeterinario? {
        let ahora = Date()
        return visitas.filter { $0.fecha > ahora }.min { $0.fecha < $1.fecha }
    }

    /// Atenciones ya realizadas, de la más reciente a la más antigua.
    private var pasadas: [VisitaVeterinario] {
        let ahora = Date()
        return visitas.filter { $0.fecha <= ahora }
    }

    // MARK: - Cuerpo

    var body: some View {
        ZStack {
            Tema.fondo.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TituloPantalla(titulo: "Veterinario", subtitulo: Empresa.veterinario)

                    tarjetaProximaVisita

                    EtiquetaSeccion(texto: "Historial de atenciones")
                    tarjetaHistorial

                    Button("Registrar atención") { modo = .registrar }
                        .buttonStyle(BotonSecundario())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .sheet(item: $modo) { modoActual in
            HojaVisitaVeterinario(modo: modoActual) { fecha, tipoAtencion in
                guardar(fecha: fecha, tipoAtencion: tipoAtencion)
            }
        }
    }

    // MARK: - Bloques

    private var tarjetaProximaVisita: some View {
        Tarjeta {
            EtiquetaSeccion(texto: "Próxima visita")

            if let proxima {
                Text(fechaLarga(proxima.fecha))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                if !proxima.tipoAtencion.isEmpty {
                    Text(proxima.tipoAtencion)
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                }
                Chip(texto: "Agendada", estilo: .exito)
            } else {
                Text("Por agendar")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text("No hay visita programada con \(Empresa.veterinario).")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            }

            Button("Agendar visita") { modo = .agendar }
                .buttonStyle(BotonPrimario())
        }
    }

    private var tarjetaHistorial: some View {
        Tarjeta {
            if pasadas.isEmpty {
                Text("Aún no hay atenciones registradas.")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            } else {
                ForEach(Array(pasadas.enumerated()), id: \.element.id) { indice, visita in
                    if indice > 0 { Divider() }
                    filaAtencion(visita)
                }
            }
        }
    }

    private func filaAtencion(_ visita: VisitaVeterinario) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text(diaDelMes(visita.fecha))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text(mesAbreviado(visita.fecha))
                    .font(.system(size: 12))
                    .foregroundStyle(Tema.secundario)
            }
            .frame(width: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(visita.tipoAtencion)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                if !visita.alcance.isEmpty {
                    Text(visita.alcance)
                        .font(.system(size: 14))
                        .foregroundStyle(Tema.secundario)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Acciones

    private func guardar(fecha: Date, tipoAtencion: String) {
        let limpio = tipoAtencion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return }
        contexto.insert(VisitaVeterinario(fecha: fecha, tipoAtencion: limpio, alcance: ""))
        try? contexto.save()
        modo = nil
    }

    // MARK: - Formato de fecha

    private func diaDelMes(_ fecha: Date) -> String {
        String(Calendar.current.component(.day, from: fecha))
    }

    private func mesAbreviado(_ fecha: Date) -> String {
        let formato = DateFormatter()
        formato.locale = Locale(identifier: "es_MX")
        formato.dateFormat = "MMM"
        return formato.string(from: fecha)
    }
}

// MARK: - Modo de la hoja

private enum ModoVisita: String, Identifiable {
    case agendar
    case registrar
    var id: String { rawValue }
}

// MARK: - Hoja para agendar o registrar

private struct HojaVisitaVeterinario: View {

    let modo: ModoVisita
    let alGuardar: (Date, String) -> Void

    @Environment(\.dismiss) private var cerrar
    @State private var fecha: Date
    @State private var tipoAtencion: String = ""

    init(modo: ModoVisita, alGuardar: @escaping (Date, String) -> Void) {
        self.modo = modo
        self.alGuardar = alGuardar
        _fecha = State(initialValue: modo == .agendar
                       ? HojaVisitaVeterinario.manana()
                       : Date())
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
            let inicio = HojaVisitaVeterinario.manana()
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

    private var listaParaGuardar: Bool {
        !tipoAtencion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TituloPantalla(titulo: titulo, subtitulo: subtitulo)

                        Tarjeta {
                            EtiquetaSeccion(texto: "Fecha")
                            DatePicker("Fecha de la atención",
                                       selection: $fecha,
                                       in: rango,
                                       displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .tint(Tema.verde)
                                .accessibilityLabel("Fecha de la atención")
                        }

                        Tarjeta {
                            EtiquetaSeccion(texto: "Tipo de atención")
                            TextField("Revisión general", text: $tipoAtencion)
                                .font(.system(size: 16))
                                .foregroundStyle(Tema.tinta)
                                .textInputAutocapitalization(.sentences)
                                .frame(minHeight: 44)
                        }

                        Button(titulo) {
                            alGuardar(fecha, tipoAtencion)
                        }
                        .buttonStyle(BotonPrimario())
                        .disabled(!listaParaGuardar)
                        .opacity(listaParaGuardar ? 1 : 0.5)

                        Button("Cancelar") { cerrar() }
                            .buttonStyle(BotonSecundario())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    VistaVeterinario()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self, VisitaVeterinario.self, Pedido.self], inMemory: true)
}
