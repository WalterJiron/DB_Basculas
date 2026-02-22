USE Bascula
GO

CREATE TRIGGER trg_ActualizarStock_Venta
-- Este es cuando al registrar la venta también la marcan como completada
ON DetalleVenta
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @CodProd INT, @Cantidad INT, @CodAlmacen INT, @IdUser UNIQUEIDENTIFIER,  @CodVenta INT, @Mensaje NVARCHAR(100);

	DECLARE stock_cursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT i.CodProd, i.Cantidad, i.CodAlmacen, v.IdUser
		FROM INSERTED AS i
		INNER JOIN Venta AS v ON v.CodVenta = i.CodVenta
		WHERE v.EstadoVenta = 'completada';
	
	OPEN stock_cursor;
	FETCH NEXT FROM cur INTO @CodProd, @Cantidad, @CodAlmacen, @IdUser, @CodVenta;
	
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
		
		FETCH NEXT FROM stock_cursor INTO @CodProd, @Cantidad, @CodAlmacen, @IdUser,  @CodVenta;
	END
	
	CLOSE stock_cursor;
	DEALLOCATE stock_cursor;
END;