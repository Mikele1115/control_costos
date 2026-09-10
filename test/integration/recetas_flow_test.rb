require "test_helper"

class RecetasFlowTest < ActionDispatch::IntegrationTest
  setup do
    # 10 $/g
    @queso = insumo_con_precio(nombre: "Muzzarella", unidad_base: "g",
                               precio: 10_000, cantidad: 1, unidad: "kg")

    # rinde 1000 g y cuesta 1000 -> 1 $/g
    @salsa = crear_preparacion(nombre: "Salsa de tomate", rinde: 1000, unidad: "g")
    agregar(@salsa, @queso, 100, "g")

    # 200 (salsa) + 500 (queso) = 700 -> 175/porcion -> 17,5 % de food cost
    @plato = crear_plato(nombre: "Milanesa", precio_venta: 2800)
    agregar(@plato, @salsa, 200, "g")
    agregar(@plato, @queso, 50, "g")
  end

  test "el listado muestra platos y preparaciones con su tipo" do
    get recetas_path
    assert_response :success
    assert_includes response.body, "Milanesa"
    assert_includes response.body, "Salsa de tomate"
    assert_includes response.body, "Plato"
    assert_includes response.body, "Preparación"
  end

  test "la ficha de un plato muestra los indicadores" do
    get receta_path(@plato)
    assert_response :success
    assert_includes response.body, "$700,00"   # costo total
    assert_includes response.body, "25,0 %"    # food cost: 700 sobre 2800
  end

  test "el desglose reparte el costo entre los ingredientes" do
    get receta_path(@plato)
    assert_includes response.body, "$200,00"   # la salsa
    assert_includes response.body, "$500,00"   # el queso
    assert_includes response.body, "28,6 %"    # 200/700
    assert_includes response.body, "71,4 %"    # 500/700
  end

  test "senala las sub-recetas en el desglose" do
    get receta_path(@plato)
    assert_includes response.body, "sub-receta"
  end

  test "senala los insumos con merma" do
    cebolla = insumo_con_precio(nombre: "Cebolla", merma: 20,
                                precio: 2000, cantidad: 1, unidad: "kg")
    agregar(@plato, cebolla, 100, "g")
    get receta_path(@plato)
    assert_includes response.body, "merma 20 %"
  end

  test "la ficha de una preparacion muestra su costo unitario y donde se usa" do
    get receta_path(@salsa)
    assert_response :success
    assert_includes response.body, "$1,00"
    assert_includes response.body, "Se usa en"
  end

  test "avisa cuando falta un precio en vez de inventar un numero" do
    agregar(@plato, crear_insumo(nombre: "Sal fina"), 10, "g")
    get receta_path(@plato)
    assert_response :success
    assert_includes response.body, "No se puede costear"
    assert_not_includes response.body, "$700,00"
  end

  test "una fecha anterior al primer precio deja la receta sin costear" do
    get receta_path(@plato), params: { fecha: "2025-01-01" }
    assert_response :success
    assert_includes response.body, "No se puede costear"
  end

  test "una fecha ilegible cae en hoy en vez de reventar" do
    get receta_path(@plato), params: { fecha: "melon" }
    assert_response :success
    assert_includes response.body, "$700,00"
  end

  test "el listado tambien acepta la fecha" do
    get recetas_path, params: { fecha: "2025-01-01" }
    assert_response :success
    assert_includes response.body, "falta el precio"
  end
end
