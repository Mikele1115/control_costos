require "test_helper"

class PreciosFlowTest < ActionDispatch::IntegrationTest
  setup do
    @harina = crear_insumo(nombre: "Harina 000", unidad_base: "g")
  end

  # --- Formulario ---------------------------------------------------

  test "el formulario propone hoy como fecha" do
    get new_insumo_precio_insumo_path(@harina)
    assert_response :success
    assert_includes response.body, Date.current.to_s
  end

  test "el formulario preselecciona la unidad base del insumo" do
    get new_insumo_precio_insumo_path(@harina)
    assert_select "option[selected][value=?]", "g"

    aceite = crear_insumo(nombre: "Aceite", unidad_base: "ml")
    get new_insumo_precio_insumo_path(aceite)
    assert_select "option[selected][value=?]", "ml"
  end

  test "el desplegable solo ofrece unidades de la misma magnitud" do
    get new_insumo_precio_insumo_path(@harina)
    assert_includes response.body, "kilogramos"
    assert_not_includes response.body, "mililitros"

    aceite = crear_insumo(nombre: "Aceite", unidad_base: "ml")
    get new_insumo_precio_insumo_path(aceite)
    assert_includes response.body, "mililitros"
    assert_not_includes response.body, "kilogramos"
  end

  # --- Alta ---------------------------------------------------------

  test "cargar una compra deriva el costo por unidad base" do
    assert_difference "PrecioInsumo.count", 1 do
      post insumo_precio_insumos_path(@harina), params: {
        precio_insumo: { precio_compra: 30_000, cantidad_compra: 25,
                         unidad_compra: "kg", vigente_desde: Date.new(2026, 1, 1) }
      }
    end
    assert_redirected_to insumo_path(@harina)
    assert_equal BigDecimal("1.2"), @harina.reload.costo_unitario

    follow_redirect!
    assert_includes response.body, "Precio cargado"
  end

  test "rechaza una unidad de otra magnitud aunque llegue por POST directo" do
    assert_no_difference "PrecioInsumo.count" do
      post insumo_precio_insumos_path(@harina), params: {
        precio_insumo: { precio_compra: 100, cantidad_compra: 1,
                         unidad_compra: "l", vigente_desde: Date.current }
      }
    end
    assert_response 422
    assert_includes response.body, "magnitudes distintas"
  end

  test "rechaza dos precios del mismo dia" do
    crear_precio(@harina, precio: 30_000, cantidad: 25, unidad: "kg", desde: Date.new(2026, 1, 1))
    assert_no_difference "PrecioInsumo.count" do
      post insumo_precio_insumos_path(@harina), params: {
        precio_insumo: { precio_compra: 31_000, cantidad_compra: 25,
                         unidad_compra: "kg", vigente_desde: Date.new(2026, 1, 1) }
      }
    end
    assert_response 422
    assert_includes response.body, "ya tiene un precio cargado para esa fecha"
  end

  test "rechaza cantidad cero" do
    assert_no_difference "PrecioInsumo.count" do
      post insumo_precio_insumos_path(@harina), params: {
        precio_insumo: { precio_compra: 100, cantidad_compra: 0,
                         unidad_compra: "g", vigente_desde: Date.current }
      }
    end
    assert_response 422
  end

  # --- Borrado ------------------------------------------------------

  test "borrar un precio" do
    precio = crear_precio(@harina, precio: 30_000, cantidad: 25, unidad: "kg")
    assert_difference "PrecioInsumo.count", -1 do
      delete insumo_precio_insumo_path(@harina, precio)
    end
    assert_redirected_to insumo_path(@harina)
  end

  test "no se puede borrar el precio de otro insumo manipulando la URL" do
    sal   = crear_insumo(nombre: "Sal fina")
    ajeno = crear_precio(sal, precio: 900, cantidad: 1, unidad: "kg")

    assert_no_difference "PrecioInsumo.count" do
      delete insumo_precio_insumo_path(@harina, ajeno)
    end
    assert_response :not_found
  end

  # --- Vigencia -----------------------------------------------------

  test "la ficha marca vigente el precio que rige, no el mas nuevo" do
    crear_precio(@harina, precio: 30_000, cantidad: 25, unidad: "kg", desde: 1.month.ago.to_date)
    crear_precio(@harina, precio: 45_000, cantidad: 25, unidad: "kg", desde: 1.month.from_now.to_date)

    get insumo_path(@harina)
    assert_response :success
    assert_includes response.body, "vigente"
    assert_includes response.body, "futuro"
  end

  test "un precio con fecha futura no altera el costo de hoy" do
    crear_precio(@harina, precio: 30_000, cantidad: 25, unidad: "kg", desde: 1.month.ago.to_date)
    crear_precio(@harina, precio: 45_000, cantidad: 25, unidad: "kg", desde: 1.month.from_now.to_date)

    assert_equal BigDecimal("1.2"), @harina.reload.costo_unitario
  end
end
