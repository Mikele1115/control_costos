require "test_helper"

class InsumoTest < ActiveSupport::TestCase
  test "exige nombre y unidad base" do
    insumo = Insumo.new
    assert_not insumo.valid?
    assert insumo.errors[:nombre].any?
    assert insumo.errors[:unidad_base].any?
  end

  test "la unidad base solo puede ser g, ml o unidad" do
    insumo = Insumo.new(nombre: "X", unidad_base: "kg")
    assert_not insumo.valid?
    assert_includes insumo.errors[:unidad_base], "debe ser g, ml o unidad"
  end

  test "el nombre es unico sin distinguir mayusculas" do
    crear_insumo(nombre: "Cebolla")
    duplicado = Insumo.new(nombre: "cebolla", unidad_base: "g")
    assert_not duplicado.valid?
    assert duplicado.errors[:nombre].any?
  end

  test "la merma debe estar entre 0 y 99,99" do
    assert_not Insumo.new(nombre: "X", unidad_base: "g", merma_porcentaje: 100).valid?
    assert_not Insumo.new(nombre: "X", unidad_base: "g", merma_porcentaje: -1).valid?
  end

  test "la base de datos rechaza la merma invalida aunque se salte el modelo" do
    insumo = crear_insumo(merma: 20)
    assert_raises(ActiveRecord::StatementInvalid) do
      insumo.update_column(:merma_porcentaje, 100)
    end
  end

  test "la merma por defecto es cero" do
    assert_equal 0, crear_insumo.merma_porcentaje
  end

  test "el factor de merma compensa el desperdicio" do
    assert_equal BigDecimal("1.25"), crear_insumo(merma: 20).factor_merma.round(4)
    assert_equal BigDecimal(1),      crear_insumo(merma: 0).factor_merma
  end

  test "costo_de combina precio, conversion y merma" do
    # $2.000/kg = 2 $/g, merma 20%: 200 g limpios exigen comprar 250 g
    cebolla = insumo_con_precio(merma: 20, precio: 2000, cantidad: 1, unidad: "kg")
    assert_equal BigDecimal(500), cebolla.costo_de(200, "g")
  end

  test "el costo no depende de la unidad en que se exprese la cantidad" do
    harina = insumo_con_precio(precio: 30_000, cantidad: 25, unidad: "kg")
    assert_equal harina.costo_de(180, "g"), harina.costo_de("0.18", "kg")
  end

  test "usa el precio vigente a la fecha consultada" do
    harina = insumo_con_precio(precio: 30_000, cantidad: 25, unidad: "kg",
                               desde: Date.new(2026, 1, 1))
    crear_precio(harina, precio: 45_000, cantidad: 25, unidad: "kg",
                 desde: Date.new(2026, 8, 15))

    assert_equal BigDecimal("1.2"), harina.costo_unitario(Date.new(2026, 3, 1))
    assert_equal BigDecimal("1.8"), harina.costo_unitario(Date.new(2026, 9, 1))
    assert_nil harina.costo_unitario(Date.new(2025, 12, 31))
  end

  test "se niega a costear un insumo sin precio" do
    sal = crear_insumo
    assert_raises(Insumo::SinPrecio) { sal.costo_de(10, "g") }
  end

  test "no se puede borrar un insumo que tiene precios" do
    harina = insumo_con_precio(precio: 30_000, cantidad: 25, unidad: "kg")
    assert_not harina.destroy
    assert Insumo.exists?(harina.id)
  end

  test "solo admite unidades de su propia magnitud" do
    assert_equal %w[g kg], crear_insumo(unidad_base: "g").unidades_permitidas
    assert_equal %w[ml l], crear_insumo(unidad_base: "ml").unidades_permitidas

    aceite = insumo_con_precio(unidad_base: "ml", precio: 9000, cantidad: 5, unidad: "l")
    assert_raises(Unidad::Incompatible) { aceite.costo_de(100, "g") }
  end
end
