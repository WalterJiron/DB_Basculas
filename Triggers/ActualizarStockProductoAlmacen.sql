USE Bascula
GO

CREATE TRIGGER trg_ActualizarStock_ProductoAlmacen
ON Producto
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	
	IF UPDATE(Stock)
	BEGIN
		UPDATE ProductoAlmacen
		SET StockActual = p.Stock,
			DateUpdate = SYSDATETIMEOFFSET()
		FROM ProductoAlmacen as pa
		INNER JOIN INSERTED as p ON pa.CodProd = p.CodProd;
	END
END;