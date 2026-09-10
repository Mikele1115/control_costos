class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: t("autenticacion.correo_asunto"), to: user.email_address
  end
end
