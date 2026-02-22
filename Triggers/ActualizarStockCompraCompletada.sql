USE Bascula
GO

CREATE TRIGGER trg_ActualizarStock_Compra_Completada
-- Este es cuando se usa el ProcCompleteCompra, en vez de marcar como completada al registrar
ON Compra
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @CodProd INT, @Cantidad INT, @CodAlmacen INT, @IdUser UNIQUEIDENTIFIER, @CodCompra INT, @Mensaje NVARCHAR(100);
	
	DECLARE stock_cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT dc.CodProd, dc.Cantidad, dc.CodAlmacen, i.IdUser, i.CodCompra
		FROM INSERTED AS i
		INNER JOIN DELETED AS d ON i.CodCompra = d.CodCompra
		INNER JOIN DetalleCompra AS dc ON dc.CodCompra = i.CodCompra
		WHERE i.EstadoCompra = 'completada';
	
	OPEN stock_cursor;
	FETCH NEXT FROM stock_cursor INTO @CodProd, @Cantidad, @CodAlmacen, @IdUser, @CodCompra;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- Stock de Producto
		UPDATE Producto SET
				Stock = Stock + @Cantidad,
				DateUpdate = SYSDATETIMEOFFSET() 
		WHERE CodProd = @CodProd;
		
		-- Auditoría
		INSERT INTO MovimientosInventario (CodProd, Cantidad, TipoMovimiento, IdUser, AlmacenID, Comentario)
		VALUES (@CodProd, @Cantidad, 'Entrada', @IdUser, @CodAlmacen, CONCAT('Entrada por completar compra #', @CodCompra));
		
		FETCH NEXT FROM stock_cursor INTO @CodProd, @Cantidad, @CodAlmacen, @IdUser, @CodCompra;
	END
	
	CLOSE stock_cursor;
	DEALLOCATE stock_cursor;
END;