# --- Ingles: para los nombres de tabla y de clase -------------------
#
# Sus reglas para plurales latinos (/([ti])a$/) existen para que "data",
# "media" o "bacteria" queden invariables, pero de paso dejan sin
# pluralizar medio castellano: receta, cuenta, venta, carta, dieta...
# Como el dominio esta en castellano, las sustituimos.
#
# Este juego es el que usa Rails para deducir "Receta" -> tabla
# "recetas", asi que tocarlo cambia el esquema. No quitar.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.plural(/([ti])a$/i, '\1as')
  inflect.singular(/([ti])a$/i, '\1a')

  # Las palabras terminadas en consonante siguen tomando "s" a la
  # inglesa: Proveedor daria la tabla "proveedors". Se declara aparte.
  inflect.irregular "proveedor", "proveedores"
end

# --- Castellano: para los textos de las vistas ----------------------
#
# El helper `pluralize` de las vistas llama a String#pluralize(locale)
# con el locale activo. Sin reglas para :es devolvia la palabra sin
# tocar ("3 plato"), asi que hay que definirlas aparte.
#
# Las reglas se prueban de la ultima a la primera, por eso van de la
# mas general a la mas especifica. Cubren el caso comun; no pretenden
# ser una gramatica completa del castellano.
ActiveSupport::Inflector.inflections(:es) do |inflect|
  inflect.plural(/$/, "s")                      # plato  -> platos
  inflect.plural(/([^aeiouáéíóú])$/i, '\1es')   # error  -> errores
  inflect.plural(/z$/i, "ces")                  # luz    -> luces
  inflect.plural(/(s|x)$/i, '\1')               # crisis -> crisis
end
