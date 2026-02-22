USE Bascula
GO

CREATE PROC ProcUpdateMetodoPago
@CodMetodoPago INT,
@NombreMetodo NVARCHAR(50),
@DescripMetodo NVARCHAR(250),
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodMetodoPago IS NULL OR @NombreMetodo IS NULL OR TRIM(@NombreMetodo) = ''
		BEGIN
			SET @Mensaje = 'ERROR: El código y nombre del método de pago son campos obligatorios.';
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
            SET @Mensaje = 'ERROR: El nombre del método de pago solo puede contener letras y espacios';
            RETURN;
        END

		BEGIN TRANSACTION;

		DECLARE @exist_Metodo BIT;
		SET @exist_Metodo = (SELECT EstadoMetodo FROM MetodoPago WITH(UPDLOCK, ROWLOCK)
							 WHERE CodMetodoPago = @CodMetodoPago)

		IF @exist_Metodo IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Método de pago ('+ TRY_CONVERT(nvarchar(10),@CodMetodoPago) +') no registrado en el sistema, revise el código/ID.';
			RETURN;
		END
		
		IF @exist_Metodo = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El método de pago del código ('+ TRY_CONVERT(nvarchar(10),@CodMetodoPago) +') está desactivado';
			RETURN;
		END
		
		IF EXISTS (SELECT 1 FROM MetodoPago WITH (UPDLOCK, ROWLOCK)
				   WHERE NombreMetodo = @NombreMetodo
				   AND CodMetodoPago <> @CodMetodoPago
				   AND EstadoMetodo = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Ya existe otro método de pago activo con el nombre "'+ @NombreMetodo +'".';
			RETURN;
		END

		UPDATE MetodoPago
		SET NombreMetodo = (TRIM(@NombreMetodo)),
			DescripMetodo = (TRIM(@DescripMetodo)),
			DateUpdate = SYSDATETIMEOFFSET()
		WHERE CodMetodoPago = @CodMetodoPago;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar método de pago.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Método de pago actualizado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @Mensaje = 'Error al actualizar el método de pago: ' + ERROR_MESSAGE();
	END CATCH
END