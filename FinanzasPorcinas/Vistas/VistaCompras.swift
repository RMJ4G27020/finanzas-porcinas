import SwiftUI
import SwiftData

/// "¿A quién le compro más barato?"
/// Se presenta empujada desde Dinero, por eso no lleva NavigationStack propio.
struct VistaCompras: View {
    @Query(sort: [SortDescriptor(\Compra.fecha, order: .reverse)]) private var compras: [Compra]

    @State private var mostrandoFormulario = false
    @State private var aviso: String?
    @State private var cambiosGuardados = 0

    // MARK: - Datos derivados (calculados en Swift, no en @Query)

    /// Precio más reciente por bulto de cada proveedor de alimento, de menor a mayor.
    /// Solo cuentan las compras de alimento por bulto: un precio por pieza no se compara con uno por bulto.
    /// `compras` ya viene de la más reciente a la más antigua.
    private var preciosDeAlimento: [ComprasPrecioProveedor] {
        var proveedoresVistos = Set<String>()
        var recientes: [ComprasPrecioProveedor] = []
        for compra in compras where comprasEsAlimento(compra) && comprasEsBulto(compra) {
            let nombre = compra.proveedor.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !nombre.isEmpty, proveedoresVistos.insert(nombre.lowercased()).inserted else { continue }
            recientes.append(ComprasPrecioProveedor(proveedor: nombre,
                                                    precio: compra.precioUnitario))
        }
        return recientes.sorted { $0.precio < $1.precio }
    }

    private var precioMasBajo: Double { preciosDeAlimento.map(\.precio).min() ?? 0 }
    private var precioMasAlto: Double { preciosDeAlimento.map(\.precio).max() ?? 0 }

    /// Solo se marca "Más barato" cuando hay con quién comparar y los precios no son iguales.
    private func esMasBarato(_ fila: ComprasPrecioProveedor) -> Bool {
        preciosDeAlimento.count > 1
        && precioMasBajo < precioMasAlto
        && fila.precio == precioMasBajo
    }

    // MARK: - Cuerpo

    var body: some View {
        ZStack {
            Tema.fondo.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    tarjetaComparacion
                    TituloSeccion(texto: "Últimas compras", icono: "clock")
                    listaDeCompras
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { barraRegistrar }
        .overlay(alignment: .top) {
            if let aviso {
                ComprasAviso(texto: aviso)
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
        .navigationTitle("Compras")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Tema.fondo, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $mostrandoFormulario) {
            ComprasFormulario { compra in
                cambiosGuardados += 1
                let texto = "Compra guardada: \(compra.concepto), \(pesos(compra.total))"
                withAnimation(.spring(duration: 0.3)) { aviso = texto }
                AccessibilityNotification.Announcement(texto).post()
            }
        }
    }

    // MARK: - 1. ¿Quién está más barato?

    private var tarjetaComparacion: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 16) {
                Text("Alimento por bulto, ¿quién está más barato?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if preciosDeAlimento.isEmpty {
                    HStack(spacing: 14) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 28))
                            .foregroundStyle(Tema.verde)
                            .accessibilityHidden(true)
                        Text("Registra una compra de alimento por bulto y aquí verás quién te lo vende más barato.")
                            .font(.system(size: 17))
                            .foregroundStyle(Tema.secundario)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    ForEach(preciosDeAlimento, id: \.proveedor) { fila in
                        filaProveedor(fila)
                    }

                    Text("Los precios varían según el proveedor")
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                }
            }
            .padding(4)
        }
    }

    private func filaProveedor(_ fila: ComprasPrecioProveedor) -> some View {
        let barato = esMasBarato(fila)
        let fraccion = precioMasAlto > 0 ? fila.precio / precioMasAlto : 0

        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(fila.proveedor)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Tema.tinta)
                    if barato {
                        ComprasFichaBarato()
                    }
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Tema.neutroFondo)
                        Capsule()
                            .fill(barato ? Tema.verde : Tema.inactivo)
                            .frame(width: max(g.size.width * fraccion, 10))
                    }
                }
                .frame(height: 16)
                .accessibilityHidden(true)
            }

            Text(pesos(fila.precio))
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Tema.tinta)
                .frame(minWidth: 64, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(fila.proveedor), \(pesos(fila.precio)) por bulto\(barato ? ", el más barato" : "")")
    }

    // MARK: - 2. Últimas compras

    @ViewBuilder
    private var listaDeCompras: some View {
        if compras.isEmpty {
            Tarjeta {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Tema.neutroFondo).frame(width: 88, height: 88)
                        Image(systemName: "shippingbox")
                            .font(.system(size: 38))
                            .foregroundStyle(Tema.verde)
                    }
                    .accessibilityHidden(true)
                    Text("Todavía no has registrado compras")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                        .multilineTextAlignment(.center)
                    Text("Toca «Registrar compra» para anotar la primera.")
                        .font(.system(size: 17))
                        .foregroundStyle(Tema.secundario)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)
            }
        } else {
            ForEach(compras, id: \.persistentModelID) { compra in
                ComprasTarjeta(compra: compra)
            }
        }
    }

    // MARK: - Botón fijo

    private var barraRegistrar: some View {
        Button {
            mostrandoFormulario = true
        } label: {
            ComprasEtiquetaBoton(icono: "plus", titulo: "Registrar compra")
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
}

/// Precio vigente de un proveedor de alimento.
private struct ComprasPrecioProveedor {
    let proveedor: String
    let precio: Double
}

// MARK: - Piezas pequeñas

private struct ComprasFichaBarato: View {
    var body: some View {
        Text("Más barato")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Tema.exitoTexto)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Tema.exitoFondo))
    }
}

private struct ComprasEtiquetaBoton: View {
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

private struct ComprasAviso: View {
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

/// Texto de cantidad sin ceros de más: "4", "2.5" o "0.25".
private func comprasNumero(_ valor: Double) -> String {
    valor.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "es_MX")))
}

/// El concepto "Alimento", sin importar mayúsculas ni espacios de más.
private func comprasEsAlimento(_ compra: Compra) -> Bool {
    compra.concepto.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "alimento"
}

private func comprasEsBulto(_ compra: Compra) -> Bool {
    compra.unidad.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "bulto"
}

/// "4 bultos × $485"
private func comprasCuenta(cantidad: Double, unidad: String, precio: Double) -> String {
    let plural = cantidad == 1 ? unidad : unidad + "s"
    return "\(comprasNumero(cantidad)) \(plural) × \(pesos(precio))"
}

// MARK: - Tarjeta de una compra

private struct ComprasTarjeta: View {
    let compra: Compra

    @ScaledMetric(relativeTo: .title3) private var tTotal: CGFloat = 22

    private var esAlimento: Bool { comprasEsAlimento(compra) }

    var body: some View {
        Tarjeta {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle().fill(esAlimento ? Tema.exitoFondo : Tema.pendienteFondo)
                    Image(systemName: esAlimento ? "shippingbox" : "cross.case")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(esAlimento ? Tema.exitoTexto : Tema.pendienteTexto)
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(compra.concepto)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                    Text("\(compra.proveedor) · \(fechaCorta(compra.fecha))")
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                    Text(comprasCuenta(cantidad: compra.cantidad, unidad: compra.unidad, precio: compra.precioUnitario))
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                }

                Spacer(minLength: 8)

                Text(pesos(compra.total))
                    .font(.system(size: tTotal, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(2)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "\(compra.concepto), \(compra.proveedor), \(fechaCorta(compra.fecha)). \(comprasCuenta(cantidad: compra.cantidad, unidad: compra.unidad, precio: compra.precioUnitario)). Total \(pesos(compra.total))."
            )
        }
    }
}

// MARK: - Formulario "Registrar compra"

private enum ComprasUnidad: String, CaseIterable, Identifiable {
    case bulto, pieza
    var id: String { rawValue }
    var nombre: String { self == .bulto ? "Bulto" : "Pieza" }
    var icono: String { self == .bulto ? "shippingbox" : "cube" }
}

private enum ComprasCampo: Hashable {
    case concepto, proveedor, cantidad, precio
}

private struct ComprasFormulario: View {
    let alGuardar: (Compra) -> Void

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @Query(sort: [SortDescriptor(\Compra.fecha, order: .reverse)]) private var compras: [Compra]

    @State private var fecha = Date()
    @State private var concepto = ""
    @State private var proveedor = ""
    @State private var cantidadTexto = ""
    @State private var unidad: ComprasUnidad = .bulto
    @State private var precioTexto = ""
    @FocusState private var campo: ComprasCampo?

    @ScaledMetric(relativeTo: .largeTitle) private var tTotal: CGFloat = 40

    // MARK: Datos

    private var cantidad: Double? { Self.numero(cantidadTexto) }
    private var precioUnitario: Double? { Self.numero(precioTexto) }

    private var conceptoLimpio: String { concepto.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var proveedorLimpio: String { proveedor.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Lo primero que falta, dicho en palabras de campo. Nil si ya se puede guardar.
    private var faltante: String? {
        if conceptoLimpio.isEmpty { return "Escribe qué compraste." }
        if proveedorLimpio.isEmpty { return "Escribe a quién se la compraste." }
        if (cantidad ?? 0) <= 0 { return "Anota cuánto compraste." }
        if (precioUnitario ?? 0) <= 0 { return "Anota a cómo te la vendieron." }
        return nil
    }

    private var sePuedeGuardar: Bool { faltante == nil }

    private var total: Double { (cantidad ?? 0) * (precioUnitario ?? 0) }

    /// Lo ya comprado, para tocar en lugar de escribir. "Alimento" siempre aparece primero.
    private var conceptosConocidos: [String] {
        Self.unicos(["Alimento"] + compras.map(\.concepto))
    }
    private var proveedoresConocidos: [String] {
        Self.unicos(compras.map(\.proveedor))
    }

    // MARK: Cuerpo

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        encabezado
                        bloqueFecha
                        bloqueConcepto
                        bloqueProveedor
                        bloqueCantidad
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
                    Button("Listo") { campo = nil }
                        .font(.system(size: 17, weight: .bold))
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Bloques

    private var encabezado: some View {
        HStack(alignment: .top, spacing: 12) {
            TituloPantalla(titulo: "Registrar compra", subtitulo: "Anota lo que compraste")
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
        Tarjeta {
            HStack {
                Text("¿Cuándo fue?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Spacer(minLength: 8)
                DatePicker("Fecha de la compra", selection: $fecha, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Tema.verde)
                    .environment(\.locale, Locale(identifier: "es_MX"))
            }
            .frame(minHeight: 44)
        }
    }

    private var bloqueConcepto: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "¿Qué compraste?")
            cajaDeTexto(.concepto, ejemplo: "Alimento", texto: $concepto)
            fichas(conceptosConocidos, elegido: concepto) { concepto = $0; campo = nil }
        }
    }

    private var bloqueProveedor: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "¿A quién se la compraste?")
            cajaDeTexto(.proveedor, ejemplo: "Nombre del proveedor", texto: $proveedor)
            if !proveedoresConocidos.isEmpty {
                fichas(proveedoresConocidos, elegido: proveedor) { proveedor = $0; campo = nil }
            }
        }
    }

    private var bloqueCantidad: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "¿Cuánto compraste?")
            cajaDeTexto(.cantidad, ejemplo: "0", texto: $cantidadTexto, numerico: true, sufijo: unidad.rawValue + "s")
            HStack(spacing: 12) {
                ForEach(ComprasUnidad.allCases) { opcion in
                    let activo = unidad == opcion
                    Button {
                        campo = nil
                        unidad = opcion
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: opcion.icono)
                                .font(.system(size: 22, weight: .semibold))
                                .accessibilityHidden(true)
                            Text(opcion.nombre)
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundStyle(activo ? Tema.superficie : Tema.tinta)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(
                            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                                .fill(activo ? Tema.verde : Tema.superficie)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                                .stroke(activo ? Tema.verde : Tema.linea, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(opcion.nombre)
                    .accessibilityAddTraits(activo ? .isSelected : [])
                }
            }
        }
    }

    private var bloquePrecio: some View {
        VStack(alignment: .leading, spacing: 12) {
            TituloSeccion(texto: "¿A cómo te la vendieron?")
            cajaDeTexto(.precio, ejemplo: "0", texto: $precioTexto, numerico: true,
                        prefijo: "$", sufijo: "por \(unidad.rawValue)")
        }
    }

    private var bloqueTotal: some View {
        Tarjeta {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total de la compra")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Tema.secundario)
                Text(pesos(total))
                    .font(.system(size: tTotal, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Tema.tinta)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let cantidad, let precioUnitario, cantidad > 0, precioUnitario > 0 {
                    Text(comprasCuenta(cantidad: cantidad, unidad: unidad.rawValue, precio: precioUnitario))
                        .font(.system(size: 17))
                        .foregroundStyle(Tema.secundario)
                } else {
                    Text("Anota cuánto y a cómo para ver el total")
                        .font(.system(size: 17))
                        .foregroundStyle(Tema.secundario)
                }
            }
            .padding(4)
            .accessibilityElement(children: .combine)
        }
    }

    private var barraGuardar: some View {
        VStack(spacing: 8) {
            if let faltante {
                Text(faltante)
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            }
            Button {
                guardar()
            } label: {
                ComprasEtiquetaBoton(icono: "checkmark", titulo: "Guardar compra")
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

    // MARK: Controles

    private func cajaDeTexto(_ id: ComprasCampo, ejemplo: String, texto: Binding<String>,
                             numerico: Bool = false, prefijo: String? = nil,
                             sufijo: String? = nil) -> some View {
        let enfocado = campo == id
        return HStack(spacing: 8) {
            if let prefijo {
                Text(prefijo)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Tema.secundario)
                    .accessibilityHidden(true)
            }
            TextField(ejemplo, text: texto)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Tema.tinta)
                .keyboardType(numerico ? .decimalPad : .default)
                .textInputAutocapitalization(numerico ? TextInputAutocapitalization.never : TextInputAutocapitalization.sentences)
                .focused($campo, equals: id)
            if let sufijo {
                Text(sufijo)
                    .font(.system(size: 17))
                    .foregroundStyle(Tema.secundario)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                .fill(Tema.superficie)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Tema.radioControl, style: .continuous)
                .stroke(enfocado ? Tema.verde : Tema.linea, lineWidth: enfocado ? 3 : 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture { campo = id }
    }

    /// Fila de opciones ya usadas: un toque llena el campo.
    private func fichas(_ opciones: [String], elegido: String,
                        alElegir: @escaping (String) -> Void) -> some View {
        let actual = elegido.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(opciones, id: \.self) { opcion in
                    let activo = opcion.lowercased() == actual
                    Button {
                        alElegir(opcion)
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

    // MARK: Guardar

    private func guardar() {
        guard let cantidad, let precioUnitario, sePuedeGuardar else { return }
        let compra = Compra(
            fecha: fecha,
            concepto: conceptoLimpio,
            proveedor: proveedorLimpio,
            cantidad: cantidad,
            unidad: unidad.rawValue,
            precioUnitario: precioUnitario
        )
        contexto.insert(compra)
        try? contexto.save()
        alGuardar(compra)
        cerrar()
    }

    private static func numero(_ texto: String) -> Double? {
        let limpio = texto
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let valor = Double(limpio), valor.isFinite else { return nil }
        return valor
    }

    /// Valores sin repetir (sin distinguir mayúsculas), en el orden en que aparecen.
    private static func unicos(_ valores: [String]) -> [String] {
        var vistos = Set<String>()
        var resultado: [String] = []
        for valor in valores {
            let limpio = valor.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !limpio.isEmpty, vistos.insert(limpio.lowercased()).inserted else { continue }
            resultado.append(limpio)
        }
        return resultado
    }
}

#Preview {
    NavigationStack {
        VistaCompras()
    }
    .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                          VisitaVeterinario.self, Pedido.self], inMemory: true)
}
