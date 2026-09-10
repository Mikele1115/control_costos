require "test_helper"

class CruceDeUmbralTest < ActiveSupport::TestCase
  ENERO = Date.new(2026, 1, 1)
  JUNIO = Date.new(2026, 6, 1)

  setup do
    # 10 $/g en enero
    @queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000,
                               cantidad: 1, unidad: "kg", desde: ENERO)
  end

  # gramos * 10 = costo del plato
  def plato_con(nombre:, gramos:, precio_venta:)
    plato = crear_plato(nombre: nombre, precio_venta: precio_venta)
    agregar(plato, @queso, gramos, "g")
    plato
  end

  # Sube el queso y devuelve el precio nuevo
  def subir_queso_a(monto)
    crear_precio(@queso, precio: monto, cantidad: 1, unidad: "kg", desde: JUNIO)
  end

  def cruces_de(precio) = CruceDeUmbral.new(precio).cruces

  test "avisa cuando un plato pasa de sano a alto" do
    plato_con(nombre: "Sano", gramos: 30, precio_venta: 1000)   # 30 % sano
    precio = subir_queso_a(14_000)                              # -> 42 % alto

    cruces = cruces_de(precio)
    assert_equal 1, cruces.size
    assert_equal :sano, cruces.first.banda_antes
    assert_equal :alto, cruces.first.banda_despues
  end

  test "avisa cuando pasa de critico a vender bajo costo" do
    plato_con(nombre: "Critico", gramos: 60, precio_venta: 1000) # 60 % critico
    precio = subir_queso_a(20_000)                               # -> 120 % perdida

    cruce = cruces_de(precio).first
    assert_equal :critico,  cruce.banda_antes
    assert_equal :perdida,  cruce.banda_despues
  end

  test "NO avisa si empeora dentro de la misma banda" do
    plato_con(nombre: "Alto", gramos: 38, precio_venta: 1000)   # 38 % alto
    precio = subir_queso_a(11_000)                              # -> 41,8 % sigue alto

    assert_empty cruces_de(precio)
  end

  test "NO avisa si sigue en banda sana" do
    plato_con(nombre: "Sano", gramos: 25, precio_venta: 1000)   # 25 %
    precio = subir_queso_a(11_000)                              # -> 27,5 % sigue sano

    assert_empty cruces_de(precio)
  end

  test "NO avisa si empeora pero sigue en zona sana" do
    plato_con(nombre: "Barato", gramos: 20, precio_venta: 1000)  # 20 % bajo
    precio = subir_queso_a(14_000)                               # -> 28 % sano

    assert_empty cruces_de(precio), "28 % no amerita molestar a nadie"
  end

  test "NO avisa si el plato mejora" do
    plato_con(nombre: "Mejora", gramos: 50, precio_venta: 1000) # 50 % critico
    precio = crear_precio(@queso, precio: 5_000, cantidad: 1, unidad: "kg", desde: JUNIO)

    assert_empty cruces_de(precio)
  end

  test "avisa de un plato que antes no se podia costear" do
    plato = crear_plato(nombre: "Nuevo", precio_venta: 1000)
    sal   = crear_insumo(nombre: "Sal fina")
    agregar(plato, sal, 100, "g")

    # Su primer precio lo deja en 60 %: critico de entrada
    precio = crear_precio(sal, precio: 6_000, cantidad: 1, unidad: "kg", desde: JUNIO)

    cruce = cruces_de(precio).find { |c| c.plato == plato }
    assert_not_nil cruce
    assert_nil cruce.banda_antes, "antes no se podia costear"
    assert_equal :critico, cruce.banda_despues
  end

  test "ignora los platos sin precio de venta" do
    plato = crear_plato(nombre: "Sin precio")
    agregar(plato, @queso, 60, "g")

    assert_empty cruces_de(subir_queso_a(20_000))
  end

  test "recoge varios platos a la vez y los ordena por nombre" do
    plato_con(nombre: "Bravo", gramos: 30, precio_venta: 1000)
    plato_con(nombre: "Alfa",  gramos: 32, precio_venta: 1000)
    precio = subir_queso_a(14_000)

    assert_equal %w[Alfa Bravo], cruces_de(precio).map { |c| c.plato.nombre }
  end

  test "el sugerido corresponde a la fecha del precio nuevo" do
    plato = plato_con(nombre: "Sano", gramos: 30, precio_venta: 1000)
    precio = subir_queso_a(14_000)

    cruce = cruces_de(precio).first
    assert_equal plato.precio_sugerido(fecha: JUNIO), cruce.sugerido
  end
end
