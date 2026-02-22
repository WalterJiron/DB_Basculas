USE Bascula 

GO

CREATE PROCEDURE Procs_InsercionCliente
	@PrimerNombreC NVARCHAR(25),
	@SegundoNombreC NVARCHAR(25),
	@PrimerApellidoC NVARCHAR(25),
	@SegundoApellidoC NVARCHAR(25),
	@TelefonoC NVARCHAR(8),
	@Direccion NVARCHAR(250),
	@TipoCliente NVARCHAR(15),
	@MENSAJE NVARCHAR(100) OUTPUT,
	@CodCliente INT OUTPUT
AS
BEGIN 
	SET NOCOUNT ON;
	
	BEGIN TRY 
		IF @PrimerNombreC IS NULL OR @PrimerApellidoC IS NULL OR @TelefonoC IS  NULL
			OR @Direccion IS NULL 
		BEGIN
			SET @MENSAJE ='Los campos primer nombre, primer apellido, teléfono, dirección no pueden ser valores nulos';
			RETURN;
		END

		IF LEN(@PrimerNombreC) < 3 OR LEN(@PrimerApellidoC) < 3 
		BEGIN 
			SET @MENSAJE = 'Los nombres y apellidos deben tener al menos 3 caracteres';
			RETURN;
		END
		
		IF LEN(@PrimerNombreC) > 25  OR LEN(@PrimerApellidoC) > 25 
		BEGIN 
			SET @MENSAJE = 'Los nombres y apellidos no pueden tener más de 25 caracteres';
			RETURN;
		END

		IF LEN(@Direccion) < 10 OR LEN(@Direccion) > 250
		BEGIN
			SET @MENSAJE = 'La dirección debe tener entre 10 y 250 caracteres';
			RETURN;
		END

		
		IF LEN(@TipoCliente) < 5 OR LEN(@TipoCliente) > 15
		BEGIN
			SET @MENSAJE = 'El tipo de cliente no puede tener menos de 5 caracteres ni más de 15';
			RETURN;
		END


		IF (@PrimerNombreC  LIKE '%[^A-Za-záéíóúÁÉÍÓÚñÑ ]%' OR
            @SegundoNombreC  LIKE '%[^A-Za-záéíóúÁÉÍÓÚñÑ ]%' OR
            @PrimerApellidoC  LIKE '%[^A-Za-záéíóúÁÉÍÓÚñÑ ]%' OR
            @SegundoApellidoC   LIKE '%[^A-Za-záéíóúÁÉÍÓÚñÑ ]%')
        BEGIN
            SET @MENSAJE = 'Los nombres y apellidos solo deben contener letras y espacios';
            RETURN;
        END
		
		IF @TipoCliente NOT IN('Juridico','Natural')
		BEGIN
			SET @MENSAJE = 'El cliente debe ser Juridico o Natural';
			RETURN;
		END

		IF (@TelefonoC NOT LIKE '[2578][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') 
		BEGIN 
			SET @MENSAJE = 'El primer número debe iniciar con 2,5,7 u 8, el resto deben ser caracteres numéricos';
			RETURN;
		END 

		IF LEN(@TelefonoC) <> 8 
		BEGIN
			SET @MENSAJE = 'El teléfono debe tener 8 números';
			RETURN 
		END

		IF EXISTS (SELECT 1 FROM Cliente 
		WHERE PNCL = LOWER(TRIM(@PrimerNombreC))
			  AND SNCL = LOWER(TRIM(@SegundoNombreC))
			  AND PACL = LOWER(TRIM(@PrimerApellidoC))
			  AND SACL = LOWER(TRIM(@SegundoApellidoC))
		)
		BEGIN
			SET @MENSAJE = 'Ya existe un cliente con el mismo nombre completo.';
			RETURN;
		END

		IF EXISTS (SELECT 1 FROM Cliente WHERE Telefono = @TelefonoC)
		BEGIN
			SET @MENSAJE = 'Ya existe un cliente con ese número de teléfono.';
			RETURN;
		END

		BEGIN TRANSACTION;		

		INSERT INTO Cliente (
			PNCL,SNCL,PACL,SACL,Telefono,Direccion,TipoCliente
			)
		VALUES(
			LOWER(TRIM(@PrimerNombreC)), LOWER(TRIM(@SegundoNombreC)), LOWER(TRIM(@PrimerApellidoC)), LOWER(TRIM(@SegundoApellidoC)), @TelefonoC, LOWER(TRIM(@Direccion)), LOWER(TRIM(@TipoCliente))
		);

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'Error al insertar el cliente';
            RETURN;
        END

		COMMIT TRANSACTION;
		SET @MENSAJE = 'Éxito al insertar el cliente';

	
		SET @CodCliente = CAST(SCOPE_IDENTITY() AS INT);

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @MENSAJE = 'Error al insertar al cliente: ' + ERROR_MESSAGE();
	END CATCH
END;