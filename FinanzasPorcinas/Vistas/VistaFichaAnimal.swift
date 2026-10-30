import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - Ficha de un cerdo

struct VistaFichaAnimal: View {
    @Bindable var animal: Animal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var itemFoto: PhotosPickerItem? = nil
    @State private var mostrandoPeso: Bool = false
    @State private var mostrandoVenta: Bool = false
    @State private var confirmandoQuitar: Bool = false
    @State private var quitado: Bool = false
    @State private var aviso: String? = nil
    @State private var notaAlEmpezar: String = ""
    @FocusState private var escribiendoNota: Bool

    private var enVenta: Bool { animal.destino == .venta }

    var body: some View {
        Group {
            if quitado {
                Tema.fondo.ignoresSafeArea()
            } else {
                contenido
            }
        }
        .navigationTitle(quitado ? "" : animal.arete)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Tema.fondo, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var contenido: some View {
        ScrollView {
            VStack(spacing: 0) {
                fotoGrande

                VStack(alignment: .leading, spacing: 16) {
                    encabezado
                    tresDatos
                    botones
                    notas
                    botonQuitar
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background { Tema.fondo.ignoresSafeArea() }
        .overlay(alignment: .top) {
            if let aviso { bannerDeAviso(aviso) }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { escribiendoNota = false }
                    .font(.system(size: 17, weight: .bold))
            }
        }
        .sheet(isPresented: $mostrandoPeso) {
            HojaPesoFicha(animal: animal) { nuevoPeso in
                mostrarAviso("Peso guardado: \(kilosComoTexto(nuevoPeso)) kg")
            }
        }
        .sheet(isPresented: $mostrandoVenta) {
            HojaVentaFicha(animal: animal) { total in
                mostrarAviso("Venta guardada: \(pesos(total))")
            }
        }
        .onChange(of: itemFoto) { _, nuevo in
            guard let nuevo else { return }
            Task {
                if let datos = try? await nuevo.loadTransferable(type: Data.self),
                   let listo = prepararFotoDeCerdo(datos) {
                    animal.foto = listo
                    try? modelContext.save()
                    mostrarAviso("Foto guardada")
                }
                itemFoto = nil
            }
        }
        .onChange(of: escribiendoNota) { _, escribiendo in
            if escribiendo {
                notaAlEmpezar = animal.notas
            } else {
                try? modelContext.save()
                if animal.notas != notaAlEmpezar { mostrarAviso("Nota guardada") }
            }
        }
        .onDisappear {
            // Si se sale con el teclado abierto, la nota también queda guardada.
            if !quitado { try? modelContext.save() }
        }
    }

    // MARK: Foto grande

    private var fotoGrande: some View {
        ZStack(alignment: .bottomTrailing) {
            FotoAnimal(animal: animal, radio: 0)
                .frame(maxWidth: .infinity)
                .frame(height: 280)

            HStack(spacing: 8) {
                if animal.foto != nil {
                    Button {
                        animal.foto = nil
                        try? modelContext.save()
                        mostrarAviso("Foto quitada")
                    } label: {
                        etiquetaSobreFoto(icono: "trash", texto: "Quitar foto", color: Tema.terracota)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quitar foto")
                }

                PhotosPicker(selection: $itemFoto, matching: .images) {
                    etiquetaSobreFoto(icono: "camera.fill", texto: "Cambiar foto", color: Tema.tinta)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cambiar foto")
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 28,
                                          bottomTrailingRadius: 28, topTrailingRadius: 0,
                                          style: .continuous))
    }

    private func etiquetaSobreFoto(icono: String, texto: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icono)
                .accessibilityHidden(true)
            Text(texto)
        }
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .background(Capsule().fill(Tema.superficie))
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
    }

    // MARK: Nombre y chips

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(animal.arete)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 8) {
                ChipRaza(raza: animal.raza)
                EtiquetaFicha(texto: animal.sexo.rawValue, estilo: .neutro)
                EtiquetaFicha(texto: animal.destino.rawValue, estilo: enVenta ? .pendiente : .exito)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Tres tarjetas

    private var tresDatos: some View {
        HStack(spacing: 12) {
            datoGrande(icono: "scalemass", valor: "\(kilosComoTexto(animal.pesoKg)) kg", etiqueta: "Peso")
            datoGrande(icono: enVenta ? "tag" : "heart", valor: animal.destino.rawValue, etiqueta: "Destino")
            datoGrande(icono: "pawprint", valor: animal.raza.rawValue, etiqueta: "Raza")
        }
    }

    private func datoGrande(icono: String, valor: String, etiqueta: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icono)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Tema.verde)
                .accessibilityHidden(true)
            Text(valor)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Tema.tinta)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(etiqueta)
                .font(.system(size: 13))
                .foregroundStyle(Tema.secundario)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Tema.superficie)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Tema.linea, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(etiqueta): \(valor)")
    }

    // MARK: Botones grandes

    private var botones: some View {
        VStack(spacing: 12) {
            if enVenta {
                Button {
                    mostrandoVenta = true
                } label: {
                    EtiquetaBotonFicha(icono: "banknote", texto: "Vender este cerdo")
                }
                .buttonStyle(BotonPrimario())
            }

            if enVenta {
                Button {
                    mostrandoPeso = true
                } label: {
                    EtiquetaBotonFicha(icono: "scalemass", texto: "Actualizar peso")
                }
                .buttonStyle(BotonSecundario())
            } else {
                Button {
                    mostrandoPeso = true
                } label: {
                    EtiquetaBotonFicha(icono: "scalemass", texto: "Actualizar peso")
                }
                .buttonStyle(BotonPrimario())
            }

            Button {
                cambiarDestino()
            } label: {
                EtiquetaBotonFicha(icono: "arrow.triangle.2.circlepath",
                                   texto: enVenta ? "Cambiar a Crianza" : "Cambiar a Venta")
            }
            .buttonStyle(BotonSecundario())
        }
    }

    private func cambiarDestino() {
        animal.destino = enVenta ? .crianza : .venta
        try? modelContext.save()
        mostrarAviso("\(animal.arete) ahora está en \(animal.destino.rawValue)")
    }

    // MARK: Notas

    private var notas: some View {
        VStack(alignment: .leading, spacing: 10) {
            TituloSeccion(texto: "Notas", icono: "note.text")
            TextField("Escribe aquí lo que quieras recordar de este cerdo",
                      text: $animal.notas, axis: .vertical)
                .font(.system(size: 17))
                .foregroundStyle(Tema.tinta)
                .lineLimit(3...8)
                .focused($escribiendoNota)
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Tema.superficie)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Tema.linea, lineWidth: 1)
                )
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded { escribiendoNota = true })
        }
        .padding(.top, 8)
    }

    // MARK: Quitar de la lista

    private var botonQuitar: some View {
        Button {
            confirmandoQuitar = true
        } label: {
            EtiquetaBotonFicha(icono: "trash", texto: "Quitar de la lista", color: Tema.terracota)
        }
        .buttonStyle(BotonSecundario())
        .padding(.top, 16)
        .confirmationDialog("¿Quitar a \(animal.arete) de la lista?",
                            isPresented: $confirmandoQuitar,
                            titleVisibility: .visible) {
            Button("Quitar de la lista", role: .destructive) { quitarDeLaLista() }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Ya no aparecerá en Mis cerdos.")
        }
    }

    /// Primero se cierra la ficha y después se borra el cerdo, para que ninguna
    /// pantalla intente leer un cerdo que ya no existe.
    private func quitarDeLaLista() {
        let contexto = modelContext
        let cerdo = animal
        quitado = true
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            contexto.delete(cerdo)
            try? contexto.save()
        }
    }

    // MARK: Aviso de confirmación

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

// MARK: - Hoja: actualizar peso

private struct HojaPesoFicha: View {
    let animal: Animal
    let alGuardar: (Double) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var peso: String
    @FocusState private var enfocado: Bool

    init(animal: Animal, alGuardar: @escaping (Double) -> Void) {
        self.animal = animal
        self.alGuardar = alGuardar
        _peso = State(initialValue: kilosComoTexto(animal.pesoKg))
    }

    private var pesoLeido: Double { leerKilos(peso) }

    private var pesoDemasiado: Bool { pesoLeido > kilosMaximosPorCerdo }

    /// Peso válido para guardar; 0 si falta o es demasiado grande.
    private var pesoNuevo: Double { pesoDemasiado ? 0 : pesoLeido }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    cabeceraDelCerdo(animal, detalle: "Peso actual: \(kilosComoTexto(animal.pesoKg)) kg")

                    VStack(alignment: .leading, spacing: 10) {
                        TituloSeccion(texto: "¿Cuánto pesa ahora?", icono: "scalemass")
                        HStack(spacing: 8) {
                            TextField("0", text: $peso)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(Tema.tinta)
                                .keyboardType(.decimalPad)
                                .focused($enfocado)
                            Text("kg")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Tema.secundario)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Tema.superficie)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Tema.linea, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .simultaneousGesture(TapGesture().onEnded { enfocado = true })

                        if pesoDemasiado { AvisoKilosDemasiados() }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { Tema.fondo.ignoresSafeArea() }
            .navigationTitle("Actualizar peso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { enfocado = false }
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    guardar()
                } label: {
                    EtiquetaBotonFicha(icono: "checkmark.circle.fill", texto: "Guardar peso")
                }
                .buttonStyle(BotonPrimario())
                .disabled(pesoNuevo <= 0)
                .opacity(pesoNuevo > 0 ? 1 : 0.45)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Tema.fondo.opacity(0.96).ignoresSafeArea(edges: .bottom))
            }
        }
        .tint(Tema.verde)
        .presentationDetents([.large])
    }

    private func guardar() {
        guard pesoNuevo > 0 else { return }
        animal.pesoKg = pesoNuevo
        try? modelContext.save()
        alGuardar(pesoNuevo)
        dismiss()
    }
}

// MARK: - Hoja: vender este cerdo

private struct HojaVentaFicha: View {
    let animal: Animal
    let alVender: (Double) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var kilosTexto: String
    @State private var precio: PrecioKg? = nil
    @FocusState private var enfocado: Bool

    init(animal: Animal, alVender: @escaping (Double) -> Void) {
        self.animal = animal
        self.alVender = alVender
        _kilosTexto = State(initialValue: kilosComoTexto(animal.pesoKg))
    }

    private var kilosLeidos: Double { leerKilos(kilosTexto) }

    private var kilosDemasiados: Bool { kilosLeidos > kilosMaximosPorCerdo }

    /// Kilos válidos para vender; 0 si faltan o son demasiados.
    private var kilos: Double { kilosDemasiados ? 0 : kilosLeidos }

    private var total: Double { kilos * (precio?.rawValue ?? 0) }

    private var puedeVender: Bool { kilos > 0 && precio != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    cabeceraDelCerdo(animal, detalle: "Pesa \(kilosComoTexto(animal.pesoKg)) kg")

                    VStack(alignment: .leading, spacing: 10) {
                        TituloSeccion(texto: "Kilos que se venden", icono: "scalemass")
                        HStack(spacing: 8) {
                            TextField("0", text: $kilosTexto)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Tema.tinta)
                                .keyboardType(.decimalPad)
                                .focused($enfocado)
                            Text("kg")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Tema.secundario)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Tema.superficie)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Tema.linea, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .simultaneousGesture(TapGesture().onEnded { enfocado = true })

                        if kilosDemasiados { AvisoKilosDemasiados() }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        TituloSeccion(texto: "Precio", icono: "tag")
                        HStack(spacing: 10) {
                            ForEach(PrecioKg.allCases) { opcion in
                                botonDePrecio(opcion)
                            }
                        }
                    }

                    resultado
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { Tema.fondo.ignoresSafeArea() }
            .navigationTitle("Vender este cerdo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { enfocado = false }
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    confirmar()
                } label: {
                    EtiquetaBotonFicha(icono: "checkmark.circle.fill", texto: "Confirmar venta")
                }
                .buttonStyle(BotonPrimario())
                .disabled(!puedeVender)
                .opacity(puedeVender ? 1 : 0.45)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Tema.fondo.opacity(0.96).ignoresSafeArea(edges: .bottom))
            }
        }
        .tint(Tema.verde)
        .presentationDetents([.large])
    }

    private func botonDePrecio(_ opcion: PrecioKg) -> some View {
        let activo = precio == opcion
        return Button {
            precio = opcion
        } label: {
            HStack(spacing: 8) {
                if activo {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text("\(opcion.etiqueta) por kilo")
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(activo ? Color.white : Tema.tinta)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(activo ? Tema.verde : Tema.superficie)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(activo ? Tema.verde : Tema.linea, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(opcion.etiqueta) por kilo")
        .accessibilityAddTraits(activo ? .isSelected : [])
    }

    private var resultado: some View {
        VStack(spacing: 8) {
            Text("Total de la venta")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Tema.secundario)
            if let precio {
                Text(pesos(total))
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Tema.verde)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("\(kilosComoTexto(kilos)) kg × \(pesos(precio.rawValue)) = \(pesos(total))")
                    .font(.system(size: 17))
                    .foregroundStyle(Tema.secundario)
            } else {
                Text("Elige el precio por kilo")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Tema.inactivo)
                    .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Tema.exitoFondo)
        )
        .accessibilityElement(children: .combine)
    }

    private func confirmar() {
        guard let precio, kilos > 0 else { return }
        let venta = Venta(fecha: Date(), areteAnimal: animal.arete,
                          kilos: kilos, precioPorKg: precio.rawValue)
        modelContext.insert(venta)
        try? modelContext.save()
        alVender(venta.total)
        dismiss()
    }
}

// MARK: - Piezas de apoyo

/// Etiqueta de botón grande (56 pt) con icono y verbo claro.
private struct EtiquetaBotonFicha: View {
    let icono: String
    let texto: String
    var color: Color? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 20, weight: .semibold))
                .accessibilityHidden(true)
            Text(texto)
                .font(.system(size: 18, weight: .bold))
        }
        .modifier(ColorOpcional(color: color))
        .frame(maxWidth: .infinity, minHeight: 56)
    }
}

/// Deja que el estilo del botón ponga el color, salvo que se pida uno propio.
private struct ColorOpcional: ViewModifier {
    let color: Color?

    func body(content: Content) -> some View {
        if let color {
            content.foregroundStyle(color)
        } else {
            content
        }
    }
}

/// Cabecera de las hojas: cara del cerdo, arete y un dato.
@ViewBuilder
private func cabeceraDelCerdo(_ animal: Animal, detalle: String) -> some View {
    HStack(spacing: 16) {
        FotoAnimal(animal: animal, radio: 18)
            .frame(width: 72, height: 72)
        VStack(alignment: .leading, spacing: 4) {
            Text(animal.arete)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Tema.tinta)
            Text(detalle)
                .font(.system(size: 17))
                .foregroundStyle(Tema.secundario)
        }
        Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
}

/// "96" si es entero, "96.5" o "96.25" si tiene decimales (hasta 2), sin separador de miles.
/// Así la cuenta en pantalla siempre coincide con lo que se guarda.
private func kilosComoTexto(_ valor: Double) -> String {
    guard valor.isFinite else { return "0" }
    var texto = String(format: "%.2f", (valor * 100).rounded() / 100)
    while texto.hasSuffix("0") { texto.removeLast() }
    if texto.hasSuffix(".") { texto.removeLast() }
    return texto
}

/// Tope de sentido común para el peso o los kilos de un solo cerdo.
private let kilosMaximosPorCerdo: Double = 5_000

/// Lee un número escrito con punto o coma; devuelve 0 si no es un número válido.
private func leerKilos(_ texto: String) -> Double {
    let valor = Double(texto.replacingOccurrences(of: ",", with: ".")) ?? 0
    return valor.isFinite ? valor : 0
}

/// Etiqueta redonda de 13 pt (la de Tema baja de 13).
private struct EtiquetaFicha: View {
    let texto: String
    var estilo: EstiloChip = .neutro

    var body: some View {
        Text(texto)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(estilo.texto)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(estilo.fondo))
    }
}

/// Aviso corto cuando el número escrito es demasiado grande.
private struct AvisoKilosDemasiados: View {
    var body: some View {
        Text("Revisa los kilos: el máximo es \(kilosComoTexto(kilosMaximosPorCerdo)) kg")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Tema.pendienteTexto)
    }
}

// MARK: - Vista previa

private struct VistaPreviaFicha: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Animal.arete)]) private var animales: [Animal]

    var body: some View {
        NavigationStack {
            if let cerdo = animales.first(where: { $0.destino == .venta }) ?? animales.first {
                VistaFichaAnimal(animal: cerdo)
            } else {
                Tema.fondo.ignoresSafeArea()
                    .onAppear { DatosIniciales.sembrarSiHaceFalta(modelContext) }
            }
        }
    }
}

#Preview {
    VistaPreviaFicha()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                              VisitaVeterinario.self, Pedido.self], inMemory: true)
}
