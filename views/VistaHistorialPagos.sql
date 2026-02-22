USE Bascula
GO

CREATE VIEW VistaHistorialPagos AS
SELECT 
    P.CodPago,
    MP.NombreMetodo AS MetodoPago,
    P.MontoPago,
    P.FechaPago,
    P.EstadoPago,
    U.NameUser AS Usuario
FROM Pago P
LEFT JOIN MetodoPago MP ON P.CodMetodoPago = MP.CodMetodoPago
LEFT JOIN Users U ON P.IdUser = U.CodigoUser;
