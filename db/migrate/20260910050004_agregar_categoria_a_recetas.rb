class AgregarCategoriaARecetas < ActiveRecord::Migration[8.1]
  def change
    add_column :recetas, :categoria, :string

    # Dos reglas en una: la categoria debe ser de la lista, y solo la
    # pueden tener los platos. Una preparacion no va en la carta.
    add_check_constraint :recetas, <<~SQL.squish, name: "categoria_valida"
      categoria IS NULL
      OR (tipo = 'plato'
          AND categoria IN ('principal', 'compartir', 'postre', 'bebestible'))
    SQL

    add_index :recetas, [:categoria, :nombre]
  end
end
