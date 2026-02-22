CREATE DATABASE Bascula;

GO

USE Bascula;

GO

------------------------------------------- USUARIOS Y PERMISOS DEL SISTEMA -------------------------------------------

-- Tabla de Roles       
CREATE TABLE Rol(   
    CodigoRol UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY NOT NULL,
    NombreRol NVARCHAR(50) UNIQUE NOT NULL,
    DescripRol NVARCHAR(MAX) NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoRol BIT DEFAULT 1
);

GO

-- Tabla de Usuarios         
CREATE TABLE Users(
    CodigoUser UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY NOT NULL,
    NameUser NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Clave VARBINARY(300) NOT NULL,   -- Para encriptar con HASHBYTES(SHA2_256, clave)
    Rol UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Rol(CodigoRol) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    LastLogin DATETIMEOFFSET,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   
    DateDelete DATETIMEOFFSET,
    EstadoUser BIT DEFAULT 1
); 

------------------------------------------- GESTION DE INVENTARIO -------------------------------------------

-- Tabla de Almacen (Para almacenar los productos y servicios)
--- Por el momento solo hay uno.
CREATE TABLE Almacen(
    CodAlmacen INT IDENTITY(100,1) PRIMARY KEY NOT NULL, 
    NombreAlmacen NVARCHAR(50) UNIQUE NOT NULL,
    DescripAlmacen NVARCHAR(250),
    Direccion NVARCHAR(250) NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoAlmacen BIT DEFAULT 1
);

GO

-- Tabala de Categorias
CREATE TABLE Categoria(
    CodCat INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    NombreCat NVARCHAR(50) UNIQUE NOT NULL,
    DescripCat NVARCHAR(MAX) NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoCat BIT DEFAULT 1
);

GO

-- Tabla de Subcategorias
CREATE TABLE SubCategoria(
    CodSubCat INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    NombreSubCat NVARCHAR(50) UNIQUE NOT NULL,
    DescripSubCat NVARCHAR(MAX) NOT NULL,
    CodCat INT FOREIGN KEY REFERENCES Categoria(CodCat) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoSubCat BIT DEFAULT 1
);

GO

-- Tabla de Productos (BASCULAS)
CREATE TABLE Producto(
    CodProd INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    NombreProd NVARCHAR(50) UNIQUE NOT NULL,
    DescripProd NVARCHAR(MAX) NOT NULL,
    CodSubCat INT FOREIGN KEY REFERENCES SubCategoria(CodSubCat) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL, 
    Stock INT NOT NULL CHECK (Stock >= 0),
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoProd BIT DEFAULT 1
);

GO

-- Tabla de Detalle de Producto (Para almacenar el stock minimo, precio de compra y venta)
CREATE TABLE DetalleProducto(
    CodDetProd INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    CodProd INT FOREIGN KEY REFERENCES Producto(CodProd) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    StockMinimo INT CHECK (StockMinimo >= 0) NOT NULL, -- Para alerta
    PrecioUnitario DECIMAL(18,4) CHECK (PrecioUnitario > 0) NOT NULL,
    PrecioVenta DECIMAL(18,4) CHECK (PrecioVenta > 0) NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoDetProd BIT DEFAULT 1
);

GO

-- Taba de Union entre Almacen y Producto
CREATE TABLE ProductoAlmacen(
    CodAlmacen INT FOREIGN KEY REFERENCES Almacen(CodAlmacen) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    CodProd INT FOREIGN KEY REFERENCES Producto(CodProd) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    PRIMARY KEY (CodAlmacen, CodProd),
    StockActual INT NOT NULL CHECK (StockActual >= 0), -- Para almacenar el stock actual del producto en el almacen
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoAlmacenProd BIT DEFAULT 1
);

GO

--- Tabla de Metodo de Pago (Se utiliza para las compras y ventas)
CREATE TABLE MetodoPago (
    CodMetodoPago INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    NombreMetodo NVARCHAR(50) UNIQUE NOT NULL,      -- Ej: 'Efectivo', 'Transferencia'
    DescripMetodo NVARCHAR(250),                    -- Descripción opcional
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,
    DateDelete DATETIMEOFFSET,
    EstadoMetodo BIT DEFAULT 1
);

GO

-- Tabla Pago
CREATE TABLE Pago (
    CodPago INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    CodMetodoPago INT FOREIGN KEY REFERENCES MetodoPago(CodMetodoPago) ON DELETE SET NULL ON UPDATE CASCADE,
    FechaPago DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    MontoPago DECIMAL(18,4) CHECK (MontoPago > 0) NOT NULL,
    EstadoPago NVARCHAR(15) CHECK (EstadoPago IN ('aplicado', 'anulado', 'pendiente')) DEFAULT 'Aplicado',
    IdUser UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Users(CodigoUser),
    DateUpdate DATETIMEOFFSET,
    DateDelete DATETIMEOFFSET

);


GO

-- Tabla de Proveedores (Para las compras de productos)
CREATE TABLE Proveedor(
    CodProv INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    NombreProv NVARCHAR(50) NOT NULL, /*Le quite el UNIQUE para que se puedan registrar varios proveedores que compartan nombre --J*/
    DescripProv NVARCHAR(MAX),
    Telefono NVARCHAR(8) CHECK(Telefono LIKE '[2578][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') UNIQUE NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Direccion NVARCHAR(250) NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoProv BIT DEFAULT 1
);

GO

--- Tabla de proveedores porductos
CREATE TABLE ProveedorProducto(
    CodProv INT FOREIGN KEY REFERENCES Proveedor(CodProv) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    CodProd INT FOREIGN KEY REFERENCES Producto(CodProd) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    PRIMARY KEY (CodProv, CodProd) 
);

GO

-- Tabla de Compras 
CREATE TABLE Compra(
    CodCompra INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    CodProv INT FOREIGN KEY REFERENCES Proveedor(CodProv) ON DELETE CASCADE ON UPDATE CASCADE,
    TotalCompra DECIMAL(18,4) NOT NULL,
    IdUser UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Users(CodigoUser) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    Comentario NVARCHAR(300),
    FechaCompra DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    FechaRecepcion DATETIMEOFFSET, -- Fecha de recepcion de la compra
    EstadoCompra NVARCHAR(15) CHECK (EstadoCompra IN ('registrada', 'completada', 'cancelada')) DEFAULT 'registrada' NOT NULL
);

GO

-- Tabla de Detalle de Compra
CREATE TABLE DetalleCompra(
    CodDetCompra INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    CodCompra INT FOREIGN KEY REFERENCES Compra(CodCompra) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    CodAlmacen INT FOREIGN KEY REFERENCES Almacen(CodAlmacen) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    CodProd INT FOREIGN KEY REFERENCES Producto(CodProd) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    Cantidad INT CHECK (Cantidad > 0) NOT NULL,
    PrecioUnitario DECIMAL(18,4) CHECK (PrecioUnitario > 0) NOT NULL,
    SubTotalCompra AS (Cantidad * PrecioUnitario) PERSISTED, 
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoDetCompra BIT DEFAULT 1
);

GO

-- Tabla PagoCompra se encarga para unir los pagos y las compras 
CREATE TABLE PagoCompra (
    CodPago INT FOREIGN KEY REFERENCES Pago(CodPago) ON DELETE CASCADE,
    CodCompra INT FOREIGN KEY REFERENCES Compra(CodCompra) ON DELETE CASCADE,
    PRIMARY KEY (CodPago, CodCompra)
);

GO

-- Tabla de Servicios (Mantenimiento, reparacion y calibracion de las basculas)
CREATE TABLE Servicio(
    CodServ INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    NombreServ NVARCHAR(50) UNIQUE NOT NULL,
    DescripServ NVARCHAR(MAX) NOT NULL,
    Precio DECIMAL(18,4) CHECK (Precio > 0) NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoServ BIT DEFAULT 1
);

GO

----- NO PROC
--- Gestiona el historial de todo el trafico de los productos de los almacenes 
--- Tabla de Auditoria
CREATE TABLE MovimientosInventario(
    MovimientoID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    CodProd INT FOREIGN KEY REFERENCES Producto(CodProd) NOT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    TipoMovimiento NVARCHAR(20) NOT NULL CHECK (TipoMovimiento IN ('Entrada', 'Salida', 'Ajuste')),
    FechaMovimiento DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    IdUser UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Users(CodigoUser) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    AlmacenID INT FOREIGN KEY REFERENCES Almacen(CodAlmacen) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    Comentario NVARCHAR(300)
);

GO

----- NO PROC
-- Tabla de Historial de Precios de Productos (para mantener un registro de los cambios de precios)
--- Tabla de Auditoria
CREATE TABLE HistorialPrecioProducto (
    CodHistPrecio INT IDENTITY(1,1) PRIMARY KEY,
    CodProd INT REFERENCES Producto(CodProd) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    PrecioUnitario DECIMAL(18,4) NOT NULL CHECK (PrecioUnitario > 0),
    PrecioVenta DECIMAL(18,4) NOT NULL CHECK (PrecioVenta > 0),
    FechaInicio DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
    FechaFin DATETIMEOFFSET,  -- Se llena cuando cambia el precio
    Observacion NVARCHAR(250)
);

GO

------ NO PROC
-- Tabla de Historial de Compras (para mantener un registro de los cambios en las compras)
--- Tabla de Auditoria
CREATE TABLE HistorialCompra (
    CodHistorial INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    CodCompra INT NOT NULL,
    CodProvAnterior INT,
    CodProvNuevo INT, -- Quite los campos de MétodoPago
    TotalCompraAnterior DECIMAL(18,4),
    TotalCompraNuevo DECIMAL(18,4),
    FechaCambio DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    UsuarioModifico UNIQUEIDENTIFIER NOT NULL,
    Observacion NVARCHAR(300)
);

GO

------------------------------------------- GESTION DE CLIENTES -------------------------------------------

-- Clientes (Personas Naturales)
CREATE TABLE Cliente(
    CodCliente INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    PNCL NVARCHAR(25) NOT NULL,   -- Para el Nombre del Cliente
    SNCL NVARCHAR(25),            -- Para el Segundo Nombre del Cliente
    PACL NVARCHAR(25) NOT NULL,   -- Para el Apellido del Cliente
    SACL NVARCHAR(25),            -- Para el Segundo Apellido del Cliente
    Telefono NVARCHAR(8) CHECK(Telefono LIKE '[2|5|7|8][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') UNIQUE NOT NULL,
    Direccion NVARCHAR(250) NOT NULL,
    TipoCliente NVARCHAR(15) CHECK(TipoCliente IN ('natural', 'juridico')) NOT NULL, 
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   
    DateDelete DATETIMEOFFSET,   
    EstadoCL BIT DEFAULT 1
);

GO

-- Cliente Juridico (Empresas)
CREATE TABLE ClienteJuridico (
    CodClienteJuridico INT IDENTITY(100,1) PRIMARY KEY NOT NULL, 
    RUC NVARCHAR(20) UNIQUE NOT NULL,   -- RUC J0310000112410
    NombreEmpresa NVARCHAR(100) NOT NULL,
    CodCliente INT FOREIGN KEY REFERENCES Cliente(CodCliente) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    CargoContacto NVARCHAR(50),
    EmailEmpresa NVARCHAR(100) UNIQUE NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,
    DateDelete DATETIMEOFFSET,
    EstadoCLJ BIT DEFAULT 1
);

GO

------------------------------------------- GESTION DE VENTAS -------------------------------------------

-- Tabla de Ventas
CREATE TABLE Venta(
    CodVenta INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    CodCliente INT FOREIGN KEY REFERENCES Cliente(CodCliente) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    TotalVenta DECIMAL(18,4) NOT NULL,
    IdUser UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Users(CodigoUser) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    Comentario NVARCHAR(300),
    FechaVenta DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    EstadoVenta NVARCHAR(15) CHECK (EstadoVenta IN ('registrada', 'completada', 'cancelada')) DEFAULT 'registrada' NOT NULL
);

GO

-- Tabla de Detalle de Venta
CREATE TABLE DetalleVenta(
    CodDetVenta INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    CodVenta INT FOREIGN KEY REFERENCES Venta(CodVenta) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    CodAlmacen INT FOREIGN KEY REFERENCES Almacen(CodAlmacen) ON DELETE CASCADE ON UPDATE CASCADE,
    CodProd INT FOREIGN KEY REFERENCES Producto(CodProd) ON DELETE CASCADE ON UPDATE CASCADE,
    CodServ INT FOREIGN KEY REFERENCES Servicio(CodServ) ON DELETE CASCADE ON UPDATE CASCADE,
    Cantidad INT CHECK (Cantidad > 0) NOT NULL,
    PrecioUnitario DECIMAL(18,4) CHECK (PrecioUnitario > 0) NOT NULL,
    SubTotalVenta AS (Cantidad * PrecioUnitario) PERSISTED, 
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,   -- Para ver la ultima vez que se actualizo
    DateDelete DATETIMEOFFSET,   -- Para mantener un registro de cuando se elimino
    EstadoDetVenta BIT DEFAULT 1
);

GO

-- Tabla de Garantias por Producto Vendido
CREATE TABLE GarantiaDetalle (
    CodGarantia INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    CodDetVenta INT FOREIGN KEY REFERENCES DetalleVenta(CodDetVenta) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
    PlazoMeses INT CHECK (PlazoMeses > 0) NOT NULL,
    FechaInicio DATE DEFAULT CAST(GETDATE() AS DATE),
    FechaFin AS DATEADD(MONTH, PlazoMeses, FechaInicio) PERSISTED,
    EstadoGarantia BIT DEFAULT 1
);

GO

-- Tabla PagoVenta se encarga de unir al pago y a la venta 
CREATE TABLE PagoVenta (
    CodPago INT FOREIGN KEY REFERENCES Pago(CodPago) ON DELETE CASCADE,
    CodVenta INT FOREIGN KEY REFERENCES Venta(CodVenta) ON DELETE CASCADE,
    PRIMARY KEY (CodPago, CodVenta)
);

GO

------------------------------------------- GESTION DEL TALLER -------------------------------------------

-- Tabla Taller se encarga de llervar el control de las basculas a reparar
CREATE TABLE Taller(
    CodTaller INT IDENTITY(100,1) PRIMARY KEY NOT NULL,
    NombreTaller NVARCHAR(50) NOT NULL,
    DescripTaller NVARCHAR(MAX) NOT NULL,
    CodCliente INT FOREIGN KEY REFERENCES Cliente(CodCliente) ON UPDATE CASCADE ON DELETE CASCADE NOT NULL,
    DateCreate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    DateUpdate DATETIMEOFFSET,
    DateDelete DATETIMEOFFSET,
    EstadoTaller BIT DEFAULT 1 -- 1: En reparacion; 0:reparado
);

GO

-------------------------------- GESTION DE CAJA --------------------------------
-- Tabla Caja
CREATE TABLE Caja (
    ID_Caja INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Ubicacion NVARCHAR(200),
    Estado NVARCHAR(50) NOT NULL DEFAULT 'Activa',
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    FechaUltimaModificacion DATETIME NOT NULL DEFAULT GETDATE()
);

-- Tabla TransaccionCaja
CREATE TABLE TransaccionCaja (
    ID_Transaccion BIGINT IDENTITY(1,1) PRIMARY KEY,
    ID_Caja INT NOT NULL,
    Tipo_Transaccion NVARCHAR(50) NOT NULL, -- Venta, Devolucion, Apertura, Cierre, Ingreso, Egreso
    Monto DECIMAL(18,2) NOT NULL,
    Moneda NVARCHAR(10) NOT NULL DEFAULT 'USD',
    Metodo_Pago NVARCHAR(50), -- Efectivo, TarjetaCredito, TarjetaDebito, Transferencia
    ID_Ticket_Factura NVARCHAR(50), -- Número de ticket o factura, puede ser NULL
    Estado_Transaccion NVARCHAR(50) NOT NULL DEFAULT 'Completada',
    Comentario NVARCHAR(500),
    Usuario_Aplicacion NVARCHAR(100) NOT NULL, -- Usuario de la aplicación
    FechaHora_Transaccion DATETIME NOT NULL,
    FechaHora_Registro DATETIME NOT NULL DEFAULT GETDATE(),
    Usuario_Registro NVARCHAR(128) NOT NULL DEFAULT SUSER_NAME(),
    CONSTRAINT FK_TransaccionCaja_Caja FOREIGN KEY (ID_Caja) REFERENCES Caja(ID_Caja)
);

-- Tabla ArqueoCaja
CREATE TABLE ArqueoCaja (
    ID_Arqueo BIGINT IDENTITY(1,1) PRIMARY KEY,
    ID_Caja INT NOT NULL,
    FechaHora_Apertura DATETIME NOT NULL,
    FechaHora_Cierre DATETIME,
    Monto_Apertura DECIMAL(18,2) NOT NULL,
    Monto_Cierre DECIMAL(18,2),
    Monto_Calculado DECIMAL(18,2),
    Diferencia DECIMAL(18,2),
    Usuario_Apertura NVARCHAR(100) NOT NULL,
    Usuario_Cierre NVARCHAR(100),
    Estado_Arqueo NVARCHAR(50) NOT NULL DEFAULT 'Abierto',
    Comentario NVARCHAR(500),
    CONSTRAINT FK_ArqueoCaja_Caja FOREIGN KEY (ID_Caja) REFERENCES Caja(ID_Caja)
);

-- Tabla de Auditoria para TransaccionCaja
CREATE TABLE AuditoriaTransaccionCaja (
    ID_Auditoria BIGINT IDENTITY(1,1) PRIMARY KEY,
    ID_Transaccion BIGINT NOT NULL,
    Evento NVARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    Valor_Anterior NVARCHAR(MAX), -- JSON o texto con los valores anteriores (solo para UPDATE y DELETE)
    Valor_Nuevo NVARCHAR(MAX),    -- JSON o texto con los valores nuevos (solo para INSERT y UPDATE)
    Usuario_Base_Datos NVARCHAR(128) NOT NULL,
    Usuario_Aplicacion NVARCHAR(100), -- Copia del usuario de la aplicación en el momento de la transacción
    FechaHora_Auditoria DATETIME NOT NULL DEFAULT GETDATE(),
    Direccion_IP NVARCHAR(50), -- Se puede intentar capturar con CONNECTIONPROPERTY('client_net_address')
    Nombre_Host NVARCHAR(128) -- Se puede capturar con HOST_NAME()
);
