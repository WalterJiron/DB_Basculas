USE Bascula
GO

CREATE VIEW VistaPagosPorVenta AS
SELECT 
    PV.CodVenta,
    P.CodPago,
    P.MontoPago,
    P.FechaPago,
    P.EstadoPago,
    V.TotalVenta,
    C.PNCL + ' ' + C.PACL AS NombreCliente,
    MP.NombreMetodo AS MetodoPago
FROM PagoVenta PV
INNER JOIN Pago P ON PV.CodPago = P.CodPago
INNER JOIN Venta V ON PV.CodVenta = V.CodVenta
INNER JOIN Cliente C ON V.CodCliente = C.CodCliente
LEFT JOIN MetodoPago MP ON P.CodMetodoPago = MP.CodMetodoPago;
