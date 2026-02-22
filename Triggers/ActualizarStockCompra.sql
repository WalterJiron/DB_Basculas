USE Bascula
GO

CREATE TRIGGER trg_ActualizarStock_Compra
-- Este es cuando al registrar la compra también la marcan como completada
ON DetalleCompra
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @CodProd INT, @Cantidad INT, @CodAlmacen INT, @IdUser UNIQUEIDENTIFIER, @CodCompra INT, @Mensaje NVARCHAR(100);
	
	/*	Cursor sobre los datos relevantes (solo compras completadas)
		FAST_FORWARD:	Optimiza el cursor para recorrido rápido y sin escritura.
		LOCAL:			Limita el cursor solo al trigger. Mejora seguridad y evita fugas.	*/
	DECLARE stock_cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT i.CodProd, i.Cantidad, i.CodAlmacen,	c.IdUser, i.CodCompra
		FROM INSERTED as i
		INNER JOIN Compra as c ON c.CodCompra = i.CodCompra
		WHERE c.EstadoCompra = 'completada';
	
	OPEN stock_cursor;
	FETCH NEXT FROM stock_cursor INTO @CodProd, @Cantidad, @CodAlmacen, @IdUser, @CodCompra;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Stock de Producto
		/*EXEC ProcUpdateStockProducto @CodProd, @Cantidad, '+', @Mensaje OUTPUT;*/		
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