USE Bascula
GO

CREATE VIEW VistaHistorialVentas AS
SELECT 
    V.CodVenta,
    C.PNCL + ' ' + C.PACL AS NombreCliente,
    U.NameUser AS Usuario,
    V.TotalVenta,
    V.FechaVenta,
    V.EstadoVenta
FROM Venta V
INNER JOIN Cliente C ON V.CodCliente = C.CodCliente
INNER JOIN Users U ON V.IdUser = U.CodigoUser;
