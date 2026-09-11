# Se escribe con `up` y `down` a mano en vez de `change` porque el
# orden importa en los dos sentidos: al volver atras hay que rellenar
# `correo_avisos` ANTES de reponer la restriccion que lo exige, y
# `change` invierte los pasos en un orden que no lo permite.
class CrearDestinatarios < ActiveRecord::Migration[8.1]
  def up
    create_table :destinatarios do |t|
      t.string  :correo, null: false
      t.boolean :activo, null: false, default: true

      t.timestamps
    end

    # Un mismo correo no puede estar dos veces en la lista.
    add_index :destinatarios, :correo, unique: true

    # El correo que ya estaba configurado pasa a ser el primero de la
    # lista: nadie deberia quedarse sin aviso por culpa de este cambio.
    execute <<~SQL
      INSERT INTO destinatarios (correo, activo, created_at, updated_at)
      SELECT correo_avisos, true, now(), now()
      FROM configuraciones
      WHERE correo_avisos IS NOT NULL
    SQL

    remove_check_constraint :configuraciones,
      "NOT avisos_activos OR correo_avisos IS NOT NULL",
      name: "avisos_necesitan_correo"

    remove_column :configuraciones, :correo_avisos
  end

  def down
    add_column :configuraciones, :correo_avisos, :string

    execute <<~SQL
      UPDATE configuraciones
      SET correo_avisos = (SELECT correo FROM destinatarios WHERE activo ORDER BY id LIMIT 1)
    SQL

    add_check_constraint :configuraciones,
      "NOT avisos_activos OR correo_avisos IS NOT NULL",
      name: "avisos_necesitan_correo"

    drop_table :destinatarios
  end
end
