require "test_helper"

class AvisosMailerTest < ActionMailer::TestCase
  setup do
    @queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000,
                               cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    @plato = crear_plato(nombre: "Milanesa", precio_venta: 1000)
    agregar(@plato, @queso, 30, "g")   # 30 % de food cost
  end

  def subir_a(monto)
    crear_precio(@queso, precio: monto, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))
  end

  test "no manda nada si ningun plato cruzo el umbral" do
    correo = AvisosMailer.food_cost_alto(configurar_avisos, subir_a(10_500))

    assert_nil correo.message.to
  end

  test "no manda nada si no hay nadie en la lista" do
    configuracion = Configuracion.actual
    configuracion.update!(avisos_activos: true)

    correo = AvisosMailer.food_cost_alto(configuracion, subir_a(14_000))

    assert_nil correo.message.to
  end

  test "va a todos los destinatarios activos, no al de quien inicia sesion" do
    crear_usuario(email: "otra.persona@lasplendida.cl")
    configuracion = configurar_avisos(correo: "duenio@lasplendida.cl")
    Destinatario.create!(correo: "chef@lasplendida.cl")

    correo = AvisosMailer.food_cost_alto(configuracion, subir_a(14_000))

    assert_equal [ "chef@lasplendida.cl", "duenio@lasplendida.cl" ], correo.to
  end

  test "deja fuera a los desactivados" do
    configuracion = configurar_avisos(correo: "duenio@lasplendida.cl")
    Destinatario.create!(correo: "exchef@lasplendida.cl", activo: false)

    correo = AvisosMailer.food_cost_alto(configuracion, subir_a(14_000))

    assert_equal [ "duenio@lasplendida.cl" ], correo.to
  end

  test "cuenta que paso, a quien y cuanto deberia costar" do
    correo = AvisosMailer.food_cost_alto(configurar_avisos, subir_a(14_000))

    assert_equal "Un plato empeoró su food cost", correo.subject

    cuerpo = correo.body.encoded
    assert_match "Milanesa",   cuerpo
    assert_match "Muzzarella", cuerpo
  end

  test "el asunto pluraliza" do
    otro = crear_plato(nombre: "Lasagna", precio_venta: 1000)
    agregar(otro, @queso, 32, "g")

    correo = AvisosMailer.food_cost_alto(configurar_avisos, subir_a(14_000))

    assert_equal "2 platos empeoraron su food cost", correo.subject
  end

  test "respeta el umbral elegido: con 50 no molesta por un plato que llego a 42" do
    correo = AvisosMailer.food_cost_alto(configurar_avisos(umbral: 50), subir_a(14_000))

    assert_nil correo.message.to
  end

  test "respeta el umbral elegido: con 50 avisa cuando lo cruza" do
    correo = AvisosMailer.food_cost_alto(configurar_avisos(umbral: 50), subir_a(18_000))

    assert_equal [ "cocina@lasplendida.cl" ], correo.to, "54 % cruza el 50 %"
  end
end
