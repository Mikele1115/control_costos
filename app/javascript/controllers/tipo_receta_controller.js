import { Controller } from "@hotwired/stimulus"

// Un plato se vende a un precio; una preparacion rinde una cantidad
// medible que despues se dosifica. Mostramos solo los campos del
// tipo elegido.
export default class extends Controller {
  static targets = ["tipo", "plato", "preparacion"]

  connect() {
    this.actualizar()
  }

  actualizar() {
    const esPlato = this.tipoTarget.value === "plato"
    this.platoTarget.hidden = !esPlato
    this.preparacionTarget.hidden = esPlato
  }
}
