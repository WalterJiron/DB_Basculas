USE Bascula
GO

CREATE PROC ProcCreateProveedor
	@NombreProv NVARCHAR(50), --50
	@DescripProv NVARCHAR(MAX),
	@Telefono NVARCHAR(8),
	@Email NVARCHAR(100), --100
	@Direccion NVARCHAR(250), --250
	@Mensaje NVARCHAR(100) OUTPUT --150
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		IF @NombreProv IS NULL OR TRIM(@NombreProv) = '' OR @Telefono IS NULL OR @Email IS NULL OR @Direccion IS NULL OR TRIM(@Direccion) = ''
		BEGIN
			SET @Mensaje = 'ERROR: Nombre, télefono, Email, y dirección son campos obligatorios.';
			RETURN;
		END

		IF LEN(TRIM(@NombreProv)) < 3 OR LEN(TRIM(@NombreProv)) > 50
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del proveedor debe tener al menos 3 caracteres, máximo 50';
			RETURN;
		END

		IF (@NombreProv LIKE '%[^a-zA-ZÁÉÍÓÚÑáéíóúñ ]%')
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del proveedor solo puede contener letras y espacios.';
			RETURN;
		END

		IF (@Telefono NOT LIKE '[2578][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') OR LEN(TRIM(@Telefono)) != 8
		BEGIN
			SET @Mensaje = 'ERROR: El teléfono debe tener 8 dígitos y comenzar con 2, 5, 7 u 8. Asegúrese de no ingresar espacios antes o entremedio.';
			RETURN;
		END

		IF (LEN(TRIM(@Email)) < 6 OR LEN(TRIM(@Email)) > 100) 
		BEGIN
			SET @Mensaje = 'ERROR: El correo debe tener al menos 6 caracteres, máximo 100.';
			RETURN;
		END
		/*El límite absoluto real sería 254
		[parte local] + [@] + [nombre de dominio] + [.] + [extensión]*/

		IF @Email NOT LIKE '%_@_%._%' OR @Email LIKE '%@%@%' OR 
		   @Email NOT LIKE '%.%' OR @Email LIKE '%..%'
		BEGIN
			SET @Mensaje = 'ERROR: El formato del correo no es valido.';
			RETURN;
		END

		IF LEN(TRIM(@Direccion)) < 5 OR LEN(TRIM(@Direccion)) > 250
		BEGIN
			SET @Mensaje = 'ERROR: La dirección debe tener al menos 5 caracteres, máximo 250.';
			RETURN;
		END

		BEGIN TRANSACTION;

		-- Revisar si el télefono o email ya estan registrados
		IF EXISTS (SELECT 1 FROM Proveedor WITH (UPDLOCK, ROWLOCK) WHERE Telefono = @Telefono)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El teléfono "'+ @Telefono +'" ya está registrado con otro proveedor.';
			RETURN;
		END
		
		IF EXISTS (SELECT 1 FROM Proveedor WITH (UPDLOCK, ROWLOCK) WHERE Email = @Email)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El Email "'+ @Email +'" ya está registrado con otro proveedor.';
			RETURN;
		END


		INSERT INTO Proveedor (NombreProv, DescripProv, Telefono, Email, Direccion)
		VALUES ((TRIM(@NombreProv)), (TRIM(@DescripProv)), @Telefono, (lower(TRIM(@Email))), (TRIM(@Direccion)));

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al registrar el proveedor.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Proveedor registrado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al registrar el proveedor: ' + ERROR_MESSAGE();
	END CATCH
END