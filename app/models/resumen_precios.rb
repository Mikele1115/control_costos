# Interpreta el historial de precios de un insumo.
#
# Un PORO como Unidad y GraficoPrecios: no es una fila en una tabla,
# es un calculo, y asi se puede probar sin renderizar nada.
#
# Solo expone hechos. La frase que los cuenta se arma en la vista,
# porque depende del idioma y del formato.
class ResumenPrecios
  attr_reader :insumo, :precios, :hasta

  def initialize(insumo, precios = nil, hasta: Date.current)
    @insumo  = insumo
    @precios = Array(precios || insumo.precio_insumos).sort_by(&:vigente_desde)
    @hasta   = hasta
  end

  def vacio? = precios.empty?
  def unico? = precios.size == 1

  def primero = precios.first
  def ultimo  = precios.last

  def valor_inicial = primero&.costo_por_unidad_base
  def valor_actual  = ultimo&.costo_por_unidad_base

  # Variacion acumulada entre el primer precio y el ultimo.
  def variacion
    return nil if vacio? || unico? || valor_inicial.zero?

    (valor_actual - valor_inicial) / valor_inicial * 100
  end

  def subio?   = variacion&.positive? || false
  def bajo?    = variacion&.negative? || false
  def estable? = !vacio? && !unico? && variacion&.zero? || false

  def cambios = [ precios.size - 1, 0 ].max

  # Meses de calendario cubiertos, del primer precio a hoy.
  def meses
    return 0 if vacio?

    (hasta.year * 12 + hasta.month) -
      (primero.vigente_desde.year * 12 + primero.vigente_desde.month)
  end

  def mas_barato = precios.min_by(&:costo_por_unidad_base)
  def mas_caro   = precios.max_by(&:costo_por_unidad_base)

  # Cuanto salto en el ultimo cambio, respecto del precio anterior.
  def variacion_ultimo_cambio
    return nil if vacio? || unico?

    anterior = precios[-2].costo_por_unidad_base
    return nil if anterior.zero?

    (valor_actual - anterior) / anterior * 100
  end

  def ultimo_futuro? = !vacio? && ultimo.vigente_desde > hasta

  # Un precio que lleva mucho sin tocarse probablemente este viejo.
  def dias_sin_actualizar
    return nil if vacio? || ultimo_futuro?

    (hasta - ultimo.vigente_desde).to_i
  end
end
