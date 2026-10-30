import SwiftUI
import SwiftData

/// Compras de insumos del criadero. Se muestra dentro de VistaFinanzas,
/// por eso no lleva NavigationStack ni título de pantalla.
struct VistaCompras: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: [SortDescriptor(\Compra.fecha, order: .reverse)]) private var compras: [Compra]

    @State private var mostrandoFormulario = false

    // MARK: - Datos derivados (calculados en Swift, no en @Query)

    /// Precio unitario más reciente de cada proveedor de alimento,
    /// de menor a mayor. `compras` ya viene de la más reciente a la más antigua.
    private var preciosDeAlimento: [PrecioProveedor] {
        var proveedoresVistos: [String] = []
        var recientes: [PrecioProveedor] = []
        for compra in compras where compra.concepto.lowercased() == "alimento" {
            guard !proveedoresVistos.contains(compra.proveedor) else { continue }
            proveedoresVistos.append(compra.proveedor)
            recientes.append(PrecioProveedor(proveedor: compra.proveedor,
                                             precio: compra.precioUnitario))
        }
        return recientes.sorted { $0.precio < $1.precio }
    }

    // MARK: - Cuerpo

    var body: some View {
        ZStack {
            Tema.fondo.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    tarjetaComparacion
                    bloqueUltimasCompras

                    Button {
                        mostrandoFormulario = true
                    } label: {
                        Label("Registrar compra", systemImage: "plus")
                    }
                    .buttonStyle(BotonPrimario())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                    .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $mostrandoFormulario) {
            FormularioCompra()
        }
    }

    // MARK: - 1. Comparador de precios

    private var tarjetaComparacion: some View {
        Tarjeta {
            EtiquetaSeccion("Comparar precio · Alimento por bulto")

            if preciosDeAlimento.isEmpty {
                Text("Todavía no hay compras de alimento registradas.")
                    .font(.system(size: 15))
                    .foregroundStyle(Tema.secundario)
            } else {
                ForEach(Array(preciosDeAlimento.enumerated()), id: \.element.proveedor) { indice, fila in
                    HStack(spacing: 8) {
                        Text(fila.proveedor)
                            .font(.system(size: 16))
                            .foregroundStyle(Tema.tinta)
                        if indice == 0 {
                            Chip(texto: "Más barato", estilo: .exito)
                        }
                        Spacer(minLength: 8)
                        Text(pesos(fila.precio))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                    }
                    .frame(minHeight: 28)
                }

                Text("Los precios varían según el proveedor")
                    .font(.system(size: 14))
                    .foregroundStyle(Tema.secundario)
            }
        }
    }

    // MARK: - 2. Últimas compras

    private var bloqueUltimasCompras: some View {
        VStack(alignment: .leading, spacing: 8) {
            EtiquetaSeccion("Últimas compras")

            Tarjeta {
                if compras.isEmpty {
                    Text("Todavía no hay compras registradas.")
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                } else {
                    ForEach(Array(compras.enumerated()), id: \.element.persistentModelID) { indice, compra in
                        if indice > 0 {
                            Divider().overlay(Tema.linea)
                        }
                        filaCompra(compra)
                    }
                }
            }
        }
    }

    private func filaCompra(_ compra: Compra) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text(diaDelMes(compra.fecha))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text(mesAbreviado(compra.fecha))
                    .font(.system(size: 12))
                    .foregroundStyle(Tema.secundario)
            }
            .frame(width: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(compra.concepto)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text(compra.detalle)
                    .font(.system(size: 14))
                    .foregroundStyle(Tema.secundario)
            }

            Spacer(minLength: 8)

            Text(pesos(compra.total))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Tema.tinta)
        }
        .frame(minHeight: 44)
    }

    // MARK: - Formato de fecha

    private func diaDelMes(_ fecha: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d"
        return f.string(from: fecha)
    }

    private func mesAbreviado(_ fecha: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "MMM"
        return f.string(from: fecha).replacingOccurrences(of: ".", with: "")
    }
}

/// Precio unitario vigente de un proveedor de alimento.
private struct PrecioProveedor {
    let proveedor: String
    let precio: Double
}

// MARK: - Formulario de alta de compra

private struct FormularioCompra: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar

    @State private var fecha = Date()
    @State private var concepto = ""
    @State private var proveedor = ""
    @State private var cantidadTexto = ""
    @State private var unidad = "bulto"
    @State private var precioTexto = ""

    private var cantidad: Double? { Self.numero(cantidadTexto) }
    private var precioUnitario: Double? { Self.numero(precioTexto) }

    private var sePuedeGuardar: Bool {
        !concepto.trimmingCharacters(in: .whitespaces).isEmpty
        && !proveedor.trimmingCharacters(in: .whitespaces).isEmpty
        && (cantidad ?? 0) > 0
        && (precioUnitario ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Tema.fondo.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Tarjeta {
                            EtiquetaSeccion("Datos de la compra")

                            DatePicker("Fecha", selection: $fecha, displayedComponents: .date)
                                .font(.system(size: 16))
                                .foregroundStyle(Tema.tinta)
                                .tint(Tema.verde)
                                .frame(minHeight: 44)

                            campo(titulo: "Concepto", ejemplo: "Alimento", texto: $concepto)
                            campo(titulo: "Proveedor", ejemplo: "Nombre del proveedor", texto: $proveedor)
                            campo(titulo: "Cantidad", ejemplo: "4", texto: $cantidadTexto, numerico: true)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Unidad")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Tema.secundario)
                                Picker("Unidad", selection: $unidad) {
                                    Text("Bulto").tag("bulto")
                                    Text("Pieza").tag("pieza")
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .frame(minHeight: 44)
                            }

                            campo(titulo: "Precio unitario", ejemplo: "485", texto: $precioTexto, numerico: true)
                        }

                        Tarjeta {
                            EtiquetaSeccion("Total de la compra")
                            Text(totalCalculado)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Tema.tinta)
                        }

                        Button("Guardar compra") { guardar() }
                            .buttonStyle(BotonPrimario())
                            .disabled(!sePuedeGuardar)
                            .opacity(sePuedeGuardar ? 1 : 0.5)

                        Button("Cancelar") { cerrar() }
                            .buttonStyle(BotonSecundario())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Registrar compra")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var totalCalculado: String {
        guard let cantidad, let precioUnitario, cantidad > 0, precioUnitario > 0 else {
            return "Captura cantidad y precio unitario"
        }
        let plural = cantidad == 1 ? unidad : unidad + "s"
        return "\(Self.sinCeros(cantidad)) \(plural) × \(pesos(precioUnitario)) = \(pesos(cantidad * precioUnitario))"
    }

    private func campo(titulo: String, ejemplo: String, texto: Binding<String>, numerico: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.system(size: 14))
                .foregroundStyle(Tema.secundario)
            TextField(ejemplo, text: texto)
                .font(.system(size: 16))
                .foregroundStyle(Tema.tinta)
                .keyboardType(numerico ? .decimalPad : .default)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: Tema.radioControl)
                        .fill(Tema.fondo)
                        .overlay(
                            RoundedRectangle(cornerRadius: Tema.radioControl)
                                .stroke(Tema.linea, lineWidth: 1)
                        )
                )
                .accessibilityLabel(titulo)
        }
    }

    private func guardar() {
        guard let cantidad, let precioUnitario, sePuedeGuardar else { return }
        let compra = Compra(
            fecha: fecha,
            concepto: concepto.trimmingCharacters(in: .whitespaces),
            proveedor: proveedor.trimmingCharacters(in: .whitespaces),
            cantidad: cantidad,
            unidad: unidad,
            precioUnitario: precioUnitario
        )
        contexto.insert(compra)
        try? contexto.save()
        cerrar()
    }

    private static func numero(_ texto: String) -> Double? {
        let limpio = texto
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(limpio)
    }

    private static func sinCeros(_ valor: Double) -> String {
        valor == valor.rounded() ? String(Int(valor)) : String(format: "%.1f", valor)
    }
}

#Preview {
    VistaCompras()
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self, VisitaVeterinario.self, Pedido.self], inMemory: true)
}
