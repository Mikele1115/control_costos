require "test_helper"

class InsumoBusquedaTest < ActiveSupport::TestCase
  setup do
    @lacteos = Proveedor.create!(nombre: "Lácteos del Sur")
    @verdu   = Proveedor.create!(nombre: "Verdulería El Mercado")

    @azucar  = crear_insumo(nombre: "Azúcar impalpable")
    @limon   = crear_insumo(nombre: "Limón sutil")
    @leche   = crear_insumo(nombre: "Leche entera")
    @cebolla = crear_insumo(nombre: "Cebolla")

    @leche.update!(proveedor: @lacteos)
    @cebolla.update!(proveedor: @verdu)
    @limon.update!(proveedor: @verdu)
  end

  def nombres(termino) = Insumo.buscar(termino).order(:nombre).pluck(:nombre)

  test "busca por nombre" do
    assert_equal [ "Leche entera" ], nombres("leche")
  end

  test "ignora mayusculas" do
    assert_equal [ "Leche entera" ], nombres("LECHE")
    assert_equal [ "Leche entera" ], nombres("LeChE")
  end

  test "ignora acentos en los dos sentidos" do
    assert_equal [ "Azúcar impalpable" ], nombres("azucar")
    assert_equal [ "Azúcar impalpable" ], nombres("Azúcar")
    assert_equal [ "Limón sutil" ],       nombres("limon")
  end

  test "busca tambien por el nombre del proveedor" do
    assert_equal [ "Leche entera" ], nombres("lacteos")
    assert_equal [ "Cebolla", "Limón sutil" ], nombres("verduleria")
  end

  test "coincide en cualquier parte de la palabra" do
    assert_includes nombres("ntera"), "Leche entera"
  end

  test "un termino vacio devuelve todos" do
    assert_equal Insumo.count, Insumo.buscar("").count
    assert_equal Insumo.count, Insumo.buscar("   ").count
    assert_equal Insumo.count, Insumo.buscar(nil).count
  end

  test "sin coincidencias devuelve vacio" do
    assert_empty nombres("caviar")
  end

  test "escapa los comodines de LIKE" do
    # Sin sanitize_sql_like, "%" listaria todo y "_" seria comodin
    assert_empty nombres("%")
    assert_empty nombres("_")
    assert_empty nombres("leche%")
    assert_empty nombres("_eche")
  end

  test "no duplica un insumo aunque coincidan nombre y proveedor" do
    coincide = crear_insumo(nombre: "Lácteos varios")
    coincide.update!(proveedor: @lacteos)

    assert_equal 1, Insumo.buscar("lacteos").where(id: coincide.id).count
  end

  test "encuentra insumos sin proveedor" do
    suelto = crear_insumo(nombre: "Sal a granel")
    assert_nil suelto.proveedor
    assert_includes nombres("granel"), "Sal a granel"
  end

  test "se puede encadenar con otros alcances" do
    resultado = Insumo.buscar("verduleria").order(:nombre).limit(1)
    assert_equal [ "Cebolla" ], resultado.pluck(:nombre)
  end
end
