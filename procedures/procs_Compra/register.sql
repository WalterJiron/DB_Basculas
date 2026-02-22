USE Bascula
GO

CREATE PROC ProcRegisterCompra --Restore/Registrar, como una especie de estado "neutro"
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

		IF @exist_Compra = 'registrada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') ya se ha marcado como registrada.';
			RETURN;
		END

		-- Ejecutar el Restore de detalle
		DECLARE @CodDetCompraTR INT, @CodCompraTR INT, @MensajeDet NVARCHAR(100);
		SET @CodDetCompraTR = (SELECT CodDetCompra FROM DetalleCompra WITH (UPDLOCK, ROWLOCK)
							   WHERE CodCompra = @CodCompra);
		SET @CodCompraTR = @CodCompra;

		EXEC ProcRestoreDetalleCompra
			@CodDetCompra = @CodDetCompraTR,
			@CodCompra = @CodCompraTR,
			@Mensaje = @MensajeDet OUTPUT;
			
		IF @MensajeDet NOT LIKE '%correctamente%'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error al reactivar el detalle de la compra: ' + @MensajeDet;
			RETURN;
		END

		UPDATE Compra
		SET EstadoCompra = 'registrada',
			FechaRecepcion = NULL
		WHERE CodCompra = @CodCompra;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al marcar como registrada la compra.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Compra marcada como registrada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al marcar como registrada la compra: ' + ERROR_MESSAGE();
	END CATCH
END