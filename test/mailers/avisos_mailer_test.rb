require "test_helper"

class AvisosMailerTest < ActionMailer::TestCase
  setup do
    @usuario = crear_usuario(email: "cocina@lasplendida.cl")
    @queso   = insumo_con_precio(nombre: "Muzzarella", precio: 10_000,
                                 cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    @plato   = crear_plato(nombre: "Milanesa", precio_venta: 1000)
    agregar(@plato, @queso, 30, "g")   # 30 % sano
  end

  def subir_a(monto)
    crear_precio(@queso, precio: monto, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))
  end

  test "no manda nada si ningun plato empeoro de banda" do
    correo = AvisosMailer.food_cost_alto(@usuario, subir_a(10_500))
    assert_nil correo.message.to
  end

  test "cuenta que paso, a quien y cuanto deberia costar" do
    correo = AvisosMailer.food_cost_alto(@usuario, subir_a(14_000))   # 30 % -> 42 %

    assert_equal ["cocina@lasplendida.cl"], correo.to
    assert_equal "Un plato empeoró su food cost", correo.subject

    cuerpo = correo.body.encoded
    assert_match "Milanesa", cuerpo
    assert_match "Muzzarella", cuerpo
  end

  test "el asunto pluraliza" do
    otro = crear_plato(nombre: "Lasagna", precio_venta: 1000)
    agregar(otro, @queso, 32, "g")

    correo = AvisosMailer.food_cost_alto(@usuario, subir_a(14_000))
    assert_equal "2 platos empeoraron su food cost", correo.subject
  end
end
