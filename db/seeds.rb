# Datos de ejemplo. Se puede ejecutar las veces que haga falta:
# borra todo y reconstruye desde cero.
# En produccion solo se siembra a proposito, no por accidente:
#   PERMITIR_SEED=1 bin/rails db:seed
if Rails.env.production? && ENV["PERMITIR_SEED"].blank?
  abort("ABORTADO: en produccion hay que pasar PERMITIR_SEED=1")
end

USUARIO_DEMO = "demo@lasplendida.cl"
CLAVE_DEMO   = "demo1234"

puts "Cargando usuario de demostracion..."
User.find_or_initialize_by(email_address: USUARIO_DEMO).update!(password: CLAVE_DEMO)

ENERO = Date.new(2026, 1, 15)
JUNIO = Date.new(2026, 6, 1)

puts "Limpiando..."
ActiveRecord::Base.transaction do
  Ingrediente.delete_all
  Receta.delete_all
  PrecioInsumo.delete_all
  Insumo.delete_all
  Proveedor.delete_all
end

# nombre => unidad base, merma %, [[fecha, precio, cantidad, unidad], ...]
INSUMOS = {
  "Tomate perita"    => [ "g",      15, [ [ ENERO,  1_200,  1, "kg" ], [ JUNIO,  1_650, 1, "kg" ] ] ],
  "Cebolla"          => [ "g",      20, [ [ ENERO,  2_000,  1, "kg" ], [ JUNIO,  2_400, 1, "kg" ] ] ],
  "Ajo"              => [ "g",      25, [ [ ENERO,  6_000,  1, "kg" ] ] ],
  "Zanahoria"        => [ "g",      20, [ [ ENERO,  1_500,  1, "kg" ] ] ],
  "Albahaca fresca"  => [ "g",      30, [ [ ENERO, 18_000,  1, "kg" ] ] ],
  "Papa"             => [ "g",      25, [ [ ENERO,    900,  1, "kg" ], [ JUNIO,  1_200, 1, "kg" ] ] ],
  "Nalga"            => [ "g",      10, [ [ ENERO, 12_000,  1, "kg" ], [ JUNIO, 18_000, 1, "kg" ] ] ],
  "Jamon cocido"     => [ "g",       5, [ [ ENERO, 14_000,  1, "kg" ] ] ],
  "Muzzarella"       => [ "g",       0, [ [ ENERO,  9_500,  1, "kg" ], [ JUNIO, 11_000, 1, "kg" ] ] ],
  "Queso parmesano"  => [ "g",       0, [ [ ENERO, 28_000,  1, "kg" ] ] ],
  "Manteca"          => [ "g",       0, [ [ ENERO,  9_000,  1, "kg" ] ] ],
  "Harina 000"       => [ "g",       0, [ [ ENERO, 30_000, 25, "kg" ], [ JUNIO, 37_500, 25, "kg" ] ] ],
  "Pan rallado"      => [ "g",       0, [ [ ENERO,  1_800,  1, "kg" ] ] ],
  "Sal fina"         => [ "g",       0, [ [ ENERO,    900,  1, "kg" ] ] ],
  "Pimienta negra"   => [ "g",       0, [ [ ENERO, 22_000,  1, "kg" ] ] ],
  "Azucar"           => [ "g",       0, [ [ ENERO,  1_300,  1, "kg" ] ] ],
  "Leche entera"     => [ "ml",      0, [ [ ENERO,  1_400,  1, "l" ] ] ],
  "Aceite de oliva"  => [ "ml",      0, [ [ ENERO, 18_000,  1, "l" ] ] ],
  "Aceite girasol"   => [ "ml",      0, [ [ ENERO,  9_000,  5, "l" ], [ JUNIO, 11_500,  5, "l" ] ] ],
  "Vino blanco"      => [ "ml",      0, [ [ ENERO,  3_500,  1, "l" ] ] ],
  "Huevo"            => [ "unidad",  0, [ [ ENERO,  4_800,  2, "docena" ], [ JUNIO, 5_600, 2, "docena" ] ] ],
  "Pan baguette"     => [ "unidad",  0, [ [ ENERO,  1_200,  1, "unidad" ] ] ],
  "Limon"            => [ "g",      40, [ [ ENERO,  2_500,  1, "kg" ] ] ]
}

# nombre => contacto, telefono, [insumos que provee]
PROVEEDORES = {
  "Nestlé" => [ "Ana Ruiz", "2 2345 6789",
    [ "Leche entera", "Manteca" ] ],
  "Distribuidora Central" => [ "Carlos Pérez", "2 2876 5432",
    [ "Harina 000", "Pan rallado", "Azucar", "Sal fina", "Aceite girasol", "Pimienta negra" ] ],
  "Verdulería El Mercado" => [ "Marta Silva", "9 8765 4321",
    [ "Tomate perita", "Cebolla", "Ajo", "Zanahoria", "Albahaca fresca", "Papa", "Limon" ] ],
  "Carnicería San Juan" => [ "Juan Soto", "2 2555 1122",
    [ "Nalga", "Jamon cocido" ] ],
  "Lácteos del Sur" => [ "Pedro Lagos", "9 5544 3322",
    [ "Muzzarella", "Queso parmesano", "Huevo" ] ]
}

puts "Cargando proveedores..."
PROVEEDORES.each do |nombre, (contacto, telefono, _)|
  Proveedor.create!(nombre: nombre, contacto: contacto, telefono: telefono)
end

# insumo => nombre de su proveedor
PROVEEDOR_DE = PROVEEDORES.flat_map { |proveedor, (_, _, insumos)|
  insumos.map { |insumo| [ insumo, proveedor ] }
}.to_h

puts "Cargando insumos y precios..."
INSUMOS.each do |nombre, (unidad_base, merma, precios)|
  insumo = Insumo.create!(nombre: nombre, unidad_base: unidad_base, merma_porcentaje: merma,
                          proveedor: Proveedor.find_by(nombre: PROVEEDOR_DE[nombre]))
  precios.each do |fecha, precio, cantidad, unidad|
    PrecioInsumo.create!(insumo: insumo, precio_compra: precio, cantidad_compra: cantidad,
                         unidad_compra: unidad, vigente_desde: fecha)
  end
end

def renglones(receta, lista)
  lista.each do |nombre, cantidad, unidad|
    insumable = Insumo.find_by(nombre: nombre) || Receta.find_by!(nombre: nombre)
    Ingrediente.create!(receta: receta, insumable: insumable,
                        cantidad: cantidad, unidad: unidad)
  end
end

# Las preparaciones se hacen por tanda: rinden una cantidad medible
# que despues se dosifica en los platos.
puts "Cargando preparaciones..."

salsa = Receta.create!(nombre: "Salsa de tomate", tipo: "preparacion",
                       rendimiento_cantidad: 2000, rendimiento_unidad: "g")
renglones(salsa, [
  [ "Tomate perita",   2,   "kg" ],
  [ "Cebolla",         300, "g" ],
  [ "Zanahoria",       150, "g" ],
  [ "Ajo",             20,  "g" ],
  [ "Aceite de oliva", 80,  "ml" ],
  [ "Albahaca fresca", 15,  "g" ],
  [ "Azucar",          10,  "g" ],
  [ "Sal fina",        15,  "g" ]
])

blanca = Receta.create!(nombre: "Salsa blanca", tipo: "preparacion",
                        rendimiento_cantidad: 1, rendimiento_unidad: "l")
renglones(blanca, [
  [ "Leche entera",   900, "ml" ],
  [ "Manteca",        70,  "g" ],
  [ "Harina 000",     70,  "g" ],
  [ "Sal fina",       5,   "g" ],
  [ "Pimienta negra", 2,   "g" ]
])

pure = Receta.create!(nombre: "Pure de papas", tipo: "preparacion",
                      rendimiento_cantidad: 1500, rendimiento_unidad: "g")
renglones(pure, [
  [ "Papa",         1.8, "kg" ],
  [ "Leche entera", 200, "ml" ],
  [ "Manteca",      80,  "g" ],
  [ "Sal fina",     10,  "g" ]
])

# Los platos se cargan POR PLATO: las cantidades son las que van
# efectivamente en el que se sirve.
puts "Cargando platos..."

napo = Receta.create!(nombre: "Milanesa napolitana", tipo: "plato",
                      categoria: "principal", precio_venta: 8_500)
renglones(napo, [
  [ "Nalga",           200, "g" ],
  [ "Pan rallado",     50,  "g" ],
  [ "Huevo",           1,   "unidad" ],
  [ "Harina 000",      20,  "g" ],
  [ "Salsa de tomate", 100, "g" ],
  [ "Muzzarella",      80,  "g" ],
  [ "Jamon cocido",    30,  "g" ],
  [ "Aceite girasol",  75,  "ml" ],
  [ "Sal fina",        3,   "g" ]
])

lasagna = Receta.create!(nombre: "Lasagna", tipo: "plato",
                         categoria: "principal", precio_venta: 9_800)
renglones(lasagna, [
  [ "Harina 000",      67,  "g" ],
  [ "Huevo",           0.7, "unidad" ],
  [ "Nalga",           85,  "g" ],
  [ "Salsa de tomate", 135, "g" ],
  [ "Salsa blanca",    100, "ml" ],
  [ "Muzzarella",      67,  "g" ],
  [ "Queso parmesano", 25,  "g" ],
  [ "Sal fina",        2,   "g" ]
])

noquis = Receta.create!(nombre: "Noquis con salsa", tipo: "plato",
                        categoria: "principal", precio_venta: 6_500)
renglones(noquis, [
  [ "Pure de papas",   225, "g" ],
  [ "Harina 000",      75,  "g" ],
  [ "Huevo",           0.5, "unidad" ],
  [ "Salsa de tomate", 125, "g" ],
  [ "Queso parmesano", 20,  "g" ]
])

tabla = Receta.create!(nombre: "Tabla para picar", tipo: "plato",
                       categoria: "compartir", precio_venta: 9_500)
renglones(tabla, [
  [ "Jamon cocido",    80,  "g" ],
  [ "Muzzarella",      100, "g" ],
  [ "Pan baguette",    0.5, "unidad" ],
  [ "Aceite de oliva", 20,  "ml" ]
])

flan = Receta.create!(nombre: "Flan casero", tipo: "plato",
                      categoria: "postre", precio_venta: 3_200)
renglones(flan, [
  [ "Leche entera", 200, "ml" ],
  [ "Huevo",        2,   "unidad" ],
  [ "Azucar",       60,  "g" ]
])

limonada = Receta.create!(nombre: "Limonada", tipo: "plato",
                          categoria: "bebestible", precio_venta: 2_800)
renglones(limonada, [
  [ "Limon",  150, "g" ],
  [ "Azucar", 40,  "g" ]
])

puts "\nListo: #{Insumo.count} insumos, #{PrecioInsumo.count} precios, " \
     "#{Receta.preparaciones.count} preparaciones, #{Receta.platos.count} platos, " \
     "#{Ingrediente.count} renglones.\n\n"

def money(x) = ActiveSupport::NumberHelper.number_to_currency(x)

[ [ "ENERO", ENERO ], [ "HOY", Date.current ] ].each do |etiqueta, fecha|
  puts "== COSTEO AL #{etiqueta} (#{I18n.l(fecha)}) =="
  printf("  %-22s %12s %12s %8s %14s\n", "PLATO", "COSTO", "PVP", "F.COST", "PVP SUGERIDO")
  Receta.platos.order(:nombre).each do |plato|
    printf("  %-22s %12s %12s %7.1f%% %14s\n",
           plato.nombre,
           money(plato.costo_total(fecha: fecha)),
           money(plato.precio_venta),
           plato.food_cost(fecha: fecha),
           money(plato.precio_sugerido(fecha: fecha)))
  end
  puts
end
