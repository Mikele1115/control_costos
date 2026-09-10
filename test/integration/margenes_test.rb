require "test_helper"

class MargenesTest < ActionDispatch::IntegrationTest
  setup do
    queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000, cantidad: 1, unidad: "kg") # 10 $/g

    # margen 3000 · food cost 25 % · costo 1000
    @caro = crear_plato(nombre: "Plato Caro", precio_venta: 4000)
    agregar(@caro, queso, 100, "g")

    # margen 800 · food cost 20 % · costo 200
    @eficiente = crear_plato(nombre: "Plato Eficiente", precio_venta: 1000)
    agregar(@eficiente, queso, 20, "g")

    # margen 200 · food cost 71,4 % · costo 500
    @flojo = crear_plato(nombre: "Plato Flojo", precio_venta: 700)
    agregar(@flojo, queso, 50, "g")
  end

  # Solo dentro de la tabla: el resumen de arriba nombra al de mejor
  # margen, y esa mencion falsearia el orden.
  def orden_en_pagina
    tabla = response.body.split("Detalle").last
    %w[Caro Eficiente Flojo]
      .map { |n| [tabla.index("Plato #{n}"), n] }
      .sort_by(&:first)
      .map(&:last)
  end

  test "por defecto ordena por margen, de mayor a menor" do
    get margenes_path
    assert_response :success
    assert_equal %w[Caro Eficiente Flojo], orden_en_pagina
  end

  test "ordena por food cost, del peor al mejor" do
    get margenes_path(orden: "food_cost")
    assert_equal %w[Flojo Caro Eficiente], orden_en_pagina
  end

  test "ordena por costo, del mas caro al mas barato" do
    get margenes_path(orden: "costo")
    assert_equal %w[Caro Flojo Eficiente], orden_en_pagina
  end

  test "ordena por nombre" do
    get margenes_path(orden: "nombre")
    assert_equal %w[Caro Eficiente Flojo], orden_en_pagina
  end

  test "un orden inventado cae en el de por defecto" do
    get margenes_path(orden: "loquesea")
    assert_response :success
    assert_equal %w[Caro Eficiente Flojo], orden_en_pagina
  end

  test "muestra costo, margen y food cost de cada plato" do
    get margenes_path
    assert_includes response.body, "$1.000,00"  # costo del caro
    assert_includes response.body, "$3.000,00"  # su margen
    assert_includes response.body, "25,0 %"
    assert_includes response.body, "71,4 %"
  end

  test "el resumen cuenta los platos fuera de banda" do
    get margenes_path
    assert_includes response.body, "1 de 3"     # solo el flojo pasa de 35 %
  end

  test "la brecha dice cuanto habria que subir cada plato" do
    get margenes_path
    # el flojo cuesta 500: para un food cost del 30 % deberia valer 1666,67
    assert_includes response.body, "$1.666,67"
    assert_includes response.body, "+$966,67"
  end

  test "un plato sin precio de venta no compite y se avisa" do
    sin_pvp = crear_plato(nombre: "Plato Sin Precio")
    agregar(sin_pvp, Insumo.first, 10, "g")

    get margenes_path
    assert_includes response.body, "sin precio de venta cargado"
    tabla = response.body.split("Detalle").last
    assert_operator tabla.index("Plato Sin Precio"), :>,
                    tabla.index("Plato Flojo"),
                    "los platos sin datos van al final"
  end

  test "un plato que no se puede costear se marca aparte" do
    roto = crear_plato(nombre: "Plato Roto", precio_venta: 5000)
    agregar(roto, crear_insumo(nombre: "Sal sin precio"), 10, "g")

    get margenes_path
    assert_response :success
    assert_includes response.body, "falta el precio de algún insumo"
  end

  test "una fecha ilegible cae en hoy en vez de reventar" do
    get margenes_path(fecha: "melon")
    assert_response :success
    assert_equal %w[Caro Eficiente Flojo], orden_en_pagina
  end

  test "el menu enlaza a la pantalla" do
    get root_path
    assert_select "nav a[href=?]", margenes_path, text: "Márgenes"
  end

  test "los plurales salen en castellano" do
    get margenes_path
    assert_includes response.body, "3 platos con costo"
  end

  test "un orden invalido no se refleja en la pagina" do
    get margenes_path(orden: "loquesea")
    # El formulario de fecha arrastra el orden actual: debe ser uno
    # de los validos, no lo que mando el usuario.
    assert_select "input[name=orden][value=?]", "margen"
    assert_not_includes response.body, "loquesea"
  end

  test "ya no muestra el margen sumado" do
    get margenes_path
    assert_not_includes response.body, "Margen sumado"
  end

  test "destaca el mejor y el peor margen, por porcentaje" do
    get margenes_path
    assert_response :success

    # Cada porcentaje se busca DENTRO de su tarjeta: si se mirara toda
    # la pagina, la tabla de abajo tambien los contiene y la asercion
    # no distinguiria nada.
    tarjetas = response.body.split("En qué se va cada").first
    mejor    = tarjetas.split("Mejor margen").last.split("Peor margen").first
    peor     = tarjetas.split("Peor margen").last

    # Eficiente: food cost 20 % -> margen 80 %
    assert_includes mejor, "80,0 %"
    assert_includes mejor, "Plato Eficiente"
    assert_includes mejor, "$800,00"      # margen: 1000 - 200
    assert_includes mejor, "Precio de venta"
    assert_includes mejor, "$1.000,00"
    assert_includes mejor, "Costo de venta"
    assert_includes mejor, "$200,00"
    assert_includes mejor, "20,0 %"        # el costo sobre el precio
    assert_includes mejor, "Margen de venta"

    # Flojo: food cost 71,4 % -> margen 28,6 %
    assert_includes peor, "28,6 %"
    assert_includes peor, "Plato Flojo"
    assert_includes peor, "$200,00"       # margen: 700 - 500
    assert_includes peor, "$700,00"       # precio de venta
    assert_includes peor, "$500,00"       # costo de venta
    assert_includes peor, "71,4 %"        # el costo sobre el precio
    assert_includes peor, "100 %"
  end

  test "el mejor margen se elige por porcentaje, no por importe" do
    get margenes_path

    # "Plato Caro" deja mas plata ($3.000) que ningun otro, pero es
    # menos eficiente que "Plato Eficiente": 75 % contra 80 %.
    tarjetas = response.body.split("En qué se va cada").first
    assert_includes tarjetas, "Plato Eficiente"
    assert_not_includes tarjetas, "Plato Caro"
  end
end
