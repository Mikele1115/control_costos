# Quien esta autenticado lo resuelve Authentication. Esto decide que
# puede hacer una vez dentro.
#
# La regla general es una sola: toda peticion que no sea GET modifica
# algo, y para modificar hay que poder escribir. Se apoya en que la app
# es RESTful, y por eso cualquier accion que se agregue manana nace
# protegida sin que haya que acordarse de nada.
#
# Ajustes va aparte: ahi ni siquiera se puede mirar sin ser
# administrador, porque muestra quien tiene permisos y a quien se avisa.
module Autorizacion
  extend ActiveSupport::Concern

  # `new` y `edit` son GET, pero no son pantallas de consulta: existen
  # solo para escribir a continuacion. Dejar entrar ahi a quien no
  # puede guardar es ofrecerle un formulario que va a rebotar.
  ACCIONES_DE_ESCRITURA = %w[new edit].freeze

  included do
    before_action :exigir_permiso_de_escritura
    helper_method :puede_escribir?, :puede_configurar?
  end

  class_methods do
    def solo_administradores(**opciones)
      before_action :exigir_administrador, **opciones
    end

    # Para lo que ocurre antes de tener un rol: iniciar sesion, cerrarla
    # y recuperar la contrasena.
    def permitir_sin_autorizacion(**opciones)
      skip_before_action :exigir_permiso_de_escritura, **opciones
    end
  end

  private
    def puede_escribir?   = Current.user&.puede_escribir? || false
    def puede_configurar? = Current.user&.puede_configurar? || false

    def exigir_permiso_de_escritura
      return if puede_escribir?
      return if solo_consulta?

      denegar("Tu cuenta es de solo lectura: no puedes modificar datos.")
    end

    def solo_consulta?
      (request.get? || request.head?) && ACCIONES_DE_ESCRITURA.exclude?(action_name)
    end

    def exigir_administrador
      return if puede_configurar?

      denegar("Solo un administrador puede entrar a Ajustes.")
    end

    def denegar(motivo)
      # 303 tras un POST/PATCH/DELETE: es lo que Turbo espera para
      # seguir la redireccion en vez de reenviar el formulario.
      redirect_back fallback_location: root_path, alert: motivo,
                    status: (request.get? || request.head?) ? :found : :see_other
    end
end
