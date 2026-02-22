USE Bascula
GO

CREATE VIEW VistaPagosPorCompra AS
SELECT 
    PC.CodCompra,
    P.CodPago,
    P.MontoPago,
    P.FechaPago,
    P.EstadoPago,
    C.TotalCompra,
    PR.NombreProv AS Proveedor,
    MP.NombreMetodo AS MetodoPago
FROM PagoCompra PC
INNER JOIN Pago P ON PC.CodPago = P.CodPago
INNER JOIN Compra C ON PC.CodCompra = C.CodCompra
INNER JOIN Proveedor PR ON C.CodProv = PR.CodProv
LEFT JOIN MetodoPago MP ON P.CodMetodoPago = MP.CodMetodoPago;
