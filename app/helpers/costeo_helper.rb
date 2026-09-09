module CosteoHelper
  # --- Navegacion ---------------------------------------------------

  def enlace_nav(texto, ruta)
    activo = current_page?(ruta) ||
             (ruta != root_path && request.path.start_with?(ruta))

    clases = activo ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100"
    link_to texto, ruta, class: "rounded-md px-3 py-1.5 #{clases}"
  end

  # --- Formato ------------------------------------------------------

  def moneda(valor)
    return content_tag(:span, "—", class: "text-slate-400") if valor.nil?
    number_to_currency(valor)
  end

  def cantidad(valor, decimales = 2)
    return "—" if valor.nil?
    number_with_precision(valor, precision: decimales, strip_insignificant_zeros: true)
  end

  # --- Semaforo del food cost ---------------------------------------
  #
  # Referencia gastronomica: por debajo de 25% el plato esta barato,
  # entre 25 y 35 es la banda sana, por encima de 45 no es rentable.

  def clase_food_cost(valor)
    case valor
    when nil     then "bg-slate-100 text-slate-500"
    when ...25   then "bg-sky-100 text-sky-800"
    when 25...35 then "bg-emerald-100 text-emerald-800"
    when 35...45 then "bg-amber-100 text-amber-900"
    else              "bg-rose-100 text-rose-800"
    end
  end

  def etiqueta_food_cost(valor)
    case valor
    when nil     then "sin datos"
    when ...25   then "bajo"
    when 25...35 then "sano"
    when 35...45 then "alto"
    else              "crítico"
    end
  end

  def insignia_food_cost(valor)
    texto = valor.nil? ? "—" : "#{number_with_precision(valor, precision: 1)} %"
    content_tag :span, texto,
      class: "inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold #{clase_food_cost(valor)}"
  end
end
