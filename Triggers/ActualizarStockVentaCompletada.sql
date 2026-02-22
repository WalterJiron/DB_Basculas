USE Bascula
GO

CREATE TRIGGER trg_ActualizarStock_Venta_Completada
/*  Este es cuando se usa (sea el que sea) el Proc que Genaro hizo
	para marcar como completada la venta post-registro	*/
ON Venta
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @CodProd INT, @Cantidad INT, @CodAlmacen INT, @IdUser UNIQUEIDENTIFIER, @CodVenta INT, @Mensaje NVARCHAR(100);

	DECLARE stock_cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT dv.CodProd, dv.Cantidad, dv.CodAlmacen, i.IdUser, i.CodVenta
		FROM INSERTED AS i
		INNER JOIN DELETED AS d ON i.CodVenta = d.CodVenta
		INNER JOIN DetalleVenta AS dv ON dv.CodVenta = i.CodVenta
		WHERE i.EstadoVenta = 'Completada' AND d.EstadoVenta <> 'Completada';
	
	OPEN stock_cursor;
	FETCH NEXT FROM stock_cursor INTO @CodProd, @Cantidad, @CodAlmacen, @IdUser, @CodVenta;
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
        
		-- Stock de Producto
		UPDATE Producto SET
				Stock = Stock - @Cantidad,
				DateUpdate = SYSDATETIMEOFFSET()
		WHERE CodProd = @CodProd;

		-- Auditoría
		INSERT INTO MovimientosInventario (CodProd, Cantidad, TipoMovimiento, IdUser, AlmacenID, Comentario)
		VALUES (@CodProd, @Cantidad, 'Salida', @IdUser, @CodAlmacen, CONCAT('Salida por completar venta #', @CodVenta));
		
		FETCH NEXT FROM stock_cursor INTO @CodProd, @Cantidad, @CodAlmacen, @IdUser, @CodVenta;
	END
	
	CLOSE stock_cursor;
	DEALLOCATE stock_cursor;
END;