# Sistema de Gestión de Básculas (DB_Basculas)

Este proyecto contiene la infraestructura y el esquema de base de datos para un sistema de gestión integral de básculas, abarcando desde el control de inventario y ventas hasta el mantenimiento en taller y la gestión financiera de caja.

## 🚀 Tecnologías Utilizadas

- **Base de Datos**: Microsoft SQL Server (MSSQL) 2022.
- **Contenedorización**: Docker con Docker Compose.
- **Lenguaje**: T-SQL.

---

## 📊 Arquitectura del Sistema

El sistema está diseñado modularmente para garantizar escalabilidad, seguridad y trazabilidad total de las operaciones.

### 🔐 1. Seguridad y Acceso
Gestión de permisos basada en roles para asegurar la integridad de la información.
- **`Rol`**: Define los niveles de acceso (Administrador, Vendedor, Técnico, Almacenista).
- **`Users`**: Usuarios del sistema con contraseñas encriptadas mediante `HASHBYTES` (SHA2_256).

### 📦 2. Gestión de Inventario
Control exhaustivo de existencias distribuidas y catalogación jerárquica.
- **`Almacen`**: Ubicaciones físicas donde se resguardan los productos.
- **`Categoria` & `SubCategoria`**: Clasificación organizada para facilitar búsquedas y reportes.
- **`Producto`**: Maestro de artículos (básculas y repuestos).
- **`DetalleProducto`**: Precios de compra/venta y alertas de stock mínimo.
- **`ProductoAlmacen`**: Control de stock específico por cada ubicación física.

### 🛒 3. Compras y Proveedores
Ciclo completo de adquisición y abastecimiento.
- **`Proveedor`**: Ficha técnica y de contacto de socios comerciales.
- **`ProveedorProducto`**: Relación de qué proveedor surte qué productos.
- **`Compra` & `DetalleCompra`**: Registro de facturación de compra y recepción detallada.
- **`MovimientosInventario`**: Auditoría en tiempo real de entradas, salidas y ajustes manuales.

### 💰 4. Clientes y Ventas
Gestión comercial orientada al cliente y seguimiento post-venta.
- **`Cliente` & `ClienteJuridico`**: Registro detallado de personas naturales y empresas (RUC).
- **`Venta` & `DetalleVenta`**: Procesamiento de transacciones comerciales de bienes y servicios.
- **`GarantiaDetalle`**: Seguimiento automático de periodos de garantía por cada artículo vendido.

### 🛠️ 5. Taller y Servicios
Módulo de servicios técnicos y reparaciones.
- **`Servicio`**: Catálogo de mano de obra (calibración, reparación, mantenimiento).
- **`Taller`**: Gestión de equipos de clientes que ingresan para intervención técnica.

### 🏦 6. Gestión de Caja y Finanzas
Control riguroso del flujo de efectivo y auditoría transaccional.
- **`Caja`**: Terminales o puntos de recaudación físicos.
- **`ArqueoCaja`**: Procesos de apertura, cierre y conciliación de diferencias.
- **`TransaccionCaja`**: Registro pormenorizado de cada ingreso y egreso vinculado a la caja.
- **`Pago` & `MetodoPago`**: Centralización de cobros (Efectivo, Tarjeta, Transferencia).
- **`PagoVenta` & `PagoCompra`**: Tablas de vínculo para saldar transacciones comerciales.

---

## Diagrama de Base de Datos (ER)

Refleja la estructura completa del sistema, incluyendo los flujos de auditoría y gestión de caja.

```mermaid
erDiagram
    Rol ||--o{ Users : "pertenece"
    Users ||--o{ Venta : "registra"
    Users ||--o{ Compra : "registra"
    Users ||--o{ Pago : "procesa"
    Users ||--o{ MovimientosInventario : "autoriza"
    
    Categoria ||--o{ SubCategoria : "contiene"
    SubCategoria ||--o{ Producto : "clasifica"
    Producto ||--o{ DetalleProducto : "tiene"
    Producto ||--o{ ProductoAlmacen : "stock en"
    Almacen ||--o{ ProductoAlmacen : "aloja"
    Almacen ||--o{ MovimientosInventario : "origen/destino"
    Producto ||--o{ MovimientosInventario : "afecta"
    
    Proveedor ||--o{ ProveedorProducto : "suministra"
    Producto ||--o{ ProveedorProducto : "referenciado"
    Proveedor ||--o{ Compra : "vende"
    Compra ||--o{ DetalleCompra : "compuesta por"
    Producto ||--o{ DetalleCompra : "comprado"
    Almacen ||--o{ DetalleCompra : "recibe"
    
    Cliente ||--o{ ClienteJuridico : "puede ser"
    Cliente ||--o{ Venta : "compra"
    Cliente ||--o{ Taller : "solicita"
    Venta ||--o{ DetalleVenta : "compuesta por"
    Producto ||--o{ DetalleVenta : "vendido"
    Servicio ||--o{ DetalleVenta : "prestado"
    DetalleVenta ||--o{ GarantiaDetalle : "garantiza"
    
    Caja ||--o{ ArqueoCaja : "gestiona"
    Caja ||--o{ TransaccionCaja : "registra"
    Caja ||--o{ Venta : "recauda"
    Caja ||--o{ Compra : "desembolsa"
    
    MetodoPago ||--o{ Pago : "usado en"
    Pago ||--o{ PagoVenta : "aplicado"
    Venta ||--o{ PagoVenta : "saldada"
    Pago ||--o{ PagoCompra : "aplicado"
    Compra ||--o{ PagoCompra : "saldada"
    
    Producto ||--o{ HistorialPrecioProducto : "rastrea"
    Compra ||--o{ HistorialCompra : "audita"
    TransaccionCaja ||--o{ AuditoriaTransaccionCaja : "seguridad"
```
Si quieres ver mejor el esquema relacional haz clic **[aquí](https://github.com/WalterJiron/DB_Basculas/blob/main/db_basculas.pdf)**

---

## 📂 Estructura del repositorio

- `DB_Basculas.sql`: Definiciones DDL (tablas, relaciones, constraints).
- `inserts.sql`: Carga masiva de datos iniciales y catálogos.
- `procedures/`: Directorio organizado por módulos con toda la lógica CRUD y procesos de negocio.
- `Triggers/`: Disparadores para automatización de stock e historiales de auditoría.
- `views/`: Vistas predefinidas para reportes financieros y operativos.
- `compose.yml` & `dockerfile`: Infraestructura como código para despliegue rápido.

---

## 🛠️ Instalación y Despliegue

### Requisitos
- Docker instalados.
    - [Para Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
    - [Para Linux](https://docs.docker.com/desktop/setup/install/linux/)
      
> [!TIP]
> Por cualquier error en la instlación consultar [youtube](https://www.youtube.com/).   

---

## Instalación

### 1. **Configuración Inicial**:

Antes de iniciar el contenedor, edita el archivo compose.yml y configura la variable de entorno:

```yml
    MSSQL_SA_PASSWORD= Tu_contraseña
```
> [!NOTE]
> El valor que le des a esa variable sera la contraseña de ususario **sa** que usaras para
> conectarte a la base de datos.

---
    
### 2. **Iniciar el Servidor**:
```bash
    docker compose up -d
```
   
> [!NOTE]
> *El sistema detectará automáticamente el esquema y cargará los procedimientos, disparadores, vistas y datos maestros al iniciar por primera vez.*

> [!WARNING]
> Antes de ejecutar este comando, verifique que el puerto **1433** no esté siendo utilizado por otra instancia de **SQL Server** u otro servicio.
> Si el puerto está ocupado, el contenedor no podrá iniciarse y se producirá un error de conflicto de puerto (*port binding conflict*).
>
> **En Windows (PowerShell o CMD):**
>
> ```powershell
> netstat -ano | findstr :1433
> ```
>
> **En Linux:**
>
> ```bash
> sudo lsof -i :1433
> ```
>
> Si el comando devuelve resultados, significa que el puerto está en uso. En ese caso, deberá:
>
> * Detener el servicio que lo está utilizando, o
> * Modificar el puerto expuesto en el archivo `compose.yml`
>     * Ejemplo puedes usar el puerto 1434 o algún puerto que esté disponible:
>
> ```yml
> ports:
>      - "1434:1433"
> ``` 
---

### 3. **Conexión a la Base de Datos**

Una vez que el contenedor esté en ejecución, puedes conectarte utilizando cualquiera de las siguientes herramientas:

* **Azure Data Studio** (recomendado por su ligereza y compatibilidad multiplataforma)
* **SQL Server Management Studio (SSMS)**
* **Visual Studio Code (VScode)**
* Cualquier IDE con soporte para SQL Server

#### 🔐 Parámetros de Conexión

| Parámetro  | Valor                                               |
| ---------- | --------------------------------------------------- |
| Servidor   | `localhost`                                         |
| Puerto     | `1433` *(o el puerto configurado en `compose.yml`)* |
| Usuario    | `sa`                                                |
| Contraseña | La definida en `MSSQL_SA_PASSWORD`                  |

Si cambiaste el puerto, por ejemplo a **1434**, deberás conectarte de la siguiente manera:

```
localhost,1434
```

o

```
127.0.0.1,1434
```

---

> [!TIP]
> Para detener y eliminar el contenedor ejecuta:
>
> ```bash
> docker compose down
> ```
