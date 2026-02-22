USE Bascula
GO

CREATE PROC ProcRestoreServicio
@CodServ INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodServ IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código del servicio.';
			RETURN;
		END
		
		BEGIN TRANSACTION;
		
		DECLARE @exist_Serv BIT;
        SET @exist_Serv = (SELECT EstadoServ 
							 FROM Servicio WITH (UPDLOCK, ROWLOCK)
							 WHERE CodServ = @CodServ);
		
		IF @exist_Serv IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Servicio ('+ TRY_CONVERT(nvarchar(10),@CodServ) +') no registrado en el sistema, revise el código/ID.';
			RETURN;
		END
		
		IF @exist_Serv = 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El servicio del código ('+ TRY_CONVERT(nvarchar(10),@CodServ) +') ya está activo';
			RETURN;
		END

		UPDATE Servicio
		SET EstadoServ = 1,
			DateDelete = NULL
		WHERE CodServ = @CodServ;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al reactivar servicio.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Servicio reactivado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al reactivar servicio: ' + ERROR_MESSAGE();
	END CATCH
END