USE Bascula

GO

CREATE PROC Procs_InserccionClienteJuridico
	@CodRuc NVARCHAR(20),
	@EmpresaName NVARCHAR(100),
	@CodigoCL INT,
	@CargoContact NVARCHAR(50),
	@EmailEmpresa NVARCHAR(100),
	@MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY 
		IF (LEN(@CodRuc) = 0 OR LEN(@EmpresaName) = 0 OR @CodigoCL = 0  OR LEN(@EmailEmpresa)= 0)
		BEGIN
			SET @MENSAJE = 'Los campos no pueden ser nulos';
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

		IF LEN(@CargoContact) < 5 OR LEN(@CargoContact) > 50
        BEGIN
            SET @MENSAJE = 'El cargo del contacto debe tener entre 5 a 50 caracteres';
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
            SET @MENSAJE = 'El formato del correo no es valido';
            RETURN;
        END
      
		BEGIN TRANSACTION;

		-----verificamos que el cliente exista-----------------
		
		DECLARE @Cliente_Activo BIT;
		SET @Cliente_Activo = (SELECT EstadoCL FROM Cliente WITH(UPDLOCK,ROWLOCK) WHERE CodCliente = @CodigoCL);

		IF(@Cliente_Activo IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE ='El cliente base no existe';
			RETURN;
		END

		IF(@Cliente_Activo = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE ='El cliente base se encuentra inactivo';
			RETURN;
		END

		INSERT INTO ClienteJuridico (
				RUC, NombreEmpresa, CodCliente, CargoContacto, EmailEmpresa)
		VALUES(TRIM(@CodRuc), TRIM(LOWER(@EmpresaName)), @CodigoCL, TRIM(LOWER(@CargoContact)), TRIM(LOWER(@EmailEmpresa)));
		
		IF @@ROWCOUNT <> 1
		BEGIN 
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'Error al insertar el cliente juridico';
			RETURN;
		END

		COMMIT TRANSACTION;
        SET @MENSAJE = 'Cliente juridico insertado exitosamente';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @MENSAJE = 'Error al insertar cliente juridico: ' + ERROR_MESSAGE();
    END CATCH
END




