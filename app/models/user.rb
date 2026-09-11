class User < ApplicationRecord
  ROLES = %w[administrador digitador observador].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address,
            presence: { message: "no puede quedar vacío" },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "no parece un correo" },
            uniqueness: { message: "ya tiene cuenta" }

  validates :rol, inclusion: { in: ROLES, message: "no es un rol válido" }

  scope :ordenados, -> { order(:email_address) }

  def administrador? = rol == "administrador"
  def observador?    = rol == "observador"

  # El digitador y el administrador cargan datos; el observador mira.
  def puede_escribir? = !observador?

  # Ajustes reparte permisos y decide a quien se le avisa: solo el jefe.
  def puede_configurar? = administrador?
end
