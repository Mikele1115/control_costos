class CrearConfiguraciones < ActiveRecord::Migration[8.1]
  def change
    create_table :configuraciones do |t|
      t.string  :correo_avisos
      t.boolean :avisos_activos, null: false, default: false

      # El food cost a partir del cual un plato merece un correo.
      # decimal y no float: es un porcentaje que se compara, y los
      # float arrastran errores que aqui se verian como avisos raros.
      t.decimal :umbral_aviso, precision: 5, scale: 2, null: false, default: 35

      # No hay "configuraciones" en plural: hay una. Esta columna
      # siempre vale true, y su indice unico impide una segunda fila.
      t.boolean :unica, null: false, default: true

      t.timestamps
    end

    add_index :configuraciones, :unica, unique: true
    add_check_constraint :configuraciones, "unica", name: "solo_una_fila"

    # 100 % es vender justo al costo: mas arriba no tiene sentido pedir.
    add_check_constraint :configuraciones,
      "umbral_aviso > 0 AND umbral_aviso <= 100",
      name: "umbral_entre_1_y_100"

    # Sin correo no hay a quien avisarle.
    add_check_constraint :configuraciones,
      "NOT avisos_activos OR correo_avisos IS NOT NULL",
      name: "avisos_necesitan_correo"
  end
end
