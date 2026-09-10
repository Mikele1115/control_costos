require "test_helper"

class MargenPorcentajeTest < ActionDispatch::IntegrationTest
  setup do
    @queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000, cantidad: 1, unidad: "kg")
  end

  # costo = gramos * 10
  def plato_con(nombre:, gramos:, precio_venta:)
    plato = crear_plato(nombre: nombre, precio_venta: precio_venta)
    agregar(plato, @queso, gramos, "g")
    plato
  end

  # --- Modelo -------------------------------------------------------

  test "el margen y el food cost siempre suman 100" do
    plato = plato_con(nombre: "Un plato", gramos: 34, precio_venta: 1000) # 34 %
    assert_equal BigDecimal(34), plato.food_cost
    assert_equal BigDecimal(66), plato.margen_porcentaje
    assert_equal BigDecimal(100), plato.food_cost + plato.margen_porcentaje
  end

  test "un plato vendido bajo costo tiene margen negativo" do
    plato = plato_con(nombre: "En perdida", gramos: 100, precio_venta: 500) # 200 %
    assert_equal BigDecimal(-100), plato.margen_porcentaje
  end

  test "sin precio de venta no hay porcentaje de margen" do
    plato = crear_plato(nombre: "Sin precio")
    agregar(plato, @queso, 10, "g")
    assert_nil plato.margen_porcentaje
  end

  test "el margen respeta la fecha consultada" do
    plato = crear_plato(nombre: "Con historial", precio_venta: 1000)
    carne = insumo_con_precio(nombre: "Nalga", precio: 10_000, cantidad: 1, unidad: "kg",
                              desde: Date.new(2026, 1, 1))
    crear_precio(carne, precio: 20_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))
    agregar(plato, carne, 30, "g")

    assert_equal BigDecimal(70), plato.margen_porcentaje(fecha: Date.new(2026, 5, 1))
    assert_equal BigDecimal(40), plato.margen_porcentaje(fecha: Date.new(2026, 9, 1))
  end

  # --- Pantallas ----------------------------------------------------

  test "la ficha muestra el margen en pesos y en porcentaje" do
    plato = plato_con(nombre: "Un plato", gramos: 34, precio_venta: 1000)
    get receta_path(plato)
    assert_response :success
    assert_includes response.body, "$660,00"   # margen bruto
    assert_includes response.body, "66,0 %"    # margen porcentual
    assert_includes response.body, "34,0 %"    # food cost
  end

  test "el color del margen sale de su food cost complementario" do
    plato_con(nombre: "Plato Sano",    gramos: 30, precio_venta: 1000) # fc 30 -> margen 70
    plato_con(nombre: "Plato Critico", gramos: 60, precio_venta: 1000) # fc 60 -> margen 40

    get receta_path(Receta.find_by!(nombre: "Plato Sano"))
    assert_select "span.bg-emerald-100", text: "70,0 %"

    get receta_path(Receta.find_by!(nombre: "Plato Critico"))
    assert_select "span.bg-rose-100", text: "40,0 %"
  end

  test "el panel muestra el porcentaje de margen junto al importe" do
    plato_con(nombre: "Un plato", gramos: 34, precio_venta: 1000)
    get root_path
    assert_includes response.body, "$660,00"
    assert_includes response.body, "66 % de margen"
  end

  test "el comparativo muestra el porcentaje bajo el margen" do
    plato_con(nombre: "Un plato", gramos: 34, precio_venta: 1000)
    get margenes_path
    assert_response :success
    assert_includes response.body, "$660,00"
    assert_includes response.body, "66 %"
  end

  # --- Marca --------------------------------------------------------

  test "la cabecera lleva el nombre del restaurante y la pizza" do
    get root_path
    assert_select "header", html: /La Splendida/
    assert_includes response.body, "🍕"
    assert_not_includes response.body, "🍅"
  end

  test "el titulo por defecto tambien" do
    get insumos_path
    assert_select "title", text: "Insumos"

    get proveedores_path
    assert_select "title", text: "Proveedores"
  end
end
