USE Bascula

GO

CREATE PROC ACTIVAR_CLIENTE_JURIDICO
	@CodClienteJ INT,
	@MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		--------------------VALIDAR QUE NO ESTE NULO
		IF (@CodClienteJ IS NULL)
		BEGIN
			SET @MENSAJE ='El codigo del cliente es un campo obligatorio';
			RETURN;
		END

		BEGIN TRANSACTION;
		-----------------------BUSQUEDA DEL CLIENTE
		DECLARE @Juridico_Existe BIT;
		SET @Juridico_Existe = (SELECT EstadoCLJ FROM ClienteJuridico WITH (UPDLOCK,ROWLOCK) WHERE CodClienteJuridico = @CodClienteJ);
		
		----------------------VER SI EXISTE EL CLIENTE JURIDICO
		IF (@Juridico_Existe IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'El cliente juridico no existe';
			RETURN;
		END

		IF (@Juridico_Existe = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE ='El cliente juridico ya se encuentra activo';
			RETURN;
		END
		
		UPDATE ClienteJuridico SET 
			EstadoCLJ = 1,
			DateDelete = NULL
		WHERE CodClienteJuridico = @CodClienteJ

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'Error al activar el cliente juridico';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @MENSAJE = 'El cliente juridico se activo correctamente';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

			SET @MENSAJE = 'Error al activar el cliente juridico: ' +ERROR_MESSAGE();
	END CATCH
	
END