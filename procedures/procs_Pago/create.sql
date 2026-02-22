USE Bascula
GO

CREATE PROCEDURE ProcCreatePago
@CodMetodoPago INT,
@MontoPago DECIMAL(18,4),
@IdUser UNIQUEIDENTIFIER,
@EstadoPago NVARCHAR(15),
@Mensaje NVARCHAR(100) OUTPUT,
@CodPago INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		
		IF @MontoPago IS NULL OR @CodMetodoPago IS NULL OR @IdUser IS NULL OR @EstadoPago IS NULL OR TRIM(@EstadoPago) = ''
		BEGIN
			SET @Mensaje = 'ERROR: Monto, método, estado de pago y usuario son campos obligatorios.';
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

		DECLARE @exist_User BIT = (SELECT EstadoUser FROM Users WITH (UPDLOCK, ROWLOCK)
							       WHERE CodigoUser = @IdUser);

		IF @exist_User IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: ID de Usuario "'+ TRY_CONVERT(varchar(36),@IdUser) +'" no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_User = 0
		BEGIN
			SET @Mensaje = 'ERROR: El usuario del ID "'+ TRY_CONVERT(varchar(36),@IdUser) +'" está inactivo.';
			RETURN;
		END

		DECLARE @exist_Met BIT = (SELECT EstadoMetodo FROM MetodoPago WITH (UPDLOCK, ROWLOCK)
							       WHERE CodMetodoPago = @CodMetodoPago);

		IF @exist_Met IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Código de Método de pago ('+ TRY_CONVERT(nvarchar(10),@CodMetodoPago) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Met = 0
		BEGIN
			SET @Mensaje = 'ERROR: El método de pago del código ('+ TRY_CONVERT(nvarchar(10),@CodMetodoPago) +') está inactivo.';
			RETURN;
		END

		INSERT INTO Pago (CodMetodoPago, MontoPago, EstadoPago, IdUser)
		VALUES (@CodMetodoPago, @MontoPago, LOWER(TRIM(@EstadoPago)), @IdUser);
		
		-- Obtener el ID recién creado
		SET @CodPago = SCOPE_IDENTITY();

		SET @Mensaje = 'Pago registrado correctamente.';
	END TRY
	BEGIN CATCH
		SET @Mensaje = 'Error al registrar el pago: ' + ERROR_MESSAGE();
	END CATCH
END