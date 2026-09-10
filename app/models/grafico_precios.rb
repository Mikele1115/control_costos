# Calcula la geometria del grafico de precios en el tiempo.
#
# El precio de un insumo NO cambia de forma gradual: rige un valor
# hasta que se carga otro. Por eso la linea es una escalera y no una
# diagonal, que insinuaria una subida progresiva que nunca ocurrio.
#
# Es un PORO como Unidad: no es una fila en una tabla, es un calculo.
# Asi se puede probar sin renderizar nada.
class GraficoPrecios
  ANCHO    = 620
  ALTO     = 180
  MARGEN_I = 60   # izquierda: etiquetas de precio
  MARGEN_D = 12
  MARGEN_S = 16
  MARGEN_B = 28   # abajo: fechas

  attr_reader :puntos, :minimo, :maximo, :desde, :hasta

  def initialize(precios, hasta: Date.current)
    @precios = Array(precios).sort_by(&:vigente_desde)
    return if vacio?

    @desde  = @precios.first.vigente_desde
    # Si hay un precio con fecha futura, el grafico llega hasta el.
    @hasta  = [hasta, @precios.last.vigente_desde].max
    valores = @precios.map(&:costo_por_unidad_base)
    @minimo = valores.min
    @maximo = valores.max
    @puntos = calcular_puntos
  end

  def vacio? = @precios.empty?

  # Un solo precio, o varios iguales: no hay rango vertical que repartir.
  def plano? = !vacio? && minimo == maximo

  def ancho = ANCHO
  def alto  = ALTO

  def x_izquierda = MARGEN_I
  def x_derecha   = ANCHO - MARGEN_D
  def y_arriba    = MARGEN_S
  def y_abajo     = ALTO - MARGEN_B

  # La escalera: horizontal hasta la fecha del cambio, y ahi salta.
  def ruta
    return "" if vacio?

    trazos = ["M #{puntos.first[:x]} #{puntos.first[:y]}"]
    puntos.drop(1).each do |punto|
      trazos << "H #{punto[:x]}"   # llega al cambio con el precio viejo
      trazos << "V #{punto[:y]}"   # y salta al nuevo
    end
    trazos << "H #{x_derecha}"     # el ultimo precio sigue vigente
    trazos.join(" ")
  end

  # Lineas horizontales de referencia con su valor.
  def lineas_guia
    return [] if vacio?
    return [[minimo, y_de(minimo)]] if plano?

    medio = (minimo + maximo) / 2
    [[maximo, y_de(maximo)], [medio, y_de(medio)], [minimo, y_de(minimo)]]
  end

  # Cuanto subio o bajo desde el primer precio, en porcentaje.
  def variacion
    return nil if vacio? || puntos.size < 2 || puntos.first[:valor].zero?
    (puntos.last[:valor] - puntos.first[:valor]) / puntos.first[:valor] * 100
  end

  private

  def calcular_puntos
    @precios.map do |precio|
      {
        fecha: precio.vigente_desde,
        valor: precio.costo_por_unidad_base,
        x:     x_de(precio.vigente_desde),
        y:     y_de(precio.costo_por_unidad_base)
      }
    end
  end

  def x_de(fecha)
    dias = (hasta - desde).to_i
    return x_izquierda if dias.zero?

    avance = (fecha - desde).to_f / dias
    (x_izquierda + avance * (x_derecha - x_izquierda)).round(1)
  end

  def y_de(valor)
    return ((y_arriba + y_abajo) / 2.0).round(1) if plano?

    proporcion = (valor - minimo).to_f / (maximo - minimo)
    (y_abajo - proporcion * (y_abajo - y_arriba)).round(1)
  end
end
