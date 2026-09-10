# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_10_033000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ingredientes", force: :cascade do |t|
    t.decimal "cantidad", precision: 12, scale: 4, null: false
    t.datetime "created_at", null: false
    t.bigint "insumable_id", null: false
    t.string "insumable_type", null: false
    t.bigint "receta_id", null: false
    t.string "unidad", null: false
    t.datetime "updated_at", null: false
    t.index ["insumable_type", "insumable_id"], name: "index_ingredientes_on_insumable"
    t.index ["receta_id", "insumable_type", "insumable_id"], name: "index_ingredientes_unicos", unique: true
    t.index ["receta_id"], name: "index_ingredientes_on_receta_id"
    t.check_constraint "cantidad > 0::numeric", name: "cantidad_positiva"
    t.check_constraint "insumable_type::text = ANY (ARRAY['Insumo'::character varying, 'Receta'::character varying]::text[])", name: "insumable_type_valido"
  end

  create_table "insumos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "merma_porcentaje", precision: 5, scale: 2, default: "0.0", null: false
    t.string "nombre", null: false
    t.string "unidad_base", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_insumos_on_nombre", unique: true
    t.check_constraint "merma_porcentaje >= 0::numeric AND merma_porcentaje < 100::numeric", name: "merma_en_rango"
    t.check_constraint "unidad_base::text = ANY (ARRAY['g'::character varying, 'ml'::character varying, 'unidad'::character varying]::text[])", name: "unidad_base_valida"
  end

  create_table "precio_insumos", force: :cascade do |t|
    t.decimal "cantidad_compra", precision: 12, scale: 4, null: false
    t.decimal "costo_por_unidad_base", precision: 14, scale: 6, null: false
    t.datetime "created_at", null: false
    t.bigint "insumo_id", null: false
    t.decimal "precio_compra", precision: 12, scale: 2, null: false
    t.string "unidad_compra", null: false
    t.datetime "updated_at", null: false
    t.date "vigente_desde", null: false
    t.index ["insumo_id", "vigente_desde"], name: "index_precio_insumos_on_insumo_id_and_vigente_desde", unique: true
    t.index ["insumo_id"], name: "index_precio_insumos_on_insumo_id"
    t.check_constraint "cantidad_compra > 0::numeric", name: "cantidad_positiva"
    t.check_constraint "costo_por_unidad_base >= 0::numeric", name: "costo_no_negativo"
    t.check_constraint "precio_compra >= 0::numeric", name: "precio_no_negativo"
  end

  create_table "recetas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nombre", null: false
    t.decimal "precio_venta", precision: 12, scale: 2
    t.decimal "rendimiento_cantidad", precision: 12, scale: 4
    t.string "rendimiento_unidad"
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_recetas_on_nombre", unique: true
    t.check_constraint "precio_venta IS NULL OR precio_venta >= 0::numeric", name: "precio_venta_no_negativo"
    t.check_constraint "rendimiento_cantidad IS NULL OR rendimiento_cantidad > 0::numeric", name: "rendimiento_positivo"
    t.check_constraint "tipo::text = 'plato'::text OR tipo::text = 'preparacion'::text AND rendimiento_cantidad IS NOT NULL AND rendimiento_unidad IS NOT NULL", name: "rendimiento_segun_tipo"
    t.check_constraint "tipo::text = ANY (ARRAY['plato'::character varying, 'preparacion'::character varying]::text[])", name: "tipo_valido"
  end

  add_foreign_key "ingredientes", "recetas"
  add_foreign_key "precio_insumos", "insumos"
end
