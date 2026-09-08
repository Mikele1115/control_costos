require "test_helper"

class IngredienteTest < ActiveSupport::TestCase
  test "la unidad debe ser compatible con el ingrediente" do
    plato  = crear_plato
    harina = crear_insumo(unidad_base: "g")

    renglon = Ingrediente.new(receta: plato, insumable: harina, cantidad: 1, unidad: "l")
    assert_not renglon.valid?
    assert_match(/magnitudes distintas/, renglon.errors[:unidad].first)
  end

  test "tambien valida la unidad contra una sub-receta" do
    fondo = crear_preparacion(rinde: 3, unidad: "l")   # base ml
    plato = crear_plato

    assert_not Ingrediente.new(receta: plato, insumable: fondo,
                               cantidad: 200, unidad: "g").valid?
    assert Ingrediente.new(receta: plato, insumable: fondo,
                           cantidad: 200, unidad: "ml").valid?
  end

  test "un plato no puede usarse como ingrediente" do
    renglon = Ingrediente.new(receta: crear_preparacion, insumable: crear_plato,
                              cantidad: 1, unidad: "g")
    assert_not renglon.valid?
    assert_match(/convertilo en preparacion/, renglon.errors[:insumable].first)
  end

  test "no se repite el mismo ingrediente en una receta" do
    plato  = crear_plato
    harina = crear_insumo
    agregar(plato, harina, 100, "g")

    repetido = Ingrediente.new(receta: plato, insumable: harina, cantidad: 50, unidad: "g")
    assert_not repetido.valid?
    assert_includes repetido.errors[:insumable_id], "ya esta en esta receta"
  end

  test "un mismo insumo si puede estar en recetas distintas" do
    harina = crear_insumo
    agregar(crear_plato, harina, 100, "g")
    assert agregar(crear_plato, harina, 200, "g").persisted?
  end

  test "rechaza el ciclo directo A -> A" do
    salsa = crear_preparacion
    renglon = Ingrediente.new(receta: salsa, insumable: salsa, cantidad: 10, unidad: "g")
    assert_not renglon.valid?
    assert_match(/no puede contenerse a si misma/, renglon.errors[:insumable].first)
  end

  test "rechaza el ciclo indirecto A -> B -> A" do
    a = crear_preparacion
    b = crear_preparacion
    agregar(b, a, 10, "g")

    renglon = Ingrediente.new(receta: a, insumable: b, cantidad: 10, unidad: "g")
    assert_not renglon.valid?
    assert_match(/generaria un ciclo/, renglon.errors[:insumable].first)
  end

  test "detecta el ciclo aunque la asociacion este cacheada y obsoleta" do
    a = crear_preparacion
    b = crear_preparacion
    b.ingredientes.load              # cachea la lista vacia
    agregar(b, a, 10, "g")           # se crea por fuera: el cache no se entera
    assert_equal 0, b.ingredientes.size, "el cache deberia seguir obsoleto"

    renglon = Ingrediente.new(receta: a, insumable: b, cantidad: 10, unidad: "g")
    assert_not renglon.valid?, "debe consultar la base, no el cache"
  end

  test "rechaza un ciclo de cuatro saltos" do
    a, b, c, d = 4.times.map { crear_preparacion }
    agregar(b, a, 10, "g")
    agregar(c, b, 10, "g")
    agregar(d, c, 10, "g")

    assert_not Ingrediente.new(receta: a, insumable: d,
                               cantidad: 10, unidad: "g").valid?
  end

  test "permite el anidamiento profundo sin ciclo" do
    a, b, c, d, e = 5.times.map { crear_preparacion }
    agregar(b, a, 10, "g")
    agregar(c, b, 10, "g")
    agregar(d, c, 10, "g")

    assert Ingrediente.new(receta: e, insumable: d, cantidad: 10, unidad: "g").valid?
  end

  test "exige cantidad positiva" do
    assert_not Ingrediente.new(receta: crear_plato, insumable: crear_insumo,
                               cantidad: 0, unidad: "g").valid?
  end
end
