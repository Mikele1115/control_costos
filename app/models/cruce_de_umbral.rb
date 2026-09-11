# Encuentra los platos que merecen un correo a raiz de un precio recien
# cargado.
#
# Son dos reglas, y hacen falta las dos:
#
#   1. El plato cruzo el umbral que eligio el restaurante: antes estaba
#      por debajo, ahora por encima.
#   2. Ya estaba por encima, pero ademas empeoro de BANDA.
#
# La segunda existe porque un plato que va del 73 % al 130 % nunca
# "cruza" el 35 %: ya estaba arriba. Y es justo el aviso que mas urge,
# porque pasa a venderse bajo costo. La primera existe porque sin ella
# habria que repetir el mismo aviso en cada carga de precio, y un aviso
# que se repite se ignora a la semana.
#
# El antes y el despues salen del costeo por fecha: no hace falta
# guardar historial de food cost en ningun lado.
class CruceDeUmbral
  # De mejor a peor. El indice es lo que permite decir "empeoro".
  ORDEN = %i[bajo sano alto critico perdida].freeze

  UMBRAL_POR_DEFECTO = Receta::UMBRAL_ALTO

  Cruce = Struct.new(:plato, :antes, :despues, :banda_antes, :banda_despues,
                     :sugerido, keyword_init: true)

  attr_reader :precio, :umbral

  def initialize(precio, umbral: UMBRAL_POR_DEFECTO)
    @precio = precio
    @umbral = BigDecimal(umbral.to_s)
  end

  # Se evaluan todos los platos y no solo los que usan este insumo.
  # Con una carta de decenas es despreciable, corre en segundo plano, y
  # evita equivocarse siguiendo el grafo de sub-recetas hacia arriba.
  def cruces
    @cruces ||= Receta.platos.order(:nombre).filter_map { |plato| evaluar(plato) }
  end

  def alguno? = cruces.any?

  private

  def evaluar(plato)
    dia    = precio.vigente_desde
    fc_hoy = food_cost(plato, dia)
    return nil if fc_hoy.nil?
    return nil if fc_hoy < umbral

    fc_ayer = food_cost(plato, dia - 1)

    # Si antes no se podia costear, estar sobre el umbral ya es noticia.
    return nil if fc_ayer && !empeoro?(fc_ayer, fc_hoy)

    Cruce.new(
      plato:         plato,
      antes:         fc_ayer,
      despues:       fc_hoy,
      banda_antes:   fc_ayer && Receta.banda_para(fc_ayer),
      banda_despues: Receta.banda_para(fc_hoy),
      sugerido:      plato.precio_sugerido(fecha: dia)
    )
  end

  def empeoro?(antes, despues)
    return true if antes < umbral   # acaba de cruzarlo

    ORDEN.index(Receta.banda_para(despues)) > ORDEN.index(Receta.banda_para(antes))
  end

  def food_cost(plato, fecha)
    return nil unless plato.costeable?(fecha: fecha)

    plato.food_cost(fecha: fecha)
  end
end
