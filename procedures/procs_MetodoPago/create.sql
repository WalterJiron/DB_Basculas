USE Bascula
GO

CREATE PROC ProcCreateMetodoPago
@NombreMetodo nvarchar(50),
@DescripMetodo nvarchar(250),
@Mensaje nvarchar(100) OUTPUT
as
begin
	SET NOCOUNT ON;

	BEGIN TRY
		IF @NombreMetodo IS NULL OR TRIM(@NombreMetodo) = ''
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del método de pago es obligatorio.';
			RETURN;
		END

		IF LEN(TRIM(@NombreMetodo)) < 3 OR LEN(TRIM(@NombreMetodo)) > 50
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del método de pago debe tener al menos 3 caracteres, máx. 50';
			RETURN;
		END

		IF LEN(TRIM(@DescripMetodo)) > 250
		BEGIN
			SET @Mensaje = 'ERROR: La descripción excede límite de caracteres (250).';
			RETURN;
		END

		-- Se permite que ingrese el nombre con tildes y Ñ por si acaso
		IF @NombreMetodo LIKE '%[^a-zA-ZÁÉÍÓÚÑáéíóúñ ]%'
        BEGIN
            SET @Mensaje = 'ERROR: El nombre del método solo puede contener letras y espacios.';
            RETURN;
        END

		BEGIN TRANSACTION;

		IF EXISTS (SELECT 1 FROM MetodoPago WITH (UPDLOCK, ROWLOCK)
				   WHERE NombreMetodo = @NombreMetodo
				   AND EstadoMetodo = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Método de pago "'+ @NombreMetodo +'" ya registrado y activo.';
			RETURN;
		END

		INSERT INTO MetodoPago (NombreMetodo, DescripMetodo)
		VALUES ((TRIM(@NombreMetodo)), (TRIM(@DescripMetodo)));

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error al registrar el método de pago.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Método de pago registrado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		SET @Mensaje = 'Error al registrar el método de pago: ' + ERROR_MESSAGE();
	END CATCH
END