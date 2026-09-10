require "test_helper"

class GraficoPreciosTest < ActiveSupport::TestCase
  setup do
    @insumo = crear_insumo(nombre: "Nalga", unidad_base: "g")
  end

  # $/kg -> el costo por gramo es precio/1000
  def precio(monto, fecha)
    crear_precio(@insumo, precio: monto, cantidad: 1, unidad: "kg", desde: fecha)
  end

  test "sin precios no dibuja nada" do
    grafico = GraficoPrecios.new([])
    assert grafico.vacio?
    assert_equal "", grafico.ruta
    assert_empty grafico.lineas_guia
    assert_nil grafico.variacion
  end

  test "un solo precio da una linea horizontal centrada" do
    grafico = GraficoPrecios.new([precio(12_000, Date.new(2026, 1, 1))],
                                 hasta: Date.new(2026, 9, 1))
    assert grafico.plano?
    assert_equal 1, grafico.puntos.size
    assert_equal grafico.x_izquierda, grafico.puntos.first[:x]
    assert_match(/\AM [\d.]+ [\d.]+ H #{grafico.x_derecha}\z/, grafico.ruta)
  end

  test "varios precios iguales no dividen por cero" do
    grafico = GraficoPrecios.new([precio(12_000, Date.new(2026, 1, 1)),
                                  precio(12_000, Date.new(2026, 3, 1))],
                                 hasta: Date.new(2026, 9, 1))
    assert grafico.plano?
    assert_equal 1, grafico.puntos.map { |p| p[:y] }.uniq.size
  end

  test "la ruta es una escalera: H antes de cada V" do
    grafico = GraficoPrecios.new([precio(12_000, Date.new(2026, 1, 1)),
                                  precio(15_000, Date.new(2026, 4, 1)),
                                  precio(18_000, Date.new(2026, 6, 1))],
                                 hasta: Date.new(2026, 9, 1))

    assert_equal "MHVHVH", grafico.ruta.scan(/[MHV]/).join
  end

  test "el eje vertical no esta invertido: mas caro es mas arriba" do
    grafico = GraficoPrecios.new([precio(12_000, Date.new(2026, 1, 1)),
                                  precio(18_000, Date.new(2026, 6, 1))],
                                 hasta: Date.new(2026, 9, 1))

    barato, caro = grafico.puntos
    assert_operator caro[:y], :<, barato[:y], "en SVG, menor y es mas arriba"
    assert_equal grafico.y_arriba, caro[:y]
    assert_equal grafico.y_abajo,  barato[:y]
  end

  test "los puntos avanzan de izquierda a derecha con el tiempo" do
    grafico = GraficoPrecios.new([precio(12_000, Date.new(2026, 1, 1)),
                                  precio(15_000, Date.new(2026, 5, 1)),
                                  precio(18_000, Date.new(2026, 9, 1))],
                                 hasta: Date.new(2026, 9, 1))

    equis = grafico.puntos.map { |p| p[:x] }
    assert_equal equis.sort, equis
    assert_equal grafico.x_izquierda, equis.first
    assert_equal grafico.x_derecha,   equis.last
  end

  test "calcula la variacion entre el primer y el ultimo precio" do
    grafico = GraficoPrecios.new([precio(12_000, Date.new(2026, 1, 1)),
                                  precio(18_000, Date.new(2026, 6, 1))],
                                 hasta: Date.new(2026, 9, 1))
    assert_equal BigDecimal(50), grafico.variacion
  end

  test "una bajada da variacion negativa" do
    grafico = GraficoPrecios.new([precio(20_000, Date.new(2026, 1, 1)),
                                  precio(15_000, Date.new(2026, 6, 1))],
                                 hasta: Date.new(2026, 9, 1))
    assert_equal BigDecimal(-25), grafico.variacion
  end

  test "un precio futuro extiende el eje temporal" do
    grafico = GraficoPrecios.new([precio(12_000, Date.new(2026, 1, 1)),
                                  precio(18_000, Date.new(2027, 3, 1))],
                                 hasta: Date.new(2026, 9, 1))
    assert_equal Date.new(2027, 3, 1), grafico.hasta
  end

  test "ordena los precios aunque lleguen desordenados" do
    tarde = precio(18_000, Date.new(2026, 6, 1))
    pronto = precio(12_000, Date.new(2026, 1, 1))

    grafico = GraficoPrecios.new([tarde, pronto], hasta: Date.new(2026, 9, 1))
    assert_equal [Date.new(2026, 1, 1), Date.new(2026, 6, 1)],
                 grafico.puntos.map { |p| p[:fecha] }
  end

  test "las lineas guia van del maximo al minimo" do
    grafico = GraficoPrecios.new([precio(12_000, Date.new(2026, 1, 1)),
                                  precio(18_000, Date.new(2026, 6, 1))],
                                 hasta: Date.new(2026, 9, 1))

    valores = grafico.lineas_guia.map(&:first)
    assert_equal [grafico.maximo, grafico.minimo], [valores.first, valores.last]
    assert_equal 3, valores.size
  end
end
