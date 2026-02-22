USE Bascula
GO

CREATE PROC ProcUpdateProveedor
@CodProv INT,
@NombreProv NVARCHAR(50), -- 50
@DescripProv NVARCHAR(MAX),
@Telefono NVARCHAR(8),
@Email NVARCHAR(100), --100
@Direccion NVARCHAR(250), --250
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		
		IF @CodProv IS NULL OR @NombreProv IS NULL OR TRIM(@NombreProv) = '' OR
		   @Telefono IS NULL OR @Email IS NULL OR @Direccion IS NULL OR TRIM(@Direccion) = ''
		BEGIN
			SET @Mensaje = 'ERROR: El c�digo de proveedor, nombre, t�lefono, Email, y direcci�n son campos obligatorios.';
			RETURN;
		END

		IF (LEN(TRIM(@NombreProv)) < 3 OR LEN(TRIM(@NombreProv)) > 50)
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del proveedor debe tener al menos 3 caracteres, m�ximo 50';
			RETURN;
		END

		IF (@NombreProv LIKE '%[^a-zA-Z������������ ]%')
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del proveedor solo puede contener letras y espacios.';
			RETURN;
		END

		IF (@Telefono NOT LIKE '[2578][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') OR LEN(TRIM(@Telefono)) != 8
		BEGIN
			SET @Mensaje = 'ERROR: El tel�fono debe tener 8 d�gitos y comenzar con 2, 5, 7 u 8. Aseg�rese de no ingresar espacios antes o entremedio.';
			RETURN;
		END

		IF (LEN(TRIM(@Email)) < 5 OR LEN(TRIM(@Email)) > 100)
		BEGIN
			SET @Mensaje = 'ERROR: El correo debe tener al menos 5 caracteres, m�ximo 100.';
			RETURN;
		END
		/*El l�mite absoluto real ser�a 254
		[parte local] + [@] + [nombre de dominio] + [.] + [extensi�n]*/

		IF @Email NOT LIKE '%_@_%._%' OR @Email LIKE '%@%@%' OR 
		   @Email NOT LIKE '%.%' OR @Email LIKE '%..%'
		BEGIN
			SET @Mensaje = 'ERROR: El formato del correo no es valido.';
			RETURN;
		END

		IF (LEN(TRIM(@Direccion)) < 10 OR LEN(TRIM(@Direccion)) > 250)
		BEGIN
			SET @Mensaje = 'ERROR: La direcci�n debe tener al menos 10 caracteres, m�ximo 250.';
			RETURN;
		END

		BEGIN TRANSACTION;

		DECLARE @exist_Prov BIT = (SELECT EstadoProv FROM Proveedor WITH (UPDLOCK, ROWLOCK)
								   WHERE CodProv = @CodProv);
		
		IF @exist_Prov IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: C�digo de Proveedor ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') no encontrado en el sistema, revise el c�dido/ID.';
			RETURN;
		END

		IF @exist_Prov = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El proveedor del c�digo ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') est� inactivo.';
			RETURN;
		END

		-- Revisar si el t�lefono o email ya estan registrados
		IF EXISTS (SELECT 1 FROM Proveedor WITH (UPDLOCK, ROWLOCK) WHERE Telefono = @Telefono AND CodProv <> @CodProv)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El tel�fono "'+ @Telefono +'" ya est� registrado con otro proveedor.';
			RETURN;
		END
		
		IF EXISTS (SELECT 1 FROM Proveedor WITH (UPDLOCK, ROWLOCK) WHERE Email = @Email AND CodProv <> @CodProv)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El Email "'+ @Email +'" ya est� registrado con otro proveedor.';
			RETURN;
		END

		UPDATE Proveedor
		SET NombreProv = (TRIM(@NombreProv)),
			DescripProv = (TRIM(@DescripProv)),
			Telefono = @Telefono,
			Email = (lower(TRIM(@Email))),
			Direccion = (TRIM(@Direccion)),
			DateUpdate = SYSDATETIMEOFFSET()
		WHERE CodProv = @CodProv;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar el proveedor.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Proveedor actualizado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SET @Mensaje = 'Error al actualizar el proveedor: ' + ERROR_MESSAGE();
	END CATCH
END