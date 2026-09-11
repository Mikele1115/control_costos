require "test_helper"

class RecetaTest < ActiveSupport::TestCase
  test "un plato solo necesita nombre y tipo" do
    receta = Receta.new(nombre: "Milanesa", tipo: "plato")
    assert receta.valid?
  end

  test "una preparacion exige rendimiento con cantidad y unidad" do
    receta = Receta.new(nombre: "Salsa", tipo: "preparacion")
    assert_not receta.valid?
    assert receta.errors[:rendimiento_cantidad].any?
    assert receta.errors[:rendimiento_unidad].any?
  end

  test "rechaza una unidad de rendimiento inexistente" do
    receta = Receta.new(nombre: "Salsa", tipo: "preparacion",
                        rendimiento_cantidad: 2000, rendimiento_unidad: "litros")
    assert_not receta.valid?
    assert receta.errors[:rendimiento_unidad].any?
  end

  test "la base de datos exige rendimiento a las preparaciones" do
    prep = crear_preparacion(rinde: 1000, unidad: "g")
    assert_raises(ActiveRecord::StatementInvalid) do
      prep.update_column(:rendimiento_cantidad, nil)
    end
  end

  test "deduce su unidad base del rendimiento" do
    assert_equal "g",  crear_preparacion(rinde: 2000, unidad: "g").unidad_base
    assert_equal "ml", crear_preparacion(rinde: 3, unidad: "l").unidad_base
    assert_nil crear_plato.unidad_base
  end

  test "el costo de un plato es lo que cuesta servirlo" do
    plato  = crear_plato
    harina = insumo_con_precio(precio: 30_000, cantidad: 25, unidad: "kg") # 1,20 $/g
    queso  = insumo_con_precio(precio: 9_500,  cantidad: 1,  unidad: "kg") # 9,50 $/g
    agregar(plato, harina, 200, "g")  # 240
    agregar(plato, queso,  100, "g")  # 950

    assert_equal BigDecimal(1190), plato.costo_total
  end

  test "una preparacion sabe cuanto cuesta cada unidad suya" do
    salsa  = crear_preparacion(rinde: 2000, unidad: "g")
    tomate = insumo_con_precio(precio: 1200, cantidad: 1, unidad: "kg") # 1,20 $/g
    agregar(salsa, tomate, 2, "kg")   # 2000 g x 1,20 = 2400

    assert_equal BigDecimal(2400),  salsa.costo_total
    assert_equal BigDecimal("1.2"), salsa.costo_por_unidad_base
  end

  test "costea una sub-receta de forma recursiva" do
    tomate = insumo_con_precio(precio: 1200, cantidad: 1, unidad: "kg")
    salsa  = crear_preparacion(rinde: 2000, unidad: "g")
    agregar(salsa, tomate, 2, "kg")   # salsa: 2400 en total -> 1,20 $/g

    plato = crear_plato
    agregar(plato, salsa, 400, "g")   # 400 x 1,20 = 480

    assert_equal BigDecimal(480), plato.costo_total
  end

  test "un plato no se puede dosificar dentro de otra receta" do
    assert_raises(Receta::NoDosificable) { crear_plato.costo_de(100, "g") }
  end

  test "food cost, margen y precio sugerido salen del costo del plato" do
    plato = crear_plato(precio_venta: 1000)
    queso = insumo_con_precio(precio: 10_000, cantidad: 1, unidad: "kg") # 10 $/g
    agregar(plato, queso, 25, "g")   # 250

    assert_equal BigDecimal(250), plato.costo_total
    assert_equal BigDecimal(25),  plato.food_cost
    assert_equal BigDecimal(750), plato.margen_bruto
    # para un food cost del 30%: 250 / 0,30
    assert_in_delta 833.33, plato.precio_sugerido.to_f, 0.01
  end

  test "sin precio de venta no hay food cost" do
    plato = crear_plato(precio_venta: nil)
    agregar(plato, insumo_con_precio(precio: 1000, cantidad: 1, unidad: "kg"), 10, "g")
    assert_nil plato.food_cost
  end

  test "el costo cambia con la fecha porque cambia el precio del insumo" do
    plato = crear_plato
    carne = insumo_con_precio(precio: 12_000, cantidad: 1, unidad: "kg",
                              desde: Date.new(2026, 1, 1))
    crear_precio(carne, precio: 18_000, cantidad: 1, unidad: "kg",
                 desde: Date.new(2026, 6, 1))
    agregar(plato, carne, 100, "g")

    assert_equal BigDecimal(1200), plato.costo_total(fecha: Date.new(2026, 5, 1))
    assert_equal BigDecimal(1800), plato.costo_total(fecha: Date.new(2026, 9, 1))
  end

  test "se niega a costear si falta el precio de algun insumo" do
    plato = crear_plato
    agregar(plato, crear_insumo, 10, "g")

    assert_not plato.costeable?
    assert_raises(Insumo::SinPrecio) { plato.costo_total }
  end

  test "no se puede borrar una preparacion en uso" do
    salsa = crear_preparacion
    plato = crear_plato
    agregar(plato, salsa, 100, "g")

    assert_not salsa.destroy
    assert Receta.exists?(salsa.id)
  end

  test "borrar una receta se lleva sus renglones" do
    plato = crear_plato
    agregar(plato, crear_insumo, 10, "g")
    agregar(plato, crear_insumo, 20, "g")

    assert_difference "Ingrediente.count", -2 do
      plato.destroy
    end
  end

  # --- el precio de memoizar el costo -------------------------------

  test "el costo se calcula una sola vez por fecha" do
    queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000,
                              cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    plato = crear_plato(nombre: "Milanesa", precio_venta: 1000)
    agregar(plato, queso, 30, "g")

    consultas = 0
    suscriptor = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, datos|
      consultas += 1 unless %w[SCHEMA TRANSACTION].include?(datos[:name])
    end
    3.times { plato.costo_total(fecha: Date.new(2026, 6, 1)) }
    ActiveSupport::Notifications.unsubscribe(suscriptor)

    assert_operator consultas, :<=, 3, "la segunda y tercera vez no deberian preguntar nada"
  end

  test "cada fecha se memoriza por separado" do
    queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000,
                              cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    crear_precio(queso, precio: 20_000, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))
    plato = crear_plato(nombre: "Milanesa", precio_venta: 1000)
    agregar(plato, queso, 100, "g")

    enero = plato.costo_total(fecha: Date.new(2026, 3, 1))
    junio = plato.costo_total(fecha: Date.new(2026, 7, 1))

    assert_equal BigDecimal(1000), enero
    assert_equal BigDecimal(2000), junio, "memorizar enero no puede contaminar junio"
  end

  # El precio de memoizar, dicho en voz alta: el objeto conserva su
  # calculo. Los controladores redirigen despues de escribir, asi que
  # cada peticion trabaja con recetas recien cargadas.
  test "el costo memorizado no se entera de un ingrediente nuevo hasta recargar" do
    queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000,
                              cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    plato = crear_plato(nombre: "Milanesa", precio_venta: 1000)
    agregar(plato, queso, 30, "g")

    fecha    = Date.new(2026, 6, 1)
    original = plato.costo_total(fecha: fecha)

    carne = insumo_con_precio(nombre: "Carne", precio: 20_000,
                              cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    agregar(plato, carne, 70, "g")

    assert_equal original, plato.costo_total(fecha: fecha),
                 "el mismo objeto conserva el calculo que ya hizo"
    assert_operator plato.reload.costo_total(fecha: fecha), :>, original,
                    "recargado si ve el ingrediente nuevo"
  end
end
