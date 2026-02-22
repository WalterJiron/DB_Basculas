USE Bascula
GO

CREATE TRIGGER trg_HistorialPrecioProducto
ON DetalleProducto
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	
	INSERT INTO HistorialPrecioProducto (CodProd, PrecioUnitario, PrecioVenta, Observacion)
	SELECT i.CodProd, i.PrecioUnitario, i.PrecioVenta, 'Actualización de precio'
	FROM
		INSERTED as i INNER JOIN DELETED as d ON i.CodDetProd = d.CodDetProd
    WHERE
		i.PrecioUnitario <> d.PrecioUnitario OR i.PrecioVenta <> d.PrecioVenta;
END;