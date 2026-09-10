require "test_helper"

class ProveedoresTest < ActionDispatch::IntegrationTest
  setup do
    @nestle = Proveedor.create!(nombre: "Nestlé", contacto: "Ana Ruiz",
                                telefono: "2 2345 6789")
    @crema  = crear_insumo(nombre: "Crema de leche")
    @leche  = crear_insumo(nombre: "Leche condensada")
    [@crema, @leche].each { |i| i.update!(proveedor: @nestle) }
  end

  # --- Modelo -------------------------------------------------------

  test "exige nombre y no admite duplicados" do
    assert_not Proveedor.new.valid?
    assert_not Proveedor.new(nombre: "nestlé").valid?
  end

  test "un proveedor tiene varios insumos" do
    assert_equal 2, @nestle.cantidad_insumos
    assert_equal ["Crema de leche", "Leche condensada"],
                 @nestle.insumos.order(:nombre).pluck(:nombre)
  end

  test "un insumo puede no tener proveedor" do
    assert crear_insumo(nombre: "Sal a granel").valid?
  end

  test "borrar el proveedor deja sus insumos sin proveedor, no los borra" do
    assert_no_difference "Insumo.count" do
      @nestle.destroy
    end
    assert_nil @crema.reload.proveedor_id
    assert_nil @leche.reload.proveedor_id
  end

  test "la base tambien anula la referencia saltandose Rails" do
    otro = Proveedor.create!(nombre: "Local")
    insumo = crear_insumo(nombre: "Tomate cherry")
    insumo.update!(proveedor: otro)

    ActiveRecord::Base.connection.execute("DELETE FROM proveedores WHERE id = #{otro.id}")
    assert_nil insumo.reload.proveedor_id
  end

  # --- Pantallas de proveedores -------------------------------------

  test "el listado muestra contacto, telefono y cuantos insumos provee" do
    get proveedores_path
    assert_response :success
    assert_includes response.body, "Nestlé"
    assert_includes response.body, "Ana Ruiz"
    assert_includes response.body, "2 2345 6789"
  end

  test "el listado señala los insumos sin proveedor" do
    crear_insumo(nombre: "Sal a granel")
    get proveedores_path
    assert_includes response.body, "sin proveedor asignado"
    assert_includes response.body, "Sal a granel"
  end

  test "la ficha lista los insumos que provee" do
    get proveedor_path(@nestle)
    assert_response :success
    assert_includes response.body, "Crema de leche"
    assert_includes response.body, "Leche condensada"
  end

  test "alta valida" do
    assert_difference "Proveedor.count", 1 do
      post proveedores_path, params: {
        proveedor: { nombre: "Molinos", contacto: "Luis Paz", telefono: "111" }
      }
    end
    assert_redirected_to proveedor_path(Proveedor.find_by!(nombre: "Molinos"))
  end

  test "alta invalida devuelve 422" do
    assert_no_difference "Proveedor.count" do
      post proveedores_path, params: { proveedor: { nombre: "" } }
    end
    assert_response 422
    assert_includes response.body, "no puede estar en blanco"
  end

  test "edicion" do
    patch proveedor_path(@nestle), params: { proveedor: { contacto: "Otro" } }
    assert_equal "Otro", @nestle.reload.contacto
  end

  test "al borrar avisa cuantos insumos quedaron sueltos" do
    delete proveedor_path(@nestle)
    assert_redirected_to proveedores_path
    follow_redirect!
    assert_includes response.body, "2 insumos quedaron sin proveedor"
  end

  # --- Insumos agrupados --------------------------------------------

  test "el listado de insumos agrupa por proveedor, alfabeticamente" do
    zeta = Proveedor.create!(nombre: "Zeta")
    alfa = Proveedor.create!(nombre: "Alfa")
    crear_insumo(nombre: "De zeta").update!(proveedor: zeta)
    crear_insumo(nombre: "De alfa").update!(proveedor: alfa)
    crear_insumo(nombre: "Suelto")

    get insumos_path
    assert_response :success
    orden = %w[Alfa Nestlé Zeta].map { |n| [response.body.index(n), n] }
    assert_equal %w[Alfa Nestlé Zeta], orden.sort_by(&:first).map(&:last)
  end

  test "los insumos sin proveedor van en su propio grupo al final" do
    crear_insumo(nombre: "Suelto")
    get insumos_path
    assert_includes response.body, "Sin proveedor"
    assert_operator response.body.index("Sin proveedor"), :>,
                    response.body.index("Nestlé")
  end

  test "sin insumos sueltos no aparece ese grupo" do
    get insumos_path
    assert_not_includes response.body, "Sin proveedor"
  end

  # --- Asignacion desde el insumo -----------------------------------

  test "el formulario del insumo ofrece los proveedores" do
    get new_insumo_path
    assert_response :success
    assert_select "select[name=?]", "insumo[proveedor_id]"
    assert_select "option[value=?]", @nestle.id.to_s
    assert_select "option", text: "Sin proveedor"
  end

  test "el proveedor se guarda de verdad al crear un insumo" do
    post insumos_path, params: {
      insumo: { nombre: "Chocolate", unidad_base: "g", proveedor_id: @nestle.id }
    }
    assert_equal @nestle, Insumo.find_by!(nombre: "Chocolate").proveedor
  end

  test "se puede reasignar el proveedor de un insumo" do
    otro = Proveedor.create!(nombre: "Otro")
    patch insumo_path(@crema), params: { insumo: { proveedor_id: otro.id } }
    assert_equal otro, @crema.reload.proveedor
  end

  test "se puede dejar un insumo sin proveedor" do
    patch insumo_path(@crema), params: { insumo: { proveedor_id: "" } }
    assert_nil @crema.reload.proveedor
  end

  test "la ficha del insumo enlaza a su proveedor" do
    get insumo_path(@crema)
    assert_select "a[href=?]", proveedor_path(@nestle), text: "Nestlé"
  end

  test "el menu enlaza a proveedores" do
    get root_path
    assert_select "nav a[href=?]", proveedores_path, text: "Proveedores"
  end
end
