# Desplegar con Kamal

## 1. Lo que hay que tener

| | |
|---|---|
| **VPS** | Ubuntu LTS, **2 GB de RAM como mínimo** (conviven Rails y PostgreSQL). Acceso SSH como `root` con tu clave pública ya instalada. |
| **Registro de imágenes** | Docker Hub o GitHub Container Registry (`ghcr.io`). Necesitás un *token de acceso*, no tu contraseña. |
| **Dominio** *(opcional)* | Un registro `A` apuntando a la IP del VPS. Sin él no hay HTTPS. |

Kamal instala Docker en el servidor por su cuenta. No hace falta preparar nada más.

## 2. Rellenar la configuración

En `config/deploy.yml`, sustituí los tres marcadores:

- `USUARIO_REGISTRO` — tu usuario del registro (aparece dos veces)
- `IP_DEL_VPS` — la IP del servidor (aparece dos veces)
- `MI-DOMINIO.COM` — tu dominio, o `ssl: false` si todavía no tenés

## 3. Exportar los secretos

    export KAMAL_REGISTRY_PASSWORD='tu-token-del-registro'
    export DB_PASSWORD="$(openssl rand -base64 32)"

Guardá esa contraseña en un gestor: **la vas a necesitar si algún día
recreás el servidor**, y PostgreSQL solo la fija la primera vez.

## 4. Desplegar

    bin/kamal setup

La primera vez tarda: instala Docker en el servidor, construye la
imagen, la sube al registro, levanta PostgreSQL y arranca la
aplicación. Las siguientes son `bin/kamal deploy` y tardan minutos.

## 5. Sembrar los datos de demostración

    bin/kamal sembrar

Deja el recetario de ejemplo y el usuario `demo@lasplendida.cl`
con la contraseña `demo1234`.

## 6. Comprobar

    curl -I https://MI-DOMINIO.COM/up   # debe responder 200
    bin/kamal logs -f                   # los registros en vivo
    bin/kamal console                   # una consola de Rails

## Después

| Necesidad | Comando |
|---|---|
| Publicar cambios | `bin/kamal deploy` |
| Ver registros | `bin/kamal logs -f` |
| Consola de Rails | `bin/kamal console` |
| Consola de PostgreSQL | `bin/kamal dbc` |
| Volver a la versión anterior | `bin/kamal rollback` |

## Lo que NO está configurado

- **Correo saliente.** La recuperación de contraseña no enviará nada
  hasta que configures un SMTP en `config/environments/production.rb`.
  Para la demostración no hace falta.
- **Copias de seguridad.** Los datos viven en el volumen `data` del
  servidor. Si el VPS desaparece, desaparecen con él.
