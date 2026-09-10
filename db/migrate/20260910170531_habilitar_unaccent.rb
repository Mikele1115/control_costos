class HabilitarUnaccent < ActiveRecord::Migration[8.1]
  # unaccent permite que "limon" encuentre "Limón" y "lacteos"
  # encuentre "Lácteos del Sur". Desde PostgreSQL 13 es una extension
  # "trusted", asi que la puede crear el dueno de la base sin ser
  # superusuario.
  def change
    enable_extension "unaccent"
  end
end
