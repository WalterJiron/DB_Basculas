USE Bascula
GO

CREATE PROCEDURE ProcUpdatePagoCompra
@CodPago INT,
@CodCompra INT,
@NCodPago INT,
@NCodCompra INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodPago IS NULL OR @CodCompra IS NULL OR @NCodPago IS NULL OR @NCodCompra IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Todos los campos son obligatorios.';
			RETURN;
		END

		BEGIN TRANSACTION;

		-- Verificar existencia de la relación actual
		IF NOT EXISTS (SELECT 1 FROM PagoCompra WITH (UPDLOCK, ROWLOCK)
					   WHERE CodPago = @CodPago AND CodCompra = @CodCompra)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: No se encontró la relación actual de pago cód.('+ TRY_CONVERT(nvarchar(10),@CodPago) +') - compra cód.('+ TRY_CONVERT(nvarchar(10),@CodCompra) +').';
			RETURN;
		END

		-- Verificar los nuevos códigos
		DECLARE @exist_Pago NVARCHAR(15) = (SELECT EstadoPago FROM Pago WITH (UPDLOCK, ROWLOCK)
										WHERE CodPago = @NCodPago);

		IF @exist_Pago IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Nuevo código de pago ('+ TRY_CONVERT(nvarchar(10),@NCodPago) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Pago = 'anulado'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El nuevo código de pago ('+ TRY_CONVERT(nvarchar(10),@NCodPago) +') ya fue anulado, no puede aplicarse.';
			RETURN;
		END

		DECLARE @exist_Compra NVARCHAR(15) = (SELECT EstadoCompra FROM Compra WITH (UPDLOCK, ROWLOCK)
											  WHERE CodCompra = @NCodCompra);

		IF @exist_Compra IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Nuevo código de compra ('+ TRY_CONVERT(nvarchar(10),@NCodCompra) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Compra = 'cancelada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El nuevo código de compra ('+ TRY_CONVERT(nvarchar(10),@NCodCompra) +') ya se ha marcado como cancelada, no se puede completar.';
			RETURN;
		END

		-- Verificación de duplicado
		IF EXISTS (SELECT 1 FROM PagoCompra WITH (UPDLOCK, ROWLOCK)
				   WHERE CodPago = @NCodPago AND CodCompra = @NCodCompra)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La nueva relación pago cód.('+ TRY_CONVERT(nvarchar(10),@NCodPago) +') - compra cód.('+ TRY_CONVERT(nvarchar(10),@NCodCompra) +') ya existe.';
			RETURN;
		END

		UPDATE PagoCompra
		SET CodPago = @NCodPago,
			CodCompra = @NCodCompra
		WHERE CodPago = @CodPago AND CodCompra = @CodCompra;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar la relación pago-compra.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Relación pago-compra actualizada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al actualizar la relación pago-compra: ' + ERROR_MESSAGE();
	END CATCH
END
GO