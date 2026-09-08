require "test_helper"

class PrecioInsumoTest < ActiveSupport::TestCase
  test "deriva el costo por unidad base al guardar" do
    harina = crear_insumo(unidad_base: "g")
    precio = crear_precio(harina, precio: 30_000, cantidad: 25, unidad: "kg")
    assert_equal BigDecimal("1.2"), precio.costo_por_unidad_base
  end

  test "deriva el costo tambien desde litros y docenas" do
    aceite = crear_insumo(unidad_base: "ml")
    assert_equal BigDecimal("1.8"),
      crear_precio(aceite, precio: 9000, cantidad: 5, unidad: "l").costo_por_unidad_base

    huevo = crear_insumo(unidad_base: "unidad")
    assert_equal BigDecimal(200),
      crear_precio(huevo, precio: 4800, cantidad: 2, unidad: "docena").costo_por_unidad_base
  end

  test "rechaza una unidad de compra de otra magnitud" do
    harina = crear_insumo(unidad_base: "g")
    precio = PrecioInsumo.new(insumo: harina, precio_compra: 100, cantidad_compra: 1,
                              unidad_compra: "l", vigente_desde: Date.new(2026, 1, 1))
    assert_not precio.valid?
    assert_match(/magnitudes distintas/, precio.errors[:unidad_compra].first)
  end

  test "exige cantidad de compra positiva" do
    harina = crear_insumo
    precio = PrecioInsumo.new(insumo: harina, precio_compra: 100, cantidad_compra: 0,
                              unidad_compra: "g", vigente_desde: Date.new(2026, 1, 1))
    assert_not precio.valid?
  end

  test "no admite dos precios del mismo insumo en la misma fecha" do
    harina = crear_insumo
    crear_precio(harina, precio: 30_000, cantidad: 25, unidad: "kg",
                 desde: Date.new(2026, 1, 1))
    repetido = PrecioInsumo.new(insumo: harina, precio_compra: 31_000, cantidad_compra: 25,
                                unidad_compra: "kg", vigente_desde: Date.new(2026, 1, 1))
    assert_not repetido.valid?
    assert repetido.errors[:vigente_desde].any?
  end

  test "el scope vigentes_al devuelve del mas nuevo al mas viejo" do
    harina = crear_insumo
    crear_precio(harina, precio: 30_000, cantidad: 25, unidad: "kg", desde: Date.new(2026, 1, 1))
    crear_precio(harina, precio: 45_000, cantidad: 25, unidad: "kg", desde: Date.new(2026, 8, 1))
    crear_precio(harina, precio: 60_000, cantidad: 25, unidad: "kg", desde: Date.new(2027, 1, 1))

    vigentes = harina.precio_insumos.vigentes_al(Date.new(2026, 9, 1))
    assert_equal 2, vigentes.count
    assert_equal BigDecimal("1.8"), vigentes.first.costo_por_unidad_base
  end

  test "la base de datos rechaza un precio negativo aunque se salte el modelo" do
    harina = crear_insumo
    precio = crear_precio(harina, precio: 30_000, cantidad: 25, unidad: "kg")
    assert_raises(ActiveRecord::StatementInvalid) do
      precio.update_column(:precio_compra, -1)
    end
  end
end
