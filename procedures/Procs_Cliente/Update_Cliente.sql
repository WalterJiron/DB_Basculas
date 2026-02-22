USE Bascula

GO

Create PROC Procs_UPDATECLIENTE
	@CodigoCl int,
	@PrimerNombreC NVARCHAR(25),
	@SegundoNombreC NVARCHAR(25),
	@PrimerApellidoC NVARCHAR(25),
	@SegundoApellidoC NVARCHAR(25),
	@TelefonoC NVARCHAR(8),
	@Direccion NVARCHAR(250),
	@TipoCliente NVARCHAR(15),
	@MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN 
	SET NOCOUNT ON;

	BEGIN TRY 
		--------VALIDAMOS QUE LOS CAMPOS NO ESTEN NULOS NI VACIOS
		IF @CodigoCl IS NULL OR @PrimerNombreC IS NULL  OR @PrimerApellidoC IS NULL OR @TelefonoC IS  NULL
			OR @Direccion IS NULL 
		BEGIN
			SET @MENSAJE ='Los campos primer nombre, primer apellido, telefono, direccion no pueden ser valores nulos';
			RETURN;
		END
		-----validamos que los nombres y apellidos no tengan menos de 3 caracteres 
		IF LEN(@PrimerNombreC) < 3 OR LEN(@PrimerApellidoC) < 3 
		BEGIN 
			SET @MENSAJE = 'Los nombres y apellidos deben tener al menos 3 caractares';
			RETURN;
		END
		-----validamos que los nombres y apellidos no tengan mas de 25 caracteres 
		IF LEN(@PrimerNombreC) > 25 OR LEN(@PrimerApellidoC) > 25 
		BEGIN 
			SET @MENSAJE = 'Los nombres y apellidos no pueden tener mas de 25 caractares';
			RETURN;
		END

		IF LEN(@Direccion)< 10 OR LEN(@Direccion) > 250
		BEGIN
			SET @MENSAJE = 'La direccion no pueden tener menos de 10 caracteres ni mas de 250';
			RETURN;
		END

		
		IF LEN(@TipoCliente) < 5 OR LEN(@TipoCliente) > 15
		BEGIN
			SET @MENSAJE = 'El tipo de cliente no puede tener menos de 5 caracteres ni mas de 15';
			RETURN;
		END

		-- Validaci�n de caracteres invalidos  0/10
		IF (@PrimerNombreC  LIKE '%[^A-Za-záéíóúÁÉÍÓÚñÑ ]%' OR
            @SegundoNombreC  LIKE '%[^A-Za-záéíóúÁÉÍÓÚñÑ ]%' OR
            @PrimerApellidoC  LIKE '%[^A-Za-záéíóúÁÉÍÓÚñÑ ]%' OR
            @SegundoApellidoC   LIKE '%[^A-Za-záéíóúÁÉÍÓÚñÑ ]%')
        BEGIN
            SET @MENSAJE = 'Los nombres y apellidos solo deben contener letras y espacios';
            RETURN;
        END
		
		-- MALO
		IF @TipoCliente NOT IN('Juridico','Natural')
		BEGIN
			SET @MENSAJE = 'El cliente debe ser juridico o genereal';
			RETURN;
		END

		BEGIN TRANSACTION;
		
		IF EXISTS (SELECT 1 FROM Cliente 
		WHERE PNCL = LOWER(TRIM(@PrimerNombreC))
			  AND SNCL = LOWER(TRIM(@SegundoNombreC))
			  AND PACL = LOWER(TRIM(@PrimerApellidoC))
			  AND SACL = LOWER(TRIM(@SegundoApellidoC)) 
			  AND CodCliente <> @CodigoCl
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'Ya existe un cliente con el mismo nombre completo.';
			RETURN;
		END
		-----validamos que el cliente exista----------------------

		DECLARE @CODIGO_CLIENTE BIT;
		SET @CODIGO_CLIENTE =(SELECT EstadoCL FROM Cliente WITH(UPDLOCK,ROWLOCK) WHERE CodCliente = @CodigoCl);

		IF(@CODIGO_CLIENTE IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El cliente no esta registrado';
			RETURN;
		END

		------MIRAMOS SI SE ENCUENTRA ACTIVO
		IF(@CODIGO_CLIENTE = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El cliente se encuentra inactivo';
			RETURN;
		END

				--------validamos el telefono--------

		IF (@TelefonoC NOT LIKE '[2578][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') 
		BEGIN 
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El primer numero inicar con 2,5,7 u 8, el resto deben ser caracteres numericos';
			RETURN;
		END

		IF LEN(@TelefonoC) <> 8 
		BEGIN
			ROLLBACK TRANSACTION
			SET @MENSAJE = 'El telefono debe tener 8 numeros';
			RETURN 
		END
		
		-------BUSCAMOS QUE NINGUN OTRO CLIENTE TENGA EL MISMO EL TELEFONO
		DECLARE @Telefono_Duplicado NVARCHAR(8);
		SET @Telefono_Duplicado = (SELECT Telefono FROM Cliente WITH(UPDLOCK,ROWLOCK) WHERE Telefono = @TelefonoC AND CodCliente <> @CodigoCl);

		IF (@Telefono_Duplicado IS NOT NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El telefono ya se encuentra registrado';
			RETURN;
		END

		UPDATE Cliente SET 
			PNCL = LOWER(TRIM(@PrimerNombreC)), 
			SNCL = LOWER(TRIM(@SegundoNombreC)),
			PACL = LOWER(TRIM(@PrimerApellidoC)),
			SACL = LOWER(TRIM(@SegundoApellidoC)),
			Telefono = @TelefonoC,
			Direccion = LOWER(TRIM(@Direccion)),
			TipoCliente = LOWER(TRIM(@TipoCliente)),
			DateUpdate = SYSDATETIMEOFFSET()
		WHERE CodCliente = @CodigoCl;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'Error al actualizar clientes';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @MENSAJE = 'Exito al actualizar clientes';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @MENSAJE = 'Error al actualizar el cliente:' + ERROR_MESSAGE();
	END CATCH
END;