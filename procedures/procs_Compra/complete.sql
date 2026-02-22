USE Bascula
GO

CREATE PROC ProcCompleteCompra --Completar
@CodCompra INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodCompra IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código de compra.';
			RETURN;
		END
		
		BEGIN TRANSACTION;
		
		DECLARE @exist_Compra NVARCHAR(15) = (SELECT EstadoCompra FROM Compra WITH (UPDLOCK, ROWLOCK)
											  WHERE CodCompra = @CodCompra);

		IF @exist_Compra IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Compra ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') no encontrada en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Compra = 'completada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') ya se ha marcado como completada.';
			RETURN;
		END

		IF @exist_Compra = 'cancelada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') ya se ha marcado como cancelada, no se puede completar.';
			RETURN;
		END

		/*Puse un Update en DetalleCompra en vez del cursor que llama su ProcRestore,
		para que la compra sea posible marcarla como completada, ya que si
		Estado de Compra es "registrada" el DetalleCompra estará activo,
		entoces marcará redundancia el ProcRestoreDetCompra al pasar de registrado a completado,
		ya que ambas ponen detalle activo*/
		
		UPDATE DetalleCompra
		SET EstadoDetCompra = 1,
			DateDelete = NULL
		WHERE CodCompra = @CodCompra;

		UPDATE Compra
		SET EstadoCompra = 'completada',
			FechaRecepcion = SYSDATETIMEOFFSET()
		WHERE CodCompra = @CodCompra;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al marcar como completada la compra.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Compra marcada como completada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al marcar como completada la compra: ' + ERROR_MESSAGE();
	END CATCH
END