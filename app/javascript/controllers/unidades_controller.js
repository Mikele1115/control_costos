import { Controller } from "@hotwired/stimulus"

// Ajusta el desplegable de unidades al ingrediente elegido.
//
// Las unidades compatibles vienen incrustadas en cada <option> del
// otro desplegable, asi que no hay que consultar al servidor: la
// respuesta ya viajo con la pagina.
export default class extends Controller {
  static targets = ["insumable", "unidad"]

  connect() {
    this.actualizar()
  }

  actualizar() {
    const elegida = this.unidadTarget.value
    const opcion = this.insumableTarget.selectedOptions[0]
    const unidades = JSON.parse(opcion?.dataset.unidades || "{}")
    const entradas = Object.entries(unidades)

    this.unidadTarget.innerHTML = ""

    // Sin ingrediente elegido no hay unidad que ofrecer.
    if (entradas.length === 0) {
      this.unidadTarget.disabled = true
      this.unidadTarget.add(new Option("—", ""))
      return
    }

    this.unidadTarget.disabled = false
    entradas.forEach(([valor, etiqueta]) => {
      this.unidadTarget.add(new Option(etiqueta, valor))
    })

    // Si la unidad que ya estaba sigue siendo valida, se conserva.
    if (unidades[elegida]) this.unidadTarget.value = elegida
  }
}
