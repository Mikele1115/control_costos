class MargenesController < ApplicationController
  ORDENES = %w[margen food_cost costo nombre].freeze

  def index
    @fecha = fecha_solicitada
    @orden = ORDENES.include?(params[:orden]) ? params[:orden] : "margen"

    @filas = Receta.platos.includes(ingredientes: :insumable).map { |p| fila(p) }
    @filas = ordenar(@filas)

    # Solo los que tienen costo Y precio de venta entran en el resumen:
    # sin uno de los dos no hay margen que comparar.
    @analizables = @filas.select { |f| f[:food_cost].present? }
    @maximo_pvp  = @analizables.map { |f| f[:plato].precio_venta }.max || 0
  end

  private

  def fila(plato)
    costeable = plato.costeable?(fecha: @fecha)

    {
      plato:     plato,
      costeable: costeable,
      costo:     costeable ? plato.costo_total(fecha: @fecha)     : nil,
      margen:    costeable ? plato.margen_bruto(fecha: @fecha)    : nil,
      food_cost: costeable ? plato.food_cost(fecha: @fecha)       : nil,
      sugerido:  costeable ? plato.precio_sugerido(fecha: @fecha) : nil
    }
  end

  # Los platos sin datos van al final: no compiten en el ranking,
  # pero tampoco se esconden.
  def ordenar(filas)
    con_datos, sin_datos = filas.partition { |f| f[:food_cost].present? }

    ordenadas =
      case @orden
      when "food_cost" then con_datos.sort_by { |f| -f[:food_cost] }
      when "costo"     then con_datos.sort_by { |f| -f[:costo] }
      when "nombre"    then con_datos.sort_by { |f| f[:plato].nombre }
      else                  con_datos.sort_by { |f| -f[:margen] }
      end

    ordenadas + sin_datos.sort_by { |f| f[:plato].nombre }
  end
end
