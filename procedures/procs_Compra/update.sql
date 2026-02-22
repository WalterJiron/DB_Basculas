USE Bascula
GO

CREATE PROCEDURE ProcUpdateCompra
@CodCompra INT,
@CodProv INT,
@TotalCompra DECIMAL(18,4),
@IdUser UNIQUEIDENTIFIER,
@Comentario NVARCHAR(300),
@EstadoCompra NVARCHAR(15),
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF @CodCompra IS NULL OR @TotalCompra IS NULL OR @IdUser IS NULL OR @EstadoCompra IS NULL OR TRIM(@EstadoCompra) = ''
		BEGIN
			SET @Mensaje = 'ERROR: El código de compra, usuario, total y estado de compra son campos obligatorios.';
			RETURN;
		END

		IF TRIM(@EstadoCompra) NOT IN ('registrada', 'completada', 'cancelada')
		BEGIN
			SET @Mensaje = 'ERROR: Estado ingresado inválido. Tiene que ser "registrada", "completada" ó "cancelada".';
			RETURN;
		END

		IF LEN(TRIM(@Comentario)) > 300
		BEGIN
			SET @Mensaje = 'ERROR: El comentario no puede exceder los 300 caracteres.';
			RETURN;
		END
		
		IF @TotalCompra < 0
		BEGIN
			SET @Mensaje = 'ERROR: El total de compra no pueden ser menor que 0.';
			RETURN;
		END

	  /*IF CONVERT(VARCHAR(36), @IdUser) NOT LIKE
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]-' +
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]-' +
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]-' +
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]-' +
			'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
		BEGIN
			SET @Mensaje = 'ERROR: El usuario es inválido. Tiene que seguir el formato "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX".';
			RETURN;
		END*/

		BEGIN TRANSACTION;

		DECLARE @exist_Compra NVARCHAR(15) = (SELECT EstadoCompra FROM Compra WITH (UPDLOCK, ROWLOCK)
							       WHERE CodCompra = @CodCompra);

		IF @exist_Compra IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Compra ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') no encontrada en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Compra = 'cancelada' AND @EstadoCompra NOT LIKE 'registrada'
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La compra del código ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') fue cancelada, no se puede actualizar a menos que se reactive marcándola como "registrada".';
			RETURN;
		END

		DECLARE @exist_Prov BIT = (SELECT EstadoProv FROM Proveedor WITH (UPDLOCK, ROWLOCK)
							       WHERE CodProv = @CodProv);

		IF @exist_Prov IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Proveedor ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Prov = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El proveedor del código ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') se encuentra inactivo.';
			RETURN;
		END
		----------------------------------------------------------------------------------------

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
			SET @Mensaje = 'ERROR: El usuario del ID "'+ TRY_CONVERT(varchar(36),@IdUser) +'" se encuentra inactivo.';
			RETURN;
		END
		
		UPDATE Compra
		SET CodProv = @CodProv,
			TotalCompra = @TotalCompra,
			IdUser = @IdUser,
			Comentario = (TRIM(@Comentario)),
			EstadoCompra = (lower(TRIM(@EstadoCompra))),
			FechaRecepcion = SYSDATETIMEOFFSET()
		WHERE CodCompra = @CodCompra;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar la compra.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Compra actualizada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al actualizar la compra: ' + ERROR_MESSAGE();
	END CATCH
END