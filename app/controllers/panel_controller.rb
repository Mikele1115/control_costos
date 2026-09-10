class PanelController < ApplicationController
  def index
    @fecha = fecha_solicitada

    @platos        = Receta.platos.includes(ingredientes: :insumable).order(:nombre)
    @preparaciones = Receta.preparaciones.order(:nombre)
    @sin_precio    = Insumo.where.missing(:precio_insumos).order(:nombre)

    @grupos = agrupar_por_categoria(@platos)

    # Lo urgente primero: el food cost mas alto arriba.
    @alertas = @platos.filter_map { |plato| alerta(plato) }
                      .sort_by { |a| -a[:food_cost] }
  end

  private

  # En el orden de la carta, y los sin clasificar al final.
  # Se agrupa en Ruby y no con SQL porque los platos ya estan cargados
  # con sus ingredientes: volver a la base seria trabajo de mas.
  def agrupar_por_categoria(platos)
    (Receta::CATEGORIAS + [nil]).filter_map do |categoria|
      del_grupo = platos.select { |plato| plato.categoria == categoria }
      [categoria, del_grupo] if del_grupo.any?
    end
  end

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
