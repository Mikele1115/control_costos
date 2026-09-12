require "test_helper"

class PermisosTest < ActionDispatch::IntegrationTest
  # El setup global abre sesion como administrador; cada test vuelve a
  # entrar con el rol que le interesa.
  def entrar_como(rol)
    sign_out
    sign_in_as(crear_usuario(rol: rol))
  end

  def insumo_nuevo
    { insumo: { nombre: "Colado #{SecureRandom.hex(3)}", unidad_base: "g", merma_porcentaje: 0 } }
  end

  def cuenta_nueva(rol)
    { user: { email_address: "colado@lasplendida.cl", password: "secreto123", rol: rol } }
  end

  # --- observador: mira y nada mas ---------------------------------

  test "el observador puede mirar todas las pantallas de consulta" do
    entrar_como("observador")

    [ root_path, insumos_path, recetas_path, margenes_path, proveedores_path ].each do |pantalla|
      get pantalla
      assert_response :success, "deberia poder ver #{pantalla}"
    end
  end

  test "el observador no puede crear" do
    entrar_como("observador")

    assert_no_difference -> { Insumo.count } do
      post insumos_path, params: insumo_nuevo
    end
    assert_response :see_other
    assert_match "solo lectura", flash[:alert]
  end

  test "el observador no puede borrar" do
    insumo = crear_insumo(nombre: "Cebolla")
    entrar_como("observador")

    assert_no_difference -> { Insumo.count } do
      delete insumo_path(insumo)
    end
  end

  test "el observador no puede cargar un precio" do
    insumo = crear_insumo(nombre: "Cebolla")
    entrar_como("observador")

    assert_no_difference -> { PrecioInsumo.count } do
      post insumo_precio_insumos_path(insumo), params: { precio_insumo: {
        precio_compra: 1000, cantidad_compra: 1, unidad_compra: "kg", vigente_desde: Date.current
      } }
    end
  end

  test "el observador tampoco puede crear cuentas" do
    entrar_como("observador")

    assert_no_difference -> { User.count } do
      post users_path, params: cuenta_nueva("administrador")
    end
  end

  test "el observador si puede cerrar sesion" do
    entrar_como("observador")

    delete session_path
    assert_redirected_to new_session_path
  end

  # --- digitador: carga datos, no reparte permisos ------------------

  test "el digitador si puede crear" do
    entrar_como("digitador")

    assert_difference -> { Insumo.count }, 1 do
      post insumos_path, params: insumo_nuevo
    end
  end

  test "el digitador no entra a Ajustes ni para mirar" do
    entrar_como("digitador")

    get edit_configuracion_path
    assert_redirected_to root_path
    assert_match "administrador", flash[:alert]
  end

  test "al digitador no se le muestra siquiera el enlace de Ajustes" do
    entrar_como("digitador")

    get root_path
    assert_select "a[href=?]", edit_configuracion_path, count: 0
  end

  test "el digitador no puede agregar destinatarios" do
    entrar_como("digitador")

    assert_no_difference -> { Destinatario.count } do
      post destinatarios_path, params: { destinatario: { correo: "colado@lasplendida.cl" } }
    end
  end

  # El caso mas grave: escribir SI puede, asi que la regla general no lo
  # detiene. Lo detiene `solo_administradores` en UsersController.
  test "el digitador no puede crear cuentas ni repartir roles" do
    otro = crear_usuario(email: "chef@lasplendida.cl", rol: "observador")
    entrar_como("digitador")

    assert_no_difference -> { User.count } do
      post users_path, params: cuenta_nueva("administrador")
    end

    patch user_path(otro), params: { user: { rol: "administrador" } }
    assert_equal "observador", otro.reload.rol, "no puede ascender a nadie"
  end

  # --- administrador: todo ------------------------------------------

  test "al administrador si se le muestra el enlace de Ajustes" do
    get root_path
    assert_select "a[href=?]", edit_configuracion_path, count: 1
  end

  test "el administrador entra a Ajustes y puede escribir ahi" do
    get edit_configuracion_path
    assert_response :success

    assert_difference -> { Destinatario.count }, 1 do
      post destinatarios_path, params: { destinatario: { correo: "chef@lasplendida.cl" } }
    end
  end

  # --- lo que se ve, no solo lo que se puede ------------------------
  #
  # Rechazar en el servidor es lo que da seguridad, pero ofrecer un
  # boton que va a rebotar es una mentira en la pantalla.

  test "el observador no ve los botones de escritura" do
    insumo = crear_insumo(nombre: "Cebolla")
    entrar_como("observador")

    get insumos_path
    assert_select "a[href=?]", new_insumo_path, count: 0

    get insumo_path(insumo)
    assert_select "a[href=?]", edit_insumo_path(insumo), count: 0
    assert_select "a[href=?]", new_insumo_precio_insumo_path(insumo), count: 0
  end

  test "el observador no ve el panel de agregar ingrediente" do
    plato = crear_plato(nombre: "Milanesa", precio_venta: 1000)
    entrar_como("observador")

    get receta_path(plato)
    assert_response :success
    assert_select "form[action=?]", receta_ingredientes_path(plato), count: 0
  end

  test "el digitador si ve los botones" do
    insumo = crear_insumo(nombre: "Cebolla")
    entrar_como("digitador")

    get insumos_path
    assert_select "a[href=?]", new_insumo_path, count: 1

    get insumo_path(insumo)
    assert_select "a[href=?]", edit_insumo_path(insumo), count: 1
  end

  # `new` y `edit` son GET, pero existen solo para escribir despues.

  test "el observador no puede ni abrir el formulario de alta" do
    entrar_como("observador")

    get new_insumo_path
    assert_redirected_to root_path
    assert_match "solo lectura", flash[:alert]
  end

  test "el observador no puede abrir el formulario de edicion" do
    insumo = crear_insumo(nombre: "Cebolla")
    entrar_como("observador")

    get edit_insumo_path(insumo)
    assert_redirected_to root_path
  end

  test "el digitador si puede abrir los formularios" do
    insumo = crear_insumo(nombre: "Cebolla")
    entrar_como("digitador")

    get new_insumo_path
    assert_response :success

    get edit_insumo_path(insumo)
    assert_response :success
  end

  # --- quien soy, en la barra de arriba -----------------------------

  test "la barra muestra el correo y el rol de quien entro" do
    sign_out
    sign_in_as(crear_usuario(email: "chef@lasplendida.cl", rol: "digitador"))

    get root_path

    assert_select "header", text: /chef@lasplendida\.cl/
    assert_select "header span", text: "Digitador"
  end

  test "la insignia cambia con el rol" do
    entrar_como("observador")
    get root_path
    assert_select "header span", text: "Observador"

    entrar_como("administrador")
    get root_path
    assert_select "header span", text: "Administrador"
  end
end
