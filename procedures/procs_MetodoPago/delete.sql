USE Bascula
GO

CREATE PROC ProcDeleteMetodoPago
@CodMetodoPago INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodMetodoPago IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código del método de pago.';
			RETURN;
		END
		
		BEGIN TRANSACTION;
		
		DECLARE @exist_Metodo BIT;
        SET @exist_Metodo = (SELECT EstadoMetodo 
							 FROM MetodoPago WITH (UPDLOCK, ROWLOCK)
							 WHERE CodMetodoPago = @CodMetodoPago);
		
		IF @exist_Metodo IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Método de pago ('+ TRY_CONVERT(nvarchar(10),@CodMetodoPago) +' no registrado en el sistema, revise el código/ID.';
			RETURN;
		END
		
		IF @exist_Metodo = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El método de pago del código ('+ TRY_CONVERT(nvarchar(10),@CodMetodoPago) +') ya está desactivado.';
			RETURN;
		END

		UPDATE MetodoPago
		SET EstadoMetodo = 0,
			DateDelete = SYSDATETIMEOFFSET()
		WHERE CodMetodoPago = @CodMetodoPago;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al desactivar el método de pago.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Método de pago desactivado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al desactivar el método de pago: ' + ERROR_MESSAGE();
	END CATCH
END