require "test_helper"

class CategoriasTest < ActionDispatch::IntegrationTest
  setup do
    @queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000, cantidad: 1, unidad: "kg")
  end

  def plato_de(categoria, nombre)
    plato = Receta.create!(nombre: nombre, tipo: "plato",
                           categoria: categoria, precio_venta: 1000)
    agregar(plato, @queso, 30, "g")
    plato
  end

  # --- Modelo -------------------------------------------------------

  test "solo los platos pueden tener categoria" do
    prep = Receta.new(nombre: "Salsa", tipo: "preparacion", rendimiento_cantidad: 1000,
                      rendimiento_unidad: "g", categoria: "postre")
    assert_not prep.valid?
    assert_includes prep.errors[:categoria], "solo corresponde a los platos"
  end

  test "rechaza una categoria que no existe" do
    assert_not Receta.new(nombre: "X", tipo: "plato", categoria: "entradas").valid?
  end

  test "la cadena vacia del select se guarda como NULL" do
    plato = Receta.create!(nombre: "Sin clasificar", tipo: "plato", categoria: "")
    assert_nil plato.reload.categoria
  end

  test "la categoria es opcional" do
    assert Receta.new(nombre: "X", tipo: "plato").valid?
  end

  test "la base rechaza una categoria invalida aunque se salte el modelo" do
    plato = plato_de("postre", "Un postre")
    assert_raises(ActiveRecord::StatementInvalid) do
      plato.update_column(:categoria, "entradas")
    end
  end

  test "la base impide que una preparacion tenga categoria" do
    prep = crear_preparacion(nombre: "Salsa")
    assert_raises(ActiveRecord::StatementInvalid) do
      prep.update_column(:categoria, "postre")
    end
  end

  test "la etiqueta sale del archivo de idioma" do
    assert_equal "Platos principales", plato_de("principal", "A").categoria_etiqueta
    assert_equal "Para compartir",     plato_de("compartir", "B").categoria_etiqueta
    assert_equal "Postres",            plato_de("postre", "C").categoria_etiqueta
    assert_equal "Bebestibles",        plato_de("bebestible", "D").categoria_etiqueta
    assert_equal "Sin categoría",      crear_plato(nombre: "E").categoria_etiqueta
  end

  # --- Panel --------------------------------------------------------

  test "el panel agrupa en el orden de la carta y deja los sin clasificar al final" do
    plato_de("bebestible", "Una bebida")
    plato_de("postre",     "Un postre")
    plato_de("principal",  "Un principal")
    plato_de("compartir",  "Una tabla")
    sin = crear_plato(nombre: "Uno sin clasificar")
    agregar(sin, @queso, 30, "g")

    get root_path
    assert_response :success

    titulos = response.body.scan(/Platos principales|Para compartir|Postres|Bebestibles|Sin clasificar/)
    assert_equal [ "Platos principales", "Para compartir", "Postres", "Bebestibles", "Sin clasificar" ],
                 titulos.uniq
  end

  test "cada grupo cuenta sus platos" do
    plato_de("principal", "Principal uno")
    plato_de("principal", "Principal dos")
    plato_de("postre",    "Un postre")

    get root_path
    assert_includes response.body, "2 platos"
    assert_includes response.body, "1 plato"
  end

  test "una categoria sin platos no aparece" do
    plato_de("principal", "Solo este")
    get root_path
    assert_includes response.body, "Platos principales"
    assert_not_includes response.body, "Bebestibles"
  end

  test "las preparaciones siguen en su propia seccion" do
    crear_preparacion(nombre: "Salsa base")
    get root_path
    assert_includes response.body, "Preparaciones"
    assert_includes response.body, "Salsa base"
  end

  # --- Formulario y listado -----------------------------------------

  test "el formulario ofrece las cuatro secciones" do
    get new_receta_path
    assert_response :success
    Receta::CATEGORIAS.each do |categoria|
      assert_select "option[value=?]", categoria
    end
    assert_select "option", text: "Sin clasificar"
  end

  test "el desplegable de seccion vive en el bloque de plato" do
    get new_receta_path
    assert_select "[data-tipo-receta-target=plato] select[name=?]", "receta[categoria]"
  end

  test "se puede guardar una receta con su seccion" do
    post recetas_path, params: {
      receta: { nombre: "Tiramisu", tipo: "plato", categoria: "postre", precio_venta: 4000 }
    }
    assert_equal "postre", Receta.find_by!(nombre: "Tiramisu").categoria
  end

  test "el listado de recetas muestra la seccion" do
    plato_de("postre", "Un postre")
    crear_preparacion(nombre: "Salsa base")

    get recetas_path
    assert_response :success
    assert_includes response.body, "Postres"
  end

  test "la tabla del listado tiene tantas celdas como cabeceras" do
    plato_de("principal", "Un plato")
    get recetas_path
    cabeceras = response.body.scan(/<th /).size
    celdas    = response.body.split("<tbody").last.scan(/<td /).size
    assert_equal cabeceras, celdas, "columnas desalineadas"
  end
end
