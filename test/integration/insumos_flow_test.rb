require "test_helper"

class InsumosFlowTest < ActionDispatch::IntegrationTest
  setup do
    @cebolla = insumo_con_precio(nombre: "Cebolla", unidad_base: "g", merma: 20,
                                 precio: 2000, cantidad: 1, unidad: "kg")
  end

  test "el listado muestra el costo con y sin merma" do
    get insumos_path
    assert_response :success
    assert_includes response.body, "Cebolla"
    assert_includes response.body, "$2,00"   # costo por gramo
    assert_includes response.body, "$2,50"   # con la merma del 20% aplicada
  end

  test "el listado marca los insumos sin precio" do
    crear_insumo(nombre: "Sal fina")
    get insumos_path
    assert_includes response.body, "sin precio"
  end

  test "la ficha muestra el historial y senala el precio vigente" do
    crear_precio(@cebolla, precio: 2400, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))
    get insumo_path(@cebolla)
    assert_response :success
    assert_includes response.body, "Historial de precios"
    assert_includes response.body, "vigente"
    assert_includes response.body, "factor"
  end

  test "alta valida" do
    assert_difference "Insumo.count", 1 do
      post insumos_path, params: {
        insumo: { nombre: "Perejil", unidad_base: "g", merma_porcentaje: 35 }
      }
    end
    perejil = Insumo.find_by!(nombre: "Perejil")
    assert_redirected_to insumo_path(perejil)
    follow_redirect!
    assert_includes response.body, "Insumo creado."
  end

  test "alta invalida devuelve 422 y muestra los errores en castellano" do
    assert_no_difference "Insumo.count" do
      post insumos_path, params: {
        insumo: { nombre: "", unidad_base: "", merma_porcentaje: 150 }
      }
    end
    assert_response 422
    assert_includes response.body, "no puede estar en blanco"
    assert_includes response.body, "debe ser g, ml o unidad"
    assert_includes response.body, "debe estar entre 0 y 99,99"
  end

  test "nombre duplicado" do
    post insumos_path, params: { insumo: { nombre: "cebolla", unidad_base: "g" } }
    assert_response 422
    assert_includes response.body, "ya está en uso"
  end

  test "edicion" do
    patch insumo_path(@cebolla), params: { insumo: { merma_porcentaje: 30 } }
    assert_redirected_to insumo_path(@cebolla)
    assert_equal 30, @cebolla.reload.merma_porcentaje
  end

  test "borrar un insumo sin precios" do
    sal = crear_insumo(nombre: "Sal fina")
    assert_difference "Insumo.count", -1 do
      delete insumo_path(sal)
    end
    assert_redirected_to insumos_path
  end

  test "no se puede borrar un insumo con precios" do
    assert_no_difference "Insumo.count" do
      delete insumo_path(@cebolla)
    end
    follow_redirect!
    assert_includes response.body, "No se puede eliminar"
  end

  test "el panel calcula el food cost de un plato" do
    plato = crear_plato(nombre: "Tortilla", precio_venta: 4000)
    queso = insumo_con_precio(nombre: "Queso", precio: 10_000, cantidad: 1, unidad: "kg")
    agregar(plato, queso, 100, "g")   # 1000 total -> 250/porcion -> 25%

    get root_path
    assert_response :success
    assert_includes response.body, "Tortilla"
    assert_includes response.body, "$1.000,00"
    assert_includes response.body, "25,0 %"
  end
end
