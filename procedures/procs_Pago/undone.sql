USE Bascula
GO

CREATE PROCEDURE ProcUndonePago --Delete/Anular
@CodPago INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodPago IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código del pago.';
			RETURN;
		END

		BEGIN TRANSACTION;

		DECLARE @exist_Pago NVARCHAR(15) = (SELECT EstadoPago FROM Pago WITH (UPDLOCK, ROWLOCK)
										WHERE CodPago = @CodPago);

		IF @exist_Pago IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: No se encontró el pago del código ('+ TRY_CONVERT(nvarchar(10),@CodPago) +') en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Pago = 'anulado'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El pago del código ('+ TRY_CONVERT(nvarchar(10),@CodPago) +') ya está anulado.';
			RETURN;
		END

		IF @exist_Pago = 'aplicado'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El pago del código ('+ TRY_CONVERT(nvarchar(10),@CodPago) +') ya se ha marcado como "aplicado", no se puede anular.';
			RETURN;
		END

		UPDATE Pago
		SET EstadoPago = 'anulado',
			DateDelete = SYSDATETIMEOFFSET()
		WHERE CodPago = @CodPago;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al anular el pago.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Pago anulado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al anular el pago: ' + ERROR_MESSAGE();
	END CATCH
END