require "test_helper"

class UnidadesFiltradasTest < ActionDispatch::IntegrationTest
  setup do
    @plato   = crear_plato(nombre: "Milanesa")
    @harina  = crear_insumo(nombre: "Harina 000", unidad_base: "g")
    @aceite  = crear_insumo(nombre: "Aceite", unidad_base: "ml")
    @huevo   = crear_insumo(nombre: "Huevo", unidad_base: "unidad")
    @fondo   = crear_preparacion(nombre: "Fondo", rinde: 3, unidad: "l")
  end

  test "cada opcion lleva sus unidades compatibles y sus etiquetas" do
    get receta_path(@plato)
    assert_response :success

    assert_select "option[value=?][data-unidades=?]", "Insumo:#{@harina.id}",
      { "g" => "gramos", "kg" => "kilogramos" }.to_json
    assert_select "option[value=?][data-unidades=?]", "Insumo:#{@aceite.id}",
      { "ml" => "mililitros", "l" => "litros" }.to_json
    assert_select "option[value=?][data-unidades=?]", "Insumo:#{@huevo.id}",
      { "unidad" => "unidades", "docena" => "docenas" }.to_json
  end

  test "una preparacion lleva las unidades de su magnitud, no las de su rendimiento" do
    # rinde en litros, pero se dosifica en mililitros
    get receta_path(@plato)
    assert_select "option[value=?][data-unidades=?]", "Receta:#{@fondo.id}",
      { "ml" => "mililitros", "l" => "litros" }.to_json
  end

  test "Receta e Insumo responden igual a unidades_permitidas" do
    assert_equal %w[ml l], @fondo.unidades_permitidas
    assert_equal %w[ml l], @aceite.unidades_permitidas
    assert_equal [],       @plato.unidades_permitidas
  end

  test "el desplegable sigue sin ofrecer preparaciones que harian un ciclo" do
    otra = crear_preparacion(nombre: "Depende del fondo")
    agregar(otra, @fondo, 100, "ml")

    get receta_path(@fondo)
    assert_select "option[value=?]", "Receta:#{otra.id}", count: 0
    assert_select "option[value=?]", "Receta:#{@fondo.id}", count: 0
  end

  test "el formulario esta conectado al controlador de Stimulus" do
    get receta_path(@plato)
    assert_select "form[data-controller=?]", "unidades"
    assert_select "select[data-unidades-target=?]", "insumable"
    assert_select "select[data-unidades-target=?]", "unidad"
    assert_select "select[data-action=?]", "change->unidades#actualizar"
  end
end
