import SwiftUI

// MARK: - Información real de las razas del criadero
//
// Textos resumidos de Wikipedia (es.wikipedia.org: «Sus scrofa domestica» y «Large white»;
// en.wikipedia.org: «Miniature pig», «Duroc pig» y «Landrace pig»), licencia CC BY-SA.
// Fotos de Wikimedia Commons con licencia libre. Ningún dato de aquí es del criadero:
// los precios y los animales de Virginia siguen siendo los que ella registra en la app.

struct CreditoFoto {
    let autor: String
    let licencia: String
    let archivo: String
    let enlace: String
}

struct InfoRaza {
    let raza: Raza
    let titulo: String
    let subtitulo: String
    let resumen: String
    let datos: [String]
    let pieDeFoto: String
    let credito: CreditoFoto
}

extension Raza {
    /// Nombre del recurso con la foto real de la raza.
    var nombreFoto: String {
        switch self {
        case .comun:   return "foto_comun"
        case .minipig: return "foto_minipig"
        case .cruza:   return "foto_cruza"
        }
    }

    /// Foto real de la raza, si el recurso está en la app.
    var fotoReal: UIImage? { UIImage(named: nombreFoto) }
}

enum GuiaRazas {

    static let datosGenerales: [String] = [
        "Nombre científico: Sus scrofa domestica.",
        "Se domesticó hace unos 13 mil años en el Cercano Oriente; en China ocurrió aparte, de forma independiente.",
        "Aunque parezca pesado, es ágil, rápido e inteligente.",
    ]

    static func info(_ raza: Raza) -> InfoRaza {
        switch raza {
        case .comun:
            return InfoRaza(
                raza: .comun,
                titulo: "Cerdo común",
                subtitulo: "Cerdo doméstico de granja",
                resumen: "Cuerpo pesado y redondeado, hocico largo, patas cortas con pezuñas de cuatro dedos y cola corta.",
                datos: [
                    "La gestación dura unos 114 días: tres meses, tres semanas y tres días.",
                    "Crece y madura rápido, y sus camadas son numerosas.",
                    "Come de todo: vegetales y restos orgánicos que tengan proteína.",
                    "Ejemplo de raza común blanca: el Large White, de orejas tiesas y muy rústico.",
                ],
                pieDeFoto: "Foto de ejemplo: cerdo Large White",
                credito: CreditoFoto(
                    autor: "Steven Walling",
                    licencia: "CC BY-SA 3.0",
                    archivo: "Large White sow 2014-03-06 12-36.jpg",
                    enlace: "https://commons.wikimedia.org/wiki/File:Large_White_sow_2014-03-06_12-36.jpg"))
        case .minipig:
            return InfoRaza(
                raza: .minipig,
                titulo: "Minipig",
                subtitulo: "Cerdo miniatura",
                resumen: "Cerdo doméstico que de adulto sigue siendo muy pequeño.",
                datos: [
                    "Tarda unos 4 años en alcanzar su tamaño completo.",
                    "Puede vivir hasta 15 años.",
                    "Llega a medir unos 50 cm de alto en el hombro y 100 cm de largo.",
                    "Hay razas pequeñas tradicionales, como el cuino de México.",
                ],
                pieDeFoto: "Foto de ejemplo: minipig",
                credito: CreditoFoto(
                    autor: "Fcobmz",
                    licencia: "CC BY-SA 4.0",
                    archivo: "Mini Pig.jpg",
                    enlace: "https://commons.wikimedia.org/wiki/File:Mini_Pig.jpg"))
        case .cruza:
            return InfoRaza(
                raza: .cruza,
                titulo: "Cruza",
                subtitulo: "Cerdo de razas mezcladas",
                resumen: "Nace de juntar dos razas, por eso su color y su tamaño pueden variar.",
                datos: [
                    "Duroc: de color dorado a café rojizo, grande y musculoso, con orejas medio caídas.",
                    "Large White: blanco, de orejas tiesas y muy rústico.",
                    "Landrace: raza de origen danés de la que se derivaron otras.",
                    "La foto muestra un Large White junto a un Duroc, razas que se usan en cruzas.",
                ],
                pieDeFoto: "Foto de ejemplo: Large White y Duroc",
                credito: CreditoFoto(
                    autor: "Beatrice Kaseke",
                    licencia: "CC BY-SA 4.0",
                    archivo: "Mixed pigs a large white and the durac.jpg",
                    enlace: "https://commons.wikimedia.org/wiki/File:Mixed_pigs_a_large_white_and_the_durac.jpg"))
        }
    }
}

// MARK: - Pantalla "Guía de razas"

struct VistaGuiaRazas: View {
    /// Raza a la que se desplaza la guía al abrirse (por ejemplo, desde la ficha de un cerdo).
    var razaInicial: Raza? = nil

    var body: some View {
        ScrollViewReader { lector in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TituloPantalla(titulo: "Guía de razas",
                                   subtitulo: "Información real de los cerdos de tu criadero")
                    tarjetaGeneral
                    ForEach(Raza.allCases) { raza in
                        TarjetaRaza(info: GuiaRazas.info(raza))
                            .id(raza)
                    }
                    fuentes
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background { Tema.fondo.ignoresSafeArea() }
            .onAppear {
                if let razaInicial {
                    withAnimation { lector.scrollTo(razaInicial, anchor: .top) }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Tema.fondo, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var tarjetaGeneral: some View {
        Tarjeta {
            TituloSeccion(texto: "El cerdo doméstico", icono: "pawprint")
            ForEach(GuiaRazas.datosGenerales, id: \.self) { dato in
                FilaDato(texto: dato)
            }
        }
    }

    private var fuentes: some View {
        VStack(alignment: .leading, spacing: 10) {
            EtiquetaSeccion("Fuentes")
            Text("Textos resumidos de Wikipedia (licencia CC BY-SA): «Sus scrofa domestica» y «Large white» en español; «Miniature pig», «Duroc pig» y «Landrace pig» en inglés.")
                .font(.system(size: 14))
                .foregroundStyle(Tema.secundario)
            Text("Las fotos son de ejemplo de cada raza, no de tus cerdos. Sube la foto de cada uno desde su ficha.")
                .font(.system(size: 14))
                .foregroundStyle(Tema.secundario)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

private struct FilaDato: View {
    let texto: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(Tema.verde)
                .accessibilityHidden(true)
            Text(texto)
                .font(.system(size: 17))
                .foregroundStyle(Tema.tinta)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct TarjetaRaza: View {
    let info: InfoRaza

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                AvatarCerdo(raza: info.raza)
                    .frame(height: 260)
                Text(info.pieDeFoto)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Tema.tinta)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Tema.superficie.opacity(0.92)))
                    .padding(12)
            }
            .frame(height: 260)
            .clipped()

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.titulo)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Tema.tinta)
                        .accessibilityAddTraits(.isHeader)
                    Text(info.subtitulo)
                        .font(.system(size: 15))
                        .foregroundStyle(Tema.secundario)
                }
                Text(info.resumen)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Tema.tinta)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(info.datos, id: \.self) { dato in
                    FilaDato(texto: dato)
                }
                credito
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tema.superficie)
        .clipShape(RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tema.radioTarjeta, style: .continuous)
                .stroke(Tema.linea, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var credito: some View {
        let c = info.credito
        VStack(alignment: .leading, spacing: 2) {
            Text("Foto: \(c.autor) · \(c.licencia)")
                .font(.system(size: 13))
                .foregroundStyle(Tema.secundario)
            if let url = URL(string: c.enlace) {
                Link("Ver en Wikimedia Commons", destination: url)
                    .font(.system(size: 13, weight: .semibold))
                    .tint(Tema.verde)
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack { VistaGuiaRazas() }
}
