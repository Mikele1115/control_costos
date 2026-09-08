# El inflector de Rails es ingles y tiene dos juegos de reglas
# independientes. Ambos tratan las terminaciones -ta / -ia como
# plurales latinos:
#
#   inflect.plural(/([ti])a$/i, '\1a')     data   -> data
#   inflect.singular(/([ti])a$/i, '\1um')  data   -> datum
#
# En castellano eso rompe receta, cuenta, venta, carta, dieta,
# categoria... y ademas impide que el generador resuelva el
# round-trip "Receta" -> "receta" -> "Receta".
#
# Como el dominio de esta aplicacion esta en castellano, sustituimos
# ambas reglas: plural normal en -s y singular invariable.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.plural(/([ti])a$/i, '\1as')
  inflect.singular(/([ti])a$/i, '\1a')
end
