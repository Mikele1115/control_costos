require "test_helper"

class UsuariosTest < ActionDispatch::IntegrationTest
  # El setup global entra como administrador: @usuario soy "yo".

  test "la pantalla lista las cuentas y ofrece crear una" do
    crear_usuario(email: "chef@lasplendida.cl", rol: "digitador")

    get edit_configuracion_path

    assert_response :success
    assert_select "input[name=?]", "user[email_address]"
    assert_select "input[type=password][name=?]", "user[password]"
    assert_match "chef@lasplendida.cl", response.body
  end

  test "crear una cuenta con su rol" do
    assert_difference -> { User.count }, 1 do
      post users_path, params: { user: {
        email_address: "  CHEF@LaSplendida.CL ", password: "secreto123", rol: "digitador"
      } }
    end

    creado = User.find_by(email_address: "chef@lasplendida.cl")
    assert_not_nil creado, "el correo se guarda normalizado"
    assert_equal "digitador", creado.rol
    assert creado.authenticate("secreto123"), "la contraseña queda utilizable"
    assert_redirected_to edit_configuracion_path
  end

  test "un correo repetido se rechaza sin perder la pantalla" do
    crear_usuario(email: "chef@lasplendida.cl")

    assert_no_difference -> { User.count } do
      post users_path, params: { user: {
        email_address: "CHEF@lasplendida.cl", password: "secreto123", rol: "digitador"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "li", text: /ya tiene cuenta/
    # Se vuelve a dibujar la pantalla de ajustes entera, no solo el error.
    assert_select "input[type=number][name=?]", "configuracion[umbral_aviso]"
  end

  test "un rol inventado no cuela por mas que venga en el formulario" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: {
        email_address: "colado@lasplendida.cl", password: "secreto123", rol: "gerente"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "li", text: /no es un rol válido/
  end

  test "cambiar el rol de otra cuenta" do
    otro = crear_usuario(email: "chef@lasplendida.cl", rol: "observador")

    patch user_path(otro), params: { user: { rol: "digitador" } }

    assert_equal "digitador", otro.reload.rol
    assert_redirected_to edit_configuracion_path
  end

  test "eliminar otra cuenta" do
    otro = crear_usuario(email: "chef@lasplendida.cl", rol: "digitador")

    assert_difference -> { User.count }, -1 do
      delete user_path(otro)
    end
  end

  # --- la regla que impide quedarse sin administradores -------------

  test "no puedo cambiarme el rol a mi mismo" do
    patch user_path(@usuario), params: { user: { rol: "observador" } }

    assert_equal "administrador", @usuario.reload.rol
    assert_match "tu propia cuenta", flash[:alert]
  end

  test "no puedo eliminar mi propia cuenta" do
    assert_no_difference -> { User.count } do
      delete user_path(@usuario)
    end

    assert_match "tu propia cuenta", flash[:alert]
  end

  test "siempre queda al menos un administrador" do
    otro = crear_usuario(email: "chef@lasplendida.cl", rol: "administrador")

    # Puedo degradar al otro administrador...
    patch user_path(otro), params: { user: { rol: "observador" } }
    assert_equal "observador", otro.reload.rol

    # ...pero entonces yo soy el ultimo, y a mi no puedo tocarme.
    patch user_path(@usuario), params: { user: { rol: "observador" } }
    assert_equal 1, User.where(rol: "administrador").count
  end

  test "pide sesion" do
    delete session_path

    assert_no_difference -> { User.count } do
      post users_path, params: { user: {
        email_address: "colado@lasplendida.cl", password: "secreto123", rol: "administrador"
      } }
    end
    assert_redirected_to new_session_path
  end
end
