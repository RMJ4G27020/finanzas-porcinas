import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - Mis cerdos: "¿cuáles son mis cerdos?"

struct VistaAnimales: View {
    @Environment(Navegacion.self) private var navegacion
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Animal.arete)]) private var animales: [Animal]

    @State private var filtro: FiltroCerdos = .todos
    @State private var busqueda: String = ""
    @State private var mostrandoAlta: Bool = false
    @State private var aviso: String? = nil
    @FocusState private var buscando: Bool

    private enum FiltroCerdos: String, CaseIterable, Identifiable {
        case todos = "Todos"
        case crianza = "Crianza"
        case venta = "Venta"
        var id: String { rawValue }
    }

    private let columnas = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    // MARK: Datos calculados

    private var total: Int { animales.count }

    private var deCrianza: Int {
        animales.filter { $0.destino == .crianza }.count
    }

    private var subtitulo: String {
        let cerdos = total == 1 ? "1 cerdo" : "\(total) cerdos"
        return "\(cerdos) · \(deCrianza) de crianza"
    }

    private func normalizar(_ texto: String) -> String {
        texto.folding(options: [.diacriticInsensitive, .caseInsensitive],
                      locale: Locale(identifier: "es_MX"))
    }

    private var terminoBusqueda: String {
        normalizar(busqueda.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var filtrados: [Animal] {
        let termino = terminoBusqueda
        // Orden natural: "Cerdo 5" va antes que "Cerdo 10" aunque no lleve cero a la izquierda.
        let ordenados = animales.sorted {
            $0.arete.localizedStandardCompare($1.arete) == .orderedAscending
        }
        return ordenados.filter { animal in
            switch filtro {
            case .todos:   break
            case .crianza: if animal.destino != .crianza { return false }
            case .venta:   if animal.destino != .venta { return false }
            }
            guard !termino.isEmpty else { return true }
            return normalizar(animal.arete).contains(termino)
                || normalizar(animal.raza.rawValue).contains(termino)
        }
    }

    private var hayFiltroActivo: Bool {
        filtro != .todos || !terminoBusqueda.isEmpty
    }

    /// Siguiente arete sugerido: "Cerdo 21" si el mayor número usado es 20.
    private var siguienteArete: String {
        var mayor = 0
        for animal in animales {
            let digitos = String(animal.arete.reversed().prefix(while: { $0.isNumber }).reversed())
            if let numero = Int(digitos), numero < 1_000_000 { mayor = max(mayor, numero) }
        }
        return String(format: "Cerdo %02d", mayor + 1)
    }

    // MARK: Cuerpo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TituloPantalla(titulo: "Mis cerdos", subtitulo: subtitulo)

                    if !animales.isEmpty {
                        botonesDeFiltro
                        buscador
                        if hayFiltroActivo {
                            Text("Mostrando \(filtrados.count) de \(total)")
                                .font(.system(size: 15))
                                .foregroundStyle(Tema.secundario)
                        }
                    }

                    contenido
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { Tema.fondo.ignoresSafeArea() }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                if !buscando { botonAgregar }
            }
            .overlay(alignment: .top) {
                if let aviso { bannerDeAviso(aviso) }
            }
            .onChange(of: navegacion.abrirAltaAnimal) { _, nuevo in
                if nuevo { mostrandoAlta = true; navegacion.abrirAltaAnimal = false }
            }
            .onAppear {
                if navegacion.abrirAltaAnimal { mostrandoAlta = true; navegacion.abrirAltaAnimal = false }
            }
            .sheet(isPresented: $mostrandoAlta) {
                HojaAltaCerdo(sugerencia: siguienteArete) { arete in
                    mostrarAviso("\(arete) agregado")
                }
            }
        }
    }

    @ViewBuilder
    private var contenido: some View {
        if animales.isEmpty {
            estadoVacio
        } else if filtrados.isEmpty {
            estadoSinResultados
        } else {
            LazyVGrid(columns: columnas, spacing: 16) {
                ForEach(filtrados) { animal in
                    NavigationLink {
                        VistaFichaAnimal(animal: animal)
                    } label: {
                        TarjetaCerdo(animal: animal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Filtro de tres botones

    private var botonesDeFiltro: some View {
        HStack(spacing: 8) {
            ForEach(FiltroCerdos.allCases) { opcion in
                let activo = filtro == opcion
                Button {
                    filtro = opcion
                } label: {
                    Text(opcion.rawValue)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(activo ? Color.white : Tema.tinta)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                                .fill(activo ? Tema.verde : Tema.superficie)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                                .stroke(activo ? Tema.verde : Tema.linea, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(opcion == .todos ? "Todos los cerdos" : "Cerdos de \(opcion.rawValue.lowercased())")
                .accessibilityAddTraits(activo ? .isSelected : [])
            }
        }
    }

    // MARK: Buscador

    private var buscador: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Tema.secundario)
                .accessibilityHidden(true)

            TextField("Buscar por nombre o raza", text: $busqueda)
                .font(.system(size: 17))
                .foregroundStyle(Tema.tinta)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .focused($buscando)
                .onSubmit { buscando = false }

            if !busqueda.isEmpty {
                Button {
                    busqueda = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Tema.inactivo)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Borrar búsqueda")
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, busqueda.isEmpty ? 14 : 2)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Tema.superficie)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Tema.linea, lineWidth: 1)
        )
    }

    // MARK: Estados vacíos

    private var estadoVacio: some View {
        VStack(spacing: 16) {
            AvatarCerdo(raza: .comun)
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
            Text("Todavía no hay cerdos")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .multilineTextAlignment(.center)
            Text("Agrega el primero con el botón de abajo")
                .font(.system(size: 17))
                .foregroundStyle(Tema.secundario)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .accessibilityElement(children: .combine)
    }

    private var estadoSinResultados: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Tema.verde)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Tema.exitoFondo))
                .accessibilityHidden(true)

            Text(mensajeSinResultados)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .multilineTextAlignment(.center)

            if !terminoBusqueda.isEmpty {
                Button {
                    busqueda = ""
                } label: {
                    EtiquetaBotonAlta(icono: "xmark.circle.fill", texto: "Borrar búsqueda")
                }
                .buttonStyle(BotonPrimario())
            } else {
                Button {
                    filtro = .todos
                } label: {
                    EtiquetaBotonAlta(icono: "pawprint", texto: "Ver todos los cerdos")
                }
                .buttonStyle(BotonPrimario())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private var mensajeSinResultados: String {
        if !terminoBusqueda.isEmpty {
            return "No encontré ningún cerdo con “\(busqueda.trimmingCharacters(in: .whitespacesAndNewlines))”"
        }
        switch filtro {
        case .venta:   return "No hay cerdos en venta"
        case .crianza: return "No hay cerdos de crianza"
        case .todos:   return "No hay cerdos que mostrar"
        }
    }

    // MARK: Botón flotante y aviso

    private var botonAgregar: some View {
        Button {
            mostrandoAlta = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                Text("Agregar cerdo")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .frame(height: 56)
            .background(Capsule().fill(Tema.verde))
            .shadow(color: Color.black.opacity(0.22), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Agregar cerdo")
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }

    private func bannerDeAviso(_ texto: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .accessibilityHidden(true)
            Text(texto)
                .font(.system(size: 17, weight: .bold))
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Capsule().fill(Tema.verde))
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.top, 8)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
    }

    private func mostrarAviso(_ texto: String) {
        withAnimation(.easeOut(duration: 0.25)) { aviso = texto }
        UIAccessibility.post(notification: .announcement, argument: texto)
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeIn(duration: 0.25)) {
                if aviso == texto { aviso = nil }
            }
        }
    }
}

// MARK: - Tarjeta de un cerdo

private struct TarjetaCerdo: View {
    let animal: Animal

    private var enVenta: Bool { animal.destino == .venta }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay { FotoAnimal(animal: animal, radio: 12) }
                .overlay(alignment: .topLeading) {
                    if enVenta { cintaVenta }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(animal.arete)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 8) {
                ChipRaza(raza: animal.raza)
                Spacer(minLength: 0)
                Text("\(textoDeKilos(animal.pesoKg)) kg")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Tema.superficie)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Tema.linea, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(animal.arete), \(animal.raza.rawValue), \(textoDeKilos(animal.pesoKg)) kilos\(enVenta ? ", en venta" : "")")
        .accessibilityHint("Abre la ficha del cerdo")
    }

    private var cintaVenta: some View {
        Text("Venta")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0,
                                       bottomTrailingRadius: 12, topTrailingRadius: 0,
                                       style: .continuous)
                    .fill(Tema.terracota)
            )
    }
}

// MARK: - Formulario para agregar un cerdo

private struct HojaAltaCerdo: View {
    let sugerencia: String
    let alGuardar: (String) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var arete: String
    @State private var raza: Raza = .comun
    @State private var sexo: Sexo = .hembra
    @State private var peso: String = ""
    @State private var destino: Destino = .crianza
    @State private var itemFoto: PhotosPickerItem? = nil
    @State private var datosFoto: Data? = nil
    @State private var vistaPreviaFoto: UIImage? = nil
    @FocusState private var campo: Campo?

    private enum Campo { case arete, peso }

    init(sugerencia: String, alGuardar: @escaping (String) -> Void) {
        _arete = State(initialValue: sugerencia)
        self.sugerencia = sugerencia
        self.alGuardar = alGuardar
    }

    /// Tope de sentido común: evita pesos absurdos (y números que rompan otras pantallas).
    private let pesoMaximo: Double = 5_000

    private var areteLimpio: String {
        arete.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var pesoKg: Double {
        let valor = Double(peso.replacingOccurrences(of: ",", with: ".")) ?? 0
        return valor.isFinite ? valor : 0
    }

    private var pesoDemasiado: Bool { pesoKg > pesoMaximo }

    private var puedeGuardar: Bool {
        !areteLimpio.isEmpty && pesoKg > 0 && !pesoDemasiado
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TituloPantalla(titulo: "Agregar cerdo",
                                   subtitulo: "Llena los datos del cerdo nuevo")

                    seccionArete
                    seccionRaza
                    seccionSexo
                    seccionPeso
                    seccionDestino
                    seccionFoto
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { Tema.fondo.ignoresSafeArea() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { campo = nil }
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .safeAreaInset(edge: .bottom) { barraGuardar }
        }
        .tint(Tema.verde)
        .onChange(of: itemFoto) { _, nuevo in
            guard let nuevo else { return }
            Task {
                if let datos = try? await nuevo.loadTransferable(type: Data.self),
                   let listo = prepararFotoDeCerdo(datos) {
                    datosFoto = listo
                    vistaPreviaFoto = UIImage(data: listo)
                }
            }
        }
    }

    // MARK: Secciones

    private var seccionArete: some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(texto: "Arete", icono: "tag")
            TextField(sugerencia, text: $arete)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Tema.tinta)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .submitLabel(.done)
                .focused($campo, equals: .arete)
                .onSubmit { campo = nil }
                .padding(.horizontal, 16)
                .frame(minHeight: 56)
                .background(cajaDeCampo)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded { campo = .arete })
            Text("Te sugerimos el siguiente número. Puedes cambiarlo.")
                .font(.system(size: 15))
                .foregroundStyle(Tema.secundario)
        }
    }

    private var seccionRaza: some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(texto: "Raza", icono: "pawprint")
            HStack(spacing: 10) {
                ForEach(Raza.allCases) { opcion in
                    let elegida = raza == opcion
                    Button {
                        raza = opcion
                    } label: {
                        VStack(spacing: 8) {
                            AvatarCerdo(raza: opcion)
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            Text(opcion.rawValue)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Tema.tinta)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Tema.superficie)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(elegida ? Tema.verde : Tema.linea, lineWidth: elegida ? 3 : 1)
                        )
                        .overlay(alignment: .topTrailing) {
                            if elegida {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Tema.verde, Color.white)
                                    .padding(6)
                                    .accessibilityHidden(true)
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(opcion.rawValue)
                    .accessibilityAddTraits(elegida ? .isSelected : [])
                }
            }
        }
    }

    private var seccionSexo: some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(texto: "Sexo", icono: "person.2")
            HStack(spacing: 10) {
                ForEach(Sexo.allCases) { opcion in
                    OpcionGrandeAlta(titulo: opcion.rawValue, icono: "circle", activa: sexo == opcion) {
                        sexo = opcion
                    }
                }
            }
        }
    }

    private var seccionPeso: some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(texto: "Peso", icono: "scalemass")
            HStack(spacing: 8) {
                TextField("0", text: $peso)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .keyboardType(.decimalPad)
                    .focused($campo, equals: .peso)
                Text("kg")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Tema.secundario)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .background(cajaDeCampo)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { campo = .peso })

            if pesoDemasiado {
                Text("Revisa el peso: el máximo es \(textoDeKilos(pesoMaximo)) kg")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Tema.pendienteTexto)
            }
        }
    }

    private var seccionDestino: some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(texto: "Destino", icono: "signpost.right")
            HStack(spacing: 10) {
                OpcionGrandeAlta(titulo: "Crianza", icono: "heart", activa: destino == .crianza) {
                    destino = .crianza
                }
                OpcionGrandeAlta(titulo: "Venta", icono: "tag", activa: destino == .venta) {
                    destino = .venta
                }
            }
        }
    }

    private var seccionFoto: some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(texto: "Foto", icono: "photo")
            PhotosPicker(selection: $itemFoto, matching: .images) {
                if let vistaPreviaFoto {
                    Image(uiImage: vistaPreviaFoto)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                Text("Cambiar foto")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(Tema.superficie))
                            .padding(12)
                        }
                } else {
                    HStack(spacing: 14) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Tema.verde)
                            .frame(width: 64, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Tema.exitoFondo)
                            )
                        Text("Agregar una foto")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Tema.inactivo)
                    }
                    .padding(12)
                    .frame(minHeight: 88)
                    .background(cajaDeCampo)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(vistaPreviaFoto == nil ? "Agregar una foto" : "Cambiar foto")
            Text("La foto es opcional. Sin foto se muestra el dibujo de la raza.")
                .font(.system(size: 15))
                .foregroundStyle(Tema.secundario)
        }
    }

    // MARK: Guardar

    private var barraGuardar: some View {
        VStack(spacing: 0) {
            Button {
                guardar()
            } label: {
                EtiquetaBotonAlta(icono: "checkmark.circle.fill", texto: "Guardar cerdo")
            }
            .buttonStyle(BotonPrimario())
            .disabled(!puedeGuardar)
            .opacity(puedeGuardar ? 1 : 0.45)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Tema.fondo.opacity(0.96).ignoresSafeArea(edges: .bottom))
    }

    private func guardar() {
        guard puedeGuardar else { return }
        let nuevo = Animal(arete: areteLimpio, raza: raza, sexo: sexo,
                           pesoKg: pesoKg, destino: destino)
        nuevo.foto = datosFoto
        modelContext.insert(nuevo)
        try? modelContext.save()
        alGuardar(areteLimpio)
        dismiss()
    }

    private var cajaDeCampo: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Tema.superficie)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Tema.linea, lineWidth: 1)
            )
    }
}

// MARK: - Piezas de apoyo

/// Etiqueta de botón grande (56 pt) con icono y verbo claro.
private struct EtiquetaBotonAlta: View {
    let icono: String
    let texto: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 20, weight: .semibold))
                .accessibilityHidden(true)
            Text(texto)
                .font(.system(size: 18, weight: .bold))
        }
        .frame(maxWidth: .infinity, minHeight: 56)
    }
}

/// Botón de elección grande: el elegido se pinta de verde y muestra una palomita.
private struct OpcionGrandeAlta: View {
    let titulo: String
    let icono: String
    let activa: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 10) {
                Image(systemName: activa ? "checkmark.circle.fill" : icono)
                    .font(.system(size: 20, weight: .semibold))
                    .accessibilityHidden(true)
                Text(titulo)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(activa ? Color.white : Tema.tinta)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(activa ? Tema.verde : Tema.superficie)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(activa ? Tema.verde : Tema.linea, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titulo)
        .accessibilityAddTraits(activa ? .isSelected : [])
    }
}

/// "96" si es entero, "96.5" o "96.25" si tiene decimales (hasta 2), sin separador de miles.
private func textoDeKilos(_ valor: Double) -> String {
    guard valor.isFinite else { return "0" }
    var texto = String(format: "%.2f", (valor * 100).rounded() / 100)
    while texto.hasSuffix("0") { texto.removeLast() }
    if texto.hasSuffix(".") { texto.removeLast() }
    return texto
}

/// Reduce la foto a 1200 px por lado y la guarda como JPEG para que la app siga ligera.
func prepararFotoDeCerdo(_ datos: Data, ladoMaximo: CGFloat = 1200) -> Data? {
    guard let original = UIImage(data: datos) else { return nil }
    let ladoMayor = max(original.size.width, original.size.height)
    guard ladoMayor > 0 else { return nil }
    let escala = ladoMayor > ladoMaximo ? ladoMaximo / ladoMayor : 1
    let tamano = CGSize(width: max(1, (original.size.width * escala).rounded()),
                        height: max(1, (original.size.height * escala).rounded()))
    let formato = UIGraphicsImageRendererFormat.default()
    formato.scale = 1
    let imagen = UIGraphicsImageRenderer(size: tamano, format: formato).image { _ in
        original.draw(in: CGRect(origin: .zero, size: tamano))
    }
    return imagen.jpegData(compressionQuality: 0.8)
}

// MARK: - Vista previa

private struct VistaPreviaAnimales: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VistaAnimales()
            .onAppear { DatosIniciales.sembrarSiHaceFalta(modelContext) }
    }
}

#Preview {
    VistaPreviaAnimales()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                              VisitaVeterinario.self, Pedido.self], inMemory: true)
}
