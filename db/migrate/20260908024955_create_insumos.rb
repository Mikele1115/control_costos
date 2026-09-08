class CreateInsumos < ActiveRecord::Migration[8.1]
  def change
    create_table :insumos do |t|
      t.string  :nombre,      null: false
      t.string  :unidad_base, null: false
      t.decimal :merma_porcentaje, precision: 5, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :insumos, :nombre, unique: true

    add_check_constraint :insumos,
      "merma_porcentaje >= 0 AND merma_porcentaje < 100",
      name: "merma_en_rango"

    add_check_constraint :insumos,
      "unidad_base IN ('g', 'ml', 'unidad')",
      name: "unidad_base_valida"
  end
end
