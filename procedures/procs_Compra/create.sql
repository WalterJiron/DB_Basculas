USE Bascula
GO

CREATE PROCEDURE ProcCreateCompra
@CodProv INT,
@TotalCompra DECIMAL(18,4),
@IdUser UNIQUEIDENTIFIER,
@Comentario NVARCHAR(300),
/* Era poner (límite + 1) ó (MAX), sino los casos de exceso de caracteres no salían,
	porque si pongo (300) el proc automaticamente solo agarra los primeros 300 e ignora el resto*/
@EstadoCompra NVARCHAR(15),
@Mensaje NVARCHAR(100) OUTPUT,
-- Lo mismo acá pero con SET @Mensaje = '' + ERROR_MESSAGE();
@CodCompra INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF @TotalCompra IS NULL OR @IdUser IS NULL OR @EstadoCompra IS NULL OR TRIM(@EstadoCompra) = ''
		BEGIN
			SET @Mensaje = 'ERROR: El usuario, total y estado de la compra son campos obligatorios.';
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
			SET @Mensaje = 'ERROR: El total de compra no puede ser menor que 0.';
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

		DECLARE @exist_Prov BIT = (SELECT EstadoProv FROM Proveedor WITH (UPDLOCK, ROWLOCK)
							       WHERE CodProv = @CodProv);
		IF @exist_Prov IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Código de Proveedor ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Prov = 0
		BEGIN
			SET @Mensaje = 'ERROR: El proveedor del código ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') se encuentra inactivo.';
			RETURN;
		END
		----------------------------------------------------------------------------------------

		DECLARE @exist_User BIT = (SELECT EstadoUser FROM Users WITH (UPDLOCK, ROWLOCK)
							       WHERE CodigoUser = @IdUser);

		IF @exist_User IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: ID de Usuario "'+ TRY_CONVERT(varchar(36),@IdUser) +'" no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_User = 0
		BEGIN
			SET @Mensaje = 'ERROR: El usuario con el ID "'+ TRY_CONVERT(varchar(36),@IdUser) +'" está inactivo.';
			RETURN;
		END
		
		INSERT INTO Compra(CodProv, TotalCompra, IdUser, Comentario, EstadoCompra)
		VALUES (@CodProv, @TotalCompra, @IdUser, (TRIM(@Comentario)), (lower(TRIM(@EstadoCompra))));

		-- Obtenemos el codigo del producto
	  /*SELECT @CodCompra = CodCompra
		FROM Compra
		WHERE CodCompra = IDENT_CURRENT('Compra');*/
		
		SELECT @CodCompra = SCOPE_IDENTITY();

		SET @Mensaje = 'Compra registrada correctamente.';

	END TRY
	BEGIN CATCH
		SET @Mensaje = 'Error al registrar la compra: ' + ERROR_MESSAGE();
	END CATCH
END