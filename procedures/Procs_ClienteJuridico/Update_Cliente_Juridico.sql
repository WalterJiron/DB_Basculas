USE Bascula

GO

CREATE PROC PROCS_Update_ClienteJuridico
	@CodClienteJu INT,
	@CodRuc NVARCHAR(20),
	@EmpresaName NVARCHAR(100),
	@CargoContact NVARCHAR(50),
	@EmailEmpresa NVARCHAR(100),
	@MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY 
		IF ( @CodClienteJu <= 0 OR LEN(@CodRuc) = 0 OR LEN(@EmpresaName) = 0 OR 
		LEN(@EmailEmpresa) = 0)
		BEGIN
			SET @MENSAJE = 'Los campos no pueden ser nulos o vacios';
			RETURN;
		END


		IF (LEN(@CodRuc) < 13 or LEN(@CodRuc) > 20)
		BEGIN
			SET @MENSAJE = 'El ruc no puede tener menos de 13 caracteres ni mas de 20';
			RETURN;
		END	

		IF (LEN(@EmpresaName) < 5 OR LEN(@EmpresaName) > 100)
		BEGIN
			SET @MENSAJE = 'El nombre de la empresa debe tener al menos 5 caracteres';
			RETURN;
		END

		IF LEN(@CargoContact) < 7 OR LEN(@CargoContact) > 50
        BEGIN
            SET @MENSAJE = 'El cargo del contacto no debe exceder los 50 caracteres';
            RETURN;
        END

        IF LEN(@EmailEmpresa) < 6 OR LEN(@EmailEmpresa) > 100
        BEGIN
            SET @MENSAJE = 'El correo electronico debe tener entre 6 y 100 caracteres';
            RETURN;
        END

		IF @EmailEmpresa NOT LIKE '%_@_%._%' OR @EmailEmpresa LIKE '%@%@%' OR 
            @EmailEmpresa NOT LIKE '%.%' OR @EmailEmpresa LIKE '%..%'
        BEGIN
            SET @Mensaje = 'El formato del correo no es valido';
            RETURN;
        END
      

		BEGIN TRANSACTION;

		-----------VERIFCAMOS SI EL CLIENTE JURIDICO EXISTE---------------------
		DECLARE @Cliente_Juridico BIT;
		SET @Cliente_Juridico = (SELECT EstadoCLJ FROM ClienteJuridico WITH(UPDLOCK,ROWLOCK) WHERE CodClienteJuridico = @CodClienteJu);

		IF (@Cliente_Juridico IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El codigo del cliente juridico ingresado no existe';
			RETURN;
		END

		IF(@Cliente_Juridico = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE ='El cliente juridico se encuentra inactico';
			RETURN;
		END

		------VERIFICAR SI EL EMAIL YA SE ENCUENTRA REGISTRADO
		IF EXISTS (SELECT 1 FROM ClienteJuridico WITH(UPDLOCK,ROWLOCK) WHERE EmailEmpresa = @EmailEmpresa AND CodClienteJuridico <> @CodClienteJu)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El email ya esta registrado por otro cliente';
			RETURN;
		END	

		UPDATE ClienteJuridico SET 
			RUC =  TRIM(@CodRuc),
			NombreEmpresa = TRIM(LOWER(@EmpresaName)),
			CargoContacto =  TRIM(LOWER(@CargoContact)),
			EmailEmpresa = TRIM(LOWER(@EmailEmpresa)),
			DateUpdate = SYSDATETIMEOFFSET() 
		WHERE CodClienteJuridico = @CodClienteJu;

		IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'No se pudo actualizar el cliente juridico';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @MENSAJE = 'Cliente juridico actualizado exitosamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @MENSAJE = 'Error al actualizar cliente juridico: ' + ERROR_MESSAGE();
    END CATCH
END