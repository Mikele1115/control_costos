class Proveedor < ApplicationRecord
  # Al borrar un proveedor, sus insumos quedan sin proveedor.
  # No se pierden: solo dejan de estar asignados.
  has_many :insumos, dependent: :nullify

  validates :nombre, presence: true,
                     uniqueness: { case_sensitive: false }

  scope :ordenados, -> { order(:nombre) }

  def cantidad_insumos = insumos.size
end
