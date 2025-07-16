```
project url: 
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNkaWRlc2h3cnl2eGhiY2pjaHh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNzA0MzUsImV4cCI6MjA2NzY0NjQzNX0.Gfj8V1PuLxfjfDb_EHKSY6mdIzA5dLAQrveKpIi098o
API key:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNkaWRlc2h3cnl2eGhiY2pjaHh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNzA0MzUsImV4cCI6MjA2NzY0NjQzNX0.Gfj8V1PuLxfjfDb_EHKSY6mdIzA5dLAQrveKpIi098o

STRING:
postgresql://postgres:[YOUR-PASSWORD]@db.cdideshwryvxhbcjchxt.supabase.co:5432/postgres

host:
db.cdideshwryvxhbcjchxt.supabase.co

port:
5432

database:
postgres

user:
postgres


```

# PostgreSQL
Es una base de datos relacional que se encarga de almacenar los datos de la aplicación.

# Supabase
Es una base de datos relacional que se encarga de almacenar los datos de la aplicación.

---
## Tablas
### roles
- id_rol
- nombre_rol
- descripcion
- permisos
### ubicaciones
- id_ubicacion
- direccion
- coordenadas
### usuarios
- id_usuario
- id_secuencial
- nombre_usuario
- correo_electronico
- contrasena_hash
- nombres
- apellidos
- telefono
- id_ubicacion_principal
- direcciones_adicionales (de tipo jsonb)
- id_rol
- estado_actividad (estado_activo, de tipo booleano)
### categorias
- id_categoria
- nombre
- descripcion
- id_categoria_padre
- estado_actividad (esta_activo)
### detalles_productos
- id_detalle_producto
- tipo_producto
- especificaciones
- peso (de tipo decimal, mide en kg)
- dimensiones (de tipo array x, y, z)
- material_principal
- materiales_secundarios (de tipo jsonb)
- cuidados_especiales (de tipo jsonb)

### productos
- id_producto
- id_secuencial (de tipo serial, secuencial)
- codigo_sku (de tipo varchar, codigo de barras)
- nombre
- descripcion (descripción del producto)
- precio (de tipo decimal)
- costo (de tipo decimal)
- cantidad_disponible (de tipo integer)
- id_categoria
- id_detalle_productos
- marca
- talla
- estado_actividad (esta_activo)
- atributos_generales (de tipo jsonb)

### imagenes_productos
- id_imagen
- id_producto
- url_imagen
- texto_alternativo
- estado_principal (de tipo boolean)
- orden_visualizacion (de tipo integer)
- fecha_creacion

### listas_deseos
- id_lista_deseos
- id_secuencial
- id_usuario
- nombre
- estado_privacidad (de tipo boolean)
- fecha_creacion
- fecha_actualizacion

### items_lista_deseos
- id_item_lista_deseos
- id_lista_deseos
- id_producto

### carritos_compras (solo debe haber un solo carrito por usuario, una vez realizado el pedido, se eliminan los items adquiridos del carrito)
- id_carrito
- id_secuencial
- id_usuario
- fecha_actualizacion

### items_carrito
- id_item_carrito
- id_carrito
- id_producto
- cantidad

### estados_pedido
- id_estado
- codigo_estado (es unico)
- nombre_estado
- descripcion
- estado_final (de tipo booleano)
- orden_flujo (de tipo integer)

### metodos_pago
- id_metodo_pago
- nombre
- descripcion
- requiere_confirmacion (de tipo booleano)
- esta_activo (de tipo booleano)
- configuracion (de tipo jsonb)

### pedidos
- id_pedido
- id_usuario
- numero_pedido (unico)
- id_estado
- subtotal
- impuestos
- costo_envio
- total
- id_metodo_pago
- estado_pago (de tipo booleano)
- direccion (de tipo jsonb)
- informacion_remitente (de tipo jsonb)
- coordenadas (de tipo geometry)
- notas

### items_pedido
- id_item_pedido
- id_pedido
- id_producto
- cantidad
- precio_unitario
- precio_total
- descuento
- impuestos

### resenas_productos
- id_resena
- id_producto
- id_usuario
- calificacion (de tipo integer, de 1 a 5)
- comentario
- estado_aprobado (de tipo booleano)
- fecha_creacion
- fecha_actualizacion

## Tablas de auditoria e historiales
### registro_inventario
- id_registro
- id_producto
- cambio_cantidad
- nueva_cantidad
- tipo_cambio
- id_referencia
- tipo_referencia
- notas
- modificado_por
- fecha_cambio
### historial_estados_pedido
- id_historial
- id_pedido
- id_estado
- id_usuario
- notas
- fecha_cambio
### historial_precios
- id_historial_precio
- id_producto
- precio_anterior
- precio_nuevo
- modificado_por
- razon_cambio
- fecha_cambio

---


## Extensiones
- pgcrypto
  - Generar contraseñas aleatorias
- pg_stat_statements
  - Monitoreo de consultas
- postGIS
  - Geolocalización de tiendas
- ZomboDB
  - Búsqueda por similaridad
- postgres_fdw
  - Integración de tablas externas
- timescaledb
  - Optimización de tablas temporales
- pg_buffercache
  - Monitoreo de memoria
- pg_piwik
  - Análisis de usuarios
- intarray
  - Búsqueda por similaridad
- pgSphere
  - Geolocalización de tiendas
- PGX y pgspot
  - 
---

# Estructura de APIs
Se crean esquemas en PostgreSQL para cada API.
- public (api_public)
- customer (api_customer)
- admin (api_admin)
- delivery (api_delivery)

# API Pública (api_publica)
Esta estructura se encarga de las operaciones que no requieren autenticación. Aquí se aplican los filtros de búsqueda y los filtros de paginación.
## Endpoints (Procedimientos almacenados)
- Registrarse
- Iniciar sesión
- Ver descuentos
- Ver promociones
- Ver ofertas
- Ver detalles de un producto
- Buscar productos
- Filtrar productos
- Ver fotos de un producto
- Ver reseñas de un producto
- Ver calificaciones de un producto
- Ver comentarios de un producto
- Ver categorías
- Ver subcategorías
- Ver subsubcategorías

# API Cliente (api_cliente)
## Endpoints (Procedimientos almacenados)
- Ver **perfiles**
  - Ver mi perfil
  - Ver perfil de otro cliente
- Modificar **mi perfil**
  - Modificar nombre
  - Modificar apellido
  - Modificar correo
  - Modificar contraseña
- Ver **mis pedidos**
  - Ver todos mis pedidos
  - Ver detalles de un pedido
- Ver **mis listas de deseos**
  - Eliminar lista de deseos
  - Crear lista de deseos
  - Ver todas mis listas de deseos
  - Modificar mis listas de deseos
    - Modificar nombre
    - Modificar descripción
    - Modificar privacidad
      - Privada
      - Pública
  - Modificar productos
    - Añadir producto
    - Eliminar producto
- Ver **listas de deseos públicas**
- Ver **carrito de compra**
  - Añadir un producto al carrito de compra
  - Eliminar un producto del carrito de compra
  - Modificar la cantidad de un producto en el carrito de compra
  - Ver detalles de un producto en el carrito de compra
  - Ver detalles de un producto en el carrito de compra de un cliente

# API Administrador (api_admin)
Aunque los administradores tengan acceso a la información privilegiada, estos no tiene acceso ni permisos de modificar la información personal de los clientes (api_cliente).
## Endpoints (Procedimientos almacenados)
- Ver mi perfil de administrador
- Modificar mi perfil de administrador
  - Modificar nombre
  - Modificar apellido
  - Modificar correo
  - Modificar contraseña
- Ver **todos los pedidos**
  - Ver todos los pedidos
  - Ver detalles de un pedido
- Ver información de los **clientes**
  - Ver todos los clientes
  - Ver detalles de un cliente
- Ver **todos los pedidos de un cliente**
  - Ver todos los pedidos de un cliente
  - Ver detalles de un pedido de un cliente
- Modificar **productos**
  - Modificar nombre
  - Modificar descripción
  - Modificar precio
  - Modificar stock
  - Modificar categoría
  - Modificar subcategoría
  - Modificar subsubcategoría
  - Modificar detalles técnicos
  - Modificar imágenes
- Ver historial de modificaciones
  - Ver historial de modificaciones de un producto
  
> NOTA: Los estados de los pedidos son: 
> - Pendiente: El pedido se ha creado (
  pagado) pero aún no se ha enviado
> - Enviado: El pedido se ha enviado
> - Entregado: El pedido se ha entregado
> - Cancelado: El pedido se ha cancelado (el pago se ha realizado pero el pedido se ha cancelado)

# API Entregador (api_delivery)
## Endpoints (Procedimientos almacenados)
- Ver todos estados de pedidos (solo el numero_pedido y estado)
- Modificar estado de un pedido en estado de **Por enviar** a estado de **Enviado** (solo se muestra el numero_pedido y estado). No se puede modificar a estado de cancelado.
- Ver dirección y coordenadas de un pedido en estado **Por enviar y Enviado**
- Ver información de contacto de un pedido en estado **Por enviar y Enviado** (se muestra )


# Estructura de roles
Cada usuario registrado tendrá que ser asignado a un rol, los cuales serán:
- admin (tiene acceso a la api_admin y api_public)
- customer (tiene acceso a la api_customer y api_public). Solo puede ser registrado mediante la api_public
- delivery (tiene acceso a la api_delivery y api_public)
- metal_user (superuser: Tiene acceso a todas las APIs, puede realizar todas las operaciones)

# Sistema de reportes


# Seguridad a nivel de fila (Row Level Security)
...


---
# PUBLIC
Características Clave Implementadas
Seguridad:

Uso de SECURITY DEFINER para control de acceso

Validación de datos de entrada

Manejo de errores con bloques EXCEPTION

Optimización:

Paginación eficiente en todas las consultas

Uso de índices implícitos en WHERE y ORDER BY

Consultas anidadas para minimizar transferencia de datos

Estandarización JSON:

Estructuras consistentes en todas las respuestas

Formato uniforme para fechas, precios y unidades

Campos anidados para relaciones (ej. categorías, imágenes)

Funcionalidades Especiales:

Búsqueda por geolocalización con PostGIS

Sistema de reseñas con paginación

Filtros avanzados para productos

Manejo de promociones y ofertas

Adaptación al contexto peruano:

Validación de formatos de teléfono (9 dígitos, comienza con 9)

Manejo de direcciones con estructura peruana (distrito, provincia, departamento)

Moneda implícita en Soles (S/)

---
# CUSTOMER
Características Clave Implementadas
Gestión de Perfil Completa:

Consulta y actualización de datos personales

Cambio seguro de contraseña con verificación

Manejo de direcciones principales y adicionales

Sistema de Pedidos:

Listado paginado con filtros por estado

Detalle completo con historial de estados

Integración con métodos de pago

Listas de Deseos Avanzadas:

CRUD completo de listas

Control de privacidad (públicas/privadas)

Movimiento de listas al carrito

Productos recientes en vistas públicas

Carrito de Compras:

Gestión automática (creación al primer producto)

Validación de disponibilidad de stock

Actualización de cantidades

Resumen de compra

Seguridad:

Verificación de propiedad en todas las operaciones

Validación de datos de entrada

Manejo estructurado de errores

Optimización:

Respuestas JSON estructuradas y normalizadas

Paginación en listados largos

Consultas eficientes con JOINs optimizados
---
# ADMIN
Características Clave Implementadas
Gestión de Perfil de Administrador:

Consulta de perfil con privilegios

Actualización segura de datos personales

Cambio de contraseña con verificación

Gestión Completa de Pedidos:

Listado con filtros avanzados (estado, fechas)

Visualización detallada con historial de estados

Actualización de estados con validación de flujo

Gestión de Clientes:

Listado paginado con estadísticas básicas

Detalle completo con historial de compras

Visualización de listas de deseos

Gestión de Productos:

Actualización de datos básicos y técnicos

Manejo de imágenes (agregar, modificar, eliminar)

Registro automático de cambios en precios e inventario

Sistema de Auditoría:

Historial detallado de cambios de precios

Trazabilidad completa de movimientos de inventario

Registro de modificaciones con usuario responsable

Seguridad:

Validación de privilegios en todas las funciones

Protección contra modificaciones no autorizadas

Manejo estructurado de errores
---
# DELIVERY
Características Clave Implementadas
Gestión de Estados de Pedidos:

Listado de pedidos en estados "por enviar" y "enviado"

Transición controlada de estado "por enviar" a "enviado"

Validación de flujo de estados (no se permite cancelación)

Información para Entrega:

Acceso a direcciones con coordenadas geográficas

Información de contacto del cliente

Datos del remitente para devoluciones

Seguridad y Validaciones:

Restricción a solo pedidos en estados específicos

Protección contra modificaciones no autorizadas

Validación de transiciones de estado

Optimización para Dispositivos Móviles:

Respuestas concisas con solo información necesaria

Coordenadas en formato GeoJSON para mapas

Estructura simple para visualización rápida

Integración con PostGIS:

Manejo de coordenadas geográficas

Posibilidad de cálculo de rutas

Representación estándar de ubicaciones
---

