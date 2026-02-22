USE Bascula

GO

CREATE PROC Procs_ACTIVAR_CLIENTE
	@CodCl INT,
	@MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		---VALIDAR QUE NO ESTE NULO
		IF(@CodCl IS NULL)
		BEGIN
			SET @MENSAJE ='El codigo no puede ser un campo vacio';
			RETURN;
		END

		BEGIN TRANSACTION;

		DECLARE @Cliente_Existe BIT;
		SET @Cliente_Existe = (SELECT EstadoCL FROM Cliente WITH(UPDLOCK,ROWLOCK) WHERE CodCliente = @CodCl);

		----VERIFICAR SI EL CLIENTE EXISTE
		IF (@Cliente_Existe IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El cliente no esta registrado';
			RETURN;
		END

		-------VERIFICAR SI EL CLINETE YA ESTA ACTIVO
		IF (@Cliente_Existe = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El cliente ya esta activo';
			RETURN;	
		END

		UPDATE Cliente SET 
			EstadoCL = 1,
			DateDelete = NULL
		WHERE CodCliente = @CodCl;

		UPDATE ClienteJuridico SET 
			EstadoCLJ = 1,
			DateDelete = NULL
		WHERE CodCliente = @CodCl;

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'Error al activar el cliente';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @MENSAJE = 'El cliente se activo correctamente';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

			SET @MENSAJE = 'Error al activar el cliente: ' +ERROR_MESSAGE();
	END CATCH
END;