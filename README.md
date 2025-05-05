# Proyecto IaC: Arquitectura de Tres Capas en AWS

Este proyecto implementa una arquitectura de tres capas en AWS utilizando Terraform. La arquitectura despliega una aplicación web PHP de e-commerce con una base de datos MySQL, distribuida a través de múltiples zonas de disponibilidad para garantizar alta disponibilidad.

## Arquitectura

La infraestructura desplegada sigue el patrón de tres capas:

1. **Capa de Presentación**: 
   - Network Load Balancer (NLB) para distribuir el tráfico
   - Dos servidores web en diferentes zonas de disponibilidad (us-east-1a y us-east-1b)

2. **Capa de Aplicación**: 
   - Aplicación PHP de e-commerce
   - Servidor Apache con PHP 5.6
   - Conector MySQL para PHP

3. **Capa de Datos**: 
   - Base de datos MySQL RDS 5.7
   - Desplegada en subredes privadas para mayor seguridad

## Diagrama

El diagrama de infraestructura implementada muestra:
- VPC: vpc-practico-3tier
- Zonas de disponibilidad: us-east-1a y us-east-1b
- Subredes: 10.0.1.0/24 y 10.0.2.0/24 (públicas), 10.0.3.0/24 y 10.0.4.0/24 (privadas)
- Servidores web: webapp-server01 y webapp-server02
- Grupos de seguridad para SSH y HTTP
- RDS MySQL en subredes privadas
- Network Load Balancer (NLB) distribuyendo tráfico entre las instancias

## Requisitos previos

- AWS CLI configurado con credenciales apropiadas
- Terraform v1.0.0 o superior
- Par de claves SSH disponible en AWS (para acceder a las instancias EC2)
- Bucket S3 para almacenar el estado remoto
- Tabla DynamoDB para bloqueo de estado

## Estructura del proyecto

```
.
├── main.tf              # Configuración principal de Terraform
├── variables.tf         # Definición de variables
├── terraform.tfvars     # Valores de las variables (no incluido en el repositorio)
├── outputs.tf           # Salidas después del despliegue
├── backend.tf           # Configuración del estado remoto
├── user_data.sh         # Script de inicialización para las instancias EC2
└── README.md            # Este archivo
```

## Pasos para el despliegue

### 1. Clonar el repositorio

```bash
git clone <https://github.com/lr251516/iac2025.git>
cd <IAC2025>
```

### 2. Configurar las variables

Crea un archivo `terraform.tfvars` con los valores adecuados para tu entorno:

```hcl
# Configuración de red
vpc_cidr              = "10.0.0.0/16"
public_subnet_1_cidr  = "10.0.1.0/24"
public_subnet_2_cidr  = "10.0.2.0/24"
private_subnet_1_cidr = "10.0.3.0/24"
private_subnet_2_cidr = "10.0.4.0/24"

# Configuración de la base de datos
db_instance_class     = "db.t3.micro"
db_name               = "ecommerce"
db_username           = "dbadmin"
db_password           = "SecurePassword"

# Configuración de las instancias EC2
instance_type         = "t2.micro"
key_name              = "tu-clave-ssh"

# Región y zonas de disponibilidad
region                = "us-east-1"
az_a                  = "us-east-1a"
az_b                  = "us-east-1b"

# Repositorio de la aplicación
app_repo              = "https://github.com/mauricioamendola/simple-ecomme.git"
```

### 3. Preparar el estado remoto

Primero, crea un bucket S3 y una tabla DynamoDB para el estado remoto:

```bash
# Crear el bucket S3
aws s3api create-bucket --bucket terraform-state-practico-iac --region us-east-1

# Habilitar el versionado en el bucket
aws s3api put-bucket-versioning --bucket terraform-state-practico-iac --versioning-configuration Status=Enabled

# Crear la tabla DynamoDB para el bloqueo
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 4. Inicializar Terraform

```bash
terraform init
```

### 5. Validar la configuración

```bash
terraform validate
```

### 6. Ver el plan de ejecución

```bash
terraform plan
```

### 7. Aplicar la configuración

```bash
terraform apply
```

Confirma escribiendo `yes` cuando se te solicite.

### 8. Acceder a la aplicación

Una vez completado el despliegue, utiliza la salida `nlb_dns_name` para acceder a la aplicación web desde tu navegador:

```
http://[nlb_dns_name]
```

## Componentes implementados

### Infraestructura de red
- VPC dedicada con CIDR 10.0.0.0/16
- Subredes públicas en dos zonas de disponibilidad para los servidores web
- Subredes privadas para la base de datos
- Internet Gateway y tablas de rutas configuradas

### Servidores web
- Instancias EC2 con Amazon Linux 2
- Apache, PHP 5.6 y componentes necesarios
- Aplicación e-commerce desplegada automáticamente mediante script de inicialización
- Grupos de seguridad para SSH y HTTP

### Base de datos
- Instancia RDS MySQL 5.7
- Desplegada en subredes privadas para mayor seguridad
- Grupo de seguridad restrictivo que solo permite tráfico desde los servidores web

### Balance de carga
- Network Load Balancer (NLB) distribuyendo tráfico entre instancias
- Health checks a nivel TCP garantizando alta disponibilidad
- Desplegado en subredes públicas

## Decisiones de diseño

### Elección de Network Load Balancer sobre Application Load Balancer

Para este proyecto se decidió implementar un Network Load Balancer (NLB) en lugar de un Application Load Balancer (ALB) debido a:

1. **Mayor rendimiento**: Los NLB operan en la capa 4 (TCP) del modelo OSI, lo que les permite manejar millones de solicitudes por segundo con latencia ultra baja.

2. **Health checks más robustos**: Los health checks basados en TCP son más simples y consistentes, verificando solo si el puerto está abierto y respondiendo, lo que resulta en una detección más confiable del estado de las instancias.

3. **Menor sobrecarga**: Al operar en la capa de transporte en lugar de la capa de aplicación, los NLB introducen menos sobrecarga en la comunicación entre el cliente y el servidor.

4. **Preservación de direcciones IP de origen**: Los NLB preservan las direcciones IP de origen de los clientes, lo que puede ser beneficioso para ciertas aplicaciones.

### Uso de estado remoto

Se implementó el almacenamiento del estado en S3 con bloqueo en DynamoDB para permitir:

1. **Colaboración**: Múltiples desarrolladores pueden trabajar con la misma infraestructura
2. **Seguridad**: El estado se almacena cifrado en S3
3. **Bloqueo**: Se evitan modificaciones concurrentes que podrían causar inconsistencias

## Recursos AWS utilizados
- aws_vpc
- aws_subnet
- aws_internet_gateway
- aws_route_table
- aws_security_group
- aws_db_subnet_group
- aws_db_instance
- aws_instance
- aws_lb (tipo: network)
- aws_lb_target_group
- aws_lb_listener

## Provisioners implementados
- local-exec: Guarda información sobre las instancias creadas
- user_data: Configura automáticamente los servidores web al iniciar

## Limpieza de recursos

Para eliminar todos los recursos creados por este proyecto:

```bash
terraform destroy
```

Confirma escribiendo `yes` cuando se te solicite.

## Posibles mejoras futuras

- Implementación de Auto Scaling para una mejor capacidad de respuesta bajo carga
- Configuración de HTTPS mediante certificados SSL/TLS
- Implementación de CloudWatch para monitoreo y alertas
- Configuración de respaldos automáticos
- Implementación de un pipeline de CI/CD para automatizar despliegues

## Troubleshooting

### Problema: No se puede acceder a la aplicación web
- Verifica que las instancias EC2 estén en estado "running"
- Comprueba los logs de Apache en `/var/log/httpd/error_log`
- Verifica que el grupo de seguridad permita tráfico HTTP

### Problema: Error de conexión a la base de datos
- Verifica que la base de datos esté en estado "available"
- Comprueba que el archivo `config.php` tenga los parámetros correctos
- Verifica que el grupo de seguridad permita tráfico desde los servidores web

## Autor

Lucas Rodriguez - lucasro01@gmail.com

---

Proyecto desarrollado como parte del curso de Implementación de Soluciones Cloud / Tema: Infraestructura como Código - Universidad ORT Uruguay