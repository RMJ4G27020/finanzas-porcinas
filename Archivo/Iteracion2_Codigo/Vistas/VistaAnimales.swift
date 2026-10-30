import SwiftUI
import SwiftData

// MARK: - Pantalla de animales

struct VistaAnimales: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: [SortDescriptor(\Animal.arete)]) private var animales: [Animal]

    @State private var busqueda: String = ""
    @State private var filtro: FiltroDestino = .todos
    @State private var mostrandoAlta: Bool = false

    @ScaledMetric(relativeTo: .headline) private var tamArete: CGFloat = 16
    @ScaledMetric(relativeTo: .subheadline) private var tamResumen: CGFloat = 14
    @ScaledMetric(relativeTo: .footnote) private var tamNota: CGFloat = 13

    private enum FiltroDestino: String, CaseIterable, Identifiable {
        case todos = "Todos"
        case crianza = "Crianza"
        case venta = "Venta"
        var id: String { rawValue }
    }

    private var deCrianza: Int {
        animales.filter { $0.destino == .crianza }.count
    }

    private func normalizar(_ texto: String) -> String {
        texto.folding(options: [.diacriticInsensitive, .caseInsensitive],
                      locale: Locale(identifier: "es_MX"))
    }

    private var filtrados: [Animal] {
        let termino = normalizar(busqueda.trimmingCharacters(in: .whitespacesAndNewlines))
        return animales.filter { animal in
            let coincideDestino: Bool
            switch filtro {
            case .todos:   coincideDestino = true
            case .crianza: coincideDestino = animal.destino == .crianza
            case .venta:   coincideDestino = animal.destino == .venta
            }
            guard coincideDestino else { return false }
            guard !termino.isEmpty else { return true }
            return normalizar(animal.arete).contains(termino)
                || normalizar(animal.raza.rawValue).contains(termino)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        encabezado
                        buscador
                        selectorDestino
                        NavigationLink {
                            VistaVeterinario()
                        } label: {
                            Text("Ver visitas del veterinario")
                        }
                        .buttonStyle(BotonSecundario())
                        VStack(alignment: .leading, spacing: 8) {
                            if !animales.isEmpty {
                                Text("Mostrando \(filtrados.count) de \(animales.count)")
                                    .font(.system(size: tamNota))
                                    .foregroundStyle(Tema.secundario)
                            }
                            lista
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $mostrandoAlta) {
                FormularioNuevoAnimal()
            }
        }
    }

    // MARK: Encabezado

    private var encabezado: some View {
        HStack(alignment: .top, spacing: 12) {
            TituloPantalla(
                titulo: "Animales",
                subtitulo: "\(animales.count) animales · \(deCrianza) de crianza"
            )

            Button {
                mostrandoAlta = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: Tema.radioControl)
                            .fill(Tema.verde)
                    )
            }
            .accessibilityLabel("Agregar animal")
        }
    }

    // MARK: Buscador

    private var buscador: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Tema.inactivo)
                .accessibilityHidden(true)

            TextField("Buscar por nombre o raza", text: $busqueda)
                .font(.system(size: tamArete))
                .foregroundStyle(Tema.tinta)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.done)

            if !busqueda.isEmpty {
                Button {
                    busqueda = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Tema.inactivo)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Borrar búsqueda")
            }
        }
        .padding(.leading, 14)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: Tema.radioControl)
                .fill(Tema.superficie)
                .overlay(
                    RoundedRectangle(cornerRadius: Tema.radioControl)
                        .stroke(Tema.linea, lineWidth: 1)
                )
        )
    }

    // MARK: Filtro por destino

    private var selectorDestino: some View {
        HStack(spacing: 8) {
            ForEach(FiltroDestino.allCases) { opcion in
                Button {
                    filtro = opcion
                } label: {
                    Text(opcion.rawValue)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(filtro == opcion ? Color.white : Tema.secundario)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: Tema.radioControl)
                                .fill(filtro == opcion ? Tema.verde : Tema.superficie)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Tema.radioControl)
                                        .stroke(filtro == opcion ? Color.clear : Tema.linea,
                                                lineWidth: 1)
                                )
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mostrar \(opcion.rawValue)")
                .accessibilityAddTraits(filtro == opcion ? [.isSelected] : [])
            }
        }
    }

    // MARK: Lista

    private var lista: some View {
        Tarjeta {
            if animales.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Todavía no hay animales")
                        .font(.system(size: tamArete, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                    Text("Da de alta el primero para llevar el control del hato.")
                        .font(.system(size: tamResumen))
                        .foregroundStyle(Tema.secundario)
                    Button {
                        mostrandoAlta = true
                    } label: {
                        Text("Agregar animal")
                    }
                    .buttonStyle(BotonPrimario())
                    .padding(.top, 4)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if filtrados.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sin animales que mostrar")
                        .font(.system(size: tamArete, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                    Text("Cambia la búsqueda o el filtro para ver el hato.")
                        .font(.system(size: tamResumen))
                        .foregroundStyle(Tema.secundario)
                    Button {
                        busqueda = ""
                        filtro = .todos
                    } label: {
                        Text("Quitar filtros")
                    }
                    .buttonStyle(BotonSecundario())
                    .padding(.top, 4)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filtrados.enumerated()), id: \.element.persistentModelID) { indice, animal in
                        if indice > 0 {
                            Divider().overlay(Tema.linea)
                        }
                        NavigationLink {
                            DetalleAnimal(animal: animal)
                        } label: {
                            renglon(animal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func renglon(_ animal: Animal) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(animal.arete)
                    .font(.system(size: tamArete, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text(animal.resumen)
                    .font(.system(size: tamResumen))
                    .foregroundStyle(Tema.secundario)
            }
            Spacer(minLength: 8)
            Chip(texto: animal.destino.rawValue,
                 estilo: animal.destino == .crianza ? .neutro : .pendiente)
                .fixedSize()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Tema.inactivo)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(animal.arete). \(animal.raza.rawValue), \(animal.sexo.rawValue), \(Int(animal.pesoKg)) kilos. Destino \(animal.destino.rawValue).")
        .accessibilityHint("Abre la ficha del animal")
    }
}

// MARK: - Detalle de un animal

private struct DetalleAnimal: View {
    let animal: Animal

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @State private var confirmandoBorrado: Bool = false

    var body: some View {
        ZStack {
            Tema.fondo.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TituloPantalla(titulo: animal.arete, subtitulo: animal.resumen)

                    Tarjeta {
                        EtiquetaSeccion(texto: "Ficha")
                        dato("Raza", animal.raza.rawValue)
                        Divider().overlay(Tema.linea)
                        dato("Sexo", animal.sexo.rawValue)
                        Divider().overlay(Tema.linea)
                        dato("Peso", "\(Int(animal.pesoKg)) kg")
                        Divider().overlay(Tema.linea)
                        HStack {
                            Text("Destino")
                                .font(.system(size: 15))
                                .foregroundStyle(Tema.secundario)
                            Spacer(minLength: 8)
                            Chip(texto: animal.destino.rawValue,
                                 estilo: animal.destino == .crianza ? .neutro : .pendiente)
                        }
                        Divider().overlay(Tema.linea)
                        dato("Alta", fechaLarga(animal.fechaAlta))
                        if !animal.notas.isEmpty {
                            Divider().overlay(Tema.linea)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notas")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Tema.secundario)
                                Text(animal.notas)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Tema.tinta)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Button {
                        confirmandoBorrado = true
                    } label: {
                        Text("Dar de baja este animal")
                            .foregroundStyle(Tema.terracota)
                    }
                    .buttonStyle(BotonSecundario())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(animal.arete)
        .navigationBarTitleDisplayMode(.inline)
        .alert("¿Dar de baja a \(animal.arete)?", isPresented: $confirmandoBorrado) {
            Button("Cancelar", role: .cancel) { }
            Button("Dar de baja", role: .destructive) {
                contexto.delete(animal)
                try? contexto.save()
                cerrar()
            }
        } message: {
            Text("Se borrará del registro del criadero.")
        }
    }

    private func dato(_ etiqueta: String, _ valor: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(etiqueta)
                .font(.system(size: 15))
                .foregroundStyle(Tema.secundario)
            Spacer(minLength: 8)
            Text(valor)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Tema.tinta)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Alta de un animal

private struct FormularioNuevoAnimal: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar

    @State private var arete: String = ""
    @State private var raza: Raza = .comun
    @State private var sexo: Sexo = .hembra
    @State private var peso: String = ""
    @State private var destino: Destino = .crianza

    private var areteLimpio: String {
        arete.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var pesoKg: Double {
        Double(peso.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TituloPantalla(titulo: "Nuevo animal",
                                       subtitulo: Empresa.nombre)

                        Tarjeta {
                            EtiquetaSeccion(texto: "Arete")
                            TextField("Cerdo 08", text: $arete)
                                .font(.system(size: 16))
                                .foregroundStyle(Tema.tinta)
                                .autocorrectionDisabled(true)
                                .padding(.horizontal, 14)
                                .frame(minHeight: 44)
                                .background(campoFondo)

                            EtiquetaSeccion(texto: "Raza")
                            Picker("Raza", selection: $raza) {
                                ForEach(Raza.allCases) { opcion in
                                    Text(opcion.rawValue).tag(opcion)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(minHeight: 44)

                            EtiquetaSeccion(texto: "Sexo")
                            Picker("Sexo", selection: $sexo) {
                                ForEach(Sexo.allCases) { opcion in
                                    Text(opcion.rawValue).tag(opcion)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(minHeight: 44)

                            EtiquetaSeccion(texto: "Peso en kg")
                            TextField("0", text: $peso)
                                .font(.system(size: 16))
                                .foregroundStyle(Tema.tinta)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 14)
                                .frame(minHeight: 44)
                                .background(campoFondo)

                            EtiquetaSeccion(texto: "Destino")
                            Picker("Destino", selection: $destino) {
                                ForEach(Destino.allCases) { opcion in
                                    Text(opcion.rawValue).tag(opcion)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(minHeight: 44)
                        }

                        Button {
                            guardar()
                        } label: {
                            Text("Guardar animal")
                        }
                        .buttonStyle(BotonPrimario())
                        .disabled(areteLimpio.isEmpty)
                        .opacity(areteLimpio.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Alta de animal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                        .foregroundStyle(Tema.verde)
                }
            }
        }
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
        guard !areteLimpio.isEmpty else { return }
        let nuevo = Animal(arete: areteLimpio,
                           raza: raza,
                           sexo: sexo,
                           pesoKg: pesoKg,
                           destino: destino)
        contexto.insert(nuevo)
        try? contexto.save()
        cerrar()
    }
}

#Preview {
    VistaAnimales()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                              VisitaVeterinario.self, Pedido.self], inMemory: true)
}
