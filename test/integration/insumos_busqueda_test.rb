require "test_helper"

class InsumosBusquedaTest < ActionDispatch::IntegrationTest
  setup do
    @lacteos = Proveedor.create!(nombre: "Lácteos del Sur")
    @leche   = crear_insumo(nombre: "Leche entera")
    @leche.update!(proveedor: @lacteos)
    @cebolla = crear_insumo(nombre: "Cebolla")
  end

  test "el buscador aparece en el listado" do
    get insumos_path
    assert_response :success
    assert_select "form[action=?][method=?]", insumos_path, "get"
    assert_select "input[name=q]"
  end

  test "filtra los resultados y dice cuantos son" do
    get insumos_path(q: "leche")
    assert_response :success
    assert_includes response.body, "Leche entera"
    assert_not_includes response.body, "Cebolla"
    assert_includes response.body, "1 resultado para"
  end

  test "el encabezado sigue mostrando el total, no los filtrados" do
    get insumos_path(q: "leche")
    assert_includes response.body, "#{Insumo.count} insumos"
  end

  test "conserva el termino en el campo y ofrece limpiar" do
    get insumos_path(q: "leche")
    assert_select "input[name=q][value=?]", "leche"
    assert_select "a[href=?]", insumos_path, text: "limpiar"
  end

  test "sin coincidencias muestra un estado vacio, no una pagina en blanco" do
    get insumos_path(q: "caviar")
    assert_response :success
    assert_includes response.body, "Ningún insumo coincide"
    assert_select "a[href=?]", insumos_path, text: "Ver todos los insumos"
  end

  test "los resultados siguen agrupados por proveedor" do
    get insumos_path(q: "lacteos")
    assert_includes response.body, "Lácteos del Sur"
    assert_includes response.body, "Leche entera"
  end

  test "buscar por proveedor sin tildes funciona desde la URL" do
    get insumos_path(q: "lacteos")
    assert_includes response.body, "Leche entera"
    assert_not_includes response.body, "Cebolla"
  end

  test "sin termino lista todo" do
    get insumos_path
    assert_includes response.body, "Leche entera"
    assert_includes response.body, "Cebolla"
    assert_not_includes response.body, "resultado para"
  end
end
