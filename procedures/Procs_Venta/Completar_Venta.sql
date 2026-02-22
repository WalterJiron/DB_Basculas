USE Bascula
GO

CREATE PROC ProcCompleteVenta --Completar
@CodVenta INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodVenta IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código de venta.';
			RETURN;
		END
		
		BEGIN TRANSACTION;
		
		DECLARE @exist_Venta NVARCHAR(15) = (SELECT EstadoVenta FROM Venta WITH (UPDLOCK, ROWLOCK)
											  WHERE CodVenta = @CodVenta);

		IF @exist_Venta IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de venta ('+ TRY_CONVERT(nvarchar(10),@CodVenta) +') no encontrada en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Venta = 'completada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodVenta) +') ya se ha marcado como completada.';
			RETURN;
		END

		IF @exist_Venta = 'cancelada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodVenta) +') ya se ha marcado como cancelada, no se puede completar.';
			RETURN;
		END

		/*Puse un Update en DetalleCompra en vez del cursor que llama su ProcRestore,
		para que la compra sea posible marcarla como completada, ya que si
		Estado de Compra es "registrada" el DetalleCompra estará activo,
		entoces marcará redundancia el ProcRestoreDetCompra al pasar de registrado a completado,
		ya que ambas ponen detalle activo*/

		-- PENDIENTE VERIFICAR QUE SEA IGUAL EN VENTA --

		
		UPDATE DetalleVenta
		SET EstadoDetVenta = 1,
			DateDelete = NULL
		WHERE CodVenta = @CodVenta;

		UPDATE Venta
		SET EstadoVenta = 'completada',
			FechaVenta = SYSDATETIMEOFFSET()
		WHERE CodVenta = @CodVenta;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al marcar como completada la venta.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Venta marcada como completada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al marcar como completada la venta: ' + ERROR_MESSAGE();
	END CATCH
END