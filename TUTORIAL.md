# Tutorial de demostración — EntoData, Fase 1

Guía para encender el proyecto, demostrar todo lo que pide la Fase 1 y volver a apagarlo.

## 1. Cómo funciona

### En la nube (Google Cloud, proyecto del `.env`)

| Pieza | Qué es | Para qué sirve | ¿Cobra? |
|---|---|---|---|
| `entodata-vpc` | La red privada de la empresa, en modo *custom* | Contiene todo; los rangos los definimos nosotros | No |
| 4 subredes | Los "pisos" de la red | Visitas `10.10.0.0/26`, Ventas `10.10.0.64/27`, TI `10.10.0.96/27`, Data Center `10.10.0.128/28` | No |
| 5 reglas de firewall | El "guardia" | Decide quién puede hablar con quién; bloquea a Visitas | No |
| 3 VMs e2-micro | Computadoras de prueba | `vm-ventas-1` (.66) y `vm-ventas-2` (.67) para el ping; `vm-visitas-1` (.2) para demostrar el aislamiento | Solo encendidas |
| IAP | Túnel seguro de Google | Entrar por SSH a VMs que no tienen IP pública | No |

La red, las subredes y el firewall **siempre existen**. Las VMs se **encienden solo para la demo** y se apagan al terminar.

### En el repositorio

| Archivo | Qué hace | ¿Correrlo en la demo? |
|---|---|---|
| `.env` | Project ID, región y zona (no se sube a Git) | — |
| `infra/gcp/00-variables.sh` | Lee `.env` y define nombres, rangos e IPs; lo usan todos los scripts | No (se carga solo) |
| `infra/gcp/01-habilitar-apis.sh` | Activa Compute Engine e IAP | No, ya se hizo |
| `infra/gcp/02-red.sh` | Crea la VPC y las 4 subredes | No, ya se hizo |
| `infra/gcp/03-firewall.sh` | Crea las 5 reglas de firewall | No, ya se hizo |
| `infra/gcp/04-instancias.sh` | Crea las 3 VMs | No, ya se hizo |
| `infra/gcp/05-pruebas.sh` | Entra a cada VM, muestra su IP y gateway, hace los pings y guarda todo en `evidencias/` | **Sí** |
| `infra/gcp/06-exportar-config.sh` | Muestra un resumen de todo lo desplegado y lo guarda en `config/` | **Sí** |
| `infra/gcp/97-encender.sh` | Enciende las 3 VMs | **Sí, antes** |
| `infra/gcp/98-apagar.sh` | Apaga las 3 VMs | **Sí, después** |
| `infra/gcp/99-eliminar.sh` | Borra todo (pide escribir `eliminar`) | No |
| `config/` | Configuración real exportada de GCP | Mostrar si lo piden |
| `evidencias/` | Resultados guardados de las pruebas | Plan B |

Los scripts 01 a 04 son idempotentes: si se vuelven a correr, no duplican nada.

## 2. Antes de presentar (10 minutos antes)

```bash
cd ~/Documents/UVG/Redes/redes-proyecto-final
gcloud auth list                 # debe aparecer tu cuenta con asterisco; si no: gcloud auth login
./infra/gcp/97-encender.sh       # las 3 VMs deben quedar en RUNNING
```

1. Espere **1 minuto** a que arranquen las VMs.
2. Ensayo rápido (30 segundos): `./infra/gcp/05-pruebas.sh`. Si termina con "RESULTADO: sin respuesta (bloqueado por firewall)", todo está listo.
3. Abra [console.cloud.google.com](https://console.cloud.google.com) con el proyecto correcto y deje tres pestañas listas:
   - **VPC network → VPC networks → entodata-vpc** (pestaña *Subnets*)
   - **VPC network → Firewall** (filtro: `entodata`)
   - **Compute Engine → VM instances**

## 3. La demostración (4 a 5 minutos)

### Paso 1: La red y las subredes (pestaña VPC)
- **Señalar:** modo *Custom*; las 4 subredes con sus rangos; la columna *Gateway* (.1, .65, .97, .129).
- **Decir:** "Estos son exactamente los rangos que calculé. Google tomó como puerta de enlace la segunda dirección de cada subred, tal como en el cálculo."

### Paso 2: El firewall (pestaña Firewall)
- **Señalar:** `entodata-deny-visitas-internas` con prioridad 900 (el número menor se evalúa primero) y las cuatro reglas `allow`.
- **Decir:** "Por defecto Google bloquea todo lo que entra. Solo abrí lo necesario y bloqueé explícitamente a Visitas."

### Paso 3: Las instancias (pestaña VM instances)
- **Señalar:** 3 VMs; *Internal IP* .66, .67 y .2; *External IP* vacía.
- **Decir:** "Ninguna tiene dirección pública. Entro a ellas por un túnel seguro de Google."

### Paso 4: Ping que funciona (botón **SSH** de `vm-ventas-1`)
La primera vez, el navegador pide *Authorize*: acéptelo. En la ventana que se abre:

```bash
ip -4 addr show ens4     # muestra 10.10.0.66
ip route                 # muestra "default via 10.10.0.65" (el gateway de Ventas)
ping -c 4 10.10.0.67     # 4 received, 0% packet loss
```
- **Decir:** "Las dos computadoras de Ventas se comunican: cuatro mensajes enviados, cuatro recibidos."

### Paso 5: Ping bloqueado (botón **SSH** de `vm-visitas-1`)
```bash
ping -c 4 -W 2 10.10.0.66    # 0 received, 100% packet loss
```
- **Decir:** "Desde Visitas no hay respuesta. No es un error: es la segmentación funcionando."

### Paso 6 (opcional): La automatización (terminal)
```bash
./infra/gcp/06-exportar-config.sh   # resumen de VPC, subredes, firewall, rutas y VMs
./infra/gcp/05-pruebas.sh           # todas las pruebas en ~30 s, guardadas en evidencias/
```
- **Decir:** "Todo lo que mostré está en scripts. Cualquier persona puede reconstruir la red desde cero."

## 4. Al terminar

```bash
./infra/gcp/98-apagar.sh    # las 3 VMs deben quedar en TERMINATED
```

## 5. Si algo falla

| Problema | Solución |
|---|---|
| No hay internet o la consola no carga | Mostrar los screenshots del reporte, `evidencias/03` a `06` y `config/resumen.txt` |
| SSH no conecta | Esperar otro minuto (la VM sigue arrancando) y reintentar |
| gcloud dice que las credenciales expiraron | `gcloud auth login` |
| Un script dice "Falta PROJECT_ID" | `cp .env.example .env` y escribir el Project ID |
| El ping desde Visitas no responde | Es lo esperado |

## 6. Dónde se cumple cada requisito

| Requisito de la Fase 1 | Dónde se demuestra |
|---|---|
| Selección y justificación del proveedor | Reporte |
| Diagrama de red y cálculos de subneteo | Reporte (a mano) y Paso 1 |
| Implementación de la red segmentada | Pasos 1 a 3 y `infra/gcp/` |
| Ping entre dos instancias de una subred | Paso 4 y `evidencias/03`, `evidencias/04` |
| Archivos de configuración | `config/`, `infra/gcp/` y `README.md` |
