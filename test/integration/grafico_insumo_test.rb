require "test_helper"

class GraficoInsumoTest < ActionDispatch::IntegrationTest
  setup do
    @insumo = crear_insumo(nombre: "Nalga", unidad_base: "g")
  end

  test "la ficha dibuja el grafico cuando hay precios" do
    crear_precio(@insumo, precio: 12_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    crear_precio(@insumo, precio: 18_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))

    get insumo_path(@insumo)
    assert_response :success
    assert_includes response.body, "Evolución del precio"
    assert_select "svg[viewBox]"
    assert_select "svg path[d]"
    assert_select "svg circle", 2
  end

  test "cada punto lleva su fecha y su precio en el tooltip" do
    crear_precio(@insumo, precio: 12_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    get insumo_path(@insumo)
    assert_select "svg circle title", text: /\$12,00 por g/
  end

  test "muestra la variacion acumulada" do
    crear_precio(@insumo, precio: 12_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    crear_precio(@insumo, precio: 18_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))

    get insumo_path(@insumo)
    assert_includes response.body, "+50 %"
  end

  test "sin precios no dibuja el grafico" do
    get insumo_path(@insumo)
    assert_response :success
    assert_not_includes response.body, "Evolución del precio"
    assert_select "svg", 0
    assert_includes response.body, "Sin precios cargados"
  end

  test "con un solo precio dibuja igual, sin variacion" do
    crear_precio(@insumo, precio: 12_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    get insumo_path(@insumo)
    assert_select "svg circle", 1
    assert_not_includes response.body, "%</span>"
  end
end
