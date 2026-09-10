require "test_helper"

class ResumenInsumoTest < ActionDispatch::IntegrationTest
  setup do
    @insumo = crear_insumo(nombre: "Aceite girasol", unidad_base: "ml")
  end

  def precio(monto, fecha)
    crear_precio(@insumo, precio: monto, cantidad: 1, unidad: "l", desde: fecha)
  end

  test "resume un aumento en una frase" do
    precio(1_800, Date.new(2026, 1, 15))
    precio(2_300, Date.new(2026, 6, 1))

    get insumo_path(@insumo)
    assert_response :success
    assert_includes response.body,
      "Desde su primer precio, el 15 de enero de 2026, Aceite girasol acumula un aumento del 27,8 %."
  end

  test "resume una baja" do
    precio(20_000, Date.new(2026, 1, 1))
    precio(15_000, Date.new(2026, 6, 1))

    get insumo_path(@insumo)
    assert_includes response.body, "acumula una baja del 25,0 %"
  end

  test "avisa cuando hay un unico precio" do
    precio(1_800, Date.new(2026, 1, 15))
    get insumo_path(@insumo)
    assert_includes response.body,
      "Hay un único precio cargado para Aceite girasol, vigente desde el 15 de enero de 2026."
    assert_includes response.body, "sin cambios"
  end

  test "cuenta el caso de volver al mismo precio" do
    precio(10_000, Date.new(2026, 1, 1))
    precio(14_000, Date.new(2026, 4, 1))
    precio(10_000, Date.new(2026, 7, 1))

    get insumo_path(@insumo)
    assert_includes response.body, "volvió al mismo precio que tenía"
    assert_includes response.body, "tras 2 cambios"
  end

  test "sin precios no muestra el cuadro" do
    get insumo_path(@insumo)
    assert_response :success
    assert_not_includes response.body, "Cambios de precio"
    assert_includes response.body, "Sin precios cargados"
  end

  test "la insignia es roja al subir y verde al bajar" do
    precio(1_800, Date.new(2026, 1, 15))
    precio(2_300, Date.new(2026, 6, 1))
    get insumo_path(@insumo)
    assert_select "span.bg-rose-100", text: /27,8 %/

    otro = crear_insumo(nombre: "Papa", unidad_base: "g")
    crear_precio(otro, precio: 2_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    crear_precio(otro, precio: 1_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))
    get insumo_path(otro)
    assert_select "span.bg-emerald-100", text: /-50 %/
  end

  test "muestra el mas barato y el mas caro con sus fechas" do
    precio(1_800, Date.new(2026, 1, 15))
    precio(2_300, Date.new(2026, 6, 1))

    get insumo_path(@insumo)
    assert_includes response.body, "Más barato"
    assert_includes response.body, "$1,80"
    assert_includes response.body, "Más caro"
    assert_includes response.body, "$2,30"
  end

  test "el resumen va antes del grafico" do
    precio(1_800, Date.new(2026, 1, 15))
    precio(2_300, Date.new(2026, 6, 1))

    get insumo_path(@insumo)
    assert_operator response.body.index("Cambios de precio"), :<,
                    response.body.index("Evolución del precio"),
                    "primero la conclusion en palabras, despues el detalle visual"
  end

  test "un precio futuro se anuncia, no se cuenta como viejo" do
    precio(1_800, Date.new(2026, 1, 15))
    crear_precio(@insumo, precio: 3_000, cantidad: 1, unidad: "l",
                 desde: Date.current + 60)

    get insumo_path(@insumo)
    assert_includes response.body, "entra en vigor el"
    assert_not_includes response.body, "hace 0 días"
  end
end
