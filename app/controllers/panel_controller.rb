class PanelController < ApplicationController
  def index
    @fecha = fecha_solicitada

    @platos        = Receta.platos.includes(ingredientes: :insumable).order(:nombre)
    @preparaciones = Receta.preparaciones.order(:nombre)
    @sin_precio    = Insumo.where.missing(:precio_insumos).order(:nombre)

    # Lo urgente primero: el food cost mas alto arriba.
    @alertas = @platos.filter_map { |plato| alerta(plato) }
                      .sort_by { |a| -a[:food_cost] }
  end

  private

  def alerta(plato)
    return nil unless plato.costeable?(fecha: @fecha)
    return nil unless plato.requiere_atencion?(fecha: @fecha)

    sugerido = plato.precio_sugerido(fecha: @fecha)

    {
      plato:     plato,
      banda:     plato.banda_food_cost(fecha: @fecha),
      food_cost: plato.food_cost(fecha: @fecha),
      sugerido:  sugerido,
      brecha:    sugerido - plato.precio_venta
    }
  end
end
