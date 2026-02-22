USE Bascula
GO

CREATE PROCEDURE ProcUpdatePago
@CodPago INT,
@CodMetodoPago INT,
@MontoPago DECIMAL(18,4),
@IdUser UNIQUEIDENTIFIER,
@EstadoPago NVARCHAR(15),
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		
		IF @CodPago IS NULL OR @CodMetodoPago IS NULL OR @MontoPago IS NULL OR @IdUser IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: El código, monto, método de pago y usuario son campos obligatorios.';
			RETURN;
		END

		IF @MontoPago <= 0
		BEGIN
			SET @Mensaje = 'ERROR: El monto de pago tiene que ser mayor a 0.';
			RETURN;
		END

		IF TRIM(@EstadoPago) NOT IN ('pendiente', 'aplicado', 'anulado')
		BEGIN
			SET @Mensaje = 'ERROR: Estado ingresado inválido. Tiene que ser "pendiente", "aplicado" ó "anulado".';
			RETURN;
		END

	  /*IF CONVERT(VARCHAR(36), @IdUser) NOT LIKE
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]-' +
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]-' +
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]-' +
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]-' +
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
		BEGIN
			SET @Mensaje = 'ERROR: El usuario tiene un formato inválido. Tiene que seguir el formato "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX".';
			RETURN;
		END*/

		BEGIN TRANSACTION;

		DECLARE @exist_Pago NVARCHAR(15) = (SELECT EstadoPago FROM Pago WITH (UPDLOCK, ROWLOCK)
							       WHERE CodPago = @CodPago);

		IF @exist_Pago IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Pago ('+ TRY_CONVERT(nvarchar(10),@CodPago) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Pago = 'anulado' AND @EstadoPago != 'pendiente'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El pago del código ('+ TRY_CONVERT(nvarchar(10),@CodPago) +') fue anulado, no se puede actualizar a menos que se reactive marcándola como "pendiente".';
			RETURN;
		END
		
		DECLARE @exist_User BIT = (SELECT EstadoUser FROM Users WITH (UPDLOCK, ROWLOCK)
							       WHERE CodigoUser = @IdUser);

		IF @exist_User IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: ID de Usuario "'+ TRY_CONVERT(varchar(36),@IdUser) +'" no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_User = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El usuario del ID "'+ TRY_CONVERT(varchar(36),@IdUser) +'" está inactivo.';
			RETURN;
		END

		DECLARE @exist_Met BIT = (SELECT EstadoMetodo FROM MetodoPago WITH (UPDLOCK, ROWLOCK)
							       WHERE CodMetodoPago = @CodMetodoPago);

		IF @exist_Met IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Método de pago ('+ TRY_CONVERT(nvarchar(10),@CodMetodoPago) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Met = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El método de pago del código ('+ TRY_CONVERT(nvarchar(10),@CodMetodoPago) +') está inactivo.';
			RETURN;
		END

		UPDATE Pago
		SET CodMetodoPago = @CodMetodoPago,
			MontoPago = @MontoPago,
			EstadoPago = LOWER(TRIM(@EstadoPago)),
			IdUser = @IdUser,
			FechaPago = SYSDATETIMEOFFSET()
		WHERE CodPago = @CodPago;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar el pago.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Pago actualizado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al actualizar el pago: ' + ERROR_MESSAGE();
	END CATCH
END