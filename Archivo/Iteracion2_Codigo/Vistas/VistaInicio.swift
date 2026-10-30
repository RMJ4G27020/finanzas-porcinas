import SwiftUI
import SwiftData

/// Pantalla de inicio del Criadero Fam Rico Moreno.
struct VistaInicio: View {
    @Binding var seleccion: Seccion

    @Query(sort: [SortDescriptor(\Animal.arete)]) private var animales: [Animal]
    @Query(sort: [SortDescriptor(\Tarea.fecha)]) private var tareas: [Tarea]
    @Query(sort: [SortDescriptor(\Pedido.folio)]) private var pedidos: [Pedido]

    // Tamaños de texto: en el tamaño por defecto se ven igual que antes y crecen
    // cuando se sube el tamaño de texto en Ajustes.
    @ScaledMetric(relativeTo: .largeTitle) private var cifraGrande: CGFloat = 40
    @ScaledMetric(relativeTo: .title) private var cifraSecundaria: CGFloat = 28
    @ScaledMetric(relativeTo: .title2) private var cifraMedia: CGFloat = 24
    @ScaledMetric(relativeTo: .headline) private var tituloAtajo: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var textoFila: CGFloat = 15
    @ScaledMetric(relativeTo: .subheadline) private var textoApoyo: CGFloat = 14
    @ScaledMetric(relativeTo: .footnote) private var textoMenor: CGFloat = 13

    @Environment(\.dynamicTypeSize) private var tamanoTexto

    // Con tamaños de texto de accesibilidad las tarjetas van una debajo de otra.
    private var disposicionDeTarjetas: AnyLayout {
        tamanoTexto.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
    }

    // Se filtra y ordena en Swift: destino, tipo y estado son propiedades calculadas.
    private var animalesDeCrianza: Int {
        animales.filter { $0.destino == .crianza }.count
    }

    private var tareasDeHoy: [Tarea] {
        tareas
            .filter { Calendar.current.isDateInToday($0.fecha) }
            .sorted { $0.tipo.orden < $1.tipo.orden }
    }

    private var pedidosNuevos: Int {
        pedidos.filter { $0.estado == .nuevo }.count
    }

    // Textos para VoiceOver y para la tarjeta de pedidos.
    private var etiquetaAnimalesDeCrianza: String {
        animalesDeCrianza == 1 ? "1 animal de crianza" : "\(animalesDeCrianza) animales de crianza"
    }

    private var resumenPedidosNuevos: String {
        switch pedidosNuevos {
        case 0: return "Sin pedidos nuevos"
        case 1: return "1 nuevo"
        default: return "\(pedidosNuevos) nuevos"
        }
    }

    private func etiquetaDeVoz(_ tarea: Tarea) -> String {
        let nombre = tarea.tipo.rawValue.replacingOccurrences(of: " · ", with: ", ")
        return "\(nombre), \(tarea.hecha ? "hecho" : "pendiente")"
    }

    var body: some View {
        ZStack {
            Tema.fondo.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    encabezado
                    tarjetaCorral
                    tarjetasDelHato
                    tarjetaPrecio
                    tarjetasDeAtajos
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 96)
            }
        }
    }

    // MARK: - 1. Encabezado

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fechaLarga(Date()))
                .font(.system(size: textoMenor))
                .foregroundStyle(Tema.secundario)

            TituloPantalla(titulo: "Hola, \(Empresa.titular)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 2. Hato

    private var tarjetasDelHato: some View {
        disposicionDeTarjetas {
            Tarjeta {
                Text("\(animalesDeCrianza)")
                    .font(.system(size: cifraGrande, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text("Animales de crianza")
                    .font(.system(size: textoApoyo))
                    .foregroundStyle(Tema.secundario)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(etiquetaAnimalesDeCrianza)

            Tarjeta {
                Text("\(Empresa.puercosParaVentaAlAnio)")
                    .font(.system(size: cifraSecundaria, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                Text("Para venta al año")
                    .font(.system(size: textoApoyo))
                    .foregroundStyle(Tema.secundario)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Empresa.puercosParaVentaAlAnio) para venta al año")
        }
    }

    // MARK: - 3. Precio de venta

    private var tarjetaPrecio: some View {
        Tarjeta {
            EtiquetaSeccion(texto: "Precio de venta")

            Text("\(PrecioKg.cuarenta.etiqueta) o \(PrecioKg.ochenta.etiqueta) por kg")
                .font(.system(size: cifraMedia, weight: .bold))
                .foregroundStyle(Tema.tinta)

            Text("Según la raza")
                .font(.system(size: textoApoyo))
                .foregroundStyle(Tema.secundario)

            Button {
                seleccion = .finanzas
            } label: {
                HStack(spacing: 8) {
                    Text("Calcular una venta")
                    Image(systemName: "chevron.right")
                        .font(.system(size: textoApoyo, weight: .bold))
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(BotonSecundario())
        }
    }

    // MARK: - 4. Hoy en el corral

    // Rótulo de la tarjeta y quién registra las tareas; si no cabe en un renglón, se apilan.
    private var encabezadoDelCorral: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                EtiquetaSeccion(texto: "Hoy en el corral")
                    .lineLimit(1)
                Spacer(minLength: 8)
                if !tareasDeHoy.isEmpty {
                    atribucionDelCorral
                        .lineLimit(1)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                EtiquetaSeccion(texto: "Hoy en el corral")
                if !tareasDeHoy.isEmpty {
                    atribucionDelCorral
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var atribucionDelCorral: some View {
        Text("Las registra \(Empresa.operador)")
            .font(.system(size: textoMenor))
            .foregroundStyle(Tema.secundario)
    }

    private var tarjetaCorral: some View {
        Tarjeta {
            encabezadoDelCorral

            if tareasDeHoy.isEmpty {
                Text("Todavía no hay tareas registradas para hoy.")
                    .font(.system(size: textoFila))
                    .foregroundStyle(Tema.secundario)
            } else {
                VStack(spacing: 12) {
                    ForEach(tareasDeHoy) { tarea in
                        HStack(spacing: 12) {
                            Text(tarea.tipo.rawValue)
                                .font(.system(size: textoFila))
                                .foregroundStyle(Tema.tinta)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Chip(texto: tarea.hecha ? "Hecho" : "Pendiente",
                                 estilo: tarea.hecha ? .exito : .pendiente)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(etiquetaDeVoz(tarea))
                    }
                }
            }

            Button {
                seleccion = .bitacora
            } label: {
                Text("Ver bitácora")
                    .frame(minHeight: 44)
            }
            .buttonStyle(BotonSecundario())
        }
    }

    // MARK: - 5. Atajos

    private var tarjetasDeAtajos: some View {
        disposicionDeTarjetas {
            Button {
                seleccion = .animales
            } label: {
                Tarjeta {
                    HStack(spacing: 8) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: textoFila, weight: .bold))
                            .foregroundStyle(Tema.verde)
                        Text("Veterinario")
                            .font(.system(size: tituloAtajo, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                    }
                    Text(Empresa.veterinario)
                        .font(.system(size: textoApoyo))
                        .foregroundStyle(Tema.secundario)
                        .multilineTextAlignment(.leading)
                    Text("Ver visitas en Animales")
                        .font(.system(size: textoMenor))
                        .foregroundStyle(Tema.verde)
                        .multilineTextAlignment(.leading)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Veterinario, \(Empresa.veterinario)")
            .accessibilityHint("Abre la pestaña Animales")

            Button {
                seleccion = .pedidos
            } label: {
                Tarjeta {
                    HStack(spacing: 8) {
                        Image(systemName: "bag")
                            .font(.system(size: textoFila, weight: .bold))
                            .foregroundStyle(Tema.verde)
                        Text("Pedidos")
                            .font(.system(size: tituloAtajo, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                    }
                    if pedidosNuevos == 0 {
                        Text(resumenPedidosNuevos)
                            .font(.system(size: textoFila))
                            .foregroundStyle(Tema.secundario)
                    } else {
                        Text(resumenPedidosNuevos)
                            .font(.system(size: cifraMedia, weight: .bold))
                            .foregroundStyle(Tema.tinta)
                    }
                    Text("Facebook y WhatsApp")
                        .font(.system(size: textoApoyo))
                        .foregroundStyle(Tema.secundario)
                        .multilineTextAlignment(.leading)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pedidos, \(resumenPedidosNuevos.lowercased())")
            .accessibilityHint("Abre la pestaña Pedidos")
        }
    }
}

#Preview {
    VistaInicio(seleccion: .constant(.inicio))
        .modelContainer(for: [Animal.self, Tarea.self, Compra.self, Venta.self,
                              VisitaVeterinario.self, Pedido.self], inMemory: true)
}
