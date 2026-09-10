# Encuentra los platos que EMPEORARON de banda de food cost a raiz de
# un precio recien cargado.
#
# No basta con "esta por encima del 35 %": avisar de todos los platos
# altos en cada carga de precio es un aviso que se ignora a la semana.
# Y no basta con "cruzo el 35 %": un plato que va del 73 % al 130 %
# pasa a venderse bajo costo sin cruzar nada, y eso es lo que mas urge.
#
# Por eso se comparan las BANDAS que ya define Receta. El antes y el
# despues salen del costeo por fecha: no hace falta guardar historial.
class CruceDeUmbral
  # De mejor a peor. El indice es lo que permite decir "empeoro".
  ORDEN = %i[bajo sano alto critico perdida].freeze

  # Solo estas merecen un correo.
  PREOCUPANTES = %i[alto critico perdida].freeze

  Cruce = Struct.new(:plato, :antes, :despues, :banda_antes, :banda_despues,
                     :sugerido, keyword_init: true)

  attr_reader :precio

  def initialize(precio)
    @precio = precio
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
    ayer   = dia - 1
    fc_hoy = food_cost(plato, dia)
    return nil if fc_hoy.nil?

    banda_hoy = Receta.banda_para(fc_hoy)
    return nil unless PREOCUPANTES.include?(banda_hoy)

    fc_ayer    = food_cost(plato, ayer)
    banda_ayer = fc_ayer && Receta.banda_para(fc_ayer)

    # Si antes no se podia costear, cualquier banda preocupante es
    # noticia. Si se podia, solo avisamos cuando empeoro de cajon.
    if banda_ayer
      return nil if ORDEN.index(banda_hoy) <= ORDEN.index(banda_ayer)
    end

    Cruce.new(
      plato:         plato,
      antes:         fc_ayer,
      despues:       fc_hoy,
      banda_antes:   banda_ayer,
      banda_despues: banda_hoy,
      sugerido:      plato.precio_sugerido(fecha: dia)
    )
  end

  def food_cost(plato, fecha)
    return nil unless plato.costeable?(fecha: fecha)

    plato.food_cost(fecha: fecha)
  end
end
