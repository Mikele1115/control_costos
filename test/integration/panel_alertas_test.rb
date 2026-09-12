require "test_helper"

class PanelAlertasTest < ActionDispatch::IntegrationTest
  setup do
    @queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000, cantidad: 1, unidad: "kg")
  end

  # costo = gramos * 10
  def plato_con(nombre:, gramos:, precio_venta:)
    plato = crear_plato(nombre: nombre, precio_venta: precio_venta)
    agregar(plato, @queso, gramos, "g")
    plato
  end

  # Solo el bloque de aviso, entre su titulo y su pie. Recortar por
  # un texto que puede no existir devolveria la pagina entera y las
  # aserciones encontrarian nombres en la tabla de abajo.
  def aviso
    inicio = response.body.index("necesita")
    return "" if inicio.nil?
    fin = response.body.index("Ver el comparativo completo", inicio)
    response.body[inicio...fin]
  end

  test "sin platos problematicos no aparece el aviso" do
    plato_con(nombre: "Plato Sano", gramos: 30, precio_venta: 1000)  # 30 %
    get root_path
    assert_response :success
    assert_not_includes response.body, "necesita atención"
    assert_not_includes response.body, "necesitan atención"
  end

  test "avisa de un plato en banda alta" do
    plato_con(nombre: "Plato Alto", gramos: 40, precio_venta: 1000)  # 40 %
    get root_path
    assert_includes response.body, "Un plato necesita atención"
    assert_includes aviso, "Plato Alto"
  end

  test "el aviso dice a cuanto se vende, a cuanto deberia y cuanto falta" do
    plato_con(nombre: "Plato Alto", gramos: 40, precio_venta: 1000)  # costo 400
    get root_path
    assert_includes aviso, "$1.000,00"   # precio actual
    assert_includes aviso, "$1.333,33"   # sugerido: 400 / 0,30
    assert_includes aviso, "+$333,33"    # la brecha
  end

  test "marca aparte los platos que se venden bajo costo" do
    plato_con(nombre: "Plato En Perdida", gramos: 100, precio_venta: 500) # costo 1000
    get root_path
    assert_includes aviso, "se vende bajo costo"
    assert_includes aviso, "Plato En Perdida"
  end

  test "ordena los avisos por food cost, el peor arriba" do
    plato_con(nombre: "Plato Alto",    gramos: 40,  precio_venta: 1000) # 40 %
    plato_con(nombre: "Plato Critico", gramos: 60,  precio_venta: 1000) # 60 %
    plato_con(nombre: "Plato Perdido", gramos: 100, precio_venta: 500)  # 200 %

    get root_path
    orden = %w[Perdido Critico Alto].map { |n| [ aviso.index("Plato #{n}"), n ] }
    assert_equal %w[Perdido Critico Alto], orden.sort_by(&:first).map(&:last)
  end

  test "los platos sanos no entran en el aviso" do
    plato_con(nombre: "Plato Sano", gramos: 30, precio_venta: 1000)  # 30 %
    plato_con(nombre: "Plato Alto", gramos: 40, precio_venta: 1000)  # 40 %

    get root_path
    assert_includes aviso, "Plato Alto"
    assert_not_includes aviso, "Plato Sano"
  end

  test "un plato sin precio de venta no dispara el aviso" do
    plato = crear_plato(nombre: "Plato Sin Precio")
    agregar(plato, @queso, 100, "g")
    get root_path
    assert_response :success
    assert_not_includes response.body, "necesita atención"
  end

  test "un plato que no se puede costear no dispara el aviso" do
    plato = crear_plato(nombre: "Plato Roto", precio_venta: 100)
    agregar(plato, crear_insumo(nombre: "Sal sin precio"), 10, "g")
    get root_path
    assert_response :success
    assert_not_includes response.body, "necesita atención"
  end

  test "el aviso enlaza al comparativo y a cada plato" do
    p = plato_con(nombre: "Plato Alto", gramos: 40, precio_venta: 1000)
    get root_path
    assert_select "a[href=?]", receta_path(p)
    assert_select "a[href^=?]", margenes_path
  end

  test "el aviso respeta la fecha consultada" do
    p = plato_con(nombre: "Plato Alto", gramos: 40, precio_venta: 1000)
    get root_path(fecha: "2025-01-01")   # anterior al primer precio
    assert_response :success
    assert_not_includes response.body, "necesita atención"
  end

  # --- las bandas viven en el modelo, no en el helper ---

  test "los umbrales son de Receta y el helper los respeta" do
    assert_equal :bajo,    Receta.banda_para(BigDecimal("24.9"))
    assert_equal :sano,    Receta.banda_para(BigDecimal(Receta::UMBRAL_BAJO))
    assert_equal :alto,    Receta.banda_para(BigDecimal(Receta::UMBRAL_ALTO))
    assert_equal :critico, Receta.banda_para(BigDecimal(Receta::UMBRAL_CRITICO))
    assert_equal :perdida, Receta.banda_para(BigDecimal(100))
    assert_nil Receta.banda_para(nil)
  end

  test "requiere_atencion? solo para alto, critico y perdida" do
    assert_not plato_con(nombre: "Sano", gramos: 30, precio_venta: 1000).requiere_atencion?
    assert     plato_con(nombre: "Alto", gramos: 40, precio_venta: 1000).requiere_atencion?
    assert     plato_con(nombre: "Peor", gramos: 100, precio_venta: 500).requiere_atencion?
  end

  test "el semaforo pinta cada banda con un color distinto" do
    plato_con(nombre: "Plato Bajo",    gramos: 20,  precio_venta: 1000) # 20 %
    plato_con(nombre: "Plato Sano",    gramos: 30,  precio_venta: 1000) # 30 %
    plato_con(nombre: "Plato Alto",    gramos: 40,  precio_venta: 1000) # 40 %
    plato_con(nombre: "Plato Critico", gramos: 60,  precio_venta: 1000) # 60 %
    plato_con(nombre: "Plato Perdido", gramos: 100, precio_venta: 500)  # 200 %

    get root_path
    assert_select "span.bg-sky-100",     text: "20,0 %"
    assert_select "span.bg-emerald-100", text: "30,0 %"
    assert_select "span.bg-amber-100",   text: "40,0 %"
    assert_select "span.bg-rose-100",    text: "60,0 %"
    assert_select "span.bg-rose-200",    text: "200,0 %"
  end
end
