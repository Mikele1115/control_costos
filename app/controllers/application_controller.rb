class ApplicationController < ActionController::Base
  include Authentication
  include Autorizacion
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Todo el sistema puede costearse "a una fecha". Ese parametro llega
  # por la URL, asi que puede traer cualquier cosa: si no se entiende,
  # se usa hoy en vez de reventar con un 500.
  def fecha_solicitada
    return Date.current if params[:fecha].blank?
    Date.parse(params[:fecha])
  rescue Date::Error
    Date.current
  end
end
