USE Bascula;

GO

INSERT INTO Rol
    (NombreRol, DescripRol)
VALUES
    ('Administrador', 'Tiene acceso completo al sistema'),
    ('Vendedor', 'Puede realizar ventas y consultar inventario'),
    ('Técnico', 'Encargado de servicios de mantenimiento y reparación'),
    ('Almacenista', 'Gestiona el inventario y movimientos de almacén');

GO

-- Clave: Admin123 (encriptada con SHA2_256)
INSERT INTO Users
    (NameUser, Email, Clave, Rol)
VALUES
    ('Juan Pérez', 'juan.perez@bascula.com', HASHBYTES('SHA2_512', 'Admin123'), (SELECT CodigoRol
        FROM Rol
        WHERE NombreRol = 'Administrador')),
    ('María López', 'maria.lopez@bascula.com', HASHBYTES('SHA2_512', 'Vendedor123'), (SELECT CodigoRol
        FROM Rol
        WHERE NombreRol = 'Vendedor')),
    ('Carlos Ramírez', 'carlos.ramirez@bascula.com', HASHBYTES('SHA2_512', 'Tecnico123'), (SELECT CodigoRol
        FROM Rol
        WHERE NombreRol = 'Técnico')),
    ('Ana Martínez', 'ana.martinez@bascula.com', HASHBYTES('SHA2_512', 'Almacen123'), (SELECT CodigoRol
        FROM Rol
        WHERE NombreRol = 'Almacenista')),
    ('Walter', 'walter01@gmail.com', HASHBYTES('SHA2_512', 'walter.01' + 'walter01@gmail.com'), (SELECT CodigoRol
        FROM Rol
        WHERE NombreRol = 'Administrador'));

GO

INSERT INTO Almacen
    (NombreAlmacen, DescripAlmacen, Direccion)
VALUES
    ('Almacén Central', 'Principal almacén de básculas y repuestos', 'Calle Principal #123, Ciudad');

GO

-- 1. Categorías (10 registros)
INSERT INTO Categoria
    (NombreCat, DescripCat)
VALUES
    ('Básculas', 'Equipos de pesaje de diferentes capacidades y usos'),
    ('Repuestos', 'Componentes y piezas para mantenimiento y reparación'),
    ('Accesorios', 'Elementos complementarios para básculas'),
    ('Herramientas', 'Instrumentos para instalación y mantenimiento'),
    ('Software', 'Programas para gestión de datos de pesaje'),
    ('Baterías', 'Fuentes de energía para equipos portátiles'),
    ('Sensores', 'Dispositivos para medición de peso'),
    ('Equipo de Protección', 'Seguridad para operarios'),
    ('Materiales', 'Insumos varios para mantenimiento'),
    ('Kits', 'Paquetes especializados para instalación');

GO

-- 2. Subcategorías (12 registros)
INSERT INTO SubCategoria
    (NombreSubCat, DescripSubCat, CodCat)
VALUES
    ('Básculas Comerciales', 'Para uso en comercios y negocios', 100),
    ('Básculas Industriales', 'Para uso en industrias y procesos pesados', 100),
    ('Básculas de Laboratorio', 'Alta precisión para entornos científicos', 100),
    ('Componentes Electrónicos', 'Circuitos y partes electrónicas', 101),
    ('Plataformas', 'Superficies de pesaje', 101),
    ('Celdas de Carga', 'Sensores primarios de peso', 101),
    ('Impresoras', 'Para tickets de pesaje', 102),
    ('Display', 'Pantallas y monitores', 102),
    ('Herramientas Manuales', 'Para instalación básica', 103),
    ('Equipo de Calibración', 'Instrumentos para ajuste preciso', 103),
    ('Soportes', 'Bases y estructuras de soporte', 102),
    ('Cables y Conectores', 'Componentes de conexión', 101);

GO

-- 3. Productos (15 registros)
INSERT INTO Producto
    (NombreProd, DescripProd, CodSubCat, Stock)
VALUES
    ('Báscula Comercial BC-150', 'Capacidad 150kg, pantalla LCD', 100, 15),
    ('Báscula Industrial BI-5000', 'Capacidad 5000kg, acero inoxidable', 101, 8),
    ('Báscula Laboratorio BL-10', 'Precisión 0.01g, capacidad 10kg', 102, 5),
    ('Tarjeta Controladora TC-100', 'Control principal para básculas', 103, 25),
    ('Plataforma Acero 1x1m', 'Plataforma de acero para básculas industriales', 104, 12),
    ('Celda Carga 50kg', 'Sensor de carga para básculas comerciales', 105, 30),
    ('Impresora Térmica IT-200', 'Impresora de tickets para básculas comerciales', 106, 18),
    ('Display Digital DD-500', 'Pantalla LED para básculas industriales', 107, 10),
    ('Kit Herramientas KH-100', 'Set completo para instalación', 108, 20),
    ('Juego Pesas Calibración', 'Set de 10 pesas para calibración', 109, 8),
    ('Soporte Acero SA-300', 'Estructura de soporte para plataformas', 110, 15),
    ('Cable Conexión CC-50', 'Cable de 5m para conexión de celdas', 111, 40),
    ('Báscula Comercial BC-300', 'Capacidad 300kg, con impresora integrada', 100, 10),
    ('Báscula Industrial BI-10000', 'Capacidad 10000kg, para camiones', 101, 3),
    ('Báscula Laboratorio BL-5', 'Precisión 0.001g, capacidad 5kg', 102, 4);

GO

-- 4. DetalleProducto (15 registros)
INSERT INTO DetalleProducto
    (CodProd, StockMinimo, PrecioUnitario, PrecioVenta)
VALUES
    (100, 5, 250.00, 350.00),
    (101, 3, 1800.00, 2500.00),
    (102, 2, 1200.00, 1800.00),
    (103, 10, 75.00, 120.00),
    (104, 5, 300.00, 450.00),
    (105, 15, 45.00, 80.00),
    (106, 8, 150.00, 220.00),
    (107, 5, 200.00, 300.00),
    (108, 10, 80.00, 150.00),
    (109, 3, 350.00, 500.00),
    (110, 5, 180.00, 280.00),
    (111, 20, 15.00, 30.00),
    (112, 5, 400.00, 550.00),
    (113, 2, 3500.00, 4800.00),
    (114, 2, 1500.00, 2200.00);

GO

-- 5. ProductoAlmacen (15 registros)
INSERT INTO ProductoAlmacen
    (CodAlmacen, CodProd, stockActual)
VALUES
    (100, 100, 15),
    (100, 101, 8),
    (100, 102, 5),
    (100, 103, 25),
    (100, 104, 12),
    (100, 105, 30),
    (100, 106, 18),
    (100, 107, 10),
    (100, 108, 20),
    (100, 109, 8),
    (100, 110, 15),
    (100, 111, 40),
    (100, 112, 10),
    (100, 113, 3),
    (100, 114, 4);

GO

-- 6. MetodoPago (10 registros)
INSERT INTO MetodoPago
    (NombreMetodo, DescripMetodo)
VALUES
    ('Efectivo', 'Pago en efectivo al momento de la compra'),
    ('Transferencia', 'Transferencia bancaria'),
    ('Tarjeta de Crédito', 'Pago con tarjeta de crédito'),
    ('Tarjeta de Débito', 'Pago con tarjeta de débito'),
    ('Cheque', 'Pago con cheque a 30 días'),
    ('Crédito 15 días', 'Pago a crédito con vencimiento 15 días'),
    ('Crédito 30 días', 'Pago a crédito con vencimiento 30 días'),
    ('PayPal', 'Pago electrónico a través de PayPal'),
    ('Depósito Bancario', 'Depósito directo en cuenta'),
    ('Financiamiento', 'Pago a plazos con financiamiento');

GO

-- 7. Proveedores (12 registros)
INSERT INTO Proveedor
    (NombreProv, DescripProv, Telefono, Email, Direccion)
VALUES
    ('Tecnopesaje S.A.', 'Fabricante de básculas industriales', '22223333', 'ventas@tecnopesaje.com', 'Zona Industrial, Calle 5 #10-20'),
    ('ElectroComponentes', 'Distribuidor de componentes electrónicos', '25556666', 'info@electrocomp.com', 'Av. Principal #45-30'),
    ('Accesorios Pesaje', 'Proveedor de accesorios para básculas', '27778888', 'contacto@accesoriospesaje.com', 'Calle Comercial #12-15'),
    ('Pesos Exactos', 'Fabricante de básculas de laboratorio', '23334444', 'ventas@pesosexactos.com', 'Parque Tecnológico, Edif. 3'),
    ('HerraTools', 'Distribuidor de herramientas profesionales', '24445555', 'pedidos@herratools.com', 'Av. Industrial #200'),
    ('SensoTech', 'Fabricante de celdas de carga', '26667777', 'info@sensotech.com', 'Polígono Industrial Norte'),
    ('Display Solutions', 'Especialistas en pantallas digitales', '28889999', 'ventas@displaysol.com', 'Centro Comercial Tecnológico'),
    ('CableMasters', 'Fabricante de cables especializados', '21112222', 'contacto@cablemasters.com', 'Zona Franca #45'),
    ('Baterías Power', 'Distribuidor de baterías industriales', '29990000', 'ventas@bateriaspower.com', 'Av. Energía #150'),
    ('SoftMetrics', 'Desarrolladores de software para pesaje', '23339999', 'soporte@softmetrics.com', 'Parque de Innovación, Of. 12'),
    ('Protección Total', 'Equipos de seguridad industrial', '24446666', 'cotizaciones@protecciontotal.com', 'Calle Seguridad #78'),
    ('Materiales Industriales', 'Distribuidor de insumos varios', '27770000', 'info@materialesind.com', 'Zona Industrial Sur');

GO

-- 8. Servicios (12 registros)
INSERT INTO Servicio
    (NombreServ, DescripServ, Precio)
VALUES
    ('Calibración Báscula Comercial', 'Calibración certificada para básculas comerciales', 50.00),
    ('Calibración Báscula Industrial', 'Calibración certificada para básculas industriales', 120.00),
    ('Mantenimiento Preventivo', 'Revisión y ajuste general de báscula', 80.00),
    ('Reparación Electrónica', 'Reparación de componentes electrónicos', 65.00),
    ('Cambio de Plataforma', 'Reemplazo de plataforma de pesaje', 40.00),
    ('Instalación Completa', 'Instalación profesional de báscula nueva', 150.00),
    ('Actualización Software', 'Actualización de firmware y software', 75.00),
    ('Certificación OIML', 'Certificación internacional de precisión', 200.00),
    ('Reparación Mecánica', 'Ajuste y reparación de componentes mecánicos', 90.00),
    ('Limpieza Profesional', 'Limpieza especializada de equipos', 60.00),
    ('Capacitación Operativa', 'Entrenamiento para uso de equipos', 100.00),
    ('Diagnóstico Técnico', 'Evaluación completa de equipos', 45.00);

GO

-- 9. Clientes (15 registros)
-- Primero insertamos los clientes naturales
INSERT INTO Cliente
    (PNCL, SNCL, PACL, SACL, Telefono, Direccion, TipoCliente)
VALUES
    ('Roberto', 'Alberto', 'González', 'Pérez', '78889999', 'Colonia Las Flores #123', 'natural'),
    ('Marta', '', 'Rodríguez', 'Vásquez', '76665555', 'Residencial Los Pinos #45', 'natural'),
    ('Luis', 'Enrique', 'Hernández', '', '75554444', 'Barrio El Centro #67', 'natural'),
    ('Ana', 'María', 'Martínez', 'López', '74443333', 'Avenida Central #890', 'natural'),
    ('Carlos', 'José', 'Díaz', 'García', '73332222', 'Colonia San José #56', 'natural'),
    ('Patricia', '', 'Morales', 'Jiménez', '72221111', 'Residencial Las Acacias #34', 'natural'),
    ('Jorge', 'Alberto', 'Vargas', 'Ruiz', '71110000', 'Calle Principal #78', 'natural'),
    ('Sofía', 'Beatriz', 'Castro', 'Méndez', '79998888', 'Barrio Norte #12', 'natural'),
    ('Ricardo', '', 'Ortiz', 'Flores', '78887777', 'Colonia Santa Ana #45', 'natural'),
    ('Contacto', 'Comercial', 'Empresarial', '', '23334444', 'Zona Industrial Norte #100', 'juridico'),
    ('Contacto', 'Ventas', 'Distribuidora', '', '24445555', 'Centro Comercial Este #200', 'juridico'),
    ('Contacto', 'Logística', 'Industrial', '', '25556666', 'Polígono Industrial #50', 'juridico'),
    ('Contacto', 'Administración', 'Comercializadora', '', '26667777', 'Boulevard Los Próceres #300', 'juridico'),
    ('Contacto', 'Compras', 'Mayorista', '', '27778888', 'Zona Franca #25', 'juridico'),
    ('Contacto', 'Gerencia', 'Exportadora', '', '28889999', 'Puerto Comercial #10', 'juridico'),
    ----------- MAS CN
    ('Juan', 'Carlos', 'Ramírez', 'Sánchez', '71112224', 'Colonia San Miguel #23', 'natural'),
    ('María', 'Elena', 'Gómez', 'Herrera', '52223335', 'Residencial Las Palmas #12', 'natural'),
    ('Pedro', 'Antonio', 'Luna', 'Vargas', '83334446', 'Barrio San Jacinto #45', 'natural'),
    ('Laura', 'Isabel', 'Castro', 'Rivas', '24445557', 'Avenida Las Américas #67', 'natural'),
    ('Fernando', '', 'Mendoza', 'Aguilar', '75556668', 'Colonia Montecarlo #89', 'natural'),
    ('Gabriela', 'Patricia', 'Ortega', 'Silva', '86667779', 'Residencial Los Almendros #34', 'natural'),
    ('Diego', 'Armando', 'Fuentes', 'Navarro', '57778880', 'Calle Los Pinos #56', 'natural'),
    ('Sara', 'Lucía', 'Reyes', 'Cordero', '28889991', 'Barrio El Carmen #78', 'natural'),
    ('José', 'Manuel', 'Delgado', 'Peña', '79990002', 'Colonia Las Acacias #90', 'natural'),
    ('Andrea', 'Carolina', 'Guerrero', 'Molina', '50001113', 'Residencial Los Laureles #123', 'natural'),
    ('Raúl', 'Esteban', 'Campos', 'Salazar', '21112224', 'Avenida Los Próceres #45', 'natural'),
    ('Daniela', 'Alejandra', 'Vega', 'Paz', '72223335', 'Colonia San Francisco #67', 'natural'),
    ('Oscar', 'René', 'Miranda', 'Rosales', '53334446', 'Barrio Santa Cecilia #89', 'natural'),
    ('Karla', 'Mariana', 'Valle', 'Mejía', '84445557', 'Residencial Las Colinas #12', 'natural'),
    ('Eduardo', 'José', 'Rivas', 'Zelaya', '25556668', 'Colonia Las Margaritas #34', 'natural'),
    ----------- MAS CJ
    ('Contacto', 'Finanzas', 'Corporación', 'Alimenticia', '21112223', 'Zona Industrial Sur #150', 'juridico'),
    ('Contacto', 'Recursos', 'Humanos', 'Consultores', '52223334', 'Edificio Corporativo #500', 'juridico'),
    ('Contacto', 'Tecnología', 'Soluciones', 'Digitales', '72334445', 'Parque Tecnológico #75', 'juridico'),
    ('Contacto', 'Marketing', 'Agencia', 'Creativa', '82445556', 'Centro de Negocios #220', 'juridico'),
    ('Contacto', 'Operaciones', 'Cadena', 'Logística', '52556667', 'Polígono Industrial Este #30', 'juridico'),
    ('Contacto', 'Desarrollo', 'Inmobiliaria', 'Urbana', '78667778', 'Boulevard Ejecutivo #400', 'juridico')

GO

-- Ahora obtenemos los IDs de los clientes jurídicos recién insertados
DECLARE @clienteJuridico1 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '23334444');
DECLARE @clienteJuridico2 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '24445555');
DECLARE @clienteJuridico3 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '25556666');
DECLARE @clienteJuridico4 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '26667777');
DECLARE @clienteJuridico5 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '27778888');
DECLARE @clienteJuridico6 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '28889999');

-- Obtener los IDs de los nuevos clientes jurídicos
DECLARE @clienteJuridico7 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '21112223');
DECLARE @clienteJuridico8 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '52223334');
DECLARE @clienteJuridico9 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '72334445');
DECLARE @clienteJuridico10 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '82445556');
DECLARE @clienteJuridico11 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '52556667');
DECLARE @clienteJuridico12 INT = (SELECT CodCliente
FROM Cliente
WHERE Telefono = '78667778');

-- Finalmente insertamos en ClienteJuridico con las referencias correctas
INSERT INTO ClienteJuridico
    (RUC, NombreEmpresa, CodCliente, CargoContacto, EmailEmpresa)
VALUES
    ('J0310000112410', 'Supermercados La Económica S.A.', @clienteJuridico1, 'Gerente de Compras', 'compras@laeconomica.com'),
    ('J0310000223521', 'Distribuidora Comercial S.A.', @clienteJuridico2, 'Jefe de Ventas', 'ventas@distribuidoracomercial.com'),
    ('J0310000334632', 'Industrias Pesadas de Centroamérica', @clienteJuridico3, 'Director de Logística', 'logistica@indpesadas.com'),
    ('J0310000445743', 'Comercializadora Internacional', @clienteJuridico4, 'Coordinador de Compras', 'compras@comercializadoraint.com'),
    ('J0310000556854', 'Mayorista del Pacífico', @clienteJuridico5, 'Gerente General', 'gerencia@mayoristapac.com'),
    ('J0310000667965', 'Exportadora Continental', @clienteJuridico6, 'Director Ejecutivo', 'admin@exportadoracontinental.com'),
    ---------------- MAS
    ('J0310000778076', 'Corporación Alimenticia Nacional', @clienteJuridico7, 'Director Financiero', 'finanzas@corpalimenticia.com'),
    ('J0310000889187', 'Consultores en RRHH Internacional', @clienteJuridico8, 'Gerente de Talento', 'rrhh@consultoresint.com'),
    ('J0310000990298', 'Soluciones Digitales Avanzadas', @clienteJuridico9, 'CTO', 'tecnologia@solucionesdigitales.com'),
    ('J0310000101309', 'Agencia Creativa Publicitaria', @clienteJuridico10, 'Director Creativo', 'info@agenciacreativa.com'),
    ('J0310000112411', 'Cadena Logística Integral', @clienteJuridico11, 'Director de Operaciones', 'operaciones@cadenalogistica.com'),
    ('J0310000123521', 'Inmobiliaria Urbana Premium', @clienteJuridico12, 'Gerente de Proyectos', 'desarrollo@inmobiliariaurbana.com');

GO

-- 20. Taller (20 registros corregidos)
INSERT INTO Taller
    (NombreTaller, DescripTaller, CodCliente) 
VALUES
    ('Reparación báscula industrial 1019', 'Falla en el sistema de carga, muestra pesos negativos', 100),
    ('Mantenimiento báscula comercial 1020', 'Problemas con la interfaz de usuario', 101),
    ('Reparación báscula de laboratorio 1021', 'Deriva en las mediciones a lo largo del día', 102),
    ('Calibración báscula de precisión 1022', 'Requiere certificación para uso farmacéutico', 103),
    ('Reparación báscula de plataforma 1023', 'Fisuras en la plataforma de pesaje', 104),
    ('Mantenimiento preventivo 1024', 'Revisión semestral del sistema', 105),
    ('Reparación báscula digital 1025', 'No enciende después de tormenta eléctrica', 106),
    ('Revisión báscula contadora 1026', 'Conteo incorrecto de piezas pequeñas', 107),
    ('Reparación báscula de cocina 1027', 'Botones responden intermitentemente', 108),
    ('Mantenimiento báscula industrial 1028', 'Ruido eléctrico en las mediciones', 109),
    ('Reparación báscula de ganado 1029', 'Corrosión en componentes por humedad', 110),
    ('Revisión báscula de almacén 1030', 'Problemas de comunicación con el sistema ERP', 111),
    ('Reparación báscula de farmacia 1031', 'No cumple con tolerancias para medicamentos', 112),
    ('Mantenimiento báscula de joyería 1032', 'Vibraciones afectan mediciones precisas', 113),
    ('Reparación báscula de camiones 1033', 'Error en pesaje dinámico de ejes', 114),
    ('Revisión báscula de supermercado 1034', 'Problemas con etiquetado automático', 125),
    ('Reparación báscula de taller 1035', 'Daño por impacto de herramienta pesada', 116),
    ('Mantenimiento báscula veterinaria 1036', 'Problemas con modo de peso animal', 117),
    ('Reparación báscula de cafetería 1037', 'Acumulación de residuos afecta medición', 118),
    ('Revisión báscula industrial pesada 1038', 'Desnivelación afecta mediciones', 119);

GO




GO



-- ==========================================
-- COMPRAS (10 registros corregidos)
-- ==========================================
INSERT INTO Compra (CodProv, TotalCompra, IdUser, Comentario, FechaRecepcion) VALUES
(100, 4000.00, (SELECT TOP 1 CodigoUser FROM Users), 'Compra inicial de básculas industriales', SYSDATETIMEOFFSET()),
(101, 2500.00, (SELECT TOP 1 CodigoUser FROM Users), 'Compra de básculas comerciales', SYSDATETIMEOFFSET()),
(102, 1200.00, (SELECT TOP 1 CodigoUser FROM Users), 'Compra de sensores 50kg', SYSDATETIMEOFFSET()),
(103, 900.00, (SELECT TOP 1 CodigoUser FROM Users), 'Compra de pantallas LCD', SYSDATETIMEOFFSET()),
(104, 2000.00, (SELECT TOP 1 CodigoUser FROM Users), 'Compra masiva de sensores', SYSDATETIMEOFFSET()),
(100, 3500.00, (SELECT TOP 1 CodigoUser FROM Users), 'Reabastecimiento de básculas industriales', SYSDATETIMEOFFSET()),
(101, 750.00, (SELECT TOP 1 CodigoUser FROM Users), 'Pantallas digitales de repuesto', SYSDATETIMEOFFSET()),
(102, 1800.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta mayorista de básculas comerciales', SYSDATETIMEOFFSET()),
(103, 2500.00, (SELECT TOP 1 CodigoUser FROM Users), 'Compra de sensores de precisión', SYSDATETIMEOFFSET()),
(104, 6000.00, (SELECT TOP 1 CodigoUser FROM Users), 'Compra especial de básculas industriales', SYSDATETIMEOFFSET());

GO

-- ==========================================
-- DETALLE DE COMPRA (10 registros corregidos)
-- ==========================================
INSERT INTO DetalleCompra (CodCompra, CodAlmacen, CodProd, Cantidad, PrecioUnitario) VALUES
(100, 100, 100, 20, 200.00),
(101, 100, 101, 50, 50.00),
(102, 100, 102, 80, 15.00),
(103, 100, 103, 30, 30.00),
(104, 100, 104, 120, 16.50),
(105, 100, 105, 18, 195.00),
(106, 100, 106, 25, 30.00),
(107, 100, 107, 40, 45.00),
(108, 100, 108, 150, 16.70),
(109, 100, 109, 28, 215.00);

GO

-- ==========================================
-- PAGOS (10 registros)
-- ==========================================
INSERT INTO Pago (CodMetodoPago, MontoPago, IdUser) VALUES
(1, 4000.00, (SELECT TOP 1 CodigoUser FROM Users)),
(2, 2500.00, (SELECT TOP 1 CodigoUser FROM Users)),
(3, 1200.00, (SELECT TOP 1 CodigoUser FROM Users)),
(1, 900.00, (SELECT TOP 1 CodigoUser FROM Users)),
(2, 2000.00, (SELECT TOP 1 CodigoUser FROM Users)),
(3, 3500.00, (SELECT TOP 1 CodigoUser FROM Users)),
(1, 750.00, (SELECT TOP 1 CodigoUser FROM Users)),
(2, 1800.00, (SELECT TOP 1 CodigoUser FROM Users)),
(3, 2500.00, (SELECT TOP 1 CodigoUser FROM Users)),
(1, 6000.00, (SELECT TOP 1 CodigoUser FROM Users));

GO

-- ==========================================
-- PAGO-COMPRA (10 registros corregidos)
-- ==========================================
INSERT INTO PagoCompra (CodPago, CodCompra) VALUES
(1, 100),
(2, 101),
(3, 102),
(4, 103),
(5, 104),
(6, 105),
(7, 106),
(8, 107),
(9, 108),
(10, 109);

GO

-- ==========================================
-- VENTAS (10 registros)
-- ==========================================
INSERT INTO Venta (CodCliente, TotalVenta, IdUser, Comentario) VALUES
(100, 700.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta de báscula industrial'),
(101, 120.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta de báscula comercial'),
(100, 80.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta de sensor de carga'),
(101, 60.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta de pantalla LCD'),
(100, 350.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta especial de báscula industrial'),
(101, 240.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta de dos básculas comerciales'),
(100, 100.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta de calibración incluida'),
(101, 500.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta a empresa de sensores'),
(100, 900.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta de lote de básculas'),
(101, 150.00, (SELECT TOP 1 CodigoUser FROM Users), 'Venta de servicio de reparación');

GO

-- ==========================================
-- DETALLE DE VENTA (10 registros)
-- ==========================================
INSERT INTO DetalleVenta (CodVenta, CodAlmacen, CodProd, Cantidad, PrecioUnitario) VALUES
(100, 100, 100, 2, 350.00),
(101, 100, 101, 1, 120.00),
(102, 100, 102, 2, 40.00),
(103, 100, 103, 2, 30.00),
(104, 100, 100, 1, 350.00),
(105, 100, 101, 2, 120.00),
(106, 100, 102, 5, 20.00),
(107, 100, 102, 10, 50.00),
(108, 100, 100, 3, 300.00),
(109, 100, 103, 5, 30.00);

GO

-- ==========================================
-- GARANTÍAS (10 registros)
-- ==========================================
INSERT INTO GarantiaDetalle (CodDetVenta, PlazoMeses) VALUES
(100, 12),
(101, 6),
(102, 3),
(103, 3),
(104, 12),
(105, 6),
(106, 3),
(107, 6),
(108, 12),
(109, 6);

GO

-- ==========================================
-- PAGO-VENTA (10 registros)
-- ==========================================
INSERT INTO PagoVenta (CodPago, CodVenta) VALUES
(1, 100),
(2, 101),
(3, 102),
(4, 103),
(5, 104),
(6, 105),
(7, 106),
(8, 107),
(9, 108),
(10, 109);

GO

-- ==========================================
-- MOVIMIENTOS DE INVENTARIO (10 registros)
-- ==========================================
INSERT INTO MovimientosInventario (CodProd, Cantidad, TipoMovimiento, IdUser, AlmacenID, Comentario) VALUES
(100, 20, 'Entrada', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Ingreso por compra'),
(101, 50, 'Entrada', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Ingreso por compra'),
(102, 100, 'Entrada', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Ingreso por compra'),
(103, 30, 'Entrada', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Ingreso por compra'),
(100, 2, 'Salida', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Venta realizada'),
(101, 1, 'Salida', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Venta realizada'),
(102, 5, 'Salida', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Venta realizada'),
(103, 3, 'Salida', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Venta realizada'),
(100, 1, 'Ajuste', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Ajuste de inventario'),
(102, 2, 'Ajuste', (SELECT TOP 1 CodigoUser FROM Users), 100, 'Revisión de stock');

GO

-- ==========================================
-- HISTORIAL DE PRECIOS (10 registros)
-- ==========================================
INSERT INTO HistorialPrecioProducto (CodProd, PrecioUnitario, PrecioVenta, Observacion) VALUES
(100, 200.00, 350.00, 'Precio inicial'),
(101, 50.00, 120.00, 'Precio inicial'),
(102, 15.00, 35.00, 'Precio inicial'),
(103, 25.00, 60.00, 'Precio inicial'),
(100, 210.00, 360.00, 'Ajuste por inflación'),
(101, 55.00, 125.00, 'Nuevo precio'),
(102, 18.00, 40.00, 'Ajuste'),
(103, 28.00, 65.00, 'Ajuste'),
(100, 220.00, 370.00, 'Promoción especial'),
(101, 60.00, 130.00, 'Incremento por demanda');

GO

-- ==========================================
-- HISTORIAL DE COMPRAS (10 registros)
-- ==========================================
INSERT INTO HistorialCompra (CodCompra, CodProvAnterior, CodProvNuevo, TotalCompraAnterior, TotalCompraNuevo, UsuarioModifico, Observacion) VALUES
(100, NULL, 100, NULL, 4000.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(101, NULL, 100, NULL, 2500.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(102, NULL, 100, NULL, 1200.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(103, NULL, 101, NULL, 900.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(104, NULL, 101, NULL, 2000.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(105, NULL, 100, NULL, 3500.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(106, NULL, 101, NULL, 750.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(107, NULL, 100, NULL, 1800.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(108, NULL, 101, NULL, 2500.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial'),
(109, NULL, 100, NULL, 6000.00, (SELECT TOP 1 CodigoUser FROM Users), 'Registro inicial');

GO