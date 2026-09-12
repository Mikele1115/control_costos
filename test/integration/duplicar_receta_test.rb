require "test_helper"

class DuplicarRecetaTest < ActionDispatch::IntegrationTest
  setup do
    @queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000, cantidad: 1, unidad: "kg")
    @salsa = crear_preparacion(nombre: "Salsa de tomate", rinde: 1000, unidad: "g")
    agregar(@salsa, @queso, 100, "g")

    @plato = crear_plato(nombre: "Milanesa", precio_venta: 2800)
    agregar(@plato, @salsa, 200, "g")
    agregar(@plato, @queso, 50,  "g")
  end

  test "la copia lleva el sufijo y conserva los datos" do
    assert_difference "Receta.count", 1 do
      post duplicar_receta_path(@plato)
    end

    copia = Receta.find_by!(nombre: "Milanesa (copia)")
    assert_redirected_to receta_path(copia)
    assert_equal "plato", copia.tipo
    assert_equal @plato.precio_venta, copia.precio_venta
  end

  test "copia todos los renglones con sus cantidades y unidades" do
    post duplicar_receta_path(@plato)
    copia = Receta.find_by!(nombre: "Milanesa (copia)")

    assert_equal 2, copia.ingredientes.count
    originales = @plato.ingredientes.map { |i| [ i.insumable, i.cantidad, i.unidad ] }
    copiados   = copia.ingredientes.map  { |i| [ i.insumable, i.cantidad, i.unidad ] }
    assert_equal originales.sort_by { |o| o.first.id }, copiados.sort_by { |c| c.first.id }
  end

  test "la copia apunta a la MISMA sub-receta, no a un clon" do
    post duplicar_receta_path(@plato)
    copia = Receta.find_by!(nombre: "Milanesa (copia)")

    sub = copia.ingredientes.find { |i| i.insumable_type == "Receta" }
    assert_equal @salsa.id, sub.insumable_id
    assert_equal 1, Receta.where(nombre: "Salsa de tomate").count, "no debe clonar la salsa"
  end

  test "la copia cuesta exactamente lo mismo que el original" do
    post duplicar_receta_path(@plato)
    copia = Receta.find_by!(nombre: "Milanesa (copia)")

    assert_equal @plato.costo_total, copia.costo_total
    assert_equal @plato.food_cost,   copia.food_cost
  end

  test "duplicar dos veces numera las copias" do
    post duplicar_receta_path(@plato)
    post duplicar_receta_path(@plato)

    assert Receta.exists?(nombre: "Milanesa (copia)")
    assert Receta.exists?(nombre: "Milanesa (copia 2)")
  end

  test "duplicar una copia no encadena sufijos" do
    post duplicar_receta_path(@plato)
    copia = Receta.find_by!(nombre: "Milanesa (copia)")
    post duplicar_receta_path(copia)

    assert Receta.exists?(nombre: "Milanesa (copia 2)")
    assert_not Receta.exists?(nombre: "Milanesa (copia) (copia)")
  end

  test "la copia no hereda donde se usaba el original" do
    otro = crear_plato(nombre: "Otro plato")
    agregar(otro, @salsa, 50, "g")
    assert_equal 2, @salsa.usos.count   # la milanesa del setup y este

    post duplicar_receta_path(@salsa)
    copia = Receta.find_by!(nombre: "Salsa de tomate (copia)")

    assert_equal 0, copia.usos.count
    assert_equal 2, @salsa.reload.usos.count
  end

  test "duplicar una preparacion conserva su rendimiento" do
    post duplicar_receta_path(@salsa)
    copia = Receta.find_by!(nombre: "Salsa de tomate (copia)")

    assert copia.preparacion?
    assert_equal @salsa.rendimiento_cantidad, copia.rendimiento_cantidad
    assert_equal @salsa.rendimiento_unidad,   copia.rendimiento_unidad
    assert_equal @salsa.costo_por_unidad_base, copia.costo_por_unidad_base
  end

  test "es transaccional: si falla un renglon no queda media receta" do
    # update_column se salta las validaciones de Rails, pero NO las
    # restricciones de PostgreSQL. Para forzar el fallo hay que romper
    # algo que la base no vigile: una unidad de otra magnitud.
    @plato.ingredientes.first.update_column(:unidad, "l")

    assert_no_difference "Receta.count" do
      post duplicar_receta_path(@plato)
    end
    assert_redirected_to receta_path(@plato)
    follow_redirect!
    assert_includes response.body, "No se pudo duplicar"
  end

  test "la ficha ofrece el boton como POST, no como enlace" do
    get receta_path(@plato)
    assert_select "form[action=?][method=?]", duplicar_receta_path(@plato), "post"
  end
end
