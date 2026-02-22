USE Bascula
GO

CREATE PROC ProcCancelCompra --Delete/Cancelar
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

		IF @exist_Compra = 'cancelada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') ya se ha marcado como cancelada.';
			RETURN;
		END

		IF @exist_Compra = 'completada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') ya se ha marcado como completada, no se puede cancelar.';
			RETURN;
		END

		-- Ejecutar el Delete de detalle
		DECLARE @CodDetCompraTR INT, @CodCompraTR INT, @MensajeDet NVARCHAR(100);
		SET @CodDetCompraTR = (SELECT CodDetCompra FROM DetalleCompra WITH (UPDLOCK, ROWLOCK)
							   WHERE CodCompra = @CodCompra);
		SET @CodCompraTR = @CodCompra;

		EXEC ProcDeleteDetalleCompra
			@CodDetCompra = @CodDetCompraTR,
			@CodCompra = @CodCompraTR,
			@Mensaje = @MensajeDet OUTPUT;
			
		IF @MensajeDet NOT LIKE '%correctamente%'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error al desactivar el detalle de la compra: ' + @MensajeDet;
			RETURN;
		END

		UPDATE Compra
		SET EstadoCompra = 'cancelada',
			FechaRecepcion = NULL
		WHERE CodCompra = @CodCompra;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al marcar como cancelada la compra.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Compra marcada como cancelada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al marcar como cancelada la compra: ' + ERROR_MESSAGE();
	END CATCH
END