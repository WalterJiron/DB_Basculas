USE Bascula
GO

CREATE PROC ProcCreateServicio
@NombreServ NVARCHAR(50), --50
@DescripServ NVARCHAR(MAX),
@Precio DECIMAL(18,4),
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @NombreServ IS NULL OR TRIM(@NombreServ) = '' OR @DescripServ IS NULL OR @Precio IS NULL
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

		IF EXISTS (SELECT 1 FROM Servicio WITH (UPDLOCK, ROWLOCK)
				   WHERE NombreServ = @NombreServ
				   AND EstadoServ = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Ya existe un servicio con el nombre: "'+ @NombreServ +'".';
			RETURN;
		END

		INSERT INTO Servicio (NombreServ, DescripServ, Precio)
		VALUES (TRIM(@NombreServ), TRIM(@DescripServ), @Precio);

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al registrar el servicio.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Servicio registrado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al registrar el servicio: ' + ERROR_MESSAGE();
	END CATCH
END