USE Bascula
GO

CREATE PROCEDURE ProcCreatePagoCompra
@CodPago INT,
@CodCompra INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodPago IS NULL OR @CodCompra IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Los códigos de pago y de compra son obligatorios.';
			RETURN;
		END

		DECLARE @exist_Pago NVARCHAR(15) = (SELECT EstadoPago FROM Pago WITH (UPDLOCK, ROWLOCK)
										WHERE CodPago = @CodPago);

		IF @exist_Pago IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: No se encontró el código de pago ('+ TRY_CONVERT(nvarchar(10),@CodPago) +') en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Pago = 'anulado'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El pago del código ('+ TRY_CONVERT(nvarchar(10),@CodPago) +') ya fue anulado, no puede aplicarse.';
			RETURN;
		END

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
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') ya se ha marcado como cancelada, no se puede completar.';
			RETURN;
		END

		-- Verificar que no exista duplicado
		IF EXISTS (SELECT 1 FROM PagoCompra WITH (UPDLOCK, ROWLOCK)
				   WHERE CodPago = @CodPago AND CodCompra = @CodCompra)
		BEGIN
			SET @Mensaje = 'ERROR: La relación pago cód.('+ TRY_CONVERT(nvarchar(10),@CodPago) +') - compra cód.('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') ya existe.';
			RETURN;
		END

		INSERT INTO PagoCompra (CodPago, CodCompra)
		VALUES (@CodPago, @CodCompra);

		SET @Mensaje = 'Relación pago-compra registrada correctamente.';
	END TRY
	BEGIN CATCH
		SET @Mensaje = 'Error al registrar la relación pago-compra: ' + ERROR_MESSAGE();
	END CATCH
END
GO