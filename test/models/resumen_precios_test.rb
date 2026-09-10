require "test_helper"

class ResumenPreciosTest < ActiveSupport::TestCase
  setup do
    @insumo = crear_insumo(nombre: "Aceite", unidad_base: "ml")
  end

  # $/l -> el costo por ml es monto/1000
  def precio(monto, fecha)
    crear_precio(@insumo, precio: monto, cantidad: 1, unidad: "l", desde: fecha)
  end

  def resumen(hasta: Date.new(2026, 9, 10))
    ResumenPrecios.new(@insumo, @insumo.precio_insumos.reload, hasta: hasta)
  end

  test "sin precios no hay nada que resumir" do
    r = resumen
    assert r.vacio?
    assert_nil r.variacion
    assert_equal 0, r.cambios
    assert_equal 0, r.meses
  end

  test "con un solo precio no hay variacion" do
    precio(1_800, Date.new(2026, 1, 15))
    r = resumen
    assert r.unico?
    assert_nil r.variacion
    assert_equal 0, r.cambios
    assert_not r.subio?
    assert_not r.bajo?
  end

  test "calcula el aumento acumulado" do
    precio(1_800, Date.new(2026, 1, 15))
    precio(2_300, Date.new(2026, 6, 1))

    r = resumen
    assert_in_delta 27.8, r.variacion.to_f, 0.05
    assert r.subio?
    assert_not r.bajo?
    assert_equal 1, r.cambios
  end

  test "una bajada da variacion negativa" do
    precio(20_000, Date.new(2026, 1, 1))
    precio(15_000, Date.new(2026, 6, 1))

    r = resumen
    assert_equal BigDecimal(-25), r.variacion
    assert r.bajo?
  end

  test "volver al precio inicial da variacion cero" do
    precio(10_000, Date.new(2026, 1, 1))
    precio(14_000, Date.new(2026, 4, 1))
    precio(10_000, Date.new(2026, 7, 1))

    r = resumen
    assert_equal BigDecimal(0), r.variacion
    assert r.estable?
    assert_equal 2, r.cambios
  end

  test "cuenta los meses de calendario desde el primer precio" do
    precio(1_000, Date.new(2026, 1, 15))
    assert_equal 8, resumen(hasta: Date.new(2026, 9, 10)).meses
    assert_equal 0, resumen(hasta: Date.new(2026, 1, 31)).meses
  end

  test "encuentra el mas barato y el mas caro, no el primero y el ultimo" do
    precio(20_000, Date.new(2026, 1, 1))
    precio(30_000, Date.new(2026, 4, 1))   # el pico esta en el medio
    precio(25_000, Date.new(2026, 7, 1))

    r = resumen
    assert_equal Date.new(2026, 1, 1), r.mas_barato.vigente_desde
    assert_equal Date.new(2026, 4, 1), r.mas_caro.vigente_desde
  end

  test "el ultimo cambio se mide contra el precio anterior, no contra el primero" do
    precio(10_000, Date.new(2026, 1, 1))
    precio(20_000, Date.new(2026, 4, 1))
    precio(22_000, Date.new(2026, 7, 1))

    r = resumen
    assert_equal BigDecimal(120), r.variacion               # acumulada
    assert_equal BigDecimal(10),  r.variacion_ultimo_cambio # solo el ultimo salto
  end

  test "cuenta los dias desde la ultima actualizacion" do
    precio(1_000, Date.new(2026, 6, 1))
    assert_equal 101, resumen(hasta: Date.new(2026, 9, 10)).dias_sin_actualizar
  end

  test "un precio con fecha futura no cuenta como desactualizado" do
    precio(1_000, Date.new(2026, 1, 1))
    precio(2_000, Date.new(2027, 1, 1))

    r = resumen
    assert r.ultimo_futuro?
    assert_nil r.dias_sin_actualizar
  end

  test "ordena los precios aunque lleguen desordenados" do
    tarde  = precio(2_300, Date.new(2026, 6, 1))
    pronto = precio(1_800, Date.new(2026, 1, 15))

    r = ResumenPrecios.new(@insumo, [tarde, pronto], hasta: Date.new(2026, 9, 10))
    assert_equal pronto, r.primero
    assert_equal tarde,  r.ultimo
    assert r.subio?
  end
end
