USE Bascula
GO

CREATE PROC ProcUpdateServicio
@CodServ INT,
@NombreServ NVARCHAR(50), --50
@DescripServ NVARCHAR(MAX),
@Precio DECIMAL(18,4),
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodServ IS NULL OR @NombreServ IS NULL OR TRIM(@NombreServ) = '' OR @DescripServ IS NULL OR @Precio IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Todos los campos son obligatorios.';
			RETURN;
		END

		IF LEN(TRIM(@NombreServ)) < 3 OR LEN(TRIM(@NombreServ)) > 50
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del servicio debe tener entre 3 y 50 caracteres.';
			RETURN;
		END

		-- Además de tildes, espacios y Ñ dejo números por si acaso
		IF @NombreServ LIKE '%[^a-zA-ZÁÉÍÓÚÑáéíóúñ0-9 ]%'
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del servicio solo puede tener letras, números y espacios.';
			RETURN;
		END

		IF LEN(TRIM(@DescripServ)) < 5
		BEGIN
			SET @Mensaje = 'ERROR: La descripción debe tener al menos 5 caracteres.';
			RETURN;
		END

		IF @Precio <= 0
		BEGIN
			SET @Mensaje = 'ERROR: El precio de venta del servicio debe ser mayor que 0.';
			RETURN;
		END

		BEGIN TRANSACTION;

		DECLARE @exist_Serv BIT = (SELECT EstadoServ FROM Servicio WITH (UPDLOCK, ROWLOCK)
							       WHERE CodServ = @CodServ);

		IF @exist_Serv IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Servicio ('+ TRY_CONVERT(nvarchar(10),@CodServ) +') no encontrado en el sistema, revise el código/ID.';
			RETURN;
		END

		IF @exist_Serv = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El servicio del código ('+ TRY_CONVERT(nvarchar(10),@CodServ) +') está desactivado.';
			RETURN;
		END

		IF EXISTS (SELECT 1 FROM Servicio WITH (UPDLOCK, ROWLOCK)
				   WHERE NombreServ = @NombreServ
				   AND CodServ <> @CodServ
				   AND EstadoServ = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Ya existe otro servicio con el nombre: "'+ @NombreServ +'".';
			RETURN;
		END

		UPDATE Servicio
		SET NombreServ = TRIM(@NombreServ),
			DescripServ = TRIM(@DescripServ),
			Precio = @Precio,
			DateUpdate = SYSDATETIMEOFFSET()
		WHERE CodServ = @CodServ;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar el servicio.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Servicio actualizado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al actualizar el servicio: ' + ERROR_MESSAGE();
	END CATCH
END