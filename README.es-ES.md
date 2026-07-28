# jamfGitSync

¡Utiliza git como la fuente de verdad para tus scripts! Utiliza pipelines de CI/CD que cargan los scripts modificados más recientemente a un servidor de Jamf Pro.

Esta es una reescritura de [git4jamfpro](https://github.com/alectrona/git4jamfpro) (que a su vez es una reescritura de [git2jss](https://github.com/badstreff/git2jss)). Ambos son scripts muy buenos; sin embargo, descubrí rápidamente que ambos siguen utilizando el [endpoint de la API clásica](https://developer.jamf.com/jamf-pro/docs/getting-started-2) y no el nuevo [Jamf Pro API Endpoint](https://developer.jamf.com/jamf-pro/docs/jamf-pro-api-overview). (También prefería archivos json en lugar de xml).

## Beneficios de las alternativas mencionadas anteriormente

- Sin dependencias de python
- Sin dependencias de xmlstarlet
- Utiliza Client ID & Client Secrets a través de roles y clientes de API en lugar de Bearer Auth
- Permite cargar scripts muy grandes ([INSTALLOMATOR](https://github.com/Installomator/Installomator), por ejemplo)
- Permite descargar todos los scripts en paralelo desde un servidor de Jamf Pro

## Uso

### Requisitos

- Una instancia de Jamf Pro (por supuesto)
- Un servidor de VCS git (github, bitbucket, ...)
- Un Client ID & Client Secret generado para tu instancia de Jamf Pro
    - Permisos requeridos:
      ![required_permissions](/.github/assets/permissions.png)

      <details>
        <summary>en Texto..</summary>
        
        - Create Scripts
        - Read Scripts
        - Update Scripts
        - Create Computer Extension Attributes
        - Create Mobile Device Extension Attributes
        - Create User Extension Attributes
        - Read Computer Extension Attributes
        - Read Mobile Device Extension Attributes
        - Read User Extension Attributes
        - Update Computer Extension Attributes
        - Update Mobile Device Extension Attributes
        - Update User Extension Attributes

      </details>

- Una herramienta de CI/CD para automatización (Jenkins, CircleCI, Bitbucket Pipelines, GitHub Workflows, ...)
- Un Runner con al menos:
  - Bash 4.0 o superior (macOS incluye la versión 3.2, ten cuidado si usas runners de macOS)
  - `git` instalado
  - [`jq`](https://github.com/jqlang/jq) instalado

### Pasos

1. Haz un Fork / Descarga este repositorio

2. Descarga todos tus scripts y atributos de extensión actuales:

```sh
./jamfScriptSync.sh --url <YOUR_JAMF_PRO_SERVER> \
    --clientid <API_Client_ID> \
    --clientsecret <API_Client_Secret> \
    --download-scripts \
    --download-eas
```

3. Haz commit del repositorio poblado con los scripts en tu git:

```sh
git add .
git commit -a -m "feat(init): initial setup"
```

4. Haz push de este commit a tu propio repositorio. (donde quieras tener almacenados esos scripts)


### Próximos Pasos

Una vez terminada la configuración inicial, tus Pipelines _podrían_ verse algo así (por supuesto, esto depende de tu propia configuración y estos son solo ejemplos):

- [Jenkins](https://github.com/74k1/jamfGitSync/wiki/Jenkins-example)
- [BitBucket](https://github.com/74k1/jamfGitSync/wiki/BitBucket-example)
- [GitHub Workflows](https://github.com/74k1/jamfGitSync/wiki/GitHub-Workflows-example)
- [CircleCI](https://github.com/74k1/jamfGitSync/wiki/CircleCI-example)

Ahora puedes realizar cambios en tus scripts en tu propio repositorio, hacer push de esos cambios a git y dejar que tu CI/CD se encargue del resto del trabajo. :smile:

## Contribución

¡Todas las contribuciones son muy apreciadas! Me harías el día si pudieras leer primero las Directrices de Contribución.

- [Contribution Guidelines](https://github.com/74k1/jamfGitSync/blob/main/docs/CONTRIBUTING.md)

Quedo atento a tus sugerencias / mejoras. :)
